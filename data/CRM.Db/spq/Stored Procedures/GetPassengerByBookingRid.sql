

CREATE PROCEDURE [spq].[GetPassengerByBookingRid]
    @pBookingRid BIGINT ,
    @pType VARCHAR(30) ,
    @pLangCd VARCHAR(10) = 'en-gb' ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1
AS
    BEGIN 
-- SET NOCOUNT ON added to prevent extra result sets from 
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        IF @pType = 'AIRTICKET'
            BEGIN
			WITH    cteDocDetails
                  AS ( SELECT   ptdd.wPassengerDetailsRid ,
                                ptd.wIDNo ,
                                ptd.wIDType ,
                                ptd.wEnglishPinyin
                       FROM     ePassengerTravelDocDetail ptdd
                                LEFT JOIN dbo.mPersonTravelDoc ptd ON ptd.RowID = ptdd.wPersonTravelDocRid
                     ),
                    tResult
                          AS ( SELECT   1 AS wSeqNo ,
                                        ecippi.wSeqNo AS wPassengerSeqNo ,
                                        ISNULL(ecippi.wCost, 0) AS wCost ,
                                        p.wAgentCodeIn wAccount , 
			   -- CASE WHEN @pLangCd = 'en-gb' THEN ma.wEName ELSE ma.wCName END AS wAccountName,
                                        ma.wAgentCode_Display ,
                                        ma.wAgentCodeIn ,
                                        p.wCName ,
                                        p.wGender ,
										p.wBirthdate,
                                        [dbo].[fnGetDocDetailsByPassengerDetailRid](ecippi.RowID, 'ID_NO', @pLangCd) wPersonTravelDocNo ,
                                        ISNULL(ebat.wOrderNo, '') AS WOrderNo ,
                                        ecippi.RowID ,
                                        ecippi.wBookingRid ,
                                        ecippi.wClientTicketNo ,
                                        ecippi.wDepartFlightNo ,
                                        ecippi.wTakeOffDt ,
                                        ecippi.wDestination ,
                                        ecippi.wRequesterAcc ,
                                        ecippi.wPersonRid ,
                                        ecippi.wRemark ,
                                        ecippi.wStatus ,
                                        ecippi.wCrtBy ,
                                        ecippi.wCrtDt ,
                                        ecippi.wUpdDt ,
                                        ecippi.wUpdBy ,
                                        ecippi.wType ,
                                        ecippi.wApplicationType ,
                                        ecippi.wApplicationStatus ,
                                        ecippi.wAmount ,
                                        ISNULL(eb.wCancelReasonCd, '') AS wChangeOrderStatus ,
                                        ISNULL(p.wStatus, '') AS wPersonStatus ,
                                        ISNULL(p.wRole, '') AS wPersonRole ,
			   --ISNULL(eb.wRefNo,'')As wRefNo,
                                        eb.wRefNo + '-' + RIGHT('000' + CAST(( ecippi.wSeqNo ) AS VARCHAR(3)), 3) AS wRefNo ,
                                        ISNULL(p.wNickname, '') AS wNickname ,
										STUFF(( SELECT  ', ' + cdd.wEnglishPinyin
                                        FROM    cteDocDetails cdd
                                        WHERE   cdd.wPassengerDetailsRid =ecippi.RowID 
                                      FOR
                                        XML PATH('')
                                      ), 1, 1, '') AS wEnglishPinyin,
                                        ISNULL(p.wEName, '') AS wEName ,
                                        [dbo].[fnGetDocDetailsByPassengerDetailRid](ecippi.RowID, 'ID_TYPE', @pLangCd) wPersonTravelDocTypeName ,
                                        ecippi.wCasinoCardRid ,
                                        ecippi.wRoomBookingRid ,
                                        ecippi.wCancelBy ,
                                        ecippi.wCancelDebitDt ,
                                        ecippi.wCancelDt ,
                                        ecippi.wCancelReasonCd ,
                                        ecippi.wOtherReason ,
                                        ecippi.wPassengerBookingStatus ,
                                        ecippi.wChangeOrderCount ,
                                        ecippi.wIsWaiting ,
                                        ecippi.wRouteRid ,
                                        ( CASE WHEN PSDRT.wType = 'PASSENGER' THEN COALESCE(( PDPPRT.wCode + ', ' + CASE WHEN @pLangCd = 'en-gb' THEN PDPPRT.wEName
                                                                                                                         ELSE PDPPRT.wCName
                                                                                                                    END + ', ' + PDPPRT.wCity ), ' ')
                                               ELSE COALESCE(( ADPPRT.wCode + ', ' + CASE WHEN @pLangCd = 'en-gb' THEN ADPPRT.wEName
                                                                                          ELSE ADPPRT.wCName
                                                                                     END + ', ' + ADPPRT.wCity ), ' ')
                                          END ) AS wDepartureAirport ,  -- departure airport
                                        ( CASE WHEN PSDRT.wType = 'PASSENGER' THEN COALESCE(( ISNULL(PRTNRT.wCode, PLASTRT.wCode) + ', ' + CASE WHEN @pLangCd = 'en-gb' THEN ISNULL(PRTNRT.wEName, PLASTRT.wEName)
                                                                                                                                               ELSE ISNULL(PRTNRT.wCName, PLASTRT.wCName)
                                                                                                                                          END + ', ' + ISNULL(PRTNRT.wCity, PLASTRT.wCity) ), ' ')
                                               ELSE COALESCE(( ISNULL(ARTNRT.wCode, ALASTRT.wCode) + ', ' + CASE WHEN @pLangCd = 'en-gb' THEN ISNULL(ARTNRT.wEName, ALASTRT.wEName)
                                                                                                                 ELSE ISNULL(ARTNRT.wCName, ALASTRT.wCName)
                                                                                                            END + ', ' + ISNULL(ARTNRT.wCity, ALASTRT.wCity) ), ' ')
                                          END ) AS wArrivalAirport ,  -- ArrivalAirport airport
                                        ( CASE WHEN PSDRT.wType = 'PASSENGER' THEN COALESCE(PSDRT.wClassCd, '')
                                               ELSE COALESCE(ARTRT.wClassCd, '')
                                          END ) AS wAirportTravelClass , -- travel class
                                        ( CASE WHEN PSDRT.wType = 'PASSENGER' THEN PSDRT.wTakeOffDt
                                               ELSE ARTRT.wTakeOffDt
                                          END ) AS wDepartureTime ,  -- departure time
                                        ( CASE WHEN PSDRT.wType = 'PASSENGER' THEN PSDRT.wArrivalDt
                                               ELSE ARTRT.wArrivalDt
                                          END ) AS wArrivalTime ,  -- Arrival time
                                        ( CASE WHEN PSDRT.wType = 'PASSENGER' THEN ISNULL(PRTNARD.wTakeOffDt, PLASTARD.wTakeOffDt)
                                               ELSE ISNULL(ARTNARD.wTakeOffDt, ALASTARD.wTakeOffDt)
                                          END ) AS wReturnDepartureTime  -- return Departure time 
                               FROM     dbo.ePassengerDetails ecippi
                                        INNER JOIN ( SELECT *
                                                     FROM   dbo.eBooking
                                                     WHERE  ( @pBookingRid IS NULL
                                                              OR RowID = @pBookingRid
                                                            )
                                                   ) eb ON eb.RowID = ecippi.wBookingRid
                                        LEFT JOIN ( SELECT  *
                                                    FROM    dbo.eBookingAirTicket
                                                    WHERE   ( @pBookingRid IS NULL
                                                              OR wBookingRid = @pBookingRid
                                                            )
                                                  ) ebat ON ebat.wBookingRid = eb.RowID
                                        LEFT JOIN dbo.mPerson p ON p.RowID = ecippi.wPersonRid
                                        LEFT JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = ecippi.wRequesterAcc
                                        LEFT JOIN RollsMary.dbo.mAgent daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn

		--- for default routes
                                        LEFT JOIN ( SELECT *
                                                     FROM   dbo.eAirTicketRouteDtl
                                                     WHERE  wType = 'AIRTICKET'
                                                            AND wLine = 1
                                                            AND wStatus = 'A'
                                                   ) ARTRT ON ARTRT.wTypeRid = ebat.RowID
                                      
                                        LEFT JOIN ( SELECT  wTypeRid ,
                                                            MIN(wLine) AS wLine
                                                    FROM    dbo.eAirTicketRouteDtl
                                                    WHERE   wType = 'AIRTICKET'
                                                            AND wStatus = 'A'
                                                            AND wIsReturn = 'Y'
                                                            AND wLine != 1
                                                    GROUP BY wTypeRid
                                                  ) ARTNAP ON ARTNAP.wTypeRid = ebat.RowID
                                        LEFT JOIN dbo.eAirTicketRouteDtl ARTNARD ON ARTNARD.wTypeRid = ARTNAP.wTypeRid
                                                                                    AND ARTNARD.wLine = ARTNAP.wLine
                                                                                    AND ARTNARD.wStatus = 'A'
                                                                                    AND ARTNARD.wType = 'AIRTICKET'
                                        LEFT JOIN ( SELECT  wTypeRid ,
                                                            MAX(wLine) AS wLine
                                                    FROM    dbo.eAirTicketRouteDtl
                                                    WHERE   wType = 'AIRTICKET'
                                                            AND wStatus = 'A'
                                                            AND wIsReturn != 'Y'
                                                    GROUP BY wTypeRid
                                                  ) ALASTAP ON ALASTAP.wTypeRid = ebat.RowID
                                        LEFT JOIN dbo.eAirTicketRouteDtl ALASTARD ON ALASTARD.wTypeRid = ALASTAP.wTypeRid
                                                                                     AND ALASTARD.wLine = ALASTAP.wLine
                                                                                     AND ALASTARD.wStatus = 'A'
                                                                                     AND ALASTARD.wType = 'AIRTICKET'
                                        LEFT JOIN ( SELECT  *
                                                    FROM    dbo.mAirport
                                                  ) ARTNRT ON ARTNRT.RowID = ARTNARD.wDepartureAirportRid
                                        LEFT JOIN ( SELECT  *
                                                    FROM    dbo.mAirport
                                                  ) ALASTRT ON ALASTRT.RowID = ALASTARD.wArrivalAirportRid
                                        LEFT JOIN ( SELECT  *
                                                    FROM    dbo.mAirport
                                                  ) ADPPRT ON ADPPRT.RowID = ARTRT.wDepartureAirportRid                                     

		-- for passenger routes
                                        LEFT JOIN ( SELECT  *
                                                    FROM    dbo.eAirTicketRouteDtl
                                                    WHERE   wType = 'PASSENGER'
                                                            AND wStatus = 'A'
                                                            AND wLine = 1
                                                  ) PSDRT ON PSDRT.wTypeRid = ecippi.RowID
                                       
                                        LEFT JOIN ( SELECT  wTypeRid ,
                                                            MIN(wLine) AS wLine
                                                    FROM    dbo.eAirTicketRouteDtl
                                                    WHERE   wType = 'PASSENGER'
                                                            AND wStatus = 'A'
                                                            AND wIsReturn = 'Y'
                                                            AND wLine != 1
                                                    GROUP BY wTypeRid
                                                  ) PRTNAP ON PRTNAP.wTypeRid = ecippi.RowID
                                        LEFT JOIN dbo.eAirTicketRouteDtl PRTNARD ON PRTNARD.wTypeRid = PRTNAP.wTypeRid
                                                                                    AND PRTNARD.wLine = PRTNAP.wLine
                                                                                    AND PRTNARD.wStatus = 'A'
                                                                                    AND PRTNARD.wType = 'PASSENGER'
                                        LEFT JOIN ( SELECT  wTypeRid ,
                                                            MAX(wLine) AS wLine
                                                    FROM    dbo.eAirTicketRouteDtl
                                                    WHERE   wType = 'PASSENGER'
                                                            AND wStatus = 'A'
                                                            AND wIsReturn != 'Y'
                                                    GROUP BY wTypeRid
                                                  ) PLASTAP ON PLASTAP.wTypeRid = ecippi.RowID
                                        LEFT JOIN dbo.eAirTicketRouteDtl PLASTARD ON PLASTARD.wTypeRid = PLASTAP.wTypeRid
                                                                                     AND PLASTARD.wLine = PLASTAP.wLine
                                                                                     AND PLASTARD.wStatus = 'A'
                                                                                     AND PLASTARD.wType = 'PASSENGER'
                                        LEFT JOIN ( SELECT  *
                                                    FROM    dbo.mAirport
                                                  ) PRTNRT ON PRTNRT.RowID = PRTNARD.wDepartureAirportRid
                                        LEFT JOIN ( SELECT  *
                                                    FROM    dbo.mAirport
                                                  ) PLASTRT ON PLASTRT.RowID = PLASTARD.wArrivalAirportRid
                                        LEFT JOIN ( SELECT  *
                                                    FROM    dbo.mAirport
                                                  ) PDPPRT ON PDPPRT.RowID = PSDRT.wDepartureAirportRid                                     
		-- Return passenger routs
                                        LEFT JOIN ( SELECT  * ,
                                                            ROW_NUMBER() OVER ( PARTITION BY wTypeRid ORDER BY wLine DESC ) AS ReturnFistRt
                                                    FROM    dbo.eAirTicketRouteDtl
                                                    WHERE   wType = 'AIRTICKET'
                                                            AND wStatus = 'A'
                                                            AND wIsReturn = 'Y'
                                                  ) AADRRT ON AADRRT.wTypeRid = ebat.RowID
                                                              AND AADRRT.ReturnFistRt = 1

		-- Return passenger routs
                                        LEFT JOIN ( SELECT  * ,
                                                            ROW_NUMBER() OVER ( PARTITION BY wTypeRid ORDER BY wLine DESC ) AS ReturnFistRt
                                                    FROM    dbo.eAirTicketRouteDtl
                                                    WHERE   wType = 'PASSENGER'
                                                            AND wStatus = 'A'
                                                            AND wIsReturn = 'Y'
                                                  ) PSDRRT ON PSDRRT.wTypeRid = ecippi.RowID
                                                              AND PSDRRT.ReturnFistRt = 1
                               WHERE    ( ecippi.wBookingRid = @pBookingRid
                                          AND ecippi.wType = @pType
                                        )
                             ),
                        tCount
                          AS ( SELECT   wRecordCount = COUNT(1)
                               FROM     tResult
                             )
                    SELECT  tResult.* ,
                            wRecordCount
                    FROM    tResult ,
                            tCount
                    ORDER BY wCrtDt ,
                            wSeqNo
                            OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS  
	FETCH NEXT @pPageSize ROWS ONLY;  
            END;
        ELSE
            IF @pType IN ( 'CS', 'HELI', 'FERRY', 'TRAVEL_PACKAGE', 'PP', 'VISA', 'PICKUPSERVICE', 'TOURGUIDE' )
                BEGIN
				WITH    cteDocDetails
                  AS ( SELECT   ptdd.wPassengerDetailsRid ,
                                ptd.wIDNo ,
                                ptd.wIDType ,
                                ptd.wEnglishPinyin
                       FROM     ePassengerTravelDocDetail ptdd
                                LEFT JOIN dbo.mPersonTravelDoc ptd ON ptd.RowID = ptdd.wPersonTravelDocRid
                     ),
                        tResult
                              AS ( SELECT   1 AS wSeqNo ,
                                            ecippi.wSeqNo AS wPassengerSeqNo ,
                                            ISNULL(ecippi.wCost, 0) AS wCost ,
                                            p.wAgentCodeIn wAccount , 
			   -- CASE WHEN @pLangCd = 'en-gb' THEN ma.wEName ELSE ma.wCName END AS wAccountName,
                                            ma.wAgentCode_Display ,
                                            ma.wAgentCodeIn ,
                                            p.wCName ,
                                            p.wGender ,
											p.wBirthdate,
                                            [dbo].[fnGetDocDetailsByPassengerDetailRid](ecippi.RowID, 'ID_NO', @pLangCd) wPersonTravelDocNo ,
                                            ISNULL(ebat.wOrderNo, '') AS WOrderNo ,
                                            ecippi.RowID ,
                                            ecippi.wBookingRid ,
                                            ecippi.wClientTicketNo ,
                                            ecippi.wDepartFlightNo ,
                                            ecippi.wTakeOffDt ,
                                            ecippi.wDestination ,
                                            ecippi.wRequesterAcc ,
                                            ecippi.wPersonRid ,
                                            ISNULL(eptdd.wPersonTravelDocRid, -1) AS wPersonTravelDocRid ,
                                            ecippi.wRemark ,
                                            ecippi.wStatus ,
                                            ecippi.wCrtBy ,
                                            ecippi.wCrtDt ,
                                            ecippi.wUpdDt ,
                                            ecippi.wUpdBy ,
                                            ecippi.wType ,
                                            ecippi.wApplicationType ,
                                            ecippi.wApplicationStatus ,
                                            ecippi.wAmount ,
                                            ISNULL(eb.wCancelReasonCd, '') AS wChangeOrderStatus ,
                                            ISNULL(p.wStatus, '') AS wPersonStatus ,
                                            ISNULL(p.wRole, '') AS wPersonRole ,
			   --ISNULL(eb.wRefNo,'')As wRefNo,
                                            eb.wRefNo + '-' + RIGHT('000' + CAST(( ecippi.wSeqNo ) AS VARCHAR(3)), 3) AS wRefNo ,
                                            ISNULL(p.wNickname, '') AS wNickname ,
											STUFF(( SELECT  ', ' + cdd.wEnglishPinyin
                                                 FROM    cteDocDetails cdd
                                                 WHERE   cdd.wPassengerDetailsRid =ecippi.RowID 
                                                 FOR
                                                XML PATH('')
                                             ), 1, 1, '') AS wEnglishPinyin,
                                            ISNULL(p.wEName, '') AS wEName ,
                                            [dbo].[fnGetDocDetailsByPassengerDetailRid](ecippi.RowID, 'ID_TYPE', @pLangCd) wPersonTravelDocTypeName ,
                                            ecippi.wCasinoCardRid ,
                                            ecippi.wRoomBookingRid ,
                                            ecippi.wCancelBy ,
                                            ecippi.wCancelDebitDt ,
                                            ecippi.wCancelDt ,
                                            ecippi.wCancelReasonCd ,
                                            ecippi.wOtherReason ,
                                            ecippi.wPassengerBookingStatus ,
                                            ecippi.wChangeOrderCount ,
                                            ecippi.wIsWaiting ,
                                            ecippi.wRouteRid ,
                                            '' AS wDepartureAirport ,  -- departure airport
                                            '' AS wArrivalAirport ,  -- ArrivalAirport airport
                                            '' AS wAirportTravelClass , -- travel class
                                            NULL AS wDepartureTime ,  -- departure time
                                            NULL AS wArrivalTime ,  -- Arrival time
                                            NULL AS wReturnDepartureTime  -- return Departure time
                                   FROM     dbo.ePassengerDetails ecippi
                                            INNER JOIN dbo.eBooking eb ON eb.RowID = ecippi.wBookingRid
                                            LEFT JOIN dbo.ePassengerTravelDocDetail eptdd ON eptdd.wPassengerDetailsRid = ecippi.RowID
                                            LEFT JOIN dbo.eBookingAirTicket ebat ON ebat.wBookingRid = ecippi.wBookingRid
                                            LEFT JOIN dbo.mPerson p ON p.RowID = ecippi.wPersonRid
                                            LEFT JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = ecippi.wRequesterAcc
                                            LEFT JOIN RollsMary.dbo.mAgent daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
                                            --LEFT JOIN dbo.mLookUp mluppr ON mluppr.wCode = p.wRole
                                                                            --AND mluppr.wLangCd = @pLangCd
                                                                            --AND mluppr.wType = 'PERSON_ROLE'
                                   WHERE    ( ecippi.wBookingRid = @pBookingRid
                                              AND ecippi.wType = @pType
                                            )
                                 ),
                            tCount
                              AS ( SELECT   wRecordCount = COUNT(1)
                                   FROM     tResult
                                 )
                        SELECT  tResult.* ,
                                wRecordCount
                        FROM    tResult ,
                                tCount
                        ORDER BY wCrtDt ,
                                wSeqNo
                                OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS  
	FETCH NEXT @pPageSize ROWS ONLY
                    OPTION  ( RECOMPILE );  

                END;
            ELSE
                IF @pType = 'HOTEL'
                    BEGIN
	-- this section is only for RoomBooking client info
                  WITH    cteDocDetails
                  AS ( SELECT   ptdd.wPassengerDetailsRid ,
                                ptd.wIDNo ,
                                ptd.wIDType ,
                                ptd.wEnglishPinyin
                       FROM     ePassengerTravelDocDetail ptdd
                                LEFT JOIN dbo.mPersonTravelDoc ptd ON ptd.RowID = ptdd.wPersonTravelDocRid
                     ),
						    tResult
                                  AS ( SELECT DISTINCT
                                                CAST(ROW_NUMBER() OVER ( ORDER BY ecippi.wUpdDt DESC ) AS INT) AS wSeqNo ,
                                                ecippi.wSeqNo AS wPassengerSeqNo ,
                                                CAST(0 AS DECIMAL(18, 4)) AS wCost ,
                                                CAST('N' AS CHAR(1)) AS wIsLessThanHalfYear ,
                                                p.wAgentCodeIn wAccount ,
                                                ma.wAgentCode_Display ,
                                                ma.wAgentCodeIn ,
                                                p.wCName ,
                                                p.wGender ,
												p.wBirthdate,
			   --ptd.wIDNo wPersonTravelDocNo,  
                                                [dbo].[fnGetDocDetailsByPassengerDetailRid](ecippi.RowID, 'ID_NO', @pLangCd) wPersonTravelDocNo ,
                                                CAST('-1' AS VARCHAR(20)) AS WOrderNo ,
                                                ecippi.RowID ,
                                                ecippi.wBookingRid ,
                                                ecippi.wClientTicketNo ,
                                                ecippi.wDepartFlightNo ,
                                                ecippi.wTakeOffDt ,
                                                ecippi.wDestination ,
                                                ecippi.wRequesterAcc ,
                                                ecippi.wPersonRid ,
                                                ecippi.wRemark ,
                                                ecippi.wStatus ,
                                                ecippi.wCrtBy ,
                                                ecippi.wCrtDt ,
                                                ecippi.wUpdDt ,
                                                ecippi.wUpdBy ,
                                                ecippi.wType ,
                                                ecippi.wApplicationType ,
                                                ecippi.wApplicationStatus ,
                                                ecippi.wAmount ,
                                                ISNULL(eb.wCancelReasonCd, '') AS wChangeOrderStatus ,
                                                ISNULL(p.wStatus, '') AS wPersonStatus ,
                                                ISNULL(p.wRole, '') AS wPersonRole ,
			   --ISNULL(eb.wRefNo,'') As wRefNo,
                                                eb.wRefNo + '-' + RIGHT('000' + CAST(( ebr.wSeqNo ) AS VARCHAR(3)), 3) + '-' + RIGHT('000' + CAST(( ecippi.wSeqNo ) AS VARCHAR(3)), 3) AS wRefNo ,
                                                ISNULL(p.wNickname, '') AS wNickname ,
												STUFF(( SELECT  ', ' + cdd.wEnglishPinyin
                                                 FROM    cteDocDetails cdd
                                                 WHERE   cdd.wPassengerDetailsRid =ecippi.RowID 
                                                 FOR
                                                XML PATH('')
                                             ), 1, 1, '') AS wEnglishPinyin,
                                                ISNULL(p.wEName, '') AS wEName ,
			   --lupit.wTitle wPersonTravelDocTypeName,
                                                [dbo].[fnGetDocDetailsByPassengerDetailRid](ecippi.RowID, 'ID_TYPE', @pLangCd) wPersonTravelDocTypeName ,
                                                ecippi.wCasinoCardRid ,
                                                ecippi.wRoomBookingRid ,
                                                ecippi.wCancelBy ,
                                                ecippi.wCancelDebitDt ,
                                                ecippi.wCancelDt ,
                                                ecippi.wCancelReasonCd ,
                                                ecippi.wOtherReason ,
                                                ecippi.wPassengerBookingStatus ,
                                                ecippi.wChangeOrderCount ,
                                                ecippi.wIsWaiting ,
                                                ecippi.wRouteRid ,
                                                '' AS wDepartureAirport ,  -- departure airport
                                                '' AS wArrivalAirport ,  -- ArrivalAirport airport
                                                '' AS wAirportTravelClass , -- travel class
                                                NULL AS wDepartureTime ,  -- departure time
                                                NULL AS wArrivalTime ,  -- Arrival time
                                                NULL AS wReturnDepartureTime  -- return Departure time
                                       FROM     ( SELECT    *
                                                  FROM      dbo.ePassengerDetails
                                                  WHERE     wRoomBookingRid = @pBookingRid
                                                ) ecippi -- AND wType = @pwType) ecippi
                                                INNER JOIN dbo.eBooking eb ON eb.RowID = ecippi.wBookingRid
                                                INNER JOIN dbo.eBookingRoom ebr ON ebr.RowID = ecippi.wRoomBookingRid
                                                LEFT JOIN dbo.mPerson p ON p.RowID = ecippi.wPersonRid
                                                LEFT JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = ecippi.wRequesterAcc
	--LEFT JOIN dbo.mPersonTravelDoc  ptd ON ptd.RowID = ecippi.wPersonTravelDocRid 
                                                --LEFT JOIN dbo.mLookUp mluppr ON mluppr.wCode = p.wRole
                                                                                --AND mluppr.wLangCd = @pLangCd
                                                                                --AND mluppr.wType = 'PERSON_ROLE'
	--LEFT join dbo.mLookUp  lupit ON lupit.wCode = ptd.wIDType AND lupit.wType = 'ID_TYPE' and lupit.wLangCd=@pLangCd  
                                     ),
                                tCount
                                  AS ( SELECT   wRecordCount = COUNT(1)
                                       FROM     tResult
                                     )
                            SELECT  tResult.* ,
                                    wRecordCount
                            FROM    tResult ,
                                    tCount
                            ORDER BY wUpdDt DESC
                                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS  
	FETCH NEXT @pPageSize ROWS ONLY;  
                    END;
                ELSE
                    BEGIN
                        WITH    cteDocDetails
                               AS ( SELECT   ptdd.wPassengerDetailsRid ,
                                             ptd.wIDNo ,
                                             ptd.wIDType ,
                                             ptd.wEnglishPinyin
                                    FROM     ePassengerTravelDocDetail ptdd
                                             LEFT JOIN dbo.mPersonTravelDoc ptd ON ptd.RowID = ptdd.wPersonTravelDocRid
                                  ),
						    tResult
                                  AS ( SELECT DISTINCT
                                                1 AS wSeqNo ,
                                                ecippi.wSeqNo AS wPassengerSeqNo ,
                                                ISNULL(ecippi.wCost, 0) AS wCost ,
                                                p.wAgentCodeIn wAccount ,
                                                CASE WHEN @pLangCd = 'en-gb' THEN ma.wEName
                                                     ELSE ma.wCName
                                                END AS wAccountName ,
                                                p.wCName ,
                                                p.wGender ,
												p.wBirthdate,
                                                ptd.wIDNo wPersonTravelDocNo ,
                                                ISNULL(ebat.wOrderNo, '') AS WOrderNo ,
                                                ecippi.RowID ,
                                                ecippi.wBookingRid ,
                                                ecippi.wClientTicketNo ,
                                                ecippi.wDepartFlightNo ,
                                                ecippi.wTakeOffDt ,
                                                ecippi.wDestination ,
                                                ecippi.wRequesterAcc ,
                                                ecippi.wPersonRid ,
                                                ecippi.wRemark ,
                                                ecippi.wStatus ,
                                                ecippi.wCrtBy ,
                                                ecippi.wCrtDt ,
                                                ecippi.wUpdDt ,
                                                ecippi.wUpdBy ,
                                                ecippi.wType ,
                                                ecippi.wApplicationType ,
                                                ecippi.wApplicationStatus ,
                                                ecippi.wAmount ,
                                                ISNULL(eb.wCancelReasonCd, '') AS wChangeOrderStatus ,
                                                ISNULL(p.wStatus, '') AS wPersonStatus ,
                                                ISNULL(p.wRole, '') AS wPersonRole ,
			   --ISNULL(eb.wRefNo,'') As wRefNo,
                                                eb.wRefNo + '-' + RIGHT('000' + CAST(( ecippi.wSeqNo ) AS VARCHAR(3)), 3) AS wRefNo ,
                                                ISNULL(p.wNickname, '') AS wNickname ,
												STUFF(( SELECT  ', ' + cdd.wEnglishPinyin
                                                 FROM    cteDocDetails cdd
                                                 WHERE   cdd.wPassengerDetailsRid =ecippi.RowID 
                                                 FOR
                                                XML PATH('')
                                             ), 1, 1, '') AS wEnglishPinyin,
                                                ISNULL(p.wEName, '') AS wEName ,
                                                ptd.wIDType wPersonTravelDocTypeName ,
                                                ecippi.wCasinoCardRid ,
                                                ecippi.wRoomBookingRid ,
                                                ecippi.wCancelBy ,
                                                ecippi.wCancelDebitDt ,
                                                ecippi.wCancelDt ,
                                                ecippi.wCancelReasonCd ,
                                                ecippi.wOtherReason ,
                                                ecippi.wPassengerBookingStatus ,
                                                ecippi.wChangeOrderCount ,
                                                ecippi.wIsWaiting ,
                                                ecippi.wRouteRid ,
                                                '' AS wDepartureAirport ,  -- departure airport
                                                '' AS wArrivalAirport ,  -- ArrivalAirport airport
                                                '' AS wAirportTravelClass , -- travel class
                                                NULL AS wDepartureTime ,  -- departure time
                                                NULL AS wArrivalTime ,  -- Arrival time
                                                NULL AS wReturnDepartureTime,  -- return Departure time
																								'' AS wPsdrtType
                                       FROM     dbo.ePassengerDetails ecippi
                                                INNER JOIN dbo.eBooking eb ON eb.RowID = ecippi.wBookingRid
                                                LEFT JOIN dbo.mPerson p ON p.RowID = ecippi.wPersonRid
                                                LEFT JOIN dbo.eBookingAirTicket ebat ON ebat.wBookingRid = ecippi.wBookingRid
                                                LEFT JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = ecippi.wRequesterAcc
                                                LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON ecippi.RowID = ptdd.wPassengerDetailsRid
				                                LEFT JOIN dbo.mPersonTravelDoc AS ptd ON ptdd.wPersonTravelDocRid = ptd.RowID
                                                ---LEFT JOIN dbo.mLookUp mluppr ON mluppr.wCode = p.wRole
                                                                                --AND mluppr.wLangCd = @pLangCd
                                                                                --AND mluppr.wType = 'PERSON_ROLE'
                                                --LEFT JOIN dbo.mLookUp lupit ON lupit.wCode = ptd.wIDType
                                                                               --AND lupit.wType = 'ID_TYPE'
                                                                               --AND lupit.wLangCd = @pLangCd
                                       WHERE    ( ecippi.wBookingRid = @pBookingRid
                                                  AND ecippi.wType = @pType
                                                )
                                     ),
                                tCount
                                  AS ( SELECT   wRecordCount = COUNT(1)
                                       FROM     tResult
                                     )
                            SELECT  tResult.* ,
                                    wRecordCount
                            FROM    tResult ,
                                    tCount
                            ORDER BY wUpdDt DESC
                                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS  
	FETCH NEXT @pPageSize ROWS ONLY
                        OPTION  ( RECOMPILE );
                    END;
    END;