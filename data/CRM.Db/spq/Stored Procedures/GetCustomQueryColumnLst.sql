
CREATE PROCEDURE [spq].[GetCustomQueryColumnLst]
    @pCustomQueryRid BIGINT ,
    @pStatus CHAR(1) ,
    @pLangCd VARCHAR(10) ,
    @pPageNum INT = 1 ,
    @pPageSize INT = 999
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        WITH    cteData
                  AS ( SELECT   cqc_t.RowID ,
                                cqc_t.wCustomQueryRid ,
                                cqc_t.wColumnCode ,
                                cqc_t.wIsVisible ,
                                cqc_t.wAllowSelect ,
                                cqc_t.wAllowSortAcsc ,
                                cqc_t.wAllowSortDesc ,
                                cqc_t.wStatus ,
                                cqc_t.wCrtBy ,
                                cqc_t.wCrtDt ,
                                cqc_t.wUpdBy ,
                                cqc_t.wUpdDt ,
                                'N' AS RecordState
                       FROM     dbo.mCustomQueryColumn cqc_t
                                INNER JOIN dbo.mCustomQuery cq ON cq.RowID = cqc_t.wCustomQueryRid
                       WHERE    ( @pStatus = ' '
                                  OR cqc_t.wStatus = @pStatus
                                )
                                AND cqc_t.wCustomQueryRid = @pCustomQueryRid
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