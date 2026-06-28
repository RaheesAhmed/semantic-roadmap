
CREATE PROCEDURE [spq].[GetStockMovementDtl] @pRowId BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT  smd_t.RowID ,
                smd_t.wStockMovementRid ,
                smd_t.wSalesType ,
                smd_t.wAgentCodeIn ,
                smd_t.wTotalCostHKD ,
                smd_t.wItemRid ,
                smd_t.wItemQty ,
                smd_t.wStatus ,
                smd_t.wCrtDt ,
                smd_t.wCrtBy ,
                smd_t.wUpdDt ,
                smd_t.wUpdBy ,
                'N' AS RecordState
        FROM    dbo.eStockMovementDtl smd_t
        WHERE   smd_t.RowID = @pRowId;
    END;