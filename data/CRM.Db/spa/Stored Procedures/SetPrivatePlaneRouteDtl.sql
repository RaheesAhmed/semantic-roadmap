CREATE PROCEDURE [spa].[SetPrivatePlaneRouteDtl]
    (
      @pXML XML ,      
	  @pMainCompNo INT ,
	  @pTestMode INT = 0, -- 0: Normal(Non-Test), 1: UnitTest, 2: Scenario Test
	  @pNonceToken VARCHAR(64) ,
	  @pReturnResultSet CHAR(1) = 'N',
	  @pBookingPrivatePlaneRid BIGINT,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) OUTPUT
    )
AS
BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

        -- SELECT *,'Y' AS RecordState FROM dbo.ePrivatePlaneRouteDtl; 

        DECLARE @sThisTableName VARCHAR(50) = 'ePrivatePlaneRouteDtl' ,
            @sBeginTranCount	INT = 0 ,
            @sDocHandle			INT,
            @sRecCount			INT = 0,
	        @sRuningIndex		INT = 1,
			@sRowID				BIGINT = 0,
			@sNow				DATETIME2 = dbo.fnUTC8Now();
        
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ) ,
                *
        INTO    #sDataSet_SetPrivatePlaneRouteDtl FROM  OPENXML (@sDocHandle, 'DataSet/SetPrivatePlaneRouteDtlResult', 1)
		WITH (
         RowID BIGINT, wBookingPrivatePlaneRid BIGINT, wLine INT, wCityCd VARCHAR(10), wIsReturn CHAR(1), 
			wDepartureAirportRid BIGINT, wArrivalAirportRid BIGINT,
		  wTakeOffDt DATETIME2, wArrivalDt DATETIME2, wStatus CHAR(1), wCrtDt DATETIME2, wCrtBy BIGINT, 
		  wUpdDt DATETIME2, wUpdBy BIGINT, RecordState VARCHAR(1), wIsDestination CHAR(1));        

		IF EXISTS (SELECT 1 FROM #sDataSet_SetPrivatePlaneRouteDtl)
		BEGIN
			
			DECLARE @sBookingFlightType VARCHAR(30)='';
			SELECT @sBookingFlightType=wBookingType FROM dbo.eBookingPrivatePlane WHERE RowID=@pBookingPrivatePlaneRid;

			IF (SELECT COUNT(1) FROM #sDataSet_SetPrivatePlaneRouteDtl WHERE wDepartureAirportRid < 0) > 0 THROW 50001, 'Departure airport is required', 1;
			IF (SELECT COUNT(1) FROM #sDataSet_SetPrivatePlaneRouteDtl WHERE wArrivalAirportRid < 0) > 0  THROW 50001, 'Arrival airport is required', 1;
			--IF (SELECT COUNT(1) FROM #sDataSet_SetPrivatePlaneRouteDtl WHERE RTRIM(LTRIM(wCityCd)) IN ('',' ')) > 0 THROW 50001, 'Departure city is required', 1;
			IF (SELECT COUNT(1) FROM #sDataSet_SetPrivatePlaneRouteDtl WHERE wLine=1 AND wIsReturn='Y') >0 THROW 50001, 'First flight details should not be return', 1;

			IF @sBookingFlightType='OneWay'
			BEGIN
				IF (SELECT COUNT(1) FROM #sDataSet_SetPrivatePlaneRouteDtl)>1 THROW 50001, 'For "One Way" booking there should be only one flight details', 1;
				IF (SELECT COUNT(1) FROM #sDataSet_SetPrivatePlaneRouteDtl WHERE wIsReturn='Y')>1 THROW 50001, 'For "One Way" booking there should not be return flight', 1;
			END

			IF @sBookingFlightType='RoundTrip'
			BEGIN
				IF (SELECT COUNT(1) FROM #sDataSet_SetPrivatePlaneRouteDtl)<>2 THROW 50001, 'For "Round Trip" booking there should be only two flight details', 1;
				IF (SELECT COUNT(1) FROM #sDataSet_SetPrivatePlaneRouteDtl WHERE wIsReturn='Y')>1 THROW 50001, 'For "Round Trip" booking there should be only one return flight', 1;
			END

			IF @sBookingFlightType='MultiCity'
			BEGIN
				IF (SELECT COUNT(1) FROM #sDataSet_SetPrivatePlaneRouteDtl)<= 2 THROW 50001, 'For "Multicity Booking" there should be atleast 2 flight details.', 1;				
			END

		END


        BEGIN TRY	                
        IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
        		

            IF EXISTS (SELECT 1 FROM #sDataSet_SetPrivatePlaneRouteDtl WHERE RecordState = 'I' )
            BEGIN
					-- Set RowID by Sequence
					UPDATE #sDataSet_SetPrivatePlaneRouteDtl SET RowID = 0 WHERE RecordState = 'I';
					SELECT @sRecCount = COUNT(*) FROM #sDataSet_SetPrivatePlaneRouteDtl

					WHILE @sRuningIndex <= @sRecCount BEGIN
						 IF EXISTS ( SELECT 1 FROM #sDataSet_SetPrivatePlaneRouteDtl WHERE RecordState = 'I' AND wRowNum = @sRuningIndex)
							BEGIN
								EXEC spq.GetRowId @pMainCompNo, @sThisTableName, @sRowID OUTPUT
								UPDATE #sDataSet_SetPrivatePlaneRouteDtl 
									SET RowID = @sRowID 
								WHERE wRowNum = @sRuningIndex
							END
						SET @sRuningIndex = @sRuningIndex + 1;
					END	

                    INSERT  INTO [dbo].[ePrivatePlaneRouteDtl]
                    (RowID, wBookingPrivatePlaneRid, wLine, wCityCd, wIsReturn, wDepartureAirportRid, wArrivalAirportRid, wTakeOffDt, wArrivalDt, wStatus, wCrtDt, wCrtBy, wUpdDt, wUpdBy, wIsDestination)
                    SELECT RowID, @pBookingPrivatePlaneRid, wLine, ISNULL(wCityCd, ''), wIsReturn, wDepartureAirportRid, wArrivalAirportRid, wTakeOffDt, wArrivalDt, wStatus, @sNow, wCrtBy, @sNow, wUpdBy, wIsDestination 
					FROM #sDataSet_SetPrivatePlaneRouteDtl WHERE RecordState = 'I';
                END;
			
            IF EXISTS ( SELECT 1 FROM #sDataSet_SetPrivatePlaneRouteDtl WHERE RecordState = 'U' )
            BEGIN
                    UPDATE pprd_t 
						SET 
							wLine = tmp.wLine, 
							wCityCd = ISNULL(tmp.wCityCd, ''), 
							wIsReturn = tmp.wIsReturn, 
							wDepartureAirportRid = tmp.wDepartureAirportRid, 
							wArrivalAirportRid = tmp.wArrivalAirportRid,
							wTakeOffDt = tmp.wTakeOffDt, 
							wArrivalDt = tmp.wArrivalDt,
							wStatus = tmp.wStatus, 
							wUpdDt = @sNow, 
							wUpdBy = tmp.wUpdBy,
                            wIsDestination = tmp.wIsDestination
							FROM [dbo].[ePrivatePlaneRouteDtl] pprd_t 
							INNER JOIN #sDataSet_SetPrivatePlaneRouteDtl tmp ON pprd_t.RowID = tmp.RowID					
                    WHERE tmp.RecordState = 'U';
            END;
		
			UPDATE dbo.ePrivatePlaneRouteDtl SET wStatus='T' WHERE wBookingPrivatePlaneRid=@pBookingPrivatePlaneRid AND RowID NOT IN(SELECT RowID FROM #sDataSet_SetPrivatePlaneRouteDtl WHERE RowID>0);

   IF @sBeginTranCount = 0 AND @@trancount > 0
           BEGIN
			IF @pTestMode = 1
				ROLLBACK;
			ELSE
				COMMIT;
            END;

			-- Return RowID List
			IF @pReturnResultSet = 'Y'
			BEGIN
				SELECT RowID FROM #sDataSet_SetPrivatePlaneRouteDtl;
			END;
        END TRY
        BEGIN CATCH
            DECLARE @sErrorNum INT ,
                @sCatchErrorMessage NVARCHAR(4000) ,
                @xstate INT ,
                @sProcedureName VARCHAR(100) ,
                @sRtnCodeLog INT ,
                @sErrMessageLog NVARCHAR(4000);
        
            SET @sErrorNum = ERROR_NUMBER();
            SET @sCatchErrorMessage = ERROR_MESSAGE();
            SET @xstate = XACT_STATE();
            SET @sProcedureName = OBJECT_NAME(@@PROCID);
		
            IF ISNULL(@pErrCode, 0) = 0
                BEGIN
                    SET @pErrCode = 70001;
                END;

            SET @pErrMsg = CONCAT('(', @sErrorNum, ') ', @sCatchErrorMessage);

            IF @sBeginTranCount = 0
                BEGIN
                    IF @xstate != 0
                        ROLLBACK;

                    -- Write Log
					EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName,
						@pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;             			
                              
        END CATCH;

        EXEC sp_xml_removedocument @sDocHandle;
        IF OBJECT_ID('tempdb..#sDataSet_SetPrivatePlaneRouteDtl') IS NOT NULL DROP TABLE #sDataSet_SetPrivatePlaneRouteDtl;
END;