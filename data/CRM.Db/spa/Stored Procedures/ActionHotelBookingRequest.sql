CREATE PROCEDURE [spa].[ActionHotelBookingRequest]     
    @pXMLHotelBookingRequest XML = NULL ,
    @pXMLHotelBookingRequestDtl XML = NULL,        
    @pActionType CHAR(1) , 
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT	
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sBeginTranCount INT = 0	

    --SELECT COUNT(*) AS wRecordCount  FROM eHotelRequest
     
    SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';

     BEGIN TRY
            -- Try to make the transaction scope as small as possible to reduce locking
    
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

                DECLARE @pHotelBookingRid BIGINT = 0;
                
                IF @pXMLHotelBookingRequest IS NOT NULL
                    EXEC [spa].[SetHotelBookingRequest] @pXMLHotelBookingRequest, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pHotelBookingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT; 
                
                IF @pXMLHotelBookingRequestDtl IS NOT NULL
                    EXEC [spa].[SetHotelBookingRequestDtl] @pXMLHotelBookingRequest,@pXMLHotelBookingRequestDtl,@pActionType,@pMainCompNo, @pNonceToken, 'N', @pHotelBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;
    
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;		
                END;
                    
            RETURN ;
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
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ', @sCatchErrorMessage);
            
            IF @sBeginTranCount = 0
                AND ( @xstate = 1
                      OR @xstate = -1
                    )
                BEGIN
                -- transaction created within this sp
                    ROLLBACK;
                END;
            
            -- Write Log
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH;

END