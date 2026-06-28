CREATE PROCEDURE [qa].[IsGetFirstResultObject] 
(
	/*
		DECLARE @sColumnCountRtn INT
		DECLARE @sErrMsgRtn NVARCHAR(MAX)
		EXEC [qa].[IsGetFirstResultObject] 'spq.GetAgentByAgentCode_UserControl', @pColumnCount= @sColumnCountRtn output, @pErrMsg= @sErrMsgRtn output
		SELECT @sColumnCountRtn, @sErrMsgRtn
	*/
	@pSpName			VARCHAR(100),
	@pColumnCount		INT = 0 OUTPUT,
	@pErrMsg			NVARCHAR(MAX) OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @sErrMsg NVARCHAR(MAX)
	DECLARE @sColumnCount INT
	SELECT Top 1 @sErrMsg = error_message FROM Rollsmary.sys.dm_exec_describe_first_result_set_for_object(OBJECT_ID(@pSpName), NULL) order by len(isnull(error_message,'')); 
	SELECT @sColumnCount = COUNT(*) FROM Rollsmary.sys.dm_exec_describe_first_result_set_for_object(OBJECT_ID(@pSpName), NULL);

	SET @pErrMsg = @sErrMsg
	SET @pColumnCount = @sColumnCount
END