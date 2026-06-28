
CREATE PROCEDURE [spq].[GetHotelCheckInLstByHotelChangeRid]
    @pHotelChangeRid BIGINT ,
	@pRoomBookingRid BIGINT,
    @pLangCd VARCHAR(10) = 'en-GB'
AS
    BEGIN  
        SET NOCOUNT ON;
		IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 

        SELECT chk.RowID,
               chk.wBookingDate,
               htl.wName AS wHotelName,
               chk.wHotelRid,
               chk.wRoomRid,
               COALESCE(HM.wName, '') AS WRoomName,
               chk.wRoomBookingRid,
               chk.wAllotmentGroupRid,
               chk.wExtraRoom,
               chk.wIncludeBreakfast,
               chk.wCurrCode,
               chk.wAgencyRoom,
               COALESCE(ALT.wName, '') AS wAllotmentType ,
               wRoomNo = IIF(@pHotelChangeRid <= 0, ebr.wRoomNo, chk.wRoomNo),
               chk.wDismiss,
               chk.wCost,
               chk.wPrice,
               chk.wBreakfastPrice,
               chk.wExtraBedPrice,
               chk.wExtraBed,
               chk.wExtent,
               chk.wStatus,
			   CASE WHEN @pLangCd = 'en-GB' THEN usr.wName ELSE usr.wCName END AS wCName,
               chk.wUpdDt AS wCrtDt,
               chk.wUpdBy,
			   CAST (1 AS BIT) AS wOldRecord
        FROM (SELECT *  FROM dbo.eHotelCheckIn WHERE wRoomBookingRid = @pRoomBookingRid AND ((@pHotelChangeRid <= 0 AND wStatus = 'A') OR (@pHotelChangeRid > 0 AND wHotelChangeRid = @pHotelChangeRid))) chk
        INNER JOIN [dbo].[mHotel] htl ON htl.RowID = chk.wHotelRid
		INNER JOIN dbo.eBookingRoom ebr ON ebr.RowID = chk.wRoomBookingRid
        LEFT JOIN [dbo].[mAllotmentGroup] ALT ON ALT.RowID = chk.wAllotmentGroupRid
        LEFT JOIN [dbo].[mHotelRoom] HM ON HM.RowID = chk.wRoomRid
        LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = chk.wUpdBy
        ORDER BY chk.wBookingDate;
    END;