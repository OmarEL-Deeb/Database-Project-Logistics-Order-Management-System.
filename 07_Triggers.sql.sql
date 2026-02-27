use LogisticsDB
go
CREATE TRIGGER trg_ShipmentDelivered
ON Shipments
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

   
    UPDATE s
    SET DeliveredAt = GETDATE()
    FROM Shipments s
    INNER JOIN inserted i ON s.ShipmentId = i.ShipmentId
    INNER JOIN deleted d ON d.ShipmentId = i.ShipmentId
    WHERE i.Status = 'Delivered'
      AND d.Status <> 'Delivered';

    INSERT INTO ShipmentStatusHistory (ShipmentId, Status, StatusDate)
    SELECT i.ShipmentId, i.Status, GETDATE()
    FROM inserted i
    INNER JOIN deleted d ON d.ShipmentId = i.ShipmentId
    WHERE i.Status = 'Delivered'
      AND d.Status <> 'Delivered';
END;