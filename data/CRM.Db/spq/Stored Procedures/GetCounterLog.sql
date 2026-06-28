CREATE PROCEDURE [spq].[GetCounterLog]
		@pRowId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	  	
	IF @@trancount = 0
		SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

	SELECT
		RowID
	   ,wCompNo
	   ,wDeptCd
	   ,wUserRid
	   ,wType
	   ,wRelateAgentCodeIn
	   ,wRelatePersonRid
	   ,wTitle
	   ,wContent
	   ,wDateTime
	   ,wIsImportant
	   ,wIsProcessed
	   ,wIsClosed
	   ,wStatus
	   ,wCrtDt
	   ,wCrtBy
	   ,wUpdDt
	   ,wUpdBy
	   ,wCounterRid
	FROM dbo.eCounterLog
	WHERE @pRowID = RowID
END;