CREATE PROC [spq].[GetRptStockAdjustment]
    @pXMLFilter XML,
    @pLangCd VARCHAR(10) = 'zh-TW'
AS
    BEGIN
        SET NOCOUNT ON;

        ------------------------------------------------------------------------
        -- dbml
        --DECLARE @vResult TABLE (
        --    wAdjustDt                 DATE,          -- 調整時間
        --    wWarehouseName            NVARCHAR(100), -- 倉庫
        --    wOrderAgentCodeIn_Display NVARCHAR(50),  -- 訂貨户口
        --    wLotNo                    VARCHAR(50),   -- 批次號碼
        --    wBatchNo                  VARCHAR(50),   -- 批量号,
        --    wPurchaseType             NVARCHAR(50),  -- 采购类型,
        --    wItemRid                  BIGINT,
        --    wItemType                 NVARCHAR(50),  -- 货品类型
        --    wItemName                 NVARCHAR(100), -- 产品名称
        --    wValidDate                DATETIME2(7),  -- 有效期
        --    wQuantity                 INT,           -- 数量
        --    wCurrency                 VARCHAR(10),   -- 貨幣,
        --    wUnitCost                 NUMERIC(18,4), -- 单件成本
        --    wApproval                 NVARCHAR(100), -- 批核人
        --    wAdjustmentRemark         NVARCHAR(500), -- 備註
        --    wAdjustmentStatus         NVARCHAR(10),  -- 調整狀態
        --    wCrtDt                    DATETIME2(7),  -- 建立日期
        --    wUpdDt                    DATETIME2(7),  -- 修改日期
        --    wStatus                   NVARCHAR(10)   --狀態
        --);
        --SELECT * FROM @vResult
        ------------------------------------------------------------------------
        
        DECLARE @pAdjustFromDt      DATE,
                @pAdjustToDt        DATE,
                @pAdjustmentStatus  VARCHAR(30),
                @pAgentCodeIn       VARCHAR(14),
                @pDepartmentCode    VARCHAR(50),
                @pWarehouseRid      VARCHAR(MAX),
                @pStatus            CHAR(1);

        -- 仓库
        DECLARE @vWarehouse TABLE (RowID BIGINT PRIMARY KEY);

        IF @pXMLFilter IS NOT NULL
        BEGIN
            SET @pAdjustFromDt     = @pXMLFilter.value('(Filter/@pAdjustFromDt)[1]',        'DATE');
            SET @pAdjustToDt       = @pXMLFilter.value('(Filter/@pAdjustToDt)[1]',          'DATE');
            SET @pAdjustmentStatus = @pXMLFilter.value('(Filter/@pAdjustmentStatus)[1]',    'VARCHAR(30)');
            SET @pAgentCodeIn      = @pXMLFilter.value('(Filter/@pAgentCodeIn)[1]',         'VARCHAR(14)');
            SET @pDepartmentCode   = @pXMLFilter.value('(Filter/@pDepartmentCode)[1]',      'VARCHAR(50)');
            SET @pWarehouseRid     = @pXMLFilter.value('(Filter/@pWarehouseRid)[1]',        'VARCHAR(MAX)');
            SET @pStatus           = @pXMLFilter.value('(Filter/@pStatus)[1]',              'CHAR(1)');
        END;

        SET @pAdjustmentStatus  = NULLIF(@pAdjustmentStatus, '');
        SET @pAgentCodeIn       = NULLIF(@pAgentCodeIn, '');
        SET @pDepartmentCode    = NULLIF(@pDepartmentCode, '');
        SET @pWarehouseRid      = NULLIF(@pWarehouseRid, '');
        SET @pStatus            = NULLIF(@pStatus, '');

        IF @pAdjustFromDt IS NOT NULL OR @pAdjustToDt IS NOT NULL
        BEGIN
            SET @pAdjustFromDt   = ISNULL(@pAdjustFromDt, '0001-01-01');
            SET @pAdjustToDt     = ISNULL(@pAdjustToDt,'2099-12-31');
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

        CREATE TABLE #vAdjustmentStatus(wCode NVARCHAR(50) PRIMARY KEY, wTitle NVARCHAR(150));
        CREATE TABLE #vPurchaseType(wCode NVARCHAR(50) PRIMARY KEY, wTitle NVARCHAR(150));

        INSERT INTO #vAdjustmentStatus(wCode, wTitle)
        SELECT wCode, wTitle
        FROM dbo.mLookUp
        WHERE wType ='INVENTORY_ADJUSTMENT' AND wLangCd =@pLangCd;

        INSERT INTO #vPurchaseType(wCode, wTitle)
        SELECT wCode, wTitle
        FROM dbo.mLookUp
        WHERE wType ='PURCHASE_TYPE' AND wLangCd =@pLangCd;

        SELECT
            wAdjustDt = sa.wAdjustDt,
            wWarehouseName = IIF(@pLangCd = 'en-GB', mw.wEName, mw.wCName),
            wOrderAgentCodeIn_Display = mo.wAgentCode_Display,
            wLotNo = SUBSTRING(p.wLotNo, CHARINDEX('-', p.wLotNo)+1, LEN(p.wLotNo)),
            wBatchNo = p.wBatchNo,
            wPurchaseType = pt.wTitle,
            wItemRid = sad.wItemRid,
            wItemType = IIF(@pLangCd = 'en-GB', mic.wEName, mic.wCName),
            wItemName = IIF(@pLangCd = 'en-GB', mi.wEName, mi.wCName),
            wValidDate = pd.wValidDate,
            wQuantity = sai.wQty,
            wCurrency = ISNULL(pd.wCurrCode, 'HKD'),
            wUnitCost = pd.wUnitCost * pd.wCurrRate,
            wApproval = IIF(@pLangCd = 'en-GB', mu.wName, mu.wCName),
            wAdjustmentRemark = sa.wRemarks,
            wAdjustmentStatus = sas.wTitle, 
            sa.wCrtDt,
            sa.wUpdDt,
            wStatus = IIF(sa.wStatus = 'A', N'有效', N'中止')
        FROM dbo.eStockAdjustment sa
        INNER JOIN dbo.eStockAdjustmentDtl sad ON sad.wStockAdjustmentRid = sa.RowID AND sad.wStatus = 'A'
        INNER JOIN dbo.eStockAdjustmentItem sai ON sai.wStockAdjustmentDtlRid = sad.RowID AND sai.wStatus = 'A'
        LEFT JOIN dbo.ePurchase p ON p.RowID = sai.wPurchaseRid
        LEFT JOIN dbo.ePurchaseDtl pd ON pd.wPurchaseRid = p.RowID AND pd.wItemRid = sad.wItemRid
        LEFT JOIN dbo.mItem mi ON mi.RowID = sad.wItemRid
        LEFT JOIN dbo.mItemCategory mic ON mic.RowID = mi.wCategoryRid
        LEFT JOIN dbo.mWarehouse mw ON mw.RowID = sa.wWarehouseRid
        LEFT JOIN RollsMary.dbo.mAgent mo ON mo.wAgentCodeIn = p.wAgentCodeIn
        LEFT JOIN RollsMary.dbo.mUsr mu ON mu.RowID = sa.wApprovalByRid
        LEFT JOIN #vPurchaseType pt ON pt.wCode = p.wType
        LEFT JOIN #vAdjustmentStatus sas ON sas.wCode = sa.wAdjustmentStatus
        LEFT JOIN @vWarehouse vw ON vw.RowID = mw.RowID
        WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = p.wAgentCodeIn)
            AND (@pDepartmentCode IS NULL OR @pDepartmentCode = mw.wDepartmentCode)
            AND (@pAdjustmentStatus IS NULL OR @pAdjustmentStatus = sa.wAdjustmentStatus)
            AND (@pWarehouseRid IS NULL OR vw.RowID IS NOT NULL)
            AND (@pStatus IS NULL OR @pStatus = sa.wStatus)
            AND ((@pAdjustFromDt IS NULL AND @pAdjustToDt IS NULL) OR (sa.wAdjustDt BETWEEN @pAdjustFromDt AND @pAdjustToDt))
        OPTION(RECOMPILE);

        IF OBJECT_ID('tempdb..#vAdjustmentStatus') IS NOT NULL
            DROP TABLE #vAdjustmentStatus;

        IF OBJECT_ID('tempdb..#vPurchaseType') IS NOT NULL
            DROP TABLE #vPurchaseType;
    END