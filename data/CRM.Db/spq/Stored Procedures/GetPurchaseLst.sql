CREATE PROCEDURE [spq].[GetPurchaseLst]
    @pLotNo VARCHAR(50) ,
    @pVendorRid BIGINT ,
    @pAgentCodeIn VARCHAR(14) ,
    @pGuestCodeIn VARCHAR(14),
    @pCategoryRid BIGINT,
    @pFromDt DATETIME2 ,
    @pToDt DATETIME2 ,
    @pFromExpiryDt DATETIME2,
    @pToExpiryDt DATETIME2,   
    @pType VARCHAR(30),
    @pIsExpired VARCHAR(5),
    @pPurchaseStatus VARCHAR(30) ,
    @pDepartmentCode VARCHAR(30) ,
    @pSaleStatus VARCHAR(30),
    @pXMLWarehouseRid XML ,
    @pStatus CHAR(1) ,
    @pLangCd VARCHAR(10) ,
    @pPageNum INT = 1 ,
    @pPageSize INT = 999
AS
    BEGIN
        SET NOCOUNT ON;	  	
                
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        

        SET @pLotNo          = NULLIF(@pLotNo, '');
        SET @pAgentCodeIn    = NULLIF(@pAgentCodeIn, '');
        SET @pGuestCodeIn    = NULLIF(@pGuestCodeIn,'')
        SET @pPurchaseStatus = NULLIF(@pPurchaseStatus, '');
        SET @pDepartmentCode = NULLIF(@pDepartmentCode, '');
        SET @pType           = NULLIF(@pType, '');
        SET @pIsExpired      = IIF(@pIsExpired <> 'Y', NULL, 'Y');
        SET @pSaleStatus     = NULLIF(@pSaleStatus, '');
        SET @pStatus         = NULLIF(@pStatus, '');
        SET @pCategoryRid    = IIF(@pCategoryRid <= 0, NULL, @pCategoryRid);
        SET @pVendorRid      = IIF(@pVendorRid <= 0, NULL, @pVendorRid);
        SET @pFromDt         = ISNULL(@pFromDt, '0001-01-01');
        SET @pToDt           = ISNULL(@pToDt, '2099-12-31');    
        SET @pLangCd         = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');
        SET @pXMLWarehouseRid = IIF(CAST(@pXMLWarehouseRid AS NVARCHAR(MAX)) = N'<DataSet/>', NULL, @pXMLWarehouseRid);

        IF @pFromExpiryDt IS NOT NULL OR @pToExpiryDt IS NOT NULL  
        BEGIN
          SET @pFromExpiryDt = ISNULL(@pFromExpiryDt, '0001-01-01');
          SET @pToExpiryDt = ISNULL(@pToExpiryDt, '2099-12-31');  
        END

        -- 仓库
        DECLARE @vWarehouse TABLE (RowID BIGINT PRIMARY KEY);
    
        IF @pXMLWarehouseRid IS NOT NULL
        BEGIN
            INSERT INTO @vWarehouse ( RowID )
            SELECT DISTINCT T.tmp.value('@SelectionItem', 'BIGINT')
            FROM @pXMLWarehouseRid.nodes('/DataSet/Record') T ( tmp )
            WHERE T.tmp.value('@SelectionItem', 'BIGINT') > 0;
        END;

        WITH tPurchaseItem AS (
            SELECT pd.wPurchaseRid 
            FROM dbo.ePurchaseDtl pd
            INNER JOIN dbo.mItem item ON pd.wItemRid=item.RowID
            WHERE item.wCategoryRid = @pCategoryRid
            GROUP BY pd.wPurchaseRid
        ),
        tStockInventory AS (
            SELECT 
                wPurchaseRid,
                wStockQuantity = SUM(wQty)
            FROM dbo.eStockInventory
            WHERE @pSaleStatus IS NOT NULL
            GROUP BY wPurchaseRid
        ),
        tResult AS (
            SELECT 
                p.RowID ,
                p.wLotNo ,
                p.wBatchNo ,
                p.wVendorRid ,
                p.wInWarehouseRid ,
                p.wAgentCodeIn ,
                a.wAgentCode_Display ,
                p.wCurrCode ,
                p.wCurrRate ,
                p.wCost ,
                p.wType ,
                p.wRemarks ,
                p.wPurchaseStatus ,
                p.wPayExpiryDt ,
                p.wSettleBy ,
                p.wSettleDt ,
                p.wStatus ,
                p.wCrtDt ,
                p.wCrtBy ,
                p.wUpdDt ,
                p.wUpdBy ,
                p.wGuestCodeIn,
                p.wMaturityDate,
                p.wReceiptDate,
                wRelateAgentCode_Display = guest.wAgentCode_Display,
                p.wNotifier,
                p.wStoreLocation,
                wStoreWarehouse = CAST('' AS NVARCHAR(4000)),
                wPurchaseCounter = CAST(p.wPurchaseCounterRid AS NVARCHAR(100)),
                wAgentName = IIF(@pLangCd = 'en-gb', a.wEName, a.wCName),
                wSettleByName = IIF(@pLangCd = 'en-gb', u.wName, u.wCName),
                wCrtByName = IIF(@pLangCd = 'en-gb', u_c.wName, u_c.wCName),
                wUpdByName = IIF(@pLangCd = 'en-gb', u_u.wName, u_u.wCName),
                RecordState = 'N'
            FROM dbo.ePurchase p
            INNER JOIN dbo.mWarehouse mw ON mw.RowID = p.wInWarehouseRid
            LEFT JOIN tPurchaseItem pdi ON pdi.wPurchaseRid = p.RowID
            LEFT JOIN tStockInventory si ON si.wPurchaseRid = p.RowID
            LEFT JOIN RollsMary.dbo.mAgent a ON a.wAgentCodeIn = p.wAgentCodeIn
            LEFT JOIN RollsMary.dbo.mAgent guest ON guest.wAgentCodeIn =p.wGuestCodeIn
            LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = p.wSettleBy
            LEFT JOIN RollsMary.dbo.mUsr u_c ON u_c.RowID = p.wCrtBy
            LEFT JOIN RollsMary.dbo.mUsr u_u ON u_u.RowID = p.wUpdBy
            LEFT JOIN @vWarehouse vm ON vm.RowID = p.wInWarehouseRid
            WHERE ( @pLotNo IS NULL OR @pLotNo = SUBSTRING(p.wLotNo, CHARINDEX('-', p.wLotNo)+1, LEN(p.wLotNo)))
                AND ( @pVendorRid IS NULL OR @pVendorRid = p.wVendorRid )
                AND ( @pAgentCodeIn IS NULL OR @pAgentCodeIn = p.wAgentCodeIn )
                AND ( @pGuestCodeIn IS NULL OR @pGuestCodeIn = p.wGuestCodeIn )
                AND ( @pPurchaseStatus IS NULL OR @pPurchaseStatus = p.wPurchaseStatus )
                AND ( @pType IS NULL OR @pType =p.wType )
                AND ( @pStatus IS NULL OR @pStatus = p.wStatus )
                AND ( @pCategoryRid IS NULL OR pdi.wPurchaseRid IS NOT NULL)
                AND ( @pDepartmentCode IS NULL OR @pDepartmentCode = mw.wDepartmentCode )
                AND ( @pXMLWarehouseRid IS NULL OR vm.RowID IS NOT NULL )
                AND ( @pIsExpired IS NULL OR (p.wMaturityDate IS NOT NULL AND CONVERT(DATE, p.wMaturityDate) <> '0001-01-01' AND p.wMaturityDate < CONVERT(DATE, dbo.fnUTC8Now())))
                AND ((@pFromExpiryDt IS NULL AND @pToExpiryDt IS NULL) OR p.wMaturityDate BETWEEN @pFromExpiryDt AND @pToExpiryDt)
                AND ( p.wCrtDt BETWEEN @pFromDt AND @pToDt )
                AND ( @pSaleStatus IS NULL  -- 所有記錄
                  OR (@pSaleStatus = 'OPEN' AND (p.wPurchaseStatus = 'OPEN' OR si.wStockQuantity > 0))  -- 處理中（採購未完成、採購貨品未賣完）
                  OR (@pSaleStatus = 'COMPLETE' AND p.wPurchaseStatus = 'COMPLETE' AND si.wStockQuantity = 0)  -- 完成（採購完成且且貨品全部賣出）
                )
        ),
        tCount AS ( 
            SELECT wRecordCount = COUNT(1) FROM tResult
        )

        SELECT  r.* ,
                wRecordCount
        INTO #tResult
        FROM    tResult r,
                tCount c
        ORDER BY r.wCrtDt DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );

        --WITH tStockAdjustmentSum AS (
        --    SELECT
        --        sai.wPurchaseRid, 
        --        sad.wItemRid, 
        --        sa.wWarehouseRid,
        --        wQty = SUM(sai.wQty)
        --    FROM dbo.eStockAdjustment sa
        --    INNER JOIN dbo.eStockAdjustmentDtl sad ON sad.wStockAdjustmentRid = sa.RowID AND sad.wStatus = 'A'
        --    INNER JOIN dbo.eStockAdjustmentItem sai ON sai.wStockAdjustmentDtlRid = sad.RowID AND sai.wStatus = 'A'
        --    GROUP BY sai.wPurchaseRid, sad.wItemRid, sa.wWarehouseRid
        --),
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
        )

        UPDATE r 
        SET wStoreWarehouse = STUFF(
            (SELECT DISTINCT CONCAT( ',', CHAR(10), IIF(@pLangCd = 'en-gb', mw.wEName, mw.wCName)) 
            FROM dbo.eStockInventory si
            INNER JOIN dbo.mWarehouse mw ON mw.RowID = si.wWarehouseRid
            --LEFT JOIN tStockAdjustmentSum sa ON sa.wPurchaseRid = si.wPurchaseRid AND sa.wItemRid = si.wItemRid AND sa.wWarehouseRid = si.wWarehouseRid
            LEFT JOIN tStockSaleSum ss ON ss.wPurchaseRid = si.wPurchaseRid AND ss.wItemRid = si.wItemRid AND ss.wWarehouseRid = si.wWarehouseRid
            WHERE si.wPurchaseRid = r.RowID AND si.wStatus = 'A' AND (si.wQty + ISNULL(ss.wQty, 0)) > 0
            FOR XML PATH('')), 1, 2, N'')
        FROM #tResult r;

        SELECT * FROM #tResult;

        IF OBJECT_ID('tempdb..#tResult') IS NOT NULL
            DROP TABLE #tResult;
    END;