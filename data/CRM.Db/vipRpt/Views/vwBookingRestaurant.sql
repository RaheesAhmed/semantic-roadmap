


CREATE VIEW [vipRpt].[vwBookingRestaurant]
AS
SELECT e.wBookingRid,
       e.wCurrCode,
	   e.wRestaurantRid
FROM dbo.eBookingRestaurant AS e;