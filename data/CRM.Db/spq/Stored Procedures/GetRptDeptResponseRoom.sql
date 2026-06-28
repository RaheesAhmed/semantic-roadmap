
CREATE PROCEDURE [spq].[GetRptDeptResponseRoom]
    @pXMLDeptReqRoom XML,
    @pLangCd VARCHAR(10) = 'zh-TW'
AS
BEGIN
    SET NOCOUNT ON;

    SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

    ----------------------------------預訂需求----------------------------------------
    CREATE TABLE #vDeptReqRoom ( RowID BIGINT PRIMARY KEY );
    IF @pXMLDeptReqRoom IS NOT NULL
    BEGIN
        INSERT INTO #vDeptReqRoom(RowID)
        SELECT DISTINCT tmp.RowID FROM (
            SELECT RowID = T.tmp.value('@RowID', 'BIGINT')
            FROM @pXMLDeptReqRoom.nodes('DataSet/DeptReqRoom') T(tmp)
        ) tmp WHERE tmp.RowID > 0;
    END;
    ----------------------------------------------------------------------------------

    ------------------------------------預訂狀態------------------------------------------
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
    WHERE wType = 'DEPTROOM_RESPONSE_STATUS' AND wLangCd = @pLangCd;
    ------------------------------------END 預訂狀態------------------------------------------

    ------------------------------------部門狀態----------------------------------------------
    DECLARE @vDeptStatus TABLE (
        wStatus VARCHAR(20),
        wStatusName NVARCHAR(50),
        PRIMARY KEY(wStatus)
    );
    INSERT INTO @vDeptStatus (wStatus , wStatusName)
    SELECT wCode, wTitle 
    FROM dbo.mLookUp 
    WHERE wType = 'DEPTROOM_PROCESS_STATUS' 
        AND wLangCd = @pLangCd;
    ----------------------------------END 部門狀態--------------------------------------------

    ------------------------------------部門-----------------------------------------------
    DECLARE @vDept TABLE(
        wCode VARCHAR(30) PRIMARY KEY,
        wName NVARCHAR(50)
    );
    INSERT INTO @vDept(
        wCode, 
        wName
    )
    SELECT 
        wCode, 
        wTitle
    FROM dbo.mLookUp
    WHERE wType = 'DEPTREQROOM_DEPARMENT' 
        AND wLangCd = @pLangCd
        AND wCanSelect = 'Y';
    ------------------------------------END 部門--------------------------------------------------
    
    SELECT
        req.RowID,
        req.wRequestNo,
        wDeptRespRoomRid = rep.RowID,
        rep.wBigBedQty,
        rep.wTwinBedQty,
        rep.wSuiteRoom1Qty,
        rep.wSuiteRoom2Qty,
        rep.wSuiteRoom3Qty,
        rep.wDayOfStay,
        rep.wStartDate,
        rep.wEndDate,
        rep.wRemark,
        rep.wTotalAmount,
        wAgentCodeIn = ma.wAgentCodeIn,
        wAgentCode_Display = ma.wAgentCode_Display,
        wAgentCodeName = ma.wCName,
        wAgentIdentity = N'', --vai.wAgentIdentityName,
        wHotelName = h.wName,
        wRoomName = hr.wName,
        wIsApproved = IIF(rep.wIsApproved = 'Y', N'是', N'否'),
        wRepStatus = sm.wStatusName,    -- 需求狀態
        wDeptStatus = ds.wStatusName,   -- 部門狀態
        wFollowedDept = dept.wName,
        wFollowedUser = fu.wCName,
        wFollowedUserTel = fu.wPrivateTel, -- 跟進人電話
        wApplyUser = au.wCName,
        wApplyUserTel = au.wPrivateTel -- 要求人電話
    INTO #vResult
    FROM #vDeptReqRoom dr
    INNER JOIN dbo.eDeptReqRoom req WITH(NOLOCK) ON req.RowID = dr.RowID
    INNER JOIN dbo.eDeptRespRoom rep WITH(NOLOCK) ON rep.wDeptReqRoomRid = req.RowID
    INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = req.wAgentCodeIn
    LEFT JOIN dbo.mHotel h ON h.RowID = rep.wHotelRid 
    LEFT JOIN dbo.mHotelRoom hr ON hr.RowID = rep.wRoomRid
    LEFT JOIN RollsMary.dbo.mUsr fu ON fu.RowID = req.wStaffFollowedRid
    LEFT JOIN RollsMary.dbo.mUsr au ON au.RowID = req.wApplyStaffRid
    LEFT JOIN @vStatusMap sm ON sm.wStatus = rep.wRepStatus
    LEFT JOIN @vDeptStatus ds ON ds.wStatus = rep.wDeptStatus
    LEFT JOIN @vDept dept ON dept.wCode = req.wDeptFollowedCode
    WHERE req.wStatus = 'A'
        AND rep.wStatus = 'A'
    ORDER BY req.wRequestNo DESC;

    -- 2019-02-25：OP#25033，房價要在簡選時顯示最UPDATE的房價(CS確定後不可再UPDATE)
    DECLARE @sRecCount      INT ,
            @sRuningIndex   INT,
            @pRowID         BIGINT,
            @pHotelRoomRid  BIGINT,
            @pStartDate     DATE,
            @pEndDate       DATE,
            @sPerRoomAmount  NUMERIC(18, 4);

    CREATE TABLE #vDeptRespRoom(RowNum INT, wDeptRespRoomRid BIGINT PRIMARY KEY, wTotalRoomQty INT, wTotalAmount NUMERIC(18, 4), wRoomRid BIGINT );
    
    CREATE TABLE #vHotelRoomDaily(wRoomRid BIGINT, wDate DATE, wRoomPrice NUMERIC(18, 4), wBreakfastPrice NUMERIC(18, 4), wRoomCost NUMERIC(18, 4), wCurrCode VARCHAR(6))

    INSERT INTO #vDeptRespRoom(RowNum, wDeptRespRoomRid, wTotalRoomQty, wRoomRid)
    SELECT RowNum = ROW_NUMBER() OVER (ORDER BY r.wDeptRespRoomRid),
           r.wDeptRespRoomRid, 
           wTotalRoomQty = drr.wBigBedQty + drr.wTwinBedQty +  drr.wSuiteRoom1Qty + drr.wSuiteRoom2Qty + drr.wSuiteRoom3Qty ,
           wRoomRid = drr.wRoomRid
    FROM #vResult r
    INNER JOIN dbo.eDeptRespRoom drr WITH(NOLOCK) ON drr.RowID = r.wDeptRespRoomRid
    WHERE drr.wRepStatus = 'P'
        AND drr.wRoomRid > 0;
    --WHERE wDeptStatus IN ('CB', 'RA', 'CS_RQ', 'CS_RU', 'RU');

    SET @sRuningIndex = 1;
    SET @sRecCount = (SELECT COUNT(1) FROM #vDeptRespRoom);
    
    WHILE @sRuningIndex <= @sRecCount
    BEGIN
        SELECT @pHotelRoomRid = drr.wRoomRid,
               @pStartDate = r.wStartDate,
               @pEndDate = r.wEndDate
        FROM #vDeptRespRoom drr
        INNER JOIN #vResult r ON r.wDeptRespRoomRid = drr.wDeptRespRoomRid
        WHERE RowNum = @sRuningIndex;

        INSERT INTO #vHotelRoomDaily EXEC spq.GetDeptReqRoomHotelDailyLst @pHotelRoomRid, @pStartDate, @pEndDate;

        SET @sPerRoomAmount = (SELECT SUM(wRoomPrice + wBreakfastPrice) FROM #vHotelRoomDaily);

        UPDATE #vDeptRespRoom SET wTotalAmount = ISNULL(@sPerRoomAmount, 0) * ISNULL(wTotalRoomQty, 0) WHERE RowNum = @sRuningIndex;

        DELETE FROM #vHotelRoomDaily;

        SET @sRuningIndex = @sRuningIndex + 1;
    END;

    UPDATE r
    SET r.wTotalAmount = drr.wTotalAmount
    FROM #vResult r
    INNER JOIN #vDeptRespRoom drr ON drr.wDeptRespRoomRid = r.wDeptRespRoomRid

    SELECT * FROM #vResult;

    IF OBJECT_ID('tempdb..#vDeptReqRoom') IS NOT NULL   
        DROP TABLE #vDeptReqRoom;

    IF OBJECT_ID('tempdb..#vDeptRespRoom') IS NOT NULL
        DROP TABLE #vDeptRespRoom;

    IF OBJECT_ID('tempdb..#vHotelRoomDaily') IS NOT NULL
        DROP TABLE #vHotelRoomDaily;

    IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
        DROP TABLE #vResult;
END;