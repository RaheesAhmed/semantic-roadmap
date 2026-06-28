CREATE PROCEDURE [spq].[GetCorpEventLst]
  @pAgentCodeIn     NVARCHAR(14),
  @pEventName       NVARCHAR(50),
  @pDateFrom        DATETIME2(7),
  @pDateTo          DATETIME2(7),
  @pEventType       VARCHAR(30),
  @pEventSubType    VARCHAR(30),
  @pStatus          CHAR(1),
  @pLangCd          VARCHAR(30),
  @pPageSize        INT,
  @pPageNum         INT
AS
  BEGIN
    SET NOCOUNT ON;

	IF @@TRANCOUNT = 0
		SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

    SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
    SET @pEventName = IIF(NULLIF(@pEventName, '') IS NULL, NULL, @pEventName + '%');
    SET @pDateFrom = ISNULL(@pDateFrom, '0001-01-01');
    SET @pDateTo = ISNULL(@pDateTo, '9999-12-31'); 
    SET @pEventType = NULLIF(@pEventType, '');
    SET @pEventSubType = NULLIF(@pEventSubType, '');
    SET @pStatus = NULLIF(@pStatus, '');
    SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');
    SET @pPageNum = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);
    SET @pPageSize = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 100);
    
    DECLARE @vCorpEventAgent TABLE(wCorpEventRid BIGINT PRIMARY KEY);
    INSERT INTO @vCorpEventAgent SELECT DISTINCT wCorpEventRid FROM dbo.eCorpEventAgent WHERE wStatus = 'A' AND wAgentCodeIn = @pAgentCodeIn;

    WITH  tResult AS ( 
        SELECT  ce.RowID,
                ce.wName,
                ce.wCategory,
                ce.wSubCategory,
                ce.wIsCharged,
                ce.wStartDt,
                ce.wEndDt,
                ce.wGuestInvited,
                ce.wGuestAttend,
                ce.wCfmGuestAttend,
                ce.wRemark,
                ce.wStatus,
                ce.wCrtDt,
                ce.wUpdDt,
                wCategoryName = lu.wTitle,
                wUpdByCName = IIF(@pLangCd = 'en-GB', usr.wName, usr.wCName),
                wCreatedByCName = IIF (@pLangCd = 'en-GB', crusr.wName, crusr.wCName)
        FROM  dbo.eCorpEvent ce
        LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ce.wUpdBy
        LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ce.wCrtBy
        LEFT JOIN dbo.mLookUp lu ON ce.wCategory = wCode AND lu.wType = 'PROGRAMME_TYPE' AND lu.wLangCd = @pLangCd
        LEFT JOIN @vCorpEventAgent cea ON cea.wCorpEventRid = ce.RowID
        WHERE (@pAgentCodeIn IS NULL OR cea.wCorpEventRid IS NOT NULL)
            AND ( @pEventType IS NULL OR ce.wCategory = @pEventType )
            AND ( @pEventSubType IS NULL OR ce.wSubCategory = @pEventSubType )
            AND ( @pStatus IS NULL OR ce.wStatus = @pStatus )
            AND (  ce.wStartDt BETWEEN @pDateFrom AND @pDateTo
                OR ce.wEndDt BETWEEN @pDateFrom AND @pDateTo
                OR @pDateFrom BETWEEN ce.wStartDt AND ce.wEndDt
                OR @pDateTo BETWEEN ce.wStartDt AND ce.wEndDt
            )
            AND ( @pEventName IS NULL OR ce.wName LIKE @pEventName )
    ),
    tCount AS (
        SELECT wRecordCount = COUNT(1) FROM tResult
    )

    SELECT  tResult.*,
            wRecordCount
    FROM    tResult,
            tCount
    ORDER BY tResult.wCrtDt DESC
    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
    FETCH NEXT @pPageSize ROWS ONLY
	OPTION (RECOMPILE);
  END;