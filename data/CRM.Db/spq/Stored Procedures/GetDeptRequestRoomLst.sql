
CREATE PROCEDURE [spq].[GetDeptRequestRoomLst]
    @pXMLFilter XML,
    @pSort      VARCHAR(200),
    @pLangCd    VARCHAR(10) = 'zh-TW',
    @pPageSize  INT = 15,
    @pPageNum   INT = 1 
AS
BEGIN
    SET NOCOUNT ON;

    -----------------------------dbml--------------------------------
    --DECLARE @vResult TABLE(
    --    RowID                       BIGINT NOT NULL,
    --    wRequestNo                  VARCHAR(30) NOT NULL,
    --    wRequestDepartment          VARCHAR(30) NOT NULL,
    --    wAgentCodeIn                VARCHAR(14) NOT NULL,
    --    wAgentCode_Display          NVARCHAR(30) NOT NULL,
    --    wAgentCode_Name             NVARCHAR(50) NOT NULL,
    --    wAgentIdentity              VARCHAR(30) NOT NULL,
    --    wAgentLevel                 VARCHAR(30) NOT NULL,
    --    wAgentPortrait              VARBINARY(MAX),
    --    wImportantLevel             INT NOT NULL,
    --    wTotalRollingAmt            NUMERIC(18, 4) NOT NULL,
    --    wTotalBookedRoomQty         INT NOT NULL,
    --    wEventRid                   BIGINT NOT NULL,
    --    wHotelRid                   BIGINT NOT NULL,
    --    wRoomRid                    BIGINT NOT NULL,
    --    wBigBedQty                  INT NOT NULL,
    --    wTwinBedQty                 INT NOT NULL,
    --    wSuiteRoom1Qty              INT NOT NULL,
    --    wSuiteRoom2Qty              INT NOT NULL,
    --    wSuiteRoom3Qty              INT NOT NULL,
    --    wDayOfStay                  INT NOT NULL,
    --    wStartDate                  DATE NOT NULL,
    --    wEndDate                    DATE NOT NULL,
    --    wRemark                     NVARCHAR(4000),
    --    wIsNewReqRoom               CHAR(1) NOT NULL,
    --    wIsCancel                   CHAR(1) NOT NULL,
    --    wFollowedDeptCode           VARCHAR(20) NOT NULL,
    --    wFollowedStaffRid           BIGINT NOT NULL,
    --    wFollowedStaffTel           VARCHAR(20),
    --    wFollowedStaffTelExt        VARCHAR(10),
    --    wFollowedStaffTelCountryCd  VARCHAR(10),
    --    wApplyDepartment            NVARCHAR(20) NOT NULL,
    --    wApplyStaffRid              BIGINT NOT NULL,
    --    wApplyStaffTel              VARCHAR(20),
    --    wApplyStaffTelExt           VARCHAR(10),
    --    wApplyStaffTelCountryCd     VARCHAR(10),
    --    wRequestRoomQty             INT NOT NULL,
    --    wUnCompletedRoomQty         INT NOT NULL,
    --    wCancelledRoomQty           INT NOT NULL,
    --    wCompletedNotReqRoomQty     INT NOT NULL,
    --    wCompletedReqRoomQty        INT NOT NULL,
    --    wCompletedRoomQty           INT NOT NULL,
    --    wIsBookingExpired           CHAR(1) NOT NULL,
    --    wReqStatus                  VARCHAR(20) NOT NULL,
    --    wStatus                     VARCHAR(20) NOT NULL,
    --    wCrtDt                      DATETIME2(2) NOT NULL,
    --    wCrtBy                      BIGINT NOT NULL,
    --    wCrtByCName                 NVARCHAR(50) NOT NULL,
    --    wCrtByEName                 NVARCHAR(100) NOT NULL,
    --    wUpdDt                      DATETIME2(7) NOT NULL,
    --    wUpdBy                      BIGINT NOT NULL,
    --    wUpdByCName                 NVARCHAR(50) NOT NULL,
    --    wUpdByEName                 NVARCHAR(100) NOT NULL,
    --    wGUID                       UNIQUEIDENTIFIER NOT NULL,
    --    wIsExtRoom                  CHAR(1) NOT NULL,
    --    wRecordCount                INT NOT NULL
    --);

    --SELECT * FROM @vResult;
    ---------------------------END dbml------------------------------

    DECLARE @sNow DATE = CAST(dbo.fnUTC8Now() AS DATE);
    DECLARE @sAgentPortrait VARBINARY(MAX);

    SET @pLangCd    = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');
    SET @pSort      = ISNULL(NULLIF(@pSort, ''), '||');
    SET @pPageSize  = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 15);
    SET @pPageNum   = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);

    DECLARE @pDeptCd            VARCHAR(30),
            @pAgentCodeIn       VARCHAR(14),
            @pEventRid          BIGINT,
            @pRequestNo         VARCHAR(30),
            @pRequestStatus     VARCHAR(30),
            @pCheckInDate       DATE,
            @pCheckOutDate      DATE,
            @pRegionCd          VARCHAR(30),
            @pHotelRid          BIGINT,
            @pHotelRoomRid      BIGINT,
            @pFollowDeptCd      VARCHAR(30),
            @pFollowStaffRid    BIGINT,
            @pApplyStaffRid      BIGINT,
            @pDeptStatus        VARCHAR(20),
            @pHotelRefNo        VARCHAR(30),
            @pDeptReqRoomRid    BIGINT,
            @pIsNewOnly         CHAR(1),
            @pIsHightlyAgent    CHAR(1),
            @pIsUnFollowed      CHAR(1),
            @pIsUnCompleted     CHAR(1),
            @pIsUnGetKey        CHAR(1),
            @pImportantLevel    INT;

    SELECT  @pDeptCd            = T.tmp.value('@pDeptCd',             'VARCHAR(30)'),
            @pAgentCodeIn       = T.tmp.value('@pAgentCodeIn',        'VARCHAR(14)'),
            @pEventRid          = T.tmp.value('@pEventRid',           'BIGINT'),
            @pRequestNo         = T.tmp.value('@pRequestNo',          'VARCHAR(30)'),
            @pRequestStatus     = T.tmp.value('@pRequestStatus',      'VARCHAR(30)'),
            @pCheckInDate       = NULLIF(T.tmp.value('@pCheckInDate', 'VARCHAR(20)'), ''),
            @pCheckOutDate      = NULLIF(T.tmp.value('@pCheckOutDate','VARCHAR(20)'), ''),
            @pRegionCd          = T.tmp.value('@pRegionCd',           'VARCHAR(30)'),
            @pHotelRid          = T.tmp.value('@pHotelRid',           'BIGINT'),
            @pHotelRoomRid      = T.tmp.value('@pHotelRoomRid',       'BIGINT'),
            @pFollowDeptCd      = T.tmp.value('@pFollowDeptCd',       'VARCHAR(30)'),
            @pFollowStaffRid    = T.tmp.value('@pFollowStaffRid',     'BIGINT'),
            @pApplyStaffRid     = T.tmp.value('@pApplyStaffRid',      'BIGINT'),
            @pDeptStatus        = T.tmp.value('@pDeptStatus',         'VARCHAR(20)'),
            @pHotelRefNo        = T.tmp.value('@pHotelRefNo',         'VARCHAR(30)'),
            @pDeptReqRoomRid    = T.tmp.value('@pDeptReqRoomRid',     'BIGINT'),
            @pImportantLevel    = T.tmp.value('@pImportantLevel',     'INT'),
            @pIsNewOnly         = T.tmp.value('@pIsNewOnly',          'CHAR(1)'),
            @pIsHightlyAgent    = T.tmp.value('@pIsHightlyAgent',     'CHAR(1)'),
            @pIsUnFollowed      = T.tmp.value('@pIsUnFollowed',       'CHAR(1)'),
            @pIsUnCompleted     = T.tmp.value('@pIsUnCompleted',      'CHAR(1)'),
            @pIsUnGetKey        = T.tmp.value('@pIsUnGetKey',         'CHAR(1)')
    FROM @pXMLFilter.nodes('Filter') T(tmp);

    SET @pDeptCd            = NULLIF(@pDeptCd, '');
    SET @pAgentCodeIn       = NULLIF(@pAgentCodeIn, '');
    SET @pEventRid          = NULLIF(@pEventRid, 0);
    SET @pRequestNo         = NULLIF(@pRequestNo,'');
    SET @pRequestStatus     = NULLIF(@pRequestStatus, '');
    SET @pRegionCd          = NULLIF(@pRegionCd, '');
    SET @pHotelRid          = NULLIF(@pHotelRid, 0);
    SET @pHotelRoomRid      = NULLIF(@pHotelRoomRid, 0);
    SET @pFollowDeptCd      = NULLIF(@pFollowDeptCd, '');
    SET @pFollowStaffRid    = NULLIF(@pFollowStaffRid, 0);
    SET @pApplyStaffRid     = NULLIF(@pApplyStaffRid, 0);
    SET @pDeptStatus        = NULLIF(@pDeptStatus, '');
    SET @pHotelRefNo        = NULLIF(@pHotelRefNo, '');
    SET @pDeptReqRoomRid    = NULLIF(@pDeptReqRoomRid, 0);
    SET @pImportantLevel    = NULLIF(@pImportantLevel, 0);
    SET @pIsNewOnly         = IIF(@pIsNewOnly NOT IN ('Y', 'N'), NULL, @pIsNewOnly);
    SET @pIsHightlyAgent    = IIF(@pIsHightlyAgent NOT IN ('Y', 'N'), NULL, @pIsHightlyAgent);
    SET @pIsUnFollowed      = IIF(@pIsUnFollowed = 'Y', 'Y', NULL);
    SET @pIsUnCompleted     = IIF(@pIsUnCompleted = 'Y', 'Y', NULL);
    SET @pIsUnGetKey        = IIF(@pIsUnGetKey = 'Y', 'Y', NULL);
   
   CREATE TABLE #vDeptReqRoom ( 
        RowID               BIGINT PRIMARY KEY(RowID), 
        wAgentCodeIn        VARCHAR(14) NOT NULL, 
        wAccountType        VARCHAR(10) NOT NULL,
        wAgentLevel         VARCHAR(30),
        wImportantLevel     INT DEFAULT(0),
        wTotalBookedRoomQty INT DEFAULT(0), 
        wTotalRollingAmt    NUMERIC(18, 4) DEFAULT(0)
    );

    -- 2019-05-17：OP#28681，日期、酒店以細單作為搜索，不要大單
    -----------------------------------------------------------------------------
    INSERT INTO #vDeptReqRoom( RowID, wAgentCodeIn, wAccountType )
    SELECT  req.RowID, req.wAgentCodeIn, ISNULL(ma.wAccountType, '')
    FROM dbo.eDeptReqRoom AS req WITH(NOLOCK)
    LEFT JOIN dbo.eDeptRespRoom AS rep WITH(NOLOCK) ON rep.wDeptReqRoomRid = req.RowID AND rep.wStatus = 'A'
    LEFT JOIN dbo.eBooking AS eb WITH(NOLOCK) ON eb.RowID = rep.wBookingRid
    LEFT JOIN dbo.mHotel AS hr WITH(NOLOCK) ON hr.RowID = rep.wHotelRid
    LEFT JOIN RollsMary.dbo.mAgent AS ma WITH(NOLOCK) ON ma.wAgentCodeIn  = req.wAgentCodeIn
    LEFT JOIN RollsMary.dbo.mAgentIdentity AS mi WITH(NOLOCK) ON mi.wAgentCodeIn = ma.wAgentCodeIn AND mi.wValue = 'Y' AND (mi.wType = 'STAR' OR mi.wType = 'HIGHLY_VALUED')
    WHERE req.wStatus = 'A'
        AND (@pAgentCodeIn IS NULL OR ma.wAgentCode = @pAgentCodeIn Or ma.wAgentCode_Old = @pAgentCodeIn Or ma.wAgentCode_Src = @pAgentCodeIn Or ma.wAgentCode_Display = @pAgentCodeIn)
        AND ((@pDeptCd IS NULL AND (@pRequestNo IS NOT NULL OR @pDeptReqRoomRid IS NOT NULL)) OR @pDeptCd = req.wRequestDepartment) -- 部門為空時， 預訂編號不允許為空（精確單號查詢）
        AND (@pRequestNo IS NULL OR @pRequestNo = req.wRequestNo)
        AND (@pDeptReqRoomRid IS NULL OR @pDeptReqRoomRid = req.RowID)
        AND (@pHotelRefNo IS NULL OR @pHotelRefNo = eb.wRefNo)
        AND (@pRequestStatus IS NULL OR @pRequestStatus = req.wReqStatus OR @pRequestStatus = rep.wRepStatus)
        AND (@pRegionCd IS NULL OR @pRegionCd = hr.wRegion)
        AND (@pHotelRid IS NULL OR @pHotelRid = rep.wHotelRid)
        AND (@pHotelRoomRid IS NULL OR @pHotelRoomRid = rep.wRoomRid)
        AND (@pFollowDeptCd IS NULL OR @pFollowDeptCd = req.wDeptFollowedCode)
        AND (@pFollowStaffRid IS NULL OR @pFollowStaffRid = req.wStaffFollowedRid)
        AND (@pApplyStaffRid IS NULL OR @pApplyStaffRid = req.wApplyStaffRid)
        AND (@pDeptStatus IS NULL OR @pDeptStatus = rep.wDeptStatus)
        AND (@pIsNewOnly IS NULL OR @pIsNewOnly = req.wIsNewReqRoom)
        AND (@pIsHightlyAgent IS NULL OR (@pIsHightlyAgent = 'N' AND mi.RowID IS NULL) OR (@pIsHightlyAgent = 'Y' AND mi.RowID IS NOT NULL))
        AND (@pIsUnFollowed IS NULL OR (@pIsUnFollowed = 'Y' AND rep.wDeptStatus = 'RA' AND rep.wRepStatus = 'P' AND req.wStaffFollowedRid <= 0))
        AND (@pIsUnCompleted IS NULL OR (@pIsUnCompleted = 'Y' AND rep.wRepStatus = 'P' AND req.wStaffFollowedRid > 0))
        AND (@pIsUnGetKey IS NULL OR (@pIsUnGetKey = 'Y' AND rep.wDeptStatus = 'CS_AH' AND rep.wRepStatus = 'C'))
        AND ((@pEventRid IS NOT NULL AND @pEventRid = req.wEventRid) -- 如果Filter特別事件，就返回所有與此事件相關的訂單，不關注入住日期和退房日期
          OR (@pEventRid IS NULL AND ((@pCheckInDate IS NULL AND @pCheckOutDate IS NULL)
                                   OR (@pCheckInDate IS NOT NULL AND @pCheckOutDate IS NULL AND @pCheckInDate < rep.wEndDate)
                                   OR (@pCheckInDate IS NULL AND @pCheckOutDate IS NOT NULL AND @pCheckOutDate >= rep.wStartDate)
                                   OR (@pCheckInDate <= @pCheckOutDate AND NOT (@pCheckInDate >= rep.wEndDate OR @pCheckOutDate < rep.wStartDate))
                                )
            )
        )
    GROUP BY req.RowID, req.wAgentCodeIn, ma.wAccountType
    OPTION(RECOMPILE);
    -----------------------------------------------------------------------------

    ----------------------------戶口當天訂房總數量-------------------------------
    -- Old
    ---------------------------------------------------------------------------
    --CREATE TABLE #vAgentBookedRoom (
    --    wAgentCodeIn VARCHAR(14) PRIMARY KEY,
    --    wTotalBookedRoomQty INT
    --);

    --INSERT INTO #vAgentBookedRoom ( wAgentCodeIn )
    --SELECT wAgentCodeIn FROM #vDeptReqRoom GROUP BY wAgentCodeIn;

    --;WITH tCompletedRoom AS ( -- 訂單已派房總數
    --    SELECT req.wAgentCodeIn,
    --           wRoomQty = SUM(resp.wBigBedQty + resp.wTwinBedQty + resp.wSuiteRoom1Qty + resp.wSuiteRoom2Qty + resp.wSuiteRoom3Qty)
    --    FROM dbo.eDeptRespRoom resp WITH(NOLOCK)
    --    INNER JOIN dbo.eDeptReqRoom req WITH(NOLOCK) ON req.RowID = resp.wDeptReqRoomRid
    --    WHERE resp.wStartDate <= @sNow AND @sNow < resp.wEndDate
    --        AND resp.wStatus = 'A' 
    --        AND resp.wRepStatus = 'C' 
    --        AND wDeptStatus NOT IN ('CS_ST', 'CS_MM')
    --    GROUP BY req.wAgentCodeIn
    --)

    --UPDATE br
    --SET wTotalBookedRoomQty = ISNULL(cr.wRoomQty, 0)
    --FROM #vAgentBookedRoom br
    --LEFT JOIN tCompletedRoom cr ON cr.wAgentCodeIn = br.wAgentCodeIn

    --UPDATE req
    --SET wTotalBookedRoomQty = ISNULL(br.wTotalBookedRoomQty, 0)
    --FROM #vDeptReqRoom req
    --LEFT JOIN #vAgentBookedRoom br ON br.wAgentCodeIn = req.wAgentCodeIn;
    ---------------------------------------------------------------------------

    -- new : OP#30768，房數顯示條件更改為該戶口在房間預訂管理內(C-完成 與 CI-已入住)的總數
    ---------------------------------------------------------------------------
    CREATE TABLE #vAgentBookedRoom (
        wAgentCodeIn VARCHAR(14) PRIMARY KEY,
        wTotalBookedRoomQty INT
    );

    INSERT INTO #vAgentBookedRoom ( wAgentCodeIn )
    SELECT wAgentCodeIn FROM #vDeptReqRoom GROUP BY wAgentCodeIn;

    ;WITH tCompletedRoom AS ( -- 訂單已派房總數
        SELECT wAgentCodeIn = eb.wReqAgentCodeIn,
               wRoomQty = COUNT(1)
        FROM dbo.eBooking eb WITH(NOLOCK)
        INNER JOIN dbo.eBookingRoom br WITH(NOLOCK) ON br.wBookingRid = eb.RowID
        WHERE br.wStartDate <= @sNow AND @sNow < br.wEndtDate
            AND br.wStatus = 'A' 
            AND br.wBookingStatus IN ('C', 'CI')
        GROUP BY eb.wReqAgentCodeIn
    )

    UPDATE br
    SET wTotalBookedRoomQty = ISNULL(cr.wRoomQty, 0)
    FROM #vAgentBookedRoom br
    LEFT JOIN tCompletedRoom cr ON cr.wAgentCodeIn = br.wAgentCodeIn

    UPDATE req
    SET wTotalBookedRoomQty = ISNULL(br.wTotalBookedRoomQty, 0)
    FROM #vDeptReqRoom req
    LEFT JOIN #vAgentBookedRoom br ON br.wAgentCodeIn = req.wAgentCodeIn;
    ---------------------------------------------------------------------------

    -------------------------------三月轉碼數------------------------------
    DECLARE @vXML XML,
            @vResultXML XML;

    --獲取最近3個月
    --DECLARE @sPastThreeYearMonth VARCHAR(6); --當前時間往前數第3個月
    --SET @sPastThreeYearMonth = CONCAT(LEFT(CAST(DATEADD(MONTH, -2,@sNow) AS VARCHAR(10)), 4), SUBSTRING(CAST(DATEADD(MONTH, -2,@sNow) AS VARCHAR(10)), 6, 2));
    --SET @vXML = (
    --    SELECT  wAgentCodeIn = @pAgentCodeIn,
    --            wCompNo      = @sCompNo,
    --            wYearMonth   = CONCAT(wYear, wMonth)
    --    FROM RollsMary.dbo.mSettlePeriod
    --    WHERE wCompNo = 95
    --        AND (wYear + wMonth) >= @sPastThreeYearMonth
    --        AND wStartDate <= @sNow
    --    FOR XML RAW('Record'), ROOT('DataSet')
    --);

    SET @vXML = (
        SELECT  wAgentCodeIn = req.wAgentCodeIn,
                wYearMonth   = tmp.wYearMonth
        FROM #vDeptReqRoom req
        CROSS JOIN (
            SELECT  wYearMonth   = FORMAT(@sNow, 'yyyyMM')
            UNION
            SELECT  wYearMonth   = FORMAT(DATEADD(MONTH, -1, @sNow), 'yyyyMM')
            UNION
            SELECT  wYearMonth   = FORMAT(DATEADD(MONTH, -2, @sNow), 'yyyyMM')
        ) tmp
        FOR XML RAW('Record'), ROOT('DataSet')
    );

    -- 集團、場館轉碼
    EXEC util.GetRollingAndWinLoss @pXML = @vXML,
                                    @pResultXML = @vResultXML OUTPUT;

    CREATE TABLE #vRollingAndWinLoss (
        wAgentCodeIn    VARCHAR(14),
        wYearMonth      VARCHAR(6),
        wRollingHKD     NUMERIC(18, 4),
        wWinLossRatio   NUMERIC(18, 4),
        PRIMARY KEY (wAgentCodeIn, wYearMonth)
    );

    INSERT INTO #vRollingAndWinLoss (
        wAgentCodeIn,
        wYearMonth,
        wRollingHKD,
        wWinLossRatio
    )
    SELECT  wAgentCodeIn    = T.tmp.value('@wAgentCodeIn',  'VARCHAR(14)'),
            wYearMonth      = T.tmp.value('@wYearMonth',    'VARCHAR(6)'),
            wRollingHKD     = T.tmp.value('@wRollingHKD',   'NUMERIC(18, 4)'),
            wWinLossRatio   = T.tmp.value('@wWinLossRatio', 'NUMERIC(18, 4)')
    FROM @vResultXML.nodes('DataSet/Record/Group/Rolling') T(tmp);

    ;WITH tRollingAndWinLoss AS (
        SELECT  wAgentCodeIn,
                wTotalRollingAmt = SUM(wRollingHKD)
        FROM #vRollingAndWinLoss
        GROUP BY wAgentCodeIn
    )

    UPDATE req
    SET wTotalRollingAmt = ISNULL(rawl.wTotalRollingAmt, 0)
    FROM #vDeptReqRoom req
    LEFT JOIN tRollingAndWinLoss rawl ON rawl.wAgentCodeIn = req.wAgentCodeIn;
    -------------------------------三月轉碼數------------------------------

    ---------------------------------星級----------------------------------
    -- 星級優先級排列
    DECLARE @vAgentLevelMap TABLE (wType VARCHAR(30), wMapValue INT, wTypeName NVARCHAR(50), PRIMARY KEY(wType, wMapValue));
    INSERT INTO @vAgentLevelMap (wType, wMapValue, wTypeName) VALUES ('HIGHLY_VALUED', 1, N'高度重視'), ('STAR', 2, N'星級');

    SELECT  ai.wAgentCodeIn, 
            wAgentLevel = (SELECT TOP(1) wType FROM @vAgentLevelMap WHERE wMapValue = MIN(map.wMapValue))
    INTO #vAgentLevel
    FROM RollsMary.dbo.mAgentIdentity ai WITH(NOLOCK)
    INNER JOIN @vAgentLevelMap map ON map.wType = ai.wType
    INNER JOIN #vDeptReqRoom r ON r.wAgentCodeIn = ai.wAgentCodeIn
    WHERE ai.wValue = 'Y'
    GROUP BY ai.wAgentCodeIn;

    UPDATE r
    SET wAgentLevel = al.wAgentLevel
    FROM #vDeptReqRoom r
    LEFT JOIN #vAgentLevel al ON al.wAgentCodeIn = r.wAgentCodeIn;
    ---------------------------------星級----------------------------------

    ------------------------------戶口重視程度------------------------------
    -- 1. 高度重視 或 股東 或 星級 
    UPDATE req 
    SET wImportantLevel = 1 
    FROM #vDeptReqRoom req 
    WHERE req.wImportantLevel <= 0
        AND ( req.wAccountType IN ('S01', 'S02', 'A03', 'G03')
           OR req.wAgentLevel IN ('HIGHLY_VALUED')
        );

    -- 2.三個月均有轉碼且當日未有房間 或 三個月之中其中一個月轉碼超過一億且當日未有房間 或 三個月之中有兩個月有轉碼未有房間且訂當日房間
    ;WITH tRollingAndWinLoss AS (
        SELECT  wAgentCodeIn,
                wCount = COUNT(1)
        FROM #vRollingAndWinLoss
        WHERE wRollingHKD > 0
        GROUP BY wAgentCodeIn
    ), tMillionRolling AS (
        SELECT  wAgentCodeIn,
                wCount = COUNT(1)
        FROM #vRollingAndWinLoss
        WHERE wRollingHKD >= 100000000
        GROUP BY wAgentCodeIn
    )

    UPDATE req 
    SET wImportantLevel = 2 
    FROM #vDeptReqRoom req
    LEFT JOIN dbo.eDeptRespRoom resp WITH(NOLOCK) ON resp.wDeptReqRoomRid = req.RowID
    LEFT JOIN tRollingAndWinLoss rawl ON rawl.wAgentCodeIn = req.wAgentCodeIn
    LEFT JOIN tMillionRolling mr ON mr.wAgentCodeIn = req.wAgentCodeIn
    WHERE req.wImportantLevel <= 0
        AND ( ( rawl.wCount >= 3 AND req.wTotalBookedRoomQty = 0) -- 三個月均有轉碼且當日未有房間
            OR (mr.wCount >= 1 AND req.wTotalBookedRoomQty = 0) -- 三個月之中其中一個月轉碼超過一億且當日未有房間
            OR (rawl.wCount >= 2 AND req.wTotalBookedRoomQty = 0 AND resp.wStartDate <= @sNow AND @sNow < resp.wEndDate) -- 三個月之中有兩個月有轉碼未有房間且訂當日房間
        );

    --  3. 三個月均有轉碼且當日已有房間 或 三個月之中兩個月有轉碼且不是訂當天房間 或 三個月之中只有一個月有轉碼且訂當天房間
    ;WITH tRollingAndWinLoss AS (
        SELECT  wAgentCodeIn,
                wCount = COUNT(1)
        FROM #vRollingAndWinLoss
        WHERE wRollingHKD > 0
        GROUP BY wAgentCodeIn
    )

    UPDATE req 
    SET wImportantLevel = 3
    FROM #vDeptReqRoom req 
    LEFT JOIN dbo.eDeptRespRoom resp WITH(NOLOCK) ON resp.wDeptReqRoomRid = req.RowID
    LEFT JOIN tRollingAndWinLoss rawl ON rawl.wAgentCodeIn = req.wAgentCodeIn
    WHERE req.wImportantLevel <= 0
        AND (  (rawl.wCount >= 3 AND req.wTotalBookedRoomQty > 0) -- 三個月均有轉碼且當日已有房間
            OR (rawl.wCount >= 2 AND (@sNow < resp.wStartDate OR @sNow >= resp.wEndDate) ) -- 三個月之中兩個月有轉碼且不是訂當天房間
            OR (rawl.wCount >= 1 AND resp.wStartDate <= @sNow AND @sNow < resp.wEndDate) -- 三個月之中只有一個月有轉碼且訂當天房間
        );

    -- 4. 三個月未有轉碼 或 三個月只有一個月有轉碼且不是訂當天房間
    ;WITH tRollingAndWinLoss AS (
        SELECT  wAgentCodeIn,
                wCount = COUNT(1)
        FROM #vRollingAndWinLoss
        WHERE wRollingHKD > 0
        GROUP BY wAgentCodeIn
    )

    UPDATE req 
    SET wImportantLevel = 4
    FROM #vDeptReqRoom req 
    LEFT JOIN dbo.eDeptRespRoom resp WITH(NOLOCK) ON resp.wDeptReqRoomRid = req.RowID
    LEFT JOIN tRollingAndWinLoss rawl ON rawl.wAgentCodeIn = req.wAgentCodeIn
    WHERE req.wImportantLevel <= 0
        AND (ISNULL(rawl.wCount, 0) = 0 -- 三個月未有轉碼
            OR (rawl.wCount >= 1 AND (@sNow < resp.wStartDate OR @sNow >= resp.wEndDate)) -- 三個月只有一個月有轉碼且不是訂當天房間
        );
    ------------------------------戶口重視程度------------------------------

    ;WITH tResult AS (
        SELECT 
            req.RowID,
            req.wRequestNo,
            req.wRequestDepartment,
            req.wAgentCodeIn,
            ma.wAccountType,
            ma.wAgentCode_Display,
            wAgentCode_Name = ma.wCName,
            wAgentIdentity = CAST(ma.wAccountType AS VARCHAR(30)), -- 2019-06-13: OP#30058
            wAgentLevel = ISNULL(vreq.wAgentLevel, ''),
            wAgentPortrait = @sAgentPortrait, -- 頭像
            wImportantLevel = ISNULL(vreq.wImportantLevel, 0), -- 重視程度
            wTotalRollingAmt = ISNULL(vreq.wTotalRollingAmt, 0), -- 三月總轉碼
            wTotalBookedRoomQty = ISNULL(vreq.wTotalBookedRoomQty, 0), -- 當天總訂房數量
            req.wEventRid,
            req.wHotelRid,
            wHotelName = h.wName,-- 排序
            req.wRoomRid,
            wRoomName = hr.wName,-- 排序
            req.wBigBedQty,
            req.wTwinBedQty,
            req.wSuiteRoom1Qty,
            req.wSuiteRoom2Qty,
            req.wSuiteRoom3Qty,
            req.wDayOfStay,
            req.wStartDate,
            req.wEndDate,
            req.wRemark,
            req.wIsNewReqRoom,
            req.wIsCancel,
            wFollowedDeptCode = req.wDeptFollowedCode,
            wFollowedStaffRid = req.wStaffFollowedRid,
            wStaffFollowedName = fu.wCName, -- 排序
            wFollowedStaffTel = fu.wPrivateTel, -- 電話號
            wFollowedStaffTelExt = fu.wTelExt, -- 分機號
            wFollowedStaffTelCountryCd = fu.wPrivateTelCountryCode, -- 區號
            req.wApplyDepartment,
            req.wApplyStaffRid,
            wApplyStaffName = au.wCName, -- 排序
            wApplyStaffTel = au.wPrivateTel, -- 電話號
            wApplyStaffTelExt = au.wTelExt, -- 分機號
            wApplyStaffTelCountryCd = au.wPrivateTelCountryCode, -- 區號
            wRequestRoomQty = CONVERT(INT, 0), -- 需求數量
            wUnCompletedRoomQty = CONVERT(INT, 0), -- 處理中房間數量
            wCancelledRoomQty = CONVERT(INT, 0), -- 客人取消房間數量
            wCompletedNotReqRoomQty = CONVERT(INT, 0), -- 非需求酒店房間完成數量
            wCompletedReqRoomQty = CONVERT(INT, 0), -- 需求酒店房間完成數量
            wCompletedRoomQty = CONVERT(INT, 0), -- 訂單已派房總數
            wIsBookingExpired = CASE WHEN me.RowID IS NULL THEN 'N' -- 預訂是否過期，過期后不可以做任何修改
                                     WHEN me.wBookingStartDate IS NULL AND me.wBookingEndDate IS NULL AND @sNow BETWEEN me.wStartDate AND me.wEndDate THEN 'N'
                                     WHEN me.wBookingStartDate IS NOT NULL AND me.wBookingEndDate IS NULL AND @sNow >= me.wBookingStartDate AND @sNow <= me.wEndDate THEN 'N'
                                     WHEN me.wBookingStartDate IS NULL AND me.wBookingEndDate IS NOT NULL AND @sNow <= me.wBookingEndDate THEN 'N'
                                     WHEN @sNow BETWEEN me.wBookingStartDate AND me.wBookingEndDate THEN 'N'
                                     ELSE 'Y'
                                END,
            req.wReqStatus,
            req.wStatus,
            req.wCrtDt,
            req.wCrtBy,
            wCrtByCName = cu.wCName,
            wCrtByEName = cu.wName,
            req.wUpdDt,
            req.wUpdBy,
            wUpdByCName = cu.wCName,
            wUpdByEName = cu.wName,
            req.wIsExtRoom, -- 是否續房
            req.wGUID -- 修改標識
        FROM #vDeptReqRoom vreq
        INNER JOIN dbo.eDeptReqRoom AS req WITH(NOLOCK) ON req.RowID = vreq.RowID
        LEFT JOIN dbo.mHotel AS h WITH(NOLOCK) ON h.RowID = req.wHotelRid 
        LEFT JOIN dbo.mHotelRoom AS hr WITH(NOLOCK) ON hr.RowID = req.wRoomRid 
        LEFT JOIN dbo.mEvent AS me WITH(NOLOCK) ON me.RowID = req.RowID
        LEFT JOIN RollsMary.dbo.mAgent AS ma WITH(NOLOCK) ON ma.wAgentCodeIn  = req.wAgentCodeIn
        LEFT JOIN RollsMary.dbo.mUsr AS fu WITH(NOLOCK) ON fu.RowID = req.wStaffFollowedRid -- 跟進人
        LEFT JOIN RollsMary.dbo.mUsr AS au WITH(NOLOCK) ON au.RowID = req.wApplyStaffRid -- 要求人
        LEFT JOIN RollsMary.dbo.mUsr AS cu WITH(NOLOCK) ON cu.RowID = req.wCrtBy -- 創建人
        LEFT JOIN RollsMary.dbo.mUsr AS uu WITH(NOLOCK) ON uu.RowID = req.wUpdBy  -- 最後修改人
        WHERE (@pImportantLevel IS NULL OR @pImportantLevel = wImportantLevel)
	),
	tCount AS (
        SELECT wRecordCount = COUNT(1) FROM tResult
    )

    SELECT tResult.*, wRecordCount
    INTO #vResult
    FROM tResult, tCount
    ORDER BY CASE @pSort WHEN 'AgentCode_Display ASC'   THEN wAgentCode_Display END ASC,
             CASE @pSort WHEN 'AgentCode_Display DESC'  THEN wAgentCode_Display END DESC,
             -- CASE @pSort WHEN 'RequestNo ASC'           THEN wRequestNo         END ASC,
             -- CASE @pSort WHEN 'RequestNo DESC'          THEN wRequestNo         END DESC,
             CASE @pSort WHEN 'HotelName ASC'           THEN wHotelName         END ASC,
             CASE @pSort WHEN 'HotelName DESC'          THEN wHotelName         END DESC,
             CASE @pSort WHEN 'HotelRoomName ASC'       THEN wRoomName          END ASC,
             CASE @pSort WHEN 'HotelRoomName DESC'      THEN wRoomName          END DESC,
             -- CASE @pSort WHEN 'FollowedDeptCd ASC'      THEN wFollowedDeptCode  END ASC,
             -- CASE @pSort WHEN 'FollowedDeptCd DESC'     THEN wFollowedDeptCode  END DESC,
             CASE @pSort WHEN 'FollowedStaffName ASC'   THEN wStaffFollowedName END ASC,
             CASE @pSort WHEN 'FollowedStaffName DESC'  THEN wStaffFollowedName END DESC,
             CASE @pSort WHEN 'ApplyStaffName ASC'      THEN wApplyStaffName    END ASC,
             CASE @pSort WHEN 'ApplyStaffName DESC'     THEN wApplyStaffName    END DESC,
             CASE @pSort WHEN 'RequestStatus ASC'       THEN wReqStatus         END ASC,
             CASE @pSort WHEN 'RequestStatus DESC'      THEN wReqStatus         END DESC,
             CASE @pSort WHEN 'ImportantLevel ASC'      THEN wImportantLevel    END ASC,
             CASE @pSort WHEN 'ImportantLevel DESC'     THEN wImportantLevel    END DESC,
             tResult.wRequestNo DESC
    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
    FETCH NEXT @pPageSize ROWS ONLY
    OPTION (RECOMPILE );

    ---------------------------------訂房數量-----------------------------------
    ;WITH tRequestRoom AS ( -- 需求數量
        SELECT wDeptReqRoomRid,
               wRoomQty = SUM(wBigBedQty + wTwinBedQty + wSuiteRoom1Qty + wSuiteRoom2Qty + wSuiteRoom3Qty)
        FROM dbo.eDeptRespRoom WITH(NOLOCK)
        WHERE wStatus = 'A' 
            AND wRepStatus IN ('P', 'C', 'CL')
            AND wDeptStatus NOT IN ('CS_ST', 'CS_MM')
        GROUP BY wDeptReqRoomRid
    ), tUnCompletedRoom AS ( -- 處理中房間數量
        SELECT wDeptReqRoomRid,
               wRoomQty = SUM(wBigBedQty + wTwinBedQty + wSuiteRoom1Qty + wSuiteRoom2Qty + wSuiteRoom3Qty)
        FROM dbo.eDeptRespRoom WITH(NOLOCK)
        WHERE wStatus = 'A' 
            AND wRepStatus = 'P' 
            AND wDeptStatus NOT IN ('CS_ST', 'CS_MM')
        GROUP BY wDeptReqRoomRid
    ), tCancelledRoom AS ( -- 客人取消房間數量
        SELECT wDeptReqRoomRid,
               wRoomQty = SUM(wBigBedQty + wTwinBedQty + wSuiteRoom1Qty + wSuiteRoom2Qty + wSuiteRoom3Qty)
        FROM dbo.eDeptRespRoom WITH(NOLOCK)
        WHERE wStatus = 'A' 
            AND wRepStatus = 'CL' 
            AND wDeptStatus NOT IN ('CS_ST', 'CS_MM', 'CS_UQ')
        GROUP BY wDeptReqRoomRid
    ), tCompletedNotReqRoom AS ( -- 非需求酒店房間完成數量
        SELECT resp.wDeptReqRoomRid,
               wRoomQty = SUM(resp.wBigBedQty + resp.wTwinBedQty + resp.wSuiteRoom1Qty + resp.wSuiteRoom2Qty + resp.wSuiteRoom3Qty)
        FROM dbo.eDeptRespRoom resp WITH(NOLOCK)
        INNER JOIN dbo.eDeptReqRoom req WITH(NOLOCK) ON req.RowID = resp.wDeptReqRoomRid
        WHERE resp.wStatus = 'A' 
            AND resp.wRepStatus = 'C' 
            AND resp.wHotelRid <> req.wHotelRid 
            AND wDeptStatus NOT IN ('CS_ST', 'CS_MM')
        GROUP BY wDeptReqRoomRid
    ), tCompletedReqRoom AS ( -- 需求酒店房間完成數量
        SELECT resp.wDeptReqRoomRid,
               wRoomQty = SUM(resp.wBigBedQty + resp.wTwinBedQty + resp.wSuiteRoom1Qty + resp.wSuiteRoom2Qty + resp.wSuiteRoom3Qty)
        FROM dbo.eDeptRespRoom resp WITH(NOLOCK)
        INNER JOIN dbo.eDeptReqRoom req WITH(NOLOCK) ON req.RowID = resp.wDeptReqRoomRid
        WHERE resp.wStatus = 'A' 
            AND resp.wRepStatus = 'C' 
            AND resp.wHotelRid = req.wHotelRid 
            AND wDeptStatus NOT IN ('CS_ST', 'CS_MM')
        GROUP BY wDeptReqRoomRid
    ), tCompletedRoom AS ( -- 訂單已派房總數
        SELECT wDeptReqRoomRid,
               wRoomQty = SUM(wBigBedQty + wTwinBedQty + wSuiteRoom1Qty + wSuiteRoom2Qty + wSuiteRoom3Qty)
        FROM dbo.eDeptRespRoom WITH(NOLOCK)
        WHERE wStatus = 'A' 
            AND wRepStatus = 'C' 
            AND wDeptStatus NOT IN ('CS_ST', 'CS_MM')
        GROUP BY wDeptReqRoomRid
    )

    UPDATE req
    SET wRequestRoomQty = ISNULL(rr.wRoomQty, 0), -- 需求數量
        wUnCompletedRoomQty = ISNULL(ucr.wRoomQty, 0), -- 處理中房間數量
        wCancelledRoomQty = ISNULL(cr.wRoomQty, 0), -- 客人取消房間數量
        wCompletedNotReqRoomQty = ISNULL(cnrr.wRoomQty, 0), -- 非需求酒店房間完成數量
        wCompletedReqRoomQty = ISNULL(crr.wRoomQty, 0), -- 需求酒店房間完成數量
        wCompletedRoomQty = ISNULL(cdr.wRoomQty, 0) -- 訂單已派房總數
    FROM #vResult req
    LEFT JOIN tRequestRoom AS rr ON rr.wDeptReqRoomRid = req.RowID
    LEFT JOIN tUnCompletedRoom AS ucr ON ucr.wDeptReqRoomRid = req.RowID
    LEFT JOIN tCancelledRoom AS cr ON cr.wDeptReqRoomRid = req.RowID
    LEFT JOIN tCompletedNotReqRoom AS cnrr ON cnrr.wDeptReqRoomRid = req.RowID
    LEFT JOIN tCompletedReqRoom AS crr ON crr.wDeptReqRoomRid = req.RowID
    LEFT JOIN tCompletedRoom AS cdr ON cdr.wDeptReqRoomRid = req.RowID;
    ---------------------------------訂房數量-----------------------------------

    -- 2019-06-13: OP#30058
    -------------------------------戶口身份--------------------------------
    --DECLARE @vAgentXML XML;

    --CREATE TABLE #vAgentIdentity (
    --    wAgentCodeIn    VARCHAR(14) PRIMARY KEY,
    --    wShareLevel     INT,
    --    wAgentLevel     INT,
    --    wAgentType      VARCHAR(15),
    --    wDirectCredit   CHAR(1),
    --    wIsDownLevel    CHAR(1),
    --    wIsCapital      CHAR(1),
    --    wIsCredit       CHAR(1),
    --    wAgentIdentity  VARCHAR(20)
    --);
        
    --SET @vAgentXML = ( SELECT wAgentCodeIn FROM #vDeptReqRoom GROUP BY wAgentCodeIn FOR XML RAW('Record'), ROOT('DataSet') );

    --INSERT INTO #vAgentIdentity EXEC RollsMary.spq.GetAgentIdentity @pXML = @vAgentXML;
        
    --UPDATE r
    --SET wAgentIdentity = vai.wAgentIdentity
    --FROM #vResult r
    --INNER JOIN #vAgentIdentity vai ON vai.wAgentCodeIn = r.wAgentCodeIn
    -------------------------------戶口身份--------------------------------

    -------------------------------戶口頭像--------------------------------
    SELECT d.RowID, d.wAgentCodeIn
    INTO #vDocument
    FROM (
        SELECT  RowNum = ROW_NUMBER() OVER(PARTITION BY wRefRID ORDER BY wUpdDt DESC),
                ed.RowID,
                r.wAgentCodeIn
        FROM RollsMary_Doc.dbo.eDocument ed WITH(NOLOCK)
        INNER JOIN (SELECT wAgentCodeIn FROM #vResult GROUP BY wAgentCodeIn) r ON r.wAgentCodeIn = ed.wRefRID AND ed.wRefTable = 'mAgent'
        WHERE wStatus = 'A' AND wCategory = 'AGENT' AND wType = 'PHOTO' AND ed.wSizeType = 'S'
    ) AS d WHERE d.RowNum = 1;

    UPDATE r
    SET r.wAgentPortrait = ed.wFileData
    FROM #vResult r
    INNER JOIN #vDocument vd ON vd.wAgentCodeIn = r.wAgentCodeIn
    INNER JOIN RollsMary_Doc.dbo.eDocument ed WITH(NOLOCK) ON ed.RowID = vd.RowID;
    -------------------------------戶口頭像--------------------------------

    SELECT * FROM #vResult;

    IF OBJECT_ID('tempdb..#vDeptReqRoom') IS NOT NULL
        DROP TABLE #vDeptReqRoom;

    IF OBJECT_ID('tempdb..#vAgentBookedRoom') IS NOT NULL
        DROP TABLE #vAgentBookedRoom;

    IF OBJECT_ID('tempdb..#vRollingAndWinLoss') IS NOT NULL
        DROP TABLE #vRollingAndWinLoss;

    IF OBJECT_ID('tempdb..#vAgentIdentity') IS NOT NULL
        DROP TABLE #vAgentIdentity;

    IF OBJECT_ID('tempdb..#vAgentLevel') IS NOT NULL
        DROP TABLE #vAgentLevel;

    IF OBJECT_ID('tempdb..#vDocument') IS NOT NULL
        DROP TABLE #vDocument;

    IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
        DROP TABLE #vResult;
END;