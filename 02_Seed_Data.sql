USE LogisticsDB;
GO

-- 1. Insert Countries 
INSERT INTO Countries (Name) VALUES 
('Egypt'), ('Saudi Arabia'), ('United Arab Emirates'), ('United States'), ('Germany');
GO

-- 2. Insert Cities 
-- Matching CountryId with the countries inserted above
INSERT INTO Cities (Name, CountryId) VALUES 
('Cairo', 1), ('Alexandria', 1), 
('Riyadh', 2), ('Jeddah', 2), 
('Dubai', 3), ('Abu Dhabi', 3), 
('New York', 4), ('Los Angeles', 4), 
('Berlin', 5), ('Munich', 5);
GO

-- 3. Insert Warehouses (5+ Warehouses)
INSERT INTO Warehouses (Name, CityId, Capacity) VALUES 
('Cairo Main Hub', 1, 10000),
('Riyadh Central Hub', 3, 15000),
('Dubai Logistics Center', 5, 20000),
('NY Transit Node', 7, 12000),
('Berlin Depot', 9, 8000);
GO

-- 4. Insert Customers (10+ Customers)
INSERT INTO Customers (FullName, Email, Phone) VALUES 
('Ahmed Hassan', 'ahmed@example.com', '01011111111'),
('Mona Ali', 'mona@example.com', '01022222222'),
('Omar Khaled', 'omar@example.com', '01033333333'),
('Sara Youssef', 'sara@example.com', '01044444444'),
('John Smith', 'john@example.com', '12025550101'),
('Emily Davis', 'emily@example.com', '12025550102'),
('Hans Gruber', 'hans@example.com', '49151234567'),
('Anna Muller', 'anna@example.com', '49151234568'),
('Faisal Al-Saud', 'faisal@example.com', '96650000001'),
('Layla Saeed', 'layla@example.com', '97150000002');
GO

-- 5. Insert Drivers (8+ Drivers)
INSERT INTO Drivers (FullName, LicenseNumber, Salary, HireDate) VALUES 
('Khaled Mostafa', 'LIC1001', 5000.00, '2022-01-15'),
('Tariq Ziad', 'LIC1002', 5200.00, '2022-02-20'),
('Yasser Amin', 'LIC1003', 4800.00, '2022-03-10'),
('Michael Scott', 'LIC1004', 5500.00, '2021-11-05'),
('Jim Halpert', 'LIC1005', 4900.00, '2023-01-01'),
('Dwight Schrute', 'LIC1006', 5100.00, '2023-04-12'),
('Klaus Schmidt', 'LIC1007', 5300.00, '2021-08-30'),
('Sami Nabil', 'LIC1008', 5000.00, '2022-09-25');
GO

-- 6. Insert Vehicles (8+ Vehicles)
-- Assigning the 8 drivers to these vehicles
INSERT INTO Vehicles (PlateNumber, Capacity, AssignedDriverId) VALUES 
('EGY-123', 5000.00, 1),
('KSA-987', 4000.00, 2),
('UAE-456', 6000.00, 3),
('USA-111', 5500.00, 4),
('GER-222', 4500.00, 5),
('EGY-333', 5000.00, 6),
('KSA-444', 7000.00, 7),
('UAE-555', 6500.00, 8);
GO

-- 7. Insert Shipments (20 Shipments)
-- Mixing statuses: Pending, InTransit, Delivered, Cancelled
-- Note: 'Delivered' shipments have a 'DeliveredAt' date, others are NULL
INSERT INTO Shipments (CustomerId, OriginWarehouseId, DestinationWarehouseId, VehicleId, Weight, Price, Status, CreatedAt, DeliveredAt) VALUES 
(1, 1, 2, 1, 150.50, 300.00, 'Delivered', '2023-10-01 08:00', '2023-10-03 14:00'),
(2, 2, 3, 2, 200.00, 450.00, 'InTransit', '2023-10-25 09:00', NULL),
(3, 3, 4, 3, 50.00,  120.00, 'Pending',   '2023-10-26 10:00', NULL),
(4, 4, 5, 4, 1000.00,2000.00,'Delivered', '2023-09-15 07:00', '2023-09-20 18:00'),
(5, 5, 1, 5, 25.50,  80.00,  'Cancelled', '2023-10-20 11:00', NULL),
(6, 1, 3, 6, 800.00, 1600.00,'InTransit', '2023-10-24 12:00', NULL),
(7, 2, 4, 7, 450.00, 900.00, 'Delivered', '2023-08-10 09:00', '2023-08-14 16:00'),
(8, 3, 5, 8, 320.00, 640.00, 'Pending',   '2023-10-26 13:00', NULL),
(9, 4, 1, 1, 15.00,  50.00,  'Delivered', '2023-07-01 08:00', '2023-07-05 10:00'),
(10,5, 2, 2, 60.00,  150.00, 'InTransit', '2023-10-23 14:00', NULL),
(1, 1, 4, 3, 110.00, 220.00, 'Delivered', '2023-09-05 08:00', '2023-09-08 12:00'),
(2, 2, 5, 4, 75.00,  180.00, 'Pending',   '2023-10-26 15:00', NULL),
(3, 3, 1, 5, 500.00, 1000.00,'Cancelled', '2023-10-10 09:00', NULL),
(4, 4, 2, 6, 85.00,  190.00, 'Delivered', '2023-06-15 07:00', '2023-06-18 11:00'),
(5, 5, 3, 7, 95.00,  210.00, 'InTransit', '2023-10-22 10:00', NULL),
(6, 1, 5, 8, 120.00, 260.00, 'Pending',   '2023-10-26 16:00', NULL),
(7, 2, 1, 1, 300.00, 600.00, 'Delivered', '2023-05-20 08:00', '2023-05-23 15:00'),
(8, 3, 2, 2, 400.00, 800.00, 'InTransit', '2023-10-25 11:00', NULL),
(9, 4, 3, 3, 50.00,  110.00, 'Cancelled', '2023-10-18 09:00', NULL),
(10,5, 4, 4, 130.00, 290.00, 'Delivered', '2023-04-10 07:00', '2023-04-15 14:00');
GO

-- 8. Insert Payments
-- Creating a 1-to-1 relationship with the 20 shipments for realistic data
INSERT INTO Payments (ShipmentId, Amount, PaymentMethod, IsPaid, PaidDate) VALUES 
(1,  300.00, 'Card',    1, '2023-10-01 08:05'),
(2,  450.00, 'Transfer',0, NULL),
(3,  120.00, 'Cash',    0, NULL),
(4, 2000.00, 'Transfer',1, '2023-09-15 07:30'),
(5,   80.00, 'Card',    0, NULL),
(6, 1600.00, 'Transfer',1, '2023-10-24 12:15'),
(7,  900.00, 'Card',    1, '2023-08-10 09:10'),
(8,  640.00, 'Transfer',0, NULL),
(9,   50.00, 'Cash',    1, '2023-07-05 10:00'), 
(10, 150.00, 'Card',    1, '2023-10-23 14:05'),
(11, 220.00, 'Transfer',1, '2023-09-05 08:10'),
(12, 180.00, 'Card',    0, NULL),
(13,1000.00, 'Transfer',0, NULL),
(14, 190.00, 'Card',    1, '2023-06-15 07:05'),
(15, 210.00, 'Transfer',0, NULL),
(16, 260.00, 'Card',    0, NULL),
(17, 600.00, 'Transfer',1, '2023-05-20 08:30'),
(18, 800.00, 'Card',    1, '2023-10-25 11:05'),
(19, 110.00, 'Cash',    0, NULL),
(20, 290.00, 'Transfer',1, '2023-04-10 07:15');
GO

-- 9. Insert ShipmentStatusHistory
-- Tracking lifecycle for a few shipments to test analytical queries later
INSERT INTO ShipmentStatusHistory (ShipmentId, StatusDate, Status) VALUES 
-- Shipment 1 (Delivered Process)
(1, '2023-10-01 08:00', 'Pending'),
(1, '2023-10-01 14:00', 'InTransit'),
(1, '2023-10-03 14:00', 'Delivered'),
-- Shipment 2 (In Transit Process)
(2, '2023-10-25 09:00', 'Pending'),
(2, '2023-10-25 15:00', 'InTransit'),
-- Shipment 3 (Pending Process)
(3, '2023-10-26 10:00', 'Pending'),
-- Shipment 4 (Delivered Process)
(4, '2023-09-15 07:00', 'Pending'),
(4, '2023-09-17 10:00', 'InTransit'),
(4, '2023-09-20 18:00', 'Delivered'),
-- Shipment 5 (Cancelled Process)
(5, '2023-10-20 11:00', 'Pending'),
(5, '2023-10-20 12:00', 'Cancelled');
GO