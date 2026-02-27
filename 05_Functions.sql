use LogisticsDB
GO

create function dbo.fn_CalculateDriverBonus 
(@DriverID int)
RETURNS Decimal(10,2)
AS
Begin 

Declare @Bonus Decimal(10,2),
@average_delivery_time Decimal(18,2);
Select
@Bonus=count(s.ShipmentId)*50,
@average_delivery_time= AVG(cast( s.DeliveryDurationHours AS DECIMAL(10,2)))
    FROM Vehicles v
    JOIN Shipments s 
        ON v.VehicleId = s.VehicleId
    WHERE v.AssignedDriverId = @DriverId
      AND s.Status = 'Delivered';
if @average_delivery_time is not null and @average_delivery_time <24
set @Bonus=@Bonus+1000;
return Isnull(@Bonus,0);
End

--------

create Function dbo.fn_GetCustomerShipments(@CustomerId int)
returns Table
AS
Return 
(
 Select s.ShipmentId ,s.Status ,s.Price ,s.DeliveredAt
 from Shipments s 
 where CustomerId =@CustomerId

);
