
CREATE PROCEDURE [spq].[GetRestaurantSettings_Master]
    (
      @pRegion VARCHAR(10) ,
      @pName NVARCHAR(100) ,
      @pHotelRidXML XML ,
      @pStatus VARCHAR(2) ,
      @pLangCd VARCHAR(10) ,
      @pPageSize INT ,
      @pPageNum INT
    )
AS
    BEGIN
        SET NOCOUNT ON;  

        DECLARE @vHotelRidCount AS INT;

        DECLARE @vData_HotelRid AS TABLE ( SelectionItem BIGINT );

        IF CAST(@pHotelRidXML AS NVARCHAR(MAX)) != N'<DataSet/>'
            BEGIN
                INSERT  INTO @vData_HotelRid
                        ( SelectionItem
                        )
                        SELECT  tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
                        FROM    @pHotelRidXML.nodes('/DataSet/Record') AS T ( tmp );
            END;

        SET @vHotelRidCount = ( SELECT  COUNT(1)
                                FROM    @vData_HotelRid
                              );

        SET @pRegion = ISNULL(@pRegion, '');
        SET @pName = ISNULL(@pName, '');
        SET @pStatus = ISNULL(@pStatus, '');
        SET @pLangCd = ISNULL(@pLangCd, 'en-gb');
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);
   
        WITH    tResult
                  AS ( SELECT   mrs.RowID ,
                                mrs.wName ,
                                mrs.wLevel ,
                                mrs.wPhone ,
                                mrs.wHotelRid ,
                                mrs.wWorkHours ,
                                mrs.wRegion ,
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
                                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
						        mh.wName AS wHotelRidByName,
						        mrs.wDressRequire
                       FROM     dbo.mRestaurant mrs
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = mrs.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = mrs.wCrtBy
						        LEFT JOIN mHotel mh ON mh.RowID = mrs.wHotelRid
                                LEFT JOIN @vData_HotelRid v ON v.SelectionItem = mrs.wHotelRid
                       WHERE    ( @pRegion = ''
                                  OR @pRegion = mrs.wRegion
                                )
                                AND ( @pName = ''
                                      OR mrs.wName LIKE '%' + @pName + '%'
                                    )
                                AND ( @vHotelRidCount <= 0
                                      OR v.SelectionItem IS NOT NULL
                                    )
                                AND ( @pStatus = ''
                                      OR @pStatus = mrs.wStatus
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