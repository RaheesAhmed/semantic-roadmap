CREATE PROCEDURE [spa].[SetHotelRequestDtl]
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

		
	
			DECLARE @sThisTableName VARCHAR(50) = 'eHotelRequest' , -- For RowID
					@sBeginTranCount INT = 0 ,
					@sRecCount INT = 0,
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
			INTO    #sDataSet_SetHotelRequestDtl
			FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
			WITH (
					RowID BIGINT,
					wTotalProvideRoomQty BIGINT,
					wCounterRid BIGINT,
					wTotalAssignedQuantity INT 
				);

	    
			BEGIN TRY
					-- Try to make the transaction scope as small as possible to reduce locking
	
					IF @sBeginTranCount = 0
					BEGIN
						BEGIN TRAN;
					END;
	        
           
					IF @pActionType = 'U'
							BEGIN
									UPDATE  met
									SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
											met.wTotalProvideRoomQty = tmp.wTotalProvideRoomQty
																	
															
									FROM    dbo.eHotelRequestDtl AS met
											INNER JOIN #sDataSet_SetHotelRequestDtl tmp ON met.RowID = tmp.RowID
									WHERE   met.RowID = tmp.RowID;

									DECLARE @RequestRId BIGINT, @Quantity BIGINT 
									SELECT TOP 1 @RequestRId = hrd.wHotelRequestRID,@Quantity = ISNULL(tmp.wTotalAssignedQuantity,0) FROM #sDataSet_SetHotelRequestDtl tmp 
									INNER JOIN eHotelRequestDtl hrd ON tmp.RowID = hrd.RowID
									
									Update bh
									SET bh.wRoomNotArrange = ISNULL((SELECT hr.wNumberOfRoom - TotalRoomsAssigned
																FROM  eHotelRequest hr 
																INNER JOIN (SELECT SUM(wTotalProvideRoomQty) AS TotalRoomsAssigned,wHotelRequestRid FROM eHotelRequestDtl GROUP BY wHotelRequestRid) 
																hrd ON hr.RowID = hrd.wHotelRequestRid
																WHERE hrd.wHotelRequestRId = @RequestRId),0),
										bh.wQuantity = @Quantity
									FROM eBookingHotel bh
									INNER JOIN eHotelRequest hr ON hr.RowID = bh.wRequestRid
									INNER JOIN #sDataSet_SetHotelRequestDtl tmp ON tmp.wCounterRid = bh.wCounterRid
									WHERE hr.RowID = @RequestRId


							END;
							
							IF @sBeginTranCount = 0 AND @@trancount > 0
							BEGIN
								COMMIT;
							END;

						    -- Return RowID affected
							IF @pReturnResultSet = 'Y'
								SELECT  RowID
								FROM    #sDataSet_SetHotelRequestDtl;

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
							EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName,@pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
			END CATCH;
	
			EXEC sp_xml_removedocument @sDocHandle;	

			IF OBJECT_ID('tempdb..#sDataSet_SetHotelRequestDtl') IS NOT NULL
			DROP TABLE #sDataSet_SetHotelRequestDtl
		
    END;