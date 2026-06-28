




CREATE VIEW [vipRpt].[vwBookingRoom]
AS
SELECT e.RowID,
       e.wBookingRid,
       e.wCurrCode,
       e.wTotalAmount,
       e.wPaymentMethod,
       e.wHotelRid
FROM CRM.dbo.eBookingRoom AS e;