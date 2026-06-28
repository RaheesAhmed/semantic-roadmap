CREATE PROCEDURE [spq].[GetRoomBookingRefNoForMarketing]
    @pBookingRid BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pBookingRid = ISNULL(@pBookingRid, 0);
		
        SELECT
            wBookingRoomRid = ISNULL(hc.wRoomBookingRid, br.RowID),
            wBookingRid = eb.RowID,
            eb.wRefNo
        FROM dbo.eBooking AS eb 
        LEFT JOIN dbo.eHotelChange AS hc ON hc.wBookingRid = eb.RowID
        LEFT JOIN dbo.eBookingRoom AS br ON br.wBookingRid = eb.RowID
        WHERE eb.RowID = @pBookingRid
    END;