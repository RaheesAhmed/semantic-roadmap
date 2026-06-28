
CREATE PROCEDURE [spq].[GetAllotmentHotelDaily]
	@pRowID BIGINT
AS
BEGIN
    SET NOCOUNT ON;	  	
				
    IF @@trancount = 0
        SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
    SELECT 
		ahd_t.RowId, 
		ahd_t.wRoomRid, 
		ahd_t.wAllotmentGroupRid, 
		ahd_t.wDate, 
		ahd_t.wAllotmentQty, 
		ahd_t.wExtraQty, 
		ahd_t.wBookedQty, 
		ahd_t.wCurrCode, 
		ahd_t.wRoomPrice, 
		ahd_t.wBreakfastPrice, 
		ahd_t.wRoomCost, 
		ahd_t.wIsCustomized, 
		ahd_t.wStatus, 
		ahd_t.wCrtDt, 
		ahd_t.wCrtBy, 
		ahd_t.wUpdDt, 
		ahd_t.wUpdBy
	FROM dbo.eAllotmentHotelDaily ahd_t
	WHERE @pRowID = ahd_t.RowID                                                 
END;