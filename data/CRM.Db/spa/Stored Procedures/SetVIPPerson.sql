
CREATE PROCEDURE [spa].[SetVIPPerson]
    @pXML XML ,
    @pActionType CHAR(1) , -- I/U/D
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pVIPPersonRid BIGINT OUTPUT,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sThisTableName     VARCHAR(50) = 'mVIPPerson' ,
                @sBeginTranCount	INT = 0 ,
                @sDocHandle			INT,
                @sRecCount			INT = 0,
                @sRuningIndex		INT = 1,
                @sRowID				BIGINT = 0,
                @sNow				DATETIME2 = dbo.fnUTC8Now();
        
        SET @sBeginTranCount = @@trancount;
        SET @pErrCode = 0;
        SET @pErrMsg = '';
    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ) ,
                *
        INTO    #sDataSet_SetVIPPerson
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (  
            RowID                   BIGINT,
            wAgentCodeIn            VARCHAR(14),
            wPersonName             NVARCHAR(50),
            wPersonIdentity         VARCHAR(30),
            wGender                 VARCHAR(5), 
            wAuthorizerAgentCodeIn  VARCHAR(14),
            wAuthorizerIdentity     VARCHAR(30),
            wRelationship           VARCHAR(30),
            wOtherRelationship      NVARCHAR(200),
            wBirthDate              DATE,
            wCalendarType           CHAR(5),
            wYear                   INT,
            wMonth                  INT,
            wDay                    INT,
            wIsLeapMonth            CHAR(1),
            wContactWay             VARCHAR(30),
            wTelNumber              NVARCHAR(150),
            wWhatsappNumber         NVARCHAR(100),
            wWeChatNumber           NVARCHAR(100),
            wWeChatName             NVARCHAR(100),
            wBudgetRatio            NUMERIC(18,4),
            wIsWeChatVerify         CHAR(1),
            wIsPresentGift          CHAR(1),
            wIsAuthorizer           CHAR(1),
            wVIPPersonStatus        CHAR(1),
            wStatusRemark           NVARCHAR(4000),
            wSource                 VARCHAR(10),
            wIsRefusedContact       CHAR(1),
            wStatus                 CHAR(1),
            wCrtBy                  BIGINT,
            wCrtDt                  DATETIME2(7),
            wUpdBy                  BIGINT,
            wUpdDt                  DATETIME2(7)
        );

        BEGIN TRY	                
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;

            ---------------------------------------------------------------Checking-----------------------------------------------------------
            SET @sRecCount = (SELECT COUNT(1) FROM #sDataSet_SetVIPPerson);
            IF NULLIF(@pErrMsg, '') IS NULL AND @sRecCount = 0
            BEGIN
                SET @pErrMsg = N'沒有數據需要保存。';
            END;

            IF NULLIF(@pErrMsg, '') IS NULL AND @sRecCount > 1
            BEGIN
                SET @pErrMsg = N'不支持同時保存多條數據。';
            END;

            IF NULLIF(@pErrMsg, '') IS NULL AND @pActionType NOT IN ('I', 'U', 'D')
            BEGIN
                SET @pErrMsg = N'非法操作';
            END;

            IF NULLIF(@pErrMsg, '') IS NOT NULL
                THROW 50001, @pErrMsg, 1;
            -------------------------------------------------------------End Checking-----------------------------------------------------------
        		
            IF @pActionType = 'I'
            BEGIN
                SET @sRecCount = (SELECT COUNT(*) FROM #sDataSet_SetVIPPerson);

                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
                    
                    UPDATE #sDataSet_SetVIPPerson
                    SET RowID = @sRowID 
                    WHERE wRowNum = @sRuningIndex;

                    SET @sRuningIndex = @sRuningIndex + 1;
                END	

                INSERT INTO [dbo].[mVIPPerson]
                (
                    RowID, 
                    wAgentCodeIn,
                    wPersonName, 
                    wPersonIdentity, 
                    wGender, 
                    wAuthorizerAgentCodeIn, 
                    wAuthorizerIdentity, 
                    wRelationship, 
                    wOtherRelationship,
                    wBirthDate, 
                    wCalendarType, 
                    wYear, 
                    wMonth, 
                    wDay, 
                    wIsLeapMonth,
                    wContactWay, 
                    wTelNumber, 
                    wWhatsappNumber, 
                    wWeChatNumber, 
                    wWeChatName, 
                    wBudgetRatio, 
                    wIsWeChatVerify, 
                    wIsPresentGift,
                    wIsAuthorizer,
                    wVIPPersonStatus,
                    wStatusRemark,
                    wSource,
                    wIsRefusedContact,
                    wStatus, 
                    wCrtBy, 
                    wCrtDt, 
                    wUpdBy, 
                    wUpdDt
                )
                SELECT
                    RowID, 
                    wAgentCodeIn,
                    wPersonName, 
                    wPersonIdentity, 
                    wGender, 
                    wAuthorizerAgentCodeIn, 
                    wAuthorizerIdentity, 
                    wRelationship, 
                    wOtherRelationship,
                    wBirthDate, 
                    wCalendarType, 
                    wYear, 
                    wMonth, 
                    wDay, 
                    wIsLeapMonth,
                    wContactWay, 
                    wTelNumber, 
                    wWhatsappNumber, 
                    wWeChatNumber, 
                    wWeChatName, 
                    wBudgetRatio, 
                    wIsWeChatVerify, 
                    wIsPresentGift,
                    wIsAuthorizer = 'N',        -- 授權人（默認不是授權人）
                    wVIPPersonStatus,
                    wStatusRemark,
                    wSource = '001',            -- 資訊來源（默認VIP資料）
                    wIsRefusedContact = 'N',    -- 拒絕接觸
                    wStatus = 'A',              -- 記錄有效
                    wCrtBy, 
                    @sNow, 
                    wUpdBy, 
                    @sNow
                FROM #sDataSet_SetVIPPerson;
            END
            ELSE IF @pActionType = 'U'
            BEGIN
                UPDATE p
                SET wAgentCodeIn = tmp.wAgentCodeIn,
                    wPersonName = tmp.wPersonName,
                    wPersonIdentity = tmp.wPersonIdentity,
                    wGender = tmp.wGender, 
                    wAuthorizerAgentCodeIn = tmp.wAuthorizerAgentCodeIn,
                    wAuthorizerIdentity = tmp.wAuthorizerIdentity, 
                    wRelationship = tmp.wRelationship,
                    wOtherRelationship = tmp.wOtherRelationship,
                    wBirthDate = tmp.wBirthDate,
                    wCalendarType = tmp.wCalendarType,
                    wYear = tmp.wYear,
                    wMonth = tmp.wMonth,
                    wDay = tmp.wDay,
                    wIsLeapMonth = tmp.wIsLeapMonth,
                    wContactWay = tmp.wContactWay,
                    wTelNumber = tmp.wTelNumber,
                    wWhatsappNumber = tmp.wWhatsappNumber,
                    wWeChatNumber = tmp.wWeChatNumber,
                    wWeChatName = tmp.wWeChatName,
                    wBudgetRatio = tmp.wBudgetRatio ,
                    wIsWeChatVerify = tmp.wIsWeChatVerify,
                    wIsPresentGift = tmp.wIsPresentGift,
                    -- wIsAuthorizer = tmp.wIsAuthorizer,           -- 授權人不能update
                    wVIPPersonStatus = tmp.wVIPPersonStatus,
                    wStatusRemark = tmp.wStatusRemark,
                    -- wSource = tmp.wSource                        -- 資訊來源不能Update
                    -- wIsRefusedContact = tmp.wIsRefusedContact,   -- 拒絕接觸不能Update
                    -- wStatus = tmp.wStatus,                       -- 只能pActionType = 'D' 刪除記錄
                    wUpdBy = tmp.wUpdBy,
                    wUpdDt = @sNow
                FROM [dbo].[mVIPPerson] p 
                INNER JOIN #sDataSet_SetVIPPerson tmp ON tmp.RowID = p.RowID;
            END
            ELSE IF @pActionType = 'D'
            BEGIN
                UPDATE  p
                SET wStatus = 'T' ,
                    wUpdBy = tmp.wUpdBy,
                    wUpdDt = @sNow
                FROM [dbo].[mVIPPerson] p 
                INNER JOIN #sDataSet_SetVIPPerson tmp ON tmp.RowID = p.RowID
            END;

           IF @sBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                COMMIT;
            END;

			SET @pVIPPersonRid = (SELECT TOP(1) RowID FROM #sDataSet_SetVIPPerson);
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