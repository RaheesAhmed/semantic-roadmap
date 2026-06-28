CREATE PROC [spq].[GetBirthdayGiftLst]
    @pBirthdayRid BIGINT,
    @pBirthday DATE, -- 新曆生日，不能計算舊曆，Mary轉碼按新曆計
    @pLangCd VARCHAR(10) = 'zh-TW'
AS
    BEGIN
        SET NOCOUNT ON;	

        DECLARE @sVIPPersonRid BIGINT; 
            
        SET @pLangCd      = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');
        SET @pBirthdayRid = ISNULL(IIF(@pBirthdayRid < 0, NULL, @pBirthdayRid), 0);
        -- 讀取wVIPPersonRid
        SET @sVIPPersonRid = (SELECT wVIPPersonRid FROM dbo.eBirthday WHERE RowID = @pBirthdayRid);

        WITH tVIPPerson AS (
            SELECT
                wVIPPersonRid = RowID,
                wGender,
                wBudgetRatio,
                wContactWay,
                wTelNumber,
                wWhatsappNumber,
                wWeChatNumber,
                wWeChatName,
                wSource
            FROM dbo.mVIPPerson
            WHERE RowID = @sVIPPersonRid
        ),
        tBirthdayGift AS (
            SELECT
                RowID,
                wBirthdayRid,
                wGiftReason,
                wGiftDescription,
                wBudgetCurrency,
                wBudgetAmt,
                wCostCurrency ,
                wCostAmt,
                wContactWay,
                wTelNumber,
                wWhatsappNumber,
                wWeChatNumber,
                wWeChatName,
                wRemark ,
                wSource,
                wUpdBy,
                wUpdDt
            FROM dbo.eBirthdayGift
            WHERE wBirthdayRid = @pBirthdayRid
                AND wStatus = 'A'
        ),
        tResult AS (
            SELECT
                RowID = ISNULL(bg.RowID, 0),
                bg.wBirthdayRid,
                mp.wVIPPersonRid,
                mp.wGender,
                bg.wGiftReason,
                bg.wGiftDescription,
                wBudgetCurrency = IIF(bg.RowID IS NOT NULL, bg.wBudgetCurrency, 'MOP'),
                wBudgetAmt      = IIF(bg.RowID IS NOT NULL, bg.wBudgetAmt,      0),
                wCostCurrency   = IIF(bg.RowID IS NOT NULL, bg.wCostCurrency,   'MOP'),
                wCostAmt        = IIF(bg.RowID IS NOT NULL, bg.wCostAmt,        0),
                wContactWay     = IIF(bg.RowID IS NOT NULL, bg.wContactWay,     mp.wContactWay),
                wTelNumber      = IIF(bg.RowID IS NOT NULL, bg.wTelNumber,      mp.wTelNumber),
                wWhatsappNumber = IIF(bg.RowID IS NOT NULL, bg.wWhatsappNumber, mp.wWhatsappNumber),
                wWeChatNumber   = IIF(bg.RowID IS NOT NULL, bg.wWeChatNumber,   mp.wWeChatNumber),
                wWeChatName     = IIF(bg.RowID IS NOT NULL, bg.wWeChatName,     mp.wWeChatName),
                wSource         = IIF(bg.RowID IS NOT NULL, bg.wSource,         mp.wSource),
                bg.wRemark,
                bg.wUpdBy,
                bg.wUpdDt,
                wDocumentRid    = ISNULL(ds.RowID, do.RowID),
                wDocumentName   = ISNULL(ds.wDocName, do.wDocName),
                wDocumentExt    = ISNULL(ds.wDocExt, do.wDocExt),
                wDocumentData   = ISNULL(ds.wFileData, do.wFileData), 
                wActionType     = ISNULL(IIF(bg.RowID IS NOT NULL, CHAR(85), NULL), CHAR(73))
            FROM tVIPPerson mp
            LEFT JOIN tBirthdayGift bg ON 1 = 1
            LEFT JOIN CRM_Doc.dbo.eDocument ds ON ds.wRefRID = bg.RowID AND ds.wRefTable = 'eBirthdayGift' AND ds.wStatus = 'A' AND ds.wSizeType = 'S'
            LEFT JOIN CRM_Doc.dbo.eDocument do ON do.wRefRID = bg.RowID AND do.wRefTable = 'eBirthdayGift' AND do.wStatus = 'A' AND do.wSizeType = 'O' AND ds.RowID IS NULL -- 舊數據
        )

        -- dbml
        --SELECT * FROM tResult;
        SELECT * INTO #vResult FROM tResult;
       
        -- 如果生日禮物是新建的（Schedule Job不會自動生成生日禮物，按需生成，因為Job Run的時候，還沒有預算）
        IF EXISTS (SELECT 1 FROM #vResult WHERE RowID <= 0 )
        BEGIN
            DECLARE @sXMLAgentCodeIn XML,
                    @sXMLResult XML,
                    @sBudgetAmt NUMERIC(18, 4),
                    @sRollingAvgAmt NUMERIC(18, 4),
                    @sGiftType VARCHAR(10);

            DECLARE @vBirthdayBudget TABLE(
                wAgentCodeIn VARCHAR(14), 
                wRollingAvgAmt NUMERIC(18, 4), -- 平均轉碼
                wTotalBudgetAmt NUMERIC(18, 4) -- 戶口的總預算（生日禮物預算需要再乘以預算比例）
            );

            -- 戶口根據三個月的平均轉碼計算總預算值
            ----------------------------------------------------------------------------
            SET @sXMLAgentCodeIn = (
                SELECT wAgentCodeIn 
                FROM dbo.mVIPPerson 
                WHERE RowID = @sVIPPersonRid
                FOR XML RAW('Record'), ROOT('DataSet')
            );

            EXEC spq.GetBirthdayBudget @sXMLAgentCodeIn, @pBirthday, @sXMLResult OUTPUT;
            
            INSERT INTO @vBirthdayBudget
            SELECT
                wAgentCodeIn    = T.tmp.value('@wAgentCodeIn',    'VARCHAR(14)'),
                wRollingAvgAmt  = T.tmp.value('@wRollingAvgAmt',  'NUMERIC(18, 4)'),
                wTotalBudgetAmt = T.tmp.value('@wTotalBudgetAmt', 'NUMERIC(18, 4)')
            FROM @sXMLResult.nodes('DataSet/Record') T(tmp);
            ----------------------------------------------------------------------------

            -- 客戶預算 = 戶口總預算 * 預算比例
            SET @sBudgetAmt = (
                SELECT TOP (1) wBudgetAmt = ar.wTotalBudgetAmt * mp.wBudgetRatio
                FROM dbo.mVIPPerson mp
                INNER JOIN @vBirthdayBudget ar ON ar.wAgentCodeIn = mp.wAgentCodeIn
                WHERE mp.RowID = @sVIPPersonRid
            );

            -- 戶口平均轉碼
            SET @sRollingAvgAmt = (
                SELECT TOP (1) ar.wRollingAvgAmt
                FROM dbo.mVIPPerson mp
                INNER JOIN @vBirthdayBudget ar ON ar.wAgentCodeIn = mp.wAgentCodeIn
                WHERE mp.RowID = @sVIPPersonRid
            );
            
            -- 是否送禮
            --SET @sGiftType = (
            --    SELECT TOP(1) wGiftType = IIF(mp.wIsPresentGift = 'N', '001', IIF(@sRollingAvgAmt > 10000, '003', '002')) -- 轉碼單位：萬
            --    FROM dbo.mVIPPerson mp 
            --    WHERE mp.RowID = @sVIPPersonRid
            --);

            -- 2018-12-03：R#53665，更改預設值 (原要求預設為"送禮卷"，現改預設為"送禮物")
            SET @sGiftType = (
                SELECT TOP(1) wGiftType = IIF(mp.wIsPresentGift = 'N', '001', '003') -- 轉碼單位：萬
                FROM dbo.mVIPPerson mp 
                WHERE mp.RowID = @sVIPPersonRid
            );

            -- 如果預算為空（戶口沒有轉碼），且客戶資料設置了預算比例（NOT NULL），把預算設置為0
            IF @sBudgetAmt IS NULL AND EXISTS (SELECT 1 FROM dbo.mVIPPerson WHERE RowID = @sVIPPersonRid AND wBudgetRatio IS NOT NULL)
                SET @sBudgetAmt = 0;

            UPDATE #vResult 
            SET wBudgetAmt = CASE @sGiftType
                             WHEN '003' THEN @sBudgetAmt    -- 送禮物
                             WHEN '002' THEN IIF(ISNULL(@sRollingAvgAmt, 0) < 5000, 1000, 2000)    -- 送禮券
                             ELSE 0 END, -- 不送禮
                wCostAmt  = CASE @sGiftType
                             WHEN '003' THEN @sBudgetAmt    -- 送禮物
                             WHEN '002' THEN IIF(ISNULL(@sRollingAvgAmt, 0) < 5000, 1000, 2000)    -- 送禮券
                             ELSE 0 END -- 不送禮
            WHERE RowID <= 0;
        END;

        SELECT * FROM #vResult;

        IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
            DROP TABLE #vResult;
    END;