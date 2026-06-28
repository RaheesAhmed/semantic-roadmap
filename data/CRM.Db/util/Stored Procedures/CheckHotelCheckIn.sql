CREATE PROCEDURE [util].[CheckHotelCheckIn] @pUpdateData CHAR(1) -- 'Y'/'N' -> 'Y':Create Directly
AS
    BEGIN
;
        SET NOCOUNT ON;	  	
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;   
			
        WITH    cteRoomData
                  AS ( SELECT   hci.RowID AS wHotelCheckInRid ,
                                hci.wPrice AS wCheckInPrice ,
                                ( ahd.wRoomPrice
                                  + CASE WHEN hci.wIncludeBreakfast = 'Y'
                                         THEN ahd.wBreakfastPrice
                                         ELSE 0
                                    END ) AS wAllotmentPrice ,
                                hci.wCost AS wCheckInCost ,
                                ( ahd.wRoomCost
                                  + CASE WHEN hci.wIncludeBreakfast = 'Y'
                                         THEN ahd.wBreakfastPrice
                                         ELSE 0
                                    END ) AS wAllotmentCost ,
                                hci.wRoomRid ,
                                hci.wAllotmentGroupRid ,
                                hci.wBookingDate ,
                                hci.wIncludeBreakfast ,
                                ahd.wBreakfastPrice
                       FROM     dbo.eHotelCheckIn hci
                                INNER JOIN dbo.eAllotmentHotelDaily ahd ON hci.wRoomRid = ahd.wRoomRid
                                                              AND hci.wAllotmentGroupRid = ahd.wAllotmentGroupRid
                                                              AND hci.wBookingDate = ahd.wDate
                     )
            SELECT  *
            INTO    #TempRecalHotelCheckIn
            FROM    cteRoomData cteRD
            WHERE   cteRD.wCheckInPrice <> cteRD.wAllotmentPrice
                    OR cteRD.wCheckInCost <> cteRD.wAllotmentCost;

        SELECT  *
        FROM    #TempRecalHotelCheckIn;

        IF @pUpdateData = 'Y'
            BEGIN
				-----------Recal HotelCheckIn-------------				 
                UPDATE  hci
                SET     hci.wPrice = temp.wAllotmentPrice ,
                        hci.wCost = temp.wAllotmentCost
                FROM    dbo.eHotelCheckIn hci
                        INNER JOIN #TempRecalHotelCheckIn temp ON hci.RowID = temp.wHotelCheckInRid
                WHERE   hci.wPrice <> temp.wAllotmentPrice
                        AND hci.wCost <> temp.wAllotmentCost;
							

            END;

        IF OBJECT_ID('tempdb..#TempRecalHotelCheckIn') IS NOT NULL
            DROP TABLE #TempRecalHotelCheckIn;         
    END;