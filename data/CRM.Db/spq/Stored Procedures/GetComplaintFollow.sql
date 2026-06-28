CREATE PROCEDURE [spq].[GetComplaintFollow]
	@pRowID BIGINT
AS
BEGIN
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	-- PRINT dbo.fnGetAllFieldNameInTable('eComplaintFollow', 'cf', 'N', 'N', 'N', '')
	SELECT
		cf.RowID, cf.wComplaintRid, cf.wTranDt, cf.wFollowBy, cf.wFollowDeptCd, cf.wContent, cf.wSolveDt, cf.wSolveContent, cf.wPreventContent, cf.wStatus, cf.wCrtDt, cf.wCrtBy, cf.wUpdDt, cf.wUpdBy
	FROM
		dbo.eComplaintFollow cf
	WHERE
		 cf.RowID = @pRowID
END