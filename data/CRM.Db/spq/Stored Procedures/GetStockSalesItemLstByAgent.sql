CREATE PROCEDURE [spq].[GetStockSalesItemLstByAgent]
    -- RollsMary\CRM.Inventory\ViewModel\StockSalesDtlViewModel
    -- exec [spq].[GetStockSalesItemLstByAgent] 10000000010003,'1000031235'
    @pWarehouseRid BIGINT ,
    @pAgentCodeIn VARCHAR(14)
AS
    BEGIN
        SET NOCOUNT ON;	  	
                
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 	

        WITH    cteStockList
                  AS ( SELECT   si.wPurchaseRid ,
                                si.wItemRid ,
                                SUM(si.wQty) AS wQty ,
                                SUM(si.wQty) AS wRunningQty ,
                                SUM(p.wCost) AS wCost ,
                                p.wCurrCode ,
                                CAST('N' AS CHAR(1)) AS RecordState
                       FROM     dbo.eStockInventory si
                                INNER JOIN dbo.ePurchase p ON p.RowID = si.wPurchaseRid
                       WHERE    si.wWarehouseRid = @pWarehouseRid
                                AND p.wAgentCodeIn = @pAgentCodeIn
                                AND si.wStatus = 'A'
                       GROUP BY si.wPurchaseRid ,
                                si.wItemRid ,
                                p.wCurrCode
                       HAVING   SUM(si.wQty) > 0
                     )
            SELECT  si.* ,
                    i.wPrice ,
                    p.wLotNo ,
                    p.wBatchNo
            FROM    cteStockList si
                    INNER JOIN dbo.mItem i ON i.RowID = si.wItemRid
                                              AND i.wStatus = 'A'
                    INNER JOIN dbo.ePurchase p ON p.RowID = si.wPurchaseRid;
      
    END;