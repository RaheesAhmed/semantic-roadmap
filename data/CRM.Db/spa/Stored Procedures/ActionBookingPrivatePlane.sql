CREATE PROCEDURE [spa].[ActionBookingPrivatePlane]
    @pXMLBooking XML = NULL ,
    @pXMLPrivatePlane XML = NULL ,
    @pXMLPrivatePlaneRouteDtl XML = NULL ,
    @pXMLPassengerDetailsCheckInServices XML = NULL ,
    @pXMLPassengerTravelDocCheckInServices XML = NULL ,
    @pXMLAdditionalExpenses XML = NULL ,
    @pXMLVoucher XML = NULL ,
    @pActionType CHAR(1) ,
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pBookingRid BIGINT = 0 ,
    @pBookingRidOut BIGINT = 0 OUTPUT ,
    @pBookingPrivatePlaneRid BIGINT OUTPUT ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
AS
    BEGIN          
        SET NOCOUNT ON;          
	
	-- SELECT CAST(Count(*) as BIGINT) as wBookingRid, CAST(Count(*) as BIGINT) as wBookingPassengerid  From eBooking     
	
        DECLARE @sBeginTranCount INT = 0;       
    
          
        SET @sBeginTranCount = @@trancount;          
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';          
          
        IF @pActionType = 'I'
            BEGIN
                IF @pXMLPassengerDetailsCheckInServices IS NOT NULL
                    THROW 50001, 'Passenger,passenger travel doc or voucher will not be saved before save booking', 1;					
            END;

        -- 當Edit時，如果沒有打開乘客資料編輯，旅行證件是不會傳過來的，Client也沒有Get數據，故此處不應該Check TravelDoc是否為空
        --IF @pActionType = 'U'
        --    AND @pXMLPassengerDetailsCheckInServices IS NOT NULL
        --    AND @pXMLPassengerTravelDocCheckInServices IS NULL
        --    THROW 50001, 'Travel Doc is Missing', 1;		

        IF @pActionType != 'D'
            AND @pXMLPrivatePlaneRouteDtl IS NULL
            THROW 50001, 'Private Plane Route detail is missing', 1;

        BEGIN TRY          
            IF @sBeginTranCount = 0
                BEGIN          
                    BEGIN TRAN;          
                END;                    					      
			
            IF @pXMLBooking IS NOT NULL
                EXEC [spa].[SetBooking] @pXMLBooking, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;  

            IF @pXMLPrivatePlane IS NOT NULL
                EXEC [spa].[SetBookingPrivatePlane] @pXMLPrivatePlane, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pBookingPrivatePlaneRid OUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;      
			
            IF @pXMLPrivatePlaneRouteDtl IS NOT NULL
                EXEC [spa].[SetPrivatePlaneRouteDtl] @pXMLPrivatePlaneRouteDtl, @pMainCompNo, 0, @pNonceToken, 'N', @pBookingPrivatePlaneRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;             
			
            IF @pXMLPrivatePlaneRouteDtl IS NOT NULL
                EXEC [spa].[SetUpdatePlaneRouteLineSeq] @pXMLPrivatePlaneRouteDtl, @pMainCompNo, 0, @pNonceToken, 'N', @pBookingPrivatePlaneRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;             
			
            IF @pXMLPassengerDetailsCheckInServices IS NOT NULL
                EXEC [spa].[SetPassengerDetailsCheckInServices] @pXMLPassengerDetailsCheckInServices, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, 0, -1, @pErrCode OUTPUT, @pErrMsg OUTPUT;                 
			
            IF @pXMLPassengerTravelDocCheckInServices IS NOT NULL
                EXEC [spa].[SetPassengerTravelDocCheckInServices] @pXMLPassengerTravelDocCheckInServices, 'I', @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;    
		    
            IF @pXMLAdditionalExpenses IS NOT NULL
                EXEC [spa].[SetAdditionalExpenses] @pXMLAdditionalExpenses, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;
			
            -- 當@pXMLVoucher IS NULL時也要Call，因為刪除的時候，可能不會傳值過來
            -- @pXMLVoucher IS NULL 刪除所有eVoucher.wBookingRid = @pBookingRid 的消費券
            EXEC [spa].[SeteVoucher] @pXMLVoucher, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;
			
			-- 【Calendar】 --> 【Mary】
			IF @pBookingRid IS NOT NULL AND @pBookingRid > 0 BEGIN
				EXEC util.WriteMaryAgentActivitiesApiLog @pBookingRid = @pBookingRid, @pBookingType = 'PP';
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