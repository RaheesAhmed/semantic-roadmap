
CREATE PROCEDURE [spq].[GetStockSalesDtl] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT  ssd_t.RowID ,
                ssd_t.wStockSalesRid ,
                ssd_t.wItemRid ,
                ssd_t.wTotalCostHKD ,
                ssd_t.wTotalPriceHKD ,
				ssd_t.wUnitPriceHKD ,
                ssd_t.wQty ,
                ssd_t.wStatus ,
                ssd_t.wCrtDt ,
                ssd_t.wCrtBy ,
                ssd_t.wUpdDt ,
                ssd_t.wUpdBy ,
                'N' AS RecordState,
                ssd_t.wLotNo
        FROM    dbo.eStockSalesDtl ssd_t
        WHERE   ssd_t.RowID = @pRowID;                                                 
    END;