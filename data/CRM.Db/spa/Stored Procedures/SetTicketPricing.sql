
CREATE PROCEDURE [spa].[SetTicketPricing]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
	  @pReturnResultSet CHAR(1) = 'N',
	  @pRowID BIGINT = 0 OUTPUT,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT	  
	)
AS
    BEGIN

		--SELECT * FROM [eTicketPricing]
        
		SET NOCOUNT ON;		
	    DECLARE @sThisTableName VARCHAR(50) = 'eTicketPricing' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
			
	        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
		DECLARE @sErrorMsg VARCHAR(MAX)='';
	        
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
	    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetTicketPricing
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				RowID BIGINT ,
				wRouteId BIGINT,
				wClassCd  VARCHAR(30) ,
				wIsSpecialPeriod  CHAR(1),
				wCurrCode VARCHAR(6),
				wAmount NUMERIC(18,4),
				wCost NUMERIC(18,4),
				wVehicleType VARCHAR(5),
				wTicketType VARCHAR(10),
				wHandlingFee NUMERIC(18,4),				
				wStartDate DATE,
				wEndDate DATE,
				wStatus CHAR(1),
				wUpdBy BIGINT ,
				wUpdDt DATETIME2(7),
				wCharteredAmount NUMERIC(18,4),
				wCharteredCost NUMERIC(18,4),
				wCharteredHandlingFee NUMERIC(18,4)
			);

		 --better don't put everything within try, for example
	     --getting mSysTable value
	     --getting currency, period, mCompany ...
	    
        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
	
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
	        
			IF @pActionType IN('U')
				BEGIN
					SELECT @sErrorMsg=CASE WHEN s.wRouteId <> met.wRouteId THEN 'Route cannot be changed for terminated objects.'										  
										   WHEN s.wCurrCode <> met.wCurrCode THEN 'Currency code cannot be changed for terminated objects.'
										   WHEN s.wAmount <> met.wAmount THEN 'Amount cannot be changed for terminated objects.'
										   WHEN s.wCost <> met.wCost THEN 'Cost cannot be changed for terminated objects.'
										   WHEN s.wHandlingFee <> met.wHandlingFee THEN 'Handling fees cannot be changed for terminated objects.'
										   WHEN s.wCharteredAmount <> met.wCharteredAmount THEN 'Chartered amount cannot be changed for terminated objects.'
										   WHEN s.wCharteredCost <> met.wCharteredCost THEN 'Chartered cost cannot be changed for terminated objects.'
										   WHEN s.wCharteredHandlingFee <> met.wCharteredHandlingFee THEN 'Chartered handling fees cannot be changed for terminated objects.'
									  END								
					FROM #sDataSet_SetTicketPricing s INNER JOIN dbo.eTicketPricing AS met on s.RowId=met.RowID WHERE met.wStatus='T'
				END

			IF @pActionType IN('I','U') and @sErrorMsg=''
				BEGIN
					SELECT @sErrorMsg=CASE WHEN s.wRouteId <= 0 THEN 'Route is missing.'
										   WHEN ISNULL(s.wStatus,'')='' THEN 'Status is missing.'
									  END								
					FROM #sDataSet_SetTicketPricing s 
				END			

			IF @sErrorMsg <>''
					THROW 50001,@sErrorMsg,5;
	        
			IF @pActionType <> 'D'
			BEGIN
				DECLARE @RecordExist AS INT;
				DECLARE @StartDate AS DATE;
				DECLARE @EndDate AS DATE;
				DECLARE @CurrStartDate AS DATETIME;
				DECLARE @CurrEndDate AS DATETIME;


				SELECT @RecordExist = count(*), @StartDate = tp.wStartDate, @EndDate = tp.wEndDate, 
				@CurrStartDate = dataSetTP.wStartDate, @CurrEndDate = dataSetTP.wEndDate
				FROM [eTicketPricing] As tp INNER JOIN #sDataSet_SetTicketPricing dataSetTP 
				ON ((dataSetTP.wStartDate >= tp.wStartDate AND dataSetTP.wStartDate <= tp.wEndDate) 
				OR (dataSetTP.wEndDate >= tp.wStartDate AND dataSetTP.wEndDate <= tp.wEndDate) )
				AND tp.wRouteID = dataSetTP.wRouteID AND tp.ROWID != dataSetTP.RowID 
				AND tp.wVehicleType = dataSetTP.wVehicleType 
				AND (dataSetTP.wVehicleType = 'HELI' OR (tp.wTicketType = dataSetTP.wTicketType AND tp.wClassCd = dataSetTP.wClassCd))
				WHERE tp.wStatus = 'A' AND tp.RowID != dataSetTP.RowID AND tp.wIsSpecialPeriod = 'Y' AND dataSetTP.wIsSpecialPeriod = 'Y' 
				--AND dataSetTP.wIsCharteredFlight = tp.wIsCharteredFlight
				GROUP BY tp.wStartDate, tp.wEndDate, dataSetTP.wStartDate, dataSetTP.wEndDate

				IF(@RecordExist > 0)
				BEGIN
					DECLARE @message AS VARCHAR(150);
					SET @message = 'Special Period: ' + CONVERT(VARCHAR(10), @CurrStartDate, 1) + '-' + 
					CONVERT(VARCHAR(10), @CurrEndDate, 1) + ' and Special period: ' + CONVERT(VARCHAR(10), @StartDate, 1) + '-' + CONVERT(VARCHAR(10), @EndDate, 1) + ' cannot be existed at the same time.';
					THROW 50001, @message,1;
				END
			END

			IF @pActionType = 'I'
			BEGIN
			UPDATE ETP
			SET 				
				ETP.wStatus ='T'
			FROM dbo.eTicketPricing AS ETP
			INNER JOIN #sDataSet_SetTicketPricing TMP ON
			ETP.wRouteId= TMP.wRouteId AND ETP.wClassCd=TMP.wClassCd
			AND ETP.wTicketType=TMP.wTicketType AND ETP.wIsSpecialPeriod='N' AND TMP.wIsSpecialPeriod='N' AND TMP.wVehicleType='FERRY' AND ETP.wStartDate >= TMP.wStartDate ;

			UPDATE ETP
			SET 				
				ETP.wStatus ='T'
			FROM dbo.eTicketPricing AS ETP
			INNER JOIN #sDataSet_SetTicketPricing TMP ON
			ETP.wRouteId= TMP.wRouteId AND ETP.wIsSpecialPeriod='N' AND TMP.wIsSpecialPeriod='N' AND TMP.wVehicleType='HELI' AND ETP.wStartDate >= TMP.wStartDate ;
			END;


            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetTicketPricing
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetTicketPricing;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
           EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
          @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetTicketPricing
                   SET     RowID = @sRowID
							WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
						END;
				SET @pRowID = @sRowID;

				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[eTicketPricing]
                            (
								[RowID],
							    [wRouteId],
								[wClassCd],
								[wIsSpecialPeriod],
								[wCurrCode],
								[wAmount],
								[wCost],
								[wVehicleType],
								[wTicketType],
								[wHandlingFee],
								[wStartDate],
								[wEndDate],
								[wStatus],								
							    [wCrtBy],
								[wCrtDt],
								[wUpdBy],							    
								[wUpdDt],
								[wCharteredAmount]
							    ,[wCharteredCost]
								,[wCharteredHandlingFee]
							)
                            SELECT
	            	                s.RowID ,
									s.wRouteId ,
									s.wClassCd ,
									s.wIsSpecialPeriod ,
									s.wCurrCode ,
									s.wAmount,
									ISNULL(s.wCost,0),
									s.wVehicleType,
									s.wTicketType,
									s.wHandlingFee,
									s.wStartDate,
									s.wEndDate,
									s.wStatus,
									s.wUpdBy ,
									dbo.fnUTC8Now(),
									s.wUpdBy ,
									dbo.fnUTC8Now()
									,s.wCharteredAmount
									,s.wCharteredCost
									,s.wCharteredHandlingFee
                            FROM    #sDataSet_SetTicketPricing s;

						COMMIT;
                END;
            ELSE IF @pActionType = 'U'
                    BEGIN
                        UPDATE  met
                        SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
								met.wRouteId = tmp.wRouteId ,
								met.wClassCd = tmp.wClassCd ,
								met.wIsSpecialPeriod= tmp.wIsSpecialPeriod ,
								met.wCurrCode= tmp.wCurrCode ,
								met.wAmount = tmp.wAmount,								
								met.wCost = ISNULL(tmp.wCost,0),
								met.wVehicleType = tmp.wVehicleType,
								met.wTicketType = tmp.wTicketType,
								met.wHandlingFee = tmp.wHandlingFee,
								met.wStartDate = tmp.wStartDate,
								met.wEndDate = tmp.wEndDate,								
								met.wStatus = tmp.wStatus,
                                met.wUpdBy = tmp.wUpdBy ,
                                met.wUpdDt = dbo.fnUTC8Now()
								,met.wCharteredAmount = tmp.wCharteredAmount
								,met.wCharteredCost = tmp.wCharteredCost
								,met.wCharteredHandlingFee = tmp.wCharteredHandlingFee 
                        FROM    dbo.eTicketPricing AS met
                                INNER JOIN #sDataSet_SetTicketPricing tmp ON met.RowID = tmp.RowID
                        WHERE   met.RowID = tmp.RowID;
                    END;
            ELSE  if @pActionType='D'
					BEGIN
				UPDATE dbo.[eTicketPricing] 
					SET wStatus='T',
					    wUpdDt = dbo.fnUTC8Now()
				WHERE RowID IN (SELECT RowID FROM #sDataSet_SetTicketPricing)
                        END;

					DECLARE @vTax NUMERIC(18,4)
					DECLARE @vRate NUMERIC(18,4)				
					DECLARE @vCost NUMERIC(18,4)
					DECLARE @vPrice NUMERIC(18,4)
					DECLARE @vTicType VARCHAR(10)
					DECLARE @vStartDate DATE
					DECLARE @vEndDate DATE
					DECLARE @vRouteId BIGINT
					DECLARE @vFerryClass VARCHAR(6)
					DECLARE @vVehicleType VARCHAR(5)
					DECLARE @vStatus CHAR(1)										
					DECLARE @vUpdateBy BIGINT=0;

					SELECT TOP 1 @vUpdateBy=wUpdBy FROM #sDataSet_SetTicketPricing;

					DECLARE cur_update CURSOR
					STATIC FOR 
						SELECT wTicketType,wStartDate,wEndDate,wRouteId,wClassCd,wVehicleType,wStatus,wAmount FROM #sDataSet_SetTicketPricing
						OPEN cur_update
						IF @@CURSOR_ROWS > 0
						BEGIN 
							FETCH NEXT FROM cur_update INTO @vTicType,@vStartDate,@vEndDate,@vRouteId,@vFerryClass,@vVehicleType,@vstatus,@vPrice

							WHILE @@Fetch_status = 0
							BEGIN
								IF @vVehicleType = 'FERRY' AND @vstatus <> 'T'
									BEGIN
										IF @pActionType <> 'D'
										BEGIN

											--SELECT TOP 1 @vTax = wTax, @vRate = wRate from eUpdateFerryAndHeliCost 
											--					Where wRouteID = @vRouteId AND wVehicleType = @vVehicleType AND
											--						  wTicketType = @vTicType AND  wClassCd = @vFerryClass AND
											--						  @vStartDate >= wStartDate  AND wEndDate <= @vEndDate Order By wUpdDt Desc
																	  											
											
											--UPDATE FER
											--SET FER.wUnitAmt = @vPrice,
											--	FER.wTotalAmt = FER.wQuantity * @vPrice,
											--	FER.wCost =  CASE WHEN @vTicType ='ST' THEN ISNULL((((FER.wUnitAmt - @vTax) * (@vRate/100))+@vTax) * FER.wQuantity,0) ELSE FER.wCost END,
											--	FER.wExpAmt = CASE WHEN FER.wPaymentMethod='DA' OR FER.wPaymentMethod='GC' THEN (FER.wQuantity * @vPrice) ELSE 0 END,
											--	FER.wUpdBy=@vUpdateBy,
											--	FER.wUpdDt = dbo.fnUTC8Now()
											--FROM dbo.eBookingFerry FER
											--where FER.wRouteRid = @vRouteId 
											--  AND ((CAST(FER.wDepartDt AS DATE) BETWEEN @vStartDate AND @vEndDate) OR FER.wDepartDt IS NULL)
											--  AND FER.wTicketType = @vTicType 
											--  AND FER.wClassCd = @vFerryClass 
											--  And FER.wStatus = 'P';
											SELECT TOP 1 @vTax = wTax, @vRate = wRate FROM eUpdateFerryAndHeliCost 
																WHERE wRouteID = @vRouteId AND wVehicleType = @vVehicleType AND
																	  wTicketType = @vTicType AND  wClassCd = @vFerryClass AND
																	  @vStartDate >= wStartDate  AND wEndDate <= @vEndDate ORDER BY wUpdDt DESC

											SET @vRate=@vRate/100;

											--DECLARE @vCal   NUMERIC(18,4)
											--SET @vCal = (((@vPrice - @vTax) * (@vRate)) +@vTax)

											--print @vCal

											UPDATE FER
											SET 
												FER.wUnitAmt = @vPrice,												
												FER.wTotalAmt = FER.wQuantity * @vPrice,
												FER.wCost =  CASE WHEN @vTicType ='ST' THEN ISNULL((((@vPrice - @vTax) * (@vRate)) +@vTax) * FER.wQuantity,0) ELSE FER.wCost END,
												--FER.wCost =  CASE WHEN @vTicType ='ST' THEN ISNULL( @vCal * FER.wQuantity,0) ELSE FER.wCost END,
												--FER.wCost =  CASE WHEN @vTicType ='ST' THEN ISNULL((@pCost * FER.wQuantity),0) ELSE FER.wCost END,
												FER.wExpAmt = ISNULL(CASE WHEN FER.wPaymentMethod='DA' OR FER.wPaymentMethod='GC' THEN (FER.wQuantity * @vPrice) ELSE 0 END,0),
												FER.wUpdBy=@vUpdateBy,
												FER.wUpdDt = dbo.fnUTC8Now()
											FROM dbo.eBookingFerry FER
											WHERE FER.wRouteRid = @vRouteId 
											  AND ((CAST(FER.wDepartDt AS DATE) BETWEEN @vStartDate AND @vEndDate) OR FER.wDepartDt IS NULL)
											  AND FER.wTicketType = @vTicType 
											  AND FER.wClassCd = @vFerryClass 
											  And FER.wBookingStatus = 'P';

										--Select
										--	FER.wUnitAmt,
										--		FER.wTotalAmt,
										--		FER.wCost,
										--		FER.wExpAmt,
										--		FER.wUpdBy,
										--		FER.wUpdDt
										--	 FROM dbo.eBookingFerry FER
										--	where FER.wRouteRid = @vRouteId 
										--	  AND ((CAST(FER.wDepartDt AS DATE) BETWEEN @vStartDate AND @vEndDate) OR FER.wDepartDt IS NULL)
										--	  AND FER.wTicketType = @vTicType 
										--	  AND FER.wClassCd = @vFerryClass 
										--	  And FER.wStatus = 'P';
										END
									END
								ELSE IF @vVehicleType = 'HELI' AND @vstatus <> 'T'
									BEGIN
										IF @pActionType <> 'D'
										BEGIN

											SET @vCost = (SELECT TOP 1 wSellingAmt FROM eUpdateFerryAndHeliCost 
																WHERE wRouteID = @vRouteId AND wVehicleType = @vVehicleType AND
																	  @startDate >= wStartDate  AND @endDate <= wEndDate ORDER BY wEndDate DESC)
											
											Update dbo.eBookingHeli 
												   SET wUnitAmt = @vPrice,
													   wTotalAmt = wQuantity * @vPrice,
													   wExpAmt = CASE WHEN wPaymentMethod='DA' OR wPaymentMethod='GC' THEN (wQuantity * @vPrice) ELSE 0 END,
													   wCost = ISNULL(@vCost,0),
													   wUpdBy = @vUpdateBy,
													   wUpdDt = dbo.fnUTC8Now()
											WHERE wRouteRid = @vRouteId AND (CAST(wDepartDt AS DATE) BETWEEN @vStartDate AND @vEndDate)  AND wBookingStatus = 'P'
										END
									END								
								FETCH NEXT FROM cur_update INTO @vTicType,@vStartDate,@vEndDate,@vRouteId,@vFerryClass,@vVehicleType,@vstatus,@vPrice
							END
						END
					CLOSE cur_update
					DEALLOCATE cur_update

	
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
    IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetTicketPricing;
            
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

		IF OBJECT_ID('tempdb..#sDataSet_SetTicketPricing') IS NOT NULL
			DROP TABLE #sDataSet_SetTicketPricing

    END;