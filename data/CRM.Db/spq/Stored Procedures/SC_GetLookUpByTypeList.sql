CREATE PROCEDURE  [spq].[SC_GetLookUpByTypeList]
(	
	/*
	SC API 
	Get Lookup By Type	
	
	declare @pXML XML,			
			@pErrCode INT,
			@pErrMsg NVARCHAR(1000)			

	set @pXML='<DataSet>
					<Record wType="ADVICE_TYPE"/>
					<Record wType="ADVICE_SUB_TYPE"/>
				</DataSet>'

	exec [spq].[SC_GetLookUpByTypeList] @pXML, 'zh-TW', @pErrCode, @pErrMsg	
	
	SELECT @pErrCode , @pErrMsg
	*/

	@pXML		XML,
	@pLangCd	VARCHAR(30)='zh-TW',
	@pCode		INT = 0	 OUTPUT,
	@pMsg		NVARCHAR(200)='' OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @sDocHandle	INT	

	--dbml
	/*
	SELECT 
		m.wType, 
		m.wCode,
		m.wParentCode,
		m.wTitle
	FROM dbo.mLookUp m
	return
	*/


	IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;    
	
	EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML

	SELECT	    
	    *
	INTO
	    #sDataSet
	FROM OPENXML (@sDocHandle, 'DataSet/Record', 1)
	WITH (		
		wType VARCHAR(50)
	)	

	SELECT 
		m.wType, 
		m.wCode,
		m.wParentCode,
		m.wTitle
	FROM dbo.mLookUp m
	INNER JOIN #sDataSet s on s.wType = m.wType
	WHERE wLangCd =@pLangCd AND wStatus='A'	

	EXEC sp_xml_removedocument @sDocHandle	
	
	IF object_id('tempdb..#sDataSet') IS NOT NULL
		DROP TABLE #sDataSet
				
END