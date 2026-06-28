
CREATE PROCEDURE [spa].[ActionBookingAirTicket]
    @pXMLBooking XML = NULL ,
    @pXMLBookingAirTicket XML = NULL ,
    @pXMLTicketCollection XML = NULL ,
    @pXMLPassengerDetailsForAir XML = NULL ,
    @pXMLAirTicketRouteDtl XML = NULL ,
    @pXMLPassengerTravelDoc XML = NULL ,
    @pXMLVoucher XML = NULL ,
    @pXMLAdditionalExpenses XML = NULL ,
    @pActionType CHAR(1) ,
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pBookingRid BIGINT = 0 OUTPUT ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sBeginTranCount INT = 0 ,
            @pTicketCollRId BIGINT = 0;

	---SELECT COUNT(*) AS wRecordCount  from eBookingAirTicket
	 
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';

        BEGIN TRY
	-- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
				
            DECLARE @pClientTicketId BIGINT = 0 ,
                    @sTicketCollectionActionType CHAR(1);		
		
            IF @pXMLBooking IS NOT NULL AND @pXMLBookingAirTicket IS NOT NULL
            BEGIN
                DECLARE @sBookingStatus VARCHAR(10);
                SET @sBookingStatus = @pXMLBookingAirTicket.value('(DataSet/Record/@wBookingStatus)[1]', 'VARCHAR(10)');
                -- 如果是以下幾種狀態，強制把按金設置為0
                IF @sBookingStatus IN ('C', 'CL', 'UQ', 'RF')
                BEGIN
                    SET @pXMLBooking.modify('replace value of (/DataSet/SetBookingResult/@wDepositAmt)[1] with ("0")');
                END;
            END;

            IF @pXMLBooking IS NOT NULL
                EXEC [spa].[SetBooking] @pXMLBooking, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT; 		

            SET @sTicketCollectionActionType = CASE WHEN EXISTS ( SELECT    1
                                                                  FROM      dbo.eTicketCollection tc
                                                                  WHERE     tc.wBookingRid = @pBookingRid ) THEN 'U'
                                                    ELSE 'I'
                                               END;
		
            IF @pXMLBookingAirTicket IS NOT NULL
                EXEC [spa].[SetBookingAirTicket] @pXMLBookingAirTicket, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pClientTicketId OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;
		
            -- 當@pXMLVoucher IS NULL時也要Call，因為刪除的時候，可能不會傳值過來
            -- @pXMLVoucher IS NULL 刪除所有eVoucher.wBookingRid = @pBookingRid 的消費券
            -- 消費券需要放到@pActionType <> 'D'，否則當@pActionType = 'D'時，消費券退不了
            EXEC [spa].[SeteVoucher] @pXMLVoucher, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT; 	

            IF @pActionType <> 'D'
            BEGIN
			
                IF @pXMLTicketCollection IS NOT NULL
                    EXEC [spa].[SetTicketCollection] @pXMLTicketCollection, @sTicketCollectionActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pTicketCollRId OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT; 

                IF @pXMLPassengerDetailsForAir IS NOT NULL
                    EXEC [spa].[SetPassengerDetails_ForAir] @pXMLPassengerDetailsForAir, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, 'AIRTICKET', 0, @pErrCode OUTPUT, @pErrMsg OUTPUT;  -- temp
			
                IF @pXMLAirTicketRouteDtl IS NOT NULL
                    EXEC [spa].[SetAirTicketRouteDtl] @pXMLAirTicketRouteDtl, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, 'AIRTICKET', @pErrCode OUTPUT, @pErrMsg OUTPUT;
			
                IF @pXMLAirTicketRouteDtl IS NOT NULL
                    EXEC [spa].[SetUpdateAirTicketRouteLineSeq] @pXMLAirTicketRouteDtl, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, 'AIRTICKET', @pErrCode OUTPUT, @pErrMsg OUTPUT;

                IF @pXMLPassengerTravelDoc IS NOT NULL
                    EXEC [spa].[SetPassengerTravelDoc] @pXMLPassengerTravelDoc, 'I', @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT; 
			
                IF @pXMLAdditionalExpenses IS NOT NULL
                    EXEC [spa].[SetAdditionalExpenses] @pXMLAdditionalExpenses, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT; 
            END;

			-- 【Calendar】-->【Mary】
			IF @pBookingRid IS NOT NULL AND @pBookingRid > 0 BEGIN
				EXEC util.WriteMaryAgentActivitiesApiLog @pBookingRid = @pBookingRid, @pBookingType = 'AIRTICKET';
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