CREATE PROCEDURE  [spq].[SC_GetUserList]
(	
	/*
	SC API 
	2.3 Get RollsMary User List
	*/
	-- exec [spq].[SC_GetUserList] '32190' , 'zh-TW'	

	@pADAccount	NVARCHAR(20),
	@pLangCd	VARCHAR(30)='zh-TW',
	@pCode		INT = 0	 OUTPUT,
	@pMsg		NVARCHAR(200)='' OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON
    IF @@trancount = 0
        SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	
	SELECT
		RowID,
		CASE WHEN @pLangCd = 'en-gb' THEN wName ELSE wCName END AS wName,
		wADAccount, 
		wDept
	FROM RollsMary.dbo.mUsr 
	WHERE isnull(wADAccount, '')<>'' and wLineGrp ='' and wStatus ='ACTIVE' AND (ISNULL(@pADAccount, '')='' OR wADAccount = @pADAccount)
END