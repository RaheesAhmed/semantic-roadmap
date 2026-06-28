

CREATE PROCEDURE [spq].[GetRoomBookingRefNoForShare]
(
    @pBookingRid BIGINT ,
    @pBookingRoomRid BIGINT
)
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pBookingRid = ISNULL(@pBookingRid, 0);
        SET @pBookingRoomRid = ISNULL(@pBookingRoomRid, 0);
		
        SELECT
            wBookingRoomRid = br.RowID,
            br.wBookingRid,
			eb.wRefNo
        FROM dbo.eBookingRoom AS br
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = br.wBookingRid
        WHERE br.wStatus = 'A'
            AND ( @pBookingRid > 0 OR @pBookingRoomRid > 0 )
            AND ( @pBookingRid <= 0 OR br.wBookingRid = @pBookingRid )
            AND ( @pBookingRoomRid <= 0 OR br.RowID = @pBookingRoomRid );
    END;