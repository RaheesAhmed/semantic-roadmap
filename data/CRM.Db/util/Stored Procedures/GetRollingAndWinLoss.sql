CREATE PROC [util].[GetRollingAndWinLoss]
    @pXML       XML,
    @pResultXML XML OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        CREATE TABLE #vAgentCodeInList ( wAgentCodeIn VARCHAR(14), wYearMonth VARCHAR(6), PRIMARY KEY (wAgentCodeIn, wYearMonth) );

        CREATE TABLE #vCompany ( wAgentCodeIn VARCHAR(14), wComNo INT, wYearMonth VARCHAR(6), PRIMARY KEY (wAgentCodeIn, wComNo, wYearMonth) );

        -- 集團轉碼
        INSERT INTO #vAgentCodeInList ( wAgentCodeIn, wYearMonth )
        SELECT DISTINCT tmp.wAgentCodeIn, tmp.wYearMonth FROM (
            SELECT wAgentCodeIn = T.tmp.value('@wAgentCodeIn',  'VARCHAR(14)'),
                   wYearMonth   = T.tmp.value('@wYearMonth',    'VARCHAR(6)') 
            FROM @pXML.nodes('DataSet/Record') T(tmp)
        ) tmp WHERE NULLIF(tmp.wAgentCodeIn, '') IS NOT NULL AND NULLIF(tmp.wYearMonth, '') IS NOT NULL;

        -- 場館轉碼
        INSERT INTO #vCompany (wAgentCodeIn, wComNo, wYearMonth)
        SELECT DISTINCT tmp.wAgentCodeIn, tmp.wComNo, tmp.wYearMonth FROM (
            SELECT wAgentCodeIn = T.tmp.value('@wAgentCodeIn',  'VARCHAR(14)'),
                   wComNo       = T.tmp.value('@wCompNo',       'INT'),
                   wYearMonth   = T.tmp.value('@wYearMonth',    'VARCHAR(6)') 
            FROM @pXML.nodes('DataSet/Record') T(tmp)
        ) tmp WHERE NULLIF(tmp.wAgentCodeIn, '') IS NOT NULL AND NULLIF(tmp.wYearMonth, '') IS NOT NULL AND ISNULL(tmp.wComNo, 0) > 0;

        -- 獲取戶口列表的所有下線
        -- 2019-05-21：不包含下線轉碼
        --------------------------------------------------------------------------
        CREATE TABLE #vAgentLevelList (
            wAgentCodeIn    VARCHAR(14),
            wLvlAgentCodeIn VARCHAR(14),
            wYearMonth	    VARCHAR(6),
            PRIMARY KEY (wAgentCodeIn, wLvlAgentCodeIn, wYearMonth)
        );

        INSERT INTO #vAgentLevelList (
            wAgentCodeIn,
            wLvlAgentCodeIn,
            wYearMonth
        )
        SELECT  mal.wAgentCodeIn,
                mal.wLvlAgentCodeIn,
                acil.wYearMonth
        FROM RollsMary.dbo.mAgentLevel AS mal
        INNER JOIN #vAgentCodeInList acil ON acil.wAgentCodeIn = mal.wLvlAgentCodeIn AND mal.wAgentCodeIn = mal.wLvlAgentCodeIn
        WHERE mal.wEffectYearMth <= acil.wYearMonth AND (NULLIF(mal.wExpireYearMth, '') IS NULL OR mal.wExpireYearMth >= acil.wYearMonth);
        --------------------------------------------------------------------------

        -- 集團部轉碼數、殺數率
        -- 1. 不包含下線轉碼
        -- 2. 包含即出
        -- 3. 港幣結算
        --------------------------------------------------------------------------
        CREATE TABLE #vGroupRollingAndWinLoss (
            wAgentCodeIn    VARCHAR(14),
            wYearMonth      VARCHAR(6),
            wRollingHKD     NUMERIC(18, 4),
            wWinLossRatio   NUMERIC(18, 4),
            PRIMARY KEY (wAgentCodeIn, wYearMonth)
        );

        SELECT  v.wLvlAgentCodeIn,
                v.wYearMonth,
                -- 包含即出
                -- wRollingHKD = SUM(ISNULL(mabrm.wRollingAPlayHKD + mabrm.wRollingBPlayHKD - mabrm.wRollingInstantSettledAPlayHKD - mabrm.wRollingInstantSettledBPlayHKD, 0)) ,
                wRollingHKD = SUM(mabrm.wRollingAPlayHKD + mabrm.wRollingBPlayHKD) ,
                wWinLossHKD = SUM(mabrm.wWinLossAPlayHKD + mabrm.wWinLossBPlayHKD)
        INTO #sGroupAllRollingAndWinLoss
        FROM RollsMary.dbo.mAgentBalRollingMonth AS mabrm 
        INNER JOIN #vAgentLevelList v ON v.wAgentCodeIn = mabrm.wAgentCodeIn AND v.wYearMonth = mabrm.wYearMth
        LEFT JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = v.wLvlAgentCodeIn
        WHERE (ma.wAgentType = 'AGENT' OR (IIF(ma.wAgentType = 'GAMBLERS', ma.wAgentType, 'GAMBLERS') = 'GAMBLERS' AND v.wAgentCodeIn = v.wLvlAgentCodeIn))
        GROUP BY v.wLvlAgentCodeIn,v.wYearMonth;

        SELECT  araw.wLvlAgentCodeIn, 
                araw.wYearMonth, 
                wRollingHKD = ISNULL(SUM(araw.wRollingHKD),0),  --轉碼數
                wWinLossRatio=IIF(ISNULL(SUM(araw.wRollingHKD), 0) = 0, 0, ISNULL(SUM(araw.wWinLossHKD), 0)/SUM(araw.wRollingHKD)) --殺數率
        INTO #sGroupRollingAndWinLoss
        FROM #sGroupAllRollingAndWinLoss araw
        GROUP BY araw.wLvlAgentCodeIn, araw.wYearMonth;

        INSERT INTO #vGroupRollingAndWinLoss(wAgentCodeIn, wYearMonth, wRollingHKD, wWinLossRatio)
        SELECT  acil.wAgentCodeIn, 
                acil.wYearMonth, 
                wRollingHKD = ISNULL(craw.wRollingHKD, 0), 
                wWinLossRatio = ISNULL(craw.wWinLossRatio, 0)
        FROM #vAgentCodeInList acil
        LEFT JOIN #sGroupRollingAndWinLoss craw ON craw.wLvlAgentCodeIn = acil.wAgentCodeIn AND craw.wYearMonth = acil.wYearMonth;
        --------------------------------------------------------------------------

        -- 場館部轉碼數
        -- 1. 不包含下線轉碼
        -- 2. 包含即出
        -- 3. 港幣結算
        --------------------------------------------------------------------------
        CREATE TABLE #vCompanyRollingAndWinLoss (
            wAgentCodeIn    VARCHAR(14),
            wCompNo         INT,
            wYearMonth      VARCHAR(6),
            wRollingHKD     NUMERIC(18, 4),
            wWinLossRatio   NUMERIC(18, 4),
            PRIMARY KEY (wAgentCodeIn, wCompNo, wYearMonth)
        );

        SELECT  v.wLvlAgentCodeIn,
                c.wComNo,
                v.wYearMonth,
                -- 包含即出
                -- wRollingHKD = SUM(ISNULL(mabrm.wRollingAPlayHKD + mabrm.wRollingBPlayHKD - mabrm.wRollingInstantSettledAPlayHKD - mabrm.wRollingInstantSettledBPlayHKD, 0)) ,
                wRollingHKD = SUM(ISNULL(mabrm.wRollingAPlayHKD + mabrm.wRollingBPlayHKD, 0)) ,
                wWinLossHKD = SUM(ISNULL(mabrm.wWinLossAPlayHKD + mabrm.wWinLossBPlayHKD, 0))
        INTO #sCompanyAllRollingAndWinLoss
        FROM RollsMary.dbo.mAgentBalRollingMonth AS mabrm 
        INNER JOIN #vAgentLevelList v ON v.wAgentCodeIn = mabrm.wAgentCodeIn AND v.wYearMonth = mabrm.wYearMth
        INNER JOIN #vCompany c ON c.wAgentCodeIn = v.wLvlAgentCodeIn AND c.wComNo = mabrm.wCompNo
        LEFT JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = v.wLvlAgentCodeIn
        WHERE (ma.wAgentType = 'AGENT' OR (IIF(ma.wAgentType = 'GAMBLERS', ma.wAgentType, 'GAMBLERS') = 'GAMBLERS' AND v.wAgentCodeIn = v.wLvlAgentCodeIn))
        GROUP BY v.wLvlAgentCodeIn, c.wComNo, v.wYearMonth;

        SELECT  araw.wLvlAgentCodeIn, 
                araw.wComNo,
                araw.wYearMonth, 
                wRollingHKD = ISNULL(SUM(araw.wRollingHKD),0),  --轉碼數
                wWinLossRatio=IIF(ISNULL(SUM(araw.wRollingHKD), 0) = 0, 0, ISNULL(SUM(araw.wWinLossHKD), 0)/SUM(araw.wRollingHKD)) --殺數率
        INTO #sCompanyRollingAndWinLoss
        FROM #sCompanyAllRollingAndWinLoss araw
        GROUP BY araw.wLvlAgentCodeIn, araw.wComNo, araw.wYearMonth;

        INSERT INTO #vCompanyRollingAndWinLoss(wAgentCodeIn, wCompNo, wYearMonth, wRollingHKD, wWinLossRatio)
        SELECT  c.wAgentCodeIn, 
                c.wComNo,
                c.wYearMonth, 
                wRollingHKD = ISNULL(craw.wRollingHKD,0), 
                wWinLossRatio = ISNULL(craw.wWinLossRatio,0)
        FROM #vCompany c
        LEFT JOIN #sCompanyRollingAndWinLoss craw ON craw.wLvlAgentCodeIn = c.wAgentCodeIn AND craw.wComNo = c.wComNo AND craw.wYearMonth = c.wYearMonth;
        --------------------------------------------------------------------------

        -- Set Result XML
        --------------------------------------------------------------------------
        SET @pResultXML = (
            SELECT wAgentCodeIn,
                   (SELECT gr.wAgentCodeIn,
                           gr.wYearMonth,
                           gr.wRollingHKD,
                           gr.wWinLossRatio 
                    FROM #vGroupRollingAndWinLoss gr 
                    WHERE gr.wAgentCodeIn = a.wAgentCodeIn 
                    FOR XML RAW('Rolling'), TYPE, ROOT('Group')), -- 集團轉碼
                   (SELECT cr.wAgentCodeIn,
                           cr.wCompNo,
                           cr.wYearMonth,
                           cr.wRollingHKD,
                           cr.wWinLossRatio 
                    FROM #vCompanyRollingAndWinLoss cr 
                    WHERE cr.wAgentCodeIn = a.wAgentCodeIn 
                    FOR XML RAW('Rolling'), TYPE, ROOT('Company')) -- 場館轉碼
            FROM #vAgentCodeInList a
            GROUP BY a.wAgentCodeIn
            FOR XML RAW('Record'), ROOT('DataSet')
        );

        IF OBJECT_ID('tempdb..#vAgentCodeInList') IS NOT NULL
            DROP TABLE #vAgentCodeInList;

        IF OBJECT_ID('tempdb..#vYearMonth') IS NOT NULL
            DROP TABLE #vYearMonth;

        IF OBJECT_ID('tempdb..#vCompany') IS NOT NULL
            DROP TABLE #vCompany;

        IF OBJECT_ID('tempdb..#vAgentLevelLst') IS NOT NULL
            DROP TABLE #vAgentLevelLst;

        IF OBJECT_ID('tempdb..#sGroupAllRollingAndWinLoss') IS NOT NULL
            DROP TABLE #sGroupAllRollingAndWinLoss;

        IF OBJECT_ID('tempdb.#sGroupRollingAndWinLoss') IS NOT NULL
            DROP TABLE #sGroupRollingAndWinLoss;

        IF OBJECT_ID('tempdb..#vGroupRollingAndWinLoss') IS NOT NULL
            DROP TABLE #vGroupRollingAndWinLoss;

        IF OBJECT_ID('tempdb..#sCompanyAllRollingAndWinLoss') IS NOT NULL
            DROP TABLE #sCompanyAllRollingAndWinLoss;

        IF OBJECT_ID('tempdb..#sCompanyRollingAndWinLoss') IS NOT NULL
            DROP TABLE #sCompanyRollingAndWinLoss;

        IF OBJECT_ID('tempdb..#vCompanyRollingAndWinLoss') IS NOT NULL
            DROP TABLE #vCompanyRollingAndWinLoss;
    END