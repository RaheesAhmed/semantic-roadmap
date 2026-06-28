CREATE PROC spq.GetReqBookingQty
    @pUserRid BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

        SELECT wUserRid,
               wProgressQty
        FROM dbo.eReqBookingFilterLog WITH(NOLOCK)
        WHERE wUserRid = @pUserRid;
    END