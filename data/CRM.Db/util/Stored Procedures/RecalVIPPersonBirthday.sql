-- 每年12月1號自動執行Job，生成所有VIP客戶下一年的生日
-- 創建或者更新一個VIP客戶時，傳pVIPPersonRid客戶更新客戶的生日
-- 如果生日記錄存在，不再創建記錄
-- 農歷閏月會生成兩條記錄，其他情況只生成一條記錄
-- 當pSetAllVIPPerson='Y'，Check 所有VIP客戶的生日， pVIPPersonRid參數無效
-- 當pSetAllVIPPerson='N', Check pVIPPersonRid的生日
CREATE PROC [util].[RecalVIPPersonBirthday]
    @pYear              INT         = 0,
    @pSetAllVIPPerson   CHAR(1)     = 'Y',
    @pVIPPersonRid      BIGINT      = 0,
    @pAgentCodeIn       VARCHAR(14) = ''
AS
    BEGIN
        SET NOCOUNT ON;

        -- （1）如果 Year <= 0 OR NULL，生成 GETDATE() + 1個月得到的年的生日
        -- 例如：2018-06-01執行，加一個月 2018-07-01，就生成2018年的生日
        --       2018-12-01執行，加一個月 2019-01-01，就生成2019年的生日
        -- （2）如果 Year > 0，且在1900（不含）至2100（含）之間，只生成指定年份的生日
        -- （3）如果 Year > 0，且執行日期在12月份，生成兩條記錄生日記錄
        -- 例如： 2018-12-01執行，則生成2018、2019年的生日（如果不存在或者wStatus='T'）
        --       2018-06-01執行，則只生成2018年的生日（如果不存在或者wStatus='T'）
        SET @pYear = ISNULL(IIF(@pYear <= 0, NULL, @pYear), YEAR(DATEADD(MONTH, 1, GETDATE())));
        SET @pSetAllVIPPerson = ISNULL(@pSetAllVIPPerson, 'Y');
        SET @pVIPPersonRid = IIF(@pVIPPersonRid <= 0, NULL, @pVIPPersonRid);
        SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
        
        IF @pYear >= 1901 AND @pYear <= 2100
        BEGIN
            DECLARE @sThisTableName VARCHAR(50) = 'eBirthday',
                    @sNow           DATETIME2(7) = GETDATE();
            
            -- 生成哪些年份的生日
            DECLARE @vYear TABLE( wYear INT PRIMARY KEY );
            INSERT INTO @vYear (wYear) VALUES (@pYear);
            -- 如果與當前同年且在12月份執行生成指定年的生日，除了要生成本年的生日，還要生成第二年的生日
            -- 2018-12-01執行，則生成2018、2019年的生日
            IF @pYear = YEAR(@sNow) 
            BEGIN
                SET @pYear = YEAR(DATEADD(MONTH, 1, @sNow));
                IF NOT EXISTS (SELECT 1 FROM @vYear WHERE wYear = @pYear)
                    INSERT INTO @vYear (wYear) VALUES (@pYear);
            END;

            -- 新歷生日只有一條非閏月生日記錄
            -- 舊曆閏月會有兩條生日記錄（閏月、非閏月）
            DECLARE @vCalendar TABLE(
                wCalendarType CHAR(5),
                wIsLeapMonth CHAR(1),
                PRIMARY KEY(wCalendarType, wIsLeapMonth)
            );
            INSERT INTO @vCalendar( wCalendarType, wIsLeapMonth )
            VALUES ('Solar', 'N'), ('Lunar', 'N'), ('Lunar', 'Y');
            
            -- 戶口跟進
            DECLARE @vAgentFollow TABLE(wAgentCodeIn VARCHAR(14) PRIMARY KEY);
            CREATE TABLE #vAgentFollow(
                wAgentCodeIn VARCHAR(14) PRIMARY KEY,
                wFollowTeamRid BIGINT,
                wFollowDeptRid BIGINT,
                wFollowUsrRid BIGINT
            );

            --------------------------------------------------Check需要哪些生日---------------------------------------------
            -- 需要匯入的生日記錄
            CREATE TABLE #vBirthday (
                wRowNum         BIGINT,
                RowID           BIGINT DEFAULT(0),
                wVIPPersonRid   BIGINT,
                wAgentCodeIn    VARCHAR(14),
                wYear           INT,
                wIsLeapMonth    CHAR(1),
                wStatus         CHAR(1)
                PRIMARY KEY(RowID, wVIPPersonRid, wAgentCodeIn, wYear, wIsLeapMonth)
            );

            INSERT INTO #vBirthday(wVIPPersonRid, wAgentCodeIn, wYear, wIsLeapMonth, wStatus)
            SELECT DISTINCT
                wVIPPersonRid = mp.RowID,
                wAgentCodeIn  = mp.wAgentCodeIn,
                wYear         = y.wYear,
                wIsLeapMonth  = c.wIsLeapMonth,
                wStatus       = 'A'
            FROM dbo.eVIPPersonShip ps
            INNER JOIN dbo.eVIPPersonShip eps ON eps.wVIPPersonRid = eps.wVIPPersonRefRid AND eps.wVIPPersonRid = ps.wVIPPersonRefRid AND eps.wIsBirthday = 'Y' -- 是否生成生日
            INNER JOIN dbo.mVIPPerson mp ON mp.RowID = eps.wVIPPersonRid
            INNER JOIN @vCalendar c ON c.wCalendarType = mp.wCalendarType
            INNER JOIN @vYear y ON 1 = 1
            LEFT JOIN dbo.mYearMonth leap ON leap.wYear = y.wYear AND leap.wMonth = mp.wMonth AND leap.wIsLeapMonth = c.wIsLeapMonth AND c.wCalendarType = leap.wType
            LEFT JOIN dbo.eBirthday b ON b.wVIPPersonRid = mp.RowID AND b.wYear = y.wYear AND b.wIsLeapMonth = c.wIsLeapMonth AND b.wStatus = 'A'
            WHERE b.RowID IS NULL
                AND mp.wStatus = 'A'
                AND mp.wVIPPersonStatus = 'A'
                AND mp.wIsPresentGift   = 'Y' -- 只有剔佐送禮才生成生日記錄
                AND (@pSetAllVIPPerson  = 'Y' OR (@pSetAllVIPPerson = 'N' AND ps.wVIPPersonRid = @pVIPPersonRid))
                AND (@pAgentCodeIn IS NULL OR @pAgentCodeIn = mp.wAgentCodeIn)
                AND (c.wIsLeapMonth = 'N' OR (c.wIsLeapMonth = 'Y' AND leap.wType IS NOT NULL)) -- 必須是農曆閆月才有多一條記錄
                AND (mp.wYear > 1 AND mp.wMonth > 0 AND mp.wDay > 0) -- 慶生日期唔可以為空，mAgent過來的授權人生日，如果為空，則默認為（0001-01-01）
                AND (
                    (mp.wCalendarType = 'Solar' AND mp.wDay <= DATEDIFF(DAY, DATEFROMPARTS(y.wYear, mp.wMonth, 1), DATEADD(MONTH, 1, DATEFROMPARTS(y.wYear, mp.wMonth, 1))))
                    OR (mp.wCalendarType = 'Lunar' AND mp.wDay <= leap.wDaysOfMonth)
                );
            
            -- MD/VIP跟進的戶口（設置有MD/VIP跟進部門）
            -----------------------------------------
            DELETE FROM #vAgentFollow;
            DELETE FROM @vAgentFollow;

            -- 新增生日的戶口
            INSERT INTO #vAgentFollow(wAgentCodeIn)
            SELECT DISTINCT wAgentCodeIn 
            FROM #vBirthday;

            -- 當前MD/VIP跟進的戶口
            INSERT INTO @vAgentFollow(wAgentCodeIn)
            SELECT DISTINCT af.wAgentCodeIn
            FROM RollsMary.dbo.mAgentFollow af
            INNER JOIN RollsMary.dbo.mAgentFollowDtl afd ON afd.wAgentFollowRid = af.RowID
            INNER JOIN RollsMary.dbo.mDepartment md ON md.RowID = af.wDeptRid
            INNER JOIN #vAgentFollow vaf ON vaf.wAgentCodeIn = af.wAgentCodeIn
            WHERE NULLIF(af.wYearMth, '') IS NULL AND af.wStatus = 'A'
                AND NULLIF(afd.wYearMth, '') IS NULL AND afd.wStatus = 'A'
                AND md.wCode IN ('HOUSEKEEPER', 'DEVELOP') AND md.wActive = 'A' -- 只需要取VIP（HOUSEKEEPER）、MD（DEVELOP）跟進
            OPTION(RECOMPILE);

            -- T掉不是MD/VIP跟進的戶口
            UPDATE vb
            SET vb.wStatus = 'T'
            FROM #vBirthday vb
            LEFT JOIN @vAgentFollow af ON af.wAgentCodeIn = vb.wAgentCodeIn
            WHERE af.wAgentCodeIn IS NULL;
            
            -- 刪除wStatus='T'的Record不要Insert到eBirthday
            DELETE FROM #vBirthday WHERE wStatus = 'T';

            -- 對符合條件的Record進行排序
            UPDATE vb 
            SET wRowNum = svb.wRowNum
            FROM #vBirthday vb
            INNER JOIN ( 
                SELECT wRowNum = ROW_NUMBER() OVER(ORDER BY wVIPPersonRid, wYear, wIsLeapMonth),
                       wVIPPersonRid, 
                       wAgentCodeIn, 
                       wYear, 
                       wIsLeapMonth
                FROM #vBirthday
            ) svb ON svb.wVIPPersonRid = vb.wVIPPersonRid AND svb.wAgentCodeIn = vb.wAgentCodeIn AND svb.wYear = vb.wYear AND svb.wIsLeapMonth = vb.wIsLeapMonth;
            --------------------------------------------------End Check需要哪些生日---------------------------------------------
           
            DECLARE @sBeginTranCount INT,
                    @sUpdBy          BIGINT,
                    @sRowIndex       BIGINT,
                    @sRecCount       BIGINT,
                    @sRowID          BIGINT,
                    @sErrCode        INT,
                    @sErrMsg         NVARCHAR(MAX);

            SET @sBeginTranCount = @@trancount;
            SET @sErrCode = 0;
            SET @sErrMsg = '';
            -- 默認最後修改人為系統
            SET @sUpdBy = ISNULL(( SELECT TOP(1) RowID FROM RollsMary.dbo.mUsr WHERE wUsrId = 'SYSTEM' AND wName = 'System'), 0);

            BEGIN TRY
                IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

                --------------------------------------------------insert new birthday record---------------------------------------
                IF EXISTS (SELECT 1 FROM #vBirthday)
                BEGIN
                    SET @sRecCount = (SELECT COUNT(1) FROM #vBirthday);
                    SET @sRowIndex = 1;

                    WHILE @sRowIndex <= @sRecCount
                    BEGIN
                        EXEC spq.GetRowID 99, @sThisTableName, @sRowID OUTPUT;

                        UPDATE #vBirthday
                        SET RowID = @sRowID
                        WHERE wRowNum = @sRowIndex;
                        
                        SET @sRowIndex = @sRowIndex + 1;
                    END;

                    -- 戶口跟進組別、部門、組員
                    -- 獲取每個戶口的第一個跟進部門、組別、成員
                    --------------------------------------------------------------------------
                    DELETE FROM #vAgentFollow;
                    DELETE FROM @vAgentFollow;

                    -- 新增生日的戶口
                    INSERT INTO #vAgentFollow( wAgentCodeIn )
                    SELECT DISTINCT wAgentCodeIn
                    FROM #vBirthday;
                
                    -- 獲取每個戶口的第一個跟進部門、組別、成員
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
                    --------------------------------------------------------------------------

                    INSERT INTO dbo.eBirthday
                    (
                        RowID,
                        wVIPPersonRid,
                        wYear,
                        wIsLeapMonth,
                        wGiftType ,
                        wRegion,
                        wFollowDeptRid,
                        wFollowTeamRid,
                        wFollowUsrRid ,
                        wIsPushWeChat ,
                        wIsRefusedContact,
                        wPresetGiftDt,
                        wCreditAmt,
                        wApprovedStatus ,
                        wGiftStatus ,
                        wSMSStatus,
                        wStatus,
                        wCrtBy ,
                        wCrtDt ,
                        wUpdBy,
                        wUpdDt
                    )
                    SELECT
                        RowID = b.RowID,
                        wVIPPersonRid = b.wVIPPersonRid,
                        wYear = b.wYear,
                        wIsLeapMonth = b.wIsLeapMonth,
                        wGiftType = IIF(mp.wIsPresentGift = 'Y' AND mp.wIsRefusedContact = 'N', '003', '001'), -- 送禮且可接觸
                        wRegion = 'MFM',
                        wFollowDeptRid = af.wFollowDeptRid,
                        wFollowTeamRid = af.wFollowTeamRid,
                        wFollowUsrRid = af.wFollowUsrRid,
                        wIsPushWeChat = wIsWeChatVerify,
                        wIsRefusedContact = mp.wIsRefusedContact,
                        wPresetGiftDt = NULL,
                        wCreditAmt = 0,
                        wApprovedStatus = 'N',
                        wGiftStatus = 'N',
                        wSMSStatus = 'N',
                        wStatus = 'A',
                        wCrtBy = @sUpdBy,
                        wCrtDt = @sNow,
                        wUpdBy = @sUpdBy,
                        wUpdDt = @sNow
                    FROM #vBirthday b
                    INNER JOIN dbo.mVIPPerson mp ON mp.RowID = b.wVIPPersonRid
                    INNER JOIN #vAgentFollow af ON af.wAgentCodeIn = mp.wAgentCodeIn
                    WHERE af.wFollowDeptRid > 0; -- 只新加MD/VIP跟進的VIP客戶生日
                END;
                -----------------------------------------------end insert new birthday record---------------------------------------

                -----------------------------------------------update old birthday record（T掉送禮）---------------------------------------
                -- VIP客戶資料被修改過（狀態中止、相關戶口標識為非送禮戶口，如果之前生成的生日記錄沒有批核且沒有送出，則T掉此記錄）
                UPDATE eb
                SET eb.wStatus = 'T',
                    eb.wUpdDt = @sNow
                FROM dbo.eBirthday eb
                INNER JOIN @vYear y ON y.wYear = eb.wYear
                LEFT JOIN dbo.mVIPPerson mp ON mp.RowID = eb.wVIPPersonRid
                LEFT JOIN dbo.eVIPPersonShip ps ON ps.wVIPPersonRid = ps.wVIPPersonRefRid AND ps.wVIPPersonRid = eb.wVIPPersonRid AND ps.wIsBirthday = 'Y'
                WHERE (mp.RowID IS NULL OR mp.wStatus <> 'A' OR mp.wVIPPersonStatus <> 'A' OR mp.wIsPresentGift <> 'Y' OR ps.wVIPPersonRid IS NULL) -- 客戶資料中止使用、不送禮、關聯戶口未選擇
                    AND eb.wApprovedStatus = 'N'    -- 已批核的禮物不能T掉
                    AND eb.wGiftStatus = 'N'        -- 送出去的禮物不能T掉
                    AND eb.wStatus = 'A';           -- 有效的才需要T掉
                -----------------------------------------------end update old birthday record---------------------------------------

                ------------------------------------------------update old birthday record（無MD/VIP跟進T掉送禮）----------------------------
                DELETE FROM #vAgentFollow;
                DELETE FROM @vAgentFollow;

                -- 相關生日涉及戶口
                INSERT INTO #vAgentFollow(wAgentCodeIn)
                SELECT DISTINCT mp.wAgentCodeIn
                FROM dbo.eBirthday eb
                INNER JOIN @vYear y ON y.wYear = eb.wYear
                INNER JOIN dbo.mVIPPerson mp ON mp.RowID = eb.wVIPPersonRid
                WHERE (@pVIPPersonRid IS NULL OR @pVIPPersonRid = eb.wVIPPersonRid)
                    AND (@pAgentCodeIn IS NULL OR @pAgentCodeIn = mp.wAgentCodeIn)
                    AND eb.wApprovedStatus = 'N'    -- 已批核的禮物不能T掉
                    AND eb.wGiftStatus = 'N'        -- 送出去的禮物不能T掉
                    AND eb.wStatus = 'A';           -- 有效的才需要T掉
                
                -- 當前MD/VIP跟進的戶口
                INSERT INTO @vAgentFollow (wAgentCodeIn)
                SELECT DISTINCT af.wAgentCodeIn
                FROM RollsMary.dbo.mAgentFollow af
                INNER JOIN RollsMary.dbo.mAgentFollowDtl afd ON afd.wAgentFollowRid = af.RowID
                INNER JOIN RollsMary.dbo.mDepartment md ON md.RowID = af.wDeptRid
                INNER JOIN #vAgentFollow vaf ON vaf.wAgentCodeIn = af.wAgentCodeIn
                WHERE NULLIF(af.wYearMth, '') IS NULL AND af.wStatus = 'A'
                    AND NULLIF(afd.wYearMth, '') IS NULL AND afd.wStatus = 'A'
                    AND md.wCode IN ('HOUSEKEEPER', 'DEVELOP') AND md.wActive = 'A' -- 只需要取VIP（HOUSEKEEPER）、MD（DEVELOP）跟進
                OPTION(RECOMPILE);

                -- T掉非MD/VIP跟進的生日
                UPDATE eb
                SET eb.wStatus = 'T',
                    eb.wUpdDt = @sNow
                FROM dbo.eBirthday eb
                INNER JOIN @vYear y ON y.wYear = eb.wYear
                INNER JOIN dbo.mVIPPerson mp ON mp.RowID = eb.wVIPPersonRid
                LEFT JOIN @vAgentFollow af ON af.wAgentCodeIn = mp.wAgentCodeIn
                WHERE (@pVIPPersonRid IS NULL OR @pVIPPersonRid = eb.wVIPPersonRid)
                    AND (@pAgentCodeIn IS NULL OR @pAgentCodeIn = mp.wAgentCodeIn)
                    AND af.wAgentCodeIn IS NULL
                    AND eb.wApprovedStatus = 'N'    -- 已批核的禮物不能T掉
                    AND eb.wGiftStatus = 'N'        -- 送出去的禮物不能T掉
                    AND eb.wStatus = 'A';           -- 有效的才需要T掉
                --------------------------------------------------------------------------------------------------------------------
            
                -- 已經處理過嘅生日記錄，如果跟進轉佐另外一個部門，生日嘅跟進部門都要一齊轉
                ------------------------------------------------update old birthday record（跟進部門）------------------------------
                DELETE FROM #vAgentFollow;
                DELETE FROM @vAgentFollow;

                -- 獲取需要更新的生日記錄的wAgentCodeIn
                ;WITH tAgentFollow AS (
                    SELECT
                        af.wAgentCodeIn,
                        af.wDeptRid,
                        afd.wUsrRid
                    FROM RollsMary.dbo.mAgentFollow af
                    INNER JOIN RollsMary.dbo.mAgentFollowDtl afd ON afd.wAgentFollowRid = af.RowID
                    WHERE NULLIF(af.wYearMth, '') IS NULL AND af.wStatus = 'A'
                        AND NULLIF(afd.wYearMth, '') IS NULL AND afd.wStatus = 'A'
                )
            
                INSERT INTO #vAgentFollow(wAgentCodeIn)
                SELECT DISTINCT mp.wAgentCodeIn
                FROM dbo.eBirthday eb
                INNER JOIN @vYear y ON y.wYear = eb.wYear
                INNER JOIN dbo.mVIPPerson mp ON mp.RowID = eb.wVIPPersonRid
                LEFT JOIN tAgentFollow af ON af.wAgentCodeIn = mp.wAgentCodeIn AND af.wDeptRid = eb.wFollowDeptRid AND af.wUsrRid = eb.wFollowUsrRid -- 如果戶口的跟進部門、跟進人都換了，則需要把舊記錄的跟進Update一下
                WHERE (@pVIPPersonRid IS NULL OR @pVIPPersonRid = eb.wVIPPersonRid)
                    AND (@pAgentCodeIn IS NULL OR @pAgentCodeIn = mp.wAgentCodeIn)
                    AND af.wAgentCodeIn IS NULL
                    AND eb.wIsNew <> 'Y'            -- 處理過嘅Record
                    AND eb.wApprovedStatus = 'N'    -- 已批核的禮物不能Update
                    AND eb.wGiftStatus = 'N'        -- 送出去的禮物不能Update
                    AND eb.wStatus = 'A';           -- 有效才需要Update
                
                -- 獲取每個戶口的第一個跟進部門、組別、成員
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
            
                -- 更新處理過，但未批核、未送出、有效嘅生日
                UPDATE eb
                SET eb.wFollowDeptRid = af.wFollowDeptRid,
                    eb.wFollowTeamRid = af.wFollowTeamRid,
                    eb.wFollowUsrRid  = af.wFollowUsrRid
                FROM dbo.eBirthday eb
                INNER JOIN @vYear y ON y.wYear = eb.wYear
                INNER JOIN dbo.mVIPPerson mp ON mp.RowID = eb.wVIPPersonRid
                INNER JOIN #vAgentFollow af ON af.wAgentCodeIn = mp.wAgentCodeIn
                WHERE (@pVIPPersonRid IS NULL OR @pVIPPersonRid = eb.wVIPPersonRid)
                    AND (@pAgentCodeIn IS NULL OR @pAgentCodeIn = mp.wAgentCodeIn)
                    AND eb.wIsNew <> 'Y'            -- 處理過嘅Record
                    AND eb.wApprovedStatus = 'N'    -- 已批核的禮物不能Update
                    AND eb.wGiftStatus = 'N'        -- 送出去的禮物不能Update
                    AND eb.wStatus = 'A';           -- 有效才需要Update
                ------------------------------------------------update old birthday record（跟進部門）------------------------------
                
                ------------------------------------------------update old birthday record（拒絕接觸）------------------------------
                -- 拒絕接觸，不送禮
                UPDATE eb
                SET eb.wIsRefusedContact = mp.wIsRefusedContact,
                    eb.wGiftType = IIF(mp.wIsRefusedContact = 'Y', '001', eb.wGiftType) -- 不送禮
                FROM dbo.eBirthday eb
                INNER JOIN @vYear y ON y.wYear = eb.wYear
                INNER JOIN dbo.mVIPPerson mp ON mp.RowID = eb.wVIPPersonRid
                WHERE (@pVIPPersonRid IS NULL OR @pVIPPersonRid = eb.wVIPPersonRid)
                    AND (@pAgentCodeIn IS NULL OR @pAgentCodeIn = mp.wAgentCodeIn)
                    AND eb.wApprovedStatus = 'N'    -- 已批核的禮物不能Update
                    AND eb.wGiftStatus = 'N'        -- 送出去的禮物不能Update
                    AND eb.wStatus = 'A';           -- 有效才需要Update

                -- Reset禮物部份資料
                UPDATE bg
                SET bg.wGiftReason = NULL,
                    bg.wGiftDescription = NULL,
                    bg.wBudgetAmt = 0,
                    bg.wCostAmt = 0
                FROM dbo.eBirthday eb
                INNER JOIN @vYear y ON y.wYear = eb.wYear
                INNER JOIN dbo.mVIPPerson mp ON mp.RowID = eb.wVIPPersonRid
                INNER JOIN dbo.eBirthdayGift bg ON bg.wBirthdayRid = eb.RowID
                WHERE (@pVIPPersonRid IS NULL OR @pVIPPersonRid = eb.wVIPPersonRid)
                    AND (@pAgentCodeIn IS NULL OR @pAgentCodeIn = mp.wAgentCodeIn)
                    AND eb.wIsRefusedContact = 'Y'  -- 拒絕接觸
                    AND eb.wGiftType = '001'        -- 不送禮
                    AND eb.wApprovedStatus = 'N'    -- 已批核的禮物不能Update
                    AND eb.wGiftStatus = 'N'        -- 送出去的禮物不能Update
                    AND eb.wStatus = 'A';           -- 有效才需要Update
            
                -- T掉禮物圖片
                UPDATE d
                SET d.wStatus = 'T'
                FROM dbo.eBirthday eb
                INNER JOIN @vYear y ON y.wYear = eb.wYear
                INNER JOIN dbo.mVIPPerson mp ON mp.RowID = eb.wVIPPersonRid
                INNER JOIN dbo.eBirthdayGift bg ON bg.wBirthdayRid = eb.RowID
                INNER JOIN CRM_Doc.dbo.eDocument d ON d.wRefRID = bg.RowID AND d.wRefTable = 'eBirthdayGift' AND d.wStatus = 'A'
                WHERE (@pVIPPersonRid IS NULL OR @pVIPPersonRid = eb.wVIPPersonRid)
                    AND (@pAgentCodeIn IS NULL OR @pAgentCodeIn = mp.wAgentCodeIn)
                    AND eb.wIsRefusedContact = 'Y'  -- 拒絕接觸
                    AND eb.wGiftType = '001'        -- 不送禮
                    AND eb.wApprovedStatus = 'N'    -- 已批核的禮物不能Update
                    AND eb.wGiftStatus = 'N'        -- 送出去的禮物不能Update
                    AND eb.wStatus = 'A';           -- 有效才需要Update
                --------------------------------------------------------------------------------------------------------------------

                IF @sBeginTranCount = 0 AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

            END TRY
            BEGIN CATCH
                DECLARE @sErrorNum INT ,
                        @sCatchErrorMessage NVARCHAR(4000) ,
                        @xstate INT ,
                        @sProcedureName VARCHAR(100) ,
                        @sRtnCodeLog INT ,
                        @sErrMessageLog NVARCHAR(4000);
	        
                SELECT  @sErrorNum = ERROR_NUMBER() ,
                        @sCatchErrorMessage = ERROR_MESSAGE() ,
                        @xstate = XACT_STATE() ,
                        @sProcedureName = OBJECT_NAME(@@PROCID);
			
                IF ISNULL(@sErrCode, 0) = 0
                    SET @sErrCode = 70001;

                IF NULLIF(@sErrMsg, '') IS NULL
                    SET @sErrMsg = CONCAT('(', @sErrorNum, ') ', @sCatchErrorMessage);

                IF @sBeginTranCount = 0
                BEGIN
                    IF @xstate != 0
                        ROLLBACK;

                    -- Write Log
                    EXEC spa.WriteErrorLog 99, 99, @sProcedureName, @sErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
                END
                ELSE
                    THROW @sErrCode, @sErrMsg, 1;  

            END CATCH;
            
            IF OBJECT_ID('temp..#vAgentFollow') IS NOT NULL
                DROP TABLE #vAgentFollow;

            IF OBJECT_ID('tempdb..#vBirthday') IS NOT NULL
                DROP TABLE #vBirthday;
        END;
    END;