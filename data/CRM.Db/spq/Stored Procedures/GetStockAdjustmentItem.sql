
CREATE PROCEDURE [spq].[GetStockAdjustmentItem] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT  sai_t.RowID ,
                sai_t.wStockAdjustmentDtlRid ,
                sai_t.wPurchaseRid ,
                sai_t.wQty ,
                sai_t.wUnitCostHKD ,
                sai_t.wStatus ,
                sai_t.wCrtDt ,
                sai_t.wCrtBy ,
                sai_t.wUpdDt ,
                sai_t.wUpdBy ,
                'N' AS RecordState
        FROM    dbo.eStockAdjustmentItem sai_t
        WHERE   sai_t.RowID = @pRowID;                                                 
    END;