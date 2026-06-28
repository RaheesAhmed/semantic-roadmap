CREATE PROCEDURE [spq].[GetPromotionSMSAgentLst]
(
    @pManualAgentCodeIn VARCHAR(14) ,
    @pAgentCodeIn VARCHAR(14) ,
    @pAgentType VARCHAR(30) = '' ,              -- EMPTY/AGENT/GAMBLERS
    @pAccountType VARCHAR(5) = '',              -- EMPTY/1-7
    @pDateType	VARCHAR(30) = NULL,             -- 日期範圍類型： EMPTY/pDatePeriod/pDateCycle
    @pFmDatePeriod DATETIME2(7) = NULL,         -- 時間段範圍：開始
    @pToDatePeriod DATETIME2(7) = NULL,         -- 時間段範圍：結束
    @pDateCycle DATETIME2(7) = NULL,            -- 週期
    @pHasRolling CHAR(1) = NULL,                -- 有轉碼： EMPTY/Y/N
    @pRollingType VARCHAR(30) = NULL,           -- 轉碼類型： EMPTY/pAvgRollingAmt/pTotalRollingAmt
    @pAvgRollingAmt NUMERIC(18, 4) = NULL,      -- 平均轉碼
    @pTotalRollingAmt NUMERIC(18, 4) = NULL,    -- 總轉碼
    @pExcludeExtGrp CHAR(1) = NULL,             -- 不包外圍
    @pExcludeLineGrp VARCHAR(2000) = NULL       -- 不包線組
)
AS
    BEGIN
        SET NOCOUNT ON;
        SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
        
        -- dbml
        --SELECT wAgentCodeIn = CAST('' AS  VARCHAR(14)),
        --       wAgentCode_Display = CAST('' AS NVARCHAR(30)), 
        --       wCName = CAST(N'' AS NVARCHAR(30)),
        --       wSex = CAST('Y' AS CHAR(1)),
        --       wNickName = CAST(N'' AS NVARCHAR(40)),
        --       wRolling = CAST(0 AS NUMERIC(22,4)),
        --       wSMSTel = CAST('' AS VARCHAR(30));

        SET @pManualAgentCodeIn = NULLIF(@pManualAgentCodeIn, '');
        SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
        SET @pAgentType = NULLIF(@pAgentType, '');
        SET @pAccountType = NULLIF(@pAccountType, '');
        SET @pDateType = NULLIF(@pDateType, '');
        SET @pHasRolling = ISNULL(@pHasRolling, 'N');
        SET @pRollingType = NULLIF(@pRollingType, '');
        SET @pExcludeExtGrp = ISNULL(@pExcludeExtGrp, 'N');
        SET @pExcludeLineGrp = NULLIF(@pExcludeLineGrp, '');
        SET @pAvgRollingAmt = ISNULL(@pAvgRollingAmt, 0) * 10000;
        SET @pTotalRollingAmt = ISNULL(@pTotalRollingAmt, 0) * 10000;
        -- 時間段只取日期
        DECLARE @sFromDt DATE = CAST((CASE @pDateType WHEN 'pDatePeriod' THEN @pFmDatePeriod ELSE NULL END) AS DATE);
        DECLARE @sToDt DATE = CAST((CASE @pDateType WHEN 'pDatePeriod' THEN @pToDatePeriod ELSE NULL END) AS DATE);
        -- 週期只取年、月
        DECLARE @sYearMth VARCHAR(6) = CASE @pDateType WHEN 'pDateCycle' THEN FORMAT(@pDateCycle, 'yyyyMM') ELSE NULL END;

        DECLARE @tmpLineGrp TABLE( wLineGrp VARCHAR(30) );

        -- 不包線組（e.g. AA,AA1）
        IF @pExcludeLineGrp IS NOT NULL
        BEGIN
            INSERT INTO @tmpLineGrp (wLineGrp)
            SELECT DISTINCT item
            FROM dbo.fnSplit(@pExcludeLineGrp, ',')
            WHERE NULLIF(item, '') IS NOT NULL
        END;

        -- 在時間段或週期內，戶口：總轉碼、平均轉碼
        WITH tRollingSummary AS (
            SELECT
                abrd.wAgentCodeIn,
                wTotalRollingAmt = SUM(abrd.wRollingAPlayHKD + abrd.wRollingBPlayHKD + (CASE WHEN @pExcludeExtGrp = 'Y' THEN 0 ELSE abrd.wForeignTranHKD END)),
                wAvgRollingAmt = AVG(abrd.wRollingAPlayHKD + abrd.wRollingBPlayHKD + (CASE WHEN @pExcludeExtGrp = 'Y' THEN 0 ELSE abrd.wForeignTranHKD END))
            FROM RollsMary.dbo.mAgentBalRollingDay AS abrd
            INNER JOIN RollsMary.dbo.mAgent AS a ON abrd.wAgentCodeIn = a.wAgentCodeIn AND a.wAgentLevel >= 3
            WHERE @pHasRolling = 'Y' AND NULLIF(abrd.wAgentCodeIn, '') IS NOT NULL
                AND ((@pAgentCodeIn IS NULL AND @pManualAgentCodeIn IS NULL ) OR abrd.wAgentCodeIn = @pAgentCodeIn OR abrd.wAgentCodeIn = @pManualAgentCodeIn) -- 戶口
                AND (@pDateType IS NULL 
                    OR (@pDateType = 'pDatePeriod' AND ((@sFromDt IS NULL AND @sToDt IS NULL) OR (wDate BETWEEN @sFromDt AND @sToDt))) -- 時間段
                    OR (@pDateType = 'pDateCycle' AND (@sYearMth IS NULL OR abrd.wYearMth = @sYearMth))) -- 週期
            GROUP BY abrd.wAgentCodeIn
        )

        SELECT *
        INTO #tRollingSummary
        FROM tRollingSummary
        WHERE @pHasRolling = 'N'
            OR (@pRollingType IS NULL
                OR (@pRollingType = 'pAvgRollingAmt' AND wAvgRollingAmt > 0 AND wAvgRollingAmt >= @pAvgRollingAmt)
                OR (@pRollingType = 'pTotalRollingAmt' AND wTotalRollingAmt > 0 AND wTotalRollingAmt >= @pTotalRollingAmt));

        -- 戶口SMS
        SELECT
            sms.wAgentCodeIn,
            sms.wDialCode,
            sms.wTel
        INTO #tUsrSMSTel
        FROM RollsMary.dbo.eUsrSMSTel AS sms
        LEFT JOIN RollsMary.dbo.mAgent AS a ON a.wAgentCodeIn = sms.wAgentCodeIn AND a.wType != 'AUTH' AND a.wAgentLevel >= 3
        LEFT JOIN #tRollingSummary AS rs ON rs.wAgentCodeIn = sms.wAgentCodeIn
        WHERE NULLIF(sms.wAgentCodeIn, '') IS NOT NULL AND sms.wType = 'AGENT' AND sms.wSMSGrp = 'SMS_GRP_PROMO'
            AND ((@pAgentCodeIn IS NULL AND @pManualAgentCodeIn IS NULL ) OR a.wAgentCodeIn = @pAgentCodeIn OR a.wAgentCodeIn = @pManualAgentCodeIn)
            AND (@pAgentType IS NULL OR a.wAgentType = @pAgentType)
            AND (@pAccountType IS NULL OR a.wAccountType = @pAccountType)
            AND (@pHasRolling = 'N' OR rs.wAgentCodeIn IS NOT NULL)
            AND (@pExcludeLineGrp IS NULL OR NOT EXISTS (SELECT 1 FROM @tmpLineGrp WHERE wLineGrp = a.wShareGrp))
        OPTION(RECOMPILE);
        
        WITH tSMS AS (
            SELECT
                rsms.wAgentCodeIn ,
                wSMSTel = STUFF((SELECT CONCAT(',', wDialCode, '-', wTel)
                                FROM #tUsrSMSTel AS ssms
                                WHERE ssms.wAgentCodeIn = rsms.wAgentCodeIn
                                FOR XML PATH('')), 1, 1, '')
            FROM #tUsrSMSTel AS rsms
            GROUP BY rsms.wAgentCodeIn
        )

        SELECT
            a.wAgentCodeIn,
            a.wAgentCode_Display, 
            a.wCName,
            a.wSex,
            a.wNickName,
            wRolling = rs.wTotalRollingAmt,
            sms.wSMSTel
        FROM RollsMary.dbo.mAgent AS a
        LEFT JOIN tSMS AS sms ON sms.wAgentCodeIn = a.wAgentCodeIn
        LEFT JOIN #tRollingSummary AS rs ON rs.wAgentCodeIn = a.wAgentCodeIn
        WHERE a.wAgentLevel >= 3
            AND (@pHasRolling = 'N' OR (rs.wAgentCodeIn IS NOT NULL AND rs.wTotalRollingAmt > 0))
            AND ((@pAgentCodeIn IS NULL AND @pManualAgentCodeIn IS NULL ) OR a.wAgentCodeIn = @pAgentCodeIn OR a.wAgentCodeIn = @pManualAgentCodeIn)
        ORDER BY a.wAgentCode_Display
        OPTION(RECOMPILE);

        IF OBJECT_ID('tempdb..#tRollingSummary') IS NOT NULL
            DROP TABLE #tRollingSummary;

        IF OBJECT_ID('tempdb..#tUsrSMSTel') IS NOT NULL
            DROP TABLE #tUsrSMSTel;

        IF OBJECT_ID('tempdb..#tSMS') IS NOT NULL
            DROP TABLE #tSMS;
    END