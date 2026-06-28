
CREATE PROCEDURE [spq].[GetStockSalesDtlLst]
    @pStockSalesRid BIGINT ,
    @pLangCd VARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'zh-tw'));
        SET @pStockSalesRid = IIF(@pStockSalesRid <= 0 , NULL, @pStockSalesRid);

        SELECT  ssd_t.RowID ,
                ssd_t.wStockSalesRid ,
                ssd_t.wItemRid ,
                ssd_t.wTotalCostHKD ,
                ssd_t.wTotalPriceHKD ,
				ssd_t.wUnitPriceHKD ,
                ssd_t.wQty ,
                ssd_t.wStatus ,
                ssd_t.wCrtDt ,
                ssd_t.wCrtBy ,
                ssd_t.wUpdDt ,
                ssd_t.wUpdBy ,
                ssd_t.wLotNo,
                'N' AS RecordState,
                wCrtByName = IIF(@pLangCd = 'en-gb', u_c.wName, u_c.wCName),
                wUpdByName = IIF(@pLangCd = 'en-gb', u_u.wName, u_u.wCName)
        FROM dbo.eStockSalesDtl ssd_t WITH(NOLOCK)
        LEFT JOIN RollsMary.dbo.mUsr u_c ON u_c.RowID = ssd_t.wCrtBy
        LEFT JOIN RollsMary.dbo.mUsr u_u ON u_u.RowID = ssd_t.wUpdBy
        WHERE ssd_t.wStatus = 'A'
            AND ssd_t.wStockSalesRid = @pStockSalesRid
    END