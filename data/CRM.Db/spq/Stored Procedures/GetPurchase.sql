
CREATE PROCEDURE [spq].[GetPurchase] 
    @pRowID     BIGINT,
    @pLangCd    VARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

        SELECT
            RowID ,
            wLotNo ,
            wBatchNo ,
            wVendorRid ,
            wInWarehouseRid ,
            wAgentCodeIn ,
            wCurrCode ,
            wCurrRate ,
            wCost ,
            wType ,
            wRemarks ,
            wPurchaseStatus ,
            wPayExpiryDt ,
            wSettleBy ,
            wSettleDt ,
            wStatus ,
            wCrtDt ,
            wCrtBy ,
            wUpdDt ,
            wUpdBy ,
            wNoticeRecord ,
            wStoreLocation ,
            wMaturityDate,
            wGuestCodeIn,
            wReceiptDate,
            wNotifier,
            wTelephone,
            wServiceCounterRid,
            wPurchaseCounterRid,
            wStoreWarehouse = CAST('' AS NVARCHAR(4000)), -- 現存倉庫
            'N' AS RecordState
        INTO #tResult
        FROM dbo.ePurchase WITH(NOLOCK)
        WHERE @pRowID = RowID; 
        
        --WITH tStockAdjustmentSum AS (
        --    SELECT
        --        sai.wPurchaseRid, 
        --        sad.wItemRid, 
        --        sa.wWarehouseRid,
        --        wQty = SUM(sai.wQty)
        --    FROM dbo.eStockAdjustment sa
        --    INNER JOIN dbo.eStockAdjustmentDtl sad ON sad.wStockAdjustmentRid = sa.RowID AND sad.wStatus = 'A'
        --    INNER JOIN dbo.eStockAdjustmentItem sai ON sai.wStockAdjustmentDtlRid = sad.RowID AND sai.wStatus = 'A'
        --    GROUP BY sai.wPurchaseRid, sad.wItemRid, sa.wWarehouseRid
        --),
        WITH tStockSaleSum AS (
            SELECT
                ssi.wPurchaseRid, 
                ssd.wItemRid, 
                wWarehouseRid = ss.wOutWarehouseRid,
                wQty = SUM(ssi.wQty)
            FROM dbo.eStockSales ss WITH(NOLOCK)
            INNER JOIN dbo.eStockSalesDtl ssd WITH(NOLOCK) ON ssd.wStockSalesRid = ss.RowID AND ssd.wStatus = 'A'
            INNER JOIN dbo.eStockSalesItem ssi WITH(NOLOCK) ON ssi.wStockSalesDtlRid = ssd.RowID AND ssi.wStatus = 'A'
            GROUP BY ssi.wPurchaseRid, ssd.wItemRid, ss.wOutWarehouseRid
        )

        UPDATE r 
        SET wStoreWarehouse = STUFF(
            (SELECT DISTINCT CONCAT( ',', CHAR(10), IIF(@pLangCd = 'en-gb', mw.wEName, mw.wCName)) 
            FROM dbo.eStockInventory si WITH(NOLOCK)
            INNER JOIN dbo.mWarehouse mw WITH(NOLOCK) ON mw.RowID = si.wWarehouseRid
            --LEFT JOIN tStockAdjustmentSum sa ON sa.wPurchaseRid = si.wPurchaseRid AND sa.wItemRid = si.wItemRid AND sa.wWarehouseRid = si.wWarehouseRid
            LEFT JOIN tStockSaleSum ss ON ss.wPurchaseRid = si.wPurchaseRid AND ss.wItemRid = si.wItemRid AND ss.wWarehouseRid = si.wWarehouseRid
            WHERE si.wPurchaseRid = r.RowID AND si.wStatus = 'A' AND (si.wQty + ISNULL(ss.wQty, 0)) > 0
            FOR XML PATH('')), 1, 2, N'')
        FROM #tResult r;

        SELECT * FROM #tResult;
    END;