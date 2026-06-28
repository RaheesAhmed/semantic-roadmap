
CREATE PROCEDURE [spq].[GetStockInventory] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT  si_t.RowID ,
                si_t.wWarehouseRid ,
                si_t.wPurchaseRid ,
                si_t.wItemRid ,
                si_t.wQty ,
                si_t.wOnHoldQty ,
                si_t.wOriQty ,
                si_t.wStatus ,
                si_t.wCrtDt ,
                si_t.wUpdDt ,
                'N' AS RecordState
        FROM    dbo.eStockInventory si_t
        WHERE   @pRowID = si_t.RowID;                                                 
    END;