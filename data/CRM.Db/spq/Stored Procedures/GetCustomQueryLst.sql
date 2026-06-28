
CREATE PROCEDURE [spq].[GetCustomQueryLst]
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
                  AS ( SELECT   cq_t.RowID ,
                                cq_t.wQueryCd ,
                                cq_t.wQueryName ,
                                cq_t.wQueryCategory ,                                
                                cq_t.wStatus ,
                                cq_t.wCrtBy ,
                                cq_t.wCrtDt ,
                                cq_t.wUpdBy ,
                                cq_t.wUpdDt ,
                                'N' AS RecordState
                       FROM     dbo.mCustomQuery cq_t
                       WHERE    @pStatus = ' '
                                OR cq_t.wStatus = @pStatus
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