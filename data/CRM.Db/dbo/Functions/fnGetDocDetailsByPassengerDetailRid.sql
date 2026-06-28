--sp_helptext '[dbo].[fnGetDocDetailsByPassengerDetailRid]'

CREATE FUNCTION  [dbo].[fnGetDocDetailsByPassengerDetailRid] --(001,'IDNo','en-GB')                 
(                    
	@pPassengerDetailRid BIGINT,
	@pType VARCHAR(15),
	@pwLangCd VARCHAR(10)            
)                     
RETURNS  NVARCHAR(MAX)                    
BEGIN                    
	DECLARE @listStr NVARCHAR(MAX)                
               
	
	IF @pType ='ID_NO' 
	BEGIN
	SELECT @listStr =	
		
		COALESCE(@listStr+',' , '') + ptd.wIDNo
		FROM ePassengerTravelDocDetail ptdd
		INNER JOIN mPersonTravelDoc ptd ON ptd.RowID =ptdd.wPersonTravelDocRid
		WHERE ptdd.wPassengerDetailsRid = @pPassengerDetailRid                
	END
	ELSE IF @pType ='ID_TYPE' 
	BEGIN
	SELECT @listStr =	
		
		COALESCE(@listStr+',' , '') + lupit.wTitle
		FROM ePassengerTravelDocDetail ptdd
		INNER JOIN mPersonTravelDoc ptd ON ptd.RowID =ptdd.wPersonTravelDocRid
		LEFT JOIN dbo.mLookUp lupit on lupit.wCode = ptd.wIDType AND lupit.wType = 'ID_TYPE' and lupit.wLangCd=@pwLangCd
		WHERE ptdd.wPassengerDetailsRid = @pPassengerDetailRid                  

	END
	ELSE IF @pType ='ENGLISH_PINYIN' 
	BEGIN
	SELECT @listStr =	
		
		COALESCE(@listStr+',' , '') + ptd.wEnglishPinyin
		FROM ePassengerTravelDocDetail ptdd
		INNER JOIN mPersonTravelDoc ptd ON ptd.RowID =ptdd.wPersonTravelDocRid
		WHERE ptdd.wPassengerDetailsRid = @pPassengerDetailRid                
	END
                      
	RETURN  ISNULL(@listStr,'')                    
END