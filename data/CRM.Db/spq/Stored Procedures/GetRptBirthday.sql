
CREATE PROC [spq].[GetRptBirthday]
    @pXMLFilter XML,
    @pXMLBirthday XML,
    @pLangCd VARCHAR(10) = 'zh-TW'
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

        DECLARE @pCalendarType  CHAR(5),        -- 日曆類型
                @pBirthday      DATE,           -- 生日月份
                @pDeptFollow    VARCHAR(30);    -- 跟進部門
                
        DECLARE @sMDFollow      CHAR(1), -- Get MD星級客戶權限
                @sVIPFollow     CHAR(1), -- Get VIP客戶權限（MD星級客戶以外的身份都是VIP客戶）
                @sNow           DATETIME2(7) = GETDATE();

        -- 跟進部門
        DECLARE @vFollowDept TABLE(wDeptCd VARCHAR(30) PRIMARY KEY);

        -- 過濾條件
        IF @pXMLFilter IS NOT NULL
        BEGIN
            SET @pCalendarType  = @pXMLFilter.value('(Filter/@pCalendarType)[1]',   'CHAR(5)');
            SET @pBirthday      = @pXMLFilter.value('(Filter/@pBirthday)[1]',       'DATE');
            SET @pDeptFollow    = @pXMLFilter.value('(Filter/@pDeptFollow)[1]',     'VARCHAR(30)');

            SET @pCalendarType  = NULLIF(@pCalendarType, '');
            SET @pDeptFollow    = NULLIF(@pDeptFollow,   '');

            -- 跟進部門
            IF @pDeptFollow IS NOT NULL
            BEGIN
                DECLARE @sXMLDept XML;
                SET @pDeptFollow = REPLACE(REPLACE(@pDeptFollow, 'VIP', 'HOUSEKEEPER'), 'MD', 'DEVELOP');
                SET @sXMLDept = CONVERT(XML,'<DataSet><Record>' + REPLACE(@pDeptFollow, ',', '</Record><Record>') + '</Record></DataSet>');

                INSERT INTO @vFollowDept(wDeptCd)
                SELECT DISTINCT LTRIM(RTRIM(T.tmp.value('.', 'VARCHAR(30)')))
                FROM @sXMLDept.nodes('DataSet/Record') T(tmp)
                WHERE NULLIF(T.tmp.value('.', 'VARCHAR(30)'), '') IS NOT NULL;
            END;
        END;

        SET @sMDFollow  = ISNULL((SELECT 'Y' FROM @vFollowDept WHERE wDeptCd = 'DEVELOP'),  'N');
        SET @sVIPFollow = ISNULL((SELECT 'Y' FROM @vFollowDept WHERE wDeptCd = 'HOUSEKEEPER'), 'N');

        ------------------------------------生日日期------------------------------------------
        DECLARE @vBirthday TABLE(
            wCalendarType   CHAR(5),
            wYear           INT,
            wMonth          INT,
            wDay            INT,
            wIsLeapMonth    CHAR(1),
            PRIMARY KEY(wCalendarType, wYear, wMonth, wDay, wIsLeapMonth)
        );

        IF @pXMLBirthday IS NOT NULL
        BEGIN
            INSERT INTO @vBirthday
            SELECT DISTINCT
                wCalendarType   = T.tmp.value('@pCalendarType',     'CHAR(5)'),
                wYear           = T.tmp.value('@pYear',             'INT'),
                wMonth          = T.tmp.value('@pMonth',            'INT'),
                wDay            = T.tmp.value('@pDay',              'INT'),
                wIsLeapMonth    = T.tmp.value('@pIsLeapMonth',      'CHAR(1)')    
            FROM @pXMLBirthday.nodes('DataSet/Record') T(tmp)
        END;

        -- 删除無效生日
        DELETE FROM @vBirthday WHERE wCalendarType NOT IN ('Solar', 'Lunar') OR wIsLeapMonth NOT IN ('Y', 'N');
        -- 篩選新舊曆
        IF @pCalendarType IS NOT NULL AND @pCalendarType IN ('Solar', 'Lunar')
        BEGIN
            DELETE FROM @vBirthday WHERE wCalendarType <> @pCalendarType;
        END;
        -----------------------------------END 生日日期---------------------------------------

        ------------------------------------戶口身份------------------------------------------
        DECLARE @vAgentIdentity TABLE(
            wCode   VARCHAR(30) PRIMARY KEY,
            wTitle  NVARCHAR(50)
        );
        INSERT INTO @vAgentIdentity(wCode, wTitle)
        VALUES  ('SHARE',                N'股東'),
                ('SEC_SHARE',            N'股東'),
                ('AGENT',                N'代理'),
                ('CREDIT_AGENT',         N'代理'),
                ('SEC_AGENT',            N'代理'),
                ('SEC_CREDIT_AGENT',     N'代理'),
                ('GAMBLERS',             N'玩家'),
                ('CREDIT_GAMBLERS',      N'玩家'),
                ('SEC_GAMBLERS',         N'玩家'),
                ('SEC_CREDIT_GAMBLERS',  N'玩家');
        -----------------------------------END 戶口身份----------------------------------------

	    ------------------------------------戶口級別--------------------------------------------
        DECLARE @vAccountType TABLE (
            wCode   VARCHAR(30) PRIMARY KEY,
            wTitle  NVARCHAR(50)
        );
        INSERT INTO @vAccountType(wCode, wTitle)
        SELECT wCode, wTitle FROM dbo.fnGetAgentAccountType('zh-TW');
	    ------------------------------------END 戶口級別--------------------------------------------

        ------------------------------------授權人身份----------------------------------------------
        DECLARE @vAuthIdentity TABLE(
            wCode   VARCHAR(30) PRIMARY KEY,
            wTitle  NVARCHAR(50)
        );
        INSERT INTO @vAuthIdentity(wCode, wTitle)
        VALUES  ('AUTH',        N'授權人'),
                ('OWNER',       N'戶主'),
                ('BOSS',        N'幕後老闆'),
                ('STAFF',       N'伙記'),
                ('ASSISTANT',   N'業務發展部助理'),
                ('FAMILY',      N'家人'),
                ('PARTNER',     N'拍檔'),
                ('CLIENT',      N'客人'),
                ('WARRANTOR',   N'借貸担保人'),
                ('MARKETNG',    N'市場部'),
                ('DIRECTOR',    N'總監'),
                ('MDBOSS',      N'MD幕後老闆'),
                ('AGENT',       N'戶主'),
                ('CUST',        N'客人'),
                ('CRM_CUST',    N'CRM客人'),
                ('PERSONAL',    N'個人授權');
        ----------------------------------END 授權人身份-------------------------------------------

        ------------------------------------客人身份-----------------------------------------------
        DECLARE @vPersonIdentity TABLE(
            wCode   VARCHAR(30) PRIMARY KEY,
            wTitle  NVARCHAR(50)
        );
        INSERT INTO @vPersonIdentity(wCode, wTitle)
        SELECT wCode, wTitle FROM dbo.mLookUp WHERE wType = 'VIP_PERSON_IDENTITY' AND wLangCd = @pLangCd;
        -----------------------------------END 客人身份---------------------------------------------

        ------------------------------------送禮類型-----------------------------------------------
        DECLARE @vBirthdayGiftType TABLE(
            wCode   VARCHAR(30) PRIMARY KEY,
            wTitle  NVARCHAR(50)
        );
        INSERT INTO @vBirthdayGiftType(wCode, wTitle)
        SELECT wCode, wTitle FROM dbo.mLookUp WHERE wType = 'BIRTHDAY_GIFT_TYPE' AND wLangCd = @pLangCd;
        -----------------------------------END 送禮類型---------------------------------------------

        ------------------------------------生日地區-----------------------------------------------
        DECLARE @vRegion TABLE(
            wCode   VARCHAR(30) PRIMARY KEY,
            wTitle  NVARCHAR(50)
        );
        INSERT INTO @vRegion(wCode, wTitle)
        SELECT wCode, wTitle FROM dbo.mLookUp WHERE wType = 'BIRTHDAY_REGION' AND wLangCd = @pLangCd;
        -----------------------------------END 生日地區---------------------------------------------

        SELECT
            wBirthdayRid = ISNULL(eb.RowID, 0),
            wBirthdayGiftRid = ISNULL(bg.RowID, 0),
            wVIPPersonRid = mp.RowID,
            wIsNew = ISNULL(eb.wIsNew, 'Y'),
            mp.wAgentCodeIn,
            ma.wAgentCode_Display,
            wAgentName = ma.wCName,
            mp.wPersonName,
            wAgentAuthIdentity = IIF(mp.wIsAuthorizer = 'Y', aai.wTitle, NULL), -- 客戶身份(授權人)
            wPersonIdentity = vpn.wTitle,   -- VIP身份
            wAgentIdentity = vat.wTitle,    -- 戶口身份
            mp.wBirthDate,
            wIsChineseCalendar = IIF(mp.wCalendarType = 'Lunar', 'Y', 'N'),
            wCalendarType = IIF(mp.wCalendarType = 'Lunar', N'農曆', N'新曆'),
            wYear = vb.wYear,
            mp.wMonth,
            mp.wDay,
            mp.wIsLeapMonth,
            wAge = vb.wYear - mp.wYear,
            wRollingAvgAmt = CONVERT(NUMERIC(18,4), 0),
            wCreditAmt = ISNULL(eb.wCreditAmt, 0) / 10000,
            bg.wBudgetAmt,
            mp.wBudgetRatio,
            bg.wCostAmt,
            wIsRefusedContact = IIF(eb.wIsRefusedContact = 'Y', N'是', N'否'),
            wGiftType = gt.wTitle,  -- 是否送禮
            wMFMFollowTeam = CONVERT(NVARCHAR(100), NULL), -- 澳門跟進組別
            wMFMFollowUser = CONVERT(NVARCHAR(100), NULL), -- 澳門跟進人
            wMNLFollowTeam = CONVERT(NVARCHAR(100), NULL), -- 馬尼拉跟進組別
            wMNLFollowUser = CONVERT(NVARCHAR(100), NULL), -- 馬尼拉跟進人
            wApprovedStatus = IIF(eb.wApprovedStatus = 'Y', N'已批核', N'未批核'),
            wGiftStatus = IIF(eb.wGiftStatus = 'Y', N'已送出', N'未送出'),
            eb.wStatus
        INTO #vResult
        FROM dbo.mVIPPerson mp
        INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = mp.wAgentCodeIn
        INNER JOIN @vBirthday vb ON vb.wCalendarType = mp.wCalendarType AND vb.wMonth = mp.wMonth AND vb.wDay = mp.wDay
        LEFT JOIN dbo.eBirthday eb ON eb.wVIPPersonRid = mp.RowID AND eb.wYear = vb.wYear AND eb.wIsLeapMonth = vb.wIsLeapMonth AND eb.wStatus = 'A'
        LEFT JOIN dbo.eBirthdayGift bg ON bg.wBirthdayRid = eb.RowID AND bg.wStatus = 'A'
        LEFT JOIN RollsMary.dbo.mDepartment md ON md.RowID = eb.wFollowDeptRid
        LEFT JOIN @vBirthdayGiftType gt ON gt.wCode = eb.wGiftType
        LEFT JOIN @vPersonIdentity vpn ON vpn.wCode = mp.wPersonIdentity
        LEFT JOIN @vAuthIdentity aai ON aai.wCode = mp.wAuthorizerIdentity
        LEFT JOIN @vAccountType vat ON vat.wCode = ma.wAccountType
        -- LEFT JOIN @vFollowDept fd ON fd.wDeptCd = md.wCode
        WHERE mp.wStatus = 'A'
            --AND (eb.RowID IS NULL OR eb.wIsNew = 'Y' OR (eb.wIsNew = 'N' AND fd.wDeptCd IS NOT NULL)) -- 新記錄，後面再算跟進，舊記錄，取Record值
            AND ((mp.wPersonIdentity IN ('MD_CLIENT', 'MD_AGENT') AND @sMDFollow = 'Y') OR (mp.wPersonIdentity NOT IN ('MD_CLIENT', 'MD_AGENT') AND @sVIPFollow = 'Y'))
        OPTION(RECOMPILE);
        
        -- 2018-12-12：改為直接取VIP客戶身份，不跟代理跟進
        /*    
        -- 新記錄，取戶口當前跟進
        -----------------------------戶口跟進組別、部門、組員---------------------------------------
        CREATE TABLE #vAgentFollow(
            wAgentCodeIn VARCHAR(14) PRIMARY KEY,
            wFollowTeamRid BIGINT,
            wFollowDeptRid BIGINT,
            wFollowUsrRid BIGINT
        );

        -----------------------------T掉wIsNew='Y'嘅非VIP/MD跟進的戶口-----------------------------
        DELETE FROM #vAgentFollow;
        INSERT INTO #vAgentFollow( wAgentCodeIn )
        SELECT DISTINCT wAgentCodeIn FROM #vResult WHERE wIsNew = 'Y'; -- 只需要算新記錄的跟進MD/VIP，舊記錄取Record值
        
        -- 獲取每個戶口的第一個跟進部門、組別、成員
        IF EXISTS (SELECT 1 FROM #vAgentFollow)
        BEGIN
            UPDATE vaf
            SET vaf.wFollowTeamRid = ISNULL(af.wTeamRid, 0),
                vaf.wFollowDeptRid = ISNULL(af.wDeptRid, 0),
                vaf.wFollowUsrRid = ISNULL(af.wUsrRid, 0)
            FROM #vAgentFollow vaf
            LEFT JOIN (
                SELECT
                    af.wAgentCodeIn,
                    af.wTeamRid, 
                    af.wDeptRid,
                    af.wUsrRid
                FROM (
                    SELECT wRowNum = ROW_NUMBER() OVER (PARTITION BY af.wAgentCodeIn ORDER BY md.wCode DESC, afd.wIsMainInCharge DESC),
                            af.wAgentCodeIn,
                            af.wTeamRid, 
                            af.wDeptRid,
                            afd.wUsrRid
                    FROM RollsMary.dbo.mAgentFollow af
                    INNER JOIN RollsMary.dbo.mAgentFollowDtl afd ON afd.wAgentFollowRid = af.RowID
                    INNER JOIN RollsMary.dbo.mDepartment md ON md.RowID = af.wDeptRid
                    INNER JOIN @vFollowDept fd ON fd.wDeptCd = md.wCode
                    WHERE NULLIF(af.wYearMth, '') IS NULL AND af.wStatus = 'A'
                        AND NULLIF(afd.wYearMth, '') IS NULL AND afd.wStatus = 'A'
                        AND md.wActive = 'A' -- 只需要取VIP（HOUSEKEEPER）、MD（DEVELOP）跟進
                ) AS af WHERE af.wRowNum = 1 -- 取每一個戶口的第一人跟進人（順序：VIP主負責人、VIP跟進人、MD主負責人、MD跟進人）
            ) af ON af.wAgentCodeIn = vaf.wAgentCodeIn
            OPTION(RECOMPILE);
            
            -- T掉非MD/VIP跟進記錄
            UPDATE r
            SET r.wStatus = 'T'
            FROM #vResult r
            LEFT JOIN #vAgentFollow af ON af.wAgentCodeIn = r.wAgentCodeIn
            LEFT JOIN RollsMary.dbo.mDepartment md ON md.RowID = af.wFollowDeptRid
            LEFT JOIN @vFollowDept fd ON fd.wDeptCd = md.wCode
            WHERE r.wIsNew = 'Y' AND fd.wDeptCd IS NULL;
            
            DELETE FROM #vResult WHERE wStatus = 'T';
        END;
        -----------------------------END T掉wIsNew='Y'嘅非VIP/MD跟進的戶口-----------------------------
        */

        CREATE TABLE #vAgentFollowTeam(
            wAgentCodeIn    VARCHAR(14),
            wFollowLocation NVARCHAR(50),
            wFollowTeam     NVARCHAR(50),
            wFollowUsr      NVARCHAR(50),
        )

        CREATE TABLE #vAgentFollowTeamGroup(
            wAgentCodeIn    VARCHAR(14),
            wFollowLocation NVARCHAR(50),
            wFollowTeam     NVARCHAR(500),
            wFollowUsr      NVARCHAR(500),
            PRIMARY KEY(wAgentCodeIn, wFollowLocation)
        )

        INSERT INTO #vAgentFollowTeam(wAgentCodeIn, wFollowLocation, wFollowTeam, wFollowUsr)
        SELECT af.wAgentCodeIn,
               mt.wLocation,
               mt.wName,
               mu.wCName
        FROM RollsMary.dbo.mAgentFollow af
        INNER JOIN #vResult r ON r.wAgentCodeIn = af.wAgentCodeIn
        INNER JOIN RollsMary.dbo.mDepartment md ON md.RowID = af.wDeptRid
        INNER JOIN RollsMary.dbo.mTeam mt ON mt.RowId = af.wTeamRid
        INNER JOIN @vFollowDept fd ON fd.wDeptCd = md.wCode
        LEFT JOIN RollsMary.dbo.mAgentFollowDtl afd ON afd.wAgentFollowRid = af.RowID
        LEFT JOIN RollsMary.dbo.mUsr mu ON mu.RowID = afd.wUsrRid
        WHERE NULLIF(af.wYearMth, '') IS NULL AND af.wStatus = 'A'
            AND (afd.RowID IS NULL OR NULLIF(afd.wYearMth, '') IS NULL AND afd.wStatus = 'A')
            AND mt.wLocation IN('macau', 'philippines') AND NULLIF(mt.wYearMth, '') IS NULL AND mt.wStatus = 'A'
            AND md.wActive = 'A' -- 只需要取VIP（HOUSEKEEPER）、MD（DEVELOP）跟進
        OPTION(RECOMPILE);
        
        INSERT INTO #vAgentFollowTeamGroup(wAgentCodeIn, wFollowLocation, wFollowTeam, wFollowUsr)
        SELECT
            af.wAgentCodeIn, 
            af.wFollowLocation,
            wFollowTeam = STUFF((SELECT CONCAT(',', wFollowTeam) FROM #vAgentFollowTeam WHERE wAgentCodeIn = af.wAgentCodeIn AND wFollowLocation = af.wFollowLocation AND wFollowTeam IS NOT NULL GROUP BY wFollowTeam FOR XML PATH('')), 1, 1, N''),
            wFollowUsr = STUFF((SELECT CONCAT(',', wFollowUsr) FROM #vAgentFollowTeam WHERE wAgentCodeIn = af.wAgentCodeIn AND wFollowLocation = af.wFollowLocation AND wFollowUsr IS NOT NULL GROUP BY wFollowUsr FOR XML PATH('')), 1, 1, N'')
        FROM #vAgentFollowTeam af
        GROUP BY af.wAgentCodeIn, af.wFollowLocation;

        -- Update跟進組別、跟進部門
        -- 1、未批核（澳門）
        UPDATE r
        SET r.wMFMFollowTeam = af.wFollowTeam,
            r.wMFMFollowUser = af.wFollowUsr
        FROM #vResult r
        LEFT JOIN #vAgentFollowTeamGroup af ON af.wAgentCodeIn = r.wAgentCodeIn AND af.wFollowLocation = 'macau';
            
        -- 2、未批核（馬尼拉）
        UPDATE r
        SET r.wMNLFollowTeam = af.wFollowTeam,
            r.wMNLFollowUser = af.wFollowUsr
        FROM #vResult r
        LEFT JOIN #vAgentFollowTeamGroup af ON af.wAgentCodeIn = r.wAgentCodeIn AND af.wFollowLocation = 'philippines';

        -- 3、已批核（澳門）
        --UPDATE r
        --SET r.wMFMFollowTeam = mt.wName,
        --    r.wMFMFollowUser = mu.wCName
        --FROM #vResult r
        --INNER JOIN dbo.eBirthday eb ON eb.RowID = r.wBirthdayRid
        --LEFT JOIN RollsMary.dbo.mTeam mt ON mt.RowId = eb.wFollowTeamRid
        --LEFT JOIN RollsMary.dbo.mUsr mu ON mu.RowID = eb.wFollowUsrRid
        --WHERE eb.wApprovedStatus = 'Y'
        --    AND mt.wLocation = 'macau';

        -- 4、未批核（馬尼拉）
        --UPDATE r
        --SET r.wMNLFollowTeam = mt.wName,
        --    r.wMNLFollowUser = mu.wCName
        --FROM #vResult r
        --INNER JOIN dbo.eBirthday eb ON eb.RowID = r.wBirthdayRid
        --LEFT JOIN RollsMary.dbo.mTeam mt ON mt.RowId = eb.wFollowTeamRid
        --LEFT JOIN RollsMary.dbo.mUsr mu ON mu.RowID = eb.wFollowUsrRid
        --WHERE eb.wApprovedStatus = 'Y'
        --    AND mt.wLocation = 'philippines';
        ---------------------------END 戶口跟進組別、部門、組員-------------------------------------

        -------------------------------------------戶口身份-----------------------------------------
        CREATE TABLE #vAgentIdentity(
            wAgentCodeIn    VARCHAR(14) PRIMARY KEY,
            wAgentIdentity  VARCHAR(30)
        );

        INSERT INTO #vAgentIdentity( wAgentCodeIn )
        SELECT DISTINCT wAgentCodeIn 
        FROM #vResult;

        UPDATE #vAgentIdentity SET wAgentIdentity = (SELECT TOP(1) wAgentIdentity FROM RollsMary.dbo.fnGetAgentIdentity(wAgentCodeIn));
        UPDATE r
        SET r.wAgentIdentity = CONCAT(tai.wTitle, IIF(r.wAgentIdentity IS NOT NULL, '/', ''), r.wAgentIdentity)
        FROM #vResult r
        INNER JOIN #vAgentIdentity vai ON vai.wAgentCodeIn = r.wAgentCodeIn
        INNER JOIN @vAgentIdentity tai ON tai.wCode = vai.wAgentIdentity
        -----------------------------------------END 戶口身份---------------------------------------

        -----------------------------------------三月平均轉碼---------------------------------------
        DECLARE @sXMLAgentCodeIn XML,
                @sXMLResult XML;

        DECLARE @vBirthdayBudget TABLE(
            wAgentCodeIn VARCHAR(14) PRIMARY KEY, 
            wRollingAvgAmt NUMERIC(18, 4), -- 平均轉碼
            wTotalBudgetAmt NUMERIC(18, 4) -- 戶口的總預算（生日禮物預算需要再乘以預算比例）
        );
         SET @sXMLAgentCodeIn = (
            SELECT DISTINCT wAgentCodeIn 
            FROM #vResult
            FOR XML RAW('Record'), ROOT('DataSet')
        );

        EXEC spq.GetBirthdayBudget @sXMLAgentCodeIn, @pBirthday, @sXMLResult OUTPUT;
            
        INSERT INTO @vBirthdayBudget
        SELECT
            wAgentCodeIn    = T.tmp.value('@wAgentCodeIn',    'VARCHAR(14)'),
            wRollingAvgAmt  = T.tmp.value('@wRollingAvgAmt',  'NUMERIC(18, 4)'),
            wTotalBudgetAmt = T.tmp.value('@wTotalBudgetAmt', 'NUMERIC(18, 4)')
        FROM @sXMLResult.nodes('DataSet/Record') T(tmp);

        UPDATE r
        SET r.wRollingAvgAmt = ISNULL(ra.wRollingAvgAmt, 0)
        FROM #vResult r
        LEFT JOIN @vBirthdayBudget ra ON ra.wAgentCodeIn = r.wAgentCodeIn;
        ----------------------------------------END 三月平均轉碼--------------------------------------

        -- 是否送禮
        -- 如果三個月平均轉碼大於一億，「是否送禮」要default 為「送禮物」，如果小於/等於一億，「是否送禮」則default為「送禮券」
        -- 如果VIP客戶資料剔佐「不送禮」，「是否送禮」要default為「不送禮」
        -- 如果系生日管理界面保存過，不再更新「是否送禮」
        ------------------------------------------------------
        --UPDATE r
        --SET r.wGiftType = IIF(r.wRollingAvgAmt > 10000, '003', '002') -- 轉碼單位：萬
        --FROM #vResult r
        --INNER JOIN dbo.mVIPPerson mp ON mp.RowID = r.wVIPPersonRid
        --WHERE r.wIsNew = 'Y';

        -- 2018-12-03：R#53665，更改預設值 (原要求預設為"送禮卷"，現改預設為"送禮物")
        UPDATE r
        SET r.wGiftType = '003'
        FROM #vResult r
        INNER JOIN dbo.mVIPPerson mp ON mp.RowID = r.wVIPPersonRid
        WHERE r.wIsNew = 'Y';
        ------------------------------------------------------

        UPDATE r 
        SET wBudgetAmt = CASE wGiftType
                         WHEN '003' THEN ra.wTotalBudgetAmt * ISNULL(r.wBudgetRatio, 0)         -- 送禮物
                         WHEN '002' THEN IIF(ISNULL(r.wRollingAvgAmt, 0) < 5000, 1000, 2000)    -- 送禮券
                         ELSE 0 END, -- 不送禮
            wCostAmt   = CASE wGiftType
                         WHEN '003' THEN ra.wTotalBudgetAmt * ISNULL(r.wBudgetRatio, 0)         -- 送禮物
                         WHEN '002' THEN IIF(ISNULL(r.wRollingAvgAmt, 0) < 5000, 1000, 2000)    -- 送禮券
                         ELSE 0 END -- 不送禮
        FROM #vResult r
        LEFT JOIN @vBirthdayBudget ra ON ra.wAgentCodeIn = r.wAgentCodeIn
        WHERE r.wIsNew = 'Y';

        UPDATE r
        SET r.wGiftType = gt.wTitle
        FROM #vResult r
        LEFT JOIN @vBirthdayGiftType gt ON gt.wCode = r.wGiftType
        WHERE r.wIsNew = 'Y';
        ------------------------------------------------------

        -- 禮物未送出，獲取最新的欠M數
        ------------------------------------------------------
        IF EXISTS(SELECT 1 FROM #vResult WHERE wGiftStatus <> N'已送出')
        BEGIN
            UPDATE r
            SET r.wCreditAmt = ISNULL( wRealOutstanding_CAP_OD + 
                                       wRealOutstanding_MTH_OD + 
                                       wRealOutstanding_MASTER_OD + 
                                       wRealOutstanding_CREDIT_OD + 
                                       wRealOutstanding_IOU_OD +
                                       wRealOutstanding_CIO_OD + 
                                       wOutstanding_CH_OD +
                                       wRealOutstanding_F_OD + 
                                       wRealOutstanding_Y_OD, 0) / 10000
            FROM #vResult r
            LEFT JOIN RollsMary.dbo.mAgentCredit ac ON ac.wAgentCodeIn = r.wAgentCodeIn AND ac.wType = 'LIVE'
            WHERE r.wGiftStatus <> N'已送出';
        END;
        ------------------------------------------------------

        SELECT * FROM #vResult ORDER BY wYear,wMonth,wDay;

        --IF OBJECT_ID('tempdb..#vAgentFollow') IS NOT NULL
        --    DROP TABLE #vAgentFollow;

        IF OBJECT_ID('tempdb..#vAgentFollowTeam') IS NOT NULL
            DROP TABLE #vAgentFollowTeam;

        IF OBJECT_ID('tempdb..#vAgentFollowTeamGroup') IS NOT NULL
            DROP TABLE #vAgentFollowTeamGroup;

        IF OBJECT_ID('tempdb..#vAgentIdentity') IS NOT NULL
            DROP TABLE #vAgentIdentity;

        IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
            DROP TABLE #vResult;
    END;