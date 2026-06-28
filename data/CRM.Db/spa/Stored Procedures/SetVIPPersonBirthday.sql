
-- VIPLst頁面保存【是否送禮】
CREATE PROC [spa].[SetVIPPersonBirthday]
    @pXML XML,
    @pActionType CHAR(1), -- U
    @pMainCompNo INT,
    @pErrCode INT OUTPUT,
    @pErrMsg NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        ------------------
        -- dbml
        -- SELECT RowID, wIsPresentGift, wUpdBy, wUpdDt FROM dbo.mVIPPerson;
        ------------------

        DECLARE @sThisTableName     VARCHAR(50) = 'mVIPPerson' ,
                @sBeginTranCount	INT = 0 ,
                @sDocHandle			INT,
                @sYear              INT,
                @sNow				DATETIME2 = dbo.fnUTC8Now();
        
        DECLARE @vAuthorizerAgent TABLE(wAgentCodeIn VARCHAR(14) PRIMARY KEY);

        SET @sBeginTranCount = @@trancount;
        SET @pErrCode = 0;
        SET @pErrMsg  = '';
    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ) ,
                *
        INTO    #sDataSet_SetVIPPerson
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
            RowID           BIGINT,
            wIsPresentGift  CHAR(1),
            wUpdBy          BIGINT,
            wUpdDt          DATETIME2(7)
        );

        BEGIN TRY	                
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;
        		
            IF @pActionType = 'U'
            BEGIN
                -- 是否送禮有改變過的戶口，且為不送禮
                -- T掉不送禮，且沒有MD、VIP跟進的客戶
                -- 只針對授權人，用戶自己添加的VIP客戶資料不管
                ------------------------------------------------------------------------
                INSERT INTO @vAuthorizerAgent (wAgentCodeIn)
                SELECT DISTINCT mp.wAuthorizerAgentCodeIn
                FROM [dbo].[mVIPPerson] mp
                INNER JOIN #sDataSet_SetVIPPerson tmp ON tmp.RowID = mp.RowID
                WHERE NULLIF(mp.wAuthorizerAgentCodeIn, '') IS NOT NULL
                    AND mp.wIsAuthorizer = 'Y' 
                    AND tmp.wIsPresentGift = 'N'
                    --AND mp.wIsPresentGift != tmp.wIsPresentGift;
                ------------------------------------------------------------------------

                UPDATE mp
                SET wIsPresentGift = tmp.wIsPresentGift,
                    wUpdBy = tmp.wUpdBy,
                    wUpdDt = @sNow
                FROM [dbo].[mVIPPerson] mp 
                INNER JOIN #sDataSet_SetVIPPerson tmp ON tmp.RowID = mp.RowID;

                -- Update Birthday Record
                SET @sYear = YEAR(@sNow);
                EXEC util.RecalVIPPersonBirthday @sYear, 'Y', 0;

                -- 是否送禮有改變過的戶口，且為不送禮
                -- T掉不送禮，且沒有MD、VIP跟進的客戶
                -- 只針對授權人，用戶自己添加的VIP客戶資料不管
                ------------------------------------------------------------------------
                DECLARE @sAuthorizerAgentCodeIn VARCHAR(14); 
                DECLARE curAgent CURSOR FOR SELECT wAgentCodeIn FROM @vAuthorizerAgent;
                OPEN curAgent;
                FETCH NEXT FROM curAgent INTO @sAuthorizerAgentCodeIn;
                WHILE @@fetch_status = 0
                BEGIN
                    EXEC util.RecalVIPPerson NULL, @sAuthorizerAgentCodeIn, 'U';

                    FETCH NEXT FROM curAgent INTO @sAuthorizerAgentCodeIn;
                END;
                CLOSE curAgent;
                DEALLOCATE curAgent;
                ------------------------------------------------------------------------
            END

           IF @sBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                COMMIT;
            END;

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
                SET @pErrCode = 70001;

            SET @pErrMsg = CONCAT('(', @sErrorNum, ') ', @sCatchErrorMessage);

            IF @sBeginTranCount = 0
                BEGIN
                    IF @xstate != 0
                        ROLLBACK;

                    -- Write Log
					EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
                END;
            ELSE
                THROW @pErrCode, @pErrMsg, 1;             			
                              
        END CATCH;

        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetVIPPerson') IS NOT NULL
            DROP TABLE #sDataSet_SetVIPPerson;
    END;