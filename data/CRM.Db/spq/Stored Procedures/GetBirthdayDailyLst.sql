CREATE PROC [spq].[GetBirthdayDailyLst]
    @pXMLFilter XML,
    @pLangCd VARCHAR(10)
AS
    BEGIN
        DECLARE @pCalendarType      CHAR(5), -- Solar/Lunar
                @pSolarYear         INT,
                @pSolarMonth        INT,
                @pSolarDay          INT,
                @pLunarYear         INT,
                @pLunarMonth        INT,
                @pLunarDay          INT,
                @pIsLeapMonth       CHAR(1), -- Y /N
                @pRegion            VARCHAR(30),
                @pApprovedStatus    VARCHAR(5),
                @pGiftStatus        VARCHAR(5),
                @pDeptFollow        VARCHAR(30),
                @sNow               DATETIME2(7) = GETDATE();
        
        -- MD/VIP跟進權限
        DECLARE @vFollowDept TABLE(wDeptCd VARCHAR(30) PRIMARY KEY);

        IF @pXMLFilter IS NOT NULL
        BEGIN
            SET @pCalendarType      = @pXMLFilter.value('(Filter/@pCalendarType)[1]',   'CHAR(5)');
            SET @pSolarYear         = @pXMLFilter.value('(Filter/@pSolarYear)[1]',      'INT');
            SET @pSolarMonth        = @pXMLFilter.value('(Filter/@pSolarMonth)[1]',     'INT');
            SET @pSolarDay          = @pXMLFilter.value('(Filter/@pSolarDay)[1]',       'INT');
            SET @pLunarYear         = @pXMLFilter.value('(Filter/@pLunarYear)[1]',      'INT');
            SET @pLunarMonth        = @pXMLFilter.value('(Filter/@pLunarMonth)[1]',     'INT');
            SET @pLunarDay          = @pXMLFilter.value('(Filter/@pLunarDay)[1]',       'INT');
            SET @pIsLeapMonth       = @pXMLFilter.value('(Filter/@pIsLeapMonth)[1]',    'CHAR(1)');
            SET @pRegion            = @pXMLFilter.value('(Filter/@pRegion)[1]',         'VARCHAR(30)');
            SET @pApprovedStatus    = @pXMLFilter.value('(Filter/@pApprovedStatus)[1]', 'VARCHAR(5)');
            SET @pGiftStatus        = @pXMLFilter.value('(Filter/@pGiftStatus)[1]',     'VARCHAR(5)');
            SET @pDeptFollow        = @pXMLFilter.value('(Filter/@pDeptFollow)[1]',     'VARCHAR(30)');

            -- SET @pCalendarType      = NULLIF(@pCalendarType, '');
            SET @pCalendarType      = NULL;
            SET @pRegion            = NULLIF(@pRegion, '');
            SET @pApprovedStatus    = NULLIF(@pApprovedStatus, '');
            SET @pGiftStatus        = NULLIF(@pGiftStatus, '');
            SET @pDeptFollow        = NULLIF(@pDeptFollow, '');

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
        
        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

        ;WITH tVIPPerson AS (
            SELECT
                mp.RowID, 
                ma.wAgentCodeIn,
                ma.wAgentCode_Display, 
                wAgentName = IIF(@pLangCd = 'zh-TW', ma.wCName, ma.wEName),
                wAgentIdentity=(SELECT TOP(1) wAgentIdentity FROM RollsMary.dbo.fnGetAgentIdentity(ma.wAgentCodeIn)),
                mp.wPersonName,
                mp.wCalendarType
            FROM dbo.mVIPPerson mp
            INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = mp.wAgentCodeIn
            WHERE (@pCalendarType IS NULL AND ((mp.wCalendarType = 'Solar' AND mp.wMonth = @pSolarMonth AND mp.wDay = @pSolarDay) 
                                            OR (mp.wCalendarType = 'Lunar' AND mp.wMonth = @pLunarMonth AND mp.wDay = @pLunarDay)))
               OR (@pCalendarType = 'Solar' AND mp.wCalendarType = 'Solar' AND mp.wMonth = @pSolarMonth AND mp.wDay = @pSolarDay)
               OR (@pCalendarType = 'Lunar' AND mp.wCalendarType = 'Lunar' AND mp.wMonth = @pLunarMonth AND mp.wDay = @pLunarDay)
        ),
        tAgentFollow AS (
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
        )

        SELECT
            eb.RowID,
            eb.wVIPPersonRid,
            mp.wAgentCodeIn,
            mp.wAgentCode_Display, 
            mp.wAgentName,
            mp.wAgentIdentity,
            mp.wPersonName,
            eb.wGiftType,
            eb.wGiftStatus,
            eb.wFollowDeptRid,
            eb.wFollowTeamRid,
            wFollowTeamName = mt.wName,
            eb.wFollowUsrRid,
            wFollowUsrName = IIF(@pLangCd = 'zh-TW', ml.wCName, ml.wName)
        FROM dbo.eBirthday eb
        INNER JOIN tVIPPerson mp ON mp.RowID = eb.wVIPPersonRid
        LEFT JOIN RollsMary.dbo.mTeam mt ON mt.RowId = eb.wFollowTeamRid
        LEFT JOIN RollsMary.dbo.mUsr ml ON ml.RowID = eb.wFollowUsrRid
        LEFT JOIN RollsMary.dbo.mUsr mu ON mu.RowID = eb.wUpdBy
        LEFT JOIN RollsMary.dbo.mDepartment md ON md.RowID = eb.wFollowDeptRid
        LEFT JOIN @vFollowDept fd ON fd.wDeptCd = md.wCode AND eb.wIsNew <> 'Y'
        LEFT JOIN tAgentFollow af ON af.wAgentCodeIn = mp.wAgentCodeIn AND eb.wIsNew = 'Y'
        LEFT JOIN RollsMary.dbo.mDepartment af_md ON af_md.RowID = af.wDeptRid
        LEFT JOIN @vFollowDept af_fd ON af_fd.wDeptCd = md.wCode
        WHERE eb.wStatus = 'A'
            AND ((@pCalendarType IS NULL AND ((mp.wCalendarType = 'Solar' AND eb.wYear = @pSolarYear) 
                                           OR (mp.wCalendarType = 'Lunar' AND eb.wYear = @pLunarYear)))
              OR (@pCalendarType = 'Solar' AND mp.wCalendarType = 'Solar' AND eb.wYear = @pSolarYear)
              OR (@pCalendarType = 'Lunar' AND mp.wCalendarType = 'Lunar' AND eb.wYear = @pLunarYear))
            AND ((mp.wCalendarType = 'Solar' AND eb.wIsLeapMonth = 'N')
              OR (mp.wCalendarType = 'Lunar' AND eb.wIsLeapMonth = @pIsLeapMonth))
            AND ((eb.wIsNew <> 'Y' AND fd.wDeptCd IS NOT NULL) OR (eb.wIsNew = 'Y' AND af_fd.wDeptCd IS NOT NULL)) -- 如果記錄已經修改過，記錄嘅跟進部門要有Select權限；如果記錄冇修改過，記錄嘅跟進部門取當前跟進部門，且要有Select權限
            AND (@pRegion IS NULL OR @pRegion = eb.wRegion)
            AND (@pApprovedStatus IS NULL OR @pApprovedStatus = eb.wApprovedStatus)
            AND (@pGiftStatus IS NULL OR @pGiftStatus = eb.wGiftStatus)
        OPTION(RECOMPILE);
    END;