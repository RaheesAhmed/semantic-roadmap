CREATE PROCEDURE [spq].[GetDeptRoomRequestSummaryLst]
    @pFilterXML XML,
    @pPageSize INT,
    @pPageNum INT,
    @pLangCd VARCHAR(10) = 'zh-TW'
AS
BEGIN  
	SET NOCOUNT ON;

    ------------------dbml---------------------
    --DECLARE @tResult AS TABLE (
    --    wHotelRid       BIGINT NOT NULL,
    --    wHotelCd        VARCHAR(20),
    --    wHotelName      NVARCHAR(100),
    --    wRegionCd       VARCHAR(20),
    --    wRoomRid        BIGINT,
    --    wRoomCd         VARCHAR(30),
    --    wRoomName       NVARCHAR(100),
    --    wAllotmentQty   INT NOT NULL,
    --    wRequestQty     INT NOT NULL,
    --    wCompletedQty   INT NOT NULL,
    --    wQueueQty       INT NOT NULL,
    --    wRecordCount    INT NOT NULL
    --);

    --SELECT * FROM @tResult
    ----------------End dbml-------------------

    DECLARE @sDeptCd VARCHAR(20);
    DECLARE @sRegionCd VARCHAR(20);
    DECLARE @sHotelType VARCHAR(10);
    DECLARE @sHotelRid BIGINT;
    DECLARE @sEventRid BIGINT;
    DECLARE @sDate DATE;

    IF @pFilterXML IS NOT NULL
    BEGIN
        SET @sDeptCd    = @pFilterXML.value('(Filter/@pDeptCd)[1]',    'VARCHAR(20)');
        SET @sRegionCd  = @pFilterXML.value('(Filter/@pRegionCd)[1]',  'VARCHAR(20)');
        SET @sHotelType = @pFilterXML.value('(Filter/@pHotelType)[1]', 'VARCHAR(10)');
        SET @sHotelRid  = @pFilterXML.value('(Filter/@pHotelRid)[1]',  'BIGINT');
        SET @sEventRid  = @pFilterXML.value('(Filter/@pEventRid)[1]',  'BIGINT');
        SET @sDate      = @pFilterXML.value('(Filter/@pDate)[1]',      'DATE');
    END;

    SET @sDeptCd    = NULLIF(@sDeptCd, '');
    SET @sRegionCd  = NULLIF(@sRegionCd, '');
    SET @sHotelType = NULLIF(@sHotelType, ''); -- NULL: 全部酒店  HA：有設房額  NA：沒設房額  LH：本館  EH：外館
    SET @sHotelRid  = IIF(@sHotelRid <= 0 , NULL,  @sHotelRid);
    SET @sEventRid  = IIF(@sEventRid <= 0, NULL, @sEventRid); -- 只用來計算特別事件房間的需求量、完成總數，不Filter過濾分頁
    SET @sDate      = ISNULL(@sDate, CAST(GETDATE() AS DATE));
    SET @pPageSize  = IIF(ISNULL(@pPageSize, 0) <= 0, 20, @pPageSize );
    SET @pPageNum   = IIF(ISNULL(@pPageNum, 0) <= 0, 1, @pPageNum);
    SET @pLangCd    = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

    CREATE TABLE #tResult (
        wHotelRid       BIGINT,
        wHotelCd        VARCHAR(20),
        wHotelName      NVARCHAR(100),
        wRegionCd       VARCHAR(20),
        wRoomRid        BIGINT,
        wRoomCd         VARCHAR(30),
        wRoomName       NVARCHAR(100),
        wAllotmentQty   INT,
        wRequestQty     INT,
        wCompletedQty    INT,
        wQueueQty       INT,
        wRecordCount    INT
    );

    -- 部門、日期有設置房額的酒店（值為0等於沒設置有房額）
    SELECT 
        hr.wHotelRid
    INTO #tHasAllotmentHotel
    FROM dbo.mHotelRoom AS hr 
    INNER JOIN dbo.mHotel AS h ON h.RowID = hr.wHotelRid AND hr.wStatus = 'A' 
    LEFT JOIN dbo.eAllotmentHotelDaily AS ad ON ad.wRoomRid = hr.RowID AND ad.wDate = @sDate AND ad.wStatus = 'A'
    LEFT JOIN dbo.mAllotmentGroup AS ag ON ag.RowID = ad.wAllotmentGroupRid AND ag.wDept = @sDeptCd -- AND ag.wStatus = 'A' -- 歷史記錄
    WHERE (ad.RowId IS NULL OR (ad.RowId IS NOT NULL AND ag.RowID IS NOT NULL))
    GROUP BY hr.wHotelRid
    HAVING ISNULL(SUM(ad.wAllotmentQty), 0) > 0
    OPTION (RECOMPILE);

    WITH tHotel AS (
        SELECT
            wHotelRid = h.RowID,
            wHotelCd = h.wCode,
            wHotelName = h.wName,
            wRegionCd = h.wRegion
        FROM dbo.mHotel AS h
        LEFT JOIN #tHasAllotmentHotel AS ah ON ah.wHotelRid = h.RowID
        WHERE h.wStatus = 'A'
            AND (@sRegionCd IS NULL OR @sRegionCd = h.wRegion)
            AND (@sHotelRid IS NULL OR @sHotelRid = h.RowID)
            AND (@sHotelType IS NULL
              OR (@sHotelType = 'HA' AND ah.wHotelRid IS NOT NULL)
              OR (@sHotelType = 'NA' AND ah.wHotelRid IS NULL)
              OR (@sHotelType = 'LH' AND h.wIsBase = '1')
              OR (@sHotelType = 'EH' AND h.wIsBase <> '1')
            )
    ),
    tCount AS (
        SELECT wRecordCount = COUNT(1) FROM tHotel
    )

    SELECT
        wHotelRid,
        wHotelCd,
        wHotelName,
        wRegionCd,
        wRecordCount
    INTO #tHotel
    FROM tHotel, tCount
    ORDER BY wHotelRid
    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	FETCH NEXT @pPageSize ROWS ONLY
    OPTION (RECOMPILE);

    -- 如果沒有指定酒店，返回【全部酒店】的Record， 此句要放在#tHotel之後（要取記錄總數量）
    IF(@sHotelRid IS NULL)
    BEGIN
        DECLARE @sRecordCount   INT;
        DECLARE @sAllotmentQty  INT;
        DECLARE @sRequestQty    INT;
        DECLARE @sCompleteQty   INT;
        DECLARE @sQueueQty      INT;

        -- 酒店總數
        SELECT TOP(1) @sRecordCount = wRecordCount FROM #tHotel;

        -- 所有酒店，所有房額總數
        SELECT @sAllotmentQty = ISNULL(SUM(ad.wAllotmentQty), 0)
        FROM dbo.mHotelRoom AS hr 
        INNER JOIN dbo.mHotel AS h ON h.RowID = hr.wHotelRid AND hr.wStatus = 'A' 
        LEFT JOIN dbo.eAllotmentHotelDaily AS ad ON ad.wRoomRid = hr.RowID AND ad.wDate = @sDate AND ad.wStatus = 'A'
        LEFT JOIN dbo.mAllotmentGroup AS ag ON ag.RowID = ad.wAllotmentGroupRid AND ag.wDept = @sDeptCd -- AND ag.wStatus = 'A'
        WHERE (ad.RowId IS NULL OR (ad.RowId IS NOT NULL AND ag.RowID IS NOT NULL))
            AND (@sRegionCd IS NULL OR @sRegionCd = h.wRegion)
            AND (@sHotelType IS NULL
              OR (@sHotelType = 'HA' AND ad.RowId IS NOT NULL)
              OR (@sHotelType = 'NA' AND ad.RowId IS NULL)
              OR (@sHotelType = 'LH' AND h.wIsBase = '1')
              OR (@sHotelType = 'EH' AND h.wIsBase <> '1')
            )
        OPTION (RECOMPILE);

        -- 所有酒店，需要房額總數
        SELECT @sRequestQty = SUM(dr.wBigBedQty + dr.wTwinBedQty + dr.wSuiteRoom1Qty + dr.wSuiteRoom2Qty + dr.wSuiteRoom3Qty)
        FROM dbo.eDeptRespRoom AS dr WITH(NOLOCK)
        INNER JOIN dbo.eDeptReqRoom AS r WITH(NOLOCK) ON r.RowID = dr.wDeptReqRoomRid
        LEFT JOIN dbo.mHotel AS h ON h.RowID = dr.wHotelRid
        LEFT JOIN #tHasAllotmentHotel AS ah ON ah.wHotelRid = dr.wHotelRid
        WHERE dr.wStatus = 'A' AND r.wStatus = 'A' AND dr.wRepStatus IN ('P', 'C' ) AND dr.wDeptStatus NOT IN ('RQ', 'CS_RQ')
            AND (dr.wStartDate <= @sDate AND @sDate < dr.wEndDate)
            AND (@sEventRid IS NULL OR @sEventRid = r.wEventRid) -- Filter特別事件，只計算特別事件當天的需求總數
            AND (@sRegionCd IS NULL OR @sRegionCd = h.wRegion)
            AND (@sDeptCd IS NULL OR @sDeptCd = r.wRequestDepartment)
            AND (@sHotelType IS NULL
              OR (@sHotelType = 'HA' AND ah.wHotelRid IS NOT NULL)
              OR (@sHotelType = 'NA' AND ah.wHotelRid IS NULL)
              OR (@sHotelType = 'LH' AND h.wIsBase = '1')
              OR (@sHotelType = 'EH' AND h.wIsBase <> '1')
            )
        OPTION (RECOMPILE);

        -- 所有酒店，完成房額總數
        SELECT @sCompleteQty = SUM(dr.wBigBedQty + dr.wTwinBedQty + dr.wSuiteRoom1Qty + dr.wSuiteRoom2Qty + dr.wSuiteRoom3Qty)
        FROM dbo.eDeptRespRoom AS dr WITH(NOLOCK)
        INNER JOIN dbo.eDeptReqRoom AS r WITH(NOLOCK) ON r.RowID = dr.wDeptReqRoomRid
        LEFT JOIN dbo.mHotel AS h ON h.RowID = dr.wHotelRid
        LEFT JOIN #tHasAllotmentHotel AS ah ON ah.wHotelRid = dr.wHotelRid
        WHERE dr.wStatus = 'A' AND r.wStatus = 'A' AND dr.wRepStatus = 'C'
            AND (dr.wStartDate <= @sDate AND @sDate < dr.wEndDate)
            AND (@sEventRid IS NULL OR @sEventRid = r.wEventRid) -- Filter特別事件，只計算特別事件當天的完成總數
            AND (@sRegionCd IS NULL OR @sRegionCd = h.wRegion)
            AND (@sDeptCd IS NULL OR @sDeptCd = r.wRequestDepartment)
            AND (@sHotelType IS NULL
              OR (@sHotelType = 'HA' AND ah.wHotelRid IS NOT NULL)
              OR (@sHotelType = 'NA' AND ah.wHotelRid IS NULL)
              OR (@sHotelType = 'LH' AND h.wIsBase = '1')
              OR (@sHotelType = 'EH' AND h.wIsBase <> '1')
            )
        OPTION (RECOMPILE);

        -- 所有酒店，排隊房額總數
        SELECT @sQueueQty = SUM(dr.wBigBedQty + dr.wTwinBedQty + dr.wSuiteRoom1Qty + dr.wSuiteRoom2Qty + dr.wSuiteRoom3Qty)
        FROM dbo.eDeptRespRoom AS dr WITH(NOLOCK)
        INNER JOIN dbo.eDeptReqRoom AS r WITH(NOLOCK) ON r.RowID = dr.wDeptReqRoomRid
        LEFT JOIN dbo.mHotel AS h ON h.RowID = dr.wHotelRid
        LEFT JOIN #tHasAllotmentHotel AS ah ON ah.wHotelRid = dr.wHotelRid
        WHERE dr.wStatus = 'A' AND r.wStatus = 'A' AND dr.wRepStatus = 'P' AND dr.wDeptStatus IN ('RQ', 'CS_RQ')
            AND (dr.wStartDate <= @sDate AND @sDate < dr.wEndDate)
            AND (@sEventRid IS NULL OR @sEventRid = r.wEventRid) -- Filter特別事件，只計算特別事件當天的完成總數
            AND (@sRegionCd IS NULL OR @sRegionCd = h.wRegion)
            AND (@sDeptCd IS NULL OR @sDeptCd = r.wRequestDepartment)
            AND (@sHotelType IS NULL
              OR (@sHotelType = 'HA' AND ah.wHotelRid IS NOT NULL)
              OR (@sHotelType = 'NA' AND ah.wHotelRid IS NULL)
              OR (@sHotelType = 'LH' AND h.wIsBase = '1')
              OR (@sHotelType = 'EH' AND h.wIsBase <> '1')
            )
        OPTION (RECOMPILE);

        INSERT INTO #tResult (
            wHotelRid,
            wHotelCd,
            wHotelName,
            wRegionCd,
            wRoomRid,
            wRoomCd,
            wRoomName,
            wAllotmentQty,
            wRequestQty,
            wCompletedQty,
            wQueueQty,
            wRecordCount
       )
       SELECT
            wHotelRid     = -1,
            wHotelCd      = '',
            wHotelName    = N'全部酒店',
            wRegionCd     = '',
            wRoomRid      = -1,
            wRoomCd       = '',
            wRoomName     = N'',
            wAllotmentQty = ISNULL(@sAllotmentQty, 0),
            wRequestQty   = ISNULL(@sRequestQty,   0),
            wCompletedQty  = ISNULL(@sCompleteQty,  0),
            wQueueQty     = ISNULL(@sQueueQty,     0),
            wRecordCount  = ISNULL(@sRecordCount,  0);
    END;

    -- 房間總配額數量（區分房型，不區分房名稱）
    SELECT
        wHotelRid = hr.wHotelRid,
        wRoomRid = hr.RowID,
        wRoomCd = hr.wCode,
        wRoomName = hr.wName,
        wAllotmentQty = SUM(IIF((ad.RowId IS NULL OR (ad.RowId IS NOT NULL AND ag.RowID IS NOT NULL)), ISNULL(ad.wAllotmentQty, 0), 0)) -- 如果房間每日房間配置非空，房額類型也不能為空（如果值參@sDeptCd IS NULL， 就會導致每日配置不為空，房額類型為空，此時會取到其他部門的房額）
    INTO #tAllotmentHotel
    FROM dbo.mHotelRoom AS hr
    INNER JOIN #tHotel AS h ON h.wHotelRid = hr.wHotelRid AND hr.wStatus = 'A'
    LEFT JOIN dbo.eAllotmentHotelDaily AS ad ON ad.wRoomRid = hr.RowID AND ad.wDate = @sDate AND ad.wStatus = 'A' -- 房間類型不管有沒有停用，都要Select出來，只是房額數量=0
    LEFT JOIN dbo.mAllotmentGroup AS ag ON ag.RowID = ad.wAllotmentGroupRid AND ag.wDept = @sDeptCd --AND ag.wStatus = 'A'
    GROUP BY hr.wHotelRid, hr.RowID, hr.wCode, hr.wName
    OPTION (RECOMPILE);

    -- 需求數量
    SELECT
        dr.wHotelRid,
        dr.wRoomRid,
        wRequestQty = SUM(dr.wBigBedQty + dr.wTwinBedQty + dr.wSuiteRoom1Qty + dr.wSuiteRoom2Qty + dr.wSuiteRoom3Qty)
    INTO #tRequestHotel
    FROM dbo.eDeptRespRoom AS dr WITH(NOLOCK)
    INNER JOIN dbo.eDeptReqRoom AS r WITH(NOLOCK) ON r.RowID = dr.wDeptReqRoomRid
    INNER JOIN #tHotel AS h ON h.wHotelRid = dr.wHotelRid
    WHERE dr.wStatus = 'A' AND r.wStatus = 'A' AND dr.wRepStatus IN ('P', 'C')
        AND (dr.wStartDate <= @sDate AND @sDate < dr.wEndDate)
        AND (@sEventRid IS NULL OR @sEventRid = r.wEventRid) -- Filter特別事件，只計算特別事件當天的需求總數
        AND (@sDeptCd IS NULL OR @sDeptCd = r.wRequestDepartment)
    GROUP BY dr.wHotelRid, dr.wRoomRid
    OPTION (RECOMPILE);
    
    -- 完成數量
    SELECT 
        dr.wHotelRid,
        dr.wRoomRid,
        wCompletedQty = SUM(dr.wBigBedQty + dr.wTwinBedQty + dr.wSuiteRoom1Qty + dr.wSuiteRoom2Qty + dr.wSuiteRoom3Qty)
    INTO #tCompleteHotel
    FROM dbo.eDeptRespRoom AS dr WITH(NOLOCK)
    INNER JOIN dbo.eDeptReqRoom AS r WITH(NOLOCK) ON r.RowID = dr.wDeptReqRoomRid
    INNER JOIN #tHotel AS h ON h.wHotelRid = dr.wHotelRid
    WHERE dr.wStatus = 'A' AND r.wStatus = 'A' AND dr.wRepStatus = 'C'
        AND (dr.wStartDate <= @sDate  AND @sDate < dr.wEndDate)
        AND (@sEventRid IS NULL OR @sEventRid = r.wEventRid) -- Filter特別事件，只計算特別事件當天的完成總數
        AND (@sDeptCd IS NULL OR @sDeptCd = r.wRequestDepartment)
    GROUP BY dr.wHotelRid, dr.wRoomRid
    OPTION (RECOMPILE);

    -- 排隊數量
    SELECT 
        dr.wHotelRid,
        dr.wRoomRid,
        wQueueQty = SUM(dr.wBigBedQty + dr.wTwinBedQty + dr.wSuiteRoom1Qty + dr.wSuiteRoom2Qty + dr.wSuiteRoom3Qty)
    INTO #tQueueHotel
    FROM dbo.eDeptRespRoom AS dr WITH(NOLOCK)
    INNER JOIN dbo.eDeptReqRoom AS r WITH(NOLOCK) ON r.RowID = dr.wDeptReqRoomRid
    INNER JOIN #tHotel AS h ON h.wHotelRid = dr.wHotelRid
    WHERE dr.wStatus = 'A' AND r.wStatus = 'A' AND dr.wDeptStatus = 'CS_RQ'
        AND (dr.wStartDate <= @sDate  AND @sDate < dr.wEndDate)
        AND (@sEventRid IS NULL OR @sEventRid = r.wEventRid) -- Filter特別事件，只計算特別事件當天的完成總數
        AND (@sDeptCd IS NULL OR @sDeptCd = r.wRequestDepartment)
    GROUP BY dr.wHotelRid, dr.wRoomRid
    OPTION (RECOMPILE);
   
   -- 設置有房額的的酒店
   INSERT INTO #tResult (
        wHotelRid,
        wHotelCd,
        wHotelName,
        wRegionCd,
        wRoomRid,
        wRoomCd,
        wRoomName,
        wAllotmentQty,
        wRequestQty,
        wCompletedQty,
        wQueueQty,
        wRecordCount
   )
    SELECT
        h.wHotelRid,
        h.wHotelCd,
        h.wHotelName,
        h.wRegionCd,
        ISNULL(ta.wRoomRid, 0),
        ISNULL(ta.wRoomCd, ''),
        ISNULL(ta.wRoomName, ''),
        ISNULL(ta.wAllotmentQty, 0),
        ISNULL(rh.wRequestQty, 0),
        ISNULL(ch.wCompletedQty, 0),
        ISNULL(qh.wQueueQty, 0),
        ISNULL(h.wRecordCount, 0)
    FROM #tHotel AS h
    LEFT JOIN #tAllotmentHotel AS ta ON ta.wHotelRid = h.wHotelRid
    LEFT JOIN #tRequestHotel AS rh ON rh.wHotelRid = h.wHotelRid AND rh.wRoomRid = ta.wRoomRid AND rh.wRoomRid > 0
    LEFT JOIN #tCompleteHotel AS ch ON ch.wHotelRid = h.wHotelRid AND ch.wRoomRid = ta.wRoomRid AND ch.wRoomRid > 0
    LEFT JOIN #tQueueHotel AS qh ON qh.wHotelRid = h.wHotelRid AND qh.wRoomRid = ta.wRoomRid AND qh.wRoomRid > 0
    OPTION(RECOMPILE);

    -- 需求沒有選擇房間類型，此時數量只加在酒店總數上，不會顯示在房間類型,此時會出現酒店下所有房間類型下的總數和不等於酒店總數
    -- 沒有房間類型的酒店也可以下訂單
    INSERT INTO #tResult (
        wHotelRid,
        wHotelCd,
        wHotelName,
        wRegionCd,
        wRoomRid,
        wRoomCd,
        wRoomName,
        wAllotmentQty,
        wRequestQty,
        wCompletedQty,
        wQueueQty,
        wRecordCount
   )
    SELECT
        h.wHotelRid,
        h.wHotelCd,
        h.wHotelName,
        h.wRegionCd,
        wRoomRid = 0,
        wRoomCd = '',
        wRoomName = '',
        wAllotmentQty = 0,
        ISNULL(rh.wRequestQty, 0),
        ISNULL(ch.wCompletedQty, 0),
        ISNULL(qh.wQueueQty, 0),
        ISNULL(h.wRecordCount, 0)
    FROM #tHotel AS h
    LEFT JOIN #tRequestHotel AS rh ON rh.wHotelRid = h.wHotelRid AND rh.wRoomRid <= 0
    LEFT JOIN #tCompleteHotel AS ch ON ch.wHotelRid = h.wHotelRid AND ch.wRoomRid <= 0
    LEFT JOIN #tQueueHotel AS qh ON qh.wHotelRid = h.wHotelRid AND qh.wRoomRid <= 0
    WHERE rh.wHotelRid IS NOT NULL OR ch.wHotelRid IS NOT NULl AND qh.wHotelRid IS NOT NULL
    OPTION(RECOMPILE);

    SELECT * FROM #tResult;

    IF OBJECT_ID('tempdb..#tHotel') IS NOT NULL
        DROP TABLE #tHotel;

    IF OBJECT_ID('tempdb..#tAllotmentHotel') IS NOT NULL
        DROP TABLE #tAllotmentHotel;

    IF OBJECT_ID('tempdb..#tRequestHotel') IS NOT NULL
        DROP TABLE #tRequestHotel;

    IF OBJECT_ID('tempdb..#tCompleteHotel') IS NOT NULL
        DROP TABLE #tCompleteHotel;

    IF OBJECT_ID('tempdb..#tQueueHotel') IS NOT NULL
        DROP TABLE #tQueueHotel;

    IF OBJECT_ID('tempdb..#tHasAllotmentHotel') IS NOT NULL
        DROP TABLE #tHasAllotmentHotel;

    IF OBJECT_ID('tempdb..#tResult') IS NOT NULL
        DROP TABLE #tResult;
END;