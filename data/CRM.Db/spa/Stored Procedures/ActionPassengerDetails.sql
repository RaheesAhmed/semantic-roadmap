CREATE PROCEDURE [spa].[ActionPassengerDetails]                                                         
	@pXML XML ,                                      
	@pActionType CHAR(1) ,                                 
	@pMainCompNo INT ,                                
	@pNonceToken VARCHAR(64) ,                                
	@pBookingRid BIGINT = 0,
	@pBookingType VARCHAR(30)='',
	@pErrCode INT = 0 OUTPUT,                                   
	@pErrMsg NVARCHAR(200) = '' OUTPUT	 
AS                                
BEGIN                                
    SET NOCOUNT ON;                                
                                
	DECLARE @sBeginTranCount INT = 0        
 
	-- SELECT COUNT(*) AS wRecordCount  FROM ePassengerDetails                         
                                
	SET @sBeginTranCount = @@trancount;                                
	SELECT  @pErrCode = 0 ,                                
			@pErrMsg = '';                                
                                
	BEGIN TRY                                                                 
		IF @sBeginTranCount = 0                                
        BEGIN                                
            BEGIN TRAN;                                
        END; 
		 
		IF @pBookingType!='AIRTICKET'
		BEGIN
			DECLARE @pCheckinServiceRid BIGINT = 0                      
			EXEC [spa].[SetPassengerDetailsCheckInServices] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, 1, @pCheckinServiceRid, @pErrCode OUTPUT, @pErrMsg OUTPUT                 
			EXEC [spa].[SetPassengerTravelDocCheckInServices]  @pXML, 'I', @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT
			IF @pBookingType = 'HELI' AND @pActionType<>'D'
			BEGIN
				EXEC [spa].[SetAdditionalExpenses] @pXML, 'U', @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;				
			END
        END
		
		IF @pBookingType='AIRTICKET'
		BEGIN		
			EXEC [spa].[SetPassengerDetails_ForAir] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid,'PASSENGER',0, @pErrCode OUTPUT, @pErrMsg OUTPUT                 
			IF @pActionType<>'D'
			BEGIN
				EXEC [spa].[SetPassengerTravelDoc_ForAir] @pXML, 'I', @pMainCompNo, @pNonceToken, 'N', @pBookingRid,'PASSENGER', @pErrCode OUTPUT, @pErrMsg OUTPUT
				EXEC [spa].[SetAirTicketRouteDtl] @pXML, @pActionType, @pMainCompNo, @pNonceToken,'N', @pBookingRid,'PASSENGER', @pErrCode OUTPUT, @pErrMsg OUTPUT;
				EXEC [spa].[SetAdditionalExpenses] @pXML, 'U', @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;
			END
        END

		IF @sBeginTranCount = 0 AND @@trancount > 0
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
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ',                      
                                  @sCatchErrorMessage);                                
         
   IF @sBeginTranCount = 0                            
    AND ( @xstate = 1                                
                      OR @xstate = -1                                
                    )                                
                BEGIN                                
                    ROLLBACK;                                
                END;                                
 
         -- Write Log                                
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName,                                
                @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;                                
   END CATCH;                     
END