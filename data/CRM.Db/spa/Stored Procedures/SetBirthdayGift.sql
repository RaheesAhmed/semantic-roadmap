CREATE PROCEDURE [spa].[SetBirthdayGift]
    @pXML XML ,      
    @pBirthdayRid BIGINT,
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pBirthdayGiftRid BIGINT OUTPUT,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sThisTableName VARCHAR(50) = 'eBirthdayGift' ,
                @sBeginTranCount	INT = 0 ,
                @sDocHandle			INT,
                @sRecCount			INT = 0,
                @sRuningIndex		INT = 1,
                @sRowID				BIGINT = 0,
                @sUpdBy             BIGINT = 0,
                @sNow				DATETIME2 = dbo.fnUTC8Now();
        
        SET @sBeginTranCount = @@trancount;
        SET @pErrCode = 0;
        SET @pErrMsg = '';
        SET @pBirthdayRid = ISNULL(IIF(@pBirthdayRid < 0, NULL, @pBirthdayRid), 0);
    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ) ,
                *
        INTO    #sDataSet_SetBirthdayGift
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
        WITH (
            RowID BIGINT,
            wBirthdayRid BIGINT,
            wGiftReason NVARCHAR(500),
            wGiftDescription NVARCHAR(50),
            wBudgetCurrency VARCHAR(10), -- 预算货币
            wBudgetAmt NUMERIC(18,4), -- 预算
            wCostCurrency VARCHAR(10), -- 价值货币
            wCostAmt NUMERIC(18,4), -- 价值
            wContactWay VARCHAR(10),
            wTelNumber NVARCHAR(150),
            wWhatsappNumber VARCHAR(50),
            wWeChatNumber NVARCHAR(100),
            wWeChatName NVARCHAR(100),
            wRemark NVARCHAR(4000),
            wSource VARCHAR(10),
            wStatus CHAR(1),
            wCrtBy BIGINT,
            wCrtDt DATETIME2(7),
            wUpdBy BIGINT,
            wUpdDt DATETIME2(7),
            wActionType VARCHAR(1)
        );
        
        EXEC sp_xml_removedocument @sDocHandle;  

        BEGIN TRY	                
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;
        	
             ------------------------ Checking -----------------------------
            IF NULLIF(@pErrMsg, '') IS NULL AND @pBirthdayRid = 0
            BEGIN
                SET @pErrMsg = N'生日禮物沒有指定VIP客戶。';
            END;

            IF NULLIF(@pErrMsg, '') IS NULL AND EXISTS (SELECT 1 FROM #sDataSet_SetBirthdayGift WHERE wActionType NOT IN ('I', 'U', 'D'))
            BEGIN
                SET @pErrMsg = N'非法操作。';
            END;

            SELECT @sRecCount = COUNT(1) FROM #sDataSet_SetBirthdayGift WHERE wActionType IN ('I', 'U');
            IF NULLIF(@pErrMsg, '') IS NULL AND @sRecCount = 0
            BEGIN
                SET @pErrMsg = N'至少要給VIP客戶送一份禮物.';
            END;

            IF NULLIF(@pErrMsg, '') IS NOT NULL
                THROW 50001, @pErrMsg, 1;
            -----------------------End Checking ---------------------------

            -- 把Insert的Record的RowID設置為0
            UPDATE #sDataSet_SetBirthdayGift 
            SET RowID = 0 
            WHERE wActionType = 'I';

            -- 刪除無效的禮物
            SELECT TOP(1) @sUpdBy = wUpdBy FROM #sDataSet_SetBirthdayGift WHERE wActionType IN ('I', 'U');
            UPDATE bg
            SET wStatus = 'T',
                wUpdBy = @sUpdBy,
                wUpdDt = @sNow
            FROM dbo.eBirthdayGift bg
            LEFT JOIN #sDataSet_SetBirthdayGift tmp ON tmp.RowID = bg.RowID
            WHERE bg.wBirthdayRid = @pBirthdayRid
                AND tmp.RowID IS NULL
                AND bg.wStatus = 'A';
            	
            IF EXISTS ( SELECT 1 FROM #sDataSet_SetBirthdayGift WHERE wActionType = 'I' )
            BEGIN
                SELECT @sRecCount = COUNT(*) FROM #sDataSet_SetBirthdayGift

                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    IF EXISTS ( SELECT 1 FROM #sDataSet_SetBirthdayGift WHERE wActionType = 'I' AND wRowNum = @sRuningIndex)
                    BEGIN
                        EXEC spq.GetRowId @pMainCompNo, @sThisTableName, @sRowID OUTPUT
                        
                        UPDATE #sDataSet_SetBirthdayGift
                        SET RowID = @sRowID
                        WHERE wRowNum = @sRuningIndex
                    END
                    
                    SET @sRuningIndex = @sRuningIndex + 1;
                END
                
                INSERT INTO [dbo].[eBirthdayGift] (
                    RowID,
                    wBirthdayRid,
                    wGiftReason,
                    wGiftDescription,
                    wBudgetCurrency,
                    wBudgetAmt,
                    wCostCurrency,
                    wCostAmt,
                    wContactWay ,
                    wTelNumber,
                    wWhatsappNumber,
                    wWeChatNumber,
                    wWeChatName,
                    wRemark,
                    wSource ,
                    wStatus,
                    wCrtBy,
                    wCrtDt,
                    wUpdBy,
                    wUpdDt
                )
                SELECT 
                    RowID,
                    wBirthdayRid,
                    wGiftReason,
                    wGiftDescription,
                    wBudgetCurrency,
                    wBudgetAmt,
                    wCostCurrency,
                    wCostAmt,
                    wContactWay ,
                    wTelNumber,
                    wWhatsappNumber,
                    wWeChatNumber,
                    wWeChatName,
                    wRemark,
                    wSource ,
                    wStatus,
                    wCrtBy,
                    @sNow,
                    wUpdBy,
                    @sNow
                FROM #sDataSet_SetBirthdayGift
                WHERE wActionType = 'I';
            END;
            
            IF EXISTS ( SELECT 1 FROM #sDataSet_SetBirthdayGift WHERE wActionType = 'U' )
            BEGIN
                UPDATE bg
                SET --wBirthdayRid = tmp.wBirthdayRid, 
                    wGiftReason = tmp.wGiftReason,
                    wGiftDescription = tmp.wGiftDescription,
                    wBudgetCurrency = tmp.wBudgetCurrency,
                    wBudgetAmt = tmp.wBudgetAmt,
                    wCostCurrency = tmp.wCostCurrency,
                    wCostAmt = tmp.wCostAmt,
                    wContactWay = tmp.wContactWay ,
                    wTelNumber = tmp.wTelNumber,
                    wWhatsappNumber = tmp.wWhatsappNumber,
                    wWeChatNumber = tmp.wWeChatNumber,
                    wWeChatName = tmp.wWeChatName,
                    wRemark = tmp.wRemark,
                    wSource = tmp.wSource ,
                    wStatus = tmp.wStatus,
                    wUpdBy = tmp.wUpdBy, 
                    wUpdDt = @sNow 
                FROM [dbo].[eBirthdayGift] bg 
                INNER JOIN #sDataSet_SetBirthdayGift tmp ON tmp.RowID = bg.RowID
                WHERE tmp.wActionType = 'U';
            END;

            IF EXISTS ( SELECT  1 FROM #sDataSet_SetBirthdayGift WHERE wActionType = 'D' )
            BEGIN
                UPDATE bg
                SET wStatus = 'T' ,
                    wUpdBy = tmp.wUpdBy,
                    wUpdDt = @sNow
                FROM [dbo].[eBirthdayGift] bg
                INNER JOIN #sDataSet_SetBirthdayGift tmp ON tmp.RowID = bg.RowID
                WHERE tmp.wActionType = 'D';
            END;
            
            IF @sBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                COMMIT;
            END;

            SET @pBirthdayGiftRid = (SELECT TOP(1) RowID FROM #sDataSet_SetBirthdayGift);
        END TRY
        BEGIN CATCH
            DECLARE @sErrorNum INT ,
                    @sCatchErrorMessage NVARCHAR(4000) ,
                    @xstate INT ,
                    @sProcedureName VARCHAR(100) ,
                    @sRtnCodeLog INT ,
                    @sErrMessageLog NVARCHAR(4000);
        
            SET @sErrorNum = ERROR_NUMBER();
            SET @pErrCode = ERROR_NUMBER();
            SET @sCatchErrorMessage = ERROR_MESSAGE();
            SET @xstate = XACT_STATE();
            SET @sProcedureName = OBJECT_NAME(@@PROCID);
		
            IF ISNULL(@pErrCode, 0) = 0
            BEGIN
                SET @pErrCode = 70001;
            END;

            SET @pErrMsg = CONCAT('(', @sErrorNum, ') ', @sCatchErrorMessage);

            IF @sBeginTranCount = 0
            BEGIN
                IF @xstate != 0
                    ROLLBACK;

                -- Write Log
                EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
            END;
            ELSE
                THROW;           
        END CATCH;
        
        IF OBJECT_ID('tempdb..#sDataSet_SetBirthdayGift') IS NOT NULL
            DROP TABLE #sDataSet_SetBirthdayGift;

    END;