
CREATE PROCEDURE [spq].[GetStockSalesItem] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT  ssi_t.RowID ,
                ssi_t.wStockSalesDtlRid ,
                ssi_t.wPurchaseRid ,
                ssi_t.wQty ,
                ssi_t.wUnitCostHKD ,
                ssi_t.wStatus ,
                ssi_t.wCrtDt ,
                ssi_t.wCrtBy ,
                ssi_t.wUpdDt ,
                ssi_t.wUpdBy ,
                'N' AS RecordState
        FROM    dbo.eStockSalesItem ssi_t
        WHERE   ssi_t.RowID = @pRowID;                                                 
    END;