CREATE PROCEDURE [spq].[GetServiceCounterContact]
    (
      @pwSeriverCounterRid  bigint,
	  @pwLangCd varchar(10) = 'en-gb' 
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	 
       SELECT  
		msccv.RowID,
		msccv.wSeriverCounterRid,
		msccv.wDepartmentCode,
		ldept.wTitle as DepartmentTitle,
		msccv.wContactType,
		lcontact.wTitle as ContactTitle,
		msccv.wTel,
		msccv.wEmail,
		msccv.wIsUsingApp,
		msccv.wSeqNo,			
		msccv.wCrtDt,
		msccv.wCrtBy,
		msccv.wUpdDt,
		msccv.wUpdBy
		,CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END AS wUpdByCName
		 ,CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END AS wCreatedByCName
        FROM  [crm].[dbo].mServiceCounterContact msccv
		LEFT join [RollsMary].[dbo].mUsr usr on usr.RowID=msccv.wUpdBy
		LEFT join [RollsMary].[dbo].[mUsr] crusr on crusr.RowID=msccv.wCrtBy   
		Left Join mLookUp ldept On ldept.wType = 'DEPARTMENT' And msccv.wDepartmentCode = ldept.wCode And ldept.wLangCd = @pwLangCd
		Left Join mLookUp lcontact On lcontact.wType = 'CONTACT_TYPE' And msccv.wContactType = lcontact.wCode And lcontact.wLangCd = @pwLangCd             
       WHERE   
		( @pwSeriverCounterRid = ''
            OR @pwSeriverCounterRid IS NULL
            OR @pwSeriverCounterRid = msccv.wSeriverCounterRid
        );

END;