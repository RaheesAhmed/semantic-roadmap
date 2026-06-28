CREATE PROCEDURE [spa].[SetUpdateFerryHelicopterTicketsCost] 
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
	  @pReturnResultSet CHAR(1) = 'N',
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
	)
AS
    BEGIN
        SET NOCOUNT ON;

		--SELECT *FROM [eUpdateFerryAndHeliCost]

	    DECLARE @sThisTableName VARCHAR(50) = 'eUpdateFerryAndHeliCost' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
			
	        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
	        
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
	    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetUpdateFerryHelicopterTicketsCost
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				RowID BIGINT ,
				wRouteID  BIGINT ,
				wVehicleType VARCHAR(20),
				wStartDate DATE,
				wEndDate DATE,
				wTicketType VARCHAR(10),
				wClassCd VARCHAR(5),
				wSellingAmt NUMERIC(18,4),
				wRate NUMERIC(18,4),
				wTax NUMERIC(18,4),
				wPrice NUMERIC(18,4),
				wRebatePrice NUMERIC(18,4),
				wStatus CHAR(1),
				wCurrCode VARCHAR(6),
				wUpdDt DATETIME2(7),
				wUpdBy BIGINT,
                wCalculateCostWay VARCHAR(5)
			);

		 --better don't put everything within try, for example    
        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;
	        
			--IF @pActionType <> 'D'
			--	BEGIN
			--IF EXISTS(SELECT * FROM eUpdateFerryAndHeliCost As UHFC INNER JOIN #sDataSet_SetUpdateFerryHelicopterTicketsCost TEMPUHFC ON TEMPUHFC.wStartDate BETWEEN UHFC.wStartDate AND UHFC.wEndDate AND UHFC.wRouteID = TEMPUHFC.wRouteID AND TEMPUHFC.wVehicleType= UHFC.wVehicleType AND TEMPUHFC.ROWID != UHFC.RowID WHERE UHFC.wStatus <> 'T')
			--throw 50001, 'Special Period cannot be existed at the same time.', 1;

			--	DECLARE @RecordExist as int;
			--	DECLARE @tmpStartDate as date;
			--	DECLARE @tmpEndDate as date;
			--	DECLARE @CurrStartDate as datetime;
			--	DECLARE @CurrEndDate as datetime;


			--	SELECT @RecordExist = count(*), @tmpStartDate = uc.wStartDate, @tmpEndDate = uc.wEndDate, 
			--	@CurrStartDate = dataSetUC.wStartDate, @CurrEndDate = dataSetUC.wEndDate
			--	FROM eUpdateFerryAndHeliCost As uc 
			--	INNER JOIN #sDataSet_SetUpdateFerryHelicopterTicketsCost dataSetUC
			--	ON ((dataSetUC.wStartDate >= uc.wStartDate AND dataSetUC.wStartDate <= uc.wEndDate) 
			--	OR (dataSetUC.wEndDate >= uc.wStartDate AND dataSetUC.wEndDate <= uc.wEndDate))
			--	AND uc.wRouteID = dataSetUC.wRouteID
			--	AND uc.wVehicleType = dataSetUC.wVehicleType AND uc.wClassCd = dataSetUC.wClassCd AND uc.wTicketType = dataSetUC.wTicketType
			--	 AND uc.ROWID != dataSetUC.RowID
			--	WHERE uc.wStatus <> 'T' AND uc.RowID != dataSetUC.RowID
			--	Group By uc.wStartDate, uc.wEndDate, dataSetUC.wStartDate, dataSetUC.wEndDate

			--	if(@RecordExist > 0)
			--	BEGIN
			--	DECLARE @message as varchar(150);
			--	SET @message = 'Special Period: ' + CONVERT(VARCHAR(8), @CurrStartDate, 1) + '-' + CONVERT(VARCHAR(8), @CurrEndDate, 1) + ' and Special period: ' + CONVERT(VARCHAR(8), @tmpStartDate, 1) + '-' + CONVERT(VARCHAR(8), @tmpEndDate, 1) + ' cannot be existed at the same time.';
			--	throw 50001, @message,1;
			--	END
			--END
			
            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetUpdateFerryHelicopterTicketsCost
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(1)
					FROM	#sDataSet_SetUpdateFerryHelicopterTicketsCost;
                    WHILE @sRuningIndex <= @sRecCount
						BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetUpdateFerryHelicopterTicketsCost
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				 	-- MAIN Logic here, example here is inserting dataset to eUpdateFerryAndHeliCost
                    INSERT  INTO dbo.[eUpdateFerryAndHeliCost]
                            (
								[RowID],
								[wRouteID],
								[wVehicleType],
								[wStartDate],
								[wEndDate],
								[wTicketType],
								[wClassCd],
								[wSellingAmt],
								[wRate],
								[wTax],
								[wPrice],
								[wRebatePrice],
								[wStatus],
								[wCurrCode],
								[wCrtBy],
								[wCrtDt],
								[wUpdBy],						    
								[wUpdDt],
                                wCalculateCostWay
							)
                            SELECT
	            	                s.RowID,
									s.wRouteID ,
									s.wVehicleType ,
									s.wStartDate ,
									s.wEndDate ,
									s.wTicketType,
									s.wClassCd,
									s.wSellingAmt,
									s.wRate,
									s.wTax,
									s.wPrice,
									s.wRebatePrice,
									s.wStatus,
									s.wCurrCode,
									s.wUpdBy ,
									dbo.fnUTC8Now(),
									s.wUpdBy ,
									dbo.fnUTC8Now(),
                                    wCalculateCostWay
                            FROM    #sDataSet_SetUpdateFerryHelicopterTicketsCost s;
                END;
			ELSE IF @pActionType = 'U'
			BEGIN
				UPDATE UFAH
                SET   
						UFAH.wStartDate = tmp.wStartDate,
						UFAH.wEndDate = tmp.wEndDate,
						UFAH.wRouteID = tmp.wRouteID,
						UFAH.wTicketType = tmp.wTicketType,
						UFAH.wClassCd = tmp.wClassCd,
						UFAH.wSellingAmt = tmp.wSellingAmt,
						UFAH.wRate = tmp.wRate,
						UFAH.wTax = tmp.wTax,
						UFAH.wPrice=tmp.wPrice,
						UFAH.wRebatePrice=tmp.wRebatePrice, 
						UFAH.wCurrCode = tmp.wCurrCode,
						UFAH.wStatus = tmp.wStatus,
						UFAH.wUpdBy = tmp.wUpdBy,
                        UFAH.wUpdDt = dbo.fnUTC8Now(),
                        UFAH.wCalculateCostWay = tmp.wCalculateCostWay
                FROM    dbo.eUpdateFerryAndHeliCost AS UFAH
                        INNER JOIN #sDataSet_SetUpdateFerryHelicopterTicketsCost tmp ON UFAH.RowID = tmp.RowID;
			END
			ELSE IF @pActionType = 'D'
			BEGIN
				UPDATE UFAH
                SET   
					UFAH.wStatus = 'T',
					UFAH.wUpdBy = tmp.wUpdBy,
                    UFAH.wUpdDt = dbo.fnUTC8Now()
                FROM dbo.eUpdateFerryAndHeliCost AS UFAH
                     INNER JOIN #sDataSet_SetUpdateFerryHelicopterTicketsCost tmp ON UFAH.RowID = tmp.RowID;
			END;
           
			DECLARE @tax NUMERIC(18,4)
					,@rate NUMERIC(18,4)
					,@Price NUMERIC(18,4)
					,@TicType VARCHAR(10)
					,@startDate DATETIME
					,@endDate DATETIME
					,@routeId BIGINT
					,@FerryClass VARCHAR(5)
					,@VehicleType VARCHAR(30)
					,@Cost NUMERIC(18,4)
					,@status CHAR(1)
                    ,@CalculateCostWay VARCHAR(10);
	
			-- cost will update to all status record --ligy 2017-08-26
			DECLARE cur_update_ferry CURSOR
			STATIC FOR 
				SELECT wTax,wRate,wPrice,wTicketType,wStartDate,wEndDate,wRouteID,wClassCd,wVehicleType,wSellingAmt,wStatus,wCalculateCostWay FROM #sDataSet_SetUpdateFerryHelicopterTicketsCost
				OPEN cur_update_ferry
				IF @@CURSOR_ROWS > 0
				BEGIN 
					FETCH NEXT FROM cur_update_ferry INTO  @tax,@rate,@Price,@TicType,@startDate,@endDate,@routeId,@FerryClass,@VehicleType,@Cost,@status,@CalculateCostWay
					WHILE @@FETCH_STATUS = 0
					BEGIN
						IF @VehicleType = 'FERRY' AND @status <> 'T'
						BEGIN
							IF @CalculateCostWay='FT'
							BEGIN 
								IF @pActionType = 'D'
								BEGIN
									UPDATE dbo.eBookingFerry SET wCost = 0
									WHERE (CAST(wDepartDt AS DATE) BETWEEN @startDate AND @endDate ) AND wRouteRid = @routeId AND wTicketType = @TicType AND wClassCd = @FerryClass
									-- And wBookingStatus = 'P'
								END
								ELSE
								BEGIN
									UPDATE dbo.eBookingFerry 
										SET wCost = (((wUnitAmt - @tax) * @rate/100)+ @tax) * wQuantity
									WHERE (CAST(wDepartDt AS DATE) BETWEEN @startDate AND @endDate ) 
									AND wRouteRid = @routeId 
									AND wTicketType = @TicType 
									AND wClassCd = @FerryClass 
									--And wBookingStatus = 'P'
									AND (((wUnitAmt + @tax) * @rate) != 0);

									UPDATE dbo.eBookingFerry 
									SET wCost = 0
									WHERE (CAST(wDepartDt AS DATE) BETWEEN @startDate AND @endDate ) 
									AND wRouteRid = @routeId 
									AND wTicketType = @TicType 
									AND wClassCd = @FerryClass 
									--And wBookingStatus = 'P'
									AND (((wUnitAmt + @tax) * @rate) = 0);															
								END
							END
							ELSE IF  @CalculateCostWay='ME' 
							BEGIN
								IF @pActionType = 'D'
								BEGIN
									UPDATE dbo.eBookingFerry 
									Set wCost = 0 
									WHERE wClassCd = @FerryClass and (CAST(wDepartDt AS DATE) BETWEEN @startDate AND @endDate ) AND wTicketType = @TicType -- And wBookingStatus = 'P'
								END
								ELSE
								BEGIN
									UPDATE dbo.eBookingFerry 
									Set wCost = ( @Cost * wQuantity )
									WHERE wClassCd = @FerryClass and (CAST(wDepartDt AS DATE) BETWEEN @startDate AND @endDate ) AND wTicketType = @TicType -- And wBookingStatus = 'P'
								END
							END
							ELSE IF  @CalculateCostWay='DP'
							BEGIN
								IF @pActionType = 'D'
								BEGIN
									UPDATE dbo.eBookingFerry 
									SET wCost = 0 
									WHERE (CAST(wDepartDt AS DATE) BETWEEN @startDate AND @endDate ) AND wTicketType = @TicType  AND wUnitAmt=@Price AND wRouteRid = @routeId -- And wBookingStatus = 'P'
								END
								ELSE
								BEGIN
									UPDATE dbo.eBookingFerry 
									SET wCost = @Cost
									WHERE (CAST(wDepartDt AS DATE) BETWEEN @startDate AND @endDate ) AND wTicketType = @TicType AND wUnitAmt=@Price AND wRouteRid = @routeId --  And wBookingStatus = 'P'
								END
							END
						END
						ELSE IF @VehicleType = 'HELI' AND @status <> 'T'
						BEGIN
							IF @pActionType = 'D'
								UPDATE dbo.eBookingHeli SET wCost = 0 WHERE wRouteRid = @routeId AND (CAST(wDepartDt AS DATE) BETWEEN @startDate AND @endDate) -- AND wBookingStatus = 'P'
							ELSE
								UPDATE dbo.eBookingHeli SET wCost = (@Cost * wQuantity) WHERE wRouteRid = @routeId AND (CAST(wDepartDt AS DATE) BETWEEN @startDate AND @endDate) -- AND wBookingStatus = 'P'
						END
					FETCH NEXT FROM cur_update_ferry INTO @tax,@rate,@Price,@TicType,@startDate,@endDate,@routeId,@FerryClass,@VehicleType,@Cost,@status,@CalculateCostWay
				END
			END
			CLOSE cur_update_ferry
			DEALLOCATE cur_update_ferry
			
		    IF @sBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                COMMIT;
            END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetUpdateFerryHelicopterTicketsCost;

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
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH;
	
        EXEC sp_xml_removedocument @sDocHandle;

		IF OBJECT_ID('tempdb..#sDataSet_SetUpdateFerryHelicopterTicketsCost') IS NOT NULL
			DROP TABLE #sDataSet_SetUpdateFerryHelicopterTicketsCost
    END;