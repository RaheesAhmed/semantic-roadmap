
CREATE PROCEDURE [spq].[GetTaskSheetTypeLst_Other] 
( 
	@pDepartmentCode VARCHAR(30),
    @pParentCode VARCHAR(30) = 'L',  -- L = ALL, ''= no parentCode 
    @pStatus CHAR(1),
    @pLangCd VARCHAR(30),
    @pPageSize INT = 999,
    @pPageNum INT = 1 
)
AS
    BEGIN
        SET NOCOUNT ON;

        WITH    tResult
                  AS ( SELECT   tst.wDepartmentCode,
                                dpt.wTitle AS wDepartmentCName,
                                tst.wCode,
                                tst.wParentCode,
                                tst.wTitle,
                                tst.wStatus,
                                tst.wCrtDt,
                                tst.wCrtBy,
                                tst.wUpdDt,
                                tst.wUpdBy,
                                CASE WHEN @pLangCd = 'en-GB' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName,
                                CASE WHEN @pLangCd = 'en-GB' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     dbo.mTaskSheetType tst
                       LEFT	JOIN [RollsMary].[dbo].[mUsr] usr
                       ON       usr.RowID = tst.wUpdBy
                       LEFT JOIN [RollsMary].[dbo].[mUsr] crusr
                       ON       crusr.RowID = tst.wCrtBy
                       INNER JOIN dbo.mLookUp dpt
                       ON       dpt.wCode = tst.wDepartmentCode
                                AND dpt.wType = 'DEPARTMENT'
                                AND dpt.wLangCd = @pLangCd
                       WHERE    ( @pStatus = ' '
                                  OR tst.wStatus = @pStatus )
                                AND ( @pDepartmentCode = ''
                                      OR tst.wDepartmentCode = @pDepartmentCode )
                                AND ( @pParentCode = 'L'
                                      OR tst.wParentCode = @pParentCode )),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     tResult)
            SELECT  tResult.*,
                    wRecordCount
            FROM    tResult,
                    tCount
            --ORDER BY tResult.wCode
			ORDER BY wCrtDt Desc
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	FETCH NEXT @pPageSize ROWS ONLY;

		
    END;