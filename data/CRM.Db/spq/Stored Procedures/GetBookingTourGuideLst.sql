CREATE PROCEDURE [spq].[GetBookingTourGuideLst]
    @pRefNo AS VARCHAR(30) ,
    @pFromDebitDt AS DATETIME2 ,
    @pToDebitDt AS DATETIME2 ,
    @pDebitCounterRidXML AS XML ,
    @pReqDeptCode AS VARCHAR(30) ,
    @pFollowUpDeptCode AS VARCHAR(30) ,
    @pDebitAgentCodeIn AS VARCHAR(14) ,
    @pReqAgentCodeIn AS VARCHAR(14) ,
    @pTravelAgencyRid AS BIGINT ,
    @pRegion AS VARCHAR(10) ,
    @pStartDt AS DATETIME2 ,
    @pEndtDt AS DATETIME2 ,
    @pOrderNo AS VARCHAR(20) ,
    @pPaymentMethod AS VARCHAR(30) ,
    @pBookingStatusXML AS XML ,
    @pSort AS VARCHAR(200) ,
    @pLangCd AS VARCHAR(10) ,
    @pPageSize AS INT ,
    @pPageNum AS INT
AS
    BEGIN  
        -- SET NOCOUNT ON added to prevent extra result sets from  
        -- interfering with SELECT statements.  
        SET NOCOUNT ON;  

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
        
        DECLARE @vFromStartDt   AS DATETIME2 = '0001-01-01' ,
                @vFromEndDt    AS DATETIME2 = '0001-01-01' ,
                @vToStartDt     AS DATETIME2 = '9999-12-31' ,
                @vToEndtDt      AS DATETIME2 = '9999-12-31' ,
                @vDebitCounterRidCount AS INT ,
                @vBookingStatusCount   AS INT;

        DECLARE @vData_DebitCounterRid AS TABLE ( SelectionItem BIGINT PRIMARY KEY);
        DECLARE @vData_BookingStatus AS TABLE ( SelectionItem VARCHAR(5) PRIMARY KEY );
        
        IF @pDebitCounterRidXML IS NOT NULL
        BEGIN
            INSERT INTO @vData_DebitCounterRid ( SelectionItem )
            SELECT DISTINCT T.tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
            FROM @pDebitCounterRidXML.nodes('/DataSet/Record') AS T ( tmp )
            WHERE T.tmp.value('@SelectionItem', 'BIGINT')  > 0;
        END;

        IF @pBookingStatusXML IS NOT NULL
        BEGIN
            INSERT INTO @vData_BookingStatus ( SelectionItem )
            SELECT DISTINCT T.tmp.value('@SelectionItem', 'VARCHAR(5)') AS SelectionItem
            FROM @pBookingStatusXML.nodes('/DataSet/Record') AS T ( tmp )
            WHERE NULLIF(T.tmp.value('@SelectionItem', 'VARCHAR(5)'), '') IS NOT NULL;
        END;

        SET @vDebitCounterRidCount  = ( SELECT COUNT(1) FROM @vData_DebitCounterRid );
        SET @vBookingStatusCount    = ( SELECT COUNT(1) FROM @vData_BookingStatus );
        SET @pRefNo             = NULLIF(@pRefNo, '');
        SET @pFromDebitDt       = ISNULL(@pFromDebitDt, '0001-01-01');
        SET @pToDebitDt         = ISNULL(@pToDebitDt, '9999-12-31');  
        SET @pReqDeptCode       = NULLIF(@pReqDeptCode, '');
        SET @pFollowUpDeptCode  = NULLIF(@pFollowUpDeptCode, '');
        SET @pDebitAgentCodeIn  = NULLIF(@pDebitAgentCodeIn, '');
        SET @pReqAgentCodeIn    = NULLIF(@pReqAgentCodeIn, '');
        SET @pTravelAgencyRid   = ISNULL(IIF(@pTravelAgencyRid < 0, NULL, @pTravelAgencyRid), 0);
        SET @pRegion            = NULLIF(@pRegion, '');
        SET @pOrderNo           = NULLIF(@pOrderNo, '');
        SET @pPaymentMethod     = NULLIF(@pPaymentMethod, '');
        SET @pSort              = ISNULL(NULLIF(@pSort, ''), '||');
        SET @pLangCd            = LOWER(ISNULL(NULLIF(@pLangCd, ''), 'zh-tw'));
        SET @pPageSize          = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 9999);
        SET @pPageNum           = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);

        IF @pStartDt IS NOT NULL
        BEGIN
            SET @vFromStartDt = CAST(@pStartDt AS DATE);
            SET @vToStartDt = CAST(DATEADD(dd, 1, @pStartDt) AS DATE);
        END;

        IF @pEndtDt IS NOT NULL
        BEGIN
            SET @vFromEndDt = CAST(@pEndtDt AS DATE);
            SET @vToEndtDt = CAST(DATEADD(dd, 1, @pEndtDt) AS DATE);
        END;

        WITH tResult AS (
            SELECT 
                wSeqNo = ROW_NUMBER() OVER ( ORDER BY btg.RowID ) ,
                btg.RowID ,
                btg.wBookingRid ,
                eb.wRefNo ,
                btg.wTravelAgencyRid ,
                wAgencyName = mta.wName ,
                btg.wOrderNo ,
                eb.wDebitDt ,
                btg.wTotalAmt ,
                btg.wCurrCode ,
                btg.wStatus ,
                btg.wLang ,
                btg.wBookingStatus ,
                btg.wUpdBy ,
                btg.wUpdDt ,
                requestedServiceCounterid = eb.wReqCounterRid ,
                wAgentCodeIn = eb.wDebitAgentCodeIn ,
                requestedServiceCounter = scr.wName ,
                daAgent.wAgentCode_Display ,
                wDebitClientName = '' ,
                wDebitServiceCounterName = sc.wName ,
                wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END,
                eb.wReqDepartment ,
                wRequestedServiceCounter = msc.wName ,
                wReqUserRidByCName = CASE WHEN @pLangCd = 'en-gb' THEN rqusr.wName ELSE rqusr.wCName END ,
                wStaffFollwedRidByCName = CASE WHEN @pLangCd = 'en-gb' THEN sfusr.wName ELSE sfusr.wCName END ,
                wReqAgentCode_Display = rqAgent.wAgentCode_Display ,
                eb.wAsstBooker ,
                btg.wPaymentMethod ,
                wTravelAgencyRidByName = ta.wName ,
                btg.wRegion ,
                btg.wStartDt ,
                btg.wEndtDt ,
                eb.wDepositAmt ,
                wClient = bm.wValue,
                wAgentCodeByName = CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName ELSE daAgent.wCName END,
                wReqAgentCodeByName = CASE WHEN @pLangCd = 'en-gb' THEN rqAgent.wEName ELSE rqAgent.wCName END,
                eb.wDeptFollwedCd
            FROM dbo.eBookingTourGuide btg
            INNER JOIN dbo.eBooking eb ON eb.RowID = btg.wBookingRid
            INNER JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
            LEFT JOIN [RollsMary].[dbo].[mAgent] rqAgent ON rqAgent.wAgentCodeIn = eb.wReqAgentCodeIn
            INNER JOIN dbo.mServiceCounter sc ON sc.RowID = eb.wDebitCounterRid
            LEFT JOIN dbo.mServiceCounter scr ON scr.RowID = eb.wReqCounterRid
            LEFT JOIN dbo.mTravelAgency mta ON mta.RowID = btg.wTravelAgencyRid
            LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = btg.wUpdBy
            LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = btg.wCrtBy
            LEFT JOIN [RollsMary].[dbo].[mUsr] rqusr ON rqusr.RowID = eb.wReqUserRid
            LEFT JOIN [RollsMary].[dbo].[mUsr] sfusr ON sfusr.RowID = eb.wStaffFollwedRid
            LEFT JOIN dbo.mServiceCounter msc ON msc.RowID = eb.wReqCounterRid
            LEFT JOIN dbo.mTravelAgency ta ON ta.RowID = btg.wTravelAgencyRid
            LEFT JOIN stg.eBookingMisc bm ON bm.wBookingRid = btg.wBookingRid AND bm.wLangCd = @pLangCd AND bm.wItemCd = 'CUST_NAME'
            LEFT JOIN @vData_DebitCounterRid v ON v.SelectionItem = eb.wDebitCounterRid
            LEFT JOIN @vData_BookingStatus vs ON vs.SelectionItem = btg.wBookingStatus
            WHERE ( @pRefNo IS NULL OR @pRefNo = eb.wRefNo )
                AND ( @vDebitCounterRidCount = 0 OR v.SelectionItem IS NOT NULL )
                AND ( @pReqDeptCode IS NULL OR @pReqDeptCode = eb.wReqDepartment )
                AND ( @pFollowUpDeptCode IS NULL OR @pFollowUpDeptCode = eb.wDeptFollwedCd )
                AND ( @pDebitAgentCodeIn IS NULL OR @pDebitAgentCodeIn = eb.wDebitAgentCodeIn )
                AND ( @pReqAgentCodeIn IS NULL OR @pReqAgentCodeIn = eb.wReqAgentCodeIn )
                AND ( @pRegion IS NULL OR @pRegion = btg.wRegion )
                AND ( @pOrderNo IS NULL OR @pOrderNo = btg.wOrderNo ) 
                AND ( @pPaymentMethod IS NULL OR @pPaymentMethod = btg.wPaymentMethod )
                AND ( @pTravelAgencyRid = 0 OR @pTravelAgencyRid = btg.wTravelAgencyRid )
                AND ( @vBookingStatusCount = 0 OR vs.SelectionItem IS NOT NULL )
                AND ( @pFromDebitDt <= eb.wDebitDt AND @pToDebitDt >= eb.wDebitDt )
                AND ( @vFromStartDt <= btg.wStartDt AND @vToStartDt >= btg.wStartDt )
                AND ( @vFromEndDt <= btg.wEndtDt AND @vToEndtDt >= btg.wEndtDt )
        ),
        tCount AS (
            SELECT wRecordCount = COUNT(*) FROM tResult
        )

        SELECT  tResult.* ,
                wRecordCount
        FROM tResult, tCount
        ORDER BY CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wDebitDt END DESC ,
                 CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wRefNo END DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS  
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION(RECOMPILE);  
    END;