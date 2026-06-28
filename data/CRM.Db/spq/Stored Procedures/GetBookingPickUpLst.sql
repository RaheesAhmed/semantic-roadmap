
CREATE PROCEDURE [spq].[GetBookingPickUpLst]
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
      @pOrderNo AS VARCHAR(20) ,
      @pApplyDt AS DATETIME2 ,
      @pServiceType AS VARCHAR(3) ,
      @pPaymentMethod AS VARCHAR(30) ,
      @pBookingStatusXML AS XML ,
      @pSort AS VARCHAR(200) ,
      @pLangCd AS VARCHAR(10) ,
      @pPageSize AS INT ,
      @pPageNum AS INT
    )
AS
    BEGIN    
	-- SET NOCOUNT ON added to prevent extra result sets from    
	-- interfering with SELECT statements.    
        SET NOCOUNT ON;    
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        DECLARE @vFromDt AS DATETIME2 = '0001-01-01' ,
            @vToDt AS DATETIME2 = '9999-12-31' ,
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
        SET @pOrderNo = ISNULL(@pOrderNo, '');
        IF @pApplyDt IS NOT NULL
            BEGIN
                SET @vFromDt = @pApplyDt;
                SET @vToDt = DATEADD(dd, 1, @pApplyDt);
            END;
        SET @pServiceType = ISNULL(@pServiceType, '');
        SET @pPaymentMethod = ISNULL(@pPaymentMethod, '');
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);		       

        WITH    tResult
                  AS ( SELECT   ROW_NUMBER() OVER ( ORDER BY ps.RowID ) AS wSeqNo ,
                                ps.[RowID] ,
                                ps.[wBookingRid] ,
                                eb.[wRefNo] ,
                                eb.[wTravePkgRid] ,
                                mta.wName AS wAgencyName ,
                                ps.[wOrderNo] ,
                                ps.[wServiceType] ,
                                ps.[wApplyDt] ,
                                ps.[wCurrCode] ,
                                ps.[wTotalAmt] ,
                                ps.[wStatus] ,
                                ps.[wBookingStatus] ,
                                eb.[wDebitDt] ,
                                ps.[wReceiptNo] ,
                                ps.[wDepartDt] ,
                                ps.[wArrivalDt] ,
                                ps.[wUpdBy] ,
                                ps.[wUpdDt] ,
                                eb.wReqDepartment ,
                                eb.wReqCounterRid AS wRequestedServiceCounterid ,
                                wAgentCodeIn = eb.wDebitAgentCodeIn ,
                                scr.wName AS requestedServiceCounter ,
                                daAgent.wAgentCode_Display ,
                                '' AS wDebitClientName ,
                                sc.wName AS wDebitServiceCounterName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
                                msc.wName AS wRequestedServiceCounter ,
                                CASE WHEN @pLangCd = 'en-gb' THEN rqusr.wName
                                     ELSE rqusr.wCName
                                END AS wReqUserRidByCName ,
                                eb.wDeptFollwedCd ,
                                CASE WHEN @pLangCd = 'en-gb' THEN sfusr.wName
                                     ELSE sfusr.wCName
                                END AS wStaffFollwedRidByCName ,
                                rqAgent.wAgentCode_Display AS wReqAgentCode_Display ,
                                eb.wAsstBooker ,
                                ps.wPaymentMethod ,
                                ta.wName AS wTravelAgencyRidByName ,
                                ps.wFlightNo ,
                                CASE WHEN dpAirport.wCode IS NOT NULL THEN dpAirport.wCode + ', '
                                     ELSE dpAirport.wCode
                                END AS wDepartAirportByCode ,
                                CASE WHEN dpAirport.wCName IS NOT NULL THEN dpAirport.wCName + ', '
                                     ELSE dpAirport.wCName
                                END AS wDepartAirportByName ,
                                dpAirport.wCity AS wDepartAirportByCityCode ,
                                CASE WHEN dtAirport.wCode IS NOT NULL THEN dtAirport.wCode + ', '
                                     ELSE dtAirport.wCode
                                END AS wDestinationByCode ,
                                CASE WHEN dtAirport.wCName IS NOT NULL THEN dtAirport.wCName + ', '
                                     ELSE dtAirport.wCName
                                END AS wDestinationByName ,
                                dtAirport.wCity AS wDestinationByCityCode ,
                                eb.wDepositAmt ,
                                wClient = bm.wValue,
                                CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName
                                     ELSE daAgent.wCName
                                END AS wAgentCodeByName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN rqAgent.wEName
                                     ELSE rqAgent.wCName
                                END AS wReqAgentCodeByName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN mec.wEName
                                     ELSE mec.wCName
                                END AS wEventCodeByName
                       FROM     dbo.eBookingPickUpService ps
                                INNER JOIN dbo.eBooking eb ON eb.RowID = ps.wBookingRid
                                INNER JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
                                LEFT JOIN [RollsMary].[dbo].[mAgent] rqAgent ON rqAgent.wAgentCodeIn = eb.wReqAgentCodeIn
                                LEFT JOIN dbo.eBookingTravelPackage ebtp ON ebtp.RowID = eb.wTravePkgRid
                                INNER JOIN dbo.mServiceCounter sc ON sc.RowID = eb.wDebitCounterRid
                                LEFT JOIN dbo.mServiceCounter scr ON scr.RowID = eb.wReqCounterRid
                                LEFT JOIN dbo.mTravelAgency mta ON mta.RowID = ps.wTravelAgencyRid
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ps.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ps.wCrtBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] rqusr ON rqusr.RowID = eb.wReqUserRid
                                LEFT JOIN [RollsMary].[dbo].[mUsr] sfusr ON sfusr.RowID = eb.wStaffFollwedRid
                                LEFT JOIN dbo.mServiceCounter msc ON msc.RowID = eb.wReqCounterRid
                                LEFT JOIN dbo.mTravelAgency ta ON ta.RowID = ps.wTravelAgencyRid
                                LEFT JOIN dbo.mAirport dpAirport ON dpAirport.RowID = ps.wDepartAirport
                                LEFT JOIN dbo.mAirport dtAirport ON dtAirport.RowID = ps.wDestination
                                LEFT JOIN stg.eBookingMisc bm ON bm.wBookingRid = ps.wBookingRid AND bm.wLangCd = @pLangCd AND bm.wItemCd = 'CUST_NAME'
                                LEFT JOIN @vData_DebitCounterRid v ON v.SelectionItem = eb.wDebitCounterRid
                                LEFT JOIN @vData_BookingStatus vs ON vs.SelectionItem = ps.wBookingStatus
						  LEFT JOIN dbo.mEventCode mec ON mec.RowID = eb.wEventCodeRid
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
                                      OR @pTravelAgencyRid = ps.wTravelAgencyRid
                                    )
                                AND ( @pOrderNo = ''
                                      OR @pOrderNo = ps.wOrderNo
                                    )
                                AND ( @vFromDt <= ps.wApplyDt
                                      AND @vToDt >= ps.wApplyDt
                                    )
                                AND ( @pServiceType = ''
                                      OR @pServiceType = ps.wServiceType
                                    )
                                AND ( @pPaymentMethod = ''
                                      OR @pPaymentMethod = ps.wPaymentMethod
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