
CREATE PROCEDURE [spq].[GetHotelRequestNoForShare]
(
    @pHotelRequestRid BIGINT,
    @pHotelRequestDtlRid BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;
	
    SET @pHotelRequestRid = ISNULL(@pHotelRequestRid, 0);
    SET @pHotelRequestDtlRid = ISNULL(@pHotelRequestDtlRid, 0);

    SELECT
        wHotelRequestDtlRid = hrd.RowID,
        hrd.wHotelRequestRid,
        hr.wRequestNo
    FROM dbo.eHotelRequestDtl AS hrd
    INNER JOIN dbo.eHotelRequest AS hr ON hr.RowID = hrd.wHotelRequestRid
    WHERE (@pHotelRequestRid > 0 OR @pHotelRequestDtlRid > 0)
        AND (@pHotelRequestRid = 0 OR @pHotelRequestRid = hr.RowID)
        AND (@pHotelRequestDtlRid = 0 OR @pHotelRequestDtlRid = hrd.RowID)
END;