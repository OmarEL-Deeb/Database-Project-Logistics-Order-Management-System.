USE LogisticsDB;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO
-- 1) Subquery vs Join


----- Subquery Version -----

SELECT FullName
FROM Customers
WHERE CustomerId IN (
SELECT CustomerId
FROM Shipments
WHERE Status = 'Delivered'
);
GO

----- Join Version -----'

SELECT DISTINCT c.FullName
FROM Customers c
INNER JOIN Shipments s
ON c.CustomerId = s.CustomerId
WHERE s.Status = 'Delivered';
GO

/*
  Expected Result:
  JOIN typically performs better on large datasets due to optimized execution plan.
  */




-- CTE vs Temp Table


----- CTE Version -----

WITH DeliveredShipments AS (
SELECT ShipmentId, Price
FROM Shipments
WHERE Status = 'Delivered'
)
SELECT SUM(Price) AS TotalRevenue
FROM DeliveredShipments;
GO

----- Temp Table Version -----

SELECT ShipmentId, Price
INTO #DeliveredShipments
FROM Shipments
WHERE Status = 'Delivered';

SELECT SUM(Price) AS TotalRevenue
FROM #DeliveredShipments;

DROP TABLE #DeliveredShipments;
GO

/*
  Expected Result:
  CTE is suitable for single-use queries.
  Temp Table is better when reusing intermediate result multiple times.
  */

---

-- Indexed vs Non-Indexed Search
====

-- Drop index temporarily (ONLY FOR TESTING)
IF EXISTS (
SELECT 1 FROM sys.indexes
WHERE name = 'IX_Shipments_Status'
)
BEGIN
DROP INDEX IX_Shipments_Status ON Shipments;
END
GO

----- Without Index (Table Scan Expected) -----'

SELECT *
FROM Shipments
WHERE Status = 'Delivered';
GO

-- Recreate index
CREATE NONCLUSTERED INDEX IX_Shipments_Status
ON Shipments(Status);
GO

----- With Index (Index Seek Expected) -----'

SELECT *
FROM Shipments
WHERE Status = 'Delivered';
GO

/*

Before Index:

* Execution Plan: Table Scan
* Higher Logical Reads

After Index:

* Execution Plan: Index Seek
* Lower Logical Reads

Conclusion:
Indexing significantly reduces I/O cost and improves query performance.
*/



/*

Performance Findings Summary:

1. JOIN generally performs better than Subquery in large datasets.
2. CTE is efficient for single-use queries, while Temp Tables are better for repeated usage.
3. Indexing significantly improves search performance by reducing Table Scans and I/O cost.
*/

