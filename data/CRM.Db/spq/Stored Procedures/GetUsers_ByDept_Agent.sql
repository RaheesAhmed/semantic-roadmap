
CREATE PROCEDURE [spq].[GetUsers_ByDept_Agent]
(
	@pDept varchar(15),
	@pStatus varchar(10),
	@pLangCd varchar(10) = 'en-GB'
)
AS
BEGIN
	SET NOCOUNT ON

	SELECT 
		RowID, 
		CASE WHEN @pLangCd = 'en-GB' THEN wName ELSE wCName END AS wCName,
		wPrivateTel = '+' + wPrivateTelCountryCode + '-' +  wPrivateTel,
		wCName as ChName,
		wName as Ename
	FROM RollsMary.dbo.mUsr
	WHERE (ISNULL(@pStatus,'') = '' OR wStatus = @pStatus)
		AND (ISNULL(@pDept, '') = '' OR wDept = @pDept)
END