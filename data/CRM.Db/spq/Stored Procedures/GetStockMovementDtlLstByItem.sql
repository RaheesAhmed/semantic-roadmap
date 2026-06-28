
CREATE PROCEDURE [spq].[GetStockMovementDtlLstByItem]
    @pWarehouseRid BIGINT ,
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
	
        WITH    cteData
                  AS ( SELECT   smd.RowID ,
                                smd.wStockMovementRid ,
                                smd.wSalesType ,
                                smd.wAgentCodeIn ,
                                sm.wOutWarehouseRid ,
                                CASE WHEN @pLang = 'en-gb' THEN w_o.wEName
                                     ELSE w_o.wCName
                                END AS wOutWarehouseName ,
                                sm.wInWarehouseRid ,
                                CASE WHEN @pLang = 'en-gb' THEN w_i.wEName
                                     ELSE w_i.wCName
                                END AS wInWarehouseName ,
                                smd.wTotalCostHKD ,
                                smd.wItemRid ,
                                CASE WHEN @pLang = 'en-gb' THEN i.wEName
                                     ELSE i.wCName
                                END AS wItemName ,
                                smd.wItemQty ,
                                sm.wMovementStatus ,
                                smd.wCrtDt ,
                                smd.wCrtBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_c.wName
                                     ELSE u_c.wCName
                                END AS wCrtByName ,
                                smd.wUpdDt ,
                                smd.wUpdBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_u.wName
                                     ELSE u_u.wCName
                                END AS wUpdByName ,
                                sm.wStatus ,
                                'N' AS RecordState
                       FROM     dbo.eStockMovementDtl smd
                                LEFT JOIN dbo.eStockMovement sm ON sm.RowID = smd.wStockMovementRid
                                INNER JOIN dbo.mWarehouse w_o ON w_o.RowID = sm.wOutWarehouseRid
                                INNER JOIN dbo.mWarehouse w_i ON w_i.RowID = sm.wInWarehouseRid
                                INNER JOIN dbo.mItem i ON i.RowID = smd.wItemRid
                                LEFT JOIN RollsMary.dbo.mUsr u_c ON u_c.RowID = sm.wCrtBy
                                LEFT JOIN RollsMary.dbo.mUsr u_u ON u_u.RowID = sm.wUpdBy
                       WHERE    ( sm.wInWarehouseRid = @pWarehouseRid
                                  OR sm.wOutWarehouseRid = @pWarehouseRid
                                )
                                AND smd.wItemRid = @pItemRid
                                AND smd.wStatus = 'A'
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