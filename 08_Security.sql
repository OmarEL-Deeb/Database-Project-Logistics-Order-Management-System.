-- 1) Create SQL Login for ReadOnly
CREATE LOGIN ReadOnlyLogin
WITH PASSWORD = 'StrongPassword123!';
GO

-- 2) Create Database User
USE LogisticsDB;
GO

CREATE USER ReadOnlyUser
FOR LOGIN ReadOnlyLogin;
GO

-- 3) Create ReadOnly Role
CREATE ROLE ReadOnlyRole;
GO

-- 4) Grant SELECT permission
GRANT SELECT ON SCHEMA::dbo TO ReadOnlyRole;
GO

-- Add User to ReadOnly Role
ALTER ROLE ReadOnlyRole
ADD MEMBER ReadOnlyUser;
GO

-- ========================================
-- Driver Role Setup
-- ========================================

-- Create SQL Login for Driver
CREATE LOGIN DriverLogin
WITH PASSWORD = 'DriverPass123!';
GO

-- Create Database User for Driver
USE LogisticsDB;
GO

CREATE USER DriverUser
FOR LOGIN DriverLogin;
GO

-- Create Driver Role
CREATE ROLE DriverRole;
GO

-- Grant limited permissions
GRANT SELECT ON Shipments TO DriverRole;
GRANT UPDATE ON Shipments TO DriverRole;
GO

-- Deny DELETE explicitly
DENY DELETE ON Shipments TO DriverRole;
GO

-- Add DriverUser to DriverRole
ALTER ROLE DriverRole
ADD MEMBER DriverUser;
GO