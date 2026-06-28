CREATE PROCEDURE [spq].[GetHotelDailyCheckInRecordByRoombookingId]
    @pRoombookingId BIGINT ,
    @pLangCd VARCHAR(10) = 'en-GB'
AS
    BEGIN  
        SET NOCOUNT ON;
		IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 

        SELECT  CHK.RowID ,
                CHK.wBookingDate ,
                HTL.wName AS wHotelName ,
                CHK.wHotelRid ,
                CHK.wRoomRid ,
                COALESCE(HM.wName, '') AS WRoomName ,
                CHK.wRoomBookingRid ,
                CHK.wAllotmentGroupRid ,
                CHK.wExtraRoom ,
                CHK.wIncludeBreakfast ,
                CHK.wCurrCode ,
                CHK.wAgencyRoom ,
                COALESCE(ALT.wName, '') AS wAllotmentType ,
                CHK.wRoomNo ,
                CHK.wDismiss ,
                CHK.wCost ,
                CHK.wPrice ,
                CHK.wBreakfastPrice,
                CHK.wExtraBedPrice,
                CHK.wExtraBed,
                CHK.wExtent ,
                CHK.wStatus ,
				( CASE WHEN EBR.wBookingStatus = 'P' THEN 'P'
                       ELSE 'C'
                 END ) AS wBookingStatus ,--每日入住記錄狀態 需要分為 「處理中」 及「完成」,房间预订状态为完成,
                --CAST(usr.wName AS VARCHAR(200)) AS wCName ,
				CASE WHEN @pLangCd = 'en-GB' THEN usr.wName
                     ELSE usr.wCName END AS wCName,
                CHK.wUpdDt AS wCrtDt ,
                CAST(CHK.wUpdBy AS BIGINT) AS wUpdBy
        FROM    ( SELECT    *
                  FROM      dbo.eHotelCheckIn
                  WHERE     wRoomBookingRid = @pRoombookingId
                            AND wStatus = 'A'
                ) CHK
                INNER JOIN [dbo].[mHotel] HTL ON HTL.RowID = CHK.wHotelRid
                LEFT JOIN [dbo].[mAllotmentGroup] ALT ON ALT.RowID = CHK.wAllotmentGroupRid
                LEFT JOIN [dbo].[mHotelRoom] HM ON HM.RowID = CHK.wRoomRid
                INNER JOIN dbo.eBookingRoom EBR ON EBR.RowID = CHK.wRoomBookingRid
                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = CHK.wUpdBy
        WHERE   ( ( CHK.wStatus = 'T'
                    AND ( EBR.wBookingStatus = 'RF'
                          OR EBR.wBookingStatus = 'UQ'
                          OR EBR.wBookingStatus = 'CL'
                        )
                  )
                  OR CHK.wStatus = 'A'
                )
        ORDER BY CHK.wBookingDate;
    END;