
CREATE PROCEDURE [spa].[ActionVIPPerson]
    @pXMLVIPPerson XML = NULL ,
    @pXMLVIPPersonShip XML = NULL ,
    @pActionType CHAR(1) , -- I/U/D
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pVIPPersonRid BIGINT = 0 OUTPUT ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        ---------------------- dbml -----------------------
        --DECLARE @sResult TABLE(RowID BIGINT NOT NULL);
        --SELECT RowID FROM @sResult;
        --------------------end dbml ----------------------

        DECLARE @sBeginTranCount INT = 0;

        SET @sBeginTranCount = @@trancount;
        SET @pErrCode = 0;
        SET @pErrMsg = '';

        BEGIN TRY
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;
				
            IF NULLIF(@pErrMsg, '') IS NULL
                EXEC spa.SetVIPPerson @pXMLVIPPerson, @pActionType, @pMainCompNo, @pNonceToken, @pVIPPersonRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;

            IF NULLIF(@pErrMsg, '') IS NULL
                EXEC spa.SetVIPPersonShip @pXMLVIPPersonShip, @pVIPPersonRid, @pMainCompNo, @pNonceToken, @pErrCode OUTPUT,  @pErrMsg OUTPUT;

            -- Update Birthday Record
            IF NULLIF(@pErrMsg, '') IS NULL AND @pActionType IN ('I', 'U', 'D')
            BEGIN
                DECLARE @sYear INT = YEAR(GETDATE());
                
                EXEC [util].[RecalVIPPersonBirthday] @sYear, 'N', @pVIPPersonRid; 
            END;

            -- 是否送禮有改變過的戶口，且為不送禮
            -- T掉不送禮，且沒有MD、VIP跟進的客戶
            -- 只針對授權人，用戶自己添加的VIP客戶資料不管
            ------------------------------------------------------------------------------------------------
            IF NULLIF(@pErrMsg, '') IS NULL AND @pActionType = 'U' AND @pVIPPersonRid > 0
            BEGIN
                 DECLARE @sAuthorizerAgentCodeIn VARCHAR(14);
                 SET @sAuthorizerAgentCodeIn = (SELECT TOP(1) wAuthorizerAgentCodeIn FROM dbo.mVIPPerson WHERE RowID = @pVIPPersonRid AND wIsAuthorizer = 'Y' AND wIsPresentGift = 'N');
                 
                 IF NULLIF(@sAuthorizerAgentCodeIn, '') IS NOT NULL
                    EXEC util.RecalVIPPerson NULL, @sAuthorizerAgentCodeIn, 'U';
            END;
            ------------------------------------------------------------------------------------------------

            IF NULLIF(@pErrMsg, '') IS NOT NULL
                THROW 50001, @pErrMsg, 1;

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
	        
            SELECT  @sErrorNum = ERROR_NUMBER() ,
                    @sCatchErrorMessage = ERROR_MESSAGE() ,
                    @xstate = XACT_STATE() ,
                    @sProcedureName = OBJECT_NAME(@@PROCID);
			
            IF ISNULL(@pErrCode, 0) = 0
            BEGIN
                SET @pErrCode = 70001;
            END;

            IF NULLIF(@pErrMsg, '') IS NULL
                SET @pErrMsg = CONCAT('(', @sErrorNum, ') ', @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0 AND ( @xstate = 1 OR @xstate = -1 )
            BEGIN
                ROLLBACK;
            END;
	        
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;

        END CATCH;
    END;