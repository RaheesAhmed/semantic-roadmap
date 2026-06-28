CREATE PROCEDURE [spa].[SetHotelRequest]
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

		--SELECT [RowID]
		--,[wStartDate]
		--,[wEndDate]
		--,[wDayOfStay]
		--,[wNumberOfRoom]
		--,[wIsAgentHotel]
		--,[wBedType]
		--,[wRemark]
		--,[wUpdDt]
		--,[wUpdBy]
		--,[wUnqualifiedRid]
		--,[wCancelReasonCd]
		--,[wOtherReason]
		--,[wCancelDt]
		--,[wCancelBy]
		--,[wStatus]
		--FROM [dbo].[eHotelRequest]


			DECLARE @sThisTableName VARCHAR(50) = 'eHotelRequest' , -- For RowID
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
			INTO    #sDataSet_SetHotelRequest
			FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
			WITH (

					RowID BIGINT 
					,wStartDate DATE
					,wEndDate DATE
					,wDayOfStay INT
					,wNumberOfRoom INT
					,wIsAgentHotel CHAR(1)
					,wBedType VARCHAR(2)
					,wRemark NVARCHAR(500)
					,wUpdDt DATETIME2(7)
					,wUpdBy BIGINT
					,wUnqualifiedRid BIGINT
					,wCancelReasonCd VARCHAR(30)
					,wOtherReason NVARCHAR(200)
					,wCancelDt DATETIME2(7)
					,wCancelBy BIGINT
					,wStatus VARCHAR(3)
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
	        
           
						IF @pActionType = 'U'
							BEGIN
								UPDATE  met
								SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
                        
									met.wStartDate = tmp.wStartDate 
									,met.wEndDate = tmp.wEndDate
									,met.wDayOfStay= tmp.wDayOfStay
									,met.wNumberOfRoom= tmp.wNumberOfRoom
									,met.wIsAgentHotel= tmp.wIsAgentHotel
									,met.wBedType= tmp.wBedType
									,met.wRemark= tmp.wRemark
									,met.wUpdBy = tmp.wUpdBy
									,met.wUpdDt = tmp.wUpdDt
									,met.wUnqualifiedRid = tmp.wUnqualifiedRid
									,met.wCancelReasonCd = tmp.wCancelReasonCd
									,met.wOtherReason = tmp.wOtherReason
									,met.wCancelDt = tmp.wCancelDt
									,met.wCancelBy = tmp.wCancelBy
									,met.wStatus = tmp.wStatus					 
								FROM    dbo.eHotelRequest AS met
										INNER JOIN #sDataSet_SetHotelRequest tmp ON met.RowID = tmp.RowID
								WHERE   met.RowID = tmp.RowID;
							END;
							
						IF @sBeginTranCount = 0 AND @@trancount > 0
						BEGIN
							COMMIT;
						END;

						-- Return RowID affected
						IF @pReturnResultSet = 'Y'
							SELECT  RowID
							FROM    #sDataSet_SetHotelRequest;
							
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

			IF OBJECT_ID('tempdb..#sDataSet_SetHotelRequest') IS NOT NULL DROP TABLE #sDataSet_SetHotelRequest;
		
    END;