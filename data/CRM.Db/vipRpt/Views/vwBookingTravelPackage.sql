


CREATE VIEW [vipRpt].[vwBookingTravelPackage]
AS
SELECT e.wBookingRid,
       e.wCurrCode,
       e.wTotalAmt,
       e.wPaymentMethod
FROM dbo.eBookingTravelPackage AS e;