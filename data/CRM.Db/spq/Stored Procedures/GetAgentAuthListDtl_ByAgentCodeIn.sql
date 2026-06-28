CREATE PROCEDURE [spq].[GetAgentAuthListDtl_ByAgentCodeIn] 
(
	@pAgentCodeIn nvarchar(20),
	@pwLangCd varchar(10) = 'en-GB'
)
AS
BEGIN
	SET NOCOUNT ON

	Select 
		wAgentCodeIn,
		wAgentCode,
		CASE WHEN @pwLangCd = 'en-GB' THEN wEName ELSE wCName END AS wCName,
		wSex,
		wTel 
	FROM 
	RollsMary.dbo.mAgent 
	where wAgentCodeIn = @pAgentCodeIn
END