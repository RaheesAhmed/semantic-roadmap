
CREATE PROCEDURE [util].[CheckBookingInfo] (
	@pBookingRefNo		VARCHAR(30)	
)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT
		*
	FROM
		ebooking b
	INNER JOIN
		eBookingHotel bh ON b.RowID = bh.wBookingRid
	INNER JOIN
		eBookingRoom br ON bh.RowID = br.wHotelBookingRid
	INNER JOIN
		eHotelChange hc ON br.RowID = hc.wRoomBookingRid
	INNER JOIN
		mHotelRoom hr on br.wHotelRoomRid = hr.RowID
	WHERE
		b.wRefNo = @pBookingRefNo;
END