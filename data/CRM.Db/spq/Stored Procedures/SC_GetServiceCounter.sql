CREATE PROCEDURE  [spq].[SC_GetServiceCounter]
(	
	/*
	SC API 
	2.1 Get Service Counter (CRM) 
	服務櫃台	
	*/
	-- exec [spq].[SC_GetServiceCounter] '' 	

	@pName		NVARCHAR(20),
	@pCode	INT = 0	 OUTPUT,
	@pMsg	NVARCHAR(200)='' OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT 
		RowID,
		wName,
		wSeqNo
	FROM dbo.mServiceCounter
	WHERE (ISNULL(@pName,'')='' OR wName =@pName) and wStatus='A'
			
END