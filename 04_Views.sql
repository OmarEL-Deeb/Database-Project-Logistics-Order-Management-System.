use LogisticsDB
Go
--ActiveDrivers
Create view ActiveDrivers
AS
select DriverId,FullName
from Drivers
where IsActive =1
--ShipmentSummary
CREATE VIEW View_ShipmentSummary AS
SELECT 
    s.ShipmentId,
    c.FullName AS CustomerName,
    d.FullName AS DriverName,
    s.Status,
    p.Amount,
    p.IsPaid
FROM Shipments s
JOIN Customers c ON s.CustomerId = c.CustomerId
LEFT JOIN Payments p ON s.ShipmentId = p.ShipmentId
LEFT JOIN Vehicles v ON s.VehicleId = v.VehicleId
LEFT JOIN Drivers d ON v.AssignedDriverId = d.DriverId;
--MonthlyRevenue
CREATE VIEW View_MonthlyRevenue AS
SELECT 
    YEAR(PaidDate) AS Year,
    MONTH(PaidDate) AS Month,
    SUM(Amount) AS TotalRevenue
FROM Payments
WHERE IsPaid = 1
GROUP BY YEAR(PaidDate), MONTH(PaidDate);
--UnpaidShipments
CREATE VIEW View_UnpaidShipments AS
SELECT s.*
FROM Shipments s
LEFT JOIN Payments p 
    ON s.ShipmentId = p.ShipmentId
WHERE p.ShipmentId IS NULL;