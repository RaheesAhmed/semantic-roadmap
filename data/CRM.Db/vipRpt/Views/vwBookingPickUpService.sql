


CREATE VIEW [vipRpt].[vwBookingPickUpService]
AS
SELECT e.wBookingRid,
       e.wCurrCode,
       e.wTotalAmt,
       e.wPaymentMethod
FROM dbo.eBookingPickUpService AS e;