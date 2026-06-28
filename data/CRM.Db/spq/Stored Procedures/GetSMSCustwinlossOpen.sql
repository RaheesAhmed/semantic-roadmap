CREATE PROCEDURE [spq].[GetSMSCustwinlossOpen]
    @pAgentCodeIn VARCHAR(14),
    @pCompNo VARCHAR(10),
    @pLangCd VARCHAR(30)
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;     
			
        SET @pLangCd = LOWER(@pLangCd); 
        SET @pLangCd = ISNULL(@pLangCd,'zh-tw')

        DECLARE @sCount INT=0;
        DECLARE @sServiceCounterName NVARCHAR(40);
        SELECT  @sServiceCounterName = wCName FROM RollsMary.dbo.mCompany WHERE wCompNo = @pCompNo;

        SELECT ep.wAgentCodeIn, ms.wName 
        INTO   #sDataTemp
        FROM   CRM.dbo.eStockInventory es
               INNER JOIN CRM.dbo.ePurchase ep ON es.wPurchaseRid =ep.RowID
               INNER JOIN CRM.dbo.mWarehouse mw ON ep.wInWarehouseRid =mw.RowID
               INNER JOIN CRM.dbo.mServiceCounter ms ON ms.RowID=mw.wCounterRid
        WHERE  ep.wAgentCodeIn = @pAgentCodeIn
        GROUP BY ep.wAgentCodeIn, ms.wName
        HAVING SUM(ISNULL(es.wQty,0)) >0

       SELECT @sCount = COUNT(*) FROM #sDataTemp
       IF @sCount > 0
           BEGIN
               SELECT wReqAgentCode_Display = a.wAgentCode_Display,
                      wReqAgentName = CASE WHEN @pLangCd = 'en-gb' THEN a.wEName ELSE a.wCName END,
                      wServiceCounterName = @sServiceCounterName,
                      wContent = N'並於'+ STUFF((SELECT ','+wName FROM #sDataTemp FOR XML PATH('')),1,1,'') +N'有'
               FROM   RollsMary.dbo.mAgent a 
               WHERE  a.wAgentCodeIn = @pAgentCodeIn
           
           END;
       ELSE
           BEGIN
               SELECT wReqAgentCode_Display = a.wAgentCode_Display,
                      wReqAgentName = CASE WHEN @pLangCd = 'en-gb' THEN a.wEName ELSE a.wCName END,
                      wServiceCounterName = @sServiceCounterName,
                      wContent = N'沒有任何'
               FROM   RollsMary.dbo.mAgent a
               WHERE  a.wAgentCodeIn = @pAgentCodeIn 
           END;

    IF OBJECT_ID('tempdb..#sDataTemp') IS NOT NULL
            DROP TABLE #sDataTemp;	
    END;