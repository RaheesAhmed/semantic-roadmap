CREATE PROC [spq].[GetBirthdayMonthSummary]
    @pXMLBirthday XML,
    @pXMLFilter XML
AS 
    BEGIN
        SET NOCOUNT ON;

        ---------------------- dbml ------------------------
        --DECLARE @vResult TABLE(
        --    wTotalCount         INT, 
        --    wApprovedCount      INT, 
        --    wUnApprovedCount    INT,
        --    wUnSendCount        INT, 
        --    wTotalBudgetAmt     NUMERIC(18,4), 
        --    wApprovedBudgetAmt  NUMERIC(18,4), 
        --    wBalanceBudgetAmt   NUMERIC(18,4)
        --);
        --SELECT * FROM @vResult;
        --------------------end dbml -----------------------

        DECLARE @pCalendarType      CHAR(5),        -- 日曆類型
                @pYear              INT,            -- 年
                @pMonth             INT,            -- 月
                @pBirthdayMonth     DATE,           -- 生日年月
                @pDeptFollow        VARCHAR(30),    -- 跟進部門
                @pRegion            VARCHAR(30);    -- 客戶地區

        DECLARE @sTotalCount        INT,            -- 生日人數
                @sApprovedCount     INT,            -- 需禮物數量
                @sUnApprovedCount   INT,            -- 未批核數量
                @sUnSendCount       INT,            -- 未送數量
                @sTotalBudgetAmt    NUMERIC(18, 4), -- 總預算
                @sApprovedBudgetAmt NUMERIC(18, 4), -- 已批預算
                @sBalanceBudgetAmt  NUMERIC(18, 4); -- 餘額

        -- 跟進部門
        DECLARE @vFollowDept TABLE(wDeptCd VARCHAR(30) PRIMARY KEY);

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

        -- 戶口預算
        DECLARE @vBirthdayBudget TABLE(
            wAgentCodeIn VARCHAR(14), 
            wRollingAvgAmt NUMERIC(18, 4), -- 平均轉碼
            wTotalBudgetAmt NUMERIC(18, 4) -- 戶口的總預算（生日禮物預算需要再乘以預算比例）
        );

        IF @pXMLFilter IS NOT NULL
        BEGIN
            SET @pCalendarType = @pXMLFilter.value('(Filter/@pCalendarType)[1]', 'CHAR(5)');
            SET @pYear         = @pXMLFilter.value('(Filter/@pYear)[1]',         'INT');
            SET @pMonth        = @pXMLFilter.value('(Filter/@pMonth)[1]',        'INT');
            SET @pDeptFollow   = @pXMLFilter.value('(Filter/@pDeptFollow)[1]',   'VARCHAR(30)');
            SET @pRegion       = @pXMLFilter.value('(Filter/@pRegion)[1]',       'VARCHAR(30)');
            
            -- SET @pCalendarType = NULLIF(@pCalendarType, '');
            SET @pCalendarType  = NULL;
            SET @pDeptFollow    = NULLIF(@pDeptFollow, '');
            SET @pRegion        = NULLIF(@pRegion, '');
            SET @pBirthdayMonth = DATEFROMPARTS(@pYear, @pMonth, 1);

            -- 跟進部門
            IF @pDeptFollow IS NOT NULL
            BEGIN
                DECLARE @sDeptXML XML = CONVERT(XML,'<DataSet><Record>' + REPLACE(@pDeptFollow, ',', '</Record><Record>') + '</Record></DataSet>');

                INSERT INTO @vFollowDept(wDeptCd)
                SELECT DISTINCT wDeptCd = IIF(T.tmp.value('.', 'VARCHAR(30)') = 'VIP', 'HOUSEKEEPER', 'DEVELOP')
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
        
        SELECT
            wBirthdayRid = eb.RowID,
            eb.wIsNew,
            eb.wVIPPersonRid,
            mp.wAgentCodeIn,
            eb.wGiftType,
            eb.wApprovedStatus,
            eb.wGiftStatus,
            wBudgetRatio = ISNULL(mp.wBudgetRatio, 0),
            wBudgetAmt   = CONVERT(NUMERIC(18,4), 0),
            wCostAmt     = CONVERT(NUMERIC(18,4), 0),
            wStatus      = 'A'
        INTO #vBirthday
        FROM dbo.eBirthday eb
        INNER JOIN dbo.mVIPPerson mp ON mp.RowID = eb.wVIPPersonRid
        INNER JOIN @vBirthday vb ON 1 = 1
        LEFT JOIN RollsMary.dbo.mDepartment md ON md.RowID = eb.wFollowDeptRid
        WHERE eb.wStatus = 'A'
            AND eb.wIsRefusedContact = 'N'
            AND vb.wCalendarType = mp.wCalendarType 
            AND vb.wYear = eb.wYear 
            AND vb.wMonth = mp.wMonth 
            AND vb.wDay = mp.wDay 
            AND vb.wIsLeapMonth = eb.wIsLeapMonth
            AND (@pRegion IS NULL OR @pRegion = eb.wRegion)
            AND (eb.wIsNew = 'Y' OR (eb.wIsNew = 'N' AND EXISTS(SELECT 1 FROM @vFollowDept fd WHERE fd.wDeptCd = md.wCode))) -- 新記錄，後面再算跟進，舊記錄，取Record值
        OPTION(RECOMPILE);

        -- 添加主鍵，否則Join得很慢
        ALTER TABLE #vBirthday ADD PRIMARY KEY(wBirthdayRid);

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
        FROM #vBirthday
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
            UPDATE vb
            SET vb.wStatus = 'T'
            FROM #vBirthday vb
            LEFT JOIN #vAgentFollow af ON af.wAgentCodeIn = vb.wAgentCodeIn AND vb.wIsNew = 'Y'
            LEFT JOIN RollsMary.dbo.mDepartment md ON md.RowID = af.wFollowDeptRid
            LEFT JOIN @vFollowDept fd ON fd.wDeptCd = md.wCode
            WHERE vb.wIsNew = 'Y' AND fd.wDeptCd IS NULL;
            
            DELETE FROM #vBirthday WHERE wStatus = 'T';
        END;
        --------------------------------------------------------------------------
        
        -- 預算
        IF EXISTS (SELECT 1 FROM #vBirthday WHERE wIsNew = 'Y')
        BEGIN
            DECLARE @sXMLAgentCodeIn    XML,
                    @sXMLResult         XML;

            SET @sXMLAgentCodeIn = (
                SELECT  wAgentCodeIn
                FROM    #vBirthday
                WHERE   wIsNew = 'Y'
                GROUP BY wAgentCodeIn
                FOR XML RAW('Record'), ROOT('DataSet')
            );
            
            -- 計算戶口總預算
            EXEC spq.GetBirthdayBudget @sXMLAgentCodeIn, @pBirthdayMonth, @sXMLResult OUTPUT;

            INSERT INTO @vBirthdayBudget
            SELECT
                wAgentCodeIn    = T.tmp.value('@wAgentCodeIn',    'VARCHAR(14)'),
                wRollingAvgAmt  = T.tmp.value('@wRollingAvgAmt',  'NUMERIC(18, 4)'),
                wTotalBudgetAmt = T.tmp.value('@wTotalBudgetAmt', 'NUMERIC(18, 4)')
            FROM @sXMLResult.nodes('DataSet/Record') T(tmp);
            
            -- 是否送禮
            -- 如果三個月平均轉碼大於一億，「是否送禮」要default 為「送禮物」，如果小於/等於一億，「是否送禮」則default為「送禮券」
            -- 如果VIP客戶資料剔佐「不送禮」，「是否送禮」要default為「不送禮」
            -- 如果系生日管理界面保存過，不再更新「是否送禮」
            ------------------------------------------------------
            UPDATE vb
            SET vb.wGiftType = IIF(mp.wIsPresentGift = 'N', '001', IIF(bb.wRollingAvgAmt > 10000, '003', '002')) -- 轉碼單位：萬
            FROM #vBirthday vb
            INNER JOIN dbo.mVIPPerson mp ON mp.RowID = vb.wVIPPersonRid
            LEFT JOIN @vBirthdayBudget bb ON bb.wAgentCodeIn = vb.wAgentCodeIn
            WHERE vb.wIsNew = 'Y';
            ------------------------------------------------------
        END;
        -- END 預算

        SET @sTotalCount      = (SELECT COUNT(1) FROM #vBirthday); -- 生日總人數（不包括拒絕接觸的客戶，是否送禮包括：不送禮、送禮券、送禮物）
        SET @sApprovedCount   = (SELECT COUNT(1) FROM #vBirthday WHERE wApprovedStatus = 'Y');
        SET @sUnApprovedCount = (SELECT COUNT(1) FROM #vBirthday WHERE wApprovedStatus = 'N');
        SET @sUnSendCount     = (SELECT COUNT(1) FROM #vBirthday WHERE wApprovedStatus = 'Y' AND wGiftStatus = 'N');
       
        -- 總預算
        SET @sTotalBudgetAmt = (
            SELECT SUM(IIF(bg.RowID IS NOT NULL, ISNULL(bg.wBudgetAmt, 0), 
                           CASE vb.wGiftType
                           WHEN '003' THEN bb.wTotalBudgetAmt * vb.wBudgetRatio    -- 送禮物
                           WHEN '002' THEN IIF(ISNULL(bb.wRollingAvgAmt, 0) < 5000, 1000, 2000)    -- 送禮券
                           ELSE 0 END -- 不送禮
                      ))
            FROM #vBirthday vb
            LEFT JOIN dbo.eBirthdayGift bg ON bg.wBirthdayRid = vb.wBirthdayRid
            LEFT JOIN @vBirthdayBudget bb ON bb.wAgentCodeIn = vb.wAgentCodeIn
            WHERE vb.wGiftType <> '001'
                AND (bg.RowID IS NULL OR bg.wStatus = 'A')
        );
        
        -- 已批預算
        SET @sApprovedBudgetAmt = (
            SELECT SUM(bg.wBudgetAmt)
            FROM #vBirthday vb
            INNER JOIN dbo.eBirthdayGift bg ON bg.wBirthdayRid = vb.wBirthdayRid
            WHERE vb.wApprovedStatus = 'Y' 
                AND vb.wGiftType <> '001'
                AND bg.wStatus = 'A'
        );

        -- 餘額
        SET @sBalanceBudgetAmt = (
            SELECT SUM(bg.wBudgetAmt - bg.wCostAmt)
            FROM #vBirthday vb
            INNER JOIN dbo.eBirthdayGift bg ON bg.wBirthdayRid = vb.wBirthdayRid
            WHERE vb.wApprovedStatus = 'Y' 
                AND vb.wGiftType <> '001'
                AND bg.wStatus = 'A'
        );

        SELECT 
            wTotalCount         = ISNULL(@sTotalCount, 0), 
            wApprovedCount      = ISNULL(@sApprovedCount, 0), 
            wUnApprovedCount    = ISNULL(@sUnApprovedCount, 0),
            wUnSendCount        = ISNULL(@sUnSendCount, 0), 
            wTotalBudgetAmt     = ISNULL(@sTotalBudgetAmt, 0), 
            wApprovedBudgetAmt  = ISNULL(@sApprovedBudgetAmt, 0), 
            wBalanceBudgetAmt   = ISNULL(@sBalanceBudgetAmt, 0);

        IF OBJECT_ID('tempdb..#vBirthday') IS NOT NULL
            DROP TABLE #vBirthday;
    END;