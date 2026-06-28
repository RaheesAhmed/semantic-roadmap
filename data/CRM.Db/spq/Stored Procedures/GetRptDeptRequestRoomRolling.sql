CREATE PROC [spq].[GetRptDeptRequestRoomRolling]
    @pXML       XML,
    @pLangCd    VARCHAR(10),
    @pErrCode   INT OUTPUT,
    @pErrMsg    NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        -- dbml
        -----------------------------------------------------------
        --DECLARE @vResult TABLE (
        --    wAgentCodeIn        VARCHAR(14) NOT NULL,
        --    wAgentCode_Display  NVARCHAR(30) NOT NULL,
        --    wAgentCodeName      NVARCHAR(50) NOT NULL,
        --    wHotelName          NVARCHAR(100) NOT NULL,
        --    wCompanyName        NVARCHAR(30) NOT NULL,
        --    wCurrCode           VARCHAR(30),
        --    wRollingAmt         NUMERIC(18, 4),
        --    wWinLossAmt         NUMERIC(18, 4),
        --    wDate               DATE NOT NULL,
        --    wBookedRoomQty      INT NOT NULL
        --);

        --SELECT * FROM @vResult;
        -----------------------------------------------------------

        DECLARE @vHotel TABLE (RowID BIGINT PRIMARY KEY);
        DECLARE @vCompany TABLE (wCompNo INT PRIMARY KEY);

        DECLARE @vXML XML;

        DECLARE @pAgentCodeIn   VARCHAR(14),
                @pStartDate     DATE,
                @pEndDate       DATE,
                @pHotelRid      VARCHAR(MAX),
                @pCompNo        VARCHAR(MAX);

        SELECT @pAgentCodeIn    = T.tmp.value('@wAgentCodeIn',      'VARCHAR(14)'),
               @pStartDate      = NULLIF(T.tmp.value('@wStartDate', 'VARCHAR(10)'), ''),
               @pEndDate        = NULLIF(T.tmp.value('@wEndDate',   'VARCHAR(10)'), ''),
               @pHotelRid       = T.tmp.value('@wHotelRid',         'VARCHAR(MAX)'),
               @pCompNo         = T.tmp.value('@wCompNo',           'VARCHAR(MAX)')
        FROM @pXML.nodes('Filter') T(tmp);
        
        SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
        SET @pHotelRid = NULLIF(@pHotelRid, '');
        SET @pCompNo = NULLIF(@pCompNo, '');

        IF @pHotelRid IS NOT NULL
        BEGIN
            SET @vXML = CONVERT(XML,'<DataSet><Record>' + REPLACE(@pHotelRid, ',', '</Record><Record>') + '</Record></DataSet>');

            INSERT INTO @vHotel(RowID)
            SELECT DISTINCT CONVERT(BIGINT, tmp.RowID) FROM (
                SELECT RowID = T.tmp.value('.', 'VARCHAR(64)')
                FROM @vXML.nodes('DataSet/Record') T(tmp)
            ) tmp WHERE NULLIF(tmp.RowID, '') IS NOT NULL;
        END;

        IF @pCompNo IS NOT NULL
        BEGIN
            SET @vXML = CONVERT(XML,'<DataSet><Record>' + REPLACE(@pCompNo, ',', '</Record><Record>') + '</Record></DataSet>');

            INSERT INTO @vCompany ( wCompNo )
            SELECT DISTINCT CONVERT(INT, tmp.wCompNo) FROM (
                SELECT wCompNo = T.tmp.value('.', 'VARCHAR(64)')
                FROM @vXML.nodes('DataSet/Record') T(tmp)
            ) tmp WHERE NULLIF(tmp.wCompNo, '') IS NOT NULL;
        END
        
        SET @pErrMsg = '';
        SET @pErrCode = 0;

        IF @pErrMsg = '' AND @pStartDate IS NULL
            SET @pErrMsg = N'開始日期不能為空';

        IF @pErrMsg = '' AND @pEndDate IS NULL
            SET @pErrMsg = N'結束日期不能為空';
            
        IF @pErrMsg = '' AND DATEDIFF(DAY, @pStartDate, @pEndDate) > 31
            SET @pErrMsg = N'日期範圍不能超過一個月';

        IF @pErrMsg <> ''
            SET @pErrCode = 50001;
        
        IF @pErrMsg = ''
        BEGIN
            -- 把時間段轉成每一日（計算每一日轉碼數）
            -----------------------------------------------------------
            CREATE TABLE #vDate(wDate DATE PRIMARY KEY);
            INSERT INTO #vDate ( wDate )
            SELECT wDate = DATEADD(DAY, number, @pStartDate)
            FROM master.dbo.spt_values
            WHERE [type] = 'P' 
                AND DATEADD(DAY, number, @pStartDate) <= @pEndDate ;

            -- 隨便篩選條件的入住記錄
            -----------------------------------------------------------
            CREATE TABLE #vResult ( 
                wAgentCodeIn VARCHAR(14), 
                wCompNo INT,
                wDate DATE, 
                wHotelRid BIGINT, 
                wBookedRoomQty INT 
                PRIMARY KEY (wAgentCodeIn, wCompNo, wDate, wHotelRid)
            );

            INSERT INTO #vResult (
                wAgentCodeIn, 
                wCompNo, 
                wDate, 
                wHotelRid,
                wBookedRoomQty
            )
            SELECT  req.wAgentCodeIn,
                    ISNULL(sc.wRollexCompNo, 0),
                    d.wDate,
                    resp.wHotelRid,
                    wBookedRoomQty = SUM(resp.wBigBedQty + resp.wTwinBedQty + resp.wSuiteRoom1Qty + resp.wSuiteRoom2Qty + resp.wSuiteRoom3Qty)
            FROM dbo.eDeptReqRoom req
            INNER JOIN dbo.eDeptRespRoom resp ON resp.wDeptReqRoomRid = req.RowID
            INNER JOIN dbo.mHotel mh ON mh.RowID = resp.wHotelRid
            LEFT JOIN dbo.mServiceCounter sc ON sc.RowID = mh.wDebitServiceCounter
            LEFT JOIN @vHotel vh ON vh.RowID = resp.wHotelRid
            LEFT JOIN @vCompany vc ON vc.wCompNo = sc.wRollexCompNo
            CROSS JOIN #vDate d
            WHERE req.wStatus = 'A'
                AND resp.wStatus = 'A'
                AND resp.wRepStatus = 'C'
                AND resp.wDeptStatus NOT IN ('CS_ST', 'CS_MM')
                AND (@pAgentCodeIn IS NULL OR @pAgentCodeIn = req.wAgentCodeIn)
                AND (@pHotelRid IS NULL OR vh.RowID IS NOT NULL)
                AND (@pCompNo IS NULL OR vc.wCompNo IS NOT NULL)
                AND (resp.wStartDate <= d.wDate AND d.wDate < resp.wEndDate)
            GROUP BY req.wAgentCodeIn, sc.wRollexCompNo, d.wDate, resp.wHotelRid
            OPTION(RECOMPILE);
            -----------------------------------------------------------

            -- 入住期間每一日轉碼數
            -----------------------------------------------------------
            CREATE TABLE #vRollingDay (
                wAgentCodeIn VARCHAR(14), 
                wCompNo INT, 
                wDate DATE
                PRIMARY KEY(wAgentCodeIn, wCompNo, wDate)
            );

            INSERT INTO #vRollingDay (
                wAgentCodeIn,
                wCompNo,
                wDate
            )
            SELECT  wAgentCodeIn, 
                    wCompNo, 
                    wDate 
            FROM #vResult 
            WHERE wCompNo > 0
            GROUP BY wAgentCodeIn, wCompNo, wDate;

            SELECT rd.wAgentCodeIn, 
                   rd.wCompNo, 
                   rd.wDate,
                   wCurrCode = 'HKD',
                   wRollingHKD = SUM(abrd.wRollingAPlayHKD + abrd.wRollingBPlayHKD),
                   wWinLossHKD = SUM(abrd.wWinLossAPlayHKD + abrd.wWinLossBPlayHKD)
            INTO #vRollingResult
            FROM #vRollingDay rd
            INNER JOIN RollsMary.dbo.mAgentBalRollingDay abrd ON abrd.wAgentCodeIn = rd.wAgentCodeIn AND abrd.wCompNo = rd.wCompNo AND abrd.wDate = rd.wDate
            GROUP BY rd.wAgentCodeIn, rd.wCompNo, rd.wDate;
            -----------------------------------------------------------

            SELECT  ma.wAgentCodeIn,
                    ma.wAgentCode_Display,
                    wAgentCodeName = ma.wCName,
                    wHotelName = mh.wName,
                    wCompanyName = ISNULL(mc.wCName, ''),
                    wCurrCode   = IIF(mc.wCName IS NULL, NULL, ISNULL(rr.wCurrCode, 'HKD')),
                    wRollingAmt = IIF(mc.wCName IS NULL, NULL, ISNULL(rr.wRollingHKD, 0)),
                    wWinLossAmt = IIF(mc.wCName IS NULL, NULL, ISNULL(rr.wWinLossHKD, 0)),
                    r.wDate,
                    r.wBookedRoomQty
            FROM #vResult r
            INNER JOIN dbo.mHotel mh ON mh.RowID = r.wHotelRid
            INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = r.wAgentCodeIn
            LEFT JOIN dbo.mServiceCounter sc ON sc.RowID = mh.wDebitServiceCounter
            LEFT JOIN RollsMary.dbo.mCompany mc ON mc.wCompNo = sc.wRollexCompNo
            LEFT JOIN #vRollingResult rr ON rr.wAgentCodeIn = r.wAgentCodeIn AND rr.wCompNo = r.wCompNo AND rr.wDate = r.wDate
            ORDER BY r.wDate desc;
        END

        IF OBJECT_ID('tempdb..#vDate') IS NOT NULL
            DROP TABLE #vDate;

        IF OBJECT_ID('tempdb..#vRollingDay') IS NOT NULL
            DROP TABLE #vRollingDay;

        IF OBJECT_ID('tempdb..#vRollingResult') IS NOT NULL
            DROP TABLE #vRollingResult;

        IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
            DROP TABLE #vResult;
    END