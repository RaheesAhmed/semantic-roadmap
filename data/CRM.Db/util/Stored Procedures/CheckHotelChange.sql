CREATE PROCEDURE [util].[CheckHotelChange] @pUpdateData CHAR(1), -- 'Y'/'N' -> 'Y':Create Directly
	@pHotelChangeRidString NVARCHAR(MAX)
AS
    BEGIN
;
        SET NOCOUNT ON;	  	
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;   
			
        WITH    cteCustomizedAllotment
                  AS ( SELECT   wRoomRid ,
                                wDate ,
                                wRoomPrice ,
                                wRoomCost ,
                                wBreakfastPrice ,
                                wAllotmentGroupRid
                       FROM     eAllotmentHotelDaily
                       WHERE    wIsCustomized = 'Y'
                                AND wStatus = 'A'
                     ),
                cteAllotment
                  AS ( SELECT   ahd.wRoomRid ,
                                ahd.wDate ,
                                ahd.wRoomPrice ,
                                ahd.wRoomCost ,
                                ahd.wBreakfastPrice ,
                                ahd.wAllotmentGroupRid
                       FROM     eAllotmentHotelDaily ahd
                                INNER JOIN cteCustomizedAllotment cteCA ON ahd.wRoomRid <> cteCA.wRoomRid
                                                              AND ahd.wDate <> cteCA.wDate
                                                              AND ahd.wRoomPrice <> cteCA.wRoomPrice
                                                              AND wStatus = 'A'
                       UNION
                       SELECT   wRoomRid ,
                                wDate ,
                                wRoomPrice ,
                                wRoomCost ,
                                wBreakfastPrice ,
                                wAllotmentGroupRid
                       FROM     cteCustomizedAllotment
                     )
            SELECT  hc.RowID ,                    
                    br.wCrtDt ,
                    hc.wAction ,            
                    hc.wAmountChange ,
                    ISNULL(( CASE WHEN DATEDIFF(DAY, hc.wNewStartDate,  --提前入住
                                                hc.wOriStartDate) > 0
                                  THEN ( SELECT SUM(cteA.wRoomPrice)
                                                + ( CASE WHEN br.wIncludeBreakfast = 'Y'
                                                         THEN SUM(cteA.wBreakfastPrice)
                                                         ELSE 0
                                                    END )
                                         FROM   cteAllotment cteA
                                         WHERE  hc.wOriStartDate > cteA.wDate
                                                AND hc.wNewStartDate <= cteA.wDate
                                                AND cteA.wRoomRid = br.wHotelRoomRid
                                                AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                                       )
                                  ELSE ( SELECT -1 * SUM(cteA.wRoomPrice)  --延遲入住
                                         FROM   cteAllotment cteA
                                         WHERE  hc.wNewStartDate > cteA.wDate
                                                AND hc.wOriStartDate <= cteA.wDate
                                                AND cteA.wRoomRid = br.wHotelRoomRid
                                                AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                                       )
                             END ), 0)
                    + ISNULL(( CASE WHEN DATEDIFF(DAY, hc.wOriEndDate,
                                                  hc.wNewEndDate) > 0 --延遲交房
                                         THEN ( SELECT  SUM(cteA.wRoomPrice)
                                                        + ( CASE
                                                              WHEN br.wIncludeBreakfast = 'Y'
                                                              THEN SUM(cteA.wBreakfastPrice)
                                                              ELSE 0
                                                            END )
                                                FROM    cteAllotment cteA
                                                WHERE   hc.wNewEndDate > cteA.wDate
                                                        AND hc.wOriEndDate <= cteA.wDate
                                                        AND cteA.wRoomRid = br.wHotelRoomRid
                                                        AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                                              )                          
                                    ELSE (CASE WHEN hc.wAction = 'RF' 
											THEN 0 
											ELSE  (SELECT   -1 * SUM(cteA.wRoomPrice) --提早交房
												   FROM     cteAllotment cteA
												   WHERE    hc.wOriEndDate > cteA.wDate
															AND hc.wNewEndDate <= cteA.wDate
															AND cteA.wRoomRid = br.wHotelRoomRid
															AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid)
											END
                                         )
                               END ), 0)
                    + ISNULL(CASE WHEN hc.wAction = 'RF'
                                  THEN ( SELECT -1 * ( SUM(cteA.wRoomPrice)
                                                       + ( CASE
                                                              WHEN br.wIncludeBreakfast = 'Y'
                                                              THEN SUM(cteA.wBreakfastPrice)
                                                              ELSE 0
                                                           END ) )
                                         FROM   cteAllotment cteA
                                         WHERE  hc.wOriEndDate > cteA.wDate
                                                AND hc.wOriStartDate <= cteA.wDate
                                                AND cteA.wRoomRid = br.wHotelRoomRid
                                                AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                                       )
                                  ELSE 0
                             END, 0) AS wSupposedAmount ,
                    hc.wCostChange ,
                    ISNULL(( CASE WHEN DATEDIFF(DAY, hc.wNewStartDate,  --提前入住
                                                hc.wOriStartDate) > 0
                                  THEN ( SELECT SUM(cteA.wRoomCost)
                                         FROM   cteAllotment cteA
                                         WHERE  hc.wOriStartDate > cteA.wDate
                                                AND hc.wNewStartDate <= cteA.wDate
                                                AND cteA.wRoomRid = br.wHotelRoomRid
                                                AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                                       )
                                  ELSE ( SELECT -1 * SUM(cteA.wRoomCost)  --延遲入住
                                         FROM   cteAllotment cteA
                                         WHERE  hc.wNewStartDate > cteA.wDate
                                                AND hc.wOriStartDate <= cteA.wDate
                                                AND cteA.wRoomRid = br.wHotelRoomRid
                                                AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                                       )
                             END ), 0)
                    + ISNULL(( CASE WHEN DATEDIFF(DAY, hc.wOriEndDate,
                                                  hc.wNewEndDate) > 0 --延遲交房
                                         THEN ( SELECT  SUM(cteA.wRoomCost)
                                                FROM    cteAllotment cteA
                                                WHERE   hc.wNewEndDate > cteA.wDate
                                                        AND hc.wOriEndDate <= cteA.wDate
                                                        AND cteA.wRoomRid = br.wHotelRoomRid
                                                        AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                                              )
                                    ELSE ( CASE WHEN hc.wAction = 'RF' 
											THEN 0 
											ELSE  ( SELECT   -1 * SUM(cteA.wRoomCost) --提早交房
												   FROM     cteAllotment cteA
												   WHERE    hc.wOriEndDate > cteA.wDate
															AND hc.wNewEndDate <= cteA.wDate
															AND cteA.wRoomRid = br.wHotelRoomRid
															AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid)
											END
                                         )
                               END ), 0)
                    + ISNULL(CASE WHEN hc.wAction = 'RF'
                                  THEN ( SELECT -1 * ( SUM(cteA.wRoomCost)
                                                       + ( CASE
                                                              WHEN br.wIncludeBreakfast = 'Y'
                                                              THEN SUM(cteA.wBreakfastPrice)
                                                              ELSE 0
                                                           END ) )
                                         FROM   cteAllotment cteA
                                         WHERE  hc.wOriEndDate > cteA.wDate
                                                AND hc.wOriStartDate <= cteA.wDate
                                                AND cteA.wRoomRid = br.wHotelRoomRid
                                                AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                                       )
                                  ELSE 0
                             END, 0) AS wSupposedCostChange ,
                    hc.wTotalAmount ,
                    ISNULL(( SELECT SUM(cteA.wRoomPrice)
                                    + ( CASE WHEN br.wIncludeBreakfast = 'Y'
                                             THEN SUM(cteA.wBreakfastPrice)
                                             ELSE 0
                                        END )
                             FROM   cteAllotment cteA
                             WHERE  hc.wNewEndDate > cteA.wDate
                                    AND hc.wNewStartDate <= cteA.wDate
                                    AND cteA.wRoomRid = br.wHotelRoomRid
                                    AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                           ), 0) AS wSupposedTotalAmount ,
                    hc.wTotalCost ,
                    ISNULL(( SELECT SUM(cteA.wRoomCost)
                             FROM   cteAllotment cteA
                             WHERE  hc.wNewEndDate > cteA.wDate
                                    AND hc.wNewStartDate <= cteA.wDate
                                    AND cteA.wRoomRid = br.wHotelRoomRid
                                    AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                           ), 0) AS wSupposedTotalCost ,
                    br.wIncludeBreakfast ,
                    h.wName AS wHotelName ,
                    hr.wName AS wRoomName ,
                    hc.wOriStartDate ,
                    hc.wNewStartDate ,
                    hc.wOriEndDate ,
                    hc.wNewEndDate ,
                    br.wAllotmentGroupRid ,
                    br.wHotelRoomRid
            INTO    #TempRecalHotelChange
            FROM    dbo.eHotelChange hc
                    INNER JOIN dbo.eBookingRoom br ON hc.wRoomBookingRid = br.RowID        
                    INNER JOIN dbo.mHotel h ON h.RowID = br.wHotelRid
                    INNER JOIN dbo.mHotelRoom hr ON hr.RowID = br.wHotelRoomRid
            WHERE   ( ISNULL(( CASE WHEN DATEDIFF(DAY, hc.wNewStartDate,  --提前入住
                                                  hc.wOriStartDate) > 0
                                    THEN ( SELECT   SUM(cteA.wRoomPrice)
                                                    + ( CASE WHEN br.wIncludeBreakfast = 'Y'
                                                             THEN SUM(cteA.wBreakfastPrice)
                                                             ELSE 0
                                                        END )
                                           FROM     cteAllotment cteA
                                           WHERE    hc.wOriStartDate > cteA.wDate
                                                    AND hc.wNewStartDate <= cteA.wDate
                                                    AND cteA.wRoomRid = br.wHotelRoomRid
                                                    AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                                         )
                                    ELSE ( SELECT   -1 * SUM(cteA.wRoomPrice)  --延遲入住
                                           FROM     cteAllotment cteA
                                           WHERE    hc.wNewStartDate > cteA.wDate
                                                    AND hc.wOriStartDate <= cteA.wDate
                                                    AND cteA.wRoomRid = br.wHotelRoomRid
                                                    AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                                         )
                               END ), 0)
                      + ISNULL(( CASE WHEN DATEDIFF(DAY, hc.wOriEndDate,
                                                    hc.wNewEndDate) > 0 --延遲交房
                                           THEN ( SELECT    SUM(cteA.wRoomPrice)
                                                            + ( CASE
                                                              WHEN br.wIncludeBreakfast = 'Y'
                                                              THEN SUM(cteA.wBreakfastPrice)
                                                              ELSE 0
                                                              END )
                                                  FROM      cteAllotment cteA
                                                  WHERE     hc.wNewEndDate > cteA.wDate
                                                            AND hc.wOriEndDate <= cteA.wDate
                                                            AND cteA.wRoomRid = br.wHotelRoomRid
                                                            AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                                                )
                                      ELSE ( CASE WHEN hc.wAction = 'RF' 
											THEN 0 
											ELSE  (SELECT -1 * SUM(cteA.wRoomPrice) --提早交房
													 FROM   cteAllotment cteA
													 WHERE  hc.wOriEndDate > cteA.wDate
															AND hc.wNewEndDate <= cteA.wDate
															AND cteA.wRoomRid = br.wHotelRoomRid
															AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid)
											END
                                           )
                                 END ), 0)
                      + ISNULL(CASE WHEN hc.wAction = 'RF'
                                    THEN ( SELECT   -1 * ( SUM(cteA.wRoomPrice)
                                                           + ( CASE
                                                              WHEN br.wIncludeBreakfast = 'Y'
                                                              THEN SUM(cteA.wBreakfastPrice)
                                                              ELSE 0
                                                              END ) )
                                           FROM     cteAllotment cteA
                                           WHERE    hc.wOriEndDate > cteA.wDate
                                                    AND hc.wOriStartDate <= cteA.wDate
                                                    AND cteA.wRoomRid = br.wHotelRoomRid
                                                    AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                                         )
                                    ELSE 0
                               END, 0) <> hc.wAmountChange
                      OR ISNULL(( SELECT    SUM(cteA.wRoomPrice)
                                            + ( CASE WHEN br.wIncludeBreakfast = 'Y'
                                                     THEN SUM(cteA.wBreakfastPrice)
                                                     ELSE 0
                                                END )
                                  FROM      cteAllotment cteA
                                  WHERE      hc.wNewEndDate > cteA.wDate
											AND hc.wNewStartDate <= cteA.wDate
                                            AND cteA.wRoomRid = br.wHotelRoomRid
                                            AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                                ), 0) <> br.wTotalAmount
						OR ISNULL(( CASE WHEN DATEDIFF(DAY, hc.wNewStartDate,  --提前入住
                                                hc.wOriStartDate) > 0
                                  THEN ( SELECT SUM(cteA.wRoomCost)
                                         FROM   cteAllotment cteA
                                         WHERE  hc.wOriStartDate > cteA.wDate
                                                AND hc.wNewStartDate <= cteA.wDate
                                                AND cteA.wRoomRid = br.wHotelRoomRid
                                                AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                                       )
                                  ELSE ( SELECT -1 * SUM(cteA.wRoomCost)  --延遲入住
                                         FROM   cteAllotment cteA
                                         WHERE  hc.wNewStartDate > cteA.wDate
                                                AND hc.wOriStartDate <= cteA.wDate
                                                AND cteA.wRoomRid = br.wHotelRoomRid
                                                AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                                       )
                             END ), 0)
                    + ISNULL(( CASE WHEN DATEDIFF(DAY, hc.wOriEndDate,
                                                  hc.wNewEndDate) > 0 --延遲交房
                                         THEN ( SELECT  SUM(cteA.wRoomCost)
                                                FROM    cteAllotment cteA
                                                WHERE   hc.wNewEndDate > cteA.wDate
                                                        AND hc.wOriEndDate <= cteA.wDate
                                                        AND cteA.wRoomRid = br.wHotelRoomRid
                                                        AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                                              )
                                    ELSE ( CASE WHEN hc.wAction = 'RF' 
											THEN 0 
											ELSE  ( SELECT   -1 * SUM(cteA.wRoomCost) --提早交房
												   FROM     cteAllotment cteA
												   WHERE    hc.wOriEndDate > cteA.wDate
															AND hc.wNewEndDate <= cteA.wDate
															AND cteA.wRoomRid = br.wHotelRoomRid
															AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid)
											END
                                         )
                               END ), 0)
                    + ISNULL(CASE WHEN hc.wAction = 'RF'
                                  THEN ( SELECT -1 * ( SUM(cteA.wRoomCost)
                                                       + ( CASE
                                                              WHEN br.wIncludeBreakfast = 'Y'
                                                              THEN SUM(cteA.wBreakfastPrice)
                                                              ELSE 0
                                                           END ) )
                                         FROM   cteAllotment cteA
                                         WHERE  hc.wOriEndDate > cteA.wDate
                                                AND hc.wOriStartDate <= cteA.wDate
                                                AND cteA.wRoomRid = br.wHotelRoomRid
                                                AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                                       )
                                  ELSE 0
                             END, 0) <> hc.wCostChange
						 OR ISNULL(( SELECT SUM(cteA.wRoomCost)
                             FROM   cteAllotment cteA
                             WHERE  hc.wNewEndDate > cteA.wDate
                                    AND hc.wNewStartDate <= cteA.wDate
                                    AND cteA.wRoomRid = br.wHotelRoomRid
                                    AND cteA.wAllotmentGroupRid = br.wAllotmentGroupRid
                           ), 0) <> hc.wTotalCost
                    )
                    AND hc.wAction <> 'C'
                    AND br.wUseAgencyAllotment <> 'Y'
            ORDER BY 1 ,
                    2 ,
                    3;
        
        WITH    cteAgencyAllotmentHotel
                  AS ( SELECT  --b.wRefNo ,
                                hc.RowID ,
                                hc.wTotalAmount ,
                                ( SELECT    SUM(hci.wPrice)
                                  FROM      dbo.eHotelCheckIn hci
                                  WHERE     wRoomBookingRid = br.RowID
                                            AND hci.wStatus = 'A'
                                            AND hc.wNewEndDate > hci.wBookingDate
                                            AND hc.wNewStartDate <= hci.wBookingDate
                                ) AS wSupposedTotalAmount ,
                                hc.wTotalCost ,
                                ( SELECT    SUM(hci.wCost)
                                  FROM      dbo.eHotelCheckIn hci
                                  WHERE     wRoomBookingRid = br.RowID
                                            AND hci.wStatus = 'A'
                                            AND hc.wNewEndDate > hci.wBookingDate
                                            AND hc.wNewStartDate <= hci.wBookingDate
                                ) AS wSupposedTotalCost
                       FROM     dbo.eHotelChange hc
                                INNER JOIN dbo.eBookingRoom br ON hc.wRoomBookingRid = br.RowID
                --INNER JOIN dbo.eBooking b ON b.RowID = br.wBookingRid
                --                             AND b.wBookingType = 'ROOM'
                                INNER JOIN dbo.mHotel h ON h.RowID = br.wHotelRid
                       WHERE    wUseAgencyAllotment = 'Y'
                                AND hc.wAction = 'C'
                     )
            SELECT  RowID ,
                    wTotalAmount ,
                    wSupposedTotalAmount ,
                    wTotalCost ,
                    wSupposedTotalCost
            INTO    #TempRecalAgencyAllotmentHotelChange
            FROM    cteAgencyAllotmentHotel cteAAH
            WHERE   cteAAH.wTotalAmount <> cteAAH.wSupposedTotalAmount
                    OR cteAAH.wTotalCost <> cteAAH.wSupposedTotalCost;
        

		-----------Recal Confirm Payment by eAllotmentHotelDaily-------------			 
        WITH    cteCustomizedAllotment
                  AS ( SELECT   wRoomRid ,
                                wDate ,
                                wRoomPrice ,
                                wRoomCost ,
                                wBreakfastPrice ,
                                wAllotmentGroupRid
                       FROM     eAllotmentHotelDaily
                       WHERE    wIsCustomized = 'Y'
                                AND wStatus = 'A'
                     ),
                cteAllotment
                  AS ( SELECT   ahd.wRoomRid ,
                                ahd.wDate ,
                                ahd.wRoomPrice ,
                                ahd.wRoomCost ,
                                ahd.wBreakfastPrice ,
                                ahd.wAllotmentGroupRid
                       FROM     eAllotmentHotelDaily ahd
                                INNER JOIN cteCustomizedAllotment cteCA ON ahd.wRoomRid <> cteCA.wRoomRid
                                                              AND ahd.wDate <> cteCA.wDate
                                                              AND ahd.wRoomPrice <> cteCA.wRoomPrice
                                                              AND wStatus = 'A'
                       UNION
                       SELECT   wRoomRid ,
                                wDate ,
                                wRoomPrice ,
                                wRoomCost ,
                                wBreakfastPrice ,
                                wAllotmentGroupRid
                       FROM     cteCustomizedAllotment
                     ),
                cteConfirmPaymentByAllotmentHotelDaily
                  AS ( SELECT  --b.wRefNo ,
                                br.wHotelRoomRid ,
                                br.wAllotmentGroupRid ,
                                hc.RowID ,
                                hc.wTotalAmount ,
                                ( SELECT    SUM(cteA.wRoomPrice)
                                            + ( CASE WHEN br.wIncludeBreakfast = 'Y'
                                                     THEN SUM(cteA.wBreakfastPrice)
                                                     ELSE 0
                                                END )
                                  FROM      cteAllotment cteA
                                  WHERE     hc.wNewEndDate > cteA.wDate
                                            AND hc.wNewStartDate <= cteA.wDate
                                            AND cteA.wRoomRid = br.wHotelRoomRid
                                            AND cteA.wAllotmentGroupRid = agd.wAllotmentGroupRid
                                ) AS wSupposedTotalAmount ,
                                hc.wTotalCost ,
                                ( SELECT    SUM(cteA.wRoomCost)
                                            + ( CASE WHEN br.wIncludeBreakfast = 'Y'
                                                     THEN SUM(cteA.wBreakfastPrice)
                                                     ELSE 0
                                                END )
                                  FROM      cteAllotment cteA
                                  WHERE     hc.wNewEndDate > cteA.wDate
                                            AND hc.wNewStartDate <= cteA.wDate
                                            AND cteA.wRoomRid = br.wHotelRoomRid
                                            AND cteA.wAllotmentGroupRid = agd.wAllotmentGroupRid
                                ) AS wSupposedTotalCost
                       FROM     dbo.eHotelChange hc
                                INNER JOIN dbo.eBookingRoom br ON hc.wRoomBookingRid = br.RowID
                                INNER JOIN dbo.eBooking b ON b.RowID = br.wBookingRid
                                INNER JOIN dbo.mAllotmentGroupDtl agd ON agd.wCounterRid = b.wDebitCounterRid
                                                              AND br.wAllotmentGroupRid = agd.wAllotmentGroupRid
                                                              AND agd.wStatus = 'A'
                                INNER JOIN dbo.mHotel h ON h.RowID = br.wHotelRid
                       WHERE    wUseAgencyAllotment <> 'Y'
                                AND hc.wAction = 'C'
                                --AND ( hc.wTotalAmount = 0
                                --      OR hc.wTotalCost = 0
                                --    )
			               --ORDER BY hc.RowID
                     )
            SELECT  cteCPBAHD.wHotelRoomRid ,
                    cteCPBAHD.wAllotmentGroupRid ,
                    cteCPBAHD.RowID ,
                    cteCPBAHD.wTotalAmount ,
                    cteCPBAHD.wSupposedTotalAmount ,
                    cteCPBAHD.wTotalCost ,
                    cteCPBAHD.wSupposedTotalCost
            INTO    #TempRecalConfirmPaymentByAllotmentHotelDaily
            FROM    cteConfirmPaymentByAllotmentHotelDaily cteCPBAHD;


        SELECT  b.wRefNo,hc.wAmountChange, temp.wSupposedAmount, hc.wCostChange , temp.wSupposedCostChange,  hc.wTotalAmount , temp.wSupposedTotalAmount, hc.wTotalCost, temp.wSupposedTotalCost, *
        FROM    dbo.eHotelChange hc
				LEFT JOIN eBookingRoom br ON br.RowID = hc.wRoomBookingRid
				LEFT JOIN dbo.eBooking b ON b.RowID = br.wBookingRid
                INNER JOIN #TempRecalHotelChange temp ON hc.RowID = temp.RowID
        WHERE   hc.wAmountChange <> temp.wSupposedAmount
                OR hc.wCostChange <> temp.wSupposedCostChange
                OR hc.wTotalAmount <> temp.wSupposedTotalAmount
				OR hc.wTotalCost <> temp.wSupposedTotalCost
        ORDER BY 1 ,
                2 ,
                3;

        SELECT  b.wRefNo, hc.wAmountChange , temp.wSupposedTotalAmount
                  , hc.wCostChange , temp.wSupposedTotalCost
				  , hc.wTotalAmount , temp.wSupposedTotalAmount
                  , hc.wTotalCost , temp.wSupposedTotalCost, *
        FROM    dbo.eHotelChange hc
				LEFT JOIN eBookingRoom br ON br.RowID = hc.wRoomBookingRid
				LEFT JOIN dbo.eBooking b ON b.RowID = br.wBookingRid
                INNER JOIN #TempRecalAgencyAllotmentHotelChange temp ON hc.RowID = temp.RowID
        WHERE   ( hc.wAmountChange <> temp.wSupposedTotalAmount
                  OR hc.wCostChange <> temp.wSupposedTotalCost
				  OR hc.wTotalAmount <> temp.wSupposedTotalAmount
                  OR hc.wTotalCost <> temp.wSupposedTotalCost
                )
        ORDER BY 1 ,
                2 ,
                3;

        SELECT  b.wRefNo, hc.wAmountChange , temp.wSupposedTotalAmount
                  , hc.wCostChange , temp.wSupposedTotalCost
				  , hc.wTotalAmount , temp.wSupposedTotalAmount
                  , hc.wTotalCost , temp.wSupposedTotalCost, *
        FROM    dbo.eHotelChange hc
                INNER JOIN dbo.eBookingRoom br ON hc.wRoomBookingRid = br.RowID
                INNER JOIN dbo.eBooking b ON b.RowID = br.wBookingRid
                INNER JOIN #TempRecalConfirmPaymentByAllotmentHotelDaily temp ON hc.RowID = temp.RowID
        WHERE   ( hc.wTotalAmount <> temp.wSupposedTotalAmount                  
                  OR hc.wAmountChange <> temp.wSupposedTotalAmount
				  OR hc.wTotalCost <> temp.wSupposedTotalCost
                  OR hc.wCostChange <> temp.wSupposedTotalCost
                )
        ORDER BY 1 ,
                2;

        IF @pUpdateData = 'Y'
            BEGIN
				DECLARE @HotelChangeRidVariableTable TABLE ( wHotelChangeRid BIGINT );				

				IF ( @pHotelChangeRidString != '' )
					INSERT  INTO @HotelChangeRidVariableTable
                    SELECT  item
                    FROM    RollsMary.dbo.fnSplit(@pHotelChangeRidString, ',');

				-----------Recal HotelChange-------------
                UPDATE  hc
                SET     hc.wAmountChange = temp.wSupposedAmount ,
                        hc.wCostChange = temp.wSupposedCostChange ,
                        hc.wTotalAmount = temp.wSupposedTotalAmount ,
                        hc.wTotalCost = temp.wSupposedTotalCost
                FROM    dbo.eHotelChange hc
						INNER JOIN @HotelChangeRidVariableTable hcrvt ON hcrvt.wHotelChangeRid = hc.RowID
						--INNER JOIN dbo.eBookingRoom br ON hc.wRoomBookingRid = br.RowID
						--INNER JOIN dbo.eBooking b ON b.RowID = br.wBookingRid
                        INNER JOIN #TempRecalHotelChange temp ON hc.RowID = temp.RowID
                WHERE   (hc.wAmountChange <> temp.wSupposedAmount
							OR hc.wCostChange <> temp.wSupposedCostChange
							OR hc.wTotalAmount <> temp.wSupposedTotalAmount
							OR hc.wTotalCost <> temp.wSupposedTotalCost)
						--AND (wRefNo = @pRefNo OR @pRefNo='');
				
				--------hc.wTotalCost = temp.wSupposedTotalCost---Recal HotelChange AgencyAllotment-------------
                UPDATE  hc
                SET     hc.wTotalAmount = temp.wSupposedTotalAmount ,
                        hc.wTotalCost = temp.wSupposedTotalCost ,
                        hc.wAmountChange = temp.wSupposedTotalAmount ,
                        hc.wCostChange = temp.wSupposedTotalCost
                FROM    dbo.eHotelChange hc
						INNER JOIN @HotelChangeRidVariableTable hcrvt ON hcrvt.wHotelChangeRid = hc.RowID
						--INNER JOIN dbo.eBookingRoom br ON hc.wRoomBookingRid = br.RowID
						--INNER JOIN dbo.eBooking b ON b.RowID = br.wBookingRid
                        INNER JOIN #TempRecalAgencyAllotmentHotelChange temp ON hc.RowID = temp.RowID
                WHERE   ( hc.wTotalAmount <> temp.wSupposedTotalAmount
                          OR hc.wTotalCost <> temp.wSupposedTotalCost
                          OR hc.wAmountChange <> temp.wSupposedTotalAmount
                          OR hc.wCostChange <> temp.wSupposedTotalCost
                        )
                        AND temp.wSupposedTotalAmount IS NOT NULL
                        AND temp.wSupposedTotalCost IS NOT NULL
						--AND (wRefNo = @pRefNo OR @pRefNo='');

				-----------Recal BookingRoom-------------
                IF(@pHotelChangeRidString = '')
				BEGIN
					 WITH    cteHotelChangeNumber
                          AS ( SELECT   hc.wAction ,
                                        hc.wRoomBookingRid ,
                                        hc.wNewStartDate ,
                                        hc.wNewEndDate ,
                                        hc.wTotalAmount ,
                                        hc.wTotalCost ,
                                        ROW_NUMBER() OVER ( PARTITION BY hc.wRoomBookingRid ORDER BY hc.wCrtDt DESC ) AS wRowNo
                               FROM     eHotelChange hc
                               WHERE    hc.wAction <> 'RF'
                             ),
                        cteLastHotelChange
                          AS ( SELECT   cteHcn.wRoomBookingRid ,
                                        cteHcn.wNewStartDate ,
                                        cteHcn.wNewEndDate ,
                                        cteHcn.wTotalAmount ,
                                        cteHcn.wTotalCost
                               FROM     cteHotelChangeNumber cteHcn
                               WHERE    cteHcn.wRowNo = 1
                             )
                    SELECT  cteLHC.* ,
                            b.wRefNo --,
                            --br.wStartDate ,
                            --br.wEndtDate ,
                           -- br.wTotalAmount ,
                            --br.wTotalCost
                    INTO    #TempRecalBookingRoom
                    FROM    cteLastHotelChange cteLHC
                            INNER JOIN eBookingRoom br ON cteLHC.wRoomBookingRid = br.RowID
                            LEFT JOIN eBooking b ON br.wBookingRid = b.RowID
                    WHERE   cteLHC.wNewStartDate <> br.wStartDate
                            OR cteLHC.wNewEndDate <> br.wEndtDate
                            OR cteLHC.wTotalAmount <> br.wTotalAmount
                            OR cteLHC.wTotalCost <> br.wTotalCost
                    ORDER BY 1;

					UPDATE  br
					SET     br.wStartDate = temp.wNewStartDate ,
							br.wEndtDate = temp.wNewEndDate ,
							br.wTotalAmount = temp.wTotalAmount ,
							br.wTotalCost = temp.wTotalCost
					FROM    dbo.eBookingRoom br
							INNER JOIN #TempRecalBookingRoom temp ON br.RowID = temp.wRoomBookingRid; 
				END


				-----------Recal Confirm Payment by eHotelCheckIn-------------
				--;
    --            WITH    cteConfirmPaymentHotelChange
    --                      AS ( SELECT  --b.wRefNo ,
    --                                    br.wHotelRoomRid ,
    --                                    br.wAllotmentGroupRid ,
    --                                    hc.RowID ,
    --                                    hc.wTotalAmount ,
    --                                    ( SELECT    SUM(hci.wPrice)
    --                                      FROM      dbo.eHotelCheckIn hci
    --                                      WHERE     wRoomBookingRid = br.RowID
    --                                                AND hci.wStatus = 'A'
    --                                    ) AS wSupposedTotalAmount ,
    --                                    hc.wTotalCost ,
    --                                    ( SELECT    SUM(hci.wCost)
    --                                      FROM      dbo.eHotelCheckIn hci
    --                                      WHERE     wRoomBookingRid = br.RowID
    --                                                AND hci.wStatus = 'A'
    --                                    ) AS wSupposedTotalCost
    --                           FROM     dbo.eHotelChange hc
    --                                    INNER JOIN dbo.eBookingRoom br ON hc.wRoomBookingRid = br.RowID                
    --                                    INNER JOIN dbo.mHotel h ON h.RowID = br.wHotelRid
    --                           WHERE    wUseAgencyAllotment <> 'Y'
    --                                    AND hc.wAction = 'C'
    --                                    AND ( hc.wTotalAmount = 0
    --                                          OR hc.wTotalCost = 0
    --                                        )               
    --                         )
    --                UPDATE  hc
    --                SET     hc.wTotalAmount = cteCPHC.wSupposedTotalAmount ,
    --                        hc.wTotalCost = cteCPHC.wSupposedTotalCost
    --                FROM    dbo.eHotelChange hc
    --                        INNER JOIN cteConfirmPaymentHotelChange cteCPHC ON hc.RowID = cteCPHC.RowID
    --                WHERE   cteCPHC.wSupposedTotalAmount IS NOT NULL
    --                        AND cteCPHC.wSupposedTotalCost IS NOT NULL;

			-----------Recal Confirm Payment by eAllotmentHotelDaily-------------	
                UPDATE  hc
                SET     hc.wTotalAmount = temp.wSupposedTotalAmount ,
                        hc.wTotalCost = temp.wSupposedTotalCost ,
                        hc.wAmountChange = temp.wSupposedTotalAmount ,
                        hc.wCostChange = temp.wSupposedTotalCost
                FROM    dbo.eHotelChange hc
						INNER JOIN @HotelChangeRidVariableTable hcrvt ON hcrvt.wHotelChangeRid = hc.RowID
                        INNER JOIN dbo.eBookingRoom br ON hc.wRoomBookingRid = br.RowID
                        INNER JOIN dbo.eBooking b ON b.RowID = br.wBookingRid
                        INNER JOIN #TempRecalConfirmPaymentByAllotmentHotelDaily temp ON hc.RowID = temp.RowID
                WHERE   temp.wSupposedTotalAmount IS NOT NULL
                        AND temp.wSupposedTotalCost IS NOT NULL
                        AND ( hc.wTotalAmount <> temp.wSupposedTotalAmount
                              OR hc.wTotalCost <> temp.wSupposedTotalCost
                              OR hc.wAmountChange <> temp.wSupposedTotalAmount
                              OR hc.wCostChange <> temp.wSupposedTotalCost
                            )
						--AND (wRefNo = @pRefNo OR @pRefNo='');
            END;

        IF OBJECT_ID('tempdb..#TempRecalHotelChange') IS NOT NULL
            DROP TABLE #TempRecalHotelChange; 

        IF OBJECT_ID('tempdb..#TempRecalAgencyAllotmentHotelChange') IS NOT NULL
            DROP TABLE #TempRecalAgencyAllotmentHotelChange;

        IF OBJECT_ID('tempdb..#TempRecalConfirmPaymentByAllotmentHotelDaily') IS NOT NULL
            DROP TABLE #TempRecalConfirmPaymentByAllotmentHotelDaily;			

        IF OBJECT_ID('tempdb..#TempRecalBookingRoom') IS NOT NULL
            DROP TABLE #TempRecalBookingRoom;
    END;