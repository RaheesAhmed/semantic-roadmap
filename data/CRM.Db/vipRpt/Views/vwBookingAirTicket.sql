


CREATE VIEW [vipRpt].[vwBookingAirTicket]
AS
SELECT e.wBookingRid,
       e.wCurrCode,
       e.wTotalAmt,
       e.wPaymentMethod
FROM dbo.eBookingAirTicket AS e;