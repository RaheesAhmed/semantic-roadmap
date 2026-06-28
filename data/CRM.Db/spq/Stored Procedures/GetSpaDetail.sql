CREATE PROCEDURE [spq].[GetSpaDetail]
    (
      @pName NVARCHAR(100) ,
      @pHotelRidXML XML ,
      @pwStatus CHAR(1) ,
      @pwLangCd VARCHAR(10) ,
      @pPageSize INT ,
      @pPageNum INT
    )
AS
    BEGIN  
-- SET NOCOUNT ON added to prevent extra result sets from  
-- interfering with SELECT statements.  
        SET NOCOUNT ON;
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;      

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

        SET @pName = ISNULL(@pName, '');
        SET @pwStatus = ISNULL(@pwStatus, ' ');
        SET @pwLangCd = ISNULL(@pwLangCd, 'en-gb');
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);

        WITH    tResult
                  AS ( SELECT DISTINCT
                                MS.RowID ,
                                MS.wName ,
                                MS.wPhone ,
                                MS.wPhone AS wPhoneNo ,
                                MS.wHotelRid ,
                                mh.wCode ,
                                MS.wAddress ,
                                MS.wWorkHours ,
                                MS.wRemark ,
                                MS.wStatus ,
                                MS.wSeqNo ,
                                MS.wCrtDt ,
                                MS.wCrtBy ,
                                MS.wUpdDt ,
                                MS.wUpdBy ,
                                mh.wName wTitle ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
                                CASE WHEN MS.wHotelRid = MS.RowID THEN 1
                                     ELSE 0
                                END AS wIsAgentHotel
                       FROM     dbo.mSpa MS
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = MS.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = MS.wCrtBy
                                LEFT JOIN mHotel mh ON mh.RowID = MS.wHotelRid
                                LEFT JOIN @vData_HotelRid v ON v.SelectionItem = MS.wHotelRid
                       WHERE    ( @pName = ''
                                  OR MS.wName LIKE '%' + @pName + '%'
                                )
                                AND ( @vHotelRidCount <= 0
                                      OR v.SelectionItem IS NOT NULL
                                    )
                                AND ( @pwStatus = ' '
                                      OR @pwStatus = MS.wStatus
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