


CREATE VIEW [vipRpt].[vwBookingCheckInService]
AS
SELECT e.wBookingRid,
       e.wCurrCode,
       e.wTotalAmt,
       e.wPaymentMethod
FROM dbo.eBookingCheckInService AS e;