
CREATE PROCEDURE [spq].[GetRouteDtl_ByRouteRid]
    (
      @pwRouteRid  bigint
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
       SELECT  
		mrd.RowID,
		mrd.wRouteRid,
		mrd.wCheckPoint,
		mrd.wIsOneWay,
		mrd.wSeqNo,
		mrd.wCrtDt,
		mrd.wCrtBy,
		mrd.wUpdDt,
		mrd.wUpdBy
        FROM    dbo.mRouteDtl mrd                
	   WHERE   
		( @pwRouteRid = ''
            OR @pwRouteRid IS NULL
            OR @pwRouteRid = mrd.wRouteRid
        )

    END;