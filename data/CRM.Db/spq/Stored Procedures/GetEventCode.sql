CREATE PROCEDURE [spq].[GetEventCode]
    (
      @pEventCode NVARCHAR(30) ,
      @pCName NVARCHAR(500) ,
      @pRegion VARCHAR(10) ,
      @pStartDt DATE ,
      @pStatus CHAR(1) ,
      @pwLangCd VARCHAR(10) ,
      @pPageSize INT ,
      @pPageNum INT
    )
AS
    BEGIN  
        SET @pEventCode = ISNULL(@pEventCode, '');
        SET @pCName = ISNULL(@pCName, '');
        SET @pRegion = ISNULL(@pRegion, '');
        SET @pStartDt = ISNULL(@pStartDt, '0001-01-01');
        SET @pStatus = ISNULL(@pStatus, ' ');
        SET @pwLangCd = ISNULL(@pwLangCd, 'en-gb');
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);

        SET NOCOUNT ON;  
        WITH    tResult
                  AS ( SELECT   mec.RowID ,
                                mec.wEventCode ,
                                mec.wCName ,
                                mec.wEName ,
                                mec.wStartDt ,
                                mec.wEndDt ,
                                mec.wRegion ,
                                mec.wYear ,
                                mec.wRemark ,
                                mec.wStatus ,
                                mec.wCrtDt ,
                                mec.wUpdDt ,
                                mec.wCrtBy ,
                                mec.wUpdBy ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     mEventCode AS mec
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = mec.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = mec.wCrtBy
                       WHERE    ( @pEventCode = ''
                                  OR @pEventCode = mec.wEventCode
                                )
                                AND ( @pCName = ''
                                      OR mec.wCName LIKE '%' + @pCName + '%'
                                    )
                                AND ( @pRegion = ''
                                      OR @pRegion = mec.wRegion
                                    )
                                AND ( @pStartDt = '0001-01-01'
                                      OR @pStartDt = mec.wStartDt
                                    )
                                AND ( @pStatus = ' '
                                      OR @pStatus = mec.wStatus
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
            ORDER BY tResult.wCrtDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS  
   FETCH NEXT @pPageSize ROWS ONLY;  
    END;