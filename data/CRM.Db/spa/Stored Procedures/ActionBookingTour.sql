CREATE PROCEDURE [spa].[ActionBookingTour]
    @pXMLBooking XML = NULL ,
    @pXMLBookingTour XML = NULL ,
    @pXMLPassengerDetails XML = NULL ,
    @pXMLPassengerTravelDoc XML = NULL ,
    @pXMLVoucher XML = NULL ,
    @pActionType CHAR(1) ,
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pBookingRid BIGINT = 0 OUTPUT ,
    @pBookingTourRid BIGINT = 0 OUTPUT ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
AS
    BEGIN  
        SET NOCOUNT ON;  
  
        DECLARE @sBeginTranCount INT = 0;   
  
        SELECT  CAST(COUNT(*) AS BIGINT) AS wBookingRid ,
                CAST(COUNT(*) AS BIGINT) AS wBookingTourRid
        FROM    eBookingTourGuide;  
    
        SET @sBeginTranCount = @@trancount;  
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';  
  
        BEGIN TRY  
      -- Try to make the transaction scope as small as possible to reduce locking  
   
            IF @sBeginTranCount = 0
                BEGIN  
                    BEGIN TRAN;  
                END;  

            DECLARE @errorMsg VARCHAR(MAX);
            DECLARE @pAddRecord BIT= 0;

            IF @pActionType != 'D'
                BEGIN
				    -- Validate Status Management Update Booking field Start		
                    EXEC @errorMsg= [dbo].[fnValidateBookingTourByStatus] @pXml = @pXMLBooking, @pActionType = @pActionType;
                    IF @errorMsg <> ''
                        THROW 50001, @errorMsg, 1;	
					-- Validate Status Management Update Booking field End

                    IF @pXMLBooking IS NOT NULL
                        EXEC [spa].[SetBooking] @pXMLBooking, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT; 
                    IF @pXMLBookingTour IS NOT NULL
                        EXEC [spa].[SetBookingTour] @pXMLBookingTour, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pBookingTourRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;
                    IF @pXMLPassengerDetails IS NOT NULL
                        EXEC [spa].[SetPassengerDetailsCheckInServices] @pXMLPassengerDetails, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, 0, -1, @pErrCode OUTPUT, @pErrMsg OUTPUT;                 
                    IF @pXMLPassengerTravelDoc IS NOT NULL
                        EXEC [spa].[SetPassengerTravelDocCheckInServices] @pXMLPassengerTravelDoc, 'I', @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;   					
                END;
            IF @pActionType = 'D'
                BEGIN
                    IF @pXMLBooking IS NOT NULL
                        EXEC [spa].[SetBooking] @pXMLBooking, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT; 
                    IF @pXMLBookingTour IS NOT NULL
                        EXEC [spa].[SetBookingTour] @pXMLBookingTour, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pBookingTourRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;
                END;

            -- 當@pXMLVoucher IS NULL時也要Call，因為刪除的時候，可能不會傳值過來
            -- @pXMLVoucher IS NULL 刪除所有eVoucher.wBookingRid = @pBookingRid 的消費券
            EXEC [spa].[SeteVoucher] @pXMLVoucher, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;

            -- 【Calendar】-->【Mary】
            IF @pBookingRid IS NOT NULL AND @pBookingRid > 0 BEGIN
                EXEC util.WriteMaryAgentActivitiesApiLog @pBookingRid = @pBookingRid, @pBookingType = 'TOUR';
            END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
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
  
    END;