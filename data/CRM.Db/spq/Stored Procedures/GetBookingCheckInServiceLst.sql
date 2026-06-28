
CREATE PROCEDURE [spq].[GetBookingCheckInServiceLst]
    (
      @pRefNo VARCHAR(30) ,
      @pFromDebitDt DATETIME2 ,
      @pToDebitDt DATETIME2 ,
      @pDebitCounterRidXML XML ,
      @pReqDeptCode VARCHAR(30) ,
      @pFollowUpDeptCode VARCHAR(30) ,
      @pDebitAgentCodeIn VARCHAR(14) ,
      @pReqAgentCodeIn VARCHAR(14) ,
      @pSupplier AS BIGINT ,
      @pFlightNo AS VARCHAR(30) ,
      @pDepartDt AS DATETIME2 ,
      @pArrivalTimeToG15nG16 AS DATETIME2 ,
      @pOrderNo AS VARCHAR(20) ,
      @pVIPRoom AS CHAR(1) ,
      @pPaymentMethod VARCHAR(30) ,
      @pBookingStatusXML XML ,
      @pSort VARCHAR(200) ,
      @pPageSize INT ,
      @pPageNum INT ,
      @pLangCd VARCHAR(10)
    )
AS
    BEGIN  
        SET NOCOUNT ON;

        DECLARE @vFromDepartDt AS DATETIME2 = '0001-01-01' ,
            @vToDepartDt AS DATETIME2 = '9999-12-31' ,
            @vFromArrivalTimeToG15nG16 AS DATETIME2 = '0001-01-01' ,
            @vToArrivalTimeToG15nG16 AS DATETIME2 = '9999-12-31' ,
            @vDebitCounterRidCount AS INT ,
            @vBookingStatusCount INT;

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
        SET @pSupplier = ISNULL(@pSupplier, 0);
        SET @pFlightNo = ISNULL(@pFlightNo, '');
        IF @pDepartDt IS NOT NULL
            BEGIN
                SET @vFromDepartDt = @pDepartDt;
                SET @vToDepartDt = DATEADD(dd, 1, @pDepartDt);
            END;
        IF @pArrivalTimeToG15nG16 IS NOT NULL
            BEGIN
                SET @vFromArrivalTimeToG15nG16 = @pArrivalTimeToG15nG16;
                SET @vToArrivalTimeToG15nG16 = DATEADD(dd, 1, @pArrivalTimeToG15nG16);
            END;
        SET @pOrderNo = ISNULL(@pOrderNo, '');
        SET @pVIPRoom = ISNULL(@pVIPRoom, ' ');
        SET @pPaymentMethod = ISNULL(@pPaymentMethod, '');
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-GB'));       
        SET @pPageSize = ISNULL(@pPageSize, 999);
        SET @pPageNum = ISNULL(@pPageNum, 1);
		                                             
        WITH    tResult
                  AS ( SELECT DISTINCT
                                ecis.RowId ,
                                ecis.wBookingRid ,
                                wAgentCodeIn = eb.wDebitAgentCodeIn ,
                                eb.wDebitDt ,
                                CASE WHEN eb.wCancelBy IS NULL THEN -1
                                     ELSE eb.wCancelBy
                                END AS wCancelBy ,
                                SC.wName AS wDebitServiceCounterName ,
                                daAgent.wAgentCode_Display ,
                                ecis.wOrderNo ,
                                tc.wTicCollPoint ,
                                mtc.wName AS wTicCollPointByName ,
                                wTotalAmt ,
                                eb.wReqDepartment ,
                                eb.wRefNo ,
                                ecis.wArrivalTimeToG15nG16 ,
                                ecis.wVIPRoom ,
                                CAST(ecis.wQuantity AS INT) AS wQuantity ,
                                ecis.wFlightNo ,
                                ecis.wDepartDt ,
                                ecis.wCrtDt ,
                                ecis.wCrtBy ,
                                ecis.wUpdDt ,
                                ecis.wUpdBy ,
                                ecis.wBookingStatus ,
                                ecis.wPaymentMethod ,
                                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
                                ecis.wStatus ,
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
                                wClient = bm.wValue,
                                eb.wDepositAmt ,
                                ta.wName AS wTravelAgencyRidByName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName
                                     ELSE daAgent.wCName
                                END AS wAgentCodeByName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN rqAgent.wEName
                                     ELSE rqAgent.wCName
                                END AS wReqAgentCodeByName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN mec.wEName
                                     ELSE mec.wCName
                                END AS wEventCodeByName
                       FROM     [CRM].[dbo].eBookingCheckInService ecis
                                INNER JOIN dbo.eBooking eb ON eb.RowID = ecis.wBookingRid
                                INNER JOIN dbo.mServiceCounter SC ON SC.RowID = eb.wDebitCounterRid
                                INNER JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
                                LEFT JOIN dbo.eTicketCollection tc ON tc.wBookingRid = ecis.wBookingRid
                                LEFT JOIN mTicketCollectionPoint mtc ON mtc.wCode = tc.wTicCollPoint
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ecis.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ecis.wCrtBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] rqusr ON rqusr.RowID = eb.wReqUserRid
                                LEFT JOIN [RollsMary].[dbo].[mUsr] sfusr ON sfusr.RowID = eb.wStaffFollwedRid
                                LEFT JOIN dbo.mServiceCounter msc ON msc.RowID = eb.wReqCounterRid
                                LEFT JOIN [RollsMary].[dbo].[mAgent] rqAgent ON rqAgent.wAgentCodeIn = eb.wReqAgentCodeIn
                                LEFT JOIN dbo.mTravelAgency ta ON ta.RowID = ecis.wSupplier
                                LEFT JOIN stg.eBookingMisc bm ON bm.wBookingRid = ecis.wBookingRid AND bm.wLangCd = @pLangCd AND bm.wItemCd = 'CUST_NAME'
                                LEFT JOIN @vData_DebitCounterRid v ON v.SelectionItem = eb.wDebitCounterRid
                                LEFT JOIN @vData_BookingStatus vs ON vs.SelectionItem = ecis.wBookingStatus
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
                                AND ( @pSupplier = 0
                                      OR @pSupplier = ecis.wSupplier
                                    )
                                AND ( @pFlightNo = ''
                                      OR @pFlightNo = ecis.wFlightNo
                                    )
                                AND ( @vFromDepartDt <= ecis.wDepartDt
                                      AND @vToDepartDt >= ecis.wDepartDt
                                    )
                                AND ( @vFromArrivalTimeToG15nG16 <= ecis.wArrivalTimeToG15nG16
                                      AND @vToArrivalTimeToG15nG16 >= ecis.wArrivalTimeToG15nG16
                                    )
                                AND ( @pOrderNo = ''
                                      OR @pOrderNo = ecis.wOrderNo
                                    )
                                AND ( @pVIPRoom = ' '
                                      OR @pVIPRoom = ecis.wVIPRoom
                                    )
                                AND ( @pPaymentMethod = ''
                                      OR @pPaymentMethod = ecis.wPaymentMethod
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
		FETCH NEXT @pPageSize ROWS ONLY
        --OPTION(RECOMPILE);
                      
    END;