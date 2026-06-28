CREATE PROCEDURE [spq].[GetPreferenceSubtype] 
    (
	  @pwStatus varchar(2),
	  @pwLangCd varchar(10) = 'en-gb',
	  @pwPreferenceTypeId BIGINT,
	  @pPageSize INT = 999,
	  @pPageNum INT = 1
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	WITH tResult AS (
       SELECT  
	   ma.RowID
	  ,ma.wPreferenceTypeRid
      ,ma.wName
      ,ma.wCode	    
      ,ma.wSeqNo
	  ,ma. wStatus 
      ,ma.wCrtDt
      ,ma.wCrtBy
      ,ma.wUpdDt
      ,ma.wUpdBy
	  ,CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END AS wUpdByCName
	  ,CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END AS wCreatedByCName
	  ,ls.wTitle as wStatusName
        FROM [CRM].[dbo].[mPreferenceSubtype] ma
        inner join [RollsMary].[dbo].[mUsr] usr on usr.RowID=ma.wUpdBy
		inner join [RollsMary].[dbo].[mUsr] crusr on crusr.RowID=ma.wCrtBy	
	    inner join dbo.mPreferenceType mp on mp.RowID = ma.wPreferenceTypeRid
		inner join dbo.mLookUp ls on ls.wCode = ma.wStatus and ls.wLangCd = @pwLangCd and ls.wType= 'COMMON_STATUS'  
	   WHERE   
		
	   ( @pwStatus = ''
            OR @pwStatus IS NULL
            OR @pwStatus = ma.wStatus
        )
		AND
		(
		@pwPreferenceTypeId = ''
			OR @pwPreferenceTypeId IS NULL
			OR @pwPreferenceTypeId = 0
			OR @pwPreferenceTypeId = ma.wPreferenceTypeRid
		)
		
		 ),tCount AS (
		SELECT wRecordCount = COUNT(*) FROM tResult
	)
	SELECT tResult.*, wRecordCount
		FROM tResult,tCount
		  ORDER BY wUpdDt Desc
		  OFFSET @pPageSize * (@pPageNum - 1) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY;
    END;