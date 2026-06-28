
CREATE PROCEDURE [spq].[GetStockAdjustmentItemLst]
    @pStockAdjustmentDtlRid BIGINT ,
    @pLang VARCHAR(10) ,
    @pStatus CHAR(1) ,
    @pPageNum INT = 1 ,
    @pPageSize INT = 999
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SET @pLang = LOWER(ISNULL(@pLang, ''));

        WITH    ctePurchaseDtl
                  AS ( SELECT   pd.wPurchaseRid ,
                                MAX(pd.wUnitCost * pd.wCurrRate) AS wUnitCostHKD
                       FROM     dbo.ePurchaseDtl pd
                                INNER JOIN dbo.eStockAdjustmentDtl sad ON sad.wItemRid = pd.wItemRid
                                INNER JOIN dbo.eStockAdjustmentItem sai ON sai.wStockAdjustmentDtlRid = sad.RowID
                                                                           AND sai.wPurchaseRid = pd.wPurchaseRid
                       WHERE    sad.RowID = @pStockAdjustmentDtlRid
                       GROUP BY pd.wPurchaseRid
                     ),
                cteData
                  AS ( SELECT   sai_t.RowID ,
                                sai_t.wStockAdjustmentDtlRid ,
                                sai_t.wPurchaseRid ,
                                RIGHT(p.wLotNo, LEN(p.wLotNo) - 7) AS wLotNo ,
                                p.wBatchNo ,
                                sai_t.wQty ,
                                ISNULL(pd.wUnitCostHKD, 0) AS wUnitCostHKD ,
                                sai_t.wStatus ,
                                sai_t.wCrtDt ,
                                sai_t.wCrtBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_c.wName
                                     ELSE u_c.wCName
                                END AS wCrtByName ,
                                sai_t.wUpdDt ,
                                sai_t.wUpdBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_u.wName
                                     ELSE u_u.wCName
                                END AS wUpdByName ,
                                'N' AS RecordState
                       FROM     dbo.eStockAdjustmentItem sai_t
                                LEFT JOIN dbo.ePurchase p ON p.RowID = sai_t.wPurchaseRid
                                LEFT JOIN ctePurchaseDtl pd ON pd.wPurchaseRid = p.RowID
                                LEFT JOIN RollsMary.dbo.mUsr u_c ON u_c.RowID = sai_t.wCrtBy
                                LEFT JOIN RollsMary.dbo.mUsr u_u ON u_u.RowID = sai_t.wUpdBy
                       WHERE    sai_t.wStockAdjustmentDtlRid = @pStockAdjustmentDtlRid
                                AND ( @pStatus = ' '
                                      OR sai_t.wStatus = @pStatus
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