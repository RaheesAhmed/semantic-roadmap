CREATE PROCEDURE [spq].[GetTravelAgency]
    (
      @pwCode NVARCHAR(30) ,
      @pwName NVARCHAR(30) ,
      @pwStatus CHAR ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1 ,
      @pwLangCd VARCHAR(10) = 'en-GB'
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT   mta.RowID ,
                                mta.wName ,
                                mta.wCode ,
                                mta.wIsHotel ,
                                mta.wIsAirTic ,
                                mta.wIsShowTic ,
                                mta.wIsTourGuide ,
                                mta.wIsPickup ,
                                mta.wIsLeading ,
                                mta.wIsShip ,
                                mta.wIsHelicopter ,
                                mta.wIsPrivatePlane ,
                                mta.wIsRestaurant ,
                                mta.wIsCheckIn ,
                                mta.wIsVisa ,
                                mta.wIsTravelPac ,
								mta.wIsOtherExp,
                                mta.wSeqNo ,
                                mta.wStatus ,
                                mta.wCrtDt ,
                                mta.wCrtBy ,
                                mta.wUpdDt ,
                                mta.wUpdBy ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     [CRM].[dbo].[mTravelAgency] mta
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = mta.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = mta.wCrtBy
                       WHERE    ( @pwCode = ''
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
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     tResult
                     )
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            ORDER BY wCrtDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY;


    END;