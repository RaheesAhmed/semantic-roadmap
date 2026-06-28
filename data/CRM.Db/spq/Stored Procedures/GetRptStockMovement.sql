CREATE PROC [spq].[GetRptStockMovement]
    @pXMLFilter XML,
    @pLangCd VARCHAR(10) = 'zh-TW'
AS
    BEGIN
        SET NOCOUNT ON;

        ------------------------------------------------------------------------
        -- dbml
        --DECLARE @vResult TABLE (
        --    wStockMovementRid         BIGINT,
        --    wStockMovementDtlRid      BIGINT,
        --    wStockMovementItemRid     BIGINT,
        --    wOutWarehouseName         NVARCHAR(100), -- 出貨倉庫
        --    wInWarehouseName          NVARCHAR(100), -- 入貨倉庫
        --    wAgentCode_Display        NVARCHAR(50),  -- 訂貨户口
        --    wLotNo                    VARCHAR(50),   -- 批次號碼
        --    wBatchNo                  VARCHAR(50),   -- 批量号,
        --    wPurchaseType             VARCHAR(50),   -- 採購類型
        --    wPurchaseTypeName         NVARCHAR(50),  -- 採購類型
        --    wItemName                 NVARCHAR(100), -- 類別
        --    wCategoryName             NVARCHAR(100), -- 產品名稱
        --    wValidDate                DATETIME2(7),  -- 有效期
        --    wQty                      INT,           -- 数量
        --    wCurrCode                 VARCHAR(10),   -- 貨幣,
        --    wUnitCostHKD              NUMERIC(18,4), -- 每件成本
        --    wRemarks                  NVARCHAR(500), -- 備註
        --    wMovementStatusName       NVARCHAR(10),  -- 轉倉狀態
        --    wCrtDt                    DATETIME2(7),  -- 建立日期
        --    wUpdDt                    DATETIME2(7),  -- 修改日期
        --    wStatusName               NVARCHAR(10)   --狀態
        --);
        --SELECT * FROM @vResult
        ------------------------------------------------------------------------

        DECLARE @pOutFromDt           DATE,
                @pOutToDt             DATE,
                @pInFromDt            DATE,
                @pInToDt              DATE,
                @pMovementStatus      VARCHAR(30),
                @pAgentCodeIn         VARCHAR(14),
                @pOutDepartmentCode   VARCHAR(50),
                @pInDepartmentCode    VARCHAR(50),
                @pOutWarehouseRid     VARCHAR(MAX),
                @pInWarehouseRid      VARCHAR(MAX),
                @pStatus              CHAR(1);

        -- 出貨仓库
        DECLARE @vOutWarehouse TABLE (RowID BIGINT PRIMARY KEY);
        -- 入貨仓库
        DECLARE @vInWarehouse TABLE (RowID BIGINT PRIMARY KEY);

        IF @pXMLFilter IS NOT NULL
        BEGIN
            SET @pOutFromDt         = @pXMLFilter.value('(Filter/@pOutFromDt)[1]',            'DATE');
            SET @pOutToDt           = @pXMLFilter.value('(Filter/@pOutToDt)[1]',              'DATE');
            SET @pInFromDt          = @pXMLFilter.value('(Filter/@pInFromDt)[1]',             'DATE');
            SET @pInToDt            = @pXMLFilter.value('(Filter/@pInToDt)[1]',               'DATE');
            SET @pMovementStatus    = @pXMLFilter.value('(Filter/@pMovementStatus)[1]',       'VARCHAR(30)');
            SET @pAgentCodeIn       = @pXMLFilter.value('(Filter/@pAgentCodeIn)[1]',          'VARCHAR(14)');
            SET @pOutDepartmentCode = @pXMLFilter.value('(Filter/@pOutDepartmentCode)[1]',    'VARCHAR(50)');
            SET @pInDepartmentCode  = @pXMLFilter.value('(Filter/@pInDepartmentCode)[1]',     'VARCHAR(50)');
            SET @pOutWarehouseRid   = @pXMLFilter.value('(Filter/@pOutWarehouseRid)[1]',      'VARCHAR(MAX)');
            SET @pInWarehouseRid    = @pXMLFilter.value('(Filter/@pInWarehouseRid)[1]',       'VARCHAR(MAX)');
            SET @pStatus            = @pXMLFilter.value('(Filter/@pStatus)[1]',               'CHAR(1)');
        END;

        SET @pMovementStatus    = NULLIF(@pMovementStatus, '');
        SET @pAgentCodeIn       = NULLIF(@pAgentCodeIn, '');
        SET @pOutDepartmentCode = NULLIF(@pOutDepartmentCode, '');
        SET @pInDepartmentCode  = NULLIF(@pInDepartmentCode, '');
        SET @pOutWarehouseRid   = NULLIF(@pOutWarehouseRid, '');
        SET @pInWarehouseRid    = NULLIF(@pInWarehouseRid, '');
        SET @pStatus            = NULLIF(@pStatus, '');

        IF @pOutFromDt IS NOT NULL OR @pOutToDt IS NOT NULL
        BEGIN
            SET @pOutFromDt   = ISNULL(@pOutFromDt, '0001-01-01');
            SET @pOutToDt     = ISNULL(@pOutToDt,'2099-12-31');
        END;

        IF @pInFromDt IS NOT NULL OR @pInToDt IS NOT NULL
        BEGIN
            SET @pInFromDt   = ISNULL(@pInFromDt, '0001-01-01');
            SET @pInToDt     = ISNULL(@pInToDt,'2099-12-31');
        END;

        IF @pOutWarehouseRid IS NOT NULL
        BEGIN
            DECLARE @sXMLOutWarehouse XML;
            SET @sXMLOutWarehouse = CONVERT(XML,'<DataSet><Record>' + REPLACE(@pOutWarehouseRid, ',', '</Record><Record>') + '</Record></DataSet>');

            INSERT INTO @vOutWarehouse(RowID)
            SELECT DISTINCT T.tmp.value('.', 'BIGINT')
            FROM @sXMLOutWarehouse.nodes('DataSet/Record') T(tmp)
            WHERE T.tmp.value('.', 'BIGINT') > 0;
        END;

        IF @pInWarehouseRid IS NOT NULL
        BEGIN
            DECLARE @sXMLInWarehouse XML;
            SET @sXMLInWarehouse = CONVERT(XML,'<DataSet><Record>' + REPLACE(@pInWarehouseRid, ',', '</Record><Record>') + '</Record></DataSet>');

            INSERT INTO @vInWarehouse(RowID)
            SELECT DISTINCT T.tmp.value('.', 'BIGINT')
            FROM @sXMLInWarehouse.nodes('DataSet/Record') T(tmp)
            WHERE T.tmp.value('.', 'BIGINT') > 0;
        END;

        CREATE TABLE #vMovementItems(RowID BIGINT PRIMARY KEY, wItemName NVARCHAR(100),wCategoryName NVARCHAR(100));

        INSERT INTO #vMovementItems(RowID, wItemName,wCategoryName)
        SELECT mi.RowID ,
               wItemName = IIF(@pLangCd = 'en-GB', mi.wEName,mi.wCName) ,
               wCategoryName = IIF(@pLangCd = 'en-GB', mc.wEName, mc.wCName)
        FROM dbo.mItem mi
        LEFT JOIN dbo.mItemCategory mc ON mc.RowID = mi.wCategoryRid 

        SELECT  wStockMovementRid = sm_t.RowID,
                wStockMovementDtlRid = smd.RowID,
                wStockMovementItemRid = smi.RowID,
                wOutWarehouseName = IIF(@pLangCd = 'en-GB', w_o.wEName, w_o.wCName), 
                wInWarehouseName = IIF(@pLangCd = 'en-GB', w_i.wEName, w_i.wCName),
                ma.wAgentCode_Display ,
                wLotNo = SUBSTRING(p.wLotNo,CHARINDEX('-',p.wLotNo)+1,LEN(p.wLotNo)) ,
                p.wBatchNo,
                wPurchaseType = ml.wCode,
                wPurchaseTypeName = ml.wTitle ,
                mi.wItemName ,
                mi.wCategoryName ,
                pd.wValidDate,
                smi.wQty,
                p.wCurrCode ,
                smi.wUnitCostHKD ,
                sm_t.wRemarks ,
                wMovementStatusName = mls.wTitle ,
                sm_t.wCrtDt ,
                sm_t.wUpdDt ,
                wStatusName = IIF(sm_t.wStatus = 'A',N'有效',N'中止')
        FROM dbo.eStockMovement sm_t
        INNER JOIN dbo.eStockMovementDtl smd ON sm_t.RowID = smd.wStockMovementRid AND smd.wStatus = 'A'
        INNER JOIN dbo.eStockMovementItem smi ON smd.RowID = smi.wStockMovementDtlRid AND smi.wStatus = 'A'
        LEFT JOIN dbo.mWarehouse w_i ON w_i.RowID = sm_t.wInWarehouseRid
        LEFT JOIN dbo.mWarehouse w_o ON w_o.RowID = sm_t.wOutWarehouseRid
        LEFT JOIN dbo.ePurchase p ON p.RowID = smi.wPurchaseRid AND p.wStatus = 'A'
        LEFT JOIN dbo.ePurchaseDtl pd ON pd.wPurchaseRid = p.RowID AND pd.wItemRid = smd.wItemRid
        LEFT JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = p.wAgentCodeIn
        LEFT JOIN dbo.mLookUp ml ON ml.wType = 'PURCHASE_TYPE' AND ml.wCode = p.wType AND ml.wLangCd = @pLangCd
        LEFT JOIN #vMovementItems mi ON mi.RowID = smd.wItemRid
        LEFT JOIN dbo.mLookUp mls ON mls.wType = 'INVENTORY_MOVEMENT' AND mls.wCode = sm_t.wMovementStatus AND mls.wLangCd = @pLangCd
        LEFT JOIN @vOutWarehouse vw_o ON vw_o.RowID = w_o.RowID
        LEFT JOIN @vInWarehouse vw_i ON vw_i.RowID = w_i.RowID
        WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = p.wAgentCodeIn)
            AND (@pOutDepartmentCode IS NULL OR @pOutDepartmentCode = w_o.wDepartmentCode)
            AND (@pInDepartmentCode IS NULL OR @pInDepartmentCode = w_i.wDepartmentCode)
            AND (@pStatus IS NULL OR @pStatus = sm_t.wStatus)
            AND (@pOutWarehouseRid IS NULL OR vw_o.RowID IS NOT NULL)
            AND (@pInWarehouseRid IS NULL OR vw_i.RowID IS NOT NULL)
            AND (@pMovementStatus IS NULL OR @pMovementStatus = sm_t.wMovementStatus)
            AND ((@pOutFromDt IS NULL AND @pOutToDt IS NULL) OR (sm_t.wOutDt BETWEEN @pOutFromDt AND @pOutToDt)) 
            AND ((@pInFromDt IS NULL AND @pInToDt IS NULL) OR (sm_t.wInDt BETWEEN @pInFromDt AND @pInToDt)) 
        OPTION(RECOMPILE);

         IF OBJECT_ID('tempdb..#vMovementItems') IS NOT NULL
            DROP TABLE #vMovementItems;
    END