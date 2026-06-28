


CREATE VIEW [vipRpt].[vwBookingHeli]
AS
SELECT e.wBookingRid,
       e.wCurrCode,
       e.wTotalAmt,
       e.wPaymentMethod
FROM dbo.eBookingHeli AS e;