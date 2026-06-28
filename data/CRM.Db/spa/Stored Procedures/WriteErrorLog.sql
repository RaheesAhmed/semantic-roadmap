-- =============================================
-- Author:          ACS
-- CREATE date: 2011-12-29
-- Description:     Insert ErrorMsg to EventLog Table
-- =============================================
CREATE PROCEDURE [spa].[WriteErrorLog]
	/*
		select top 100 * from Rollex_Sync.dbo.eErrorLog2 order by wCurDateTime desc
		exec spa.WriteErrorLog 10, 10, N'測試1', N'測試2',0,0
	*/
	@pMainCompNo int,
	@pCompNo int,
    @pLogCode     nvarchar(50)='',  -- Name of stored procedure or predined event code
    @pLogInfo     nvarchar(MAX)='', -- User define log message
    @pRtnCode     int = 0 output,
    @pErrMsg nvarchar(2000) = '' Output
AS

DECLARE
	@sDbName AS 		VARCHAR(100),
    @sSql AS			NVARCHAR(MAX)
    
SELECT @sDbName = db_name();

Begin Try
	declare @vRowNo bigint
     -- SET NOCOUNT ON added to prevent extra result sets from
	Set Nocount On;
	set @pRtnCode = 0; 
	-- Insert statements for procedure here
	Set @pErrMsg =    '<ERR PROC: ' + error_procedure() +'>' + char(13) + char(10) 
				+ '<LINE:' + cast(error_line() as varchar(10)) + '>' + char(13) + char(10) 
				+ '<MSG:' + substring(error_message(), 0, 1500) + '>'
	
    SET @sSql = 
    	'INSERT INTO ' + @sDbName + '_Log.dbo.eErrorLog (wCompNo,wCurDateTime, wFormID, wError) 
    	VALUES (' + 
        	--CAST (ISNULL(@pMainCompNo,0) AS VARCHAR(100)) + ', ' +
            CAST (ISNULL(@pCompNo,0) AS VARCHAR(100)) + ', ' +
            'GETDATE(), ' +
            'N'+'''' + ISNULL(@pLogCode,'') + ''', ' + 
            'N'+'''' + REPLACE(ISNULL(@pErrMsg + char(13) + char(10),''),'''','''''') + REPLACE(ISNULL(@pLogInfo + char(13) + char(10),''),'''','''''') + ''')'
	--PRINT (@sSql)  
    EXECUTE(@sSql)
	--exec dbo.spaGetRowID 10, 'eErrorLog', 1, @vRowNo output
	/*
	insert into dbo.eErrorLog2 (wMainCompNo, wCompNo,wCurDateTime, wFormID, wError)
		values (@pMainCompNo, @pCompNo, getdate(), @pLogCode, isnull(@pErrMsg + char(13) + char(10),'') + @pLogInfo)
    */
	Return 0
     
End Try
Begin Catch
     Set @pRtnCode = -1
     RaisError(@pErrMsg, 10, 1) With NoWait;  -- Write The Error Message in The Windows Application Event Log
End Catch