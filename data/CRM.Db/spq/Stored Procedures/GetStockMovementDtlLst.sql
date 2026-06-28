
CREATE PROCEDURE [spq].[GetStockMovementDtlLst]
    @pStockMovementRid BIGINT ,
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
	
        WITH    cteData
                  AS ( SELECT   smd_t.RowID ,
                                smd_t.wStockMovementRid ,
                                smd_t.wSalesType ,
								smd_t.wAgentCodeIn , 
								a.wAgentCode_Display,
                                CASE WHEN @pLang = 'en-gb' THEN a.wEName
                                     ELSE a.wCName
                                END AS wAgentName ,
                                smd_t.wTotalCostHKD ,
                                smd_t.wItemRid ,
                                smd_t.wItemQty ,
                                sm_t.wStatus ,
                                smd_t.wCrtDt ,
                                smd_t.wCrtBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_c.wName
                                     ELSE u_c.wCName
                                END AS wCrtByName ,
                                smd_t.wUpdDt ,
                                smd_t.wUpdBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_u.wName
                                     ELSE u_u.wCName
                                END AS wUpdByName ,
                                'N' AS RecordState,
                                smd_t.wPurchaseRid,
                                RIGHT(p.wLotNo, LEN(p.wLotNo) - 7) AS wLotNo ,
                                p.wBatchNo ,
                                mi.wCategoryRid,
                                wCategoryName = IIF(@pLang = 'en-gb', mc.wEName, mc.wCName)
                       FROM     dbo.eStockMovementDtl smd_t
                                INNER JOIN dbo.eStockMovement sm_t ON sm_t.RowID=smd_t.wStockMovementRid
                                LEFT JOIN RollsMary.dbo.mUsr u_c ON u_c.RowID = smd_t.wCrtBy
                                LEFT JOIN RollsMary.dbo.mUsr u_u ON u_u.RowID = smd_t.wUpdBy
								LEFT JOIN RollsMary.dbo.mAgent a ON a.wAgentCodeIn = smd_t.wAgentCodeIn
                                LEFT JOIN dbo.ePurchase p ON p.RowID = smd_t.wPurchaseRid AND smd_t.wPurchaseRid > 0
                                LEFT JOIN dbo.mItem mi ON mi.RowID = smd_t.wItemRid 
                                LEFT JOIN dbo.mItemCategory mc ON mc.RowID = mi.wCategoryRid 
                       WHERE    smd_t.wStockMovementRid = @pStockMovementRid
                                AND ( @pStatus = ' '
                                      OR smd_t.wStatus = @pStatus
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