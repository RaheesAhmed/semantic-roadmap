CREATE PROC [spq].[GetDeptReqRoomHotelDailyLst]
    @pHotelRoomRid BIGINT,
    @pStartDate DATE,
    @pEndDate DATE
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pHotelRoomRid = ISNULL(IIF(@pHotelRoomRid <= 0, NULL, @pHotelRoomRid), 0);
        SET @pStartDate = ISNULL(@pStartDate, CAST(dbo.fnUTC8Now() AS DATE));
        SET @pEndDate = ISNULL(@pEndDate, @pStartDate);

        WITH tHotelRoomDaily AS (
            SELECT
                RowID = MAX(RowId)
            FROM dbo.eAllotmentHotelDaily
            WHERE @pHotelRoomRid = wRoomRid
                AND @pStartDate <= wDate
                AND wDate < @pEndDate
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

       SELECT * FROM tResult
    END;