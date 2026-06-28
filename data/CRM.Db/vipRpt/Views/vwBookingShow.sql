


CREATE VIEW [vipRpt].[vwBookingShow]
AS
SELECT e.wBookingRid,
       e.wCurrCode,
       e.wTotalAmt,
       e.wPaymentMethod
FROM dbo.eBookingShow AS e;