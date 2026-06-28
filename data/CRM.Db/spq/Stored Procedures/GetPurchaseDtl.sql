
CREATE PROCEDURE [spq].[GetPurchaseDtl] @pRowId BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT  pd_t.RowID ,
                pd_t.wPurchaseRid ,
                pd_t.wCurrCode ,
                pd_t.wCurrRate ,
                pd_t.wUnitCost ,
                pd_t.wQty ,
                pd_t.wStockInQty ,
                pd_t.wItemRid ,
                pd_t.wStatus ,
                pd_t.wCrtDt ,
                pd_t.wCrtBy ,
                pd_t.wUpdDt ,
                pd_t.wUpdBy ,
                'N' AS RecordState,
                pd_t.wValidDate,
                wHandleRemark,
                wHandleStatus 
        FROM    dbo.ePurchaseDtl pd_t
        WHERE   pd_t.RowID = @pRowId;
    END;