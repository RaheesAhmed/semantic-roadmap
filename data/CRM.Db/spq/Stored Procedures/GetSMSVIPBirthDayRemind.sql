CREATE PROC [spq].[GetSMSVIPBirthDayRemind]
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
                @sNow               DATETIME2(7) = GETDATE();

        ------------------------------------戶口身份------------------------------------------
        DECLARE @sAgentIdentityLookup TABLE(
            wAgentIdentity VARCHAR(20),
            wAgentIdentityName NVARCHAR(50),
            wAgentColor CHAR(8)
        );

        INSERT INTO @sAgentIdentityLookup(wAgentIdentity, wAgentIdentityName, wAgentColor)
        VALUES ('SHARE',                N'股東',       '#b9a46d'),
               ('SEC_SHARE',            N'股東',       '#b9a46d'),
               ('AGENT',                N'代理',       '#55b85d'),
               ('CREDIT_AGENT',         N'代理',       '#55b85d'),
               ('GAMBLERS',             N'玩家',       '#f460b5'),
               ('CREDIT_GAMBLERS',      N'玩家',       '#f460b5'),
               ('SEC_AGENT',            N'代理',       '#39d1db'),
               ('SEC_CREDIT_AGENT',     N'代理',       '#39d1db'),
               ('SEC_GAMBLERS',         N'玩家',       '#39d1db'),
               ('SEC_CREDIT_GAMBLERS',  N'玩家',       '#39d1db');
        -----------------------------------END 戶口身份----------------------------------------
	    ------------------------------------戶口級別--------------------------------------------
	    DECLARE @vAccountType AS TABLE (
	    	wCode VARCHAR(10) PRIMARY KEY,
	    	wTitle NVARCHAR(10)
	    );
	    INSERT INTO  @vAccountType(wCode, wTitle)
	    SELECT wCode, wTitle FROM dbo.fnGetAgentAccountType('zh-TW');
	    ------------------------------------END 戶口級別--------------------------------------------

        IF @pXMLFilter IS NOT NULL
        BEGIN
            --SET @pCalendarType      = @pXMLFilter.value('(Filter/@pCalendarType)[1]',   'CHAR(5)');
            SET @pSolarYear         = @pXMLFilter.value('(Filter/@pSolarYear)[1]',      'INT');
            SET @pSolarMonth        = @pXMLFilter.value('(Filter/@pSolarMonth)[1]',     'INT');
            SET @pSolarDay          = @pXMLFilter.value('(Filter/@pSolarDay)[1]',       'INT');
            SET @pLunarYear         = @pXMLFilter.value('(Filter/@pLunarYear)[1]',      'INT');
            SET @pLunarMonth        = @pXMLFilter.value('(Filter/@pLunarMonth)[1]',     'INT');
            SET @pLunarDay          = @pXMLFilter.value('(Filter/@pLunarDay)[1]',       'INT');
            SET @pIsLeapMonth       = @pXMLFilter.value('(Filter/@pIsLeapMonth)[1]',    'CHAR(1)');
            SET @pRegion            = @pXMLFilter.value('(Filter/@pRegion)[1]',         'VARCHAR(30)');
            SET @pApprovedStatus    = @pXMLFilter.value('(Filter/@pApprovedStatus)[1]', 'VARCHAR(5)');
            SET @pGiftStatus        = @pXMLFilter.value('(Filter/@pGiftStatus)[1]',      'VARCHAR(5)');

            SET @pCalendarType      = NULLIF(@pCalendarType, '');
            SET @pRegion            = NULLIF(@pRegion, '');
            SET @pApprovedStatus    = NULLIF(@pApprovedStatus, '');
            SET @pGiftStatus        = NULLIF(@pGiftStatus, '');
        END;

        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

        ;WITH tVIPPerson AS (
            SELECT
                mp.RowID, 
                ma.wAgentCodeIn,
                ma.wNationality,
                ma.wAccountType,
                ma.wAgentCode_Display, 
                wAgentName = IIF(@pLangCd = 'zh-TW', ma.wCName, ma.wEName),
                wAgentIdentity=(SELECT TOP(1) wAgentIdentity FROM RollsMary.dbo.fnGetAgentIdentity(ma.wAgentCodeIn)),
                mp.wPersonName,
                mp.wCalendarType,
                mp.wYear ,
                mp.wMonth ,
                mp.wDay ,
                mp.wIsLeapMonth ,
                wGender = CASE WHEN mp.wGender = 'M' THEN N'先生' ELSE N'小姐' END ,
                wCalendarTypeName = CASE WHEN mp.wCalendarType = 'Solar' THEN N'新曆' ELSE N'農曆' END ,
                mp.wPersonIdentity ,
                mp.wIsAuthorizer 
            FROM dbo.mVIPPerson mp
            INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = mp.wAgentCodeIn
            WHERE ((@pCalendarType IS NULL AND ((mp.wCalendarType = 'Solar' AND mp.wMonth = @pSolarMonth AND mp.wDay = @pSolarDay) 
                                              OR (mp.wCalendarType = 'Lunar' AND mp.wMonth = @pLunarMonth AND mp.wDay = @pLunarDay)
                                                )
                   )
                OR (@pCalendarType = 'Solar' AND mp.wCalendarType = 'Solar' AND mp.wMonth = @pSolarMonth AND mp.wDay = @pSolarDay)
                OR (@pCalendarType = 'Lunar' AND mp.wCalendarType = 'Lunar' AND mp.wMonth = @pLunarMonth AND mp.wDay = @pLunarDay)
                )
                AND (mp.wPersonIdentity = 'VIP_AGENT' OR mp.wPersonIdentity = 'VIP_BOSS' OR  mp.wPersonIdentity = 'VIP_OWNER' --VIP生日
                  OR mp.wPersonIdentity = 'MD_AGENT' OR mp.wPersonIdentity = 'MD_CLIENT') --MD生日
            )

        SELECT
            mp.wYear ,
            mp.wMonth ,
            mp.wDay ,
            wBirthday = CONCAT(mp.wMonth,N'月',mp.wDay,N'日'),
            mp.wIsLeapMonth ,
            lu.wAgentIdentityName,--戶口身份
            wAccountTypeName = ai.wTitle,--戶口級別
            mp.wAgentCode_Display ,
            wPersonIdentityName = CASE mp.wPersonIdentity WHEN 'VIP_AGENT' THEN N'戶主'
                                                          WHEN 'VIP_BOSS'  THEN N'老闆'
                                                          WHEN 'VIP_OWNER' THEN N'戶主'
                                                          WHEN 'MD_CLIENT' THEN N'戶主'
                                                          WHEN 'MD_AGENT'  THEN N'戶主'
                                                          ELSE '' END ,
            mp.wPersonName ,
            wGender ,
            wCalendarTypeName ,
            ml.wTitle AS wSourceName ,
            g.wGiftDescription ,
            g.wTelNumber ,
            g.wWeChatNumber ,
            g.wWeChatName ,
            wGiftStatus = CASE WHEN eb.wGiftStatus = 'N' THEN N'未送出' ELSE N'已送出' END ,
            --g.wSource ,
            --eb.wGiftType ,
            --eb.wApprovedStatus ,
            mp.wPersonIdentity ,
            mp.wIsAuthorizer ,
            wAddress = CASE WHEN mp.wNationality = 'CHN' THEN CONCAT(mc.wCName,ISNULL(province.wCName,'') + ISNULL(province.wCSuffix,''))
                       ELSE ISNULL(mc.wCName,'') END,
            mp.wAgentCodeIn,
            mp.wCalendarType,
            eb.RowID
        FROM dbo.eBirthday eb
        INNER JOIN tVIPPerson mp ON mp.RowID = eb.wVIPPersonRid
        INNER JOIN dbo.eBirthdayGift g ON eb.RowID = g.wBirthdayRid
        LEFT JOIN dbo.mLookUp ml ON ml.wCode = g.wSource AND ml.wLangCd = @pLangCd AND ml.wType = 'VIP_BIRTHDAY_SOURCE'
        LEFT JOIN @sAgentIdentityLookup AS lu ON lu.wAgentIdentity = mp.wAgentIdentity
        LEFT JOIN @vAccountType ai ON ai.wCode = mp.wAccountType
        LEFT JOIN RollsMary.dbo.mAgentExt mae ON mp.wAgentCodeIn = mae.wAgentCodeIn
        LEFT JOIN RollsMary.dbo.mCountry mc ON mc.wCountryCode = mp.wNationality
        LEFT JOIN RollsMary.dbo.mCountryDtl province ON province.wCountryDtlCode = mae.wProvinceCode
        WHERE eb.wStatus = 'A'
            AND (
                (@pCalendarType IS NULL AND ((mp.wCalendarType = 'Solar' AND eb.wYear = @pSolarYear) 
                                            OR (mp.wCalendarType = 'Lunar' AND eb.wYear = @pLunarYear)
                                            )
                )
             OR (@pCalendarType = 'Solar' AND mp.wCalendarType = 'Solar' AND eb.wYear = @pSolarYear)
             OR (@pCalendarType = 'Lunar' AND mp.wCalendarType = 'Lunar' AND eb.wYear = @pLunarYear)
            )
            AND (
                (mp.wCalendarType = 'Solar' AND eb.wIsLeapMonth = 'N')
             OR (mp.wCalendarType = 'Lunar' AND eb.wIsLeapMonth = @pIsLeapMonth)
            )
            AND eb.wApprovedStatus = 'Y' AND eb.wGiftType = '003' --1.批核狀態：已批核 2.送禮狀態：送禮物  （送禮券、不送禮都唔發SMS）

    END;