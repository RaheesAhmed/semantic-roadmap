


CREATE VIEW [vipRpt].[vwBookingPrivatePlane]
AS
SELECT e.wBookingRid,
       e.wCurrCode,
       e.wTotalAmt,
       e.wPaymentMethod
FROM dbo.eBookingPrivatePlane AS e;