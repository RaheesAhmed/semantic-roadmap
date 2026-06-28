
CREATE PROCEDURE [test].[GetRptDeptRequestRoom]
    @pXMLFilter XML,
    @pLangCd VARCHAR(10) = 'zh-TW'
AS
BEGIN
    SET NOCOUNT ON;

    SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

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
            @pIsNewOnly         CHAR(1),
            @pDeptReqRoomRid    BIGINT,
            @pFollowStaffRid    BIGINT,
            @pApplyStaffRid     BIGINT,
            @pDeptStatus        VARCHAR(20),
            @pHotelRefNo        VARCHAR(30),
            @pIsHightlyAgent    CHAR(1),
            @pIsUnFollowed      CHAR(1),
            @pIsUnCompleted     CHAR(1),
            @pIsUnGetKey        CHAR(1);

    SELECT  @pDeptCd            = T.tmp.value('(Filter/@pDeptCd)[1]',             'VARCHAR(30)'),
            @pAgentCodeIn       = T.tmp.value('(Filter/@pAgentCodeIn)[1]',        'VARCHAR(14)'),
            @pEventRid          = T.tmp.value('(Filter/@pEventRid)[1]',           'BIGINT'),
            @pRequestNo         = T.tmp.value('(Filter/@pRequestNo)[1]',          'VARCHAR(30)'),
            @pRequestStatus     = T.tmp.value('(Filter/@pRequestStatus)[1]',      'VARCHAR(30)'),
            @pCheckInDate       = NULLIF(T.tmp.value('(Filter/@pCheckInDate)[1]', 'VARCHAR(20)'), ''),
            @pCheckOutDate      = NULLIF(T.tmp.value('(Filter/@pCheckOutDate)[1]','VARCHAR(20)'), ''),
            @pRegionCd          = T.tmp.value('(Filter/@pRegionCd)[1]',           'VARCHAR(30)'),
            @pHotelRid          = T.tmp.value('(Filter/@pHotelRid)[1]',           'BIGINT'),
            @pHotelRoomRid      = T.tmp.value('(Filter/@pHotelRoomRid)[1]',       'BIGINT'),
            @pFollowDeptCd      = T.tmp.value('(Filter/@pFollowDeptCd)[1]',       'VARCHAR(30)'),
            @pFollowStaffRid    = T.tmp.value('(Filter/@pFollowStaffRid)[1]',     'BIGINT'),
            @pApplyStaffRid     = T.tmp.value('(Filter/@pApplyStaffRid)[1]',      'BIGINT'),
            @pDeptStatus        = T.tmp.value('(Filter/@pDeptStatus)[1]',         'VARCHAR(20)'),
            @pHotelRefNo        = T.tmp.value('(Filter/@pHotelRefNo)[1]',         'VARCHAR(30)'),
            @pDeptReqRoomRid    = T.tmp.value('(Filter/@pDeptReqRoomRid)[1]',     'BIGINT'),
            @pIsNewOnly         = T.tmp.value('(Filter/@pIsNewOnly)[1]',          'CHAR(1)'),
            @pIsHightlyAgent    = T.tmp.value('(Filter/@pIsHightlyAgent)[1]',     'CHAR(1)'),
            @pIsUnFollowed      = T.tmp.value('(Filter/@pIsUnFollowed)[1]',       'CHAR(1)'),
            @pIsUnCompleted     = T.tmp.value('(Filter/@pIsUnCompleted)[1]',      'CHAR(1)'),
            @pIsUnGetKey        = T.tmp.value('(Filter/@pIsUnGetKey)[1]',         'CHAR(1)')
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
    SET @pIsNewOnly         = IIF(@pIsNewOnly NOT IN ('Y', 'N'), NULL, @pIsNewOnly);
    SET @pIsHightlyAgent    = IIF(@pIsHightlyAgent NOT IN ('Y', 'N'), NULL, @pIsHightlyAgent);
    SET @pIsUnFollowed      = IIF(@pIsUnFollowed = 'Y', 'Y', NULL);
    SET @pIsUnCompleted     = IIF(@pIsUnCompleted = 'Y', 'Y', NULL);
    SET @pIsUnGetKey        = IIF(@pIsUnGetKey = 'Y', 'Y', NULL);
    
    -- 預訂部門
    -----------------------------------------------------------------------------------
    DECLARE @vDept TABLE( wCode VARCHAR(30) PRIMARY KEY, wName NVARCHAR(50) );
    INSERT INTO @vDept( wCode, wName )
    SELECT wCode, wTitle
    FROM dbo.mLookUp
    WHERE wType = 'DEPTREQROOM_DEPARMENT' 
        AND wLangCd = @pLangCd
        AND wCanSelect = 'Y';
    
    -- 需求狀態對照表
    -----------------------------------------------------------------------------------
    DECLARE @vStatusMap AS TABLE(
        wStatus VARCHAR(20),
        wMapValue INT,
        wStatusName NVARCHAR(50)
        PRIMARY KEY(wStatus, wMapValue)
    );
    INSERT INTO @vStatusMap( 
        wStatus, 
        wMapValue, 
        wStatusName 
    )
    SELECT  wStatus     = wCode, 
            wMapValue   = wSeqNo, 
            wStatusName = wTitle
    FROM dbo.mLookUp
    WHERE wType = 'DEPTROOM_RESPONSE_STATUS' AND wLangCd = 'zh-TW';

    -- DECLARE @vDeptReqRoom TABLE ( RowID  BIGINT PRIMARY KEY(RowID) );

    CREATE TABLE #vDeptReqRoom ( RowID  BIGINT PRIMARY KEY(RowID) );

    -- 2019-05-17：OP#28681，日期、酒店以細單作為搜索，不要大單
    ---------------------------------------------------------------------------------------
    INSERT INTO #vDeptReqRoom(RowID)
    SELECT req.RowID
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
    GROUP BY req.RowID
    OPTION(RECOMPILE);
    ------------------------------------------------------------------------------------

    SELECT 
        dr.RowID,
        dr.wRequestNo,
        dr.wRequestDepartment,
        dr.wHotelRid,
        dr.wRoomRid,
        dr.wBigBedQty,
        dr.wTwinBedQty,
        dr.wSuiteRoom1Qty,
        dr.wSuiteRoom2Qty,
        dr.wSuiteRoom3Qty,
        dr.wDayOfStay,
        dr.wStartDate,
        dr.wEndDate,
        dr.wRemark,
        dr.wUpdDt,
        dr.wUpdBy,
        dr.wEventRid,
        dr.wTotalAmt,
        wHotelName = h.wName,
        wRoomName = hr.wName,
        wAgentCodeIn = dr.wAgentCodeIn,
        wAgentCode_Display = a.wAgentCode_Display,
        wAgentCodeName = a.wCName,
        wAgentIdentity = CAST('' AS NVARCHAR(50)),
        wAgentLevel = CAST('' AS NVARCHAR(50)),
        wChatMessage = CAST('' AS NVARCHAR(MAX)),
        wFollowedDept = dept.wName,
        wFollowedUser = fu.wCName,
        wFollowedUserTel = fu.wPrivateTel, -- 跟進人電話
        wApplyUser = au.wCName,
        wApplyUserTel = au.wPrivateTel, -- 要求人電話
        wUpdUser= uu.wCName,
        wReqStatus = sm.wStatusName,
        wRequestRoomQty = CONVERT(INT, 0), -- 需求數量
        wUnCompletedRoomQty = CONVERT(INT, 0), -- 處理中房間數量
        wCancelledRoomQty = CONVERT(INT, 0), -- 客人取消房間數量
        wCompletedNotReqRoomQty = CONVERT(INT, 0), -- 非需求酒店房間完成數量
        wCompletedReqRoomQty = CONVERT(INT, 0), -- 需求酒店房間完成數量
        wCompletedRoomQty = CONVERT(INT, 0) -- 訂單已派房總數
    INTO #vResult
    FROM #vDeptReqRoom vreq
    -- FROM @vDeptReqRoom vreq
    INNER JOIN dbo.eDeptReqRoom AS dr WITH(NOLOCK) ON dr.RowID = vreq.RowID
    LEFT JOIN dbo.mHotel AS h WITH(NOLOCK) ON h.RowID = dr.wHotelRid 
    LEFT JOIN dbo.mHotelRoom AS hr WITH(NOLOCK) ON hr.RowID = dr.wRoomRid 
    LEFT JOIN dbo.mEvent AS me WITH(NOLOCK) ON me.RowID = dr.RowID
    LEFT JOIN RollsMary.dbo.mAgent AS a WITH(NOLOCK) ON a.wAgentCodeIn  = dr.wAgentCodeIn
    LEFT JOIN RollsMary.dbo.mUsr AS fu WITH(NOLOCK) ON fu.RowID = dr.wStaffFollowedRid 
    LEFT JOIN RollsMary.dbo.mUsr AS au WITH(NOLOCK) ON au.RowID = dr.wApplyStaffRid
    LEFT JOIN RollsMary.dbo.mUsr AS uu WITH(NOLOCK) ON uu.RowID = dr.wUpdBy
    LEFT JOIN @vDept AS dept ON dept.wCode = dr.wDeptFollowedCode
    LEFT JOIN @vStatusMap AS sm ON sm.wStatus = dr.wReqStatus
    OPTION(RECOMPILE);

    ---------------------------------訂房數量-----------------------------------
    ;WITH tRequestRoom AS ( -- 需求數量
        SELECT wDeptReqRoomRid,
               wRoomQty = SUM(wBigBedQty + wTwinBedQty + wSuiteRoom1Qty + wSuiteRoom2Qty + wSuiteRoom3Qty)
        FROM dbo.eDeptRespRoom WITH(NOLOCK)
        WHERE wStatus = 'A' 
            AND wRepStatus IN ('P', 'C')
            AND wDeptStatus NOT IN ('CS_ST', 'CS_MS')
        GROUP BY wDeptReqRoomRid
    ),tUnCompletedRoom AS ( -- 處理中房間數量
        SELECT wDeptReqRoomRid,
               wRoomQty = SUM(wBigBedQty + wTwinBedQty + wSuiteRoom1Qty + wSuiteRoom2Qty + wSuiteRoom3Qty)
        FROM dbo.eDeptRespRoom WITH(NOLOCK)
        WHERE wStatus = 'A' 
            AND wRepStatus = 'P' 
            AND wDeptStatus NOT IN ('CS_ST', 'CS_MS')
        GROUP BY wDeptReqRoomRid
    ), tCancelledRoom AS ( -- 客人取消房間數量
        SELECT wDeptReqRoomRid,
               wRoomQty = SUM(wBigBedQty + wTwinBedQty + wSuiteRoom1Qty + wSuiteRoom2Qty + wSuiteRoom3Qty)
        FROM dbo.eDeptRespRoom WITH(NOLOCK)
        WHERE wStatus = 'A' 
            AND wRepStatus = 'CL' 
            AND wDeptStatus NOT IN ('CS_ST', 'CS_MS')
        GROUP BY wDeptReqRoomRid
    ), tCompletedNotReqRoom AS ( -- 非需求酒店房間完成數量
        SELECT resp.wDeptReqRoomRid,
               wRoomQty = SUM(resp.wBigBedQty + resp.wTwinBedQty + resp.wSuiteRoom1Qty + resp.wSuiteRoom2Qty + resp.wSuiteRoom3Qty)
        FROM dbo.eDeptRespRoom resp WITH(NOLOCK)
        INNER JOIN dbo.eDeptReqRoom req WITH(NOLOCK) ON req.RowID = resp.wDeptReqRoomRid
        WHERE resp.wStatus = 'A' 
            AND resp.wRepStatus = 'C' 
            AND resp.wHotelRid <> req.wHotelRid 
            AND wDeptStatus NOT IN ('CS_ST', 'CS_MS')
        GROUP BY wDeptReqRoomRid
    ), tCompletedReqRoom AS ( -- 需求酒店房間完成數量
        SELECT resp.wDeptReqRoomRid,
               wRoomQty = SUM(resp.wBigBedQty + resp.wTwinBedQty + resp.wSuiteRoom1Qty + resp.wSuiteRoom2Qty + resp.wSuiteRoom3Qty)
        FROM dbo.eDeptRespRoom resp WITH(NOLOCK)
        INNER JOIN dbo.eDeptReqRoom req WITH(NOLOCK) ON req.RowID = resp.wDeptReqRoomRid
        WHERE resp.wStatus = 'A' 
            AND resp.wRepStatus = 'C' 
            AND resp.wHotelRid = req.wHotelRid 
            AND wDeptStatus NOT IN ('CS_ST', 'CS_MS')
        GROUP BY wDeptReqRoomRid
    ), tCompletedRoom AS ( -- 訂單已派房總數
        SELECT wDeptReqRoomRid,
               wRoomQty = SUM(wBigBedQty + wTwinBedQty + wSuiteRoom1Qty + wSuiteRoom2Qty + wSuiteRoom3Qty)
        FROM dbo.eDeptRespRoom WITH(NOLOCK)
        WHERE wStatus = 'A' 
            AND wRepStatus = 'C' 
            AND wDeptStatus NOT IN ('CS_ST', 'CS_MS')
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

    -------------------------------戶口身份--------------------------------
    DECLARE @vAgentXML XML;

    DECLARE @vAgentType TABLE(
        wCode       VARCHAR(30) PRIMARY KEY,
        wTitle      NVARCHAR(50),
        wBackground CHAR(7),
        wForeground CHAR(7),
        wSeqNo      INT
    );
    INSERT INTO @vAgentType SELECT * FROM dbo.fnGetAgentType(@pLangCd);

    CREATE TABLE #vAgentIdentity (
        wAgentCodeIn    VARCHAR(14) PRIMARY KEY,
        wShareLevel     INT,
        wAgentLevel     INT,
        wAgentType      VARCHAR(15),
        wDirectCredit   CHAR(1),
        wIsDownLevel    CHAR(1),
        wIsCapital      CHAR(1),
        wIsCredit       CHAR(1),
        wAgentIdentity  VARCHAR(20)
    );
        
    SET @vAgentXML = ( SELECT wAgentCodeIn FROM #vResult GROUP BY wAgentCodeIn FOR XML RAW('Record'), ROOT('DataSet') );

    INSERT INTO #vAgentIdentity EXEC RollsMary.spq.GetAgentIdentity @pXML = @vAgentXML;
        
    UPDATE r
    SET wAgentIdentity = vat.wTitle
    FROM #vResult r
    INNER JOIN #vAgentIdentity vai ON vai.wAgentCodeIn = r.wAgentCodeIn
    INNER JOIN @vAgentType vat ON vat.wCode = vai.wAgentIdentity
    -------------------------------戶口身份--------------------------------

    ---------------------------------星級----------------------------------
    -- 星級優先級排列
    DECLARE @vAgentLevelMap TABLE (wType VARCHAR(30), wMapValue INT, wTypeName NVARCHAR(50), PRIMARY KEY(wType, wMapValue));
    INSERT INTO @vAgentLevelMap (wType, wMapValue, wTypeName) VALUES ('HIGHLY_VALUED', 1, N'高度重視'), ('STAR', 2, N'星級');

    SELECT  ai.wAgentCodeIn, 
            wAgentLevelName = (SELECT TOP(1) wTypeName FROM @vAgentLevelMap WHERE wMapValue = MIN(map.wMapValue))
    INTO #vAgentLevel
    FROM RollsMary.dbo.mAgentIdentity ai WITH(NOLOCK)
    INNER JOIN @vAgentLevelMap map ON map.wType = ai.wType
    INNER JOIN #vResult r ON r.wAgentCodeIn = ai.wAgentCodeIn
    WHERE ai.wValue = 'Y'
    GROUP BY ai.wAgentCodeIn;

    UPDATE r
    SET wAgentLevel = al.wAgentLevelName
    FROM #vResult r
    LEFT JOIN #vAgentLevel al ON al.wAgentCodeIn = r.wAgentCodeIn
    ---------------------------------星級----------------------------------

    SELECT * FROM #vResult ORDER BY wRequestNo DESC;

    IF OBJECT_ID('tempdb..#vDeptReqRoom') IS NOT NULL
        DROP TABLE #vDeptReqRoom;

    IF OBJECT_ID('tempdb..#vAgentIdentity') IS NOT NULL
        DROP TABLE #vAgentIdentity;

    IF OBJECT_ID('tempdb..#vAgentLevel') IS NOT NULL
        DROP TABLE #vAgentLevel;

    IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
        DROP TABLE #vResult;
END;