CREATE PROCEDURE [spq].[GetBookingFerryTicketsAllotmentLst]
    (
	   @pRouteRid BIGINT,
	   @pCounterRid BIGINT,
	   @pFromTicketNo VARCHAR (30),
	   @pToTicketNo VARCHAR (30),
	   @pTicketType  VARCHAR (30),
	   @pLangCd Varchar(10) ='en-GB',
	   @pPageNum INT = 1 ,
	   @pPageSize INT = 999
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;	
		SET @pPageSize = ISNULL(@pPageSize, 20);
        SET @pPageNum = ISNULL(@pPageNum, 1);

    -- Insert statements for procedure here
	  WITH tResult AS (  
	  SELECT  
	  ROW_NUMBER() OVER ( ORDER BY afr.RowID)  AS wSeqNo,
	   afr.RowID
      ,afr.wTicketNo
	  ,afr.wCounterRid
      ,mcc.wName AS wCounterCName
	  ,afr.wStatus
      ,afr.wExpiryDate wValidDate
      ,afr.wTicketType wTicketTypeCode
      ,afr.wRouteRid
	  ,afr.wClassCd wFerryClassCode	  
	  ,afr.wAmount
	  ,afr.wAllotmentStatus wAllotmentStatusCode
	  ,afr.wRemark	  
	  ,afr.wCurrCode	  
	  ,afr.wCrtDt
	  ,afr.wCrtBy
      ,afr.wUpdDt
      ,afr.wUpdBy
	  ,CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END AS wUpdByCName
	  ,CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END AS wCreatedByCName
	  ,CASE WHEN r.wIsTwoWay='Y' THEN r.wRouteFrom + '<->' + r.wRouteTo ELSE r.wRouteFrom + '->' + r.wRouteTo END AS wRoute
	  ,CAST(0 AS bit) AS wIsSelected
	  ,eb.wRefNo
	  ,afr.wBookingRid
	FROM    [crm].[dbo].[eAllotmentTicket] afr
			INNER JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = afr.wUpdBy 
			INNER JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = afr.wCrtBy
			LEFT JOIN dbo.mRoute r ON r.RowID = afr.wRouteRid													
			LEFT JOIN dbo.eBooking eb ON eb.rowid = afr.wBookingRid
			LEFT JOIN dbo.mServiceCounter mcc ON mcc.RowID = afr.wCounterRid
		WHERE (Isnull(@pTicketType, '') = '' OR @pTicketType = afr.wTicketType)
			  AND (@pRouteRid = 0
				OR @pRouteRid IS NULL
				OR @pRouteRid = afr.wRouteRid)
			  AND (@pCounterRid = 0
				OR @pCounterRid IS NULL
				OR @pCounterRid = afr.wCounterRid)
			  AND ((@pFromTicketNo = '' OR @pToTicketNo = '')
				OR (@pFromTicketNo IS NULL OR @pToTicketNo IS NULL)
				OR (afr.wTicketNo BETWEEN @pFromTicketNo AND @pToTicketNo))
			  AND afr.wAllotmentStatus='N' 
			  AND afr.wStatus='A'
		 ), tCount AS (
		SELECT wRecordCount = COUNT(*) FROM tResult
	)
	SELECT tResult.*, wRecordCount
		FROM tResult,tCount		  
		ORDER BY wTicketNo asc	
		OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		FETCH NEXT @pPageSize ROWS ONLY
			OPTION  ( RECOMPILE );	
 END;