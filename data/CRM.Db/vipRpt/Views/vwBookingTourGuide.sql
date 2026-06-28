


CREATE VIEW [vipRpt].[vwBookingTourGuide]
AS
SELECT e.wBookingRid,
       e.wCurrCode,
       e.wTotalAmt,
       e.wPaymentMethod
FROM CRM.dbo.eBookingTourGuide AS e;