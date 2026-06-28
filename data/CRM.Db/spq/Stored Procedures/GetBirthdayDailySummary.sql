CREATE PROC [spq].[GetBirthdayDailySummary]
    @pXMLBirthday XML,
    @pXMLFilter XML
AS
    BEGIN
        SET NOCOUNT ON;

        --IF @@trancount = 0
        --    SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        --------------------dbml--------------------
        --DECLARE @vBirthdayGift TABLE(
        --  wBirthday DATE NOT NULL,
        --  wGiftType VARCHAR(10) NOT NULL,
        --  wApprovedStatus CHAR(5) NOT NULL,
        --  wGiftStatus VARCHAR(5) NOT NULL,
        --  wGiftCount INT NOT NULL
        --);
        --SELECT * FROM @vResult;
        ------------------END dbml ------------------
        
        DECLARE @pCalendarType  CHAR(5),        -- 日曆類型
                @pDeptFollow    VARCHAR(30),    -- 跟進部門
                @pRegion        VARCHAR(30);    -- 客戶地區;

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

        IF @pXMLFilter IS NOT NULL
        BEGIN
            SET @pCalendarType  = @pXMLFilter.value('(Filter/@pCalendarType)[1]',   'CHAR(5)');
            SET @pDeptFollow    = @pXMLFilter.value('(Filter/@pDeptFollow)[1]',     'VARCHAR(30)');
            SET @pRegion        = @pXMLFilter.value('(Filter/@pRegion)[1]',         'VARCHAR(30)');

            -- SET @pCalendarType = NULLIF(@pCalendarType, '');
            SET @pCalendarType  = NULL;
            SET @pDeptFollow    = NULLIF(@pDeptFollow, '');
            SET @pRegion        = NULLIF(@pRegion, '');

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
            eb.wIsNew,
            mp.wAgentCodeIn,
            vb.wBirthday,
            eb.wGiftType,
            eb.wApprovedStatus,
            eb.wGiftStatus,
            eb.wStatus
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

        SELECT
            vb.wBirthday,
            vb.wGiftType,
            vb.wApprovedStatus,
            vb.wGiftStatus,
            wGiftCount = COUNT(1)
        FROM #vBirthday vb
        GROUP BY vb.wBirthday, vb.wGiftType, vb.wApprovedStatus, vb.wGiftStatus;

        IF OBJECT_ID('tempdb..#vBirthday') IS NOT NULL
            DROP TABLE #vBirthday;
    END;