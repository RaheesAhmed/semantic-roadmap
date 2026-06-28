CREATE PROC [spq].[GetRptPurchase]
    @pXMLFilter XML,
    @pLangCd VARCHAR(10) = 'zh-TW'
AS
    BEGIN
        SET NOCOUNT ON;

        -------------------------------dbml-------------------------------
        --DECLARE @vResult TABLE (
        --    wPurchaseRid              BIGINT,
        --    wPurchaseDtlRid           BIGINT,
        --    wLotNo                    VARCHAR(50),   -- 批次号
        --    wBatchNo                  VARCHAR(50),   -- 批量号
        --    wIsCustomerOrder          CHAR(1),       -- 客人订货
        --    wOrderAgentCodeIn_Display NVARCHAR(50),  -- 订货户口
        --    wGustAgentCodeIn_Display  NVARCHAR(50),  -- 送客户口
        --    wVendorName               NVARCHAR(50),  -- 供应商
        --    wPurchaseType             VARCHAR(50),   -- 采购类型
        --    wPurchaseTypeName         NVARCHAR(50),  -- 采购类型
        --    wItemType                 NVARCHAR(50),  -- 货品类型
        --    wItemName                 NVARCHAR(100), -- 产品名称
        --    wValidDate                DATETIME2(7),  -- 有效期
        --    wQuantity                 INT,           -- 数量
        --    wCurrency                 VARCHAR(10),   -- 貨幣
        --    wUnitCost                 NUMERIC(18,4), -- 单件成本
        --    wTotalCost                NUMERIC(18,4), -- 总成本
        --    wPurchaseStatus           NVARCHAR(10),  -- 采购状态
        --    wReceiptDate              DATETIME2(7),  -- 收货日期
        --    wPurchaseCounter          NVARCHAR(100), -- 落單服務櫃台
        --    wWarehouseName            NVARCHAR(100), -- 入貨仓库
        --    wStoreWarehouse           NVARCHAR(4000),-- 現存倉庫
        --    wStoreLocation            NVARCHAR(300), -- 存放位置
        --    wMaturityDate             DATETIME2(7),  -- 到期日
        --    wStockStatus              NVARCHAR(10),  -- 存货状态
        --    wNoticeRecord             NVARCHAR(500), -- 通知记录
        --    wPurchaseRemark           NVARCHAR(500), -- 备注
        --    wPurchaseDtlRemark        NVARCHAR(500), -- 处理备注
        --    wItemStatus               NVARCHAR(10),  -- 货品状态
        --    wBalanceQuantity          INT,           -- 未到货数量
        --    wStockQuantity            INT,           -- 到货数量
        --    wAjustQuantity            INT,           -- 调整数量
        --    wSaledQuantity            INT,           -- 销售数量
        --    wCrtDt                    DATETIME2(7),  -- 建立日期
        --    wUpdDt                    DATETIME2(7),  -- 修改日期
        --    wStatus                   NVARCHAR(10)   -- 状态
        --);
        --SELECT * FROM @vResult;
        -----------------------------end dbml-----------------------------

        DECLARE @pLotNo          VARCHAR(50),
                @pVendorRid      BIGINT,
                @pCategoryRid    BIGINT,
                @pAgentCodeIn    VARCHAR(14),
                @pGuestCodeIn    VARCHAR(14),
                @pFromDt         DATE,
                @pToDt           DATE,
                @pFromExpiryDt   DATE,
                @pToExpiryDt     DATE,
                @pType           VARCHAR(30),
                @pIsExpired      VARCHAR(5),
                @pPurchaseStatus VARCHAR(30),
                @pDepartmentCode VARCHAR(30),
                @pWarehouseRid   VARCHAR(MAX),
                @pSaleStatus     VARCHAR(30),
                @pStatus         CHAR(1);

        -- 仓库
        DECLARE @vWarehouse TABLE (RowID BIGINT PRIMARY KEY);

        IF @pXMLFilter IS NOT NULL
        BEGIN
            SET @pLotNo          = @pXMLFilter.value('(Filter/@pLotNo)[1]',         'VARCHAR(50)');
            SET @pVendorRid      = @pXMLFilter.value('(Filter/@pVendorRid)[1]',     'BIGINT');
            SET @pCategoryRid    = @pXMLFilter.value('(Filter/@pCategoryRid)[1]',   'BIGINT');
            SET @pAgentCodeIn    = @pXMLFilter.value('(Filter/@pAgentCodeIn)[1]',   'VARCHAR(14)');
            SET @pGuestCodeIn    = @pXMLFilter.value('(Filter/@pGuestCodeIn)[1]',   'VARCHAR(14)');
            SET @pFromDt         = @pXMLFilter.value('(Filter/@pFromDt)[1]',        'DATE');
            SET @pToDt           = @pXMLFilter.value('(Filter/@pToDt)[1]',          'DATE');
            SET @pFromExpiryDt   = @pXMLFilter.value('(Filter/@pFromExpiryDt)[1]',  'DATE');
            SET @pToExpiryDt     = @pXMLFilter.value('(Filter/@pToExpiryDt)[1]',    'DATE');
            SET @pType           = @pXMLFilter.value('(Filter/@pType)[1]',          'VARCHAR(30)');
            SET @pIsExpired      = @pXMLFilter.value('(Filter/@pIsExpired)[1]',     'VARCHAR(5)');
            SET @pPurchaseStatus = @pXMLFilter.value('(Filter/@pPurchaseStatus)[1]','VARCHAR(30)');
            SET @pDepartmentCode = @pXMLFilter.value('(Filter/@pDepartmentCode)[1]','VARCHAR(30)');
            SET @pWarehouseRid   = @pXMLFilter.value('(Filter/@pWarehouseRid)[1]',  'VARCHAR(MAX)');
            SET @pSaleStatus     = @pXMLFilter.value('(Filter/@pSaleStatus)[1]',    'VARCHAR(30)');
            SET @pStatus         = @pXMLFilter.value('(Filter/@pStatus)[1]',        'CHAR(1)');
        END;

        SET @pLotNo          = NULLIF(@pLotNo, '');
        SET @pVendorRid      = ISNULL(@pVendorRid, 0);
        SET @pCategoryRid    = ISNULL(@pCategoryRid, 0);
        SET @pAgentCodeIn    = NULLIF(@pAgentCodeIn, '');
        SET @pGuestCodeIn    = NULLIF(@pGuestCodeIn, '');
        SET @pFromDt         = ISNULL(@pFromDt, '0001-01-01');
        SET @pToDt           = ISNULL(@pToDt, '2099-12-31');
        SET @pType           = NULLIF(@pType, '');
        SET @pIsExpired      = IIF(@pIsExpired <> 'Y', NULL, 'Y');
        SET @pPurchaseStatus = NULLIF(@pPurchaseStatus, '');
        SET @pDepartmentCode = NULLIF(@pDepartmentCode, '');
        SET @pWarehouseRid   = NULLIF(@pWarehouseRid, '');
        SET @pSaleStatus     = NULLIF(@pSaleStatus, '');
        SET @pStatus         = NULLIF(@pStatus, '');

        IF @pFromExpiryDt IS NOT NULL OR @pToExpiryDt IS NOT NULL
        BEGIN
            SET @pFromExpiryDt   = ISNULL(@pFromExpiryDt, '0001-01-01');
            SET @pToExpiryDt     = ISNULL(@pToExpiryDt,'2099-12-31');
        END;

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
        CREATE TABLE #vResult (
            wPurchaseRid              BIGINT,
            wPurchaseDtlRid           BIGINT,
            wLotNo                    VARCHAR(50),   -- 批次号
            wBatchNo                  VARCHAR(50),   -- 批量号
            wIsCustomerOrder          CHAR(1),       -- 客人订货
            wOrderAgentCodeIn_Display NVARCHAR(50),  -- 订货户口
            wGustAgentCodeIn_Display  NVARCHAR(50),  -- 送客户口
            wVendorName               NVARCHAR(50),  -- 供应商
            wPurchaseType             VARCHAR(50),   -- 采购类型
            wPurchaseTypeName         NVARCHAR(50),  -- 采购类型
            wItemRid                  BIGINT,
            wItemType                 NVARCHAR(50),  -- 货品类型
            wItemName                 NVARCHAR(100), -- 产品名称
            wValidDate                DATETIME2(7),  -- 有效期
            wQuantity                 INT,           -- 数量
            wCurrency                 VARCHAR(10),   -- 貨幣
            wUnitCost                 NUMERIC(18,4), -- 单件成本
            wTotalCost                NUMERIC(18,4), -- 总成本
            wPurchaseStatus           NVARCHAR(10),  -- 采购状态
            wReceiptDate              DATETIME2(7),  -- 收货日期
            wPurchaseCounter          NVARCHAR(100), -- 落單服務櫃台
            wWarehouseName            NVARCHAR(100), -- 入貨仓库
            wStoreWarehouse           NVARCHAR(4000),-- 現存倉庫
            wStoreLocation            NVARCHAR(300), -- 存放位置
            wMaturityDate             DATETIME2(7),  -- 到期日
            wStockStatus              NVARCHAR(10),  -- 存货状态
            wNoticeRecord             NVARCHAR(500), -- 通知记录
            wPurchaseRemark           NVARCHAR(500), -- 备注
            wPurchaseDtlRemark        NVARCHAR(500), -- 处理备注
            wItemStatus               NVARCHAR(10),  -- 货品状态
            wBalanceQuantity          INT,           -- 未到货数量
            wStockQuantity            INT,           -- 到货数量
            wAjustQuantity            INT,           -- 调整数量
            wSaledQuantity            INT,           -- 销售数量
            wCrtDt                    DATETIME2(7),  -- 建立日期
            wUpdDt                    DATETIME2(7),  -- 修改日期
            wStatus                   NVARCHAR(10)   -- 状态
        );

        CREATE TABLE #vPurchase(RowID BIGINT, wLotNo VARCHAR(50), PRIMARY KEY(RowID, wLotNo));
        CREATE TABLE #vPurchaseStatus(wCode NVARCHAR(50) PRIMARY KEY, wTitle NVARCHAR(150));
        CREATE TABLE #vPurchaseType(wCode NVARCHAR(50) PRIMARY KEY, wTitle NVARCHAR(150));
        CREATE TABLE #vCommonStatus(wCode NVARCHAR(50) PRIMARY KEY, wTitle NVARCHAR(150));

        INSERT INTO #vPurchaseStatus(wCode, wTitle)
        SELECT wCode, wTitle
        FROM dbo.mLookUp
        WHERE wType ='INVENTORY_PURCHASE' AND wLangCd =@pLangCd;

        INSERT INTO #vPurchaseType(wCode, wTitle)
        SELECT wCode, wTitle
        FROM dbo.mLookUp
        WHERE wType ='PURCHASE_TYPE' AND wLangCd =@pLangCd;

        INSERT INTO #vCommonStatus(wCode, wTitle)
        SELECT wCode, wTitle
        FROM dbo.mLookUp
        WHERE wType ='COMMON_STATUS' AND wLangCd =@pLangCd;

        WITH tPurchase AS (
            SELECT
                p.*,
                LotNo = SUBSTRING(p.wLotNo, CHARINDEX('-', p.wLotNo)+1, LEN(p.wLotNo))
            FROM dbo.ePurchase p
        ),
        tStockInventory AS (
            SELECT 
                wPurchaseRid,
                wStockQuantity = SUM(wQty)
            FROM dbo.eStockInventory
            GROUP BY wPurchaseRid
        )

        INSERT INTO #vPurchase(RowID, wLotNo)
        SELECT DISTINCT p.RowID, wLotNo = p.LotNo
        FROM tPurchase p
        LEFT JOIN dbo.ePurchaseDtl pd ON pd.wPurchaseRid = p.RowID AND pd.wStatus = 'A'
        LEFT JOIN dbo.mWarehouse mw ON mw.RowID = p.wInWarehouseRid
        LEFT JOIN RollsMary.dbo.mAgent mo ON mo.wAgentCodeIn = p.wAgentCodeIn
        LEFT JOIN RollsMary.dbo.mAgent mg ON mg.wAgentCodeIn = p.wGuestCodeIn
        LEFT JOIN dbo.mItem mi ON mi.RowID = pd.wItemRid
        LEFT JOIN @vWarehouse vw ON vw.RowID = mw.RowID
        LEFT JOIN tStockInventory si ON si.wPurchaseRid = p.RowID
        WHERE (@pLotNo IS NULL OR @pLotNo = p.LotNo)
            AND (@pVendorRid = 0 OR @pVendorRid = p.wVendorRid)
            AND (@pAgentCodeIn IS NULL OR @pAgentCodeIn = p.wAgentCodeIn)
            AND (@pGuestCodeIn IS NULL OR @pGuestCodeIn = p.wGuestCodeIn)
            AND (@pPurchaseStatus IS NULL OR @pPurchaseStatus = p.wPurchaseStatus)
            AND (@pType IS NULL OR @pType = p.wType)
            AND (@pStatus IS NULL OR @pStatus = p.wStatus)
            AND (@pCategoryRid = 0 OR @pCategoryRid = mi.wCategoryRid)
            AND (@pDepartmentCode IS NULL OR @pDepartmentCode = mw.wDepartmentCode)
            AND (@pWarehouseRid IS NULL OR vw.RowID IS NOT NULL)
            AND (@pIsExpired IS NULL OR (p.wMaturityDate IS NOT NULL AND CONVERT(DATE, p.wMaturityDate) <> '0001-01-01' AND p.wMaturityDate < CONVERT(DATE, dbo.fnUTC8Now())))
            AND ((@pFromExpiryDt IS NULL AND @pToExpiryDt IS NULL) OR p.wMaturityDate BETWEEN @pFromExpiryDt AND @pToExpiryDt)
            AND (p.wCrtDt BETWEEN @pFromDt AND @pToDt)
            AND ( @pSaleStatus IS NULL  -- 所有記錄
              OR (@pSaleStatus = 'OPEN' AND (p.wPurchaseStatus = 'OPEN' OR si.wStockQuantity > 0))  -- 處理中（採購未完成、採購貨品未賣完）
              OR (@pSaleStatus = 'COMPLETE' AND p.wPurchaseStatus = 'COMPLETE' AND si.wStockQuantity = 0)  -- 完成（採購完成且且貨品全部賣出）
            )
        OPTION(RECOMPILE);

        WITH tSerialItem AS (
            SELECT 
                wPurchaseRid, 
                wItemRid,
                wStockQuantity = COUNT(1)
            FROM dbo.mItemSerial
            WHERE wStatus = 'A'
            GROUP BY wPurchaseRid, wItemRid
        )

        INSERT INTO #vResult(
            wPurchaseRid              ,
            wPurchaseDtlRid           ,
            wLotNo                    ,  -- 批次号
            wBatchNo                  ,  -- 批量号
            wIsCustomerOrder          ,  -- 客人订货
            wOrderAgentCodeIn_Display ,  -- 订货户口
            wGustAgentCodeIn_Display  ,  -- 送客户口
            wVendorName               ,  -- 供应商
            wPurchaseType             ,  -- 采购类型
            wPurchaseTypeName         ,  -- 采购类型
            wItemRid                  ,
            wItemType                 ,  -- 货品类型
            wItemName                 ,  -- 产品名称
            wValidDate                ,  -- 有效期
            wQuantity                 ,  -- 数量
            wCurrency                 ,  -- 貨幣
            wUnitCost                 ,  -- 单件成本
            wTotalCost                ,  -- 总成本
            wPurchaseStatus           ,  -- 采购状态
            wReceiptDate              ,  -- 收货日期
            wPurchaseCounter          ,  -- 落單服務櫃台
            wWarehouseName            ,  -- 入貨倉庫
            wStoreWarehouse           ,  -- 現存倉庫
            wStoreLocation            ,  -- 存放位置
            wMaturityDate             ,  -- 到期日
            wStockStatus              ,  -- 存货状态
            wNoticeRecord             ,  -- 通知记录
            wPurchaseRemark           ,  -- 备注
            wPurchaseDtlRemark        ,  -- 处理备注
            wItemStatus               ,  -- 货品状态
            wBalanceQuantity          ,  -- 未到货数量
            wStockQuantity            ,  -- 到货数量
            wAjustQuantity            ,  -- 调整数量
            wSaledQuantity            ,  -- 销售数量
            wCrtDt                    ,  -- 建立日期
            wUpdDt                    ,  -- 修改日期
            wStatus                      -- 状态
        )
        SELECT
            wPurchaseRid = p.RowID,
            wPurchaseDtlRid = pd.RowID,
            wLotNo = vp.wLotNo,
            wBatchNo = p.wBatchNo,
            wIsCustomerOrder = IIF(NULLIF(p.wAgentCodeIn, '') IS NULL, 'N', 'Y'),
            wOrderAgentCodeIn_Display = mo.wAgentCode_Display ,
            wGustAgentCodeIn_Display = mg.wAgentCode_Display ,
            wVendorName = IIF(@pLangCd = 'en-GB', mv.wEName, mv.wCName),
            wPurchaseType = pt.wCode,
            wPurchaseTypeName = pt.wTitle,
            wItemRid = mi.RowID,
            wItemType = IIF(@pLangCd = 'en-GB', mic.wEName, mic.wCName),
            wItemName = IIF(@pLangCd = 'en-GB', mi.wEName, mi.wCName),
            wValidDate = pd.wValidDate,
            wQuantity = pd.wQty,
            wCurrency = pd.wCurrCode,
            wUnitCost = pd.wUnitCost,
            wTotalCost = IIF(pd.RowID IS NULL, NULL, pd.wQty * pd.wUnitCost * pd.wCurrRate),
            wPurchaseStatus = ps.wTitle,
            wReceiptDate = p.wReceiptDate,
            wPurchaseCounter = CONCAT(mc.wCode, ' - ', mc.wName),
            wWarehouseName = IIF(@pLangCd = 'en-GB', mw.wEName, mw.wCName),
            wStoreWarehouse = CAST('' AS NVARCHAR(4000)),
            wStoreLocation = p.wStoreLocation,
            wMaturityDate = IIF(NULLIF(p.wAgentCodeIn, '') IS NULL OR (p.wPurchaseStatus != 'COMPLETE' AND (p.wMaturityDate IS NULL OR CONVERT(DATE, p.wMaturityDate) = '0001-01-01')),  NULL,
                            IIF(p.wMaturityDate IS NULL OR CONVERT(DATE, p.wMaturityDate) = '0001-01-01', DATEADD(DAY,90,dbo.fnUTC8Now()), p.wMaturityDate)),
            wStockStatus = IIF(NULLIF(p.wAgentCodeIn, '') IS NULL OR (p.wPurchaseStatus != 'COMPLETE' AND (p.wMaturityDate IS NULL OR CONVERT(DATE, p.wMaturityDate) = '0001-01-01')), '',
                            IIF(p.wMaturityDate IS NULL OR CONVERT(DATE, p.wMaturityDate) = '0001-01-01' OR DATEDIFF(DAY, p.wMaturityDate, dbo.fnUTC8Now()) < 0, N'未過期', N'已過期')),
            wNoticeRecord = p.wNoticeRecord,
            wPurchaseRemark = p.wRemarks,
            wPurchaseDtlRemark = pd.wHandleRemark,
            wItemStatus = NULL, -- 後面步驟計算得出：[未到貨] + [在庫] + [已調整] - [已銷售] = 0 = 已處理
                                                  --[未到貨] + [在庫] + [已調整] - [已銷售] > 0 = 處理中
            wBalanceQuantity = 0,
            wStockQuantity = ISNULL(IIF(mi.wIsSerialItem = 'Y', si.wStockQuantity, pd.wStockInQty), 0),
            wAjustQuantity = 0,
            wSaledQuantity = 0,
            wCrtDt = pd.wCrtDt,
            wUpdDt = pd.wUpdDt,
            wStatus  = cs.wTitle
        FROM #vPurchase vp
        INNER JOIN dbo.ePurchase p ON p.RowID = vp.RowID
        LEFT JOIN dbo.ePurchaseDtl pd ON pd.wPurchaseRid = p.RowID AND pd.wStatus = 'A'
        LEFT JOIN dbo.mServiceCounter mc ON mc.RowID = p.wPurchaseCounterRid
        LEFT JOIN dbo.mWarehouse mw ON mw.RowID = p.wInWarehouseRid
        LEFT JOIN dbo.mVendor mv ON mv.RowID = p.wVendorRid
        LEFT JOIN RollsMary.dbo.mAgent mo ON mo.wAgentCodeIn = p.wAgentCodeIn
        LEFT JOIN RollsMary.dbo.mAgent mg ON mg.wAgentCodeIn = p.wGuestCodeIn
        LEFT JOIN dbo.mItem mi ON mi.RowID = pd.wItemRid
        LEFT JOIN dbo.mItemCategory mic ON mic.RowID = mi.wCategoryRid
        LEFT JOIN tSerialItem si ON si.wPurchaseRid = pd.wPurchaseRid AND si.wItemRid = pd.wItemRid
        LEFT JOIN #vPurchaseType pt ON pt.wCode = p.wType
        LEFT JOIN #vPurchaseStatus ps ON ps.wCode = p.wPurchaseStatus
        LEFT JOIN #vCommonStatus cs ON cs.wCode = pd.wStatus;
        ------------------------------------------------------------------------------------------

        -------------------------------------調整數量、銷售數量------------------------------------
        WITH tStockAdjustment AS (
            SELECT
                sai.wPurchaseRid, 
                sad.wItemRid,
                wAjustQuantity = SUM(sai.wQty)
            FROM dbo.eStockAdjustment sa
            INNER JOIN dbo.eStockAdjustmentDtl sad ON sad.wStockAdjustmentRid = sa.RowID AND sad.wStatus = 'A'
            INNER JOIN dbo.eStockAdjustmentItem sai ON sai.wStockAdjustmentDtlRid = sad.RowID AND sai.wStatus = 'A'
            WHERE sa.wStatus = 'A' AND sa.wAdjustmentStatus = 'COMPLETE'
            GROUP BY sai.wPurchaseRid, sad.wItemRid
        ),
        tStockSaled AS (
            SELECT
                ss.wPurchaseRid, 
                ss.wItemRid,
                wSaledQuantity = SUM(ss.wSaledQuantity),
                wRFSaledQuantity = SUM(ss.wRFSaledQuantity)
            FROM (
                SELECT
                    ssi.wPurchaseRid, 
                    ssd.wItemRid,
                    wSaledQuantity = IIF(ss.wSalesStatus IN ('COMPLETE', 'REFUND'), ssi.wQty, 0), -- 完成、退款銷售數量
                    wRFSaledQuantity = IIF(ss.wSalesStatus = 'REFUND', ssi.wQty, 0) -- 退款退回數量
                FROM dbo.eStockSales ss
                INNER JOIN dbo.eStockSalesDtl ssd ON ssd.wStockSalesRid = ss.RowID AND ssd.wStatus = 'A'
                INNER JOIN dbo.eStockSalesItem ssi ON ssi.wStockSalesDtlRid = ssd.RowID AND ssi.wStatus = 'A'
                WHERE ss.wStatus = 'A' AND ss.wSalesStatus IN ('COMPLETE', 'REFUND')
                --GROUP BY ssi.wPurchaseRid, ssd.wItemRid, ss.wSalesStatus
            ) ss
            GROUP BY ss.wPurchaseRid, ss.wItemRid
        )
        
        UPDATE r
        SET r.wBalanceQuantity = r.wQuantity - r.wStockQuantity,
            r.wAjustQuantity = ISNULL(sa.wAjustQuantity, 0),
            r.wSaledQuantity = ISNULL(ss.wSaledQuantity, 0) - ISNULL(ss.wRFSaledQuantity, 0) -- 退款，相當于沒有賣出去
        FROM #vResult r
        LEFT JOIN tStockAdjustment sa ON sa.wPurchaseRid = r.wPurchaseRid AND sa.wItemRid = r.wItemRid
        LEFT JOIN tStockSaled ss ON ss.wPurchaseRid = r.wPurchaseRid AND ss.wItemRid = r.wItemRid;
        
        UPDATE #vResult SET wItemStatus = IIF((wStockQuantity + wBalanceQuantity + wAjustQuantity - wSaledQuantity) > 0 OR wPurchaseDtlRid IS NULL, N'處理中', N'已處理');

        -------------------------------------END 調整數量、銷售數量----------------------------------
        
        -----------------------------------------------現存倉庫---------------------------------------
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
            WHERE si.wPurchaseRid = r.wPurchaseRid AND si.wStatus = 'A' AND (si.wQty + ISNULL(ss.wQty, 0)) > 0
            FOR XML PATH('')), 1, 2, N'')
        FROM #vResult r;
        ---------------------------------------------END 現存倉庫-------------------------------------

        SELECT * FROM #vResult ORDER BY wCrtDt DESC;

        IF OBJECT_ID('tempdb..#vPurchase') IS NOT NULL
            DROP TABLE #vPurchase;

        IF OBJECT_ID('tempdb..#vPurchaseStatus') IS NOT NULL
            DROP TABLE #vPurchaseStatus;

        IF OBJECT_ID('tempdb..#vPurchaseType') IS NOT NULL
            DROP TABLE #vPurchaseType;

        IF OBJECT_ID('tempdb..#vCommonStatus') IS NOT NULL
            DROP TABLE #vCommonStatus;

        IF OBJECT_ID('tempdb..#vStockMovement') IS NOT NULL
            DROP TABLE #vStockMovement;
            
        IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
            DROP TABLE #vResult;
    END