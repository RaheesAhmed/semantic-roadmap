

CREATE PROCEDURE [spq].[GetStockInventoryTotalLst]
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

        SET @pAgentCodeIn = ISNULL(@pAgentCodeIn, '');
        SET @pLang = LOWER(ISNULL(@pLang, ''));    
	
        WITH cteData AS (
            SELECT 
                si.wWarehouseRid ,
                si.wItemRid ,
                i.wCategoryRid ,
                wCategoryName=CASE WHEN @pLang = 'en-gb' THEN ic.wEName ELSE ic.wCName END,
                si.wQty ,
                si.wOnHoldQty ,
                si.wOriQty
            FROM  dbo.eStockInventory si
            LEFT JOIN dbo.ePurchase p ON si.wPurchaseRid = p.RowID
            LEFT JOIN mItem i ON i.RowID = si.wItemRid
            LEFT JOIN dbo.mItemCategory ic ON ic.RowID = i.wCategoryRid
            WHERE ( @pWarehouseRid IS NULL OR @pWarehouseRid = 0 OR si.wWarehouseRid = @pWarehouseRid )
                AND ( @pLotNo IS NULL OR @pLotNo = '' OR RIGHT(p.wLotNo, LEN(p.wLotNo) - 7) = @pLotNo )
                AND ( @pItemRid IS NULL OR @pItemRid = 0 OR si.wItemRid = @pItemRid )
                AND ( @pCategoryRid IS NULL OR @pCategoryRid = 0 OR i.wCategoryRid = @pCategoryRid )
                AND ( @pAgentCodeIn IS NULL OR @pAgentCodeIn = '' OR p.wAgentCodeIn = @pAgentCodeIn ) 
                AND ( @pStatus IS NULL OR @pStatus = ' ' OR si.wStatus = @pStatus )                                                  
        ),
        cteGrpData AS (
            SELECT 
                wWarehouseRid , 
                wCategoryRid ,
                MAX(wCategoryName) AS wCategoryName ,
                wItemRid ,  
                SUM(wQty) AS wQty ,
                SUM(wOnHoldQty) AS wOnHoldQty ,
                SUM(wOriQty) AS wOriQty ,
                'N' AS RecordState
            FROM   cteData
            GROUP BY wWarehouseRid , wCategoryRid , wItemRid
        ),
        cteFilterData AS (
            SELECT *
            FROM cteGrpData
            WHERE ( NULLIF(@pHadStockGoods, '') IS NULL
                    OR (@pHadStockGoods ='YES' AND (wQty >0 OR wOnHoldQty >0))
                    OR (@pHadStockGoods ='NO'AND wQty<=0 AND wOnHoldQty<=0)
                ) 
        ),
        cteCount  AS (
            SELECT wRecordCount = COUNT(*) FROM cteFilterData
        )

        SELECT d.* ,
               c.wRecordCount
        FROM cteFilterData d , 
             cteCount c            
        ORDER BY d.wWarehouseRid DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	    FETCH NEXT @pPageSize ROWS ONLY
        OPTION ( RECOMPILE );
    END;