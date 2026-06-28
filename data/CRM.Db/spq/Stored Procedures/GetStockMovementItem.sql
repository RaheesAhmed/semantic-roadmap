
CREATE PROCEDURE [spq].[GetStockMovementItem] @pRowId BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT  smi_t.RowID ,
                smi_t.wStockMovementDtlRid ,
                smi_t.wPurchaseRid ,
                smi_t.wQty ,
                smi_t.wUnitCostHKD ,
                smi_t.wStatus ,
                smi_t.wCrtDt ,
                smi_t.wCrtBy ,
                smi_t.wUpdDt ,
                smi_t.wUpdBy ,
                'N' AS RecordState
        FROM    dbo.eStockMovementItem smi_t
        WHERE   smi_t.RowID = @pRowId;
    END;