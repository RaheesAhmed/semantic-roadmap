
CREATE PROCEDURE [spq].[GetCustomQueryLstByTargetGroup]
    @pQueryCategory VARCHAR(30) ,
    @pTargetGroupTable VARCHAR(50) ,
    @pTargetGroupTableRid BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT  cq_t.RowID ,
                cq_t.wQueryCd ,
                cq_t.wQueryName ,
                cq_t.wQueryCategory ,
                cq_t.wStatus ,
                cq_t.wCrtBy ,
                cq_t.wCrtDt ,
                cq_t.wUpdBy ,
                cq_t.wUpdDt ,
				cqtg.wIsDefault ,
                'N' AS RecordState
        FROM    dbo.mCustomQuery cq_t                
                LEFT JOIN dbo.mCustomQueryTargetGroup cqtg ON cqtg.wCustomQueryRid = cq_t.RowID
        WHERE   cq_t.wStatus = 'A'
                AND cq_t.wStatus = 'A'
                AND cq_t.wQueryCategory = @pQueryCategory
                AND ( cqtg.wTargetGroupTable = @pTargetGroupTable
                      OR cqtg.wTargetGroupTable = ''
                    )
                AND ( cqtg.wTargetGroupRid = @pTargetGroupTableRid
                      OR cqtg.wTargetGroupTable = ''
                    )
        OPTION  ( RECOMPILE );
    END;