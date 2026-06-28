

CREATE VIEW [vipRpt].[vwHotelChange]
AS
SELECT e.wBookingRid,
       e.wCurrCode,
       e.wTotalAmount,
       e.wPaymentMethod,
	   e.wRoomBookingRid
FROM dbo.eHotelChange AS e;