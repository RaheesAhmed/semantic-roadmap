
CREATE PROCEDURE [spq].[GetBirthdayLst]
    @pXMLFilter     XML,
    @pXMLBirthday   XML,
    @pLangCd        VARCHAR(10) = 'zh-TW',
    @pPageSize      INT = 15,
    @pPageNum       INT = 1 
AS
    BEGIN
        SET NOCOUNT ON;	  	

        --IF @@trancount = 0
        --    SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        -- dbml
        ------------------------------------------------------------------
        --DECLARE @vResult TABLE (
        --    RowID                   BIGINT          NOT NULL,
        --    wVIPPersonRid           BIGINT          NOT NULL,
        --    wIsNew                  CHAR(1)         NOT NULL,
        --    wAgentCodeIn            VARCHAR(14),
        --    wAgentCode_Display      NVARCHAR(50), 
        --    wAgentName              NVARCHAR(50),
        --    wAgentIdentity          NVARCHAR(30),
        --    wPersonName             NVARCHAR(50),
        --    wRelationship           VARCHAR(30),
        --    wOtherRelationship      NVARCHAR(200),
        --    wAuthorizerAgentCodeIn  VARCHAR(14),
        --    wAuthorizerName         NVARCHAR(50),
        --    wCalendarType           CHAR(5)         NOT NULL,
        --    wBirthdayYear           INT             NOT NULL,
        --    wBirthdayMonth          INT             NOT NULL,
        --    wBirthdayDay            INT             NOT NULL,
        --    wBudgetRatio            NUMERIC(18,4),
        --    wVIPPersonStatus        CHAR(1)         NOT NULL,
        --    wYear                   INT             NOT NULL,
        --    wIsLeapMonth            CHAR(1)         NOT NULL,
        --    wGiftType               VARCHAR(10),
        --    wRegion                 VARCHAR(30),
        --    wFollowDeptRid          BIGINT,
        --    wFollowTeamRid          BIGINT,
        --    wFollowTeamName         NVARCHAR(50),
        --    wFollowUsrRid           BIGINT,
        --    wFollowUsrName          NVARCHAR(50),
        --    wIsPushWeChat           CHAR(1),
        --    wIsRefusedContact       VARCHAR(1),
        --    wPresetGiftDt           DATE,
        --    wCreditAmt              NUMERIC(18,4),
        --    wRollingAvgAmt          NUMERIC(18,4),
        --    wApprovedStatus         VARCHAR(5),
        --    wGiftStatus             VARCHAR(5),
        --    wSMSStatus              VARCHAR(5),
        --    wUpdBy                  NVARCHAR(50),
        --    wUpdDt                  DATETIME2(7)        NOT NULL,
        --    wRecordCount            INT NOT NULL
        --);
        --SELECT * FROM @vResult;
        ------------------------------------------------------------------

        SET @pLangCd   = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');
        SET @pPageSize = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 15);
        SET @pPageNum  = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);

        DECLARE @pCalendarType      CHAR(5),        -- 日曆類型
                @pAgentCode         NVARCHAR(30),   -- 戶口
                @pPersonName        NVARCHAR(50),   -- 客戶姓名
                @pGiftType          VARCHAR(10),    -- 是否送禮
                @pGiftStatus        VARCHAR(5),     -- 送禮狀態
                @pApprovedStatus    VARCHAR(5),     -- 批核狀態
                @pDeptFollow        VARCHAR(30),    -- 跟進部門
                @pRegion            VARCHAR(30);    -- 客戶地區
                
        DECLARE @sXMLAgentCodeIn XML,
                @sBirthday DATE = CAST(GETDATE() AS DATE);

        -- 跟進部門
        DECLARE @vFollowDept TABLE(wDeptCd VARCHAR(30) PRIMARY KEY);
        -- 轉碼
        DECLARE @vRollingAvg TABLE(wAgentCodeIn VARCHAR(14), wRollingAvgAmt NUMERIC(18, 4));
        DECLARE @vRollingAgent TABLE(wAgentCodeIn VARCHAR(14), wYear INT, wMonth INT );
        DECLARE @vRollingYearMonth TABLE(RowID INT IDENTITY(1,1), wYear INT, wMonth INT, xmlAgentCodeIn XML);

        -- 生日
        DECLARE @vBirthday TABLE(
            wCalendarType   CHAR(5),
            wBirthday       DATE,
            wYear           INT,
            wMonth          INT,
            wDay            INT,
            wIsLeapMonth    CHAR(1)
            PRIMARY KEY(wCalendarType, wBirthday, wYear, wMonth, wDay, wIsLeapMonth)
        );

        -- 平均轉碼
        CREATE TABLE #vRollingAvg (
            wAgentCodeIn    VARCHAR(14), 
            wYear           INT,
            wMonth          INT,
            wRollingAvgAmt  NUMERIC(18, 4),
            PRIMARY KEY(wAgentCodeIn, wYear, wMonth)
        );

        -- 過濾條件
        IF @pXMLFilter IS NOT NULL    
        BEGIN
            SET @pCalendarType   = @pXMLFilter.value('(Filter/@pCalendarType)[1]',   'CHAR(5)');
            SET @pAgentCode      = @pXMLFilter.value('(Filter/@pAgentCode)[1]',      'NVARCHAR(30)');
            SET @pPersonName     = @pXMLFilter.value('(Filter/@pPersonName)[1]',     'NVARCHAR(50)');
            SET @pGiftType       = @pXMLFilter.value('(Filter/@pGiftType)[1]',       'VARCHAR(10)');
            SET @pGiftStatus     = @pXMLFilter.value('(Filter/@pGiftStatus)[1]',     'VARCHAR(5)');
            SET @pApprovedStatus = @pXMLFilter.value('(Filter/@pApprovedStatus)[1]', 'VARCHAR(5)');
            SET @pDeptFollow     = @pXMLFilter.value('(Filter/@pDeptFollow)[1]',     'VARCHAR(30)');
            SET @pRegion         = @pXMLFilter.value('(Filter/@pRegion)[1]',         'VARCHAR(30)');
            
            SET @pCalendarType   = NULLIF(@pCalendarType , '');
            SET @pAgentCode      = NULLIF(@pAgentCode, '');
            SET @pPersonName     = IIF(NULLIF(@pPersonName, '') IS NULL, NULL, CONCAT('%', LTRIM(RTRIM(@pPersonName)) ,'%'));
            SET @pGiftType       = NULLIF(@pGiftType, '');
            SET @pGiftStatus     = NULLIF(@pGiftStatus, '');
            SET @pApprovedStatus = NULLIF(@pApprovedStatus, '');
            SET @pDeptFollow     = NULLIF(@pDeptFollow, '');
            SET @pRegion         = NULLIF(@pRegion, '');
            
            -- 跟進部門
            IF @pDeptFollow IS NOT NULL
            BEGIN
                DECLARE @sDeptXML XML;
                SET @pDeptFollow = REPLACE(REPLACE(@pDeptFollow, 'VIP', 'HOUSEKEEPER'), 'MD', 'DEVELOP');
                SET @sDeptXML = CONVERT(XML,'<DataSet><Record>' + REPLACE(@pDeptFollow, ',', '</Record><Record>') + '</Record></DataSet>');

                INSERT INTO @vFollowDept(wDeptCd)
                SELECT DISTINCT T.tmp.value('.', 'VARCHAR(30)')
                FROM @sDeptXML.nodes('DataSet/Record') T(tmp);
            END;
        END;
        
        -- 生日條件
        IF @pXMLBirthday IS NOT NULL
        BEGIN
            INSERT INTO @vBirthday
            SELECT DISTINCT
                wCalendarType = T.tmp.value('@pCalendarType', 'CHAR(5)'),
                wBirthday     = T.tmp.value('@pBirthday',     'DATE'),
                wYear         = T.tmp.value('@pYear',         'INT'),
                wMonth        = T.tmp.value('@pMonth',        'INT'),
                wDay          = T.tmp.value('@pDay',          'INT'),
                wIsLeapMonth  = T.tmp.value('@pIsLeapMonth',  'CHAR(1)')
            FROM @pXMLBirthday.nodes('DataSet/Record') T(tmp);

            -- 刪除無效生日，新曆沒有閏月
            DELETE FROM @vBirthday WHERE wCalendarType NOT IN ('Solar', 'Lunar') OR wIsLeapMonth NOT IN ('Y', 'N') OR (wCalendarType = 'Solar' AND wIsLeapMonth = 'Y');
            -- 篩選新/舊曆（只SELECT新/舊曆）
            IF @pCalendarType IS NOT NULL AND @pCalendarType IN ('Solar', 'Lunar')
            BEGIN
                DELETE FROM @vBirthday WHERE wCalendarType <> @pCalendarType;
            END;
        END;
        
        -- 在生日條件範圍內的所有VIP客戶
        SELECT
            wBirthdayRid = eb.RowID,
            vb.wBirthday, -- 新曆（計算轉碼）
            eb.wIsNew,
            mp.RowID, 
            ma.wAgentCodeIn,
            ma.wAgentCode_Display, 
            wAgentName = IIF(@pLangCd = 'zh-TW', ma.wCName, ma.wEName),
            wAgentIdentity= CONVERT(NVARCHAR(30), N''),
            mp.wPersonName,
            mp.wRelationship, 
            mp.wOtherRelationship,
            mp.wAuthorizerAgentCodeIn,
            wAuthorizerName = IIF(@pLangCd = 'zh-TW', mu.wCName, mu.wEName),
            mp.wCalendarType,
            mp.wYear,
            mp.wMonth,
            mp.wDay,
            mp.wIsLeapMonth,
            wIsPushWeChat = mp.wIsWeChatVerify, 
            mp.wIsPresentGift,
            mp.wBudgetRatio,
            mp.wVIPPersonStatus,
            wFollowDeptRid = eb.wFollowDeptRid,
            wFollowTeamRid = eb.wFollowTeamRid,
            wFollowTeamName = mt.wName,
            wFollowUsrRid = eb.wFollowUsrRid,
            wFollowUsrName = IIF(@pLangCd = 'zh-TW', ml.wCName, ml.wName),
            eb.wStatus
        INTO #vVIPPerson
        FROM dbo.eBirthday eb
        INNER JOIN dbo.mVIPPerson mp ON mp.RowID = eb.wVIPPersonRid
        INNER JOIN @vBirthday vb ON 1 = 1
        INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = mp.wAgentCodeIn             -- 戶口
        LEFT JOIN RollsMary.dbo.mAgent mu ON mu.wAgentCodeIn = mp.wAuthorizerAgentCodeIn    -- 授權人
        LEFT JOIN RollsMary.dbo.mDepartment md ON md.RowID = eb.wFollowDeptRid
        LEFT JOIN RollsMary.dbo.mTeam mt ON mt.RowId = eb.wFollowTeamRid
        LEFT JOIN RollsMary.dbo.mUsr ml ON ml.RowID = eb.wFollowUsrRid
        WHERE eb.wStatus = 'A'
            AND vb.wCalendarType = mp.wCalendarType -- 新/舊曆生日
            AND vb.wYear = eb.wYear                 -- 生日年
            AND vb.wMonth = mp.wMonth               -- 生日月
            AND vb.wDay = mp.wDay                   -- 生日日
            AND vb.wIsLeapMonth = eb.wIsLeapMonth   -- 農曆閏月生日
            AND (@pApprovedStatus IS NULL OR @pApprovedStatus = eb.wApprovedStatus) -- 批核狀態
            AND (@pGiftStatus IS NULL OR @pGiftStatus = eb.wGiftStatus)             -- 送禮狀態
            AND (@pAgentCode IS NULL                                                -- 戶口搜索
                OR @pAgentCode = ma.wAgentCode 
                Or @pAgentCode = ma.wAgentCode_Old 
                Or @pAgentCode = ma.wAgentCode_Src 
                Or @pAgentCode = ma.wAgentCode_Display)
            AND (@pPersonName IS NULL OR mp.wPersonName LIKE  @pPersonName)         -- 客戶搜索
            AND (@pRegion IS NULL OR @pRegion = eb.wRegion)                         -- 地區
            AND (eb.wIsNew = 'Y' OR (eb.wIsNew = 'N' AND EXISTS(SELECT 1 FROM @vFollowDept fd WHERE fd.wDeptCd = md.wCode))) -- 新記錄，後面再算跟進，舊記錄，取Record值
        OPTION(RECOMPILE);
        
        -- 添加主鍵，否則Join得很慢
        ALTER TABLE #vVIPPerson ADD PRIMARY KEY(wBirthdayRid);
        
        -- 新記錄，取戶口當前跟進
        -- 戶口跟進組別、部門、組員
        --------------------------------------------------------------------------
        CREATE TABLE #vAgentFollow(
            wAgentCodeIn VARCHAR(14) PRIMARY KEY,
            wFollowTeamRid BIGINT,
            wFollowDeptRid BIGINT,
            wFollowUsrRid BIGINT
        );

        INSERT INTO #vAgentFollow( wAgentCodeIn )
        SELECT DISTINCT wAgentCodeIn 
        FROM #vVIPPerson
        WHERE wIsNew = 'Y'; -- 只需要算新記錄的跟進MD/VIP，舊記錄取Record值
        
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
                    WHERE NULLIF(af.wYearMth, '') IS NULL AND af.wStatus = 'A'
                        AND NULLIF(afd.wYearMth, '') IS NULL AND afd.wStatus = 'A'
                        AND md.wCode IN ('HOUSEKEEPER', 'DEVELOP') AND md.wActive = 'A' -- 只需要取VIP（HOUSEKEEPER）、MD（DEVELOP）跟進
                ) AS af WHERE af.wRowNum = 1 -- 取每一個戶口的第一人跟進人（順序：VIP主負責人、VIP跟進人、MD主負責人、MD跟進人）
            ) af ON af.wAgentCodeIn = vaf.wAgentCodeIn
            OPTION(RECOMPILE);
            
            -- T掉沒有跟進權限的記錄
            UPDATE mp
            SET mp.wStatus = 'T'
            FROM #vVIPPerson mp
            LEFT JOIN #vAgentFollow af ON af.wAgentCodeIn = mp.wAgentCodeIn AND mp.wIsNew = 'Y'
            LEFT JOIN RollsMary.dbo.mDepartment md ON md.RowID = af.wFollowDeptRid
            LEFT JOIN @vFollowDept fd ON fd.wDeptCd = md.wCode
            WHERE mp.wIsNew = 'Y' AND fd.wDeptCd IS NULL;
            
            DELETE FROM #vVIPPerson WHERE wStatus = 'T';

            -- 只Update新記錄
            UPDATE mp
            SET wFollowDeptRid  = af.wFollowDeptRid,
                wFollowTeamRid  = af.wFollowTeamRid,
                wFollowTeamName = mt.wName,
                wFollowUsrRid   = af.wFollowUsrRid,
                wFollowUsrName  = IIF(@pLangCd = 'zh-TW', ml.wCName, ml.wName)
            FROM #vVIPPerson mp
            INNER JOIN #vAgentFollow af ON af.wAgentCodeIn = mp.wAgentCodeIn AND mp.wIsNew = 'Y'
            LEFT JOIN RollsMary.dbo.mTeam mt ON mt.RowId = af.wFollowTeamRid
            LEFT JOIN RollsMary.dbo.mUsr ml ON ml.RowID = af.wFollowUsrRid;
        END;
        --------------------------------------------------------------------------

        DECLARE @sRecCount INT,
                @sRunIndex INT,
                @sAgentCodeIn VARCHAR(14);
        -- 送禮物、送禮券計算未生成禮物Record的戶口轉碼
        -- 如果送禮類型為空，不需要算轉碼，全部出
        -- 2018-12-03：R#53665，更改預設值 (原要求預設為"送禮卷"，現改預設為"送禮物")
        /*
        IF @pGiftType IS NOT NULL AND @pGiftType != '001'
        BEGIN
            INSERT INTO @vRollingAgent(wAgentCodeIn, wYear, wMonth)
            -- 只需要計算新記錄的轉碼數量，舊記錄已經確認過【是否送禮】，直接取Record值
            SELECT DISTINCT wAgentCodeIn, YEAR(wBirthday), MONTH(wBirthday) FROM #vVIPPerson WHERE wIsNew = 'Y'; 

            -- 同一個月的戶口Group埋一齊，一齊去算平均轉碼
            INSERT INTO @vRollingYearMonth(wYear, wMonth, xmlAgentCodeIn)
            SELECT 
                ra.wYear, 
                ra.wMonth, 
                xmlAgentCodeIn = (
                    SELECT sa.wAgentCodeIn 
                    FROM @vRollingAgent sa 
                    WHERE sa.wYear = ra.wYear 
                        AND sa.wMonth = ra.wMonth
                    FOR XML RAW('Record'), ROOT('DataSet')) 
            FROM @vRollingAgent ra
            GROUP BY ra.wYear, ra.wMonth;

            -- 依次去算平均轉碼
            SET @sRecCount = (SELECT COUNT(1) FROM @vRollingYearMonth);
            SET @sRunIndex = 1;

            WHILE @sRunIndex <= @sRecCount
            BEGIN
                SELECT 
                    @sBirthday = DATEFROMPARTS(wYear, wMonth, 1), 
                    @sXMLAgentCodeIn = xmlAgentCodeIn 
                FROM @vRollingYearMonth 
                WHERE RowID = @sRunIndex;

                INSERT INTO @vRollingAvg EXEC spq.GetRollingAvgForBirthday @sXMLAgentCodeIn, @sBirthday;

                INSERT INTO #vRollingAvg(wAgentCodeIn, wYear, wMonth, wRollingAvgAmt)
                SELECT
                    wAgentCodeIn,
                    wYear  = YEAR(@sBirthday),
                    wMonth = MONTH(@sBirthday),
                    wRollingAvgAmt
                FROM @vRollingAvg

                DELETE FROM @vRollingAvg;

                SET @sRunIndex = @sRunIndex + 1;
            END;
        END;
        */

        ;WITH tResult AS (
            SELECT
                eb.RowID,
                eb.wVIPPersonRid,
                eb.wIsNew,
                mp.wBirthday,
                mp.wAgentCodeIn,
                mp.wAgentCode_Display, 
                mp.wAgentName,
                mp.wAgentIdentity,
                mp.wPersonName,
                mp.wRelationship,
                mp.wOtherRelationship,
                mp.wAuthorizerAgentCodeIn,
                mp.wAuthorizerName,
                mp.wCalendarType,
                wBirthdayYear = mp.wYear,
                wBirthdayMonth = mp.wMonth,
                wBirthdayDay = mp.wDay,
                mp.wBudgetRatio,
                mp.wVIPPersonStatus,
                eb.wYear,
                eb.wIsLeapMonth,
                eb.wGiftType,
                eb.wRegion,
                mp.wFollowDeptRid,
                mp.wFollowTeamRid,
                mp.wFollowTeamName,
                mp.wFollowUsrRid,
                mp.wFollowUsrName,
                eb.wIsPushWeChat,
                eb.wIsRefusedContact,
                eb.wPresetGiftDt,
                eb.wCreditAmt,
                wRollingAvgAmt = CONVERT(NUMERIC(18,4), 0),
                eb.wApprovedStatus,
                eb.wGiftStatus,
                eb.wSMSStatus,
                wUpdBy = IIF(@pLangCd = 'zh-TW', mu.wCName, mu.wName),
                eb.wUpdDt
            FROM dbo.eBirthday eb
            INNER JOIN #vVIPPerson mp ON mp.wBirthdayRid = eb.RowID
            LEFT JOIN RollsMary.dbo.mUsr mu ON mu.RowID = eb.wUpdBy
            --LEFT JOIN #vRollingAvg ra ON ra.wAgentCodeIn = mp.wAgentCodeIn AND ra.wYear = YEAR(mp.wBirthday) AND ra.wMonth = MONTH(mp.wBirthday)
            --WHERE (@pGiftType IS NULL OR (eb.wIsNew = 'N' AND @pGiftType = eb.wGiftType) -- 記錄修改過
            --                          OR (eb.wIsNew = 'Y' AND @pGiftType = '001' AND mp.wIsPresentGift = 'N')  -- 原記錄，不送禮
            --                          OR (eb.wIsNew = 'Y' AND @pGiftType = '002' AND mp.wIsPresentGift = 'Y' AND ISNULL(ra.wRollingAvgAmt, 0) <= 10000) -- 原記錄，送禮券
            --                          OR (eb.wIsNew = 'Y' AND @pGiftType = '003' AND mp.wIsPresentGift = 'Y' AND ra.wRollingAvgAmt > 10000))            -- 原記錄，送禮物
            -- 2018-12-03：R#53665，更改預設值 (原要求預設為"送禮卷"，現改預設為"送禮物")
            WHERE (@pGiftType IS NULL OR (eb.wIsNew = 'N' AND @pGiftType = eb.wGiftType) -- 記錄修改過
                                      OR (eb.wIsNew = 'Y' AND @pGiftType = '001' AND mp.wIsPresentGift = 'N')  -- 原記錄，不送禮
                                      OR (eb.wIsNew = 'Y' AND @pGiftType = '003' AND mp.wIsPresentGift = 'Y')) -- 原記錄，送禮物
        ),
        tCount AS (
            SELECT wRecordCount = COUNT(1) FROM tResult
        )
        
        SELECT tResult.*, wRecordCount
        INTO #vResult
        FROM tResult, tCount
        ORDER BY RowID DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION(RECOMPILE);
        
        -- Update戶口身份
        UPDATE #vResult SET wAgentIdentity = (SELECT TOP(1) wAgentIdentity FROM RollsMary.dbo.fnGetAgentIdentity(wAgentCodeIn));

        -- 前面計算的轉碼，是用來Filter是否送禮
        -- 三個月平均轉碼數
        -----------------------------------------------------
        DELETE FROM #vRollingAvg;
        DELETE FROM @vRollingAvg;
        DELETE FROM @vRollingAgent;
        DELETE FROM @vRollingYearMonth;

        INSERT INTO @vRollingAgent(wAgentCodeIn, wYear, wMonth)
        SELECT DISTINCT wAgentCodeIn, YEAR(wBirthday), MONTH(wBirthday) FROM #vResult; 

        -- 同一個月的戶口Group埋一齊，一齊去算平均轉碼
        INSERT INTO @vRollingYearMonth(wYear, wMonth, xmlAgentCodeIn)
        SELECT 
            ra.wYear, 
            ra.wMonth, 
            xmlAgentCodeIn = (
                SELECT sa.wAgentCodeIn 
                FROM @vRollingAgent sa 
                WHERE sa.wYear = ra.wYear 
                    AND sa.wMonth = ra.wMonth
                FOR XML RAW('Record'), ROOT('DataSet')) 
        FROM @vRollingAgent ra
        GROUP BY ra.wYear, ra.wMonth;

        -- 依次去算平均轉碼
        SET @sRecCount = (SELECT COUNT(1) FROM @vRollingYearMonth);
        SET @sRunIndex = 1;

        WHILE @sRunIndex <= @sRecCount
        BEGIN
            SELECT @sBirthday = DATEFROMPARTS(wYear, wMonth, 1), 
                   @sXMLAgentCodeIn = xmlAgentCodeIn 
            FROM   @vRollingYearMonth 
            WHERE  RowID = @sRunIndex;

            INSERT INTO @vRollingAvg EXEC spq.GetRollingAvgForBirthday @sXMLAgentCodeIn, @sBirthday;

            INSERT INTO #vRollingAvg(wAgentCodeIn, wYear, wMonth, wRollingAvgAmt)
            SELECT
                wAgentCodeIn,
                wYear = YEAR(@sBirthday),
                wMonth = MONTH(@sBirthday),
                wRollingAvgAmt
            FROM @vRollingAvg;

            DELETE FROM @vRollingAvg;

            SET @sRunIndex = @sRunIndex + 1;
        END;
        
        UPDATE r
        SET r.wRollingAvgAmt = ISNULL(ra.wRollingAvgAmt, 0)
        FROM #vResult r
        LEFT JOIN #vRollingAvg ra ON ra.wAgentCodeIn = r.wAgentCodeIn AND ra.wYear = YEAR(r.wBirthday) AND ra.wMonth = MONTH(r.wBirthday);
        -----------------------------------------------------

        -- 是否送禮
        -- 如果三個月平均轉碼大於一億，「是否送禮」要default 為「送禮物」，如果小於/等於一億，「是否送禮」則default為「送禮券」
        -- 如果VIP客戶資料剔佐「不送禮」，「是否送禮」要default為「不送禮」
        -- 如果系生日管理界面保存過，不再更新「是否送禮」
        ------------------------------------------------------
        --UPDATE r
        --SET r.wGiftType = IIF(mp.wIsPresentGift = 'N', '001', IIF(r.wRollingAvgAmt > 10000, '003', '002')) -- 轉碼單位：萬
        --FROM #vResult r
        --INNER JOIN dbo.mVIPPerson mp ON mp.RowID = r.wVIPPersonRid
        --WHERE r.wIsNew = 'Y';

        -- 2018-12-03：R#53665，更改預設值 (原要求預設為"送禮卷"，現改預設為"送禮物")
        UPDATE r
        SET r.wGiftType = IIF(mp.wIsPresentGift = 'N', '001', '003') -- 轉碼單位：萬
        FROM #vResult r
        INNER JOIN dbo.mVIPPerson mp ON mp.RowID = r.wVIPPersonRid
        WHERE r.wIsNew = 'Y';
        ------------------------------------------------------

        -- 禮物未送出，獲取最新的欠M數
        ------------------------------------------------------
        IF EXISTS(SELECT 1 FROM #vResult WHERE wGiftStatus <> 'Y')
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
                                       wRealOutstanding_Y_OD, 0)
            FROM #vResult r
            LEFT JOIN RollsMary.dbo.mAgentCredit ac ON ac.wAgentCodeIn = r.wAgentCodeIn
            WHERE ac.wType = 'LIVE' AND r.wGiftStatus <> 'Y';
        END;
        ------------------------------------------------------
        
        SELECT 
            RowID,
            wVIPPersonRid,
            wIsNew,
            wAgentCodeIn,
            wAgentCode_Display, 
            wAgentName,
            wAgentIdentity,
            wPersonName,
            wRelationship,
            wOtherRelationship,
            wAuthorizerAgentCodeIn,
            wAuthorizerName,
            wCalendarType,
            wBirthdayYear,
            wBirthdayMonth,
            wBirthdayDay,
            wBudgetRatio,
            wVIPPersonStatus,
            wYear,
            wIsLeapMonth,
            wGiftType,
            wRegion,
            wFollowDeptRid,
            wFollowTeamRid,
            wFollowTeamName,
            wFollowUsrRid,
            wFollowUsrName,
            wIsPushWeChat,
            wIsRefusedContact,
            wPresetGiftDt,
            wCreditAmt,
            wRollingAvgAmt,
            wApprovedStatus,
            wGiftStatus,
            wSMSStatus,
            wUpdBy,
            wUpdDt,
            wRecordCount
        FROM #vResult;
        
        IF OBJECT_ID('tempdb..#vRollingAvg') IS NOT NULL
            DROP TABLE #vRollingAvg;

        IF OBJECT_ID('tempdb..#vVIPPerson') IS NOT NULL
            DROP TABLE #vVIPPerson;
        
        IF OBJECT_ID('tempdb..#vAgentFollow') IS NOT NULL
            DROP TABLE #vAgentFollow;

        IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
            DROP TABLE #vResult;
    END;