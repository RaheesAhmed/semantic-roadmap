CREATE PROCEDURE [spq].[GetOwnerListByAgentCode] 
(
	@pAgentCode nvarchar(20) = NULL,
	@pwLangCd varchar(10) = 'en-GB'
)
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT Distinct wLvlAgentCodeIn,mAgentLevel.wAgentLevel,
	CASE WHEN @pwLangCd = 'en-GB' THEN wEName ELSE wCName END AS wCName
	FROM RollsMary.dbo.mAgentLevel 
	INNER JOIN RollsMary.dbo.mAgent ON mAgent.wAgentCodeIn = mAgentLevel.wLvlAgentCodeIn
	WHERE (mAgentLevel.wAgentCodeIn=@pAgentCode OR @pAgentCode IS NULL) AND mAgentLevel.wExpireYearMth='' 
	-- Below line is commented for testing as most of the agent codes don't have data for wAuthIdentity='Auth'  
	--AND mAgent.wAuthIdentity='Auth'  
	ORDER BY mAgentLevel.wAgentLevel,wLvlAgentCodeIn
END