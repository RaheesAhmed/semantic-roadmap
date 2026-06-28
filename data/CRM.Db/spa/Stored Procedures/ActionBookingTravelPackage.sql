CREATE PROCEDURE [spa].[ActionBookingTravelPackage]
    @pXMLBooking XML = NULL ,
    @pXMLBookingTravelPackage XML = NULL ,
    @pXMLPassengerDetailsCheckInServices XML = NULL ,
    @pXMLPassengerTravelDocCheckInServices XML = NULL ,
    @pXMLVoucher XML = NULL ,
    @pActionType CHAR(1) ,
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pBookingRid BIGINT = 0 OUTPUT ,
    @pTravelPackageRid BIGINT = 0 OUTPUT ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        --Select Count(*) as wRecordCount,Count(*) as wRecordCount1  from eBookingTravelPackage

        DECLARE @sBeginTranCount INT = 0;	
	 
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';

        BEGIN TRY
        -- Try to make the transaction scope as small as possible to reduce locking
	
        IF @sBeginTranCount = 0
        BEGIN
            BEGIN TRAN;
        END;										

        IF @pXMLBooking IS NOT NULL
            EXEC [spa].[SetBooking] @pXMLBooking, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT; 									      
            
        IF @pXMLBookingTravelPackage IS NOT NULL
            EXEC [spa].[SetBookingTravelPackage] @pXMLBookingTravelPackage, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pTravelPackageRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;    

        EXEC [spa].[SetPassengerDetailsCheckInServices] @pXMLPassengerDetailsCheckInServices, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, 0, 0, @pErrCode OUTPUT, @pErrMsg OUTPUT;

        IF @pXMLPassengerTravelDocCheckInServices IS NOT NULL
            EXEC [spa].[SetPassengerTravelDocCheckInServices] @pXMLPassengerTravelDocCheckInServices, 'I', @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;
            
        -- 當@pXMLVoucher IS NULL時也要Call，因為刪除的時候，可能不會傳值過來
        -- @pXMLVoucher IS NULL 刪除所有eVoucher.wBookingRid = @pBookingRid 的消費券
        EXEC [spa].[SeteVoucher] @pXMLVoucher, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT; 					
	
        IF @sBeginTranCount = 0 AND @@trancount > 0
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