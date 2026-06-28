

CREATE PROCEDURE [spq].[GetTravelAgencyList_Report]
    (
      @pwCode  NVARCHAR (30),
      @pwName  NVARCHAR (30),
      @pwStatus Char
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
 
       SELECT  
		mta.RowID,
		mta.wName,
		mta.wCode,
		mta.wIsHotel,
		mta.wIsAirTic,
		mta.wIsShowTic,
		mta.wIsTourGuide,
		mta.wIsLeading,
		mta.wIsPickup,
		mta.wIsShip ,
		mta.wIsHelicopter ,
		mta.wIsPrivatePlane ,
		mta.wIsRestaurant ,
		mta.wIsCheckIn ,
		mta.wIsVisa,
		mta.wIsTravelPac,
		mta.wSeqNo,
		mta.wStatus,
		mta.wCrtDt,
		mta.wCrtBy,
		mta.wUpdDt,
		mta.wUpdBy
        FROM    dbo.mTravelAgency mta                
	   WHERE   
		( @pwCode = ''
            OR @pwCode IS NULL
            OR @pwCode = mta.wCode
        )
		AND ( @pwName = ''
            OR @pwName IS NULL
            OR @pwName = mta.wName
        )
		AND ( @pwStatus = ''
            OR @pwStatus IS NULL
            OR @pwStatus = mta.wStatus
        )
		
    END;