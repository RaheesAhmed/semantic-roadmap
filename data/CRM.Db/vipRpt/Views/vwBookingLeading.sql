


CREATE VIEW [vipRpt].[vwBookingLeading]
AS
	  SELECT e.wBookingRid, e.wCurrCode, e.wTotalAmt, e.wPaymentMethod FROM dbo.eBookingLeading AS e