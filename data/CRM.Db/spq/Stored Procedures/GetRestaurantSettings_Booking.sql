
CREATE PROCEDURE [spq].[GetRestaurantSettings_Booking]
    (
      @pwStatus VARCHAR(10) ,
      @pwLangCd VARCHAR(10) = 'en-GB' ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1  
    )
AS
    BEGIN
        SET NOCOUNT ON;  
   
        WITH    tResult
                  AS ( SELECT   mrs.RowID ,
                                mrs.wName ,
                                mrs.wLevel ,
                                lupl.wTitle AS wLevelTitle ,
                                mrs.wPhone ,
                                mrs.wHotelRid ,
                                mrs.wWorkHours ,
                                mrs.wRegion AS wRegionCode ,
                                lupr.wTitle AS wRegionName ,
                                mrs.wNoOfSeat ,
                                mrs.wIsSign ,
                                mrs.wAddress ,
                                mrs.wIsBtm ,
                                mrs.wMinCharge ,
                                mrs.wMenu ,
                                mrs.wStatus ,
                                mrs.wSeqNo ,
                                mrs.wCrtDt ,
                                mrs.wCrtBy ,
                                mrs.wUpdDt ,
                                mrs.wUpdBy ,
                                mrs.wCuisine ,
                                mrs.wAwards ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     dbo.mRestaurant mrs
                                LEFT JOIN mLookUp lupr ON lupr.wCode = mrs.wRegion
                                                           AND lupr.wType = 'REGION'
                                                           AND lupr.wLangCd = @pwLangCd  
  --inner join mLookUp lupc on lupc.wCode = mh.wCurrCode AND lupc.wType = 'CURRENCY' AND lupc.wLangCd = @pwLangCd  
                                LEFT JOIN mLookUp lupl ON mrs.wLevel = lupl.wCode
                                                          AND lupl.wType = 'RESTAURANT_LEVEL'
                                                          AND lupl.wLangCd = @pwLangCd
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = mrs.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = mrs.wCrtBy
                       WHERE    ( @pwStatus = ''
                                  OR @pwStatus IS NULL
                                  OR @pwStatus = mrs.wStatus
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