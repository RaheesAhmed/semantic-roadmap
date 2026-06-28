
CREATE PROCEDURE [spq].[GetHotelRequestDtlByRid]
	@pRowID BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	IF @@trancount = 0
		SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

	SELECT
		hrd_t.RowID
	   ,hrd_t.wHotelRequestRid
	   ,hrd_t.wHotelCode
	   ,hrd_t.wLine
	   ,hrd_t.wCounterRid
	   ,hrd_t.wTotalProvideRoomQty
	   ,hrd_t.wIsReject
	   ,hrd_t.wSeqNo
	   ,hrd_t.wCrtDt
	   ,hrd_t.wCrtBy
	   ,hrd_t.wUpdDt
	   ,hrd_t.wUpdBy
	   ,hrd_t.wCrtByCounterRid
	   ,hrd_t.wPriority
	   ,hrd_t.wRemark
	   ,'N' AS RecordState
	FROM dbo.eHotelRequestDtl hrd_t
	WHERE @pRowID = hrd_t.RowID
END;