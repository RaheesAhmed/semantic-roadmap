CREATE PROCEDURE [spa].[SetActivityLog]
(
	@pXML XML,
	@pActionType CHAR(1), 
	@pMainCompNo INT,
	@pNonceToken VARCHAR(64),	
	@pReturnResultSet CHAR(1) = 'N',
	@pErrCode INT = 0 OUTPUT,
	@pErrMsg NVARCHAR(200) = '' OUTPUT   
)
/* Test call
-- Insert New
DECLARE @pErrCode INT ,
	@pErrMsg NVARCHAR(200);
EXEC spa.SetActivityLog @pXML = N'
	<DataSet><Record RowID="0" wAction="I" wReqAgentCodeIn="1000018899" wBookingRid="10000000010077" wCategory="eBookingFerry" wRemark="2017-11-02, 經濟位, KLT&gt;ZST" wIsLatest="Y" wIsComplete="N" wCrtDt="2017-05-25T15:42:55.883" wCrtBy="100000010010" wUpdDt="2017-05-25T15:42:55.883" wUpdBy="100000010010"/></DataSet>', -- xml
	@pActionType = 'I', -- char(1)
	@pMainCompNo = 10, -- int
	@pNonceToken = '', -- varchar(64)
	@pReturnResultSet = 'N', -- char(1)
	@pErrCode = @pErrCode OUTPUT, -- int
	@pErrMsg = @pErrMsg OUTPUT -- nvarchar(200)
SELECT @pErrCode, @pErrMsg
*/
AS
BEGIN
		-- For DBML
		--SELECT
		--	RowID = CAST(0 AS BIGINT)

		--RETURN;
		--

		SET NOCOUNT ON;
		DECLARE	@sThisTableName VARCHAR(50) = 'eActivityLog',
				@sDocHandle	INT,
				@sRecCount INT = 0,
				@sRuningIndex INT = 1,
				@sRowID BIGINT = 0,
				@vNow DATETIME2 = dbo.fnUTC8Now(),
				@sBeginTranCount INT = 0;
		
		SET @sBeginTranCount = @@trancount;
						
		EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML
		
		SELECT 
			wRowNum = ROW_NUMBER() OVER(ORDER BY wUpdDt), 
			*
		INTO #sDataLog
		FROM OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
			-- PRINT [dbo].[fnGetAllFieldNameInTable]('eActivityLog', '', 'Y', '', '', '')
			RowID BIGINT, wAction VARCHAR(10), wReqAgentCodeIn VARCHAR(14), wBookingRid BIGINT, 
			wCategory VARCHAR(30), wRemark NVARCHAR(500), wIsLatest CHAR(1), wIsComplete CHAR(1), 
			wCrtDt DATETIME2, wCrtBy BIGINT, wUpdDt DATETIME2, wUpdBy BIGINT
		)
			
			BEGIN TRY
			-- Try to make the transaction scope as small as possible to reduce locking
			IF @sBeginTranCount = 0
				BEGIN
					BEGIN TRAN;
				END;
					
			IF @pActionType = 'I' 
			BEGIN
				-- Set RowID by Sequence
					UPDATE  #sDataLog
					SET     RowID = 0;
					SELECT  @sRecCount = COUNT(*)
					FROM    #sDataLog;
					WHILE @sRuningIndex <= @sRecCount
						BEGIN
							EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
								@sRowID OUTPUT;
					
							UPDATE  #sDataLog
							SET     RowID = @sRowID
							WHERE   wRowNum = @sRuningIndex;
							SET @sRuningIndex = @sRuningIndex + 1;
						END;   	

					-- Update wIsLatest for Booking
					UPDATE
						d
					SET
						d.wIsLatest = 'N'
					FROM
						dbo.eActivityLog d
					INNER JOIN
						#sDataLog tmp ON d.wBookingRid = d.wBookingRid
					WHERE
						d.wIsLatest = 'Y'
					AND
						ISNULL(tmp.wBookingRid, -1) != -1

					-- Insert data
					-- PRINT [dbo].[fnGetAllFieldNameInTable]('eActivityLog', '', 'N', '', '', '')
					INSERT INTO 
						dbo.eActivityLog (RowID, wAction, wReqAgentCodeIn, wBookingRid, wCategory, wRemark, wIsLatest, wIsComplete, wCrtDt, wCrtBy, wUpdDt, wUpdBy)
					SELECT 
						RowID, wAction, wReqAgentCodeIn, wBookingRid, wCategory, wRemark, wIsLatest, wIsComplete, @vNow, wCrtBy, @vNow, wUpdBy
					FROM 
						#sDataLog
			END	     
			ELSE IF @pActionType = 'U'
				BEGIN
					UPDATE  d
					SET     -- PRINT [dbo].[fnGetAllFieldNameInTable]('eActivityLog', '', 'N', '', 'Y', 'tmp')                                
						wAction = tmp.wAction, 
						wReqAgentCodeIn = tmp.wReqAgentCodeIn, 
						wBookingRid = tmp.wBookingRid, 
						wCategory = tmp.wCategory, 
						wRemark = tmp.wRemark, 
						wIsLatest = tmp.wIsLatest, 
						wIsComplete = tmp.wIsComplete, 
						wCrtDt = tmp.wCrtDt, 
						wCrtBy = tmp.wCrtBy, 
						wUpdDt = @vNow, 
						wUpdBy = tmp.wUpdBy
					FROM
						dbo.eActivityLog AS d
					INNER JOIN 
						#sDataLog tmp ON d.RowID = tmp.RowID
				END;
			ELSE IF @pActionType = 'D' BEGIN
				;THROW 70002, 'Deleted operation is not allowed', 1;
			END

			IF @sBeginTranCount = 0
				AND @@trancount > 0
				BEGIN
					COMMIT;
				END;

			SELECT @pErrCode = 0, @pErrMsg = 'SUCCESS';

			-- Return RowID affected
			IF @pReturnResultSet = 'Y'
				SELECT  RowID
				FROM    #sDataLog;

		RETURN;
		END TRY

		BEGIN CATCH
			DECLARE @vErrorNum INT ,
				@vCatchErrorMessage NVARCHAR(4000) ,
				@xstate INT ,
				@vProcedureName VARCHAR(100) ,
				@vRtnCodeLog INT ,
				@vErrMessageLog NVARCHAR(4000);
			
			SET  @vErrorNum = ERROR_NUMBER();
			SET  @vCatchErrorMessage = ERROR_MESSAGE();
			SET  @xstate = XACT_STATE();
			SET  @vProcedureName = OBJECT_NAME(@@PROCID);
			
			IF ISNULL(@pErrCode, 0) = 0
				BEGIN
					SET @pErrCode = 999;
				END;
			SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @vErrorNum, ') ',
								  @vCatchErrorMessage);
			
			IF @sBeginTranCount = 0 BEGIN
				IF @xstate != 0
					ROLLBACK;
				EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT, @vErrMessageLog OUTPUT;
			END
			ELSE
				THROW;

		END CATCH;

		EXEC sp_xml_removedocument @sDocHandle	
		
		IF OBJECT_ID('tempdb..#sDataLog') IS NOT NULL DROP TABLE #sDataLog		    	
	END