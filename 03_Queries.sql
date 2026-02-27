use LogisticsDB
-----------------------Basic Queries----------------------------
--Get all shipments with customer name and vehicle plate
SELECT 
    s.ShipmentId,
    c.FullName AS CustomerName,
    v.PlateNumber,
    s.Status,
    s.CreatedAt
FROM Shipments s
JOIN Customers c ON s.CustomerId = c.CustomerId
JOIN Vehicles v ON s.VehicleId = v.VehicleId;
---Get all shipments not delivered
SELECT 
    ShipmentId,
    OriginWarehouseId,
    DestinationWarehouseId,
    Weight,
    Status,
    CreatedAt
FROM Shipments
WHERE Status <> 'Delivered'; 
--Get drivers without assigned vehicles
SELECT 
    d.DriverId,
    d.FullName,
    d.LicenseNumber
FROM Drivers d
LEFT JOIN Vehicles v ON d.DriverId = v.AssignedDriverId
WHERE v.VehicleId IS NULL;
--Calculate warehouse capacity usage percentage
SELECT 
    w.WarehouseId,
    w.Name AS WarehouseName,
    w.Capacity AS TotalCapacity,
    ISNULL(SUM(s.Weight), 0) AS CurrentUsedWeight,
CAST((ISNULL(SUM(s.Weight), 0) / 
CAST(w.Capacity AS DECIMAL(18,2)))*100  AS DECIMAL(5,4)) AS UsagePercentage
FROM Warehouses w
LEFT JOIN Shipments s ON w.WarehouseId = s.OriginWarehouseId AND s.Status = 'Pending'
GROUP BY 
    w.WarehouseId, 
    w.Name, 
    w.Capacity;
--Get customers created in the last 30 days
SELECT 
    CustomerId,
    FullName,
    Email,
    Phone,
    CreatedDate
FROM Customers
WHERE CreatedDate >= DATEADD(DAY, -30, GETDATE());

-----------------------Intermediate Queries----------------------------
--Top 5 customers by shipment count
SELECT TOP 5
    c.CustomerId,
    c.FullName AS CustomerName,
    COUNT(s.ShipmentId) AS TotalShipments
FROM Customers c
JOIN Shipments s ON c.CustomerId = s.CustomerId
GROUP BY c.CustomerId, c.FullName
ORDER BY TotalShipments DESC;

--Monthly revenue grouped by year and month
SELECT 
    YEAR(PaidDate) AS RevenueYear,
    MONTH(PaidDate) AS RevenueMonth,
    SUM(Amount) AS TotalRevenue
FROM Payments
WHERE IsPaid = 1 AND PaidDate IS NOT NULL
GROUP BY YEAR(PaidDate), MONTH(PaidDate)
ORDER BY RevenueYear DESC, RevenueMonth DESC;
--Average delivery time per warehouse
SELECT 
    w.WarehouseId,
    w.Name AS WarehouseName,
    AVG(s.DeliveryDurationHours) AS AvgDeliveryHours
FROM Warehouses w
JOIN Shipments s ON w.WarehouseId = s.OriginWarehouseId
WHERE s.Status = 'Delivered' 
GROUP BY w.WarehouseId, w.Name;
--Drivers with more than 3 delayed shipments
SELECT 
    d.DriverId,
    d.FullName AS DriverName,
    COUNT(s.ShipmentId) AS DelayedShipmentsCount
FROM Drivers d
JOIN Vehicles v ON d.DriverId = v.AssignedDriverId
JOIN Shipments s ON v.VehicleId = s.VehicleId
WHERE s.Status = 'Delivered' AND s.DeliveryDurationHours > 48 
GROUP BY d.DriverId, d.FullName
HAVING COUNT(s.ShipmentId) > 3; 
--Customers who have shipments but no payments
SELECT DISTINCT 
    c.CustomerId, 
    c.FullName
FROM Customers c
JOIN Shipments s ON c.CustomerId = s.CustomerId
WHERE c.CustomerId NOT IN (
    SELECT s2.CustomerId 
    FROM Shipments s2 
    JOIN Payments p ON s2.ShipmentId = p.ShipmentId 
    WHERE p.IsPaid = 1
);
--Warehouses with no shipments
SELECT 
    w.WarehouseId, 
    w.Name AS WarehouseName
FROM Warehouses w
LEFT JOIN Shipments s ON w.WarehouseId = s.OriginWarehouseId 
                      OR w.WarehouseId = s.DestinationWarehouseId
WHERE s.ShipmentId IS NULL;

--------------------------------------Advanced Queries-----------------------------------
--Rank drivers by total delivered shipments using ROW_NUMBER
 Select 
 d.DriverId ,d.FullName AS DriverName,
    COUNT(s.ShipmentId) AS DeliveredCount,
	ROW_NUMBER() Over(Order by count (s.ShipmentId) DESC)AS DriverRank

  from Drivers d left join Vehicles v
  on d.DriverId =v.AssignedDriverId
  left join Shipments s on s.VehicleId =v.VehicleId
  where s.Status='Delivered'
  Group by d.DriverId ,d.FullName;
--Use CTE to calculate revenue per city
;
with CityRevenue AS(
select 
c.CityId ,c.Name , sum(p.Amount) AS TotalRevenue
from Payments p join Shipments s on p.ShipmentId =p.ShipmentId
join Warehouses w on w.WarehouseId =s.OriginWarehouseId 
join Cities c on c.CityId =w.CityId
where p.IsPaid=1 
group by c.CityId ,c.Name
)
select * from CityRevenue

--Use WINDOW FUNCTIONS to calculate running revenue
SELECT 
    p.PaymentId,
    c.CityId,
    c.Name AS CityName,
    p.PaidDate,
    p.Amount,
    SUM(p.Amount) OVER (
        PARTITION BY c.CityId
        ORDER BY p.PaidDate
        ROWS UNBOUNDED PRECEDING
    ) AS RunningTotalRevenue
FROM Payments p
JOIN Shipments s ON p.ShipmentId = s.ShipmentId
JOIN Warehouses w ON s.OriginWarehouseId = w.WarehouseId
JOIN Cities c ON w.CityId = c.CityId
WHERE p.IsPaid = 1 AND p.PaidDate IS NOT NULL;

--Use EXISTS to find customers with unpaid shipments
SELECT *
FROM Customers c
WHERE EXISTS (
    SELECT 1
    FROM Shipments s
    JOIN Payments p ON s.ShipmentId = p.ShipmentId
    WHERE s.CustomerId = c.CustomerId
      AND p.IsPaid = 0
);
--Use SUBQUERY to compare driver salary with average salary
SELECT 
    DriverId,
    FullName,
    Salary,
    (SELECT AVG(Salary) FROM Drivers) AS AvgSalary,
    CASE 
        WHEN Salary > (SELECT AVG(Salary) FROM Drivers) THEN 'Above Average'
        WHEN Salary < (SELECT AVG(Salary) FROM Drivers) THEN 'Below Average'
        ELSE 'Average'
    END AS SalaryComparison
FROM Drivers;
--Use MERGE to synchronize drivers from staging table

CREATE TABLE StagingDrivers
( 
    DriverID INT,
    FullName NVARCHAR(150),
    LicenseNumber NVARCHAR(100),
    Salary DECIMAL(18,2),
    HireDate DATE,
    IsActive BIT
);
Merge Into Drivers AS Target 
using StagingDrivers AS Source
on Target.DriverID =Source.DriverID
when Matched then
    UPDATE SET
        Target.FullName = Source.FullName,
		Target.LicenseNumber=Source.LicenseNumber,
        Target.Salary = Source.Salary,
        Target.IsActive = Source.IsActive
When not matched then 
 INSERT (FullName, LicenseNumber, Salary, HireDate, IsActive)
    VALUES (Source.FullName, Source.LicenseNumber, Source.Salary, Source.HireDate, Source.IsActive);
--Use PIVOT to show shipment count per status
Select * from
(
select  s.Status from  Shipments s

) AS sourceTable
PIVOT
(
Count (Status) For Status in ([Pending], [InTransit], [Delivered], [Cancelled])
) AS PivotResult;

--Use GROUPING SETS for multi-level revenue summary !!
SELECT 
    CASE 
        WHEN GROUPING(c.Name) = 1 THEN 'All Cities'
        ELSE c.Name
    END AS CityName,

    CASE 
        WHEN GROUPING(p.PaymentMethod) = 1 THEN 'All Methods'
        ELSE p.PaymentMethod
    END AS PaymentMethod,

    SUM(p.Amount) AS TotalRevenue
FROM Payments p
JOIN Shipments s 
    ON p.ShipmentId = s.ShipmentId
JOIN Warehouses w 
    ON s.OriginWarehouseId = w.WarehouseId
JOIN Cities c 
    ON w.CityId = c.CityId
WHERE p.IsPaid = 1
GROUP BY GROUPING SETS
(
    (c.Name, p.PaymentMethod),  -- Detailed level
    (c.Name),                   -- Revenue per city
    (p.PaymentMethod),          -- Revenue per payment method
    ()                          -- Grand total
)
ORDER BY CityName, PaymentMethod;

--Use CROSS APPLY to fetch latest shipment per customer
SELECT 
    c.CustomerId,
    c.FullName,
    ls.ShipmentId,
    ls.Status,
    ls.CreatedAt,
    ls.DeliveredAt,
    ls.Price
FROM Customers c
CROSS APPLY
(
    SELECT TOP 1 
        s.ShipmentId,
        s.Status,
        s.CreatedAt,
        s.DeliveredAt,
        s.Price
    FROM Shipments s
    WHERE s.CustomerId = c.CustomerId
    ORDER BY s.CreatedAt DESC
) AS ls;