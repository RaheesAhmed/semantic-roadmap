

CREATE PROCEDURE [spq].[GetShiftDetails_Share]
    (
      @pwStatus CHAR(1) ,
      @pwLangCd VARCHAR(10) = 'en-GB' ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1
    )
AS
    BEGIN
        SET NOCOUNT ON;

        WITH    tResult
                  AS ( SELECT   ms.RowID ,
                                ms.wCode ,
                                ms.wName ,
                                ms.wDepartmentCd ,
                                ms.wStatus ,
                                ms.wSeqNo ,
                                ms.wCrtDt ,
                                ms.wCrtBy ,
                                ms.wUpdDt ,
                                ms.wUpdBy ,
                                lr.wTitle AS wDeptName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     dbo.mShift ms
                                INNER JOIN dbo.mLookUp lr ON lr.wCode = ms.wDepartmentCd
                                                             AND lr.wLangCd = @pwLangCd
                                                             AND lr.wType = 'DEPARTMENT'
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ms.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ms.wCrtBy
                       WHERE    ( @pwStatus = ''
                                  OR @pwStatus = '\0'
                                  OR @pwStatus IS NULL
                                  OR @pwStatus = ms.wStatus
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