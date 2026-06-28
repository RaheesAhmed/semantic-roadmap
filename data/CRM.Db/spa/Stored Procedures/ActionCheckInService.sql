CREATE PROCEDURE [spa].[ActionCheckInService]
    @pXMLBooking XML ,
    @pXMLVoucher XML ,
    @pXMLTicketCollection XML ,
    @pXMLCheckInService XML ,
    @pXMLPassengerDetailsCheckInServices XML ,
    @pXMLPassengerTravelDocCheckInServices XML ,
    @pActionType CHAR(1) ,
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pBookingRid BIGINT = 0 ,
    @pBookingRidOut BIGINT = 0 OUTPUT ,
    @pTicketCollRid BIGINT = 0 OUTPUT ,
    @pCheckinServiceRid BIGINT = 0 OUTPUT ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
AS
    BEGIN                                
        SET NOCOUNT ON;                                
     
     --Select Count(*) as wRecordCount,Count(*) as wRecordCount1  from eBookingCheckInService
                                
        DECLARE @sBeginTranCount INT = 0;                                 
                                
        SET @sBeginTranCount = @@trancount;                                
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';          
                                  
                                
        BEGIN TRY                                
                                 
            IF @sBeginTranCount = 0
                BEGIN                                
                    BEGIN TRAN;                                
                END;    
            DECLARE @errorMsg VARCHAR(MAX);
            DECLARE @pAddRecord BIT= 0;
/*
            IF @pActionType = 'I'
            BEGIN
                IF @pXMLPassengerDetailsCheckInServices IS NOT NULL
                    SET @pAddRecord =1
                IF @pXMLPassengerTravelDocCheckInServices IS NOT NULL							
                    SET @pAddRecord =1
                IF @pXMLVoucher IS NOT NULL
                    SET @pAddRecord =1
            END
            
            IF @pAddRecord = 1
                THROW 50001, 'Can Not insert passenger, passenger travel doc or voucher before saving Check In Service booking', 1;	

            IF @pXMLBooking IS NOT NULL
            BEGIN
                    
                -- Validate Status Management Update Booking field Start		
                    EXEC @errorMsg= [dbo].[fnValidateUpdateCheckInServiceByStatus] @pXml=@pXMLBooking,@pActionType= @pActionType
                    IF @errorMsg <> ''
                    THROW 50001, @errorMsg, 1;		                                                                    
                EXEC [spa].[SetBooking] @pXMLBooking, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;  
            END   
            IF EXISTS(SELECT RowID FROM eBookingCheckInService WHERE wBookingRid =  @pBookingRid AND wBookingStatus IN('P')) AND @pXMLTicketCollection IS NOT NULL
                THROW 50001, 'Ticket Collection object can not be saved when booking status is In-Progress', 1;	

*/
            IF @pXMLBooking IS NOT NULL
                EXEC [spa].[SetBooking] @pXMLBooking, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;  
                    
            IF @pXMLPassengerDetailsCheckInServices IS NOT NULL
                EXEC [spa].[SetPassengerDetailsCheckInServices] @pXMLPassengerDetailsCheckInServices, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, 0, @pCheckinServiceRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;        

            IF @pXMLCheckInService IS NOT NULL
                EXEC [spa].[SetCheckInService] @pXMLCheckInService, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pCheckinServiceRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;        

            -- 當@pXMLVoucher IS NULL時也要Call，因為刪除的時候，可能不會傳值過來
            -- @pXMLVoucher IS NULL 刪除所有eVoucher.wBookingRid = @pBookingRid 的消費券
            EXEC [spa].[SeteVoucher] @pXMLVoucher, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;

            IF @pXMLTicketCollection IS NOT NULL
                EXEC [spa].[SetTicketCollection] @pXMLTicketCollection, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pTicketCollRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;
         
            IF @pXMLPassengerTravelDocCheckInServices IS NOT NULL
                EXEC [spa].[SetPassengerTravelDocCheckInServices] @pXMLPassengerTravelDocCheckInServices, 'I', @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;
            
            -- 【Calendar】-->【Mary】
            IF @pBookingRid IS NOT NULL AND @pBookingRid > 0 BEGIN
                EXEC util.WriteMaryAgentActivitiesApiLog @pBookingRid = @pBookingRid, @pBookingType = 'CHK_IN_SVC';
            END;

            -- Update RollsMary.dbo.eExpTran 中的 remark.
            IF @pActionType = 'U'
            BEGIN
                DECLARE @vXMLUpdExp NVARCHAR(MAX) = '' ,
                            @vErrCode INT = 0 ,
                            @vErrMsg NVARCHAR(MAX);

                SET @vXMLUpdExp = (SELECT e.* 
                        FROM RollsMary.dbo.eExpTran AS e 
                         WHERE e.wExpGroup = 'RCRM' AND e.wExpType = 'I' AND e.wDeductType = 'DC' AND e.wIsDeposit <> 'Y' AND e.wBookingRid = @pBookingRid
                    FOR XML RAW('Record') , ROOT('DataSet'));

                IF @vXMLUpdExp != ''
                BEGIN
                    EXEC spa.SetCrmExpTran @pXML = @vXMLUpdExp, -- xml
                        @pActionType = 'U', -- char(1)
                        @pMainCompNo = @pMainCompNo, -- int
                        @pNonceToken = @pNonceToken, -- varchar(64)
                        @pErrCode = @vErrCode OUTPUT, -- int
                        @pErrMsg = @vErrMsg OUTPUT; -- nvarchar(200)
                    IF @vErrCode != 0
                        BEGIN
                            SET @pErrMsg = @vErrMsg;
                            THROW 50001, @pErrMsg, 1;
                        END;
                END;
            END

            SET @pBookingRidOut = @pBookingRid;     
         
             -- EXEC [spa].[SetActivityLog] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;                       
                                
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