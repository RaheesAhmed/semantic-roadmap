
CREATE PROCEDURE [spq].[GetRptStockSales]
    @pXMLFilter XML,
    @pLangCd VARCHAR(10) = 'zh-TW'
AS
    BEGIN
        SET NOCOUNT ON;
        
        -------------------------------dbml-------------------------------
        --DECLARE @vResult TABLE(
        --    wStockSalesRid                  BIGINT,
        --    wPurchaseRid                    BIGINT,
        --    wLotNo                          VARCHAR(50),    -- 批次號
        --    wBatchNo                        VARCHAR(50),    -- 批量號
        --    wStockSalesRefNo                VARCHAR(50),    -- 銷售單號
        --    wWarehouseName                  NVARCHAR(100),  -- 出貨仓库
        --    wDebitCounterName               NVARCHAR(50),   -- 扣數櫃台
        --    wSalesType                      NVARCHAR(50),   -- 提貨/一般銷售
        --    wIsBorrowGoods                  NCHAR(1),       -- 借貨
        --    wRemark                         NVARCHAR(4000), -- 借貨備註
        --    wRecipientAgentCodeIn_Display   NVARCHAR(50),   -- 提货户口
        --    wDebitAgentCodeIn_Display       NVARCHAR(50),   -- 扣数户口
        --    wPaymentMethod                  NVARCHAR(50),   -- 付款方式
        --    wPurchaseType                   VARCHAR(30),    -- 采购类型
        --    wPurchaseTypeName               NVARCHAR(50),   -- 采购类型
        --    wItemType                       NVARCHAR(50),   -- 產品类型
        --    wItemName                       NVARCHAR(100),  -- 产品名称
        --    wSaledQuantity                  INT,            -- 销售数量
        --    wCurrency                       VARCHAR(10),    -- 貨幣
        --    wUnitCost                       NUMERIC(18,4),  -- 单件成本
        --    wTotalCost                      NUMERIC(18,4),  -- 总成本
        --    wUnitPrice                      NUMERIC(18,4),  -- 單價
        --    wTotalAmt                       NUMERIC(18,4),  -- 總值
        --    wSaleStaff                      NVARCHAR(50),   -- 銷售同事
        --    wSaleDateTime                   DATETIME2(7),   -- 銷售時間
        --    wSaleStatus                     NVARCHAR(30),   -- 銷售狀態
        --    wCrtDt                          DATETIME2(7),   -- 建立日期
        --    wUpdDt                          DATETIME2(7),   -- 修改日期
        --    wStatus                         NVARCHAR(10)    -- 状态
        --);
        --SELECT * FROM @vResult;
        -----------------------------end dbml-----------------------------  
        
        DECLARE @pRefNo             VARCHAR(50) ,
                @pAgentCodeIn       VARCHAR(14) ,
                @pDepartmentCode    VARCHAR(30) ,
                @pSalesFromDt       DATE ,
                @pSalesToDt         DATE,
                @pPickupFromDt      DATE,
                @pPickupToDt        DATE,
                @pSalesStatus       VARCHAR(30) ,
                @pIsBorrowGoods     CHAR(1),
                @pWarehouseRid      VARCHAR(MAX),
                @pStatus            CHAR(1);

        -- 仓库
        DECLARE @vWarehouse TABLE (RowID BIGINT PRIMARY KEY);

        IF @pXMLFilter IS NOT NULL
        BEGIN
            SET @pRefNo             = @pXMLFilter.value('(Filter/@pRefNo)[1]',             'VARCHAR(50)');
            SET @pAgentCodeIn       = @pXMLFilter.value('(Filter/@pAgentCodeIn)[1]',       'VARCHAR(14)');
            SET @pDepartmentCode    = @pXMLFilter.value('(Filter/@pDepartmentCode)[1]',    'VARCHAR(30)');
            SET @pSalesStatus       = @pXMLFilter.value('(Filter/@pSalesStatus)[1]',       'VARCHAR(30)');
            SET @pIsBorrowGoods     = @pXMLFilter.value('(Filter/@pIsBorrowGoods)[1]',     'CHAR(1)');
            SET @pWarehouseRid      = @pXMLFilter.value('(Filter/@pWarehouseRid)[1]',      'VARCHAR(MAX)');
            SET @pStatus            = @pXMLFilter.value('(Filter/@pStatus)[1]',            'CHAR(1)');

            -- 日期參數如果為：""，直接轉成日期會變成：1900-01-01，此處判斷到是：""，變成：NULL，轉成日期也就為：NULL
            SET @pSalesFromDt       = CAST(NULLIF(@pXMLFilter.value('(Filter/@pSalesFromDt)[1]',  'VARCHAR(20)'), '') AS DATE);
            SET @pSalesToDt         = CAST(NULLIF(@pXMLFilter.value('(Filter/@pSalesToDt)[1]',    'VARCHAR(20)'), '') AS DATE);
            SET @pPickupFromDt      = CAST(NULLIF(@pXMLFilter.value('(Filter/@pPickupFromDt)[1]', 'VARCHAR(20)'), '') AS DATE);
            SET @pPickupToDt        = CAST(NULLIF(@pXMLFilter.value('(Filter/@pPickupToDt)[1]',   'VARCHAR(20)'), '') AS DATE);
        END;
        
        SET @pRefNo             = NULLIF(@pRefNo, '');
        SET @pAgentCodeIn       = NULLIF(@pAgentCodeIn, '');
        SET @pDepartmentCode    = NULLIF(@pDepartmentCode, '');
        SET @pSalesFromDt       = ISNULL(@pSalesFromDt, '0001-01-01');
        SET @pSalesToDt         = ISNULL(@pSalesToDt, '2099-12-31');
        SET @pSalesStatus       = NULLIF(@pSalesStatus, '');
        SET @pIsBorrowGoods     = NULLIF(@pIsBorrowGoods, '');
        SET @pWarehouseRid      = NULLIF(@pWarehouseRid, '');
        SET @pStatus            = NULLIF(@pStatus, '');
        SET @pLangCd            = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');
        
        IF @pPickupFromDt IS NOT NULL OR @pPickupToDt IS NOT NULL
        BEGIN
           SET @pPickupFromDt   = ISNULL(@pPickupFromDt, '0001-01-01');
            SET @pPickupToDt    = ISNULL(@pPickupToDt, '2099-12-31');
        END
        
        IF @pWarehouseRid IS NOT NULL
        BEGIN
            DECLARE @sXMLWarehouse XML;
            SET @sXMLWarehouse = CONVERT(XML,'<DataSet><Record>' + REPLACE(@pWarehouseRid, ',', '</Record><Record>') + '</Record></DataSet>');

            INSERT INTO @vWarehouse(RowID)
            SELECT DISTINCT T.tmp.value('.', 'BIGINT')
            FROM @sXMLWarehouse.nodes('DataSet/Record') T(tmp)
            WHERE T.tmp.value('.', 'BIGINT') > 0;
        END;

        ------------------------------------------------------------------------------------------
        CREATE TABLE #vPurchaseStatus(wCode NVARCHAR(50) PRIMARY KEY, wTitle NVARCHAR(150));
        CREATE TABLE #vPurchaseType(wCode NVARCHAR(50) PRIMARY KEY, wTitle NVARCHAR(150));
        CREATE TABLE #vPaymentMethod(wCode NVARCHAR(50) PRIMARY KEY, wTitle NVARCHAR(150));
        CREATE TABLE #vSaleStatus(wCode NVARCHAR(50) PRIMARY KEY, wTitle NVARCHAR(150));
        CREATE TABLE #vSaleType(wCode NVARCHAR(50) PRIMARY KEY, wTitle NVARCHAR(150));
        CREATE TABLE #vCommonStatus(wCode NVARCHAR(50) PRIMARY KEY, wTitle NVARCHAR(150));

        INSERT INTO #vPurchaseStatus(wCode, wTitle)
        SELECT wCode, wTitle
        FROM dbo.mLookUp
        WHERE wType ='INVENTORY_PURCHASE' AND wLangCd =@pLangCd;

        INSERT INTO #vPurchaseType(wCode, wTitle)
        SELECT wCode, wTitle
        FROM dbo.mLookUp
        WHERE wType ='PURCHASE_TYPE' AND wLangCd =@pLangCd;

        INSERT INTO #vPaymentMethod(wCode, wTitle)
        SELECT wCode, wTitle
        FROM dbo.mLookUp
        Where wType ='PAYMENT_TYPE_INVENTORY' AND wLangCd =@pLangCd;

        INSERT INTO #vSaleStatus(wCode, wTitle)
        SELECT wCode, wTitle
        FROM dbo.mLookUp
        Where wType ='INVENTORY_SALES' AND wLangCd =@pLangCd;

        INSERT INTO #vSaleType(wCode, wTitle)
        SELECT wCode, wTitle
        FROM dbo.mLookUp
        Where wType ='INVENTORY_SALESTYPE' AND wLangCd =@pLangCd;

        INSERT INTO #vCommonStatus(wCode, wTitle)
        SELECT wCode, wTitle
        FROM dbo.mLookUp
        Where wType ='COMMON_STATUS' AND wLangCd =@pLangCd;
        
        SELECT  wStockSalesRid = ss.RowID,
                wPurchaseRid = p.RowID,
                wLotNo = SUBSTRING(p.wLotNo, CHARINDEX('-', p.wLotNo)+1, LEN(p.wLotNo)),  -- 批次號
                wBatchNo = p.wBatchNo,          -- 批量號
                wStockSalesRefNo = ss.wRefNo,   -- 銷售單號
                wWarehouseName = IIF(@pLangCd = 'en-gb', mw.wEName, mw.wCName),  -- 出貨仓库
                wDebitCounterName = sc.wName,   -- 扣數櫃台
                wSalesType = st.wTitle,         -- 提貨/一般銷售
                wIsBorrowGoods = IIF(ss.wIsBorrowGoods = 'Y', N'是', N'否'),-- 借貨
                wRemark = ss.wRemark,           -- 借貨備註
                wRecipientAgentCodeIn_Display = rAgent.wAgentCode_Display,  -- 提货户口
                wDebitAgentCodeIn_Display = dAgent.wAgentCode_Display,      -- 扣数户口
                wPaymentMethod = pay.wTitle,    -- 付款方式
                wPurchaseType  = pt.wCode,      -- 采购类型
                wPurchaseTypeName = pt.wTitle,  -- 采购类型
                wItemType = IIF(@pLangCd = 'en-GB', mic.wEName, mic.wCName), -- 產品類別
                wItemName = IIF(@pLangCd = 'en-GB', mi.wEName, mi.wCName),   -- 產品名稱
                wCurrency      = ss.wCurrCode,       -- 貨幣
                wSaledQuantity = ssi.wQty,           -- 销售数量
                wUnitCost      = ssi.wUnitCostHKD,   -- 单件成本
                wTotalCost     = IIF(ssi.RowID IS NULL, 0 , ssi.wQty * ssi.wUnitCostHKD), -- 总成本
                wUnitPrice     = ssd.wUnitPriceHKD,  -- 單價
                wTotalAmt      = IIF(ssd.RowID IS NULL OR ssi.RowID IS NULL, 0, ssi.wQty * ssd.wUnitPriceHKD), -- 總值
                wSaleStaff     = IIF(@pLangCd = 'en-gb', us.wName, us.wCName),  -- 銷售同事
                wSaleDateTime  = ss.wSalesDt,        -- 銷售時間
                wSaleStatus    = s_s.wTitle,         -- 銷售狀態
                wCrtDt         = ssi.wCrtDt,         -- 建立日期
                wUpdDt         = ssi.wUpdDt,         -- 修改日期
                wStatus        = c_s.wTitle          -- 状态
        FROM dbo.eStockSales ss
        INNER JOIN dbo.eStockSalesDtl ssd ON ssd.wStockSalesRid = ss.RowID AND ssd.wStatus = 'A'
        INNER JOIN dbo.eStockSalesItem ssi ON ssi.wStockSalesDtlRid = ssd.RowID AND ssi.wStatus = 'A'
        INNER JOIN dbo.ePurchase p ON p.RowID = ssi.wPurchaseRid
        INNER JOIN dbo.mWarehouse mw ON mw.RowID = ss.wOutWarehouseRid
        INNER JOIN dbo.mItem mi ON mi.RowID = ssd.wItemRid
        LEFT JOIN dbo.mItemCategory mic ON mic.RowID = mi.wCategoryRid
        LEFT JOIN @vWarehouse vw ON vw.RowID = ss.wOutWarehouseRid
        LEFT JOIN dbo.mServiceCounter sc ON sc.RowID = ss.wDebitCounterRid
        LEFT JOIN RollsMary.dbo.mAgent dAgent ON dAgent.wAgentCodeIn = ss.wDebitAgentCodeIn
        LEFT JOIN RollsMary.dbo.mAgent rAgent ON rAgent.wAgentCodeIn = ss.wRecipientAgentCodeIn
        LEFT JOIN RollsMary.dbo.mUsr us ON us.RowID = ss.wSalesmanRid
        LEFT JOIN #vSaleType st ON st.wCode = ss.wSalesType
        LEFT JOIN #vPaymentMethod pay ON pay.wCode = ss.wPaymentMethod
        LEFT JOIN #vPurchaseType pt ON pt.wCode = p.wType
        LEFT JOIN #vSaleStatus s_s ON s_s.wCode = ss.wSalesStatus
        LEFT JOIN #vCommonStatus c_s ON c_s.wCode = ss.wStatus
        WHERE (@pRefNo IS NULL OR @pRefNo = ss.wRefNo)
            AND (@pAgentCodeIn IS NULL OR @pAgentCodeIn = p.wAgentCodeIn)
            AND (@pDepartmentCode IS NULL OR @pDepartmentCode = mw.wDepartmentCode)
            AND (@pSalesStatus IS NULL OR @pSalesStatus = ss.wSalesStatus)
            AND (@pIsBorrowGoods IS NULL OR @pIsBorrowGoods = ss.wIsBorrowGoods)
            AND (@pStatus IS NULL OR @pStatus = ss.wStatus)
            AND (@pWarehouseRid IS NULL OR vw.RowID IS NOT NULL)
            --AND (ss.wSalesDt BETWEEN @pSalesFromDt AND @pSalesToDt)
            --AND ((@pPickupFromDt IS NULL AND @pPickupToDt IS NULL) OR (ss.wPickupDt BETWEEN @pPickupFromDt AND @pPickupToDt))
        OPTION(RECOMPILE);

        IF OBJECT_ID('tempdb..#vPurchaseStatus') IS NOT NULL
            DROP TABLE #vPurchaseStatus;

        IF OBJECT_ID('tempdb..#vPurchaseType') IS NOT NULL
            DROP TABLE #vPurchaseType;

        IF OBJECT_ID('tempdb..#vPaymentMethod') IS NOT NULL
            DROP TABLE #vPaymentMethod;

        IF OBJECT_ID('tempdb..#vSaleStatus') IS NOT NULL
            DROP TABLE #vSaleStatus;

        IF OBJECT_ID('tempdb..#vSaleType') IS NOT NULL
            DROP TABLE #vSaleType;

        IF OBJECT_ID('tempdb..#vCommonStatus') IS NOT NULL
            DROP TABLE #vCommonStatus;

        IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
            DROP TABLE #vResult;
    END;