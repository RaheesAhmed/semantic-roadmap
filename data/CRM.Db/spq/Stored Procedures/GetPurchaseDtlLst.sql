
CREATE PROCEDURE [spq].[GetPurchaseDtlLst]
    @pPurchaseRid BIGINT ,
    @pLangCd VARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        

        SET @pLangCd = LOWER(ISNULL(NULLIF(@pLangCd, ''), 'zh-tw'));
        SET @pPurchaseRid = IIF(@pPurchaseRid <= 0, NULL, @pPurchaseRid);
	
        WITH cteSerialItem AS ( 
            SELECT  wItemRid ,
                    wCount = COUNT(1)
            FROM    dbo.mItemSerial WITH(NOLOCK)
            WHERE   wStatus = 'A'
                AND wPurchaseRid = @pPurchaseRid
            GROUP BY wItemRid
        )
        
        SELECT  pd_t.RowID ,
                pd_t.wPurchaseRid ,
                pd_t.wCurrCode ,
                pd_t.wCurrRate ,
                pd_t.wUnitCost ,
                pd_t.wQty ,
                pd_t.wStockInQty ,
                pd_t.wItemRid ,
                wItemName = IIF(@pLangCd = 'en-gb', i.wEName,i.wCName),
                pd_t.wStatus ,
                pd_t.wCrtDt ,
                pd_t.wCrtBy ,
                wCrtByName = IIF(@pLangCd = 'en-gb', u_c.wName, u_c.wCName),
                pd_t.wUpdDt ,
                pd_t.wUpdBy ,
                wUpdByName = IIF(@pLangCd = 'en-gb', u_u.wName, u_u.wCName),
                i.wIsSerialItem ,
                wSerialItemCount = ISNULL(si.wCount, 0),
                p.wLotNo ,
                p.wBatchNo ,
                'N' AS RecordState,
                pd_t.wValidDate,
                pd_t.wHandleStatus,
                pd_t.wHandleRemark
        FROM dbo.ePurchaseDtl pd_t WITH(NOLOCK)
        INNER JOIN dbo.ePurchase p WITH(NOLOCK) ON p.RowID = pd_t.wPurchaseRid
        INNER JOIN dbo.mItem i WITH(NOLOCK) ON i.RowID = pd_t.wItemRid
        LEFT JOIN cteSerialItem si ON si.wItemRid = pd_t.wItemRid
        LEFT JOIN RollsMary.dbo.mUsr u_c WITH(NOLOCK) ON u_c.RowID = pd_t.wCrtBy
        LEFT JOIN RollsMary.dbo.mUsr u_u WITH(NOLOCK) ON u_u.RowID = pd_t.wUpdBy
        WHERE  pd_t.wStatus = 'A'
            AND pd_t.wPurchaseRid = @pPurchaseRid;               
    END