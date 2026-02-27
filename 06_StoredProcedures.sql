use LogisticsDB
Go
--CreateShipment
CREATE PROCEDURE sp_CreateShipment
    @CustomerId INT,
    @OriginWarehouseId INT,
    @DestinationWarehouseId INT,
    @VehicleId INT,
    @Weight DECIMAL(10,2),
    @Price DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
     
        IF @Weight <= 0
        BEGIN
            THROW 50001, 'Weight must be greater than 0.', 1;
        END

        IF @Price <= 0
        BEGIN
            THROW 50002, 'Price must be greater than 0.', 1;
        END

    
        IF NOT EXISTS (SELECT 1 FROM Customers WHERE CustomerId = @CustomerId AND IsActive = 1)
        BEGIN
            THROW 50003, 'Customer does not exist or is inactive.', 1;
        END

        
        IF NOT EXISTS (SELECT 1 FROM Warehouses WHERE WarehouseId = @OriginWarehouseId)
        BEGIN
            THROW 50004, 'Origin warehouse does not exist.', 1;
        END

        
        IF NOT EXISTS (SELECT 1 FROM Warehouses WHERE WarehouseId = @DestinationWarehouseId)
        BEGIN
            THROW 50005, 'Destination warehouse does not exist.', 1;
        END

        IF NOT EXISTS (SELECT 1 FROM Vehicles WHERE VehicleId = @VehicleId AND IsActive = 1)
        BEGIN
            THROW 50006, 'Vehicle does not exist or is inactive.', 1;
        END
        BEGIN TRANSACTION;


        INSERT INTO Shipments 
            (CustomerId, OriginWarehouseId, DestinationWarehouseId, VehicleId, Weight, Price, Status, CreatedAt)
        VALUES
            (@CustomerId, @OriginWarehouseId, @DestinationWarehouseId, @VehicleId, @Weight, @Price, 'Pending', GETDATE());

        DECLARE @NewShipmentId INT = SCOPE_IDENTITY();

        
        INSERT INTO ShipmentStatusHistory (ShipmentId, Status, StatusDate)
        VALUES (@NewShipmentId, 'Pending', GETDATE());

      
        COMMIT TRANSACTION;

       
        SELECT @NewShipmentId AS ShipmentId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
DECLARE @NewShipmentId INT;
--
EXEC sp_CreateShipment
    @CustomerId = 1,
    @OriginWarehouseId = 2,
    @DestinationWarehouseId = 3,
    @VehicleId = 5,
    @Weight = 120.5,
    @Price = 350.75;
	GO
--sp_UpdateShipmentStatus

CREATE PROCEDURE sp_UpdateShipmentStatus
    @ShipmentId INT,
    @NewStatus NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        
        IF @NewStatus NOT IN ('Pending','InTransit','Delivered','Cancelled')
            THROW 50010, 'Invalid status value.', 1;

        IF NOT EXISTS (SELECT 1 FROM Shipments WHERE ShipmentId = @ShipmentId)
            THROW 50011, 'Shipment does not exist.', 1;

        BEGIN TRANSACTION;

        UPDATE Shipments
        SET Status = @NewStatus,
            DeliveredAt = CASE WHEN @NewStatus = 'Delivered' THEN GETDATE() ELSE DeliveredAt END
        WHERE ShipmentId = @ShipmentId;

        INSERT INTO ShipmentStatusHistory (ShipmentId, Status, StatusDate)
        VALUES (@ShipmentId, @NewStatus, GETDATE());

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
---- --PayShipment
CREATE PROCEDURE sp_PayShipment
    @ShipmentId INT,
    @Amount DECIMAL(18,2),
    @PaymentMethod NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @Amount <= 0
            THROW 50020, 'Amount must be greater than 0.', 1;

        IF @PaymentMethod NOT IN ('Cash','Card','Transfer')
            THROW 50021, 'Invalid payment method.', 1;

        IF NOT EXISTS (SELECT 1 FROM Shipments WHERE ShipmentId = @ShipmentId)
            THROW 50022, 'Shipment does not exist.', 1;

        BEGIN TRANSACTION;

        INSERT INTO Payments (ShipmentId, Amount, PaymentMethod, IsPaid, PaidDate)
        VALUES (@ShipmentId, @Amount, @PaymentMethod, 1, GETDATE());
        EXEC sp_UpdateShipmentStatus @ShipmentId = @ShipmentId, @NewStatus = 'Delivered';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
---GetRevenueReport
CREATE PROCEDURE sp_GetRevenueReport
    @StartDate DATETIME,
    @EndDate DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT 
            SUM(p.Amount) AS TotalRevenue,
            COUNT(DISTINCT s.ShipmentId) AS TotalShipments,
            SUM(CASE WHEN s.Status='Delivered' THEN p.Amount ELSE 0 END) AS RevenueDelivered
        FROM Payments p
        JOIN Shipments s ON p.ShipmentId = s.ShipmentId
        WHERE p.PaidDate BETWEEN @StartDate AND @EndDate;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END

GO
---AssignVehicleToDriver
CREATE PROCEDURE sp_AssignVehicleToDriver
    @VehicleId INT,
    @DriverId INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Vehicles WHERE VehicleId = @VehicleId AND IsActive = 1)
            THROW 50030, 'Vehicle does not exist or inactive.', 1;

        IF NOT EXISTS (SELECT 1 FROM Drivers WHERE DriverId = @DriverId AND IsActive = 1)
            THROW 50031, 'Driver does not exist or inactive.', 1;

        BEGIN TRANSACTION;

        -- Assign driver
        UPDATE Vehicles
        SET AssignedDriverId = @DriverId
        WHERE VehicleId = @VehicleId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
--DeactivateCustomer
CREATE PROCEDURE sp_DeactivateCustomer
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Customers WHERE CustomerId = @CustomerId)
            THROW 50040, 'Customer does not exist.', 1;

        -- Check for unpaid shipments
        IF EXISTS (
            SELECT 1 FROM Shipments s
            LEFT JOIN Payments p ON s.ShipmentId = p.ShipmentId
            WHERE s.CustomerId = @CustomerId AND (p.IsPaid IS NULL OR p.IsPaid = 0)
        )
        BEGIN
            THROW 50041, 'Customer has unpaid shipments, cannot deactivate.', 1;
        END

        BEGIN TRANSACTION;

        -- Deactivate customer
        UPDATE Customers
        SET IsActive = 0
        WHERE CustomerId = @CustomerId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END