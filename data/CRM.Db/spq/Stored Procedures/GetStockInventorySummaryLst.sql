
CREATE PROCEDURE [spq].[GetStockInventorySummaryLst]
    @pWarehouseRid BIGINT ,
    @pItemRid BIGINT ,
    @pCategoryRid BIGINT ,
    @pAgentCodeIn VARCHAR(14) ,
    @pLang VARCHAR(10) ,
    @pStatus CHAR(1) ,
    @pLotNo VARCHAR(50) ,
    @pHadStockGoods  VARCHAR(50),
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
                                si_t.wQty ,
                                si_t.wOnHoldQty ,
                                si_t.wOriQty ,
                                si_t.wStatus ,
                                si_t.wCrtDt ,
                                si_t.wUpdDt
                       FROM     dbo.eStockInventory si_t
                                LEFT JOIN dbo.ePurchase p ON si_t.wPurchaseRid = p.RowID
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
                cteGrpData
                  AS ( SELECT   wWarehouseRid ,
                                MAX(wPurchaseRid) AS wPurchaseRid ,
                                wCategoryRid ,
                                MAX(wCategoryName) AS wCategoryName ,
                                wItemRid ,
                                wLotNo ,
                                SUM(wQty) AS wQty ,
                                SUM(wOnHoldQty) AS wOnHoldQty ,
                                SUM(wOriQty) AS wOriQty ,
                                'N' AS RecordState
                       FROM     cteData
                       GROUP BY wWarehouseRid ,
                                wCategoryRid ,
                                wItemRid ,
                                wLotNo
                     ),
                cteFilterData
                  AS ( SELECT *
                       FROM cteGrpData
                       WHERE (@pHadStockGoods IS NULL OR @pHadStockGoods ='' 
                              OR (@pHadStockGoods ='YES' AND (wQty >0 OR wOnHoldQty >0))
                              OR (@pHadStockGoods ='NO'AND wQty<=0 AND wOnHoldQty<=0)
                             ) 
                     ),
                cteCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     cteFilterData
                     )
            SELECT  d.* ,
                    c.wRecordCount
            FROM    cteFilterData d ,
                    cteCount c            
            ORDER BY d.wWarehouseRid DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );
    END;