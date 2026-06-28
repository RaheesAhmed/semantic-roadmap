 
CREATE PROCEDURE [spq].[GetAgentChipsByCage_CRM] ( 
	@pAgentCodeIn AS VARCHAR(14),
	@pLocationGrp AS VARCHAR(15), 
	@pCurrCode AS VARCHAR(3) = '',
	@puserRid AS VARCHAR(15),
	@pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
	) 
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sBeginTranCount INT = 0;

	   --SELECT Count(*) as wRecordCount From eCashTransfer

        SET @sBeginTranCount = @@TRANCOUNT;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';

        BEGIN TRY
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

           EXEC RollsMary.spq.GetAgentChipsByCage @pAgentCodeIn,@pLocationGrp,@pCurrCode,@puserRid;

            IF @sBeginTranCount = 0
                AND @@TRANCOUNT > 0
                BEGIN
                    COMMIT;
                END;
	   
            RETURN;		
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
                    SET @pErrCode = 999;
                END;
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ',
                                  @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0
                AND ( @xstate = 1
                      OR @xstate = -1
                    )
                BEGIN
			 -- transaction created within this sp
                    ROLLBACK;
                END;
        END CATCH;

    END;