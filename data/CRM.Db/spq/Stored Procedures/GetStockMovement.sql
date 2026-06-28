
CREATE PROCEDURE [spq].[GetStockMovement] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT  sm_t.RowID ,
                sm_t.wOutWarehouseRid ,
                sm_t.wOutUsrRid ,
                sm_t.wOutDt ,
                sm_t.wInWarehouseRid ,
                sm_t.wInUsrRid ,
                sm_t.wInDt ,
                sm_t.wRemarks ,
                sm_t.wMovementStatus ,
                sm_t.wStatus ,
                sm_t.wCrtDt ,
                sm_t.wCrtBy ,
                sm_t.wUpdDt ,
                sm_t.wUpdBy ,
                'N' AS RecordState
        FROM    dbo.eStockMovement sm_t
        WHERE   @pRowID = sm_t.RowID;                                                 
    END;