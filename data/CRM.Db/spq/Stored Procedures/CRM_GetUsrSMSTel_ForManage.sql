
CREATE PROCEDURE [spq].[CRM_GetUsrSMSTel_ForManage]    
    @pUserLineGrp nvarchar(10) = '',
	@pSMSType varchar(50) = '',
	@pLvlAgentCodeIn varchar(14) = '',
	@pCompNo int = 0
AS
    BEGIN
        SET NOCOUNT ON;
				
           EXEC [RollsMary].[spq].[GetUsrSMSTel_ForManage] @pUserLineGrp, @pSMSType, @pLvlAgentCodeIn,@pCompNo; 	 													      
        
    END;