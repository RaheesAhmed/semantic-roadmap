CREATE PROCEDURE [spq].[GetPurchaseDtlLstByItem]
    @pWarehouseRid BIGINT ,
    @pPurchaseRid BIGINT ,
    @pItemRid BIGINT,

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
                  AS ( SELECT   p_t.RowID ,
                                RIGHT(p_t.wLotNo, LEN(p_t.wLotNo) - 7) AS wLotNo ,
                                p_t.wBatchNo ,
                                p_t.wVendorRid ,
                                CASE WHEN @pLang = 'en-gb' THEN v.wEName
                                     ELSE v.wCName
                                END AS wVendorName ,
                                p_t.wInWarehouseRid ,
                                CASE WHEN @pLang = 'en-gb' THEN w.wEName
                                     ELSE w.wCName
                                END AS wWarehouseName ,
                                pd_t.wItemRid ,
                                CASE WHEN @pLang = 'en-gb' THEN i.wEName
                                     ELSE i.wCName
                                END AS wItemName ,
                                p_t.wAgentCodeIn ,
                                a.wAgentCode_Display ,
                                CASE WHEN @pLang = 'en-gb' THEN a.wEName
                                     ELSE a.wCName
                                END AS wAgentName ,
                                pd_t.wUnitCost ,
                                pd_t.wQty ,
                                pd_t.wStockInQty ,
                                p_t.wCurrCode ,
                                p_t.wCurrRate ,
                                wCost = (pd_t.wUnitCost * pd_t.wQty) ,
                                p_t.wType ,
                                p_t.wRemarks ,
                                p_t.wPurchaseStatus ,
                                p_t.wPayExpiryDt ,
                                p_t.wSettleBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u.wName
                                     ELSE u.wCName
                                END AS wSettleByName ,
                                p_t.wSettleDt ,
                                p_t.wStatus ,
                                p_t.wCrtDt ,
                                p_t.wCrtBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_c.wName
                                     ELSE u_c.wCName
                                END AS wCrtByName ,
                                p_t.wUpdDt ,
                                p_t.wUpdBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_u.wName
                                     ELSE u_u.wCName
                                END AS wUpdByName ,
                                'N' AS RecordState,
                                pd_t.wStatus AS wStatusDtl
                       FROM     dbo.ePurchaseDtl pd_t
                                INNER JOIN dbo.ePurchase p_t ON p_t.RowID = pd_t.wPurchaseRid
                                INNER JOIN dbo.mVendor v ON v.RowID = p_t.wVendorRid
                                INNER JOIN dbo.mWarehouse w ON w.RowID = p_t.wInWarehouseRid
                                INNER JOIN dbo.mItem i ON i.RowID = pd_t.wItemRid
                                INNER JOIN ctePurchaseLst pl ON pl.RowID = p_t.RowID
                                LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = p_t.wSettleBy
                                LEFT JOIN RollsMary.dbo.mUsr u_c ON u_c.RowID = p_t.wCrtBy
                                LEFT JOIN RollsMary.dbo.mUsr u_u ON u_u.RowID = p_t.wUpdBy
                                LEFT JOIN RollsMary.dbo.mAgent a ON a.wAgentCodeIn = p_t.wAgentCodeIn
                       WHERE    (@pWarehouseRid = 0 OR p_t.wInWarehouseRid = @pWarehouseRid)
                                AND ( @pWarehouseRid > 0 OR p_t.RowID = @pPurchaseRid)
                                AND pd_t.wItemRid = @pItemRid
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