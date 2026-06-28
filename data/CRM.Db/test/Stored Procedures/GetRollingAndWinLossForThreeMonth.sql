
CREATE PROCEDURE [test].[GetRollingAndWinLossForThreeMonth]
(
    @pAgentCodeIn VARCHAR(14)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sNow DATETIME2 = RollsMary.dbo.fnUTC8Now(), --當前時間
            @sPastThreeYearMonth VARCHAR(6) --當前時間往前數第3個月

    DECLARE @sAgentCodeInList TABLE(
        wAgentCodeIn VARCHAR(14)
    )
    INSERT INTO @sAgentCodeInList VALUES(@pAgentCodeIn);

    CREATE TABLE #sTmpLevelList (
        wAgentCodeIn    VARCHAR(14),
        wLvlAgentCodeIn VARCHAR(14),
        wShareLevel	    INT,
        wYearMonth	    VARCHAR(6)
    );
    CREATE CLUSTERED INDEX idx_TmpLevelList
    ON #sTmpLevelList(
        wAgentCodeIn,
        wYearMonth
    );

    CREATE TABLE #sYearMonth (
        wYearMonth VARCHAR(6)
    );
    CREATE CLUSTERED INDEX idx_YearMonth
    ON #sYearMonth (wYearMonth);

    SELECT @sPastThreeYearMonth = CONCAT(LEFT(CAST(DATEADD(MONTH, -2,@sNow) AS VARCHAR(10)), 4), SUBSTRING(CAST(DATEADD(MONTH, -2,@sNow) AS VARCHAR(10)), 6, 2));

    --獲取最近3個月
    INSERT INTO #sYearMonth
    SELECT msp.wYear + msp.wMonth
    FROM RollsMary.dbo.mSettlePeriod AS msp
    WHERE msp.wCompNo = 95
        AND (msp.wYear + msp.wMonth) >= @sPastThreeYearMonth
        AND msp.wStartDate <= @sNow

    --獲取戶口列表的所有下線
    INSERT INTO #sTmpLevelList
    SELECT
        mal.wAgentCodeIn,
        mal.wLvlAgentCodeIn,
        mal.wShareLevel,
        sym.wYearMonth
    FROM RollsMary.dbo.mAgentLevel AS mal
    INNER JOIN @sAgentCodeInList acil ON acil.wAgentCodeIn = mal.wLvlAgentCodeIn
    INNER JOIN #sYearMonth AS sym ON mal.wEffectYearMth <= sym.wYearMonth AND (NULLIF(mal.wExpireYearMth, '') IS NULL OR mal.wExpireYearMth >= sym.wYearMonth)

    --轉碼數 和 殺數率
    --戶口的是代理包下線，是玩家不包下線
    --;WITH cteOperateData AS(
        -- SELECT
            --  v.wLvlAgentCodeIn,
            --  v.wYearMonth,
            --  SUM((rd.wCustFxRate / rd.wCustFxRateDiv) * rd.wRolling * (rd.wMutiplyPercentage / 100)) AS wRollingHKD,
            --  SUM((rd.wCustFxRate / rd.wCustFxRateDiv) * rd.wWinLoss * (rd.wMutiplyPercentage / 100)) AS wWinLossHKD
        -- FROM RollsMary.opt.eOPTranDtlSection rd 
        -- INNER JOIN RollsMary.dbo.mSettlePeriod msp ON msp.wPeriodCodeIn = rd.wPeriodCodeIn
        -- INNER JOIN #sTmpLevelList v ON v.wAgentCodeIn = rd.wAgentCodeIn AND (msp.wYear + msp.wMonth) = v.wYearMonth
        -- LEFT JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = v.wLvlAgentCodeIn
        -- WHERE rd.wStatusPlace = '2'
        --  AND rd.wStatusOperate = '11'
        --  AND (ma.wAgentType = 'AGENT' OR (IIF(ma.wAgentType = 'GAMBLERS', ma.wAgentType, 'GAMBLERS') = 'GAMBLERS' AND v.wAgentCodeIn = v.wLvlAgentCodeIn))
        --  GROUP BY v.wLvlAgentCodeIn,v.wYearMonth
    --),
    ;WITH cteAllRollingAndWinLoss AS(
        SELECT
            v.wLvlAgentCodeIn,
            v.wYearMonth,
            wRollingHKD = SUM(ISNULL(mabrm.wRollingAPlayHKD + mabrm.wRollingBPlayHKD - mabrm.wRollingInstantSettledAPlayHKD - mabrm.wRollingInstantSettledBPlayHKD, 0)) ,
            wWinLossHKD = SUM(ISNULL(mabrm.wWinLossAPlayHKD + mabrm.wWinLossBPlayHKD, 0))
        FROM RollsMary.dbo.mAgentBalRollingMonth AS mabrm 
        INNER JOIN #sTmpLevelList v ON v.wAgentCodeIn = mabrm.wAgentCodeIn AND v.wYearMonth = mabrm.wYearMth
        LEFT JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = v.wLvlAgentCodeIn
        WHERE (ma.wAgentType = 'AGENT' OR (IIF(ma.wAgentType = 'GAMBLERS', ma.wAgentType, 'GAMBLERS') = 'GAMBLERS' AND v.wAgentCodeIn = v.wLvlAgentCodeIn))
        GROUP BY v.wLvlAgentCodeIn,v.wYearMonth
        --UNION
        --SELECT
            -- od.wLvlAgentCodeIn,
            -- od.wYearMonth,
            -- od.wRollingHKD,
            -- od.wWinLossHKD
        --FROM cteOperateData od
    ),cteRollingAndWinLoss AS(
        SELECT 
            araw.wLvlAgentCodeIn, 
            araw.wYearMonth, 
            wRollingHKD = ISNULL(SUM(araw.wRollingHKD),0),  --轉碼數
            wWinLossRatio=IIF(ISNULL(SUM(araw.wRollingHKD), 0) = 0, 0, ISNULL(SUM(araw.wWinLossHKD), 0)/SUM(araw.wRollingHKD)) --殺數率
        FROM cteAllRollingAndWinLoss araw
        GROUP BY araw.wLvlAgentCodeIn, araw.wYearMonth
    ),ctePastThreeData AS(
        SELECT 
            acil.wAgentCodeIn, 
            ym.wYearMonth, 
            ISNULL(craw.wRollingHKD,0) AS wRollingHKD, 
            ISNULL(craw.wWinLossRatio,0) AS wWinLossRatio
        FROM @sAgentCodeInList acil
        INNER JOIN #sYearMonth ym ON 1 = 1
        LEFT JOIN cteRollingAndWinLoss craw ON craw.wYearMonth = ym.wYearMonth AND craw.wLvlAgentCodeIn = acil.wAgentCodeIn
    )

    SELECT * FROM ctePastThreeData

    IF OBJECT_ID('tempdb..#sTmpLevelList') IS NOT NULL
        DROP TABLE #sTmpLevelList;
    IF OBJECT_ID('tempdb..#sYearMonth') IS NOT NULL
        DROP TABLE #sYearMonth;
END