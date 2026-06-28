CREATE PROC [spq].[GetRptBirthdayApproval]
    @pXMLFilter XML,
    @pXMLBirthday XML,
    @pLangCd VARCHAR(10) = 'zh-TW'
AS
    BEGIN
        SET NOCOUNT ON;

        --------------------------------------------------------------------------------------
        -- dbml
        --DECLARE @vResult TABLE(
        --    wAgentCode_Display  NVARCHAR(30),
        --    wAgentIdentity      NVARCHAR(100),
        --    wIsShare            VARCHAR(1),
        --    wPersonName         NVARCHAR(50),
        --    wPersonIdentity     NVARCHAR(50),
        --    wGender             VARCHAR(1),
        --    wIsChineseCalendar  VARCHAR(1),
        --    wCalendarType       NVARCHAR(5),
        --    wYear               INT NOT NULL,
        --    wMonth              INT NOT NULL,
        --    wDay                INT NOT NULL,
        --    wIsLeapMonth        CHAR(1) NOT NULL,
        --    wAge                INT NOT NULL,
        --    wBudgetCurrency     VARCHAR(50),
        --    wBudgetAmt          NUMERIC(18,4),
        --    wBudgetRatio        NUMERIC(18,4),
        --    wCostCurrency       VARCHAR(50),
        --    wCostAmt            NUMERIC(18,4),
        --    wGiftDescription    NVARCHAR(500),
        --    wGiftReason         NVARCHAR(500),
        --    wGiftRemark         NVARCHAR(4000),
        --    wGiftImage          VARBINARY(MAX),
        --    wRollingAvgAmt      NUMERIC(18,4),
        --    wCreditAmt          NUMERIC(18,4),
        --    wBirthdaySource     NVARCHAR(50),
        --    wSortNo             INT
        --)

        --SELECT * FROM @vResult;
        --------------------------------------------------------------------------------------

        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

        DECLARE @pCalendarType  CHAR(5),        -- 日曆類型
                @pBirthday      DATE,           -- 生日月份（計算平均轉碼）
                @pDeptFollow    VARCHAR(30),    -- 跟進部門
                @pRegion        VARCHAR(30),    -- 地區
                @pIsMDStar      VARCHAR(2),     -- 市場部星級客戶
                @sNow           DATETIME2(7) = GETDATE();

        -- 跟進部門
        DECLARE @vFollowDept TABLE(wDeptCd VARCHAR(30) PRIMARY KEY);

        -- 過濾條件
        IF @pXMLFilter IS NOT NULL
        BEGIN
            SET @pCalendarType  = @pXMLFilter.value('(Filter/@pCalendarType)[1]',   'CHAR(5)');
            SET @pBirthday      = @pXMLFilter.value('(Filter/@pBirthday)[1]',       'DATE');
            SET @pDeptFollow    = @pXMLFilter.value('(Filter/@pDeptFollow)[1]',     'VARCHAR(30)');
            SET @pRegion        = @pXMLFilter.value('(Filter/@pRegion)[1]',         'VARCHAR(30)');
            SET @pIsMDStar      = @pXMLFilter.value('(Filter/@pIsMDStar)[1]',       'VARCHAR(2)');

            SET @pCalendarType  = NULLIF(@pCalendarType, '');
            SET @pDeptFollow    = NULLIF(@pDeptFollow,   '');
            SET @pRegion        = NULLIF(@pRegion, '');
            SET @pIsMDStar      = NULLIF(@pIsMDStar, '');
            
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

                -- DELETE FROM @vFollowDept WHERE wDeptCd = 'DEVELOP'; -- 暫時屏蔽MD生日名單
            END;
        END;

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
        -- 過濾新/舊歷
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
        DECLARE @vAccountType AS TABLE (
	    	wCode VARCHAR(10) PRIMARY KEY,
	    	wTitle NVARCHAR(10)
	    );
	    INSERT INTO  @vAccountType(wCode, wTitle)
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

        ------------------------------------信息來源-----------------------------------------------
        DECLARE @vBirthdaySource TABLE(
            wCode   VARCHAR(30) PRIMARY KEY,
            wTitle  NVARCHAR(50)
        );
        INSERT INTO @vBirthdaySource(wCode, wTitle)
        SELECT wCode, wTitle FROM dbo.mLookUp WHERE wType = 'VIP_BIRTHDAY_SOURCE' AND wLangCd = @pLangCd;
        -----------------------------------END 信息來源---------------------------------------------

        SELECT
            wBirthdayRid = ISNULL(eb.RowID, 0),
            wBirthdayGiftRid = ISNULL(bg.RowID, 0),
            wVIPPersonRid = mp.RowID,
            wIsNew = ISNULL(eb.wIsNew, 'Y'),
            mp.wAgentCodeIn,
            ma.wAgentCode_Display,
            wAgentName = ma.wCName,
            wIsShare = 'N', -- 是否是股東
            wIsMDStar = 'N', -- 市場部星級客戶
            mp.wPersonName,
            wAgentIdentity = vat.wTitle,    -- 戶口組別/戶口身份（格式：股東/太陽客戶）
            wAuthIdentity = IIF(mp.wIsAuthorizer = 'Y', aai.wTitle, NULL), -- 客戶身份(授權人身份)
            wPersonIdentity = vpi.wTitle,   -- VIP身份
            mp.wGender,
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
            wBudgetCurrency = ISNULL(bg.wBudgetCurrency, 'MOP'),
            bg.wBudgetAmt,
            mp.wBudgetRatio,
            wCostCurrency = ISNULL(bg.wCostCurrency, 'MOP'),
            bg.wCostAmt,
            bg.wGiftDescription,
            bg.wGiftReason,
            wGiftRemark = bg.wRemark,
            wGiftType = gt.wTitle,  -- 是否送禮
            wSource = IIF(bg.RowID IS NOT NULL, bg.wSource, mp.wSource),
            wApprovedStatus = IIF(eb.wApprovedStatus = 'Y', N'已批核', N'未批核'),
            wGiftStatus = IIF(eb.wGiftStatus = 'Y', N'已送出', N'未送出'),
            eb.wStatus
        INTO #vResult
        FROM dbo.mVIPPerson mp
        INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = mp.wAgentCodeIn
        INNER JOIN @vBirthday vb ON vb.wCalendarType = mp.wCalendarType AND vb.wMonth = mp.wMonth AND vb.wDay = mp.wDay
        INNER JOIN dbo.eBirthday eb ON eb.wVIPPersonRid = mp.RowID AND eb.wYear = vb.wYear AND eb.wIsLeapMonth = vb.wIsLeapMonth AND eb.wStatus = 'A'
        INNER JOIN dbo.eBirthdayGift bg ON bg.wBirthdayRid = eb.RowID AND bg.wStatus = 'A'
        LEFT JOIN RollsMary.dbo.mDepartment md ON md.RowID = eb.wFollowDeptRid
        LEFT JOIN @vBirthdayGiftType gt ON gt.wCode = eb.wGiftType
        LEFT JOIN @vPersonIdentity vpi ON vpi.wCode = mp.wPersonIdentity
        LEFT JOIN @vAuthIdentity aai ON aai.wCode = mp.wAuthorizerIdentity
        LEFT JOIN @vAccountType vat ON vat.wCode = ma.wAccountType
        LEFT JOIN @vFollowDept fd ON fd.wDeptCd = md.wCode
        WHERE mp.wStatus = 'A' 
            AND eb.wGiftType <> '001'
            AND eb.wApprovedStatus = 'Y'
            AND eb.wIsRefusedContact = 'N'
            AND (@pRegion IS NULL OR @pRegion = eb.wRegion)
            AND (eb.wIsNew = 'Y' OR (eb.wIsNew = 'N' AND fd.wDeptCd IS NOT NULL)) -- 新記錄，後面再算跟進，舊記錄，取Record值
        OPTION(RECOMPILE);
        
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

        -------------------------------------------戶口身份-----------------------------------------
        CREATE TABLE #vAgentIdentity(
            wAgentCodeIn    VARCHAR(14) PRIMARY KEY,
            wAgentIdentity  VARCHAR(30)
        );

        INSERT INTO #vAgentIdentity( wAgentCodeIn )
        SELECT DISTINCT wAgentCodeIn FROM #vResult;

        UPDATE #vAgentIdentity SET wAgentIdentity = (SELECT TOP(1) wAgentIdentity FROM RollsMary.dbo.fnGetAgentIdentity(wAgentCodeIn));
        
        UPDATE r
        SET r.wAgentIdentity = CONCAT(tai.wTitle, IIF(r.wAgentIdentity IS NOT NULL, ' / ', ''), r.wAgentIdentity),
            r.wIsShare = IIF(vai.wAgentIdentity IN ('SHARE', 'SEC_SHARE'), 'Y', 'N' ) -- 股東
        FROM #vResult r
        INNER JOIN #vAgentIdentity vai ON vai.wAgentCodeIn = r.wAgentCodeIn
        INNER JOIN @vAgentIdentity tai ON tai.wCode = vai.wAgentIdentity

        -- 市場部星級客戶
        UPDATE r
        SET wAgentIdentity = CONCAT(N'星級',' / ',r.wAgentIdentity), -- 星級/股東/太陽客戶
            wIsMDStar = 'Y'
        FROM  #vResult r
        INNER JOIN RollsMary.dbo.mAgentIdentity mi ON mi.wAgentCodeIn = r.wAgentCodeIn
        LEFT JOIN RollsMary.dbo.mDepartment dept ON dept.RowID = mi.wDeptRid
        WHERE  mi.wValue = 'Y'
            AND mi.wType = 'STAR' 
            AND dept.wCode = 'DEVELOP';
        
        -- 星級/玩家報表，T掉所有非星級/玩家客戶
        UPDATE r
        SET r.wStatus = 'T'
        FROM #vResult r
        LEFT JOIN #vAgentIdentity vai ON vai.wAgentCodeIn = r.wAgentCodeIn
        WHERE @pIsMDStar = 'Y' AND vai.wAgentIdentity NOT LIKE '%GAMBLERS%' AND r.wIsMDStar != 'Y';

        DELETE FROM #vResult WHERE wStatus = 'T';
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
        SELECT wAgentCodeIn    = T.tmp.value('@wAgentCodeIn',    'VARCHAR(14)'),
               wRollingAvgAmt  = T.tmp.value('@wRollingAvgAmt',  'NUMERIC(18, 4)'),
               wTotalBudgetAmt = T.tmp.value('@wTotalBudgetAmt', 'NUMERIC(18, 4)')
        FROM @sXMLResult.nodes('DataSet/Record') T(tmp);

        UPDATE r
        SET r.wRollingAvgAmt = ISNULL(ra.wRollingAvgAmt, 0)
        FROM #vResult r
        LEFT JOIN @vBirthdayBudget ra ON ra.wAgentCodeIn = r.wAgentCodeIn;
        ----------------------------------------END 三月平均轉碼--------------------------------------

        --------------------------------------------送禮預算------------------------------------------
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
        ------------------------------------------END 送禮預算----------------------------------------
        
        ---------------------------------------------欠M數--------------------------------------------
        -- 禮物未送出，獲取最新的欠M數
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
        -------------------------------------------END 欠M數------------------------------------------

        SELECT 
            wAgentCode_Display,
            wAgentIdentity,
            wIsShare,
            wPersonName,
            wPersonIdentity,
            wGender,
            wIsChineseCalendar,
            wCalendarType,
            wYear,
            wMonth,
            wDay,
            wIsLeapMonth,
            wAge,
            wBudgetCurrency,
            wBudgetAmt,
            wBudgetRatio,
            wCostCurrency,
            wCostAmt,
            wGiftDescription,
            wGiftReason,
            wGiftRemark,
            wGiftImage = ISNULL(dm.wFileData, do.wFileData),
            wRollingAvgAmt,
            wCreditAmt,
            wBirthdaySource =bs.wTitle
        FROM #vResult r
        LEFT JOIN @vBirthdaySource bs ON bs.wCode = r.wSource
        LEFT JOIN CRM_Doc.dbo.eDocument dm ON dm.wRefRID = r.wBirthdayGiftRid AND dm.wRefTable = 'eBirthdayGift' AND dm.wSizeType = 'M' AND dm.wStatus = 'A'
        LEFT JOIN CRM_Doc.dbo.eDocument do ON do.wRefRID = r.wBirthdayGiftRid AND do.wRefTable = 'eBirthdayGift' AND do.wSizeType = 'O' AND do.wStatus = 'A' AND dm.RowID IS NULL -- 舊數據
        WHERE r.wStatus = 'A'

        IF OBJECT_ID('tempdb..#vAgentFollow') IS NOT NULL
            DROP TABLE #vAgentFollow;

        IF OBJECT_ID('tempdb..#vAgentIdentity') IS NOT NULL
            DROP TABLE #vAgentIdentity;

        IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
            DROP TABLE #vResult;
    END;