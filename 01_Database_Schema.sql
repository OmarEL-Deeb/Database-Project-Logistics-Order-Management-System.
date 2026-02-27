-- 1. Create the Database
CREATE DATABASE LogisticsDB;
GO

USE LogisticsDB;
GO

-- 2. Countries Table
CREATE TABLE Countries (
    CountryId INT IDENTITY(1,1) PRIMARY KEY, -- Clustered Index by default
    Name NVARCHAR(100) NOT NULL UNIQUE
);
GO

-- 3. Cities Table
CREATE TABLE Cities (
    CityId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    CountryId INT NOT NULL,
    CONSTRAINT FK_Cities_Countries FOREIGN KEY (CountryId) REFERENCES Countries(CountryId)
);
GO

-- Index for Performance & Uniqueness on Composite columns
CREATE UNIQUE NONCLUSTERED INDEX UIX_Cities_Name_Country 
ON Cities(Name, CountryId);
GO

-- 4. EmployeeRoles Table
CREATE TABLE EmployeeRoles (
    RoleId INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(100) NOT NULL UNIQUE
);
GO

-- 5. Warehouses Table
CREATE TABLE Warehouses (
    WarehouseId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(150) NOT NULL,
    CityId INT NOT NULL,
    Capacity INT CHECK (Capacity > 0),
    CreatedAt DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Warehouses_Cities FOREIGN KEY (CityId) REFERENCES Cities(CityId)
);
GO
-- Index on CityId for faster filtering by location
CREATE NONCLUSTERED INDEX IX_Warehouses_CityId ON Warehouses(CityId);
GO

-- 6. Customers Table
CREATE TABLE Customers (
    CustomerId INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(150) NOT NULL,
    Email NVARCHAR(150) NOT NULL UNIQUE,
    Phone NVARCHAR(20) NOT NULL UNIQUE,
    CreatedDate DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1
);
GO

-- 7. Drivers Table
CREATE TABLE Drivers (
    DriverId INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(150) NOT NULL,
    LicenseNumber NVARCHAR(100) NOT NULL UNIQUE,
    Salary DECIMAL(18,2) CHECK (Salary > 0),
    HireDate DATE,
    IsActive BIT DEFAULT 1
);
GO

-- 8. Vehicles Table
CREATE TABLE Vehicles (
    VehicleId INT IDENTITY(1,1) PRIMARY KEY,
    PlateNumber NVARCHAR(50) NOT NULL UNIQUE,
    Capacity DECIMAL(10,2) CHECK (Capacity > 0),
    AssignedDriverId INT NULL, -- Nullable as a vehicle might not have a driver currently
    IsActive BIT DEFAULT 1,
    CONSTRAINT FK_Vehicles_Drivers FOREIGN KEY (AssignedDriverId) REFERENCES Drivers(DriverId)
);
GO

-- 9. Employees Table
CREATE TABLE Employees (
    EmployeeId INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(150) NOT NULL,
    WarehouseId INT NOT NULL,
    RoleId INT NOT NULL,
    Salary DECIMAL(18,2) CHECK (Salary > 0),
    HireDate DATE,
    CONSTRAINT FK_Employees_Warehouses FOREIGN KEY (WarehouseId) REFERENCES Warehouses(WarehouseId),
    CONSTRAINT FK_Employees_Roles FOREIGN KEY (RoleId) REFERENCES EmployeeRoles(RoleId)
);
GO
-- 10. Shipments Table
CREATE TABLE Shipments (
    ShipmentId INT IDENTITY(1,1) PRIMARY KEY,
    CustomerId INT NOT NULL,
    OriginWarehouseId INT NOT NULL,
    DestinationWarehouseId INT NOT NULL,
    VehicleId INT NOT NULL,
    Weight DECIMAL(10,2) CHECK (Weight > 0),
    Price DECIMAL(18,2) CHECK (Price > 0),
    Status NVARCHAR(50) CHECK (Status IN ('Pending', 'InTransit', 'Delivered', 'Cancelled')),
    CreatedAt DATETIME DEFAULT GETDATE(),
    DeliveredAt DATETIME NULL,
    
    -- Computed Column: Calculates duration automatically
    DeliveryDurationHours AS DATEDIFF(HOUR, CreatedAt, DeliveredAt),

    -- Foreign Keys & Cascades
    CONSTRAINT FK_Shipments_Customers FOREIGN KEY (CustomerId) 
        REFERENCES Customers(CustomerId) ON DELETE CASCADE, -- If Customer is deleted, delete their shipments
    
    CONSTRAINT FK_Shipments_Origin FOREIGN KEY (OriginWarehouseId) 
        REFERENCES Warehouses(WarehouseId),
    
    CONSTRAINT FK_Shipments_Destination FOREIGN KEY (DestinationWarehouseId) 
        REFERENCES Warehouses(WarehouseId), -- Usually distinct from Origin, logic handled in App/Trigger
    
    CONSTRAINT FK_Shipments_Vehicles FOREIGN KEY (VehicleId) 
        REFERENCES Vehicles(VehicleId)
);
GO

-- Indexes for frequent search queries
CREATE NONCLUSTERED INDEX IX_Shipments_Status ON Shipments(Status);
CREATE NONCLUSTERED INDEX IX_Shipments_CustomerId ON Shipments(CustomerId);
GO

-- 11. ShipmentStatusHistory Table
CREATE TABLE ShipmentStatusHistory (
    ShipmentId INT NOT NULL,
    StatusDate DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(50) NOT NULL,
    
    -- Composite Primary Key (Clustered by default)
    CONSTRAINT PK_ShipmentStatusHistory PRIMARY KEY (ShipmentId, StatusDate),
    
    -- Foreign Key with Cascade Delete
    CONSTRAINT FK_History_Shipments FOREIGN KEY (ShipmentId) 
        REFERENCES Shipments(ShipmentId) ON DELETE CASCADE
);
GO

-- 12. Payments Table
CREATE TABLE Payments (
    PaymentId INT IDENTITY(1,1) PRIMARY KEY,
    ShipmentId INT NOT NULL,
    Amount DECIMAL(18,2) CHECK (Amount > 0),
    PaymentMethod NVARCHAR(50) CHECK (PaymentMethod IN ('Cash', 'Card', 'Transfer')),
    IsPaid BIT DEFAULT 0,
    PaidDate DATETIME NULL,
    
    -- Foreign Key with Cascade Delete
    CONSTRAINT FK_Payments_Shipments FOREIGN KEY (ShipmentId) 
        REFERENCES Shipments(ShipmentId) ON DELETE CASCADE
);
GO
-- Index to quickly find unpaid shipments
CREATE NONCLUSTERED INDEX IX_Payments_IsPaid ON Payments(IsPaid) INCLUDE (Amount, ShipmentId);
GO

CREATE NONCLUSTERED INDEX IX_Drivers_IsActive
ON Drivers(IsActive);
GO
CREATE NONCLUSTERED INDEX IX_Vehicles_AssignedDriverId
ON Vehicles(AssignedDriverId);
GO