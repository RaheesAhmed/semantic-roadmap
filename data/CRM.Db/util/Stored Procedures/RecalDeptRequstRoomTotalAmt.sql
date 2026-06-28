CREATE PROC [util].[RecalDeptRequstRoomTotalAmt]
AS
BEGIN
    DECLARE @sRowID BIGINT = 0 ,
            @sHotelRoomRid BIGINT,
            @sStartDate DATE,
            @sEndDate DATE,
            @sTotalAmount NUMERIC(18, 4) = 0;

    DECLARE sCURSOR CURSOR FOR SELECT RowID FROM dbo.eDeptReqRoom;
    OPEN sCURSOR;
    FETCH NEXT FROM sCURSOR INTO @sRowID;
    WHILE @@fetch_status = 0
    BEGIN
        SELECT
            @sHotelRoomRid = wRoomRid,
            @sStartDate = wStartDate,
            @sEndDate = wEndDate
        FROM dbo.eDeptReqRoom
        WHERE RowID = @sRowID;

        SET @sHotelRoomRid = ISNULL(IIF(@sHotelRoomRid <= 0, NULL, @sHotelRoomRid), 0);
        SET @sStartDate = ISNULL(@sStartDate, CAST(dbo.fnUTC8Now() AS DATE));
        SET @sEndDate = ISNULL(@sEndDate, @sStartDate);

        WITH tHotelRoomDaily AS (
            SELECT
                RowID = MAX(RowId)
            FROM dbo.eAllotmentHotelDaily
            WHERE @sHotelRoomRid = wRoomRid
                AND @sStartDate <= wDate
                AND wDate < @sEndDate
                AND wStatus = 'A'
            GROUP BY wDate, wRoomRid
        ),
        tResult AS (
            SELECT
                ahd.wRoomRid, 
                ahd.wDate,
                ahd.wRoomPrice,
                ahd.wBreakfastPrice,
                ahd.wRoomCost,
                ahd.wCurrCode
            FROM tHotelRoomDaily AS hrd
            INNER JOIN dbo.eAllotmentHotelDaily AS ahd ON ahd.RowId = hrd.RowID
        )

        SELECT @sTotalAmount = SUM(wRoomPrice + wBreakfastPrice) FROM tResult;
        
        UPDATE dbo.eDeptReqRoom SET wTotalAmt = ISNULL(@sTotalAmount, 0) * (wBigBedQty + wTwinBedQty + wSuiteRoom1Qty + wSuiteRoom2Qty + wSuiteRoom3Qty) WHERE RowID = @sRowID;
                 
        FETCH NEXT FROM sCURSOR INTO @sRowID;
    END;
    CLOSE sCURSOR;
    DEALLOCATE sCURSOR;
END;