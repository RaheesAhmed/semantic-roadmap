CREATE PROCEDURE [spq].[GetRptCorpEvent]
    @pXMLFilter XML,
    @pLangCd VARCHAR(10) = 'zh-TW'
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @pAgentCodeIn     NVARCHAR(14),
                @pEventName       NVARCHAR(50),
                @pDateFrom        DATETIME2(7),
                @pDateTo          DATETIME2(7),
                @pEventType       VARCHAR(30),
                @pEventSubType    VARCHAR(30),
                @pStatus          CHAR(1);

        IF @pXMLFilter IS NOT NULL
        BEGIN
            SET @pAgentCodeIn   = @pXMLFilter.value('(Filter/@pAgentCodeIn)[1]',    'VARCHAR(14)');
            SET @pEventName     = @pXMLFilter.value('(Filter/@pEventName)[1]',      'NVARCHAR(100)');
            SET @pDateFrom      = @pXMLFilter.value('(Filter/@pDateFrom)[1]',       'DATETIME2(7)');
            SET @pDateTo        = @pXMLFilter.value('(Filter/@pDateTo)[1]',         'DATETIME2(7)');
            SET @pEventType     = @pXMLFilter.value('(Filter/@pEventType)[1]',      'VARCHAR(30)');
            SET @pEventSubType  = @pXMLFilter.value('(Filter/@pEventSubType)[1]',   'VARCHAR(30)');
            SET @pStatus        = @pXMLFilter.value('(Filter/@pStatus)[1]',         'CHAR(1)');
        END

        SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
        SET @pEventName = IIF(NULLIF(@pEventName, '') IS NULL, NULL, @pEventName + '%');
        SET @pDateFrom = ISNULL(@pDateFrom, '0001-01-01');
        SET @pDateTo = ISNULL(@pDateTo, '9999-12-31'); 
        SET @pEventType = NULLIF(@pEventType, '');
        SET @pEventSubType = NULLIF(@pEventSubType, '');
        SET @pStatus = NULLIF(@pStatus, '');
        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

        DECLARE @vLookUp TABLE (wType VARCHAR(30), wCode VARCHAR(30), wTitle NVARCHAR(30), PRIMARY KEY (wType, wCode, wTitle));
        INSERT INTO @vLookUp SELECT DISTINCT wType, wCode, wTitle FROM dbo.mLookUp WHERE wType = 'CORP_EVENT_RESP' AND wLangCd = @pLangCd;
        INSERT INTO @vLookUp SELECT DISTINCT wType, wCode, wTitle FROM dbo.mLookUp WHERE wType = 'COMMON_STATUS' AND wLangCd = @pLangCd;
        INSERT INTO @vLookUp SELECT DISTINCT wType, wCode, wTitle FROM dbo.mLookUp WHERE wType = 'PROGRAMME_TYPE' AND wLangCd = @pLangCd;
        INSERT INTO @vLookUp SELECT DISTINCT wType, wCode, wTitle FROM dbo.mLookUp WHERE wType = 'PROGRAMME_SUB_TYPE' AND wLangCd = @pLangCd;
        
        SELECT cea.wCorpEventRid,
               ce.wStartDt,
               ce.wEndDt,
               ma.wAgentCode_Display,
               wAgentCName = ma.wCName,
               wCorpEventName = ce.wName,
               wCategoryName = mType.wTitle,
               wSubCategoryName = sType.wTitle,
               wResponseName = resp.wTitle,
               cea.wGuestInvited,
               cea.wCfmGuestAttend,
               cea.wGuestAttend,
               wAttendedPercent = IIF(cea.wCfmGuestAttend = 0, 0.0, 1.0 * cea.wGuestAttend / cea.wCfmGuestAttend),
               ce.wIsCharged,
               cea.wRemark,
               wStatusName = st.wTitle,
               cea.wUpdDt,
               wUpdByName = IIF(@pLangCd = 'en-GB', upd.wName, upd.wCName)
        FROM dbo.eCorpEventAgent cea
        INNER JOIN dbo.eCorpEvent ce ON ce.RowID = cea.wCorpEventRid
        INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = cea.wAgentCodeIn
        LEFT JOIN RollsMary.dbo.mUsr upd ON upd.RowID = cea.wUpdBy
        LEFT JOIN @vLookUp mType ON mType.wCode = ce.wCategory AND mType.wType = 'PROGRAMME_TYPE'
        LEFT JOIN @vLookUp sType ON sType.wCode = ce.wSubCategory AND sType.wType = 'PROGRAMME_SUB_TYPE'
        LEFT JOIN @vLookUp resp ON resp.wCode = cea.wResponseType AND resp.wType = 'CORP_EVENT_RESP'
        LEFT JOIN @vLookUp st ON st.wCode = ce.wStatus AND st.wType = 'COMMON_STATUS'
        WHERE cea.wStatus = 'A'
            AND (@pAgentCodeIn IS NULL OR cea.wAgentCodeIn = @pAgentCodeIn)
            AND ( @pEventType IS NULL OR ce.wCategory = @pEventType )
            AND ( @pEventSubType IS NULL OR ce.wSubCategory = @pEventSubType )
            AND ( @pStatus IS NULL OR ce.wStatus = @pStatus )
            AND (  ce.wStartDt BETWEEN @pDateFrom AND @pDateTo
                OR ce.wEndDt BETWEEN @pDateFrom AND @pDateTo
                OR @pDateFrom BETWEEN ce.wStartDt AND ce.wEndDt
                OR @pDateTo BETWEEN ce.wStartDt AND ce.wEndDt
            )
            AND ( @pEventName IS NULL OR ce.wName LIKE @pEventName )
        OPTION(RECOMPILE);
    END