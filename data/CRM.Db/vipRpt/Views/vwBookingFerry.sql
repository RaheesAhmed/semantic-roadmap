


CREATE VIEW [vipRpt].[vwBookingFerry]
AS
SELECT e.wBookingRid,
       e.wCurrCode,
       e.wTotalAmt,
       e.wPaymentMethod
FROM dbo.eBookingFerry AS e;