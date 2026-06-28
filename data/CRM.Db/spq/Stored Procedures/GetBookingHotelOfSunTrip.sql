CREATE PROC spq.GetBookingHotelOfSunTrip
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sLastestCrtDt DATE = DATEADD(DAY, -31, CONVERT(DATE, dbo.fnUTC8Now()));

        SELECT bh.wBookingRid,
               eb.wRefNo
        FROM dbo.eBooking eb WITH(NOLOCK)
        INNER JOIN dbo.eBookingHotel bh WITH(NOLOCK) ON bh.wBookingRid = eb.RowID
        LEFT JOIN dbo.eDeptRespRoom drr WITH(NOLOCK) ON drr.wBookingRid = eb.RowID AND drr.wStatus = 'A' -- 如果已經設定關聯到其他訂務，不能再Select返回
        WHERE bh.wStatus = 'A'
            AND bh.wSource = 'SunTrip'
            AND bh.wCrtDt >= @sLastestCrtDt
            AND drr.RowID IS NULL;
    END