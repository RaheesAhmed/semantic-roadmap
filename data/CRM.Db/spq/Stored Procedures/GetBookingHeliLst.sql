--預訂編號 (default null)
--航班時間開始 (default 今天, not allow null)
--航班時間結束 (default 今天, not allow null)
--扣數日期開始 (default 今天, not allow null)
--扣數日期結束 (default 今天, not allow null)
--航線 (default null)
--扣數日期 (default null)
--扣數戶口 (default null)
--扣數櫃台 (default by login user, allow multiple choice)
--要求部門 (default null)
--跟進部門 (default null)
--單號/確認號 (default null)
--供應商 (default null)
--狀態原因 (default 完成)

CREATE PROCEDURE [spq].[GetBookingHeliLst]
    (
      @pOrderNo VARCHAR(30) ,
      @pFromDebitDt DATETIME2 ,
      @pToDebitDt DATETIME2 ,
      @pFromDepartureDt DATETIME2 ,
      @pToDepartureDt DATETIME2 ,
      @pRouteRid BIGINT ,
      @pDebitDt DATETIME2 ,
      @pDebitAgentCodeIn AS VARCHAR(14) ,
      @pDebitCounterRidXML XML ,
      @pReqDeptCd VARCHAR(30) ,
      @pFollowUpDeptCd VARCHAR(30) ,
      @pRefNo VARCHAR(30) ,
      @pReqAgentCodeIn AS VARCHAR(14) ,
      @pBookingLocation VARCHAR(20) ,
      @pBookingStatusXML AS XML ,
      @pSort VARCHAR(200) ,
      @pLangCd VARCHAR(10) ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1 ,
      @pBookingRefRid BIGINT = 0
    )
AS
    BEGIN
        SET NOCOUNT ON;
	
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;						

        DECLARE @sDocHandle INT ,
            @vDebitCounterRidCount INT ,
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
        SET @pReqDeptCd = ISNULL(@pReqDeptCd, '');
        SET @pFollowUpDeptCd = ISNULL(@pFollowUpDeptCd, '');
        SET @pRefNo = ISNULL(@pRefNo, '');
        SET @pBookingLocation = ISNULL(@pBookingLocation, '');
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'zh-tw'));
        SET @pBookingRefRid = ISNULL(@pBookingRefRid, 0);
        SET @pReqAgentCodeIn = ISNULL(@pReqAgentCodeIn, '');

        WITH    tResult
                  AS ( SELECT   ebh.RowID ,
                                ebh.wBookingRid ,
                                ebh.wTicketId ,
                                ebh.wBookingStatus ,
                                ebh.wUnqualifiedRid ,
                                eb.wDebitDt ,
                                eb.wRefNo AS wTicketNo ,
                                ebh.wPaymentMethod ,
                                ebh.wCurrCode ,
                                ebh.wTotalAmt ,
                                ebh.wOrderNo ,
                                ebh.wBookingLocation ,
                                r.wRouteFrom ,
                                r.wRouteTo ,
                                sc.wName AS wDebitServiceCounterName ,
                                ebh.wDepartDt ,
                                wDepartDateTime = FORMAT(ebh.wDepartDt, 'yyyy-MM-dd HH:mm:ss'), -- 時間要用字符串，否則有時區偏差問題
                                ebh.wQuantity ,
                                ebh.wIsCharteredFlight ,
                                ebh.wUpdDt ,
                                eb.wDebitCounterRid ,
                                wAgentCodeIn = eb.wDebitAgentCodeIn ,
                                daAgent.wAgentCode_Display ,
                                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
                                ebh.wChangeOrderCount ,
                                eb.wReqDepartment ,
                                CASE WHEN @pLangCd = 'en-gb' THEN rqusr.wName
                                     ELSE rqusr.wCName
                                END AS wReqUserRidByCName ,
                                eb.wDeptFollwedCd ,
                                CASE WHEN @pLangCd = 'en-gb' THEN sfusr.wName
                                     ELSE sfusr.wCName
                                END AS wStaffFollwedRidByCName ,
                                rqAgent.wAgentCode_Display AS wReqAgentCode_Display ,
                                ebh.wRemark ,
                                eb.wAsstBooker ,
                                eb.wAssBookerTel ,
                                CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName
                                     ELSE daAgent.wCName
                                END AS wAgentCodeByName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN rqAgent.wEName
                                     ELSE rqAgent.wCName
                                END AS wReqAgentCodeByName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN mec.wEName
                                     ELSE mec.wCName
                                END AS wEventCodeByName
                       FROM     [dbo].eBookingHeli ebh
                                INNER JOIN dbo.eBooking eb ON eb.RowID = ebh.wBookingRid AND ebh.wStatus = 'A'
                                INNER JOIN dbo.mServiceCounter sc ON sc.RowID = eb.wDebitCounterRid
                                LEFT JOIN dbo.mRoute r ON r.RowID = ebh.wRouteRid
                                LEFT JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ebh.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ebh.wCrtBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] rqusr ON rqusr.RowID = eb.wReqUserRid
                                LEFT JOIN [RollsMary].[dbo].[mUsr] sfusr ON sfusr.RowID = eb.wStaffFollwedRid
                                LEFT JOIN [RollsMary].[dbo].[mAgent] rqAgent ON rqAgent.wAgentCodeIn = eb.wReqAgentCodeIn
                                LEFT JOIN @vData_DebitCounterRid v ON eb.wDebitCounterRid = v.SelectionItem
                                LEFT JOIN @vData_BookingStatus vs ON vs.SelectionItem = ebh.wBookingStatus
                                LEFT JOIN dbo.mEventCode mec ON mec.RowID = eb.wEventCodeRid
                       WHERE    ( @pOrderNo = ''
                                  OR @pOrderNo = ebh.wOrderNo
                                )
                                AND ( @pFromDebitDt <= eb.wDebitDt
                                      AND @pToDebitDt >= eb.wDebitDt
                                    )
                                AND ( @pFromDepartureDt <= ebh.wDepartDt
                                      AND @pToDepartureDt >= ebh.wDepartDt
                                    )
                                AND ( @pRouteRid = ''
                                      OR @pRouteRid = ebh.wRouteRid
                                    )
                                AND ( @pDebitAgentCodeIn = ''
                                      OR @pDebitAgentCodeIn = eb.wDebitAgentCodeIn
                                    )
                                AND ( @vDebitCounterRidCount <= 0
                                      OR v.SelectionItem IS NOT NULL
                                    )
                                AND ( @pReqDeptCd = ''
                                      OR @pReqDeptCd = eb.wReqDepartment
                                    )
                                AND ( @pFollowUpDeptCd = ''
                                      OR @pFollowUpDeptCd = eb.wDeptFollwedCd
                                    )
                                AND ( @pRefNo = ''
                                      OR @pRefNo = eb.wRefNo
                                    )
                                AND ( @pBookingLocation = ''
                                      OR @pBookingLocation = ebh.wBookingLocation
                                    )
                                AND ( @vBookingStatusCount <= 0
                                      OR vs.SelectionItem IS NOT NULL
                                    )
                                AND ( @pBookingRefRid <= 0
                                      OR @pBookingRefRid = ebh.wBookingRid
                                    )
                                AND ( @pReqAgentCodeIn = ''
                                      OR @pReqAgentCodeIn = eb.wReqAgentCodeIn
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
                    CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wTicketNo
                    END DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		   FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );
    END;