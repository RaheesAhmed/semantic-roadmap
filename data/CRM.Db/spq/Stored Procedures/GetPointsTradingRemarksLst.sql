
CREATE PROCEDURE [spq].[GetPointsTradingRemarksLst]
    @pPointsTradingRid BIGINT ,
    @pLangCd VARCHAR(30) ,
    @pStatus CHAR(1) ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1
AS
    BEGIN
        SET NOCOUNT ON;	
    
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        WITH    cteData
                  AS ( SELECT   ptr.RowID ,
                                ptr.wPointsTradingRid ,
                                ptr.wRemarks ,
                                ptr.wCrtDt ,
                                ptr.wCrtBy ,
                                CASE WHEN @pLangCd = 'en-GB' THEN u_cb.wName
                                     ELSE u_cb.wCName
                                END AS wCrtByName ,
                                ptr.wUpdDt ,
                                ptr.wUpdBy ,
                                CASE WHEN @pLangCd = 'en-GB' THEN u.wName
                                     ELSE u.wCName
                                END AS wUpdByName
                       FROM     dbo.ePointsTradingRemarks ptr
                                LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = ptr.wUpdBy
                                LEFT JOIN RollsMary.dbo.mUsr u_cb ON u_cb.RowID = ptr.wCrtBy
                       WHERE    ptr.wPointsTradingRid = @pPointsTradingRid
                                AND ptr.wStatus = @pStatus
                     ),
                cteCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     cteData
                     )
            SELECT  d.* ,
                    c.wRecordCount
            FROM    cteData d ,
                    cteCount c
            ORDER BY d.wUpdDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );

    END;