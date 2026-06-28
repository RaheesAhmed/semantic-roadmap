CREATE PROCEDURE [spa].[SetHotelDailyCheckInRecord]
    (
      @pXML XML,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64),
	  @pReturnResultSet CHAR(1) = 'N',
      @pErrCode INT = 0 OUTPUT,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
	)
AS
BEGIN
	SET NOCOUNT ON;			
	
	-- SELECT *,''AS wBookingStatus FROM eHotelCheckIn;

			DECLARE @sThisTableName VARCHAR(50) = 'eHotelCheckIn' , -- For RowID
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
	    	    
			SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
					*
			INTO    #sDataSet_SeteHotelCheckIn
			FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
			WITH (
					RowID BIGINT,
					wPrice NUMERIC(18, 4),
					wCost NUMERIC(18, 4),
                    wBreakfastPrice NUMERIC(18, 4),
                    wExtraBedPrice NUMERIC(18, 4),
					wUpdBy BIGINT,
					wIncludeBreakfast CHAR(1),
                    wBookingStatus VARCHAR(5)
				);

					BEGIN TRY                   
	
					IF @sBeginTranCount = 0
						BEGIN
							BEGIN TRAN;
						END;
	                
                     --要加個checking，如房間預訂的狀態已經變了，每日入住這裡就不給改,要退出后重新进入
                    IF EXISTS(SELECT 1 FROM eBookingRoom ebr
                                              INNER JOIN eHotelCheckIn hc ON hc.wRoomBookingRid = ebr.RowID
                                              INNER JOIN #sDataSet_SeteHotelCheckIn tmp ON hc.RowID = tmp.RowID AND ebr.wBookingStatus != tmp.wBookingStatus )
                    BEGIN
                       SET @pErrMsg=dbo.fnGetErrorMsg('1001','zh-TW');
                       THROW 70002, @pErrMsg, 1;
                    END

						IF @pActionType = 'U'
							BEGIN

								Update ebr
								SET ebr.wTotalCost = ((ebr.wTotalCost-hc.wCost - hc.wBreakfastPrice - hc.wExtraBedPrice)+tmp.wCost + tmp.wBreakfastPrice + tmp.wExtraBedPrice) 
								FROM eBookingRoom ebr
								INNER JOIN eHotelCheckIn hc ON hc.wRoomBookingRid = ebr.RowID 
								INNER JOIN #sDataSet_SeteHotelCheckIn tmp ON hc.RowID = tmp.RowID

                                IF EXISTS (SELECT 1 FROM #sDataSet_SeteHotelCheckIn WHERE wBookingStatus='P')--只有p状态才可以更改价格
                                BEGIN
                                  Update ebr
								  SET ebr.wTotalAmount = ((ebr.wTotalAmount-hc.wPrice- hc.wBreakfastPrice - hc.wExtraBedPrice)+tmp.wPrice+ tmp.wBreakfastPrice + tmp.wExtraBedPrice)									
								  FROM eBookingRoom ebr
								  INNER JOIN eHotelCheckIn hc ON hc.wRoomBookingRid = ebr.RowID 
								  INNER JOIN #sDataSet_SeteHotelCheckIn tmp ON hc.RowID = tmp.RowID
                                END;

								UPDATE  met
								SET   
										met.wPrice =tmp.wPrice,
										met.wCost=tmp.wCost,
                                        met.wBreakfastPrice = tmp.wBreakfastPrice,
                                        met.wExtraBedPrice = tmp.wExtraBedPrice,
										met.wUpdDt= dbo.fnUTC8Now(),
										met.wUpdBy=tmp.wUpdBy
										--,met.wIncludeBreakfast=tmp.wIncludeBreakfast				Need Confirmation 
															
								FROM    dbo.eHotelCheckIn AS met
										INNER JOIN #sDataSet_SeteHotelCheckIn tmp ON met.RowID = tmp.RowID
								WHERE   met.RowID = tmp.RowID;
							END;
	
						IF @sBeginTranCount = 0 AND @@trancount > 0
						BEGIN
							COMMIT;
						END;

							-- Return RowID affected
					IF @pReturnResultSet = 'Y'
						SELECT  RowID
						FROM    #sDataSet_SeteHotelCheckIn;

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
							SET @pErrMsg = CONCAT(@sCatchErrorMessage, CHAR(10), '(', @sErrorNum, ') ');
			
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

			IF OBJECT_ID('tempdb..#sDataSet_SeteHotelCheckIn') IS NOT NULL DROP TABLE #sDataSet_SeteHotelCheckIn;
		
END;