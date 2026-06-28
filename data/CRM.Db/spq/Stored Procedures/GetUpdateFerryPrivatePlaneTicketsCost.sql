CREATE PROCEDURE [spq].[GetUpdateFerryPrivatePlaneTicketsCost]
    (
      @pwVehicleType  NVARCHAR (30),
      @pwTicType  NVARCHAR (30),
      @pwFerryClass  NVARCHAR (30),
	  @pPageSize INT = 999,
	  @pPageNum INT = 1,
      @pwLangCd Varchar(10) ='en-GB'
    )
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
	
    -- Insert statements for procedure here
	 WITH tResult AS (	 	
       SELECT 
	    ROW_NUMBER() OVER ( ORDER BY tc.RowID)  AS wSeqNo, 
        tc.RowID,
        tc. wRouteId,
	    r.wRouteFrom + ' to ' + r.wRouteTo wRoute,
        tc.wVehicleType,
        tc.wStartDate,
        tc.wEndDate,
        tc.wTicketType wTicTypeCode,
		lkty.wTitle wTicType,
        tc.wClassCd wFerryClassCode,
		lkfc.wTitle wFerryClass,
        tc.wSellingAmt,
        tc.wRate,
        tc.wTax,
        tc.wCrtDt,
        tc.wCrtBy,
        tc.wUpdDt,
        tc.wUpdBy,
		tc.wStatus,
		tc.wCurrency
		,CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END AS wUpdByCName
		,CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END AS wCreatedByCName
        FROM  [CRM].[dbo].eUpdateFerryAndPrivatePlaneCost  tc  
		inner join [RollsMary].[dbo].[mUsr] usr on usr.RowID=tc.wUpdBy 
		left join [RollsMary].[dbo].[mUsr] crusr on crusr.RowID=tc.wCrtBy 
		 LEFT join mLookUp lkty on lkty.wCode = tc.wTicketType AND lkty.wLangCd = @pwLangCd And lkty.wType = CASE WHEN  @pwVehicleType IS NOT NULL and @pwVehicleType = 'FERRY' THEN 'FERRY_TICKET_TYPE' 
																			   END
		 Left join mLookUp lkfc on lkfc.wCode = tc.wClassCd AND lkfc.wLangCd = @pwLangCd And lkfc.wType = 'FERRY_CLASS'
		 inner join dbo.mRoute r on r.RowID = tc.wRouteId
		  WHERE   
		( @pwVehicleType = ''
            OR @pwVehicleType IS NULL
            OR @pwVehicleType = tc.wVehicleType
        )
		AND (   @pwTicType  = ''
            OR @pwTicType IS NULL
            OR @pwTicType = tc.wTicketType
        )
		AND (  @pwFerryClass  = ''
            OR @pwFerryClass  IS NULL
            OR  @pwFerryClass  = tc.wClassCd
        )
	
	),tCount AS (
		SELECT wRecordCount = COUNT(*) FROM tResult
	)
	SELECT tResult.*, wRecordCount
		FROM tResult,tCount
		 ORDER BY wUpdDt Desc
		  OFFSET @pPageSize * (@pPageNum - 1) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY;
		  END