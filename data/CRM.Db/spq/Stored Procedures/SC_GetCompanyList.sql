CREATE PROCEDURE  [spq].[SC_GetCompanyList]
(	
	/*
	SC API 
	2.3 Get RollsMary Company List
	*/
	-- exec [spq].[SC_GetCompanyList]  'en-gb'	

	@pLangCd	VARCHAR(30)='zh-TW',
	@pCode		INT = 0	 OUTPUT,
	@pMsg		NVARCHAR(200)='' OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON
    IF @@trancount = 0
        SET TRANSACTION ISOLATION LEVEL SNAPSHOT;	
	
	select 
		wCompNo, 
		CASE WHEN @pLangCd = 'en-gb' THEN wEName ELSE wCName END AS wName,
		wSortSeq
	from RollsMary.dbo.mCompany where wStatus ='A'
	order by wSortSeq
END