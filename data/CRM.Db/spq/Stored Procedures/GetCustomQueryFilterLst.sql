
CREATE PROCEDURE [spq].[GetCustomQueryFilterLst]
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
                  AS ( SELECT   cqf_t.RowID ,
                                cqf_t.wCustomQueryRid ,
                                cqf_t.wFilterCode ,
                                cqf_t.wIsVisible ,
                                cqf_t.wDefaultValue ,
                                cqf_t.wStatus ,
                                cqf_t.wCrtBy ,
                                cqf_t.wCrtDt ,
                                cqf_t.wUpdBy ,
                                cqf_t.wUpdDt ,
                                'N' AS RecordState
                       FROM     dbo.mCustomQueryFilter cqf_t
                                INNER JOIN dbo.mCustomQuery cq ON cq.RowID = cqf_t.wCustomQueryRid
                       WHERE    ( @pStatus = ' '
                                  OR cqf_t.wStatus = @pStatus
                                )
                                AND cqf_t.wCustomQueryRid = @pCustomQueryRid
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