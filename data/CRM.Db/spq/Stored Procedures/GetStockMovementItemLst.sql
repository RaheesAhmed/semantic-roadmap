
CREATE PROCEDURE [spq].[GetStockMovementItemLst]
    @pStockMovementDtlRid BIGINT ,
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
                  AS ( SELECT   smi_t.RowID ,
                                smi_t.wStockMovementDtlRid ,
                                smi_t.wPurchaseRid ,
                                RIGHT(p.wLotNo, LEN(p.wLotNo) - 7) AS wLotNo ,
								p.wBatchNo ,
                                smi_t.wQty ,
                                smi_t.wUnitCostHKD ,
                                smi_t.wStatus ,
                                smi_t.wCrtDt ,
                                smi_t.wCrtBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_c.wName
                                     ELSE u_c.wCName
                                END AS wCrtByName ,
                                smi_t.wUpdDt ,
                                smi_t.wUpdBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_u.wName
                                     ELSE u_u.wCName
                                END AS wUpdByName ,
                                'N' AS RecordState
                       FROM     dbo.eStockMovementItem smi_t
                                LEFT JOIN dbo.ePurchase p ON p.RowID = smi_t.wPurchaseRid
                                LEFT JOIN RollsMary.dbo.mUsr u_c ON u_c.RowID = smi_t.wCrtBy
                                LEFT JOIN RollsMary.dbo.mUsr u_u ON u_u.RowID = smi_t.wUpdBy
                       WHERE    smi_t.wStockMovementDtlRid = @pStockMovementDtlRid
                                AND ( @pStatus = ' '
                                      OR smi_t.wStatus = @pStatus
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