	
CREATE PROCEDURE [spq].[GetDeptResponseRoomLst]
    @pDeptReqRoomRid BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        dr.RowID,
        dr.wDeptReqRoomRid,
        dr.wHotelRid,
        dr.wRoomRid,
        dr.wBookingRid,
        dr.wBigBedQty,
        dr.wTwinBedQty,
        dr.wSuiteRoom1Qty,
        dr.wSuiteRoom2Qty,
        dr.wSuiteRoom3Qty,
        dr.wDayOfStay,
        dr.wStartDate ,
        dr.wEndDate,
        dr.wStatus,
        dr.wRepStatus,
        dr.wRemark,
        dr.wTotalAmount,
        dr.wIsApproved,
        dr.wDeptStatus,
        dr.wCrtDt,
        dr.wCrtBy,
        dr.wUpdDt,
        dr.wUpdBy,
        dr.wGUID,
        dr.wIsExtRoom,
        wHotelRefNo = eb.wRefNo,
        wHotelName = h.wName,
        wRoomName = r.wName,
        wRegionCd = h.wRegion
    INTO #vResult
    FROM dbo.eDeptRespRoom AS dr WITH(NOLOCK)
    LEFT JOIN dbo.mHotel AS h WITH(NOLOCK) ON dr.wHotelRid = h.RowID 
    LEFT JOIN dbo.mHotelRoom AS r WITH(NOLOCK) ON dr.wRoomRid = r.RowID
    LEFT JOIN dbo.eBooking AS eb WITH(NOLOCK) ON eb.RowID = dr.wBookingRid
    WHERE dr.wStatus = 'A'
        AND @pDeptReqRoomRid = dr.wDeptReqRoomRid;
    
    -- 2019-02-25：OP#25033，房價要在簡選時顯示最UPDATE的房價(CS確定後不可再UPDATE)
    DECLARE @sRecCount      INT ,
            @sRuningIndex   INT,
            @pRowID         BIGINT,
            @pHotelRoomRid  BIGINT,
            @pStartDate     DATE,
            @pEndDate       DATE,
            @sPerRoomAmount  NUMERIC(18, 4);

    CREATE TABLE #vDeptRespRoom(RowNum INT, RowID BIGINT PRIMARY KEY, wTotalRoomQty INT, wTotalAmount NUMERIC(18, 4) );
    
    CREATE TABLE #vHotelRoomDaily(wRoomRid BIGINT, wDate DATE, wRoomPrice NUMERIC(18, 4), wBreakfastPrice NUMERIC(18, 4), wRoomCost NUMERIC(18, 4), wCurrCode VARCHAR(6))

    INSERT INTO #vDeptRespRoom(RowNum, RowID, wTotalRoomQty)
    SELECT RowNum = ROW_NUMBER() OVER (ORDER BY RowID),
           RowID, 
           wTotalRoomQty = wBigBedQty + wTwinBedQty +  wSuiteRoom1Qty + wSuiteRoom2Qty + wSuiteRoom3Qty 
    FROM #vResult 
    WHERE wRepStatus = 'P'
        AND wRoomRid > 0;
    --WHERE wDeptStatus IN ('CB', 'RA', 'CS_RQ', 'CS_RU', 'RU');

    SET @sRuningIndex = 1;
    SET @sRecCount = (SELECT COUNT(1) FROM #vDeptRespRoom);
    
    WHILE @sRuningIndex <= @sRecCount
    BEGIN
        SELECT @pHotelRoomRid = r.wRoomRid,
               @pStartDate = r.wStartDate,
               @pEndDate = r.wEndDate
        FROM #vDeptRespRoom drr
        INNER JOIN #vResult r ON r.RowID = drr.RowID
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
    INNER JOIN #vDeptRespRoom drr ON drr.RowID = r.RowID

    SELECT * FROM #vResult ORDER BY wCrtDt DESC;

    IF OBJECT_ID('tempdb..#vDeptRespRoom') IS NOT NULL
        DROP TABLE #vDeptRespRoom;

    IF OBJECT_ID('tempdb..#vHotelRoomDaily') IS NOT NULL
        DROP TABLE #vHotelRoomDaily;

    IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
        DROP TABLE #vResult;
        
END;