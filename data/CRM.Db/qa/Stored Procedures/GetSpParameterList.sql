
CREATE PROCEDURE [qa].[GetSpParameterList] 
(
	/*
		EXEC [qa].[GetSpParameterList] 'spq.GetAgentByAgentCode_UserControl', ''
	*/
	@pSpName			VARCHAR(100),
	@pErrMsg			NVARCHAR(MAX) OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @sErrMsg NVARCHAR(MAX)
	
	SELECT object_id, parameter_id, system_type_id, is_nullable, name AS objectName
	FROM sys.parameters  
	WHERE object_id = OBJECT_ID(@pSpName)

	SET @pErrMsg = @sErrMsg
END