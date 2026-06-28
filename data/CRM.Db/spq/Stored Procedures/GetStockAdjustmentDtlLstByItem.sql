
CREATE PROCEDURE [spq].[GetStockAdjustmentDtlLstByItem]
    @pWarehouseRid BIGINT ,
    @pPurchaseRid BIGINT ,
    @pItemRid BIGINT ,
    @pLang VARCHAR(10) ,
    @pPageNum INT = 1 ,
    @pPageSize INT = 999
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
        
        SET @pLang = LOWER(ISNULL(@pLang, ''));
	
        WITH    ctePurchase
                  AS ( SELECT   wLotNo
                       FROM     dbo.ePurchase
                       WHERE    RowID = @pPurchaseRid
                     ),
                ctePurchaseLst
                  AS ( SELECT   RowID
                       FROM     dbo.ePurchase p
                                INNER JOIN ctePurchase pl ON pl.wLotNo = p.wLotNo
                       WHERE    p.wStatus = 'A'
                     ),
                cteData
                  AS ( SELECT   sai.RowID ,
                                sad.wStockAdjustmentRid ,
                                sai.wStockAdjustmentDtlRid ,
                                sai.wPurchaseRid ,
                                p.wLotNo ,
                                sa.wWarehouseRid ,
                                CASE WHEN @pLang = 'en-gb' THEN w.wEName
                                     ELSE w.wCName
                                END AS wWarehouseName ,
                                sad.wItemRid ,
                                CASE WHEN @pLang = 'en-gb' THEN i.wEName
                                     ELSE i.wCName
                                END AS wItemName ,
                                sai.wQty ,
                                sai.wUnitCostHKD ,
                                --p.wCost AS wPurchaseCost ,
                                wPurchaseCost=(sai.wQty*sai.wUnitCostHKD),
                                a.wAgentCode_Display ,
                                CASE WHEN @pLang = 'en-gb' THEN a.wEName
                                     ELSE a.wCName
                                END AS wAgentName ,
                                sa.wApprovalByRid ,
                                CASE WHEN @pLang = 'en-gb' THEN u.wName
                                     ELSE u.wCName
                                END AS wApprovalByName ,
                                sa.wAdjustDt ,
                                sa.wAdjustmentStatus ,
                                sai.wCrtDt ,
                                sai.wCrtBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_c.wName
                                     ELSE u_c.wCName
                                END AS wCrtByName ,
                                sai.wUpdDt ,
                                sai.wUpdBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_u.wName
                                     ELSE u_u.wCName
                                END AS wUpdByName ,
                                sa.wStatus ,
                                'N' AS RecordState
                       FROM     dbo.eStockAdjustmentItem sai
                                LEFT JOIN dbo.eStockAdjustmentDtl sad ON sad.RowID = sai.wStockAdjustmentDtlRid
                                LEFT JOIN dbo.eStockAdjustment sa ON sa.RowID = sad.wStockAdjustmentRid
                                INNER JOIN ctePurchaseLst pl ON pl.RowID = sai.wPurchaseRid
                                INNER JOIN dbo.ePurchase p ON p.RowID = sai.wPurchaseRid
                                INNER JOIN dbo.mWarehouse w ON w.RowID = sa.wWarehouseRid
                                INNER JOIN dbo.mItem i ON i.RowID = sad.wItemRid
                                LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = sa.wApprovalByRid
                                LEFT JOIN RollsMary.dbo.mUsr u_c ON u_c.RowID = sa.wCrtBy
                                LEFT JOIN RollsMary.dbo.mUsr u_u ON u_u.RowID = sa.wUpdBy
                                LEFT JOIN RollsMary.dbo.mAgent a ON a.wAgentCodeIn = p.wAgentCodeIn
                       WHERE    sa.wWarehouseRid = @pWarehouseRid
                                --AND sai.wPurchaseRid = @pPurchaseRid
                                AND sad.wItemRid = @pItemRid
								AND sai.wStatus='A'
                     ),
                cteCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     cteData
                     )
            SELECT  d.* ,
                    c.wRecordCount
            FROM    cteData d ,
                    cteCount c
            ORDER BY d.RowID DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );
    END;