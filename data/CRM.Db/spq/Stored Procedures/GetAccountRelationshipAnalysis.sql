CREATE PROCEDURE [spq].[GetAccountRelationshipAnalysis] 
(
@pStatus char(1),
@pPageSize INT = 999,
@pPageNum INT = 1,
@pAccount NVARCHAR(200)='',
@pAccountId VARCHAR (100)='',
@pAccountCreatedDate DATE=NULL,
@pAgentCode_Old NVARCHAR(100)='',
@pLevel INT=NULL,
@pAccountType VARCHAR(30)=NULL,
@pAccountCategory VARCHAR(30)=NULL, -- AgentType
@pCreatedAccountLocation INT=NULL,
@pUplineAgent VARCHAR(30)=NULL
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	WITH tResult AS (
			SELECT
			ma.wAgentCode_Display,
			ma.wAgentCodeIn,
			ma.wAgentCode_Old,
			ma.wCreateDate,
			ma.wAccountType,
			ma.wAgentType,
			ma.wCompNo,
			ma.wUpLvlAgentCodeIn,
			ma.wStatus,
			ISNULL(mal.wAgentLevel,0) AS wAgentLevel,
			wIsShareholder = CASE WHEN (Select ISNULL(SUM(mab.wCapitalAmt + mab.wForeignCapitalAmt), 0) from RollsMary.dbo.mAgentBal mab Where mab.wAgentCodeIn = ma.wAgentCodeIn) > 0 THEN 'Y' ELSE 'N' END
		FROM 
		(SELECT * FROM RollsMary.dbo.mAgent (NOLOCK) 
			WHERE (@pAccount IS NULL OR @pAccount='' OR wAgentCodeIn=@pAccount)
			AND (@pAccountId IS NULL OR @pAccountId='' OR wAgentCodeIn=@pAccountId)
			AND (@pAgentCode_Old IS NULL OR @pAgentCode_Old='' OR wAgentCode_Old = @pAgentCode_Old)
			AND (@pAccountCreatedDate IS NULL OR CAST(wCreateDate AS DATE) = @pAccountCreatedDate)
			AND (@pLevel IS NULL OR @pLevel=0 OR wAgentLevel=@pLevel)
			AND (@pAccountType IS NULL OR @pAccountType='' OR wAccountType=@pAccountType)
			AND (@pAccountCategory IS NULL OR @pAccountCategory='' OR wAgentType=@pAccountCategory)
			AND (@pCreatedAccountLocation IS NULL OR @pCreatedAccountLocation=0 OR wCompNo=@pCreatedAccountLocation)
			AND (@pUplineAgent IS NULL OR @pUplineAgent='' OR wUpLvlAgentCodeIn=@pUplineAgent)
			AND (@pStatus IS NULL OR @pStatus='' OR wStatus=@pStatus)
		) AS MA
		INNER JOIN RollsMary.dbo.mAgentLevel mal ON mal.wLvlAgentCodeIn= ma.wAgentCodeIn
		INNER JOIN RollsMary.dbo.mAgentBal mab on mab.wAgentCodeIn = ma.wAgentCodeIn
	),tCount AS (
		SELECT wRecordCount = COUNT(*) FROM tResult
	)
	SELECT tResult.*, wRecordCount
		FROM tResult,tCount
		  ORDER BY wStatus
		  OFFSET @pPageSize * (@pPageNum - 1) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY;

END;