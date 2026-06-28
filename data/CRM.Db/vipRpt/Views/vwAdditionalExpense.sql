

CREATE VIEW [vipRpt].[vwAdditionalExpense]
AS
SELECT e.wBookingRefRid,
       e.wCurrcode,
       e.wTotalAmt,
       e.wPaymentMethod
FROM dbo.eAdditionalExpense AS e;