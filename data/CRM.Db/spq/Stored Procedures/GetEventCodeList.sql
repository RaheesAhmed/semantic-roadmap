 
CREATE PROCEDURE [spq].[GetEventCodeList] 
(  
	@pStatus Varchar (6),  
	@pLangCd Varchar(10) ='en-GB'	
)  
AS  
    BEGIN  
        SET NOCOUNT ON;  
  
   SELECT  
	   mec.RowID,
	   mec.wEventCode,  
	   Name = CASE WHEN @pLangCd = 'en-GB' THEN mec.wEName ELSE mec.wCName END,	   
	   mec.wStatus
   FROM mEventCode as mec           
   WHERE     
   (@pStatus = '' OR @pStatus = '\0'  
            OR @pStatus IS NULL  
            OR @pStatus = mec.wStatus  
    )    

END;