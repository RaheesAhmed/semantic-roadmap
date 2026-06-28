


CREATE VIEW [vipRpt].[vwBookingVisa]
AS
SELECT e.wBookingRid,
       e.wCurrCode,
       e.wTotalAmt,
       e.wPaymentMethod
FROM dbo.eBookingVisa AS e;