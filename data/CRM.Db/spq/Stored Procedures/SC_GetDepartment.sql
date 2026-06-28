CREATE PROCEDURE  [spq].[SC_GetDepartment]
(	
	/*
	SC API 
	2.2 Get RollsMary Department	
	*/
	-- exec [spq].[SC_GetDepartment] '' , 'zh-TW'	

	@pDeptCode	NVARCHAR(20),
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
		wCode,
		CASE WHEN @pLangCd = 'en-gb' THEN wEName ELSE wCName END as wName,
		wSeqNo			
	FROM RollsMary.dbo.mDepartment
	WHERE (ISNULL(@pDeptCode,'')='' OR wCode =@pDeptCode) and wActive='A' AND wUserLineGrp = '' and wIsRealDept = 'Y'	
	ORDER BY wCode
END