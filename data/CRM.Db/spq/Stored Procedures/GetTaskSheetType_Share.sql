
CREATE PROCEDURE [spq].[GetTaskSheetType_Share]
	@pDepartmentCode VARCHAR(30),
	@pCode VARCHAR(30)
AS
BEGIN
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	-- PRINT dbo.fnGetAllFieldNameInTable('mTaskSheetType', 'tst', 'N', 'N', 'N', '')
	SELECT
		tst.wDepartmentCode, tst.wCode, tst.wParentCode, tst.wTitle, tst.wStatus, tst.wCrtDt, tst.wCrtBy, tst.wUpdDt, tst.wUpdBy
	FROM
		dbo.mTaskSheetType tst
	WHERE
		tst.wDepartmentCode = @pDepartmentCode
	AND
		tst.wCode = @pCode
		
END