CREATE FUNCTION [dbo].[fnGetBookingTypeName]
(
    @pBookingType varchar(30)
)
RETURNS NVARCHAR(500)
AS
BEGIN
    DECLARE @vName NVARCHAR(500);
    SET @vName =  CASE @pBookingType
                        WHEN 'ADDITIONALEXPENSES' THEN N'其它消費'
                        WHEN 'HOTEL'			THEN N'酒店'
                        WHEN 'ROOM'				THEN N'房間'
                        WHEN 'CHANGEHOTEL'		THEN N'房間'
                        WHEN 'FERRY'			THEN N'船票'
                        WHEN 'AIRTICKET'		THEN N'機票'
                        WHEN 'HELI'				THEN N'直升機票'
                        WHEN 'SHOWTICKET'		THEN N'門票'
                        WHEN 'PP'				THEN N'私人飛機票'
                        WHEN 'CHK_IN_SVC'		THEN N'流動登機服務'
                        WHEN 'Visa'				THEN N'簽證'
                        WHEN 'PickUp_SERVICE'	THEN N'機場貴賓服務'
                        WHEN 'LEADING_SERVICE'	THEN N'警察開路'
                        WHEN 'TOUR'				THEN N'導遊'
                        WHEN 'TRAVEL_PACKAGE'   THEN N'旅遊套票'
                        WHEN 'RESTAURANT'       THEN N'餐廳'
                    ELSE UPPER(@pBookingType) END;
    RETURN @vName;
END
