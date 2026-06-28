CREATE PROCEDURE [spq].[GetSMSPurchase_Reminder]
    @pRowID BIGINT ,
    @pSendType INT ,            --跟進@pSendType選擇不同的發送模板，0是完成採購時的模板，1是60日到期SMS的模板
    @pGuid VARCHAR(50),
    @pLangCd VARCHAR(30)
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
        WITH tStockSaleSum AS (
            SELECT
                ssi.wPurchaseRid, 
                ssd.wItemRid, 
                wWarehouseRid = ss.wOutWarehouseRid,
                wQty = SUM(ssi.wQty)
            FROM dbo.eStockSales ss
            INNER JOIN dbo.eStockSalesDtl ssd ON ssd.wStockSalesRid = ss.RowID AND ssd.wStatus = 'A'
            INNER JOIN dbo.eStockSalesItem ssi ON ssi.wStockSalesDtlRid = ssd.RowID AND ssi.wStatus = 'A'
            GROUP BY ssi.wPurchaseRid, ssd.wItemRid, ss.wOutWarehouseRid
        ),tmp AS(
            SELECT p.RowID,wStoreWarehouse = STUFF(
                   (SELECT DISTINCT CONCAT( ',', wTitle) 
                   FROM dbo.eStockInventory si
                   INNER JOIN dbo.mWarehouse mw ON mw.RowID = si.wWarehouseRid
                   INNER JOIN dbo.mServiceCounter sc ON sc.RowID = mw.wCounterRid
                   INNER JOIN Rollsmary.dbo.mLookUpLang ml ON  ml.wCode = sc.wRollexCompNo AND wLang = (CASE WHEN @pLangCd = N'ko-KO' THEN N'ko-KR' ELSE @pLangCd END) AND wType = 'TT_COMPANY'
                   LEFT JOIN tStockSaleSum ss ON ss.wPurchaseRid = si.wPurchaseRid AND ss.wItemRid = si.wItemRid AND ss.wWarehouseRid = si.wWarehouseRid
                   WHERE  si.wPurchaseRid = p.RowID AND si.wStatus = 'A' AND (si.wQty + ISNULL(ss.wQty, 0)) > 0
                   FOR XML PATH('')), 1, 1, N''),
                   wStoreWarehouse_TW = STUFF(
                   (SELECT DISTINCT CONCAT( ',', wTitle) 
                   FROM dbo.eStockInventory si
                   INNER JOIN dbo.mWarehouse mw ON mw.RowID = si.wWarehouseRid
                   INNER JOIN dbo.mServiceCounter sc ON sc.RowID = mw.wCounterRid
                   INNER JOIN Rollsmary.dbo.mLookUpLang ml ON  ml.wCode = sc.wRollexCompNo AND wLang = 'zh-TW' AND wType = 'TT_COMPANY'
                   LEFT JOIN tStockSaleSum ss ON ss.wPurchaseRid = si.wPurchaseRid AND ss.wItemRid = si.wItemRid AND ss.wWarehouseRid = si.wWarehouseRid
                   WHERE  si.wPurchaseRid = p.RowID AND si.wStatus = 'A' AND (si.wQty + ISNULL(ss.wQty, 0)) > 0
                   FOR XML PATH('')), 1, 1, N''),
                   wStoreWarehouse_Tel = STUFF(
                   (SELECT DISTINCT CONCAT( ',', ISNULL(scc.wTel,'')) 
                   FROM dbo.eStockInventory si
                   INNER JOIN dbo.mWarehouse mw ON mw.RowID = si.wWarehouseRid
                   INNER JOIN dbo.mServiceCounter sc ON sc.RowID = mw.wCounterRid
                   LEFT JOIN CRM.dbo.mServiceCounterContact scc ON scc.wSeriverCounterRid = sc.RowID AND scc.wContactType = 'CSSMS' AND scc.wDepartmentCode='MEMBER'
                   LEFT JOIN tStockSaleSum ss ON ss.wPurchaseRid = si.wPurchaseRid AND ss.wItemRid = si.wItemRid AND ss.wWarehouseRid = si.wWarehouseRid
                   WHERE  si.wPurchaseRid = p.RowID AND si.wStatus = 'A' AND (si.wQty + ISNULL(ss.wQty, 0)) > 0
                   FOR XML PATH('')), 1, 1, N'')
            FROM dbo.ePurchase p
        )

        SELECT  
                p.RowID ,
                p.wAgentCodeIn ,
                wAgentCode = CASE WHEN @pLangCd = 'zh-TW' THEN a.wAgentCode 
                                  WHEN @pLangCd = 'en-US' THEN REPLACE(a.wAgentCode,N'組',N'group')
                                  WHEN @pLangCd = 'ko-KO' THEN REPLACE(a.wAgentCode,N'組',N'조')
                                  ELSE REPLACE(a.wAgentCode,N'組',N'组') END ,
                wYear = YEAR(p.wMaturityDate) ,
                wMonth = CASE WHEN @pLangCd != 'en-US'THEN CAST(MONTH(p.wMaturityDate) AS VARCHAR)
                         ELSE CASE MONTH(p.wMaturityDate) WHEN 1 THEN 'Jan'
                              WHEN 2 THEN 'Feb'
                              WHEN 3 THEN 'Mar'
                              WHEN 4 THEN 'Apr'
                              WHEN 5 THEN 'May'
                              WHEN 6 THEN 'Jun'
                              WHEN 7 THEN 'Jul'
                              WHEN 8 THEN 'Aug'
                              WHEN 9 THEN 'Sep'
                              WHEN 10 THEN 'Oct'
                              WHEN 11 THEN 'Nov'
                              WHEN 12 THEN 'Dec'
                              ELSE '' END
                          END,
                wDay = DAY(p.wMaturityDate),
                --sc.wName AS wServiceCounterName ,
                wServiceCounterName = tmp.wStoreWarehouse ,
                ISNULL(scc.wTel,'') AS wServiceCounterTel ,
                p.wNotifier,
                p.wTelephone,
                wStoreWarehouse_TW,
                @pSendType AS wSendType,
                CASE WHEN SUBSTRING(tmp.wStoreWarehouse_Tel,1,1) =',' THEN RIGHT(tmp.wStoreWarehouse_Tel,LEN(wStoreWarehouse_Tel)-1) 
                     ELSE wStoreWarehouse_Tel END AS wStoreWarehouse_Tel
        FROM    CRM.dbo.ePurchase p
                INNER JOIN RollsMary.dbo.mAgent a ON a.wAgentCodeIn=p.wAgentCodeIn
                LEFT JOIN tmp ON tmp.RowID = p.RowID
                LEFT JOIN CRM.dbo.mServiceCounter sc ON sc.RowID = p.wServiceCounterRid 
                LEFT JOIN CRM.dbo.mServiceCounterContact scc ON scc.wSeriverCounterRid = sc.RowID AND scc.wContactType = 'CSSMS' AND wDepartmentCode='MEMBER'
        WHERE   p.RowID = @pRowID AND p.wPurchaseStatus='COMPLETE';

    END;