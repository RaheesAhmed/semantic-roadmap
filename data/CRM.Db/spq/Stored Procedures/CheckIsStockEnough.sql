



CREATE PROCEDURE [spq].[CheckIsStockEnough]
                 @pRowID BIGINT,
                 @pType VARCHAR(10),
                 @pResult BIT OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;	  	
		DECLARE @sGetKeyPasscode VARCHAR(10)='';               

       IF @pType='MOVEMENT'
       BEGIN
        --该转仓单所有的货品数量 与仓库货品的数量进行对比            
            WITH cteMovement AS (
                SELECT 
                    SUM(item.wQty) AS wMoveQty,
                    dtl.wItemRid,
                    dtl.wAgentCodeIn,
                    movement.wOutWarehouseRid
                FROM dbo.eStockMovementDtl dtl
                INNER JOIN  dbo.eStockMovementItem item ON item.wStockMovementDtlRid =dtl.RowID  
                INNER JOIN dbo.eStockMovement movement ON dtl.wStockMovementRid =movement.RowID
                WHERE movement.RowID =@pRowID
                GROUP BY dtl.wItemRid,
                         dtl.wAgentCodeIn,
                         movement.wOutWarehouseRid
            )
            SELECT  
               SUM(stock.wQty) - movment.wMoveQty AS wQty,
               movment.wItemRid,
               movment.wAgentCodeIn,
               pur.wInWarehouseRid
            INTO #tmpMoveResult      
            FROM dbo.eStockInventory stock 
            INNER JOIN dbo.ePurchase pur ON stock.wPurchaseRid = pur.RowID
            INNER JOIN dbo.ePurchaseDtl dtl ON dtl.wPurchaseRid =stock.wPurchaseRid AND dtl.wItemRid =stock.wItemRid
            INNER JOIN cteMovement movment ON movment.wAgentCodeIn =pur.wAgentCodeIn 
                                          AND movment.wItemRid =stock.wItemRid
                                          AND movment.wOutWarehouseRid =stock.wWarehouseRid
            WHERE stock.wStatus ='A' 
                 AND pur.wStatus ='A' 
                 AND dtl.wStatus ='A'
                 AND pur.wPurchaseStatus ='COMPLETE'
            GROUP BY movment.wItemRid,
                     movment.wAgentCodeIn,
                     pur.wInWarehouseRid,
                     movment.wMoveQty

          IF EXISTS( SELECT 1 FROM #tmpMoveResult WHERE wQty <0)--wQty<0  说明 仓库确实不够 则不需要自动分配
          BEGIN
             SET @pResult=0
          END;

          ELSE
          BEGIN
            IF EXISTS(
               SELECT 1
               FROM dbo.eStockMovementItem item
               INNER JOIN dbo.eStockMovementDtl  dtl ON item.wStockMovementDtlRid =dtl.RowID  
               INNER JOIN dbo.eStockMovement movement ON dtl.wStockMovementRid =movement.RowID
               INNER JOIN dbo.eStockInventory inv ON item.wPurchaseRid =inv.wPurchaseRid AND dtl.wItemRid =inv.wItemRid
               WHERE item.wQty > inv.wQty AND movement.RowID =@pRowID --item.wQty > inv.wQty 说明现有的批次号库存数量比转仓单要转仓的数量小 此时需要重新分配批次号
             )
             BEGIN
               SET @pResult=1
             END;
             ELSE
               BEGIN
                  SET @pResult=0
               END;
          END;                                      
       END;       
       ELSE IF @pType='SALES'
       BEGIN
            --该销售单所有的货品数量 与仓库货品的数量进行对比            
            WITH cteSales AS (
            SELECT 
                SUM(item.wQty) AS wMoveQty,
                dtl.wItemRid,
                sales.wRecipientAgentCodeIn,
                sales.wOutWarehouseRid
            FROM dbo.eStockSalesDtl dtl
            INNER JOIN  dbo.eStockSalesItem item ON item.wStockSalesDtlRid =dtl.RowID  
            INNER JOIN dbo.eStockSales sales ON dtl.wStockSalesRid =sales.RowID
            WHERE sales.RowID =@pRowID
            GROUP BY dtl.wItemRid,
                        sales.wRecipientAgentCodeIn,
                        sales.wOutWarehouseRid
            )

            SELECT  
                SUM(stock.wQty) - sales.wMoveQty AS wQty,
                sales.wItemRid,
                sales.wRecipientAgentCodeIn,
                pur.wInWarehouseRid
            INTO #tmpSalesResult      
            FROM dbo.eStockInventory stock 
            INNER JOIN  dbo.ePurchase pur ON stock.wPurchaseRid = pur.RowID
            INNER JOIN  dbo.ePurchaseDtl dtl ON dtl.wPurchaseRid =stock.wPurchaseRid AND dtl.wItemRid =stock.wItemRid
            INNER JOIN  cteSales sales ON sales.wRecipientAgentCodeIn =pur.wAgentCodeIn 
                                            AND sales.wItemRid =stock.wItemRid
                                            AND sales.wOutWarehouseRid =stock.wWarehouseRid
            WHERE stock.wStatus ='A' 
                AND pur.wStatus ='A' 
                AND dtl.wStatus ='A'
                AND pur.wPurchaseStatus ='COMPLETE'
            GROUP BY sales.wItemRid,
                        sales.wRecipientAgentCodeIn,
                        pur.wInWarehouseRid,
                        sales.wMoveQty

            IF EXISTS( SELECT 1 FROM #tmpSalesResult WHERE wQty <0)--wQty<0  说明 仓库确实不够 则不需要自动分配
            BEGIN
                SET @pResult=0
            END;
            ELSE
            BEGIN
               IF EXISTS(
                   SELECT 1
                   FROM dbo.eStockSalesItem item
                   INNER JOIN dbo.eStockSalesDtl  dtl ON item.wStockSalesDtlRid =dtl.RowID 
                   INNER JOIN dbo.eStockSales sales ON dtl.wStockSalesRid =sales.RowID
                   INNER JOIN dbo.eStockInventory inv ON item.wPurchaseRid =inv.wPurchaseRid AND dtl.wItemRid =inv.wItemRid
                   WHERE item.wQty > inv.wQty AND sales.RowID =@pRowID  --item.wQty > inv.wQty 说明现有的批次号库存数量比销售单要销售的数量小 此时需要重新分配批次号
                  )
               BEGIN
                  SET @pResult=1
               END
               ELSE
               BEGIN
                 SET @pResult=0
               END;  
            END; 
       END; 
       ELSE
       BEGIN 
        SET @pResult=0    
       END;

      IF OBJECT_ID('tempdb..#tmpSalesResult') IS NOT NULL
      BEGIN 
        DROP TABLE #tmpSalesResult;
      END

      IF OBJECT_ID('tempdb..#tmpMoveResult') IS NOT NULL 
      BEGIN
        DROP TABLE #tmpMoveResult;
      END                                    
    END;