
/*預訂編號 (default null)
(表演)日期/時間 開始 (default 今天, not allow null)
(表演)日期/時間 結束 (default 今天, not allow null)
到票 (default NO) 未取得相關門票
取票地點 (default by login user, allow multiple choice)
已取票 (default 未取)
扣數戶口 (default null)
扣數櫃台 (default null)
要求部門 (default null)
跟進部門 (default null)
狀態原因 (default 完成)
*/

CREATE PROCEDURE [spq].[GetBookingShowLst]
(
    @pRefNo AS VARCHAR(30) ,
    @pHaveTicket AS CHAR(1) ,
    @pFromDebitDt AS DATETIME2 ,
    @pToDebitDt AS DATETIME2 ,
    @pFromShowDt AS DATETIME2 ,
    @pToShowDt AS DATETIME2 ,
    @pTicketCollectionCdXML AS XML ,
    @pShowRid AS BIGINT ,
    @pReqAgentCodeIn AS VARCHAR(14) ,
    @pDebitAgentCodeIn AS VARCHAR(14) ,
    @pDebitCounterRidXML AS XML ,
    @pReqDeptCode AS VARCHAR(30) ,
    @pFollowUpDeptCode AS VARCHAR(30) ,
    @pIsTicketCollected AS VARCHAR(10) ,
    @pBookingStatusXML AS XML ,
    @pSort AS VARCHAR(200) ,
    @pLangCd AS VARCHAR(10) ,
    @pPageSize AS INT ,
    @pPageNum AS INT 
)
AS
    BEGIN  
        SET NOCOUNT ON;
		
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        DECLARE @vDebitCounterRidCount INT ,
                @vTicketCollectionCdCount INT ,
                @vBookingStatusCount AS INT;
        
        DECLARE @vData_DebitCounterRid AS TABLE ( wDebitCounterRid BIGINT );
        DECLARE @vData_BookingStatus AS TABLE ( wBookingStatus VARCHAR(5) );
        DECLARE @vData_TicketCollectionCd AS TABLE ( wTicketCollectionCd BIGINT );

        IF CAST(@pDebitCounterRidXML AS NVARCHAR(MAX)) != N'<DataSet/>'
        BEGIN
            INSERT  INTO @vData_DebitCounterRid ( wDebitCounterRid )
            SELECT  tmp.value('@SelectionItem', 'BIGINT') AS wDebitCounterRid
            FROM    @pDebitCounterRidXML.nodes('/DataSet/Record') AS T ( tmp );
        END;

        IF CAST(@pBookingStatusXML AS NVARCHAR(MAX)) != N'<DataSet/>'
        BEGIN
            INSERT  INTO @vData_BookingStatus ( wBookingStatus )
            SELECT  tmp.value('@SelectionItem', 'VARCHAR(5)') AS wBookingStatus
            FROM    @pBookingStatusXML.nodes('/DataSet/Record') AS T ( tmp );
        END;

        IF CAST(@pTicketCollectionCdXML AS NVARCHAR(MAX)) != N'<DataSet/>'
        BEGIN
            INSERT  INTO @vData_TicketCollectionCd ( wTicketCollectionCd )
            SELECT  tmp.value('@SelectionItem', 'BIGINT') AS wTicketCollectionCd
            FROM    @pTicketCollectionCdXML.nodes('/DataSet/Record') AS T ( tmp );
        END;

        SET @vDebitCounterRidCount = ( SELECT COUNT(1) FROM @vData_DebitCounterRid );
        SET @vBookingStatusCount = ( SELECT COUNT(1) FROM @vData_BookingStatus );
        SET @vTicketCollectionCdCount = ( SELECT COUNT(1) FROM @vData_TicketCollectionCd );
        
        SET @pRefNo = NULLIF(@pRefNo, '');
        SET @pHaveTicket = NULLIF(@pHaveTicket, ' ');
        SET @pFromDebitDt = CAST(ISNULL(@pFromDebitDt, '0001-01-01') AS DATE);
        SET @pToDebitDt = CAST(ISNULL(@pToDebitDt, '9999-12-31') AS DATE);
        SET @pFromShowDt = CAST(ISNULL(@pFromShowDt, '0001-01-01') AS DATE);
        SET @pToShowDt = CAST(ISNULL(@pToShowDt, '9999-12-31') AS DATE); 
        SET @pShowRid = IIF(@pShowRid <= 0, NULL, @pShowRid);
        SET @pReqAgentCodeIn = NULLIF(@pReqAgentCodeIn, '');
        SET @pDebitAgentCodeIn = NULLIF(@pDebitAgentCodeIn, '');
        SET @pReqDeptCode = NULLIF(@pReqDeptCode, '');
        SET @pFollowUpDeptCode = NULLIF(@pFollowUpDeptCode, '');
        SET @pIsTicketCollected = NULLIF(@pIsTicketCollected, '');
        SET @pSort = ISNULL(NULLIF(@pSort, ''), '||');
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-GB'));
        SET @pPageSize = ISNULL(IIF(@pPageSize <= 0 , NULL, @pPageSize), 999);
        SET @pPageNum = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);
		
        WITH tResult AS (
            SELECT
                bs.RowID ,
                bs.wBookingRid ,
                eb.wRefNo ,
                wTicCollPointByName = mtc.wName ,
                tc.wIsCollected ,
                bs.wHaveTicket ,
                eb.wDebitDt ,
                wDebitServiceCounterName = SC.wName ,
                eb.wReqDepartment ,
                wReqUserRidByCName = CASE WHEN @pLangCd = 'en-gb' THEN rqusr.wName ELSE rqusr.wCName END,
                eb.wDeptFollwedCd ,
                wStaffFollwedRidByCName = CASE WHEN @pLangCd = 'en-gb' THEN sfusr.wName ELSE sfusr.wCName END ,
                daAgent.wAgentCode_Display ,
                wReqAgentCode_Display = rqAgent.wAgentCode_Display ,
                eb.wAsstBooker ,
                eb.wAssBookerTel ,
                bs.wOrderNo ,
                wShowName = ms.wName ,
                bs.wOtherName ,
                bs.wShowDt ,
                bs.wTotalQuantity ,
                bs.wCurrCode ,
                bs.wTotalAmt ,
                wTravelAgencyRidByName = ta.wName ,
                wRequestedServiceCounter = msc.wName ,
                bs.wBookingStatus ,
                bs.wUpdBy ,
                bs.wUpdDt ,
                daAgent.wAgentCodeIn ,
                wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END,
                wAgentCodeByName = CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName ELSE daAgent.wCName END,
                wReqAgentCodeByName = CASE WHEN @pLangCd = 'en-gb' THEN rqAgent.wEName ELSE rqAgent.wCName END ,
                wEventCodeByName = CASE WHEN @pLangCd = 'en-gb' THEN mec.wEName ELSE mec.wCName END
            FROM dbo.eBookingShow bs
            INNER JOIN dbo.eBooking eb ON eb.RowID = bs.wBookingRid
            INNER JOIN RollsMary.dbo.mAgent daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
            INNER JOIN dbo.mServiceCounter SC ON SC.RowID = eb.wDebitCounterRid
            LEFT JOIN dbo.mServiceCounter msc ON msc.RowID = eb.wReqCounterRid
            LEFT JOIN dbo.mShow ms ON ms.RowID = bs.wShowRid
            LEFT JOIN dbo.eTicketCollection tc ON tc.wBookingRid = bs.wBookingRid
            LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = bs.wUpdBy
            LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = bs.wCrtBy
            LEFT JOIN dbo.mTicketCollectionPoint mtc ON mtc.wCode = tc.wTicCollPoint
            LEFT JOIN RollsMary.dbo.mUsr rqusr ON rqusr.RowID = eb.wReqUserRid
            LEFT JOIN RollsMary.dbo.mAgent rqAgent ON rqAgent.wAgentCodeIn = eb.wReqAgentCodeIn
            LEFT JOIN RollsMary.dbo.mUsr sfusr ON sfusr.RowID = eb.wStaffFollwedRid
            LEFT JOIN dbo.mTravelAgency ta ON ta.RowID = bs.wTravelAgencyRid
            LEFT JOIN @vData_DebitCounterRid v ON eb.wDebitCounterRid = v.wDebitCounterRid
            LEFT JOIN @vData_TicketCollectionCd vtc ON mtc.RowID = vtc.wTicketCollectionCd
            LEFT JOIN @vData_BookingStatus vs ON vs.wBookingStatus = bs.wBookingStatus
            LEFT JOIN dbo.mEventCode mec ON mec.RowID = eb.wEventCodeRid
            WHERE ( @pRefNo IS NULL OR @pRefNo = eb.wRefNo )
                AND ( @pHaveTicket IS NULL OR @pHaveTicket = bs.wHaveTicket )
                AND ( @pFromDebitDt <= eb.wDebitDt AND @pToDebitDt >= eb.wDebitDt )
                AND ( @pFromShowDt <= bs.wShowDt AND @pToShowDt >= bs.wShowDt )
                AND ( @vTicketCollectionCdCount <= 0 OR vtc.wTicketCollectionCd IS NOT NULL )
                AND ( @pShowRid IS NULL OR @pShowRid = bs.wShowRid )
                AND ( @pReqAgentCodeIn IS NULL OR @pReqAgentCodeIn = eb.wReqAgentCodeIn )
                AND ( @pDebitAgentCodeIn IS NULL OR @pDebitAgentCodeIn = eb.wDebitAgentCodeIn )
                AND ( @vDebitCounterRidCount <= 0 OR v.wDebitCounterRid IS NOT NULL )
                AND ( @pReqDeptCode IS NULL OR @pReqDeptCode = eb.wReqDepartment )
                AND ( @pFollowUpDeptCode IS NULL OR @pFollowUpDeptCode = eb.wDeptFollwedCd )
                AND ( @pIsTicketCollected IS NULL OR @pIsTicketCollected = tc.wIsCollected
                    OR ( @pIsTicketCollected = 'false' AND tc.wIsCollected IS NULL ) )
                AND ( @vBookingStatusCount <= 0 OR vs.wBookingStatus IS NOT NULL )
            ),
            tCount AS (
                SELECT wRecordCount = COUNT(*) FROM tResult
            )

            SELECT
                tResult.* ,
                wRecordCount
            FROM tResult , tCount
            ORDER BY CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wDebitDt END DESC ,
            CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wRefNo END DESC
            OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS  
            FETCH NEXT @pPageSize ROWS ONLY
            OPTION  ( RECOMPILE );
    END;