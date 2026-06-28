
CREATE PROCEDURE [spq].[GetRollingAvgForBirthday]
    @pXMLAgentCodeIn XML,
    @pDate DATE
AS
BEGIN
    SET NOCOUNT ON;
   
    DECLARE @sNow DATETIME2 = ISNULL(@pDate, RollsMary.dbo.fnUTC8Now()), --當前時間
            @sPastThreeYearMonth VARCHAR(6) --當前時間往前數第3個月

    DECLARE @vAgentCodeIn TABLE(
        wAgentCodeIn VARCHAR(14) PRIMARY KEY
    );

    CREATE TABLE #vAgentLevel (
        wAgentCodeIn    VARCHAR(14),
        wLvlAgentCodeIn VARCHAR(14),
        wYearMonth	    VARCHAR(6),
        PRIMARY KEY (wAgentCodeIn, wLvlAgentCodeIn, wYearMonth)
    );

    CREATE TABLE #vYearMonth (
        wYearMonth VARCHAR(6) PRIMARY KEY
    );

    -- 把時間轉換成1號
    -- @sNow生日月份不計算，提前一個月準備，所以此處要減掉2
    SET @sNow = DATEADD(MONTH, -2, DATEFROMPARTS(YEAR(@sNow), MONTH(@sNow), 1));
    SET @sPastThreeYearMonth = CONCAT(LEFT(CAST(DATEADD(MONTH, -2,@sNow) AS VARCHAR(10)), 4), SUBSTRING(CAST(DATEADD(MONTH, -2,@sNow) AS VARCHAR(10)), 6, 2));

    IF @pXMLAgentCodeIn IS NOT NULL
    BEGIN
        INSERT INTO @vAgentCodeIn
        SELECT DISTINCT
            wAgentCodeIn = T.tmp.value('@wAgentCodeIn', 'VARCHAR(14)')
        FROM @pXMLAgentCodeIn.nodes('DataSet/Record') T(tmp)
    END;

    --獲取最近3個月
    INSERT INTO #vYearMonth
    SELECT DISTINCT msp.wYear + msp.wMonth
    FROM RollsMary.dbo.mSettlePeriod AS msp
    WHERE msp.wCompNo = 95
        AND (msp.wYear + msp.wMonth) >= @sPastThreeYearMonth
        AND msp.wStartDate <= @sNow
    OPTION(RECOMPILE);
        
    --獲取戶口列表的所有下線
    INSERT INTO #vAgentLevel
    SELECT DISTINCT
        mal.wAgentCodeIn,
        mal.wLvlAgentCodeIn,
        sym.wYearMonth
    FROM RollsMary.dbo.mAgentLevel AS mal
    INNER JOIN @vAgentCodeIn acil ON acil.wAgentCodeIn = mal.wLvlAgentCodeIn
    INNER JOIN #vYearMonth AS sym ON mal.wEffectYearMth <= sym.wYearMonth AND (NULLIF(mal.wExpireYearMth, '') IS NULL OR mal.wExpireYearMth >= sym.wYearMonth)
    OPTION(RECOMPILE);
    
    --轉碼數 
    SELECT
            v.wLvlAgentCodeIn,
            v.wYearMonth,
            wRollingHKD = SUM(ISNULL(mabrm.wRollingAPlayHKD_WithoutInstant, 0))
    INTO #vAllRollingAndWinLoss
    FROM RollsMary.dbo.mAgentBalRollingMonth AS mabrm 
    INNER JOIN #vAgentLevel v ON v.wAgentCodeIn = mabrm.wAgentCodeIn AND v.wYearMonth = mabrm.wYearMth
    INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = v.wLvlAgentCodeIn
    WHERE (ma.wAgentType = 'AGENT' OR v.wAgentCodeIn = v.wLvlAgentCodeIn)
    GROUP BY v.wLvlAgentCodeIn,v.wYearMonth
    OPTION(RECOMPILE);

    SELECT 
        acil.wAgentCodeIn, 
        ym.wYearMonth, 
        wRollingHKD = ISNULL(craw.wRollingHKD, 0)
    INTO #vPastThreeData
    FROM @vAgentCodeIn acil
    LEFT JOIN #vYearMonth ym ON 1 = 1
    LEFT JOIN #vAllRollingAndWinLoss craw ON craw.wYearMonth = ym.wYearMonth AND craw.wLvlAgentCodeIn = acil.wAgentCodeIn
    OPTION(RECOMPILE);

    SELECT 
        wAgentCodeIn, 
        wRollingAvgAmt = SUM(ISNULL(wRollingHKD, 0)) / 3 / 10000 -- 萬
    FROM #vPastThreeData
    GROUP BY wAgentCodeIn
    HAVING SUM(ISNULL(wRollingHKD, 0)) > 0
    OPTION(RECOMPILE);

    IF OBJECT_ID('tempdb..#vAllRollingAndWinLoss') IS NOT NULL
        DROP TABLE #vAllRollingAndWinLoss;

    IF OBJECT_ID('tempdb..#vPastThreeData') IS NOT NULL
        DROP TABLE #vPastThreeData;

    IF OBJECT_ID('tempdb..#vAgentLevel') IS NOT NULL
        DROP TABLE #vAgentLevel;

    IF OBJECT_ID('tempdb..#vYearMonth') IS NOT NULL
        DROP TABLE #vYearMonth;
END