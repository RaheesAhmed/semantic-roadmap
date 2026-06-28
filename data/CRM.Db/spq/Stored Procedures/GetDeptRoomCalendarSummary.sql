CREATE PROCEDURE [spq].[GetDeptRoomCalendarSummary]
    @pFilterXML XML,
    @pLangCd VARCHAR(10) = 'zh-TW'
AS
BEGIN
    SET NOCOUNT ON;

    ------------------dbml---------------------
    --DECLARE @tResult AS TABLE (
    --    wDate           DATE NOT NULL,
    --    wAllotmentQty   INT NOT NULL,
    --    wRequestQty     INT NOT NULL,
    --    wCompletedQty   INT NOT NULL,
    --    wQueueQty       INT NOT NULL,
    --    wNewRequestQty  INT NOT NULL
    --);

    --SELECT * FROM @tResult
    ----------------End dbml-------------------

    DECLARE @sDeptCd VARCHAR(20);
    DECLARE @sRegionCd VARCHAR(20);
    DECLARE @sHotelType VARCHAR(10);
    DECLARE @sHotelRid BIGINT;
    DECLARE @sRoomRid BIGINT;
    DECLARE @sEventRid BIGINT;
    DECLARE @sStartDate DATE;
    DECLARE @sEndDate DATE;
    DECLARE @sDay INT;
    DECLARE @vDay TABLE ( wDate DATE PRIMARY KEY);

    IF @pFilterXML IS NOT NULL
    BEGIN
        SET @sDeptCd    = @pFilterXML.value('(Filter/@pDeptCd)[1]',    'VARCHAR(20)');
        SET @sRegionCd  = @pFilterXML.value('(Filter/@pRegionCd)[1]',  'VARCHAR(20)');
        SET @sHotelType = @pFilterXML.value('(Filter/@pHotelType)[1]', 'VARCHAR(10)');
        SET @sHotelRid  = @pFilterXML.value('(Filter/@pHotelRid)[1]',  'BIGINT');
        SET @sRoomRid   = @pFilterXML.value('(Filter/@pRoomRid)[1]',   'BIGINT');
        SET @sEventRid  = @pFilterXML.value('(Filter/@pEventRid)[1]',  'BIGINT');
        SET @sStartDate = @pFilterXML.value('(Filter/@pStartDate)[1]', 'DATE');
        SET @sEndDate   = @pFilterXML.value('(Filter/@pEndDate)[1]',   'DATE');
    END;

    SET @sDeptCd = NULLIF(@sDeptCd, '');
    SET @sRegionCd = NULLIF(@sRegionCd, '');
    SET @sHotelType = NULLIF(@sHotelType, ''); -- NULL: 全部酒店  HA：有設房額  NA：沒設房額  LH：本館  EH：外館
    SET @sHotelRid = IIF(@sHotelRid <= 0 , NULL,  @sHotelRid);
    SET @sRoomRid = IIF(@sRoomRid <= 0 , NULL,  @sRoomRid);
    SET @sEventRid = IIF(@sEventRid <= 0, NULL, @sEventRid);
    SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

    -- 把日期範圍轉換成每一天
    IF @sStartDate IS NOT NULL AND @sEndDate IS NOT NULL
    BEGIN
        SET @sDay = DATEDIFF(DAY, @sStartDate, @sEndDate);
        INSERT INTO @vDay ( wDate )
        SELECT wDate = DATEADD(DAY, number, @sStartDate)
        FROM master.dbo.spt_values
        WHERE type = 'P' AND number <= @sDay ;
    END;

    -- 部門、日期有設置房額的酒店（值為0等於沒設置有房額）
    SELECT
        d.wDate,
        hr.wHotelRid
    INTO #vHasAllotmentHotel
    FROM @vDay AS d
    INNER JOIN dbo.mHotelRoom AS hr ON 1 = 1
    INNER JOIN dbo.mHotel AS h ON h.RowID = hr.wHotelRid AND hr.wStatus = 'A' 
    LEFT JOIN dbo.eAllotmentHotelDaily AS ad ON ad.wRoomRid = hr.RowID AND ad.wDate = d.wDate AND ad.wStatus = 'A'
    LEFT JOIN dbo.mAllotmentGroup AS ag ON ag.RowID = ad.wAllotmentGroupRid AND ag.wDept = @sDeptCd -- AND ag.wStatus = 'A'
    WHERE (ad.RowId IS NULL OR (ad.RowId IS NOT NULL AND ag.RowID IS NOT NULL))
    GROUP BY d.wDate, hr.wHotelRid
    HAVING ISNULL(SUM(ad.wAllotmentQty), 0) > 0
    OPTION(RECOMPILE);

    -- 所有酒店，所有房額總數
    SELECT
        d.wDate,
        wAllotmentQty = ISNULL(SUM(ad.wAllotmentQty), 0)
    INTO #vAllotmentHotel
    FROM @vDay AS d
    INNER JOIN dbo.mHotelRoom AS hr ON 1 = 1
    INNER JOIN dbo.mHotel AS h ON h.RowID = hr.wHotelRid AND hr.wStatus = 'A' 
    LEFT JOIN dbo.eAllotmentHotelDaily AS ad ON ad.wRoomRid = hr.RowID AND ad.wDate = d.wDate AND ad.wStatus = 'A'
    LEFT JOIN dbo.mAllotmentGroup AS ag ON ag.RowID = ad.wAllotmentGroupRid AND ag.wDept = @sDeptCd -- AND ag.wStatus = 'A'
    WHERE (ad.RowId IS NULL OR (ad.RowId IS NOT NULL AND ag.RowID IS NOT NULL))
        AND (@sRegionCd IS NULL OR @sRegionCd = h.wRegion)
        AND (@sHotelRid IS NULL OR @sHotelRid = hr.wHotelRid)
        AND (@sRoomRid IS NULL OR @sRoomRid = hr.RowID)
        AND (@sHotelType IS NULL
              OR (@sHotelType = 'HA' AND ad.RowId IS NOT NULL)
              OR (@sHotelType = 'NA' AND ad.RowId IS NULL)
              OR (@sHotelType = 'LH' AND h.wIsBase = '1')
              OR (@sHotelType = 'EH' AND h.wIsBase <> '1')
        )
    GROUP BY d.wDate
    OPTION (RECOMPILE);

    -- 所有酒店，需要房額總數
    SELECT
        d.wDate,
        wRequestQty = SUM(dr.wBigBedQty + dr.wTwinBedQty + dr.wSuiteRoom1Qty + dr.wSuiteRoom2Qty + dr.wSuiteRoom3Qty)
    INTO #vRequestHotel
    FROM @vDay AS d
    INNER JOIN dbo.eDeptRespRoom AS dr WITH(NOLOCK) ON 1 = 1
    INNER JOIN dbo.eDeptReqRoom AS r WITH(NOLOCK) ON r.RowID = dr.wDeptReqRoomRid
    LEFT JOIN dbo.mHotel AS h ON h.RowID = dr.wHotelRid
    LEFT JOIN #vHasAllotmentHotel AS ah ON ah.wHotelRid = dr.wHotelRid AND ah.wDate = d.wDate
    WHERE dr.wStatus = 'A' AND r.wStatus = 'A' AND dr.wRepStatus IN ('P', 'C' ) AND dr.wDeptStatus NOT IN ('RQ', 'CS_RQ')
        AND (dr.wStartDate <= d.wDate AND d.wDate < dr.wEndDate)
        AND (@sEventRid IS NULL OR @sEventRid = r.wEventRid) -- Filter特別事件，只計算特別事件當天的需求總數
        AND (@sRegionCd IS NULL OR @sRegionCd = h.wRegion)
        AND (@sHotelRid IS NULL OR @sHotelRid = dr.wHotelRid)
        AND (@sRoomRid IS NULL OR @sRoomRid = dr.wRoomRid)
        AND (@sDeptCd IS NULL OR @sDeptCd = r.wRequestDepartment)
        AND (@sHotelType IS NULL
            OR (@sHotelType = 'HA' AND ah.wHotelRid IS NOT NULL)
            OR (@sHotelType = 'NA' AND ah.wHotelRid IS NULL)
            OR (@sHotelType = 'LH' AND h.wIsBase = '1')
            OR (@sHotelType = 'EH' AND h.wIsBase <> '1')
        )
    GROUP BY d.wDate
    OPTION (RECOMPILE);

    -- 所有酒店，完成房額總數
    SELECT
        d.wDate,
        wCompletedQty = SUM(dr.wBigBedQty + dr.wTwinBedQty + dr.wSuiteRoom1Qty + dr.wSuiteRoom2Qty + dr.wSuiteRoom3Qty)
    INTO #vCompleteHotel
    FROM @vDay AS d
    LEFT JOIN dbo.eDeptRespRoom AS dr WITH(NOLOCK) ON 1 = 1
    LEFT JOIN dbo.eDeptReqRoom AS r WITH(NOLOCK) ON r.RowID = dr.wDeptReqRoomRid
    LEFT JOIN dbo.mHotel AS h ON h.RowID = dr.wHotelRid
    LEFT JOIN #vHasAllotmentHotel AS ah ON ah.wHotelRid = dr.wHotelRid AND ah.wDate = d.wDate
    WHERE dr.wStatus = 'A' AND r.wStatus = 'A' AND dr.wRepStatus = 'C'
        AND (dr.wStartDate <= d.wDate AND d.wDate < dr.wEndDate)
        AND (@sEventRid IS NULL OR @sEventRid = r.wEventRid) -- Filter特別事件，只計算特別事件當天的完成總數
        AND (@sRegionCd IS NULL OR @sRegionCd = h.wRegion)
        AND (@sHotelRid IS NULL OR @sHotelRid = dr.wHotelRid)
        AND (@sRoomRid IS NULL OR @sRoomRid = dr.wRoomRid)
        AND (@sDeptCd IS NULL OR @sDeptCd = r.wRequestDepartment)
        AND (@sHotelType IS NULL
            OR (@sHotelType = 'HA' AND ah.wHotelRid IS NOT NULL)
            OR (@sHotelType = 'NA' AND ah.wHotelRid IS NULL)
            OR (@sHotelType = 'LH' AND h.wIsBase = '1')
            OR (@sHotelType = 'EH' AND h.wIsBase <> '1')
        )
    GROUP BY d.wDate
    OPTION (RECOMPILE);

    -- 所有酒店，排隊房間總數
    SELECT
        d.wDate,
        wQueueQty = SUM(dr.wBigBedQty + dr.wTwinBedQty + dr.wSuiteRoom1Qty + dr.wSuiteRoom2Qty + dr.wSuiteRoom3Qty)
    INTO #vQueueHotel
    FROM @vDay AS d
    LEFT JOIN dbo.eDeptRespRoom AS dr WITH(NOLOCK) ON 1 = 1
    LEFT JOIN dbo.eDeptReqRoom AS r WITH(NOLOCK) ON r.RowID = dr.wDeptReqRoomRid
    LEFT JOIN dbo.mHotel AS h ON h.RowID = dr.wHotelRid
    LEFT JOIN #vHasAllotmentHotel AS ah ON ah.wHotelRid = dr.wHotelRid AND ah.wDate = d.wDate
    WHERE dr.wStatus = 'A' AND r.wStatus = 'A' AND dr.wRepStatus = 'P' AND dr.wDeptStatus IN ('RQ', 'CS_RQ')
        AND (dr.wStartDate <= d.wDate AND d.wDate < dr.wEndDate)
        AND (@sEventRid IS NULL OR @sEventRid = r.wEventRid) -- Filter特別事件，只計算特別事件當天的完成總數
        AND (@sRegionCd IS NULL OR @sRegionCd = h.wRegion)
        AND (@sHotelRid IS NULL OR @sHotelRid = dr.wHotelRid)
        AND (@sRoomRid IS NULL OR @sRoomRid = dr.wRoomRid)
        AND (@sDeptCd IS NULL OR @sDeptCd = r.wRequestDepartment)
        AND (@sHotelType IS NULL
            OR (@sHotelType = 'HA' AND ah.wHotelRid IS NOT NULL)
            OR (@sHotelType = 'NA' AND ah.wHotelRid IS NULL)
            OR (@sHotelType = 'LH' AND h.wIsBase = '1')
            OR (@sHotelType = 'EH' AND h.wIsBase <> '1')
        )
    GROUP BY d.wDate
    OPTION (RECOMPILE);

    -- 未處理酒店需求
    SELECT
        d.wDate,
        wNewRequestQty = COUNT(1)
    INTO #vNewRequestHotel
    FROM @vDay AS d
    LEFT JOIN dbo.eDeptReqRoom AS r WITH(NOLOCK) ON 1 = 1
    LEFT JOIN dbo.mHotel AS h ON h.RowID = r.wHotelRid
    LEFT JOIN #vHasAllotmentHotel AS ah ON ah.wHotelRid = r.wHotelRid AND ah.wDate = d.wDate
    WHERE r.wStatus = 'A' AND r.wIsNewReqRoom = 'Y'
        AND (r.wStartDate = d.wDate)
        AND (@sEventRid IS NULL OR @sEventRid = r.wEventRid) -- Filter特別事件，只計算特別事件當天的完成總數
        AND (@sRegionCd IS NULL OR @sRegionCd = h.wRegion)
        AND (@sHotelRid IS NULL OR @sHotelRid = r.wHotelRid)
        AND (@sRoomRid IS NULL OR @sRoomRid = r.wRoomRid)
        AND (@sDeptCd IS NULL OR @sDeptCd = r.wRequestDepartment)
        AND (@sHotelType IS NULL
            OR (@sHotelType = 'HA' AND ah.wHotelRid IS NOT NULL)
            OR (@sHotelType = 'NA' AND ah.wHotelRid IS NULL)
            OR (@sHotelType = 'LH' AND h.wIsBase = '1')
            OR (@sHotelType = 'EH' AND h.wIsBase <> '1')
        )
    GROUP BY d.wDate
    OPTION(RECOMPILE);

    SELECT
        wDate          = d.wDate,
        wAllotmentQty  = ISNULL(ah.wAllotmentQty , 0),
        wRequestQty    = ISNULL(rh.wRequestQty, 0),
        wCompletedQty  = ISNULL(ch.wCompletedQty, 0),
        wQueueQty      = ISNULL(qh.wQueueQty, 0),
        wNewRequestQty = ISNULL(nrh.wNewRequestQty, 0)
    FROM @vDay AS d
    LEFT JOIN #vAllotmentHotel AS ah ON ah.wDate = d.wDate
    LEFT JOIN #vRequestHotel AS rh ON rh.wDate = d.wDate
    LEFT JOIN #vCompleteHotel AS ch ON ch.wDate = d.wDate
    LEFT JOIN #vQueueHotel AS qh ON qh.wDate = d.wDate
    LEFT JOIN #vNewRequestHotel AS nrh ON nrh.wDate = d.wDate;

    IF OBJECT_ID('tempdb..#vAllotmentHotel') IS NOT NULL
        DROP TABLE #vAllotmentHotel;

    IF OBJECT_ID('tempdb..#vRequestHotel') IS NOT NULL
        DROP TABLE #vRequestHotel;

    IF OBJECT_ID('tempdb..#vCompleteHotel') IS NOT NULL
        DROP TABLE #vCompleteHotel;

    IF OBJECT_ID('tempdb..#vQueueHotel') IS NOT NULL
        DROP TABLE #vQueueHotel;

    IF OBJECT_ID('tempdb..#vNewRequestHotel') IS NOT NULL
        DROP TABLE #vNewRequestHotel;

    IF OBJECT_ID('tempdb..#vHasAllotmentHotel') IS NOT NULL
        DROP TABLE #vHasAllotmentHotel;
END;