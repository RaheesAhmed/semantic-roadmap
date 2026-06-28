

CREATE PROCEDURE [test].[GetAirTicketPassengerLst]
    (
      @pFromDebitDt DATETIME2 ,
      @pToDebitDt DATETIME2 ,
      @pDebitDt DATETIME2 ,
      @pDebitAgentCodeIn VARCHAR(14) ,
      @pReqAgentCodeIn VARCHAR(14) ,
      @pRefNo VARCHAR(30) ,
      @pSeqNo INT ,
      @pFlightType VARCHAR(30) ,
      @pCName NVARCHAR(50) ,
      @pEName VARCHAR(500) ,
      @pEnglishPinyin NVARCHAR(100) ,
      @pIDType VARCHAR(30) ,
      @pIDNo VARCHAR(30) ,
      @pDepartureAirportRid BIGINT ,
      @pTakeOffDt DATETIME2 ,
      @pArrivalnDepartAirportRid BIGINT ,
      @pArrivalnTakeOffDt DATETIME2 ,
      @pArrivalAirportRid BIGINT ,
      @pArrivalDt DATETIME2 ,
      @pDepartFlightNo VARCHAR(20) ,
      @pClassCd NVARCHAR(50) ,
      @pIsCompAcc CHAR(1) ,
      @pBookingStatusXML XML ,
      @pSort VARCHAR(200) ,
      @pPageSize INT ,
      @pPageNum INT ,
      @pLangCd VARCHAR(10)
    )
AS
    BEGIN 

	-- SET NOCOUNT ON added to prevent extra result sets from 
        SET NOCOUNT ON;

        DECLARE @vFromTakeOffDt AS DATETIME2 = '0001-01-01' ,
            @vToTakeOffDt AS DATETIME2 = '9999-12-31' ,
            @vFromArrivalnTakeOffDt AS DATETIME2 = '0001-01-01' ,
            @vToArrivalnTakeOffDt AS DATETIME2 = '9999-12-31' ,
            @vFromArrivalDt AS DATETIME2 = '0001-01-01' ,
            @vToArrivalDt AS DATETIME2 = '9999-12-31' ,
            @vBookingStatusCount INT;

        DECLARE @vData_BookingStatus AS TABLE
            (
              SelectionItem VARCHAR(5)
            );

        IF CAST(@pBookingStatusXML AS NVARCHAR(MAX)) != N'<DataSet/>'
            BEGIN
                INSERT  INTO @vData_BookingStatus
                        ( SelectionItem
                        )
                        SELECT  tmp.value('@SelectionItem', 'VARCHAR(5)') AS SelectionItem
                        FROM    @pBookingStatusXML.nodes('/DataSet/Record') AS T ( tmp );
            END;

        SET @vBookingStatusCount = ( SELECT COUNT(1)
                                     FROM   @vData_BookingStatus
                                   );
        SET @pFromDebitDt = ISNULL(@pFromDebitDt, '0001-01-01');
        SET @pToDebitDt = ISNULL(@pToDebitDt, '9999-12-31');  
        IF @pDebitDt IS NOT NULL
            BEGIN
                SET @pFromDebitDt = @pDebitDt;                                    
                SET @pToDebitDt = DATEADD(dd, 1, @pDebitDt);                                  
            END;
        SET @pDebitAgentCodeIn = ISNULL(@pDebitAgentCodeIn, '');
        SET @pReqAgentCodeIn = ISNULL(@pReqAgentCodeIn, '');		
        SET @pRefNo = ISNULL(@pRefNo, '');
        SET @pSeqNo = ISNULL(@pSeqNo, 0);
        SET @pFlightType = ISNULL(@pFlightType, '');
        SET @pEName = ISNULL(@pEName, '');
        SET @pCName = ISNULL(@pCName, '');
        SET @pEnglishPinyin = ISNULL(@pEnglishPinyin, '');
        SET @pIDType = ISNULL(@pIDType, '');
        SET @pIDNo = ISNULL(@pIDNo, '');
        SET @pDepartureAirportRid = ISNULL(@pDepartureAirportRid, 0);
        IF @pTakeOffDt IS NOT NULL
            BEGIN
                SET @vFromTakeOffDt = @pTakeOffDt;                                    
                SET @vToTakeOffDt = DATEADD(dd, 1, @pTakeOffDt);                                  
            END;
        SET @pArrivalnDepartAirportRid = ISNULL(@pArrivalnDepartAirportRid, 0);
        IF @pArrivalnTakeOffDt IS NOT NULL
            BEGIN
                SET @vFromArrivalnTakeOffDt = @pArrivalnTakeOffDt;                                    
                SET @vToArrivalnTakeOffDt = DATEADD(dd, 1, @pArrivalnTakeOffDt);                                  
            END;
        SET @pArrivalAirportRid = ISNULL(@pArrivalAirportRid, 0);
        IF @pArrivalDt IS NOT NULL
            BEGIN
                SET @vFromArrivalDt = @pArrivalDt;                                    
                SET @vToArrivalDt = DATEADD(dd, 1, @pArrivalDt);                                  
            END;
        SET @pDepartFlightNo = ISNULL(@pDepartFlightNo, '');
        SET @pClassCd = ISNULL(@pClassCd, '');
        SET @pIsCompAcc = ISNULL(@pIsCompAcc, ' ');
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);
	
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 

        WITH    cteDocDetails
                  AS ( SELECT   ptdd.wPassengerDetailsRid ,
                                ptd.wIDNo ,
                                ptd.wIDType ,
                                ptd.wEnglishPinyin
                       FROM     ePassengerTravelDocDetail ptdd
                                LEFT JOIN dbo.mPersonTravelDoc ptd ON ptd.RowID = ptdd.wPersonTravelDocRid
                     ),
                cteFirstRouteDtl
                  AS ( SELECT   fard.wArrivalAirportRid ,
                                fard.wTypeRid ,
                                fard.wType ,
                                fard.wClassCd ,
                                fard.wAirline ,
                                fard.wDepartureAirportRid ,
                                fard.wTakeOffDt ,
                                fard.wArrivalDt ,
                                fard.wDepartFlightNo ,
                                fdptma.wCode + ', ' + CASE WHEN @pLangCd = 'en-gb' THEN fdptma.wEName
                                                           ELSE fdptma.wCName
                                                      END + ', ' AS wDepartAirport ,
                                fdptma.wCity AS wDepartAirportCity ,
                                farvma.wCode + ', ' + CASE WHEN @pLangCd = 'en-gb' THEN farvma.wEName
                                                           ELSE farvma.wCName
                                                      END + ', ' AS wArrivalAirport ,
                                farvma.wCity AS wArrivalAirportCity
                       FROM     dbo.eAirTicketRouteDtl fard
                                LEFT JOIN dbo.mAirport fdptma ON fdptma.RowID = fard.wDepartureAirportRid
                                LEFT JOIN dbo.mAirport farvma ON farvma.RowID = fard.wArrivalAirportRid
                       WHERE    fard.wLine = 1
                                AND fard.wStatus = 'A'
                     ),
                cteLastRouteDtl
                  AS ( SELECT   lard.wArrivalAirportRid ,
                                lard.wTypeRid ,
                                lard.wType ,
                                lard.wDepartureAirportRid ,
                                lard.wTakeOffDt ,
                                lard.wArrivalDt ,
                                lard.wDepartFlightNo ,
						  larvma.wCode + ', ' + CASE WHEN @pLangCd = 'en-gb' THEN larvma.wEName
                                                           ELSE larvma.wCName
                                                      END + ', ' AS wAirport ,
						  larvma.wCity AS wCity
                       FROM     dbo.eAirTicketRouteDtl lard
                                INNER JOIN ( SELECT wTypeRid ,
                                                    MAX(wLine) AS wLine
                                             FROM   dbo.eAirTicketRouteDtl
                                             WHERE  wStatus = 'A'
                                                    AND wIsReturn != 'Y'
                                             GROUP BY wTypeRid
                                           ) larl ON larl.wTypeRid = lard.wTypeRid
                                                     AND larl.wLine = lard.wLine
                                                     AND lard.wStatus = 'A'
                                LEFT JOIN dbo.mAirport larvma ON larvma.RowID = lard.wArrivalAirportRid
                     ),
                cteReturnRouteDtl
                  AS ( SELECT   lard.wArrivalAirportRid ,
                                lard.wTypeRid ,
                                lard.wType ,
                                lard.wDepartureAirportRid ,
                                lard.wTakeOffDt ,
                                lard.wArrivalDt ,
                                lard.wDepartFlightNo ,
						  ldptma.wCode + ', ' + CASE WHEN @pLangCd = 'en-gb' THEN ldptma.wEName
                                                           ELSE ldptma.wCName
                                                      END + ', ' AS wAirport ,
						  ldptma.wCity AS wCity
                       FROM     dbo.eAirTicketRouteDtl lard
                                INNER JOIN ( SELECT wTypeRid ,
										  MIN(wLine) AS wLine
								     FROM	  dbo.eAirTicketRouteDtl
									WHERE  wStatus = 'A'
										  AND wIsReturn = 'Y'
										  AND wLine != 1
								     GROUP BY wTypeRid
                                           ) larl ON larl.wTypeRid = lard.wTypeRid
                                                     AND larl.wLine = lard.wLine
                                                     AND lard.wStatus = 'A'
                                LEFT JOIN dbo.mAirport ldptma ON ldptma.RowID = lard.wDepartureAirportRid
                     ),
                tResult
                  AS ( SELECT   DISTINCT
                                psd.RowID ,
                                psd.wBookingRid ,
                                eb.wRefNo ,
                                eb.wDebitDt ,
                                daAgent.wAgentCode_Display ,
                                eb.wReqAgentCodeIn ,
                                rqAgent.wAgentCode_Display AS wReqAgentCode_Display ,
                                ps.wCName ,
                                ISNULL(ps.wEName, '') AS wEName ,
                                STUFF(( SELECT  ', ' + cdd.wIDNo
                                        FROM    cteDocDetails cdd
                                        WHERE   cdd.wPassengerDetailsRid = dd.wPassengerDetailsRid
                                      FOR
                                        XML PATH('')
                                      ), 1, 1, '') AS wIDNo ,
                                STUFF(( SELECT  ',' + cdd.wIDType
                                        FROM    cteDocDetails cdd
                                        WHERE   cdd.wPassengerDetailsRid = dd.wPassengerDetailsRid
                                      FOR
                                        XML PATH('')
                                      ), 1, 1, '') AS wIDType ,
                                STUFF(( SELECT  ', ' + cdd.wEnglishPinyin
                                        FROM    cteDocDetails cdd
                                        WHERE   cdd.wPassengerDetailsRid = dd.wPassengerDetailsRid
                                      FOR
                                        XML PATH('')
                                      ), 1, 1, '') AS wEnglishPinyin ,
                                ps.wGender ,
                                psd.wClientTicketNo ,
                                ebat.wFlightType ,
                                COALESCE(pfrd.wClassCd, afrd.wClassCd, '') AS wClassCd ,
                                COALESCE(pfrd.wAirline, afrd.wAirline, '') AS wAirline ,
                                COALESCE(pfrd.wDepartFlightNo, afrd.wDepartFlightNo, '') AS wDepartFlightNo ,
                                COALESCE(pfrd.wDepartAirport, afrd.wDepartAirport, '') AS wDepartureAirport ,
                                COALESCE(pfrd.wDepartAirportCity, afrd.wDepartAirportCity, '') AS wDepartAirportCityCd ,
                                COALESCE(pfrd.wArrivalAirport, afrd.wArrivalAirport, '') AS wArrivalAirport ,
                                COALESCE(pfrd.wArrivalAirportCity, afrd.wArrivalAirportCity, '') AS wArrivalAirportCityCd ,
                                COALESCE(pfrd.wTakeOffDt, afrd.wTakeOffDt, '') AS wTakeOffDt ,
                                COALESCE(pfrd.wArrivalDt, afrd.wArrivalDt, '') AS wArrivalDt ,
                                COALESCE(pfrd.wDepartAirport, afrd.wDepartAirport, '') AS wFirstDepartureAirport ,
                                COALESCE(pfrd.wDepartAirportCity, afrd.wDepartAirportCity, '') AS wFirstDepartAirportCityCd ,
                                COALESCE(pfrd.wTakeOffDt, afrd.wTakeOffDt, '') AS wFirstTakeOffDt ,
                                COALESCE(pfrd.wDepartFlightNo, afrd.wDepartFlightNo, '') AS wFirstDepartFlightNo ,
                                COALESCE(prrd.wAirport, plrd.wAirport, arrd.wAirport, alrd.wAirport, '') AS wLastAirport ,
                                COALESCE(prrd.wCity, plrd.wCity, arrd.wCity, alrd.wCity, '') AS wLastCityCd ,
                                COALESCE(prrd.wTakeOffDt, plrd.wTakeOffDt, arrd.wTakeOffDt, alrd.wTakeOffDt, '') AS wLastDt ,
                                COALESCE(prrd.wDepartFlightNo, plrd.wDepartFlightNo, arrd.wDepartFlightNo, alrd.wDepartFlightNo, '') AS wLastFlightNo ,
                                psd.wChangeOrderCount ,
                                psd.wIsWaiting ,
                                psd.wAmount ,
                                psd.wCost ,
                                psd.wPassengerBookingStatus ,
                                psd.wCrtDt ,
                                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByName ,
                                psd.wSeqNo ,
                                ebat.wBookingStatus ,
                                psd.wExpiryDt AS wPassengerExpiryDate ,
                                ebat.wCurrCode ,
                                ps.wAgentCodeIn ,
                                psd.wCheckInServiceBookingRid ,
                                psd.wIsValidDateLessThanSixMnth ,
                                psd.wType ,
                                psd.wDestination ,
                                psd.wAirlineId ,
                                psd.wOtherReason ,
                                psd.wCancelReasonCd ,
                                psd.wCancelDebitDt ,
                                psd.wCancelDt ,
                                psd.wStatus ,
                                psd.wPersonRid ,
                                psd.wAirTicketGroupBookingRid ,
                                psd.wAirTicketBookingRid ,
                                psd.wRefRid ,
                                psd.wUpdDt ,
                                psd.wCrtBy ,
                                psd.wRemark ,
                                psd.wPersonTravelDocRid ,
                                psd.wRequesterAcc ,
                                psd.wClientBookingId ,
                                psd.wPrivatePlaneBookingId ,
                                psd.wTakeOffDt AS wTakeOffDtInDetail ,
                                eb.wExpDt ,
                                CASE WHEN ai.wAgentCodeIn IS NOT NULL THEN 'Y'
                                     ELSE 'N'
                                END AS wIsCompAcc
                       FROM     dbo.ePassengerDetails psd
                                INNER JOIN dbo.eBooking eb ON eb.RowID = psd.wBookingRid
                                INNER JOIN dbo.eBookingAirTicket ebat ON ebat.wBookingRid = eb.RowID
                                LEFT JOIN RollsMary.dbo.mAgent daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
                                LEFT JOIN RollsMary.dbo.mAgent rqAgent ON rqAgent.wAgentCodeIn = eb.wReqAgentCodeIn
                                LEFT JOIN dbo.mPerson ps ON ps.RowID = psd.wPersonRid
                                LEFT JOIN cteDocDetails dd ON dd.wPassengerDetailsRid = psd.RowID
                                LEFT JOIN cteFirstRouteDtl pfrd ON pfrd.wType = 'PASSENGER'
                                                                   AND pfrd.wTypeRid = psd.RowID
                                LEFT JOIN cteLastRouteDtl plrd ON plrd.wType = 'PASSENGER'
                                                                  AND plrd.wTypeRid = psd.RowID
                                LEFT JOIN cteReturnRouteDtl prrd ON prrd.wType = 'PASSENGER'
                                                                  AND prrd.wTypeRid = psd.RowID
                                LEFT JOIN cteFirstRouteDtl afrd ON afrd.wType = 'AIRTICKET'
                                                                   AND afrd.wTypeRid = ebat.RowID
                                LEFT JOIN cteLastRouteDtl alrd ON alrd.wType = 'AIRTICKET'
                                                                  AND alrd.wTypeRid = ebat.RowID
                                LEFT JOIN cteReturnRouteDtl arrd ON arrd.wType = 'AIRTICKET'
                                                                  AND arrd.wTypeRid = ebat.RowID
                                LEFT JOIN dbo.eAirTicketRouteDtl prdf ON prdf.wType = 'PASSENGER'
                                                                         AND prdf.wTypeRid = psd.RowID
                                LEFT JOIN dbo.eAirTicketRouteDtl ardf ON ardf.wType = 'AIRTICKET'
                                                                         AND ardf.wTypeRid = psd.RowID
                                LEFT JOIN RollsMary.dbo.[mUsr] usr ON usr.RowID = psd.wUpdBy
                                LEFT JOIN @vData_BookingStatus vs ON vs.SelectionItem = ebat.wBookingStatus
                                LEFT JOIN RollsMary.dbo.mAgentIdentity ai ON ai.wType = 'COMPANY_ACCT'
                                                                             AND ai.wValue = 'Y'
                                                                             AND ai.wAgentCodeIn = eb.wReqAgentCodeIn
                       WHERE    ( @pFromDebitDt <= eb.wDebitDt
                                  AND @pToDebitDt >= eb.wDebitDt
                                )
                                AND ( @pDebitAgentCodeIn = ''
                                      OR @pDebitAgentCodeIn = eb.wDebitAgentCodeIn
                                    )
                                AND ( @pReqAgentCodeIn = ''
                                      OR @pReqAgentCodeIn = eb.wReqAgentCodeIn
                                    )
                                AND ( @pRefNo = ''
                                      OR @pSeqNo = 0
                                      OR ( eb.wRefNo = @pRefNo
                                           AND psd.wSeqNo = @pSeqNo
                                         )
                                    )
                                AND ( @pCName = ''
                                      OR @pCName = ps.wCName
                                    )
                                AND ( @pFlightType = ''
                                      OR @pFlightType = ebat.wFlightType
                                    )
                                AND ( @pEName = ''
                                      OR @pEName = ps.wEName
                                    )
                                AND ( @pEnglishPinyin = ''
                                      OR @pEnglishPinyin = dd.wEnglishPinyin
                                    )
                                AND ( @pIDType = ''
                                      OR @pIDType = dd.wIDType
                                    )
                                AND ( @pIDNo = ''
                                      OR @pIDNo = dd.wIDNo
                                    )
                                AND ( @pDepartureAirportRid = 0
                                      OR @pDepartureAirportRid = pfrd.wDepartureAirportRid
                                      OR @pDepartureAirportRid = afrd.wDepartureAirportRid
                                    )
                                AND ( ( @vFromTakeOffDt <= pfrd.wTakeOffDt
                                        AND @vToTakeOffDt >= pfrd.wTakeOffDt
                                      )
                                      OR ( @vFromTakeOffDt <= afrd.wTakeOffDt
                                           AND @vToTakeOffDt >= afrd.wTakeOffDt
                                         )
                                    )
                                AND ( @pArrivalAirportRid = 0
                                      OR @pArrivalAirportRid = pfrd.wArrivalAirportRid
                                      OR @pDepartureAirportRid = afrd.wArrivalAirportRid
                                    )
                                AND ( ( @vFromArrivalDt <= pfrd.wArrivalDt
                                        AND @vToArrivalDt >= pfrd.wArrivalDt
                                      )
                                      OR ( @vFromArrivalDt <= afrd.wArrivalDt
                                           AND @vToArrivalDt >= afrd.wArrivalDt
                                         )
                                    )
                                AND ( @pDepartFlightNo = ''
                                      OR @pDepartFlightNo = pfrd.wDepartFlightNo
                                      OR @pDepartFlightNo = afrd.wDepartFlightNo
                                    )
                                AND ( @pClassCd = ''
                                      OR @pClassCd = pfrd.wClassCd
                                      OR @pClassCd = afrd.wClassCd
                                    )
                                AND ( @pArrivalnDepartAirportRid = 0
                                      OR @pArrivalnDepartAirportRid = prdf.wDepartureAirportRid
                                      OR @pArrivalnDepartAirportRid = prdf.wArrivalAirportRid
                                      OR @pArrivalnDepartAirportRid = ardf.wDepartureAirportRid
                                      OR @pArrivalnDepartAirportRid = ardf.wArrivalAirportRid
                                    )
                                AND ( ( prdf.wTakeOffDt IS NULL
                                        OR ( @vFromArrivalnTakeOffDt <= prdf.wTakeOffDt
                                             AND @vToArrivalnTakeOffDt >= prdf.wTakeOffDt
                                           )
                                      )
                                      OR ( prdf.wArrivalDt IS NULL
                                           OR ( @vFromArrivalnTakeOffDt <= prdf.wArrivalDt
                                                AND @vToArrivalnTakeOffDt >= prdf.wArrivalDt
                                              )
                                         )
                                      OR ( ardf.wTakeOffDt IS NULL
                                           OR ( @vFromArrivalnTakeOffDt <= ardf.wTakeOffDt
                                                AND @vToArrivalnTakeOffDt >= ardf.wTakeOffDt
                                              )
                                         )
                                      OR ( ardf.wArrivalDt IS NULL
                                           OR ( @vFromArrivalnTakeOffDt <= ardf.wArrivalDt
                                                AND @vToArrivalnTakeOffDt >= ardf.wArrivalDt
                                              )
                                         )
                                    )
                                AND ( @pIsCompAcc = ' '
                                      OR ( @pIsCompAcc = 'Y'
                                           AND ai.wAgentCodeIn IS NOT NULL
                                         )
                                      OR ( @pIsCompAcc = 'N'
                                           AND ai.wAgentCodeIn IS NULL
                                         )
                                    )
                                AND ( @vBookingStatusCount <= 0
                                      OR vs.SelectionItem IS NOT NULL
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
            ORDER BY CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wDebitDt
                     END DESC ,
                    CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wRefNo
                    END DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS  
	FETCH NEXT @pPageSize ROWS ONLY;  
    END;