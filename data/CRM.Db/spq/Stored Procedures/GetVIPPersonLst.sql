
CREATE PROCEDURE [spq].[GetVIPPersonLst]
    @pFilterXML XML,
    @pLangCd VARCHAR(10) = 'zh-TW',
    @pPageNum INT = 1,
    @pPageSize INT = 100     
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	
        DECLARE @pAgentCode         NVARCHAR(50),
                @pPersonName        NVARCHAR(50),
                @pPersonIdentity    VARCHAR(30),
                @pAuthIdentity      VARCHAR(30),
                @pIsPresentGift     CHAR(1),
                @pCalendarType      CHAR(5),
                @pBirthdayMonth     INT,
                @pVIPPersonStatus   CHAR(1),
                @pDeptFollow        VARCHAR(30);
        
        DECLARE @sMDFollow          CHAR(1), -- Get MD星級客戶權限
                @sVIPFollow         CHAR(1), -- Get VIP客戶權限（MD星級客戶以外的身份都是VIP客戶）
                @sNow               DATETIME2(7) = GETDATE();
        
        -- MD/VIP跟進權限
        DECLARE @vFollowDept TABLE(wDeptCd VARCHAR(30) PRIMARY KEY);

        IF @pFilterXML IS NOT NULL
        BEGIN
            SET @pAgentCode       = @pFilterXML.value('(Filter/@pAgentCode)[1]',        'NVARCHAR(100)');
            SET @pPersonName      = @pFilterXML.value('(Filter/@pPersonName)[1]',       'NVARCHAR(100)');
            SET @pPersonIdentity  = @pFilterXML.value('(Filter/@pPersonIdentity)[1]',   'VARCHAR(30)');
            SET @pAuthIdentity    = @pFilterXML.value('(Filter/@pAuthIdentity)[1]',     'VARCHAR(30)');
            SET @pIsPresentGift   = @pFilterXML.value('(Filter/@pIsPresentGift)[1]',    'CHAR(1)');
            SET @pCalendarType    = @pFilterXML.value('(Filter/@pCalendarType)[1]',     'CHAR(5)');
            SET @pBirthdayMonth   = @pFilterXML.value('(Filter/@pBirthdayMonth)[1]',    'INT');
            SET @pVIPPersonStatus = @pFilterXML.value('(Filter/@pVIPPersonStatus)[1]',  'CHAR(1)');
            SET @pDeptFollow      = @pFilterXML.value('(Filter/@pDeptFollow)[1]',       'VARCHAR(30)');
        END;

        SET @pAgentCode       = NULLIF(@pAgentCode, '');
        SET @pPersonName      = IIF(NULLIF(@pPersonName, '') IS NULL, NULL, CONCAT('%', LTRIM(RTRIM(@pPersonName)) ,'%'));
        SET @pPersonIdentity  = NULLIF(@pPersonIdentity, '');
        SET @pAuthIdentity    = NULLIF(@pAuthIdentity, '');
        SET @pIsPresentGift   = NULLIF(@pIsPresentGift, '');
        SET @pCalendarType    = NULLIF(@pCalendarType, '');
        SET @pVIPPersonStatus = NULLIF(@pVIPPersonStatus, '');
        SET @pDeptFollow      = NULLIF(@pDeptFollow, '');
        SET @pLangCd          = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');
        SET @pPageNum         = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);
        SET @pPageSize        = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 100);

        IF @pDeptFollow IS NOT NULL
        BEGIN
            DECLARE @sDeptXML XML;
            -- SET @pDeptFollow = REPLACE(REPLACE(@pDeptFollow, 'VIP', 'HOUSEKEEPER'), 'MD', 'DEVELOP');
            SET @sDeptXML = CONVERT(XML,'<DataSet><Record>' + REPLACE(@pDeptFollow, ',', '</Record><Record>') + '</Record></DataSet>');

            INSERT INTO @vFollowDept(wDeptCd)
            SELECT DISTINCT T.tmp.value('.', 'VARCHAR(30)')
            FROM @sDeptXML.nodes('DataSet/Record') T(tmp);
        END;

        SET @sMDFollow  = ISNULL((SELECT 'Y' FROM @vFollowDept WHERE wDeptCd = 'MD'),  'N');
        SET @sVIPFollow = ISNULL((SELECT 'Y' FROM @vFollowDept WHERE wDeptCd = 'VIP'), 'N');
        
        ;WITH tResult AS (
            SELECT
                mp.RowID, 
                ma.wAgentCodeIn,
                ma.wAgentCode_Display, 
                wAgentName = IIF(@pLangCd = 'zh-TW', ma.wCName, ma.wEName),
                mp.wPersonName, 
                mp.wPersonIdentity, 
                wAgentAuthIdentity = IIF(mp.wIsAuthorizer = 'Y', IIF(mu.wType = 'AGENT', 'RM_AGENT', mu.wAuthIdentity), NULL),
                mp.wGender, 
                mp.wAuthorizerAgentCodeIn, 
                wAuthorizerName = IIF(@pLangCd = 'zh-TW', mu.wCName, mu.wEName),
                mp.wAuthorizerIdentity, 
                mp.wRelationship, 
                mp.wOtherRelationship,
                mp.wCalendarType, 
                mp.wBirthDate, 
                mp.wYear, 
                mp.wMonth,
                mp.wDay, 
                mp.wIsLeapMonth,
                mp.wContactWay, 
                mp.wTelNumber, 
                mp.wWhatsappNumber, 
                mp.wWeChatNumber, 
                mp.wWeChatName, 
                mp.wIsWeChatVerify, 
                mp.wIsPresentGift, 
                mp.wIsAuthorizer,
                mp.wBudgetRatio, 
                mp.wStatusRemark,
                mp.wVIPPersonStatus,
                mp.wUpdDt,
                mp.wCrtDt
            FROM dbo.mVIPPerson mp
            INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = mp.wAgentCodeIn
            LEFT JOIN RollsMary.dbo.mAgent mu ON mu.wAgentCodeIn = mp.wAuthorizerAgentCodeIn
            WHERE (@pVIPPersonStatus IS NULL OR @pVIPPersonStatus = mp.wVIPPersonStatus)
                AND (@pAgentCode IS NULL 
                  OR @pAgentCode = ma.wAgentCode 
                  OR @pAgentCode = ma.wAgentCode_Old 
                  OR @pAgentCode = ma.wAgentCode_Src 
                  OR @pAgentCode = ma.wAgentCode_Display)
                AND (@pPersonName IS NULL OR mp.wPersonName LIKE @pPersonName)
                AND (@pPersonIdentity IS NULL OR @pPersonIdentity = mp.wPersonIdentity)
                AND (@pAuthIdentity IS NULL OR (mp.wIsAuthorizer = 'Y' AND @pAuthIdentity = IIF(mu.wType = 'AGENT', 'RM_AGENT', mu.wAuthIdentity)))
                AND (@pIsPresentGift IS NULL OR @pIsPresentGift = mp.wIsPresentGift)
                AND (@pCalendarType IS NULL OR @pCalendarType = mp.wCalendarType)
                AND (@pBirthdayMonth IS NULL OR @pBirthdayMonth = mp.wMonth)
                AND ((mp.wPersonIdentity IN ('MD_CLIENT', 'MD_AGENT') AND @sMDFollow = 'Y') OR (mp.wPersonIdentity NOT IN ('MD_CLIENT', 'MD_AGENT') AND @sVIPFollow = 'Y'))
                AND mp.wStatus = 'A'
        ),
        tCount AS (
            SELECT wRecordCount = COUNT(1) FROM tResult
        )
            
        SELECT  r.* ,
                c.wRecordCount
        FROM    tResult r ,
                tCount c
        ORDER BY r.wCrtDt DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	    FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );
    END;