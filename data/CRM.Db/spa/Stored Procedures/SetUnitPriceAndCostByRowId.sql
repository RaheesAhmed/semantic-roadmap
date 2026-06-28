CREATE PROCEDURE [spa].[SetUnitPriceAndCostByRowId]
(
	@pMainCompNo INT ,
	@pRowID BIGINT,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
)
AS
    BEGIN

		--Select COUNT(*) As wRecordCount from [eTicketPricing]
        
		SET NOCOUNT ON;		
	    DECLARE
            @sBeginTranCount INT = 0 ,
            @sDocHandle INT;
		      
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
	    
        
		DECLARE @wRouteId BIGINT,
				@wVehicleType VARCHAR(20),
				@wTicketType VARCHAR(10),
				@wClassCd VARCHAR(30),
				@wIsSpecialPeriod CHAR(1),
				@wAmount NUMERIC(18,4),
				@wCost NUMERIC(18,4),
				@wStartDate DATE,
				@wEndDate DATE,
				@wStatus CHAR(1),
				@ROWID BIGINT = @pRowID

        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
	        
			
			SELECT @wRouteId = wRouteId, @wVehicleType = wVehicleType, @wTicketType = wTicketType,
					@wClassCd = wClassCd,@wIsSpecialPeriod = wIsSpecialPeriod,@wAmount = wAmount,
					@wCost = wCost, @wStartDate = wStartDate, @wEndDate = wEndDate,@wStatus = wStatus
			FROM eTicketPricing WHERE RowID = @pRowID

			IF(@wStatus = NULL OR @wStatus = '\0')
			BEGIN
				RETURN;
			END

			IF (@wVehicleType = 'FERRY')
			BEGIN
				
				Update dbo.eBookingFerry 
				SET wUnitAmt = @wAmount
				WHERE (CAST(wDepartDt AS DATE) BETWEEN @wStartDate AND @wEndDate ) 
				AND wRouteRid = @wRouteId 
				AND wTicketType = @wTicketType
				AND wClassCd = @wClassCd
				And wBookingStatus = 'P'

				Update dbo.eBookingFerry 
				SET wTotalAmt = wUnitAmt * wQuantity
				WHERE (CAST(wDepartDt AS DATE) BETWEEN @wStartDate AND @wEndDate ) 
				AND wRouteRid = @wRouteId 
				AND wTicketType = @wTicketType
				AND wClassCd = @wClassCd
				And wBookingStatus = 'P'


				IF (@wTicketType = 'ST')  ----Type 1
				BEGIN
					
					DECLARE @RowID1 BIGINT,@wBookingRid1 BIGINT, @wClassCd1 VARCHAR(30), @wTicketType1 VARCHAR(30), 
					@wPaymentMethod1 VARCHAR(30), @wRouteRid1 BIGINT, @wDepartDt1 DATETIME2(7), @wCurrCode1 VARCHAR(6), @wExpAmt1 NUMERIC(18,4),
					@wQuantity1 INT, @wTotalAmt1 NUMERIC(18,4), @wCost1 NUMERIC(18,4), @wUnitAmt1 NUMERIC(18,4), @wStatus1 VARCHAR(30)

					---- Declare Cursor for Update Costs
					DECLARE cur_update_ferryType1 CURSOR
					STATIC FOR 
					Select RowID,wBookingRid,wClassCd,wTicketType,wPaymentMethod,wRouteRid,wDepartDt,wCurrCode,wExpAmt,wQuantity,wTotalAmt,wCost,wUnitAmt,wBookingStatus 
							FROM eBookingFerry 
							WHERE (CAST(wDepartDt AS DATE) BETWEEN @wStartDate AND @wEndDate ) 
									AND wRouteRid = @wRouteId 
									AND wTicketType = @wTicketType
									AND wClassCd = @wClassCd
									And wBookingStatus = 'P'
					OPEN cur_update_ferryType1
						IF @@CURSOR_ROWS > 0
							BEGIN 
							FETCH NEXT FROM cur_update_ferryType1 INTO  @RowID1,@wBookingRid1,@wClassCd1,@wTicketType1,@wPaymentMethod1,@wRouteRid1,@wDepartDt1,@wCurrCode1,@wExpAmt1,@wQuantity1,@wTotalAmt1,@wCost1,@wUnitAmt1,@wStatus1
								WHILE @@Fetch_status = 0
								BEGIN

								DECLARE @tax NUMERIC(18,4) = 0, @rate NUMERIC(18,4)

								SELECT TOP 1 @tax = wTax, @rate = wRate
								FROM eUpdateFerryAndHeliCost
								WHERE 
								((CAST(wStartDate AS DATE) <= CAST(@wDepartDt1 AS DATE)) AND (CAST(wEndDate AS DATE) >= CAST(@wDepartDt1 AS DATE) ))
								AND wRouteID = @wRouteRid1 
								AND wTicketType = @wTicketType1
								AND wClassCd = @wClassCd1
								And wStatus = 'A'
								Order by wUpdDt DESC


								DECLARE @cost as decimal(18, 4) = 0;
								IF ((@wUnitAmt1 + @tax) * @rate) > 0
								BEGIN
									--SET @cost = (((@wUnitAmt1 + @tax) * @rate)/100) * @wQuantity1
									SET @cost = (((@wUnitAmt1 - @tax) * (@rate)/100)+@tax) * @wQuantity1
								END

								Update eBookingFerry
									SET wCost = @cost
								WHERE ROWID = @RowID1


								FETCH NEXT FROM cur_update_ferryType1 INTO  @RowID1,@wBookingRid1,@wClassCd1,@wTicketType1,@wPaymentMethod1,@wRouteRid1,@wDepartDt1,@wCurrCode1,@wExpAmt1,@wQuantity1,@wTotalAmt1,@wCost1,@wUnitAmt1,@wStatus1
								END
							END
						CLOSE cur_update_ferryType1
						DEALLOCATE cur_update_ferryType1
					

				END
			END
			ELSE IF (@wVehicleType = 'HELI')
			BEGIN
				Update dbo.eBookingHeli 
				SET wUnitAmt = @wAmount
				WHERE (CAST(wDepartDt AS DATE) BETWEEN @wStartDate AND @wEndDate ) 
				AND wRouteRid = @wRouteId 
				And wStatus = 'P'

				Update dbo.eBookingHeli
				SET wTotalAmt = wUnitAmt * wQuantity
				WHERE (CAST(wDepartDt AS DATE) BETWEEN @wStartDate AND @wEndDate ) 
				AND wRouteRid = @wRouteId 
				And wStatus = 'P'

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
	
        EXEC sp_xml_removedocument @sDocHandle;

    END;