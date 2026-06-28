CREATE PROCEDURE [spq].[GetAgentAuthList_ByCName]
(
	@pCName nvarchar(30),
	@pType varchar(50),
	@pwLangCd varchar(10) = 'en-GB'
)
AS
BEGIN
	SET NOCOUNT ON

	Select 
		wAgentCodeIn,
		CASE WHEN @pwLangCd = 'en-GB' THEN wEName ELSE wCName END AS wCName,
		wSex,
		wTel 
	FROM 
	RollsMary.dbo.mAgent 
	where 
	wCName = @pCName and wType = @pType AND wStatus='A'
END