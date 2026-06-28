/*預訂編號 (default null)
扣數日期開始 (default 今天, not allow null)
扣數日期結束 (default 今天, not allow null)
航班時間開始 (default 今天, not allow null)
航班時間結束 (default 今天, not allow null)
航線 (default null)
扣數日期 (default null)
扣數戶口 (default null)
扣數櫃台 (default null)
要求部門 (default null)
跟進部門 (default null)
單號/確認號 (default null)
供應商 (default null)
艙等 (default null)
取票地點 (default by login user, allow multiple choice)
已取票 (default null)
狀態 (default 完成)
*/
CREATE PROCEDURE [spq].[GetBookingFerryLst]
    (
      @pOrderNo AS VARCHAR(20) ,
      @pFromDebitDt AS DATETIME2 ,
      @pToDebitDt AS DATETIME2 ,
      @pFromDepartureDt AS DATETIME2 ,
      @pToDepartureDt AS DATETIME2 ,
      @pRouteRid AS BIGINT ,
      @pDebitDt AS DATETIME2 ,
      @pDebitAgentCodeIn AS VARCHAR(14) ,
      @pDebitCounterRidXML AS XML ,
      @pReqDeptCode AS VARCHAR(30) ,
      @pFollowUpDeptCode AS VARCHAR(30) ,
      @pClassCd AS VARCHAR(30) ,
      @pTicketCollectionCdXML AS XML ,
      @pIsTicketCollected AS VARCHAR(10) ,
	  @pWaived AS CHAR(1) ,
      @pRefNo AS VARCHAR(30) ,
      @pReqAgentCodeIn AS VARCHAR(14) ,
      @pTravelAgencyRid AS BIGINT ,
      @pTicketTypeXML AS XML ,
      @pBookingRefRid AS BIGINT ,
      @pSort AS VARCHAR(200) ,
      @pBookingStatusXML AS XML ,
      @pURLType AS VARCHAR(20),
      @pLangCd AS VARCHAR(10) ,
      @pPageNum AS INT ,
      @pPageSize AS INT             
    )
AS
    BEGIN	
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;		

        DECLARE @vDebitCounterRidCount INT ,
            @vTicketCollectionCdCount INT ,
            @vTicketTypeCount INT ,
		  @vBookingStatusCount INT;

        DECLARE @vData_DebitCounterRid AS TABLE ( SelectionItem BIGINT );

        DECLARE @vData_TicketCollectionCd AS TABLE ( SelectionItem BIGINT );

        DECLARE @vData_TicketType AS TABLE
            (
              SelectionItem VARCHAR(30)
            );

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

        IF CAST(@pTicketCollectionCdXML AS NVARCHAR(MAX)) != N'<DataSet/>'
            BEGIN
                INSERT  INTO @vData_TicketCollectionCd
                        ( SelectionItem
                        )
                        SELECT  tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
                        FROM    @pTicketCollectionCdXML.nodes('/DataSet/Record') AS T ( tmp );
            END;

        IF CAST(@pTicketTypeXML AS NVARCHAR(MAX)) != N'<DataSet/>'
            BEGIN
                INSERT  INTO @vData_TicketType
                        ( SelectionItem
                        )
                        SELECT  tmp.value('@SelectionItem', 'VARCHAR(30)') AS SelectionItem
                        FROM    @pTicketTypeXML.nodes('/DataSet/Record') AS T ( tmp );
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
        SET @vTicketCollectionCdCount = ( SELECT    COUNT(1)
                                          FROM      @vData_TicketCollectionCd
                                        );
        SET @vTicketTypeCount = ( SELECT    COUNT(1)
                                  FROM      @vData_TicketType
                                );
        SET @vBookingStatusCount = ( SELECT COUNT(1)
                                     FROM   @vData_BookingStatus
                                   );

        SET @pOrderNo = ISNULL(@pOrderNo, '');
        SET @pFromDebitDt = ISNULL(@pFromDebitDt, '0001-01-01');
        SET @pToDebitDt = ISNULL(@pToDebitDt, '9999-12-31');  
        SET @pFromDepartureDt = ISNULL(@pFromDepartureDt, '0001-01-01');
        SET @pToDepartureDt = ISNULL(@pToDepartureDt, '9999-12-31');
        SET @pRouteRid = ISNULL(@pRouteRid, 0);
        IF @pDebitDt IS NOT NULL
            BEGIN
                SET @pFromDebitDt = @pDebitDt;                                    
                SET @pToDebitDt = DATEADD(dd, 1, @pDebitDt);                                  
            END;	
        SET @pDebitAgentCodeIn = ISNULL(@pDebitAgentCodeIn, '');
        SET @pReqDeptCode = ISNULL(@pReqDeptCode, '');
        SET @pFollowUpDeptCode = ISNULL(@pFollowUpDeptCode, '');
        SET @pClassCd = ISNULL(@pClassCd, '');
        SET @pIsTicketCollected = ISNULL(@pIsTicketCollected, '');
	    SET @pWaived = ISNULL(@pWaived, ' ');
        SET @pRefNo = ISNULL(@pRefNo, '');
        SET @pReqAgentCodeIn = ISNULL(@pReqAgentCodeIn, '');
        SET @pTravelAgencyRid = ISNULL(@pTravelAgencyRid, 0);
        SET @pBookingRefRid = ISNULL(@pBookingRefRid, 0);        
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'zh-tw'));
        SET @pPageSize = ISNULL(@pPageSize, 20);
        SET @pPageNum = ISNULL(@pPageNum, 1);
        SET @pURLType = ISNULL(@pURLType, '');
	    
        WITH    tResult
                  AS ( SELECT   ebf.RowID ,
                                eb.wDebitDt ,
                                ebf.wBookingRid ,
                                eb.wRefNo ,
                                wAgentCodeIn = eb.wDebitAgentCodeIn ,
                                eb.wDebitCounterRid wDebitServiceCounter ,
                                sc.wName AS wDebitServiceCounterName ,
                                eb.wDebitAgentCodeIn wDebitAccount ,
                                eb.wDepositAmt ,
                                daAgent.wAgentCode_Display ,
                                eb.wDebitCustomerRid wDebitClient ,
                                '' AS wDebitClientName ,
                                ebf.wPaymentMethod ,
                                ebf.wTotalAmt ,
                                ebf.wRouteRid ,
                                ebf.wDepartDt ,
                                ebf.wQuantity ,
                                ebf.wClassCd ,
                                ebf.wTicketType ,
                                ebf.wCurrCode ,
                                ebf.wOrderNo ,
                                ebf.wReceiptNo ,
                                ebf.wUnitAmt ,
                                ebf.wSeqNo ,
                                ebf.wExpAmt ,
                                ebf.wCost ,
                                ebf.wRemark ,
                                ebf.wStatus ,
                                ebf.wBookingStatus ,
                                ebf.wUnqualifiedRid ,
                                ebf.wUseBlackCard ,
                                ebf.wWaived ,
                                ebf.wCrtDt ,
                                ebf.wCrtBy ,
                                ebf.wUpdDt ,
                                ebf.wUpdBy ,
                                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
                                --CASE WHEN r.wIsTwoWay = 'Y'
                                --     THEN r.wRouteFrom + '<->' + r.wRouteTo
                                --     ELSE r.wRouteFrom + '->' + r.wRouteTo
                                --END AS wRoute ,
                                CASE WHEN r.wIsTwoWay = 'Y' THEN lpFrom.wTitle + '<->' + lpTo.wTitle
                                     ELSE lpFrom.wTitle + '->' + lpTo.wTitle
                                END AS wRoute ,
                                wTicketId ,
                                eb.wReqDepartment ,
                                CASE WHEN @pLangCd = 'en-gb' THEN rqusr.wName
                                     ELSE rqusr.wCName
                                END AS wReqUserRidByCName ,
                                eb.wDeptFollwedCd ,
                                CASE WHEN @pLangCd = 'en-gb' THEN sfusr.wName
                                     ELSE sfusr.wCName
                                END AS wStaffFollwedRidByCName ,
                                rqAgent.wAgentCode_Display AS wReqAgentCode_Display ,
                                eb.wAsstBooker ,
                                eb.wAssBookerTel ,
                                ta.wName AS wTravelAgencyRidByName ,
                                mtc.wName AS wTicCollPointByName ,
                                tc.wIsCollected ,
                                CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName
                                     ELSE daAgent.wCName
                                END AS wAgentCodeByName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN rqAgent.wEName
                                     ELSE rqAgent.wCName
                                END AS wReqAgentCodeByName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN mec.wEName
                                     ELSE mec.wCName
                                END AS wEventCodeByName,
                                ebf.wURLType
                       FROM     [CRM].[dbo].eBookingFerry ebf
                                INNER JOIN dbo.eBooking eb ON eb.RowID = ebf.wBookingRid
                                INNER JOIN dbo.mServiceCounter sc ON sc.RowID = eb.wDebitCounterRid
                                LEFT JOIN dbo.mRoute r ON r.RowID = ebf.wRouteRid
                                LEFT JOIN mLookUp lpTo ON lpTo.wCode = r.wRouteTo
                                                          AND lpTo.wLangCd = @pLangCd
                                                          AND ( r.wVehicle = 'FERRY'
                                                                AND lpTo.wType = 'FERRY_ROUTE_LOCATION'
                                                              )
                                LEFT JOIN mLookUp lpFrom ON lpFrom.wCode = r.wRouteFrom
                                                            AND lpFrom.wLangCd = @pLangCd
                                                            AND ( r.wVehicle = 'FERRY'
                                                                  AND lpFrom.wType = 'FERRY_ROUTE_LOCATION'
                                                                )
                                INNER JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
                                LEFT JOIN dbo.eTicketCollection tc ON tc.wBookingRid = ebf.wBookingRid
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ebf.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ebf.wCrtBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] rqusr ON rqusr.RowID = eb.wReqUserRid
                                LEFT JOIN [RollsMary].[dbo].[mUsr] sfusr ON sfusr.RowID = eb.wStaffFollwedRid
                                LEFT JOIN dbo.mTicketCollectionPoint mtc ON mtc.wCode = tc.wTicCollPoint
                                                                            AND mtc.wIsFerryTic = 'Y'
                                LEFT JOIN dbo.mTravelAgency ta ON ta.RowID = ebf.wTravelAgencyRid
                                LEFT JOIN [RollsMary].[dbo].[mAgent] rqAgent ON rqAgent.wAgentCodeIn = eb.wReqAgentCodeIn
                                LEFT JOIN @vData_DebitCounterRid v ON eb.wDebitCounterRid = v.SelectionItem
                                LEFT JOIN @vData_TicketCollectionCd vtc ON mtc.RowID = vtc.SelectionItem
                                LEFT JOIN @vData_TicketType vt ON ebf.wTicketType = vt.SelectionItem
                                LEFT JOIN @vData_BookingStatus vs ON vs.SelectionItem = ebf.wBookingStatus
						        LEFT JOIN dbo.mEventCode mec ON mec.RowID = eb.wEventCodeRid
                       WHERE    ( @pOrderNo = ''OR @pOrderNo = ebf.wOrderNo )
                                AND ( @pFromDebitDt <= eb.wDebitDt AND @pToDebitDt >= eb.wDebitDt )
                                AND ( @pFromDepartureDt <= ebf.wDepartDt AND @pToDepartureDt >= ebf.wDepartDt )
                                AND ( @pRouteRid = '' OR @pRouteRid = ebf.wRouteRid )
                                AND ( @pDebitAgentCodeIn = '' OR @pDebitAgentCodeIn = eb.wDebitAgentCodeIn )
                                AND ( @vDebitCounterRidCount <= 0 OR v.SelectionItem IS NOT NULL )
                                AND ( @pReqDeptCode = '' OR @pReqDeptCode = eb.wReqDepartment )
                                AND ( @pFollowUpDeptCode = '' OR @pFollowUpDeptCode = eb.wDeptFollwedCd )
                                AND ( @pClassCd = ''  OR @pClassCd = ebf.wClassCd )
                                AND ( @vTicketCollectionCdCount <= 0 OR vtc.SelectionItem IS NOT NULL )
                                AND ( @pIsTicketCollected = '' OR @pIsTicketCollected = tc.wIsCollected
                                      OR ( @pIsTicketCollected = 'false'
                                           AND tc.wIsCollected IS NULL
                                         )
                                    )
						        AND ( @pWaived = ' ' OR @pWaived = ebf.wWaived )
                                AND ( @pRefNo = '' OR @pRefNo = eb.wRefNo )
                                AND ( @pReqAgentCodeIn = '' OR @pReqAgentCodeIn = eb.wReqAgentCodeIn )
                                AND ( @pTravelAgencyRid = 0 OR @pTravelAgencyRid = ebf.wTravelAgencyRid )
                                AND ( @vTicketTypeCount <= 0 OR vt.SelectionItem IS NOT NULL )
                                AND ( @vBookingStatusCount <= 0 OR vs.SelectionItem IS NOT NULL )
                                AND ( @pBookingRefRid <= 0 OR @pBookingRefRid = ebf.wBookingRid )
                                AND ( @pURLType = ''  OR @pURLType = ebf.wURLType )
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
        OPTION  ( RECOMPILE );		
    END;