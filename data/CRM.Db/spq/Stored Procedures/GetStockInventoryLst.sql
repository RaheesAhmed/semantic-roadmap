
CREATE PROCEDURE [spq].[GetStockInventoryLst]
    @pWarehouseRid BIGINT ,
    @pItemRid BIGINT ,
    @pCategoryRid BIGINT ,
    @pAgentCodeIn VARCHAR(14) ,
    @pLang VARCHAR(10) ,
    @pStatus CHAR(1) ,
    @pLotNo VARCHAR(50) ,
    @pPageNum INT = 1 ,
    @pPageSize INT = 999
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        SET @pLang = LOWER(@pLang);

        SET @pAgentCodeIn = ISNULL(@pAgentCodeIn, '');
        SET @pLang = LOWER(ISNULL(@pLang, ''));    
	
        WITH    cteData
                  AS ( SELECT   si_t.RowID ,
                                si_t.wWarehouseRid ,
                                si_t.wPurchaseRid ,
                                si_t.wItemRid ,
                                i.wCategoryRid ,
                                CASE WHEN @pLang = 'en-gb' THEN ic.wEName
                                     ELSE ic.wCName
                                END AS wCategoryName ,
                                RIGHT(p.wLotNo, LEN(p.wLotNo) - 7) AS wLotNo ,
                                ISNULL(p.wBatchNo, '') AS wBatchNo ,
                                ISNULL(p.wAgentCodeIn, '') AS wAgentCodeIn ,
                                si_t.wQty ,
                                si_t.wOnHoldQty ,
                                si_t.wOriQty ,
                                si_t.wStatus ,
                                si_t.wCrtDt ,
                                si_t.wUpdDt ,
                                wPrice = ISNULL(i.wPrice, 0),
                                wUnitCost =pdtl.wUnitCost * pdtl.wCurrRate,
                                'N' AS RecordState
                       FROM     dbo.eStockInventory si_t
                                LEFT JOIN dbo.ePurchase p ON si_t.wPurchaseRid = p.RowID
                                LEFT JOIN dbo.ePurchaseDtl pdtl ON pdtl.wPurchaseRid = si_t.wPurchaseRid AND pdtl.wItemRid = si_t.wItemRid
                                LEFT JOIN mItem i ON i.RowID = si_t.wItemRid
                                LEFT JOIN dbo.mItemCategory ic ON ic.RowID = i.wCategoryRid
                       WHERE    ( @pWarehouseRid = 0
                                  OR si_t.wWarehouseRid = @pWarehouseRid
                                )
                                AND ( @pLotNo = ''
                                      OR RIGHT(p.wLotNo, LEN(p.wLotNo) - 7) = @pLotNo
                                    )
                                AND ( @pItemRid = 0
                                      OR si_t.wItemRid = @pItemRid
                                    )
                                AND ( @pCategoryRid = 0
                                      OR i.wCategoryRid = @pCategoryRid
                                    )
                                AND ( @pAgentCodeIn = ''
                                      OR p.wAgentCodeIn = @pAgentCodeIn
                                    )
                                AND ( @pStatus = ' '
                                      OR si_t.wStatus = @pStatus
                                    )
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