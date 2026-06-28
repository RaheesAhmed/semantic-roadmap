CREATE PROCEDURE [spq].[GetBookingTravelPackageLst]
    (
      @pRefNo AS VARCHAR(30) ,
      @pFromDebitDt AS DATETIME2 ,
      @pToDebitDt AS DATETIME2 ,
      @pDebitCounterRidXML AS XML ,
      @pReqDeptCode AS VARCHAR(30) ,
      @pFollowUpDeptCode AS VARCHAR(30) ,
      @pDebitAgentCodeIn AS VARCHAR(14) ,
      @pReqAgentCodeIn AS VARCHAR(14) ,
      @pTravelAgencyRid AS BIGINT ,
      @pDeptCd AS VARCHAR(30) ,
      @pPaymentMethod AS VARCHAR(30) ,
      @pStartDt AS DATETIME2 ,
      @pEndDt AS DATETIME2 ,
      @pDestCd AS VARCHAR(30) ,
      @pPkgTypeCd AS VARCHAR(30) ,
      @pBookingStatusXML AS XML ,
      @pSort AS VARCHAR(200) ,
      @pLangCd AS VARCHAR(10) ,
      @pPageSize AS INT ,
      @pPageNum AS INT
    )
AS
    BEGIN
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 

        DECLARE @vFromStartDt AS DATETIME2 = '0001-01-01' ,
            @vToStartDt AS DATETIME2 = '9999-12-31' ,
            @vFromEndtDt AS DATETIME2 = '0001-01-01' ,
            @vToEndtDt AS DATETIME2 = '9999-12-31' ,
            @vDebitCounterRidCount AS INT ,
            @vBookingStatusCount AS INT;

        DECLARE @vData_DebitCounterRid AS TABLE ( SelectionItem BIGINT );

        DECLARE @vData_BookingStatus AS TABLE
            (
              SelectionItem VARCHAR(5)
            );

        IF CAST(@pDebitCounterRidXML AS NVARCHAR(MAX)) != N'<DataSet/>'
            BEGIN
                INSERT  INTO @vData_DebitCounterRid
                        ( SelectionItem
                        )
                        SELECT  tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
                        FROM    @pDebitCounterRidXML.nodes('/DataSet/Record') AS T ( tmp );
            END;

        IF CAST(@pBookingStatusXML AS NVARCHAR(MAX)) != N'<DataSet/>'
            BEGIN
                INSERT  INTO @vData_BookingStatus
                        ( SelectionItem
                        )
                        SELECT  tmp.value('@SelectionItem', 'VARCHAR(5)') AS SelectionItem
                        FROM    @pBookingStatusXML.nodes('/DataSet/Record') AS T ( tmp );
            END;

        SET @vDebitCounterRidCount = ( SELECT   COUNT(1)
                                       FROM     @vData_DebitCounterRid
                                     );
        SET @vBookingStatusCount = ( SELECT COUNT(1)
                                     FROM   @vData_BookingStatus
                                   );
        SET @pRefNo = ISNULL(@pRefNo, '');
        SET @pFromDebitDt = ISNULL(@pFromDebitDt, '0001-01-01');
        SET @pToDebitDt = ISNULL(@pToDebitDt, '9999-12-31');  
        SET @pReqDeptCode = ISNULL(@pReqDeptCode, '');
        SET @pFollowUpDeptCode = ISNULL(@pFollowUpDeptCode, '');
        SET @pDebitAgentCodeIn = ISNULL(@pDebitAgentCodeIn, '');
        SET @pReqAgentCodeIn = ISNULL(@pReqAgentCodeIn, '');
        SET @pTravelAgencyRid = ISNULL(@pTravelAgencyRid, 0);
        SET @pDeptCd = ISNULL(@pDeptCd, '');
        SET @pPaymentMethod = ISNULL(@pPaymentMethod, '');
        IF @pStartDt IS NOT NULL
            BEGIN
                SET @vFromStartDt = @pStartDt;
                SET @vToStartDt = DATEADD(dd, 1, @pStartDt);
            END;		
        IF @pEndDt IS NOT NULL
            BEGIN
                SET @vFromEndtDt = @pEndDt;
                SET @vToEndtDt = DATEADD(dd, 1, @pEndDt);
            END;
        SET @pDestCd = ISNULL(@pDestCd, '');
        SET @pPkgTypeCd = ISNULL(@pPkgTypeCd, '');
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);

        SET NOCOUNT ON;
	
        WITH    ctePassengerDetailsCount
                  AS ( SELECT   wBookingRid ,
                                COUNT(1) AS wPassengerCount
                       FROM     dbo.ePassengerDetails
                       WHERE    wStatus = 'A'
                       GROUP BY wBookingRid
                     ),
				cteTravelPackge AS (
					SELECT wTravePkgRid,
						   wCount = COUNT(*)
					FROM
						(-- Additional Expense
					SELECT eb.wTravePkgRid,
						   eb.RowID
						 FROM dbo.ebooking eb
						 INNER JOIN dbo.eAdditionalExpense ae ON ae.wBookingStatus = 'C'
						 AND ae.wBookingRefRid = eb.RowID -- 此處要關聯 wBookingRefRid 才正確，wBookingRid是其他消費的相關訂務
						 WHERE eb.wTravePkgRid > 0
						 UNION -- Room
					--SELECT eb.wTravePkgRid, eb.RowID
					--	 FROM dbo.ebooking eb
					--	 INNER JOIN dbo.eBookingRoom ebr ON ebr.wBookingStatus = 'C'
					--	 AND ebr.wHotelBookingRid = eb.RowID
					--	 WHERE ebr.wTravelPkgRid > 0
					SELECT eb.wTravePkgRid, eb.RowID
						 FROM dbo.eBookingRoom ebr
                         INNER JOIN dbo.ebooking eb ON eb.RowID=ebr.wBookingRid
						 WHERE ebr.wBookingStatus IN ('C', 'CI', 'CO') AND eb.wTravePkgRid > 0
						 UNION -- Ferry
					SELECT eb.wTravePkgRid,
						   eb.RowID
						 FROM dbo.ebooking eb
						 INNER JOIN dbo.eBookingFerry ebf ON ebf.wBookingStatus = 'C'
						 AND ebf.wBookingRid = eb.RowID
						 WHERE eb.wTravePkgRid > 0
						 UNION -- Air Ticket
					SELECT eb.wTravePkgRid,
						   eb.RowID
						 FROM dbo.ebooking eb
						 INNER JOIN dbo.eBookingAirTicket ebat ON ebat.wBookingStatus = 'C'
						 AND ebat.wBookingRid = eb.RowID
						 WHERE eb.wTravePkgRid > 0
						 UNION -- Heli
					SELECT eb.wTravePkgRid,
						   eb.RowID
						 FROM dbo.ebooking eb
						 INNER JOIN dbo.eBookingHeli ebh ON ebh.wBookingStatus = 'C'
						 AND ebh.wBookingRid = eb.RowID
						 WHERE eb.wTravePkgRid > 0
						 UNION -- Show Ticket
					SELECT eb.wTravePkgRid,
						   eb.RowID
						 FROM dbo.ebooking eb
						 INNER JOIN dbo.eBookingShow ebst ON ebst.wBookingStatus = 'C'
						 AND ebst.wBookingRid = eb.RowID
						 WHERE eb.wTravePkgRid > 0
						 UNION -- Restaurant
					SELECT eb.wTravePkgRid,
						   eb.RowID
						 FROM dbo.ebooking eb
						 INNER JOIN dbo.eBookingRestaurant ebr ON ebr.wBookingStatus = 'C'
						 AND ebr.wBookingRid = eb.RowID
						 WHERE eb.wTravePkgRid > 0
						 UNION -- Private Plane
					SELECT eb.wTravePkgRid,
						   eb.RowID
						 FROM dbo.ebooking eb
						 INNER JOIN dbo.eBookingPrivatePlane ebpp ON ebpp.wBookingStatus = 'C'
						 AND ebpp.wBookingRid = eb.RowID
						 WHERE eb.wTravePkgRid > 0
						 UNION -- Check In Service
					SELECT eb.wTravePkgRid,
						   eb.RowID
						 FROM dbo.ebooking eb
						 INNER JOIN dbo.eBookingCheckInService ebcis ON ebcis.wBookingStatus = 'C'
						 AND ebcis.wBookingRid = eb.RowID
						 WHERE eb.wTravePkgRid > 0
						 UNION -- Visa
					SELECT eb.wTravePkgRid,
						   eb.RowID
						 FROM dbo.ebooking eb
						 INNER JOIN dbo.eBookingVisa ebv ON ebv.wBookingStatus = 'C'
						 AND ebv.wBookingRid = eb.RowID
						 WHERE eb.wTravePkgRid > 0
						 UNION -- Pick Up Service
					SELECT eb.wTravePkgRid,
						   eb.RowID
						 FROM dbo.ebooking eb
						 INNER JOIN dbo.eBookingPickUpService ebpus ON ebpus.wBookingStatus = 'C'
						 AND ebpus.wBookingRid = eb.RowID
						 WHERE eb.wTravePkgRid > 0
						 UNION -- Leading
					SELECT eb.wTravePkgRid,
						   eb.RowID
						 FROM dbo.ebooking eb
						 INNER JOIN dbo.eBookingLeading ebl ON ebl.wBookingStatus = 'C'
						 AND ebl.wBookingRid = eb.RowID
						 WHERE eb.wTravePkgRid > 0
						 UNION -- Tour
					SELECT eb.wTravePkgRid,
						   eb.RowID
						 FROM dbo.ebooking eb
						 INNER JOIN dbo.eBookingTourGuide ebtg ON ebtg.wBookingStatus = 'C'
						 AND ebtg.wBookingRid = eb.RowID
						 WHERE eb.wTravePkgRid > 0) AS u
					GROUP BY wTravePkgRid
				),
                tResult
                  AS ( SELECT   ebtp.RowID ,
                                ebtp.wBookingRid ,
                                ebtp.wStartDt ,
                                ebtp.wEndDt ,
                                ebtp.wDeptCd ,
                                ebtp.wDestCd ,
                                ebtp.wPkgTypeCd ,
                                ebtp.wPaymentMethod ,
                                ebtp.wCurrCode ,
                                ebtp.wExpAmt ,
                                ebtp.wTotalAmt ,
                                ebtp.wTotalCost ,
                                ebtp.wRemark ,
                                ebtp.wBookingStatus ,
                                ebtp.wUnqualifiedRid ,
                                ebtp.wReceiptNo ,
								ebtp.wOrderNo ,
                                ebtp.wSeqNo ,
                                ebtp.wCrtDt ,
                                ebtp.wCrtBy ,
                                ebtp.wUpdDt ,
                                ebtp.wUpdBy ,
                                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
                                eb.wRefNo ,
                                eb.wBookingType ,
                                eb.RowID AS bookingRowID ,
                                eb.wDebitCounterRid wDebitServiceCounter ,
                                sc.wName AS wDebitServiceCounterName ,
                                eb.wDebitAgentCodeIn wDebitAccount ,
                                CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName
                                     ELSE daAgent.wCName
                                END AS wDebitAccountName ,
                                eb.wDebitCustomerRid wDebitClient ,
                                '' AS wDebitClientName ,
                                ebtp.wStatus ,
                                eb.wDebitDt ,
                                eb.wReqDepartment ,
                                msc.wName AS wRequestedServiceCounter ,
                                CASE WHEN @pLangCd = 'en-gb' THEN rqusr.wName
                                     ELSE rqusr.wCName
                                END AS wReqUserRidByCName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN sfusr.wName
                                     ELSE sfusr.wCName
                                END AS wStaffFollwedRidByCName ,
                                daAgent.wAgentCode_Display ,
                                rqAgent.wAgentCode_Display AS wReqAgentCode_Display ,
                                eb.wAsstBooker ,
                                ta.wName AS wTravelAgencyRidByName ,
                                cdc.wPassengerCount ,
                                wFinishedBookingCount = ISNULL(ctp.wCount, 0),
								-- dbo.fnGetFinishedBookingCountByTravelPkgRid(ebtp.RowID) AS wFinishedBookingCount ,
                                CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName
                                     ELSE daAgent.wCName
                                END AS wAgentCodeByName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN rqAgent.wEName
                                     ELSE rqAgent.wCName
                                END AS wReqAgentCodeByName ,
                                eb.wDeptFollwedCd ,
                                wAgentCodeIn = eb.wDebitAgentCodeIn
                       FROM     dbo.eBookingTravelPackage ebtp
                                LEFT JOIN dbo.eBooking eb ON eb.RowID = ebtp.wBookingRid
                                INNER JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
                                LEFT JOIN [RollsMary].[dbo].[mAgent] rqAgent ON rqAgent.wAgentCodeIn = eb.wReqAgentCodeIn
                                INNER JOIN dbo.mServiceCounter sc ON sc.RowID = eb.wDebitCounterRid
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ebtp.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ebtp.wCrtBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] rqusr ON rqusr.RowID = eb.wReqUserRid
                                LEFT JOIN [RollsMary].[dbo].[mUsr] sfusr ON sfusr.RowID = eb.wStaffFollwedRid
                                LEFT JOIN dbo.mServiceCounter msc ON msc.RowID = eb.wReqCounterRid
                                LEFT JOIN dbo.mTravelAgency ta ON ta.RowID = ebtp.wTravelAgencyRid
                                LEFT JOIN ctePassengerDetailsCount cdc ON cdc.wBookingRid = eb.RowID
								LEFT JOIN cteTravelPackge ctp ON ctp.wTravePkgRid = ebtp.RowID
                                LEFT JOIN @vData_DebitCounterRid v ON v.SelectionItem = eb.wDebitCounterRid
                                LEFT JOIN @vData_BookingStatus vs ON vs.SelectionItem = ebtp.wBookingStatus
                       WHERE    ( @pRefNo = ''
                                  OR @pRefNo = eb.wRefNo
                                )
                                AND ( @pFromDebitDt <= eb.wDebitDt
                                      AND @pToDebitDt >= eb.wDebitDt
                                    )
                                AND ( @vDebitCounterRidCount <= 0
                                      OR v.SelectionItem IS NOT NULL
                                    )
                                AND ( @pReqDeptCode = ''
                                      OR @pReqDeptCode = eb.wReqDepartment
                                    )
                                AND ( @pFollowUpDeptCode = ''
                                      OR @pFollowUpDeptCode = eb.wDeptFollwedCd
                                    )
                                AND ( @pDebitAgentCodeIn = ''
                                      OR @pDebitAgentCodeIn = eb.wDebitAgentCodeIn
                                    )
                                AND ( @pReqAgentCodeIn = ''
                                      OR @pReqAgentCodeIn = eb.wReqAgentCodeIn
                                    )
                                AND ( @pTravelAgencyRid = 0
                                      OR @pTravelAgencyRid = ebtp.wTravelAgencyRid
                                    )
                                AND ( @pDeptCd = ''
                                      OR @pDeptCd = ebtp.wDeptCd
                                    )
                                AND ( @pPaymentMethod = ''
                                      OR @pPaymentMethod = ebtp.wPaymentMethod
                                    )
                                AND ( @vFromStartDt <= ebtp.wStartDt
                                      AND @vToStartDt >= ebtp.wStartDt
                                    )
                                AND ( @vFromEndtDt <= ebtp.wEndDt
                                      AND @vToEndtDt >= ebtp.wEndDt
                                    )
                                AND ( @pDestCd = ''
                                      OR @pDestCd = ebtp.wDestCd
                                    )
                                AND ( @pPkgTypeCd = ''
                                      OR @pPkgTypeCd = ebtp.wPkgTypeCd
                                    )
                                AND ( @vBookingStatusCount <= 0
                                      OR vs.SelectionItem IS NOT NULL
                                    )
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(*)
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
		  FETCH NEXT @pPageSize ROWS ONLY
          OPTION(RECOMPILE);
    END;