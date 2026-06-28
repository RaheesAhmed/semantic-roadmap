
CREATE PROCEDURE [spq].[GetStockAdjustmentDtl] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT  sad_t.RowID ,
                sad_t.wStockAdjustmentRid ,
                sad_t.wTotalCostHKD ,
                sad_t.wItemRid ,
                sad_t.wItemQty ,
                sad_t.wStatus ,
                sad_t.wCrtDt ,
                sad_t.wCrtBy ,
                sad_t.wUpdDt ,
                sad_t.wUpdBy ,
                sad_t.wAdjustGroup,
                'N' AS RecordState
        FROM    dbo.eStockAdjustmentDtl sad_t
        WHERE   sad_t.RowID = @pRowID;                                                 
    END;