CREATE PROC [spq].[GetDeptRoomWeekCalendarSummary]
    @pFilterXML XML,
    @pLandCd    VARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;

        ----------------------dbml--------------------
        --DECLARE @vResult TABLE (
        --    wType           VARCHAR(30) NOT NULL,
        --    wDate           DATE NOT NULL,
        --    RowID           BIGINT NOT NULL,
        --    wCode           VARCHAR(30) NOT NULL,
        --    wName           NVARCHAR(100) NOT NULL,
        --    wAllotmentQty   INT NOT NULL,
        --    wBookedQty      INT NOT NULL,
        --    wBalanceQty     INT NOT NULL,
        --    wPendingQty     INT NOT NULL,
        --    wUnCompletedQty INT NOT NULL,
        --    wSeqNo          INT NOT NULL
        --)
        
        --SELECT * FROM @vResult;
        --------------------END dbml------------------

        DECLARE @pDeptCd            VARCHAR(20),
                @pHotelRid          BIGINT,
                @pEventRid          BIGINT, -- 用來計算特別事件房間的需求量、完成總數
                @pRegion            VARCHAR(50),
                @pHotelStartDate    DATE,
                @pRoomStartDate     DATE;

        SELECT  @pDeptCd            = T.tmp.value('@pDeptCd',           'VARCHAR(20)'),
                @pHotelRid          = T.tmp.value('@pHotelRid',         'BIGINT'),
                @pEventRid          = T.tmp.value('@pEventRid',         'BIGINT'),
                @pRegion            = T.tmp.value('@pRegion',           'VARCHAR(50)'),
                @pHotelStartDate    = T.tmp.value('@pHotelStartDate',   'DATE'),
                @pRoomStartDate     = T.tmp.value('@pRoomStartDate',    'DATE')
        FROM @pFilterXML.nodes('Filter') T(tmp);

        SET @pDeptCd            = NULLIF(@pDeptCd, '');
        SET @pHotelRid          = IIF(@pHotelRid <= 0, NULL, @pHotelRid);
        SET @pEventRid          = IIF(@pEventRid <= 0, NULL, @pEventRid);
        SET @pRegion            = NULLIF(@pRegion, '');
        SET @pHotelStartDate    = ISNULL(@pHotelStartDate, CONVERT(DATE, dbo.fnUTC8Now()));
        SET @pRoomStartDate     = ISNULL(@pRoomStartDate, CONVERT(DATE, dbo.fnUTC8Now()));
        SET @pLandCd            = ISNULL(NULLIF(@pLandCd, ''), 'zh-TW');

        CREATE TABLE #vResult (
            wType           VARCHAR(30) NOT NULL,
            wDate           DATE NOT NULL,
            RowID           BIGINT NOT NULL,
            wCode           VARCHAR(30) NOT NULL,
            wName           NVARCHAR(100) NOT NULL,
            wAllotmentQty   INT NOT NULL,
            wBookedQty      INT NOT NULL,
            wBalanceQty     INT NOT NULL,
            wPendingQty     INT NOT NULL,
            wUnCompletedQty INT NOT NULL,
            wSeqNo          INT NOT NULL
        );

        -- 計算一個禮拜的日期
        DECLARE @vDay TABLE (wDate DATE PRIMARY KEY);

        -- 房數列表
        ------------------------------------------------------------------------------
        IF @pDeptCd IS NOT NULL AND @pHotelRid IS NOT NULL
        BEGIN
            -- 計算一個禮拜的日期
            DELETE FROM @vDay;
            INSERT INTO @vDay ( wDate )
            SELECT wDate = DATEADD(DAY, number, @pRoomStartDate)
            FROM master.dbo.spt_values
            WHERE type = 'P' AND number < 7 ;

            -- 酒店房間類型
            SELECT wHotelRid        = h.RowID,
                   wHotelRoomRid    = hr.RowID,
                   wRoomCd          = hr.wCode,
                   wRoomName        = hr.wName,
                   wRoomSeqNo       = hr.wSeqNo
            INTO #vHotelRoom
            FROM dbo.mHotel h
            INNER JOIN dbo.mHotelRoom hr ON hr.wHotelRid = h.RowID
            WHERE hr.wStatus = 'A'
                AND h.wStatus = 'A'
                AND h.RowID = @pHotelRid;
               
            -- 房間配額數量 + 額外房
            SELECT d.wDate,
                   hr.wHotelRid, 
                   hr.wHotelRoomRid,
                   wAllotmentQty = SUM(IIF((ad.RowId IS NULL OR (ad.RowId IS NOT NULL AND ag.RowID IS NOT NULL)), ISNULL(ad.wAllotmentQty + ad.wExtraQty, 0), 0)) -- 如果房間每日房間配置非空，房額類型也不能為空（如果值參@sDeptCd IS NULL， 就會導致每日配置不為空，房額類型為空，此時會取到其他部門的房額）
            INTO #vAllotmentRoom
            FROM @vDay d
            CROSS JOIN #vHotelRoom hr
            LEFT JOIN dbo.eAllotmentHotelDaily AS ad ON ad.wRoomRid = hr.wHotelRoomRid AND ad.wDate = d.wDate AND ad.wStatus = 'A'
            LEFT JOIN dbo.mAllotmentGroup AS ag ON ag.RowID = ad.wAllotmentGroupRid AND ag.wDept = @pDeptCd -- AND ag.wStatus = 'A' -- 歷史記錄，原來是有效的，用完后中止，此處不需要Check狀態
            GROUP BY d.wDate, hr.wHotelRid, hr.wHotelRoomRid
            OPTION (RECOMPILE);

            -- 已訂數量（需求狀態 = 已完成）
            -- 2019-03-11：已訂數 = 每日房間配置的已訂房數，不是需求“完成”的房數
            SELECT d.wDate,
                   hr.wHotelRid, 
                   hr.wHotelRoomRid,
                   wBookedQty = SUM(IIF((ad.RowId IS NULL OR (ad.RowId IS NOT NULL AND ag.RowID IS NOT NULL)), ISNULL(ad.wBookedQty, 0), 0)) -- 如果房間每日房間配置非空，房額類型也不能為空（如果值參@sDeptCd IS NULL， 就會導致每日配置不為空，房額類型為空，此時會取到其他部門的房額）
            INTO #vBookedRoom
            FROM @vDay d
            CROSS JOIN #vHotelRoom hr
            LEFT JOIN dbo.eAllotmentHotelDaily AS ad ON ad.wRoomRid = hr.wHotelRoomRid AND ad.wDate = d.wDate AND ad.wStatus = 'A'
            LEFT JOIN dbo.mAllotmentGroup AS ag ON ag.RowID = ad.wAllotmentGroupRid AND ag.wDept = @pDeptCd -- AND ag.wStatus = 'A' -- 歷史記錄，原來是有效的，用完后中止，此處不需要Check狀態
            GROUP BY d.wDate, hr.wHotelRid, hr.wHotelRoomRid
            OPTION (RECOMPILE);
            
            -- 待覆數量（需求狀態=處理中，部門狀態=CS確認，CS更正）
            SELECT d.wDate, 
                   hr.wHotelRid, 
                   hr.wHotelRoomRid,
                   wPendingQty = SUM(dr.wBigBedQty + dr.wTwinBedQty + dr.wSuiteRoom1Qty + dr.wSuiteRoom2Qty + dr.wSuiteRoom3Qty)
            INTO #vOnHoldRoom
            FROM @vDay d
            CROSS JOIN dbo.eDeptReqRoom r WITH(NOLOCK)
            INNER JOIN dbo.eDeptRespRoom dr WITH(NOLOCK) ON dr.wDeptReqRoomRid = r.RowID
            INNER JOIN #vHotelRoom hr ON hr.wHotelRid = dr.wHotelRid AND hr.wHotelRoomRid = dr.wRoomRid
            WHERE r.wStatus = 'A' AND dr.wStatus = 'A' AND dr.wRepStatus = 'P' AND dr.wDeptStatus IN ('CS_RC', 'CS_RU', 'CS_RA', 'CS_AH', 'RC')
                AND (dr.wStartDate <= d.wDate AND d.wDate < dr.wEndDate)
                AND (@pEventRid IS NULL OR @pEventRid = r.wEventRid) -- Filter特別事件，只計算特別事件當天的完成總數
                AND (@pDeptCd IS NULL OR @pDeptCd = r.wRequestDepartment)
            GROUP BY d.wDate, hr.wHotelRid, hr.wHotelRoomRid
            OPTION (RECOMPILE);

            -- 房間數量
            INSERT INTO #vResult
            SELECT wType            = 'HotelRoom',
                   wDate            = d.wDate,
                   RowID            = hr.wHotelRoomRid,
                   wCode            = hr.wRoomCd,
                   wName            = hr.wRoomName,
                   wAllotmentQty    = ISNULL(ar.wAllotmentQty, 0),
                   wBookedQty       = ISNULL(br.wBookedQty, 0),
                   wBalanceQty      = ISNULL(ar.wAllotmentQty, 0) - ISNULL(br.wBookedQty, 0),
                   wPendingQty      = ISNULL(ohr.wPendingQty, 0),
                   wUnCompletedQty  = 0,
                   wSeqNo           = hr.wRoomSeqNo
            FROM @vDay d
            CROSS JOIN #vHotelRoom hr
            LEFT JOIN #vAllotmentRoom ar ON ar.wDate = d.wDate AND ar.wHotelRid = hr.wHotelRid AND ar.wHotelRoomRid =  hr.wHotelRoomRid
            LEFT JOIN #vBookedRoom br ON br.wDate = d.wDate AND br.wHotelRid = hr.wHotelRid AND br.wHotelRoomRid =  hr.wHotelRoomRid
            LEFT JOIN #vOnHoldRoom ohr ON ohr.wDate = d.wDate AND ohr.wHotelRid = hr.wHotelRid AND ohr.wHotelRoomRid =  hr.wHotelRoomRid

            -- 所有房間數量匯總（界面第一列房間類型要用到）
            INSERT INTO #vResult
            SELECT wType            = 'HotelRoom',
                   wDate            = '0001-01-01',
                   RowID            = hr.wHotelRoomRid,
                   wCode            = hr.wRoomCd,
                   wName            = hr.wRoomName,
                   wAllotmentQty    = SUM(r.wAllotmentQty),
                   wBookedQty       = SUM(r.wBookedQty),
                   wBalanceQty      = SUM(r.wAllotmentQty - r.wBookedQty),
                   wPendingQty      = SUM(r.wPendingQty),
                   wUnCompletedQty  = 0,
                   wSeqNo           = hr.wRoomSeqNo
            FROM #vHotelRoom hr
            LEFT JOIN #vResult r ON r.RowID = hr.wHotelRoomRid AND r.wType = 'HotelRoom'
            GROUP BY hr.wHotelRoomRid, hr.wRoomCd, hr.wRoomName, hr.wRoomSeqNo;

            -- 刪除沒有房間配額的房間類型
            DELETE FROM #vResult WHERE wDate = '0001-01-01' AND wAllotmentQty = 0 AND wType = 'HotelRoom';
            -- 刪除6天都沒有房間配額房間類型
            DELETE vr 
            FROM #vResult vr
            LEFT JOIN #vResult r ON r.RowID = vr.RowID AND r.wDate = '0001-01-01' AND vr.wType = 'HotelRoom' AND r.wType = 'HotelRoom'
            WHERE r.RowID IS NULL AND vr.wType = 'HotelRoom';
        END
        ------------------------------------------------------------------------------

        IF @pDeptCd IS NOT NULL AND @pRegion IS NOT NULL
        BEGIN
            -- 計算一個禮拜的日期
            DELETE FROM @vDay;
            INSERT INTO @vDay ( wDate )
            SELECT wDate = DATEADD(DAY, number, @pHotelStartDate)
            FROM master.dbo.spt_values
            WHERE type = 'P' AND number < 7 ;

            -- 酒店房間類型
            SELECT wHotelRid     = h.RowID,
                   wHotelRoomRid = hr.RowID,
                   wHotelCd      = h.wCode,
                   wHotelName    = h.wName,
                   wHotelSeqNo   = h.wSeqNo
            INTO #vHotel
            FROM dbo.mHotel h
            INNER JOIN dbo.mHotelRoom hr ON hr.wHotelRid = h.RowID
            WHERE hr.wStatus = 'A'
                AND h.wStatus = 'A'
                AND h.wRegion = @pRegion;
               
            -- 房間配額數量 + 額外房
            SELECT d.wDate,
                   h.wHotelRid,
                   wAllotmentQty = SUM(IIF((ad.RowId IS NULL OR (ad.RowId IS NOT NULL AND ag.RowID IS NOT NULL)), ISNULL(ad.wAllotmentQty + ad.wExtraQty, 0), 0)) -- 如果房間每日房間配置非空，房額類型也不能為空（如果值參@sDeptCd IS NULL， 就會導致每日配置不為空，房額類型為空，此時會取到其他部門的房額）
            INTO #vAllotmentHotel
            FROM @vDay d
            CROSS JOIN #vHotel h
            LEFT JOIN dbo.eAllotmentHotelDaily AS ad ON ad.wRoomRid = h.wHotelRoomRid AND ad.wDate = d.wDate AND ad.wStatus = 'A'
            LEFT JOIN dbo.mAllotmentGroup AS ag ON ag.RowID = ad.wAllotmentGroupRid AND ag.wDept = @pDeptCd -- AND ag.wStatus = 'A' -- 歷史記錄，原來是有效的，用完后中止，此處不需要Check狀態
            GROUP BY d.wDate, h.wHotelRid
            OPTION (RECOMPILE);

            -- 已訂數量（需求狀態 = 已完成）
            -- 2019-03-11：已訂數 = 每日房間配置的已訂房數，不是需求“完成”的房數
            SELECT d.wDate,
                   h.wHotelRid,
                   wBookedQty = SUM(IIF((ad.RowId IS NULL OR (ad.RowId IS NOT NULL AND ag.RowID IS NOT NULL)), ISNULL(ad.wBookedQty, 0), 0)) -- 如果房間每日房間配置非空，房額類型也不能為空（如果值參@sDeptCd IS NULL， 就會導致每日配置不為空，房額類型為空，此時會取到其他部門的房額）
            INTO #vBookedHotel
            FROM @vDay d
            CROSS JOIN #vHotel h
            LEFT JOIN dbo.eAllotmentHotelDaily AS ad ON ad.wRoomRid = h.wHotelRoomRid AND ad.wDate = d.wDate AND ad.wStatus = 'A'
            LEFT JOIN dbo.mAllotmentGroup AS ag ON ag.RowID = ad.wAllotmentGroupRid AND ag.wDept = @pDeptCd -- AND ag.wStatus = 'A' -- 歷史記錄，原來是有效的，用完后中止，此處不需要Check狀態
            GROUP BY d.wDate, h.wHotelRid
            OPTION (RECOMPILE);
            
            -- 待覆數量（需求狀態=處理中，部門狀態=CS確認，CS更正）
            ;WITH tHotel AS (
                SELECT  wHotelRid
                FROM #vHotel 
                GROUP BY wHotelRid
            )

            SELECT d.wDate, 
                   h.wHotelRid,
                   wPendingQty = SUM(dr.wBigBedQty + dr.wTwinBedQty + dr.wSuiteRoom1Qty + dr.wSuiteRoom2Qty + dr.wSuiteRoom3Qty)
            INTO #vOnHoldHotel
            FROM @vDay d
            CROSS JOIN dbo.eDeptReqRoom r WITH(NOLOCK)
            INNER JOIN dbo.eDeptRespRoom dr WITH(NOLOCK) ON dr.wDeptReqRoomRid = r.RowID
            INNER JOIN tHotel h ON h.wHotelRid = dr.wHotelRid
            WHERE r.wStatus = 'A' AND dr.wStatus = 'A' AND dr.wRepStatus = 'P' AND dr.wDeptStatus IN ('CS_RC', 'CS_RU', 'CS_RA', 'CS_AH', 'RC')
                AND (dr.wStartDate <= d.wDate AND d.wDate < dr.wEndDate)
                AND (@pEventRid IS NULL OR @pEventRid = r.wEventRid) -- Filter特別事件，只計算特別事件當天的完成總數
                AND (@pDeptCd IS NULL OR @pDeptCd = r.wRequestDepartment)
            GROUP BY d.wDate, h.wHotelRid
            OPTION (RECOMPILE);

            -- 需求數量（需求狀態 = 處理中）
            ;WITH tHotel AS (
                SELECT  wHotelRid
                FROM #vHotel 
                GROUP BY wHotelRid
            )

            SELECT d.wDate, 
                   h.wHotelRid,
                   wUnCompletedQty = SUM(dr.wBigBedQty + dr.wTwinBedQty + dr.wSuiteRoom1Qty + dr.wSuiteRoom2Qty + dr.wSuiteRoom3Qty)
            INTO #vUnCompetedHotel
            FROM @vDay d
            CROSS JOIN dbo.eDeptReqRoom r WITH(NOLOCK)
            INNER JOIN dbo.eDeptRespRoom dr WITH(NOLOCK) ON dr.wDeptReqRoomRid = r.RowID
            INNER JOIN tHotel h ON h.wHotelRid = dr.wHotelRid
            WHERE r.wStatus = 'A' AND dr.wStatus = 'A' AND dr.wRepStatus = 'P'
                AND (dr.wStartDate <= d.wDate AND d.wDate < dr.wEndDate)
                AND (@pEventRid IS NULL OR @pEventRid = r.wEventRid) -- Filter特別事件，只計算特別事件當天的完成總數
                AND (@pDeptCd IS NULL OR @pDeptCd = r.wRequestDepartment)
            GROUP BY d.wDate, h.wHotelRid
            OPTION (RECOMPILE);

            ;WITH tHotel AS (
                SELECT  wHotelRid, 
                        wHotelCd, 
                        wHotelName,
                        wHotelSeqNo
                FROM #vHotel 
                GROUP BY wHotelRid, wHotelCd, wHotelName, wHotelSeqNo
            )
            -- 房間數量
            INSERT INTO #vResult
            SELECT wType            = 'Hotel',
                   wDate            = d.wDate,
                   RowID            = h.wHotelRid,
                   wCode            = h.wHotelCd,
                   wName            = h.wHotelName,
                   wAllotmentQty    = ISNULL(SUM(ah.wAllotmentQty), 0),
                   wBookedQty       = ISNULL(SUM(bh.wBookedQty), 0),
                   wBalanceQty      = ISNULL(SUM(ah.wAllotmentQty), 0) - ISNULL(SUM(bh.wBookedQty), 0),
                   wPendingQty      = ISNULL(SUM(ohh.wPendingQty), 0),
                   wUnCompletedQty  = ISNULL(SUM(uch.wUnCompletedQty), 0),
                   wSeqNo           = h.wHotelSeqNo
            FROM @vDay d
            CROSS JOIN tHotel h
            LEFT JOIN #vAllotmentHotel ah ON ah.wDate = d.wDate AND ah.wHotelRid = h.wHotelRid
            LEFT JOIN #vBookedHotel bh ON bh.wDate = d.wDate AND bh.wHotelRid = h.wHotelRid
            LEFT JOIN #vOnHoldHotel ohh ON ohh.wDate = d.wDate AND ohh.wHotelRid = h.wHotelRid
            LEFT JOIN #vUnCompetedHotel uch ON uch.wDate = d.wDate AND uch.wHotelRid = h.wHotelRid
            GROUP BY d.wDate, h.wHotelRid, h.wHotelCd, h.wHotelName, h.wHotelSeqNo;

            -- 所有酒店數量匯總（界面第一列房間類型要用到）
            INSERT INTO #vResult
            SELECT wType            = 'Hotel',
                   wDate            = '0001-01-01',
                   RowID            = h.wHotelRid,
                   wCode            = h.wHotelCd,
                   wName            = h.wHotelName,
                   wAllotmentQty    = SUM(r.wAllotmentQty),
                   wBookedQty       = SUM(r.wBookedQty),
                   wBalanceQty      = SUM(r.wAllotmentQty - r.wBookedQty),
                   wPendingQty      = SUM(r.wPendingQty),
                   wUnCompletedQty  = SUM(r.wUnCompletedQty),
                   wSeqNo           = h.wHotelSeqNo
            FROM #vHotel h
            LEFT JOIN #vResult r ON r.RowID = h.wHotelRid AND r.wType = 'Hotel'
            GROUP BY h.wHotelRid, h.wHotelCd, h.wHotelName, h.wHotelSeqNo;

            -- 刪除沒有房間配額的房間類型
            DELETE FROM #vResult WHERE wDate = '0001-01-01' AND wAllotmentQty = 0 AND wType = 'Hotel';
            -- 刪除6天都沒有房間配額房間類型
            DELETE vr 
            FROM #vResult vr
            LEFT JOIN #vResult r ON r.RowID = vr.RowID AND r.wDate = '0001-01-01'  AND vr.wType = 'Hotel' AND r.wType = 'Hotel'
            WHERE r.RowID IS NULL AND vr.wType = 'Hotel';
        END

        SELECT * FROM #vResult;

        IF OBJECT_ID('tempdb..#vAllotmentRoom') IS NOT NULL
            DROP TABLE #vAllotmentRoom;

        IF OBJECT_ID('tempdb..#vBookedRoom') IS NOT NULL
            DROP TABLE #vBookedRoom;

        IF OBJECT_ID('tempdb..#vOnHoldRoom') IS NOT NULL
            DROP TABLE #vOnHoldRoom;

        IF OBJECT_ID('tempdb..#vHotelRoom') IS NOT NULL 
            DROP TABLE #vHotelRoom;

        IF OBJECT_ID('tempdb..#vHotel') IS NOT NULL
            DROP TABLE #vHotel;

        IF OBJECT_ID('tempdb..#vAllotmentHotel') IS NOT NULL
            DROP TABLE #vAllotmentHotel;

        IF OBJECT_ID('tempdb..#vBookedHotel') IS NOT NULL
            DROP TABLE #vBookedHotel;

        IF OBJECT_ID('tempdb..#vOnHoldHotel') IS NOT NULL
            DROP TABLE #vOnHoldHotel;

        IF OBJECT_ID('tempdb..#vUnCompetedHotel') IS NOT NULL
            DROP TABLE #vUnCompetedHotel;

        IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
            DROP TABLE #vResult;
    END