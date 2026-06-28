
CREATE PROCEDURE [spq].[GetStockSalesItemLst]
    @pStockSalesDtlRid BIGINT ,
    @pLang VARCHAR(10) ,
    @pStatus CHAR(1) ,
    @pPageNum INT = 1 ,
    @pPageSize INT = 999
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 
			
        SET @pLang = UPPER(ISNULL(@pLang, 'zh-tw'));
       
	
        WITH    cteData
                  AS ( SELECT   ssi_t.RowID ,
                                ssi_t.wStockSalesDtlRid ,
                                ssi_t.wPurchaseRid ,                                
								RIGHT(p.wLotNo, LEN(p.wLotNo) - 7) AS wLotNo ,
                                ISNULL(p.wBatchNo,'') AS wBatchNo ,
                                ssi_t.wQty ,
                                ssi_t.wUnitCostHKD ,
                                ssi_t.wStatus ,
                                ssi_t.wCrtDt ,
                                ssi_t.wCrtBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_c.wName
                                     ELSE u_c.wCName
                                END AS wCrtByName ,
                                ssi_t.wUpdDt ,
                                ssi_t.wUpdBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_u.wName
                                     ELSE u_u.wCName
                                END AS wUpdByName ,
                                'N' AS RecordState
                       FROM     dbo.eStockSalesItem ssi_t
                                LEFT JOIN dbo.ePurchase p ON p.RowID = ssi_t.wPurchaseRid
                                LEFT JOIN RollsMary.dbo.mUsr u_c ON u_c.RowID = ssi_t.wCrtBy
                                LEFT JOIN RollsMary.dbo.mUsr u_u ON u_u.RowID = ssi_t.wUpdBy
                       WHERE    ( @pStockSalesDtlRid = 0
                                  OR ssi_t.wStockSalesDtlRid = @pStockSalesDtlRid
                                )
                                AND ( @pStatus = ' '
                                      OR ssi_t.wStatus = @pStatus
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