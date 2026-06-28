
CREATE PROCEDURE [spq].[GetStockAdjustmentDtlLst]
    @pStockAdjustmentRid BIGINT ,
    @pLang VARCHAR(10) ,
    @pStatus CHAR(1) ,
    @pPageNum INT = 1 ,
    @pPageSize INT = 999
AS
    BEGIN
    SET NOCOUNT ON;	  	
				
    IF @@trancount = 0
        SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        

        SET @pLang = LOWER(ISNULL(@pLang, 'en-gb'));
	
        WITH cteData AS (
            SELECT
                sad_t.RowID ,
                sad_t.wStockAdjustmentRid ,
                sad_t.wTotalCostHKD ,
                sad_t.wItemRid ,
                sad_t.wItemQty ,
                --sad_t.wStatus ,
                sad.wStatus,
                sad_t.wCrtDt ,
                sad_t.wCrtBy ,
                sad_t.wAdjustGroup,
                sad_t.wUpdDt ,
                sad_t.wUpdBy ,
                sad_i.wPurchaseRid,
                sad_i.wUnitCostHKD,
                wStockAdjustmentItemRid = sad_i.RowID,
                wLotNo = RIGHT(p.wLotNo, LEN(p.wLotNo) - 7) ,
                p.wBatchNo ,
                mi.wCategoryRid,
                wCategoryName = IIF(@pLang = 'en-gb', mc.wEName, mc.wCName),
                wItemName = IIF(@pLang = 'en-gb', mi.wEName, mi.wCName),
                wCrtByName = IIF(@pLang = 'en-gb', u_c.wName, u_c.wCName),
                wUpdByName = IIF(@pLang = 'en-gb', u_u.wName, u_u.wCName),
                RecordState = 'U'
            FROM dbo.eStockAdjustmentDtl sad_t
            INNER JOIN dbo.eStockAdjustment sad ON sad.RowID=sad_t.wStockAdjustmentRid
            LEFT JOIN dbo.eStockAdjustmentItem sad_i ON sad_i.wStockAdjustmentDtlRid = sad_t.RowID
            LEFT JOIN dbo.mItem mi ON mi.RowID = sad_t.wItemRid
            LEFT JOIN dbo.mItemCategory mc ON mc.RowID = mi.wCategoryRid
            LEFT JOIN dbo.ePurchase p ON p.RowID = sad_i.wPurchaseRid
            LEFT JOIN RollsMary.dbo.mUsr u_c ON u_c.RowID = sad_t.wCrtBy
            LEFT JOIN RollsMary.dbo.mUsr u_u ON u_u.RowID = sad_t.wUpdBy
            WHERE sad_t.wStockAdjustmentRid = @pStockAdjustmentRid
                AND ( @pStatus = ' ' OR sad_t.wStatus = @pStatus )
        ),
        cteCount AS (
            SELECT wRecordCount = COUNT(*) FROM cteData
        )
        
        SELECT  d.* , c.wRecordCount
        FROM cteData d , cteCount c
        ORDER BY d.RowID DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY
        --OPTION  ( RECOMPILE );
    END;