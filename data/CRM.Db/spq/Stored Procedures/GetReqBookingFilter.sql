CREATE PROC [spq].[GetReqBookingFilter]
    @pUserRid   BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pUserRid = IIF(@pUserRid <= 0, NULL, @pUserRid);

        SELECT  wUserRid,
                wAgentCodeIn,
                wBookingType,
                wReqUser,
                wReqDeptCd,
                wReqStatus,
                wStartDate,
                wEndDate,
                wHotelRid
        FROM dbo.eReqBookingFilterLog
        WHERE @pUserRid = wUserRid;
    END