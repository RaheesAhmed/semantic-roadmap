
CREATE PROCEDURE [spq].[CRM_GetUsrSMSGroupBySMSType]    
    @pType varchar(10) = '',
	@pCompNo int = 0, 
	@pSMSType varchar(50) = ''
AS
    BEGIN
        SET NOCOUNT ON;
				
           EXEC [RollsMary].[spq].[GetUsrSMSGroupBySMSType] @pType, @pCompNo, @pSMSType; 	 													      
        
    END;