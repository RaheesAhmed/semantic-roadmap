
CREATE PROCEDURE [spq].[GetStockAdjustmentLst]
    @pWarehouseRid BIGINT ,
    @pAdjustFromDt DATETIME2 ,
    @pAdjustToDt DATETIME2 ,
    @pAdjustmentStatus VARCHAR(30) ,
    @pAgentCodeIn VARCHAR(14) ,
    @pDepartmentCode VARCHAR(30) ,
    @pWarehouseRidXML XML ,
    @pLang VARCHAR(10) ,
    @pStatus CHAR(1) ,
    @pPageNum INT = 1 ,
    @pPageSize INT = 999
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        SET @pLang = LOWER(@pLang);
		
        SET @pAdjustmentStatus = ISNULL(@pAdjustmentStatus, '');
        SET @pAdjustFromDt = ISNULL(@pAdjustFromDt, '1900-01-01');
        SET @pAdjustToDt = ISNULL(@pAdjustToDt, '2099-12-31');    
        SET @pAgentCodeIn = ISNULL(@pAgentCodeIn, '');
        SET @pLang = UPPER(ISNULL(@pLang, ''));
        SET @pDepartmentCode = ISNULL(@pDepartmentCode, '');
	
        DECLARE @vWarehouseRidCount INT;
        DECLARE @vData_WarehouseRid AS TABLE ( SelectionItem BIGINT );
	
        IF CAST(@pWarehouseRidXML AS NVARCHAR(MAX)) != N'<DataSet/>'
            BEGIN
                INSERT  INTO @vData_WarehouseRid
                        ( SelectionItem
                        )
                        SELECT  tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
                        FROM    @pWarehouseRidXML.nodes('/DataSet/Record') AS T ( tmp );
            END;

        SET @vWarehouseRidCount = ( SELECT  COUNT(1)
                                    FROM    @vData_WarehouseRid
                                  );

        WITH    ctePurchase
                  AS ( SELECT   RowID ,
                                wAgentCodeIn ,
                                wStatus
                       FROM     dbo.ePurchase p
                       WHERE    p.wStatus = 'A'
                     ),
                cteAdjustmentAgent
                  AS ( SELECT   DISTINCT
                                sa.RowID AS wStockAdjustmentRid
                       FROM     ctePurchase p
                                RIGHT JOIN dbo.eStockAdjustmentItem sai ON p.RowID = sai.wPurchaseRid
                                                                           AND sai.wStatus = 'A'
                                RIGHT JOIN dbo.eStockAdjustmentDtl sad ON sad.RowID = sai.wStockAdjustmentDtlRid
                                                                          AND sad.wStatus = 'A'
                                RIGHT JOIN dbo.eStockAdjustment sa ON sa.RowID = sad.wStockAdjustmentRid
                       WHERE    ( @pWarehouseRid = 0
                                  OR sa.wWarehouseRid = @pWarehouseRid
                                )
                                AND ( @pAdjustFromDt <= sa.wAdjustDt
                                      AND @pAdjustToDt >= sa.wAdjustDt
                                    )
                                AND ( @pAdjustmentStatus = ''
                                      OR sa.wAdjustmentStatus = @pAdjustmentStatus
                                    )
                                AND ( @pStatus = ' '
                                      OR sa.wStatus = @pStatus
                                    )
                                AND ( @pAgentCodeIn = ''
                                      OR p.wAgentCodeIn = @pAgentCodeIn
                                    )
                     ),
                cteData
                  AS ( SELECT   sa_t.RowID ,
                                sa_t.wWarehouseRid ,
                                sa_t.wApprovalByRid ,
                                CASE WHEN @pLang = 'en-gb' THEN u.wName
                                     ELSE u.wCName
                                END AS wApprovalByName ,
                                CASE WHEN @pLang = 'en-gb' THEN w.wEName
                                     ELSE w.wCName
                                END AS wWarehouseName ,
                                sa_t.wAdjustDt ,
                                sa_t.wRemarks ,
                                sa_t.wAdjustmentStatus ,
                                sa_t.wStatus ,
                                sa_t.wCrtDt ,
                                sa_t.wCrtBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_c.wName
                                     ELSE u_c.wCName
                                END AS wCrtByName ,
                                sa_t.wUpdDt ,
                                sa_t.wUpdBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_u.wName
                                     ELSE u_u.wCName
                                END AS wUpdByName ,
                                'N' AS RecordState
                       FROM     dbo.eStockAdjustment sa_t
                                INNER JOIN cteAdjustmentAgent aa ON aa.wStockAdjustmentRid = sa_t.RowID
                                LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = sa_t.wApprovalByRid
                                LEFT JOIN RollsMary.dbo.mUsr u_c ON u_c.RowID = sa_t.wCrtBy
                                LEFT JOIN RollsMary.dbo.mUsr u_u ON u_u.RowID = sa_t.wUpdBy
                                LEFT JOIN dbo.mWarehouse w ON w.RowID = sa_t.wWarehouseRid
                                LEFT JOIN @vData_WarehouseRid v ON v.SelectionItem = sa_t.wWarehouseRid
                       WHERE    ( @pWarehouseRid = 0
                                  OR sa_t.wWarehouseRid = @pWarehouseRid
                                )
                                AND ( @pAdjustFromDt <= sa_t.wAdjustDt
                                      AND @pAdjustToDt >= sa_t.wAdjustDt
                                    )
                                AND ( @pAdjustmentStatus = ''
                                      OR sa_t.wAdjustmentStatus = @pAdjustmentStatus
                                    )
                                AND ( @pStatus = ' '
                                      OR sa_t.wStatus = @pStatus
                                    )
                                AND ( @pDepartmentCode = ''
                                      OR w.wDepartmentCode = @pDepartmentCode
                                    )
                                AND ( @vWarehouseRidCount <= 0
                                      OR v.SelectionItem IS NOT NULL
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
            ORDER BY d.wCrtDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );
    END;