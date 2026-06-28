
CREATE PROCEDURE [spq].[GetItemSerialLstByItem]
    @pItemRid BIGINT ,
    @pPurchaseRid BIGINT ,
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
	
        WITH    cteData
                  AS ( SELECT   is_t.RowID ,
                                is_t.wItemRid ,
                                i.wCategoryRid ,
                                is_t.wSerialNo ,
                                is_t.wPurchaseRid ,
                                p.wLotNo ,
                                is_t.wStatus ,
								is_t.wCrtBy,
                                is_t.wCrtDt ,
                                CASE WHEN @pLang = 'en-gb' THEN u_c.wName
                                     ELSE u_c.wCName
                                END AS wCrtByName ,
								is_t.wUpdBy,
                                is_t.wUpdDt ,
                                CASE WHEN @pLang = 'en-gb' THEN u_u.wName
                                     ELSE u_u.wCName
                                END AS wUpdByName ,
                                'N' AS RecordState
                       FROM     dbo.mItemSerial is_t WITH(NOLOCK)
                                INNER JOIN dbo.ePurchase p WITH(NOLOCK) ON p.RowID = is_t.wPurchaseRid
                                LEFT JOIN dbo.mItem i WITH(NOLOCK) ON i.RowID = is_t.wItemRid
                                LEFT JOIN RollsMary.dbo.mUsr u_c WITH(NOLOCK) ON u_c.RowID = is_t.wCrtBy
                                LEFT JOIN RollsMary.dbo.mUsr u_u WITH(NOLOCK) ON u_u.RowID = is_t.wUpdBy
                       WHERE    i.RowID = @pItemRid
                                AND ( is_t.wPurchaseRid = @pPurchaseRid
                                      OR @pPurchaseRid = 0
                                    )
                                AND ( @pStatus = ' '
                                      OR is_t.wStatus = @pStatus
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