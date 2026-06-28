
CREATE PROCEDURE [spq].[GetActionAffectedTableLog]
AS
BEGIN
    SET NOCOUNT ON;	  	
				
    IF @@trancount = 0
        SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
    SELECT 
		aatl.wActionSp, 
		aatl.wActionType, 
		aatl.wNonceToken, 
		aatl.wRefTableName, 
		aatl.wRefRid, 
		aatl.wType, 
		aatl.wCrtDt
	FROM dbo.eActionAffectedTableLog aatl;                                              
END;