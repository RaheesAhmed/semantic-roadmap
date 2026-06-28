CREATE PROC [spq].[GetDeptReqRoomSummary]
    @pFilterXML XML
AS
    BEGIN
        SET NOCOUNT ON;

        --------------------dbml------------------------
        --DECLARE @vResult TABLE (
        --    wUnFollowedQty  INT NOT NULL,
        --    wUnCompletedQty INT NOT NULL,
        --    wUnGetKeyQty    INT NOT NULL
        --);

        --SELECT * FROM @vResult;
        ------------------END dbml----------------------

        -- Result
        DECLARE @vUnFollowedQty INT,
                @vUnCompletedQty INT,
                @vUnGetKeyQty    INT;

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
                @pApplyStaffRid     BIGINT,
                @pDeptStatus        VARCHAR(20),
                @pHotelRefNo        VARCHAR(30),
                @pDeptReqRoomRid    BIGINT,
                @pIsNewOnly         CHAR(1),
                @pIsHightlyAgent    CHAR(1);

        
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
                @pIsNewOnly         = T.tmp.value('@pIsNewOnly',          'CHAR(1)'),
                @pIsHightlyAgent    = T.tmp.value('@pIsHightlyAgent',     'CHAR(1)')
        FROM @pFilterXML.nodes('Filter') T(tmp);
        
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

        CREATE TABLE #vDeptReqRoom ( RowID BIGINT PRIMARY KEY(RowID) );

        -- 2019-05-17：OP#28681，日期、酒店以細單作為搜索，不要大單
        -----------------------------------------------------------------------------
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
        -----------------------------------------------------------------------------

        SET @vUnFollowedQty = (
            SELECT COUNT(DISTINCT dr.RowID)
            FROM #vDeptReqRoom vdr
            INNER JOIN dbo.eDeptReqRoom dr WITH(NOLOCK) ON dr.RowID = vdr.RowID
            INNER JOIN dbo.eDeptRespRoom drr WITH(NOLOCK) ON drr.wDeptReqRoomRid = dr.RowID
            LEFT JOIN RollsMary.dbo.mUsr uu WITH(NOLOCK) ON uu.RowID = dr.wStaffFollowedRid
            WHERE drr.wRepStatus = 'P'
                AND drr.wDeptStatus = 'RA'
                AND uu.RowID IS NULL
        );

        SET @vUnCompletedQty = (
            SELECT COUNT(DISTINCT dr.RowID)
            FROM #vDeptReqRoom vdr
            INNER JOIN dbo.eDeptReqRoom dr WITH(NOLOCK) ON dr.RowID = vdr.RowID
            INNER JOIN dbo.eDeptRespRoom drr WITH(NOLOCK) ON drr.wDeptReqRoomRid = dr.RowID
            LEFT JOIN RollsMary.dbo.mUsr uu WITH(NOLOCK) ON uu.RowID = dr.wStaffFollowedRid
            WHERE drr.wRepStatus = 'P'
                AND uu.RowID IS NOT NULL
        );

        SET @vUnGetKeyQty = (
            SELECT COUNT(DISTINCT dr.RowID)
            FROM #vDeptReqRoom vdr
            INNER JOIN dbo.eDeptReqRoom dr WITH(NOLOCK) ON dr.RowID = vdr.RowID
            INNER JOIN dbo.eDeptRespRoom drr WITH(NOLOCK) ON drr.wDeptReqRoomRid = dr.RowID
            LEFT JOIN RollsMary.dbo.mUsr uu WITH(NOLOCK) ON uu.RowID = dr.wStaffFollowedRid
            WHERE drr.wRepStatus = 'C'
                AND drr.wDeptStatus = 'CS_AH'
        );

        -- return result
        SELECT wUnFollowedQty = ISNULL(@vUnFollowedQty, 0), wUnCompletedQty = ISNULL(@vUnCompletedQty, 0), wUnGetKeyQty = ISNULL(@vUnGetKeyQty, 0);

        IF OBJECT_ID('tempdb..#vDeptReqRoom') IS NOT NULL
            DROP TABLE #vDeptReqRoom;
    END