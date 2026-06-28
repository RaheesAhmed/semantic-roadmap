CREATE PROCEDURE [spa].[ActionBookingLeading]
    @pXMLBooking XML = NULL ,
    @pXMLBookingLeading XML = NULL ,
    @pXMLVoucher XML = NULL ,
    @pActionType CHAR(1) ,
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pBookingRid BIGINT = 0 OUTPUT ,
    @pBookingLeadingRid BIGINT = 0 OUTPUT ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
AS
    BEGIN  
        SET NOCOUNT ON;  
  
        DECLARE @sBeginTranCount INT = 0;   
  
   --Select CAST(Count(*) as BIGINT) as wBookingRid, CAST(Count(*) as BIGINT) as wBookingLeadingRid  from eBookingAirTicket  
    
        SET @sBeginTranCount = @@TRANCOUNT;  
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
            
            IF @pXMLBookingLeading IS NOT NULL
                EXEC [spa].[SetBookingLeading] @pXMLBookingLeading, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pBookingLeadingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;  							

            -- 當@pXMLVoucher IS NULL時也要Call，因為刪除的時候，可能不會傳值過來
            -- @pXMLVoucher IS NULL 刪除所有eVoucher.wBookingRid = @pBookingRid 的消費券
            EXEC [spa].[SeteVoucher] @pXMLVoucher, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT; 

            -- 【Calendar】-->【Mary】
            IF @pBookingRid IS NOT NULL AND @pBookingRid > 0 BEGIN
                EXEC util.WriteMaryAgentActivitiesApiLog @pBookingRid = @pBookingRid, @pBookingType = 'LEADING_SERVICE';
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

            IF @sBeginTranCount = 0 AND @@TRANCOUNT > 0
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
     
            IF @sBeginTranCount = 0 AND (@xstate = 1 OR @xstate = -1)
                BEGIN  
				 -- transaction created within this sp  
                    ROLLBACK;
                END;
           
         -- Write Log  
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;  
        END CATCH;    
    END;