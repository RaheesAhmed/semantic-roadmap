CREATE PROCEDURE [spq].[GetComplaintUserLst] (
	  @pLangCd VARCHAR(30)
)
AS
BEGIN
	SET NOCOUNT ON;
	IF @@TRANCOUNT = 0
		SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

	SELECT 
		u.RowID, u.wUsrId, wName = CASE WHEN @pLangCd = 'zh-TW' THEN u.wCName ELSE u.wName END, u.wDept
	FROM
		RollsMary.dbo.mUsr u
	WHERE
		u.wStatus = 'ACTIVE'
		
END