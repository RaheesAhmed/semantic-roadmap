
CREATE PROCEDURE [spq].[GetDeptReqRoomLog]
	@pRowID BIGINT
AS
BEGIN
    SET NOCOUNT ON;	  
	
    SELECT 
        RowID, 
        wAgentCodeIn, 
        wRemark, 
        wRemarkDt = FORMAT(wRemarkDt, 'yyyy-MM-dd HH:mm:ss'), 
        wStatus, 
        wCrtBy, 
        wCrtDt, 
        wUpdBy, 
        wUpdDt
    FROM dbo.eDeptReqRoomLog
	WHERE @pRowID = RowID                                                 
END;