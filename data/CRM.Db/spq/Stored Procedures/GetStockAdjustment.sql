
CREATE PROCEDURE [spq].[GetStockAdjustment] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT  sa_t.RowID ,
                sa_t.wWarehouseRid ,
                sa_t.wApprovalByRid ,
                sa_t.wAdjustDt ,
                sa_t.wRemarks ,
                sa_t.wAdjustmentStatus ,
                sa_t.wStatus ,
                sa_t.wCrtDt ,
                sa_t.wCrtBy ,
                sa_t.wUpdDt ,
                sa_t.wUpdBy ,
                'N' AS RecordState
        FROM    dbo.eStockAdjustment sa_t
        WHERE   @pRowID = sa_t.RowID;                                                 
    END;