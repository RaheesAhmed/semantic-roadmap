
CREATE PROCEDURE [spa].[ActionCashTransfer]
    (
      @pXMLCashTransfer XML ,
      @pXMLCashTransferDtl XML ,
      @pXMLTransferCentre XML ,
      @pMainCompNo INT ,
      @pMainCageCodeIn VARCHAR(14) ,
      @pMainCounter VARCHAR(2) ,
      @pCompNo INT ,
      @pCageCodeIn VARCHAR(14) ,
      @pAuthBy BIGINT ,
      @pType VARCHAR(20) ,
      @pRemark NVARCHAR(500) ,
      @pNonceToken VARCHAR(64) ,
      @pCashTransferRid BIGINT OUTPUT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
    )
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sBeginTranCount INT = 0;

	    --SELECT RowID, wTransferGUID From eCashTransfer
        SET @sBeginTranCount = @@TRANCOUNT;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';

        BEGIN TRY
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF @pXMLCashTransfer IS NOT NULL
                EXEC [spa].[SetCashTransfer] @pXMLCashTransfer, @pXMLTransferCentre, @pMainCompNo,
                    @pMainCageCodeIn, @pMainCounter, @pCompNo, @pCageCodeIn,
                    @pAuthBy, @pType, @pRemark, 0, @pNonceToken, 'Y',
                    @pCashTransferRid OUTPUT, @pErrCode OUTPUT,
                    @pErrMsg OUTPUT;
			 
            IF @pXMLCashTransferDtl IS NOT NULL
                EXEC [spa].[SetCashTransferDtl] @pXMLCashTransferDtl,
                    @pMainCompNo, 0, @pNonceToken, 'N',
                    @pCashTransferRid OUTPUT, @pErrCode OUTPUT,
                    @pErrMsg OUTPUT;

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
	        
	       -- Write Log
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName,
                @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH;
    END;