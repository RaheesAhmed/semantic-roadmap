
CREATE PROCEDURE [spq].[GetTicketCollectionPoint_Master]
    (
      @pwCode NVARCHAR(30) ,
      @pwName NVARCHAR(30) ,
      @pwStatus CHAR ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1 ,
      @pwLangCd VARCHAR(10) = 'en-GB' ,
      @pwBookingType VARCHAR(30) = ''
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT   mtc.RowID ,
                                mtc.wName ,
                                mtc.wCode ,
                                mtc.wIsFerryTic wHasFerryTic ,
                                mtc.wIsAirTic wHasAirTic ,
                                mtc.wIsCheckInService wHasCheckInService ,
                                mtc.wIsShowTic wHasShowTic ,
                                mtc.wIsVisa wHasVisa ,
                                mtc.wSeqNo ,
                                mtc.wStatus ,
                                mtc.wCrtDt ,
                                mtc.wCrtBy ,
                                mtc.wUpdDt ,
                                mtc.wUpdBy ,
								mtc.wAddress,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     [CRM].[dbo].[mTicketCollectionPoint] mtc
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = mtc.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = mtc.wCrtBy
                       WHERE    ( @pwCode = ''
                                  OR @pwCode IS NULL
                                  OR @pwCode = mtc.wCode
                                )
                                AND ( @pwName = ''
                                      OR @pwName IS NULL
                                      OR @pwName = mtc.wName
                                    )
                                AND ( @pwStatus = ''
                                      OR @pwStatus IS NULL
                                      OR @pwStatus = mtc.wStatus
                                    )
                                AND ( @pwBookingType = ''
                                      OR @pwBookingType IS NULL
                                      OR ( ( @pwBookingType = 'FERRY'
                                             AND mtc.wIsFerryTic = 'Y'
                                           )
                                           OR ( @pwBookingType = 'AIRTICKET'
                                                AND mtc.wIsAirTic = 'Y'
                                              )
                                           OR ( @pwBookingType = 'CHECKINSERVICE'
                                                AND mtc.wIsCheckInService = 'Y'
                                                AND mtc.wStatus = 'A'
                                              )
                                           OR ( @pwBookingType = 'SHOWTICKET'
                                                AND mtc.wIsShowTic = 'Y'
                                              )
                                           OR ( @pwBookingType = 'VISA'
                                                AND mtc.wIsVisa = 'Y'
                                              )
                                         )
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