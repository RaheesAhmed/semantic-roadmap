
CREATE PROCEDURE [spq].[GetStockSalesDtlLstByItem]
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
        
        SET @pLang = LOWER(ISNULL(@pLang, 'zh-tw'));
	
        WITH    cteData
                  AS ( SELECT   ssd.RowID ,
                                wOutWarehouseRid ,
                                wRefNo ,
                                wPaymentMethod ,
                                wSalesDt ,
                                CASE WHEN @pLang = 'en-gb' THEN u_s.wName
                                     ELSE u_s.wCName
                                END AS wSalesmanName ,
                                wDebitAgentCodeIn ,
                                a_d.wAgentCode_Display AS wDebitAgentCode_Display ,
                                CASE WHEN @pLang = 'en-gb' THEN a_d.wEName
                                     ELSE a_d.wCName
                                END AS wDebitAgentName ,
                                wRecipientAgentCodeIn ,
                                a_r.wAgentCode_Display AS wRecipientAgentCode_Display ,
                                CASE WHEN @pLang = 'en-gb' THEN a_r.wEName
                                     ELSE a_r.wCName
                                END AS wRecipientAgentName ,
                                wSalesTotalPrice ,
                                wSalesStatus ,
                                ssd.wStockSalesRid ,
                                ssd.wItemRid ,
                                CASE WHEN @pLang = 'en-gb' THEN i.wEName
                                     ELSE i.wCName
                                END AS wItemName ,
                                ssd.wTotalCostHKD ,
                                ssd.wTotalPriceHKD ,
								ssd.wUnitPriceHKD ,
                                ssd.wQty ,
                                ssd.wCrtDt ,
                                ssd.wCrtBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_c.wName
                                     ELSE u_c.wCName
                                END AS wCrtByName ,
                                ssd.wUpdDt ,
                                ssd.wUpdBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_u.wName
                                     ELSE u_u.wCName
                                END AS wUpdByName ,
                                ssd.wStatus ,
                                'N' AS RecordState
                       FROM     dbo.eStockSalesDtl ssd
                                INNER JOIN dbo.eStockSales ss ON ss.RowID = ssd.wStockSalesRid
                                                                 AND ss.wStatus = 'A'
                                LEFT JOIN dbo.mItem i ON i.RowID = ssd.wItemRid
                                LEFT JOIN RollsMary.dbo.mAgent a_d ON a_d.wAgentCodeIn = ss.wDebitAgentCodeIn
                                LEFT JOIN RollsMary.dbo.mAgent a_r ON a_r.wAgentCodeIn = ss.wRecipientAgentCodeIn
                                LEFT JOIN RollsMary.dbo.mUsr u_c ON u_c.RowID = ssd.wCrtBy
                                LEFT JOIN RollsMary.dbo.mUsr u_u ON u_u.RowID = ssd.wUpdBy
                                LEFT JOIN RollsMary.dbo.mUsr u_s ON u_s.RowID = ss.wSalesmanRid
                       WHERE    ss.wOutWarehouseRid = @pWarehouseRid
                                AND ssd.wItemRid = @pItemRid
                                AND ssd.wStatus = 'A'
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