CREATE PROCEDURE [spq].[GetHotelAllotmentDailyRecord]
    (
      @pwStatus CHAR(1) ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1 ,
      @pwLangCd VARCHAR(10) = 'en-gb'

    )
AS
    BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from

	-- interfering with SELECT statements.

        SET NOCOUNT ON;

	

    -- Insert statements for procedure here

        WITH    tResult
                  AS ( SELECT 	DISTINCT
                                mh.RowID ,
                                wDate ,
                                mh.wCrtDt ,
                                mh.wCrtBy ,
                                mh.wUpdDt ,
                                mh.wUpdBy ,
                                mh.wName ,
                                tmp.wAllotmentQty ,
                                tmp.wBookedQty ,
                                tmp.wExtraQty ,
                                tmp.wRoomsLeft ,
                                mh.wStatus ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     mHotel mh
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = mh.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = mh.wCrtBy
                                INNER JOIN ( SELECT mh.RowID ,
                                                    wDate ,
                                                    SUM(wAllotmentQty) AS wAllotmentQty ,
                                                    SUM(wExtraQty) AS wExtraQty ,
                                                    SUM(wBookedQty) AS wBookedQty ,
                                                    SUM(wAllotmentQty)
                                                    - SUM(wBookedQty) AS wRoomsLeft
                                             FROM   eAllotmentHotelDaily ahd
                                                    INNER JOIN mHotelRoom mhr ON mhr.RowID = ahd.wRoomRid
                                                    INNER JOIN mHotel mh ON mh.RowID = mhr.wHotelRid
                                             GROUP BY wDate ,
                                                    mh.RowID
                                           ) tmp ON tmp.RowID = mh.RowID
                       WHERE    ( @pwStatus = ''
                                  OR @pwStatus IS NULL
                                  OR @pwStatus = mh.wStatus
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
            ORDER BY wUpdDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS

		  FETCH NEXT @pPageSize ROWS ONLY;



    END;