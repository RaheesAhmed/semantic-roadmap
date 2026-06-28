
CREATE PROCEDURE [spa].[SetCounterLog]
    (
      @pXML XML ,      
	  @pActionType CHAR(1), --I/U/D
	  @pMainCompNo INT ,
	  @pNonceToken VARCHAR(64) ,
	  @pReturnResultSet CHAR(1) = 'N',
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) OUTPUT
    )
AS
BEGIN
    SET NOCOUNT ON;

	--SELECT RowID FROM eCounterLog;

    DECLARE @sThisTableName		VARCHAR(50) = 'eCounterLog' ,
			@sBeginTranCount	INT = 0,
			@sRecCount			INT = 0,
			@sRuningIndex		INT = 1,
			@sRowID				BIGINT = 0,
			@sDocHandle			INT;
        
	DECLARE @sReturnRowID TABLE (RowID BIGINT);

    SET @sBeginTranCount = @@trancount;
    SELECT  @pErrCode = 0 ,
            @pErrMsg = '';
    
    EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
    SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ), *
    INTO    #sDataSet_SetCounterLog
    FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
	WITH (
			RowID BIGINT,
			wCompNo INT, 
			wDeptCd VARCHAR(30), 
			wUserRid BIGINT, 
			wType NVARCHAR(50), 
			wRelateAgentCodeIn VARCHAR(14), 
			wRelatePersonRid BIGINT, 
			wTitle NVARCHAR(500), 
			wContent NVARCHAR(4000), 
			wDateTime DATETIME2(7), 
			wIsImportant CHAR(1), 
			wIsProcessed VARCHAR(2),
			wIsClosed VARCHAR(1),
			wStatus CHAR(1), 
			wCrtDt DATETIME2(7), 
			wCrtBy BIGINT, 
			wUpdDt DATETIME2(7), 
			wUpdBy BIGINT,
			wCounterRid BIGINT
		); 
			       
	BEGIN TRY	                
        IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;
        		
        IF @pActionType = 'I'
            BEGIN
				-- Set RowID by Sequence
				UPDATE #sDataSet_SetCounterLog SET RowID = 0;

				SELECT @sRecCount = COUNT(1) FROM #sDataSet_SetCounterLog

				WHILE @sRuningIndex <= @sRecCount 
					BEGIN
						EXEC spq.GetRowId @pMainCompNo, @sThisTableName, @sRowID OUTPUT
						UPDATE #sDataSet_SetCounterLog SET RowID = @sRowID WHERE wRowNum = @sRuningIndex
						SET @sRuningIndex = @sRuningIndex + 1;
					END	

                INSERT INTO [dbo].[eCounterLog]
                ( 
					RowID, 
					wCompNo,
					wDeptCd, 
					wUserRid, 
					wType, 
					wRelateAgentCodeIn, 
					wRelatePersonRid,
					wIsProcessed, 
					wTitle, 
					wContent,
					wDateTime, 
					wIsImportant,
					wCrtDt, 
					wCrtBy, 
					wUpdDt, 
					wUpdBy,
					wCounterRid
				)
                SELECT 
					RowID, 
					wCompNo, 
					wDeptCd, 
					wUserRid, 
					wType, 
					wRelateAgentCodeIn, 
					wRelatePersonRid,
					ISNULL(wIsProcessed, 'N'), 
					wTitle, 
					wContent, 
					wDateTime, 
					ISNULL(wIsImportant, 'N'),
					wCrtDt, 
					wCrtBy, 
					wCrtDt = dbo.fnUTC8Now(), 
					wCrtBy,
					wCounterRid
				FROM #sDataSet_SetCounterLog
            END;
			
        ELSE IF @pActionType = 'U'
            BEGIN
                UPDATE eLog 
				SET 
					eLog.wCompNo = tmp.wCompNo,
					eLog.wDeptCd = tmp.wDeptCd, 
					eLog.wUserRid = tmp.wUserRid, 
					eLog.wType = tmp.wType, 
					eLog.wRelateAgentCodeIn = tmp.wRelateAgentCodeIn, 
					eLog.wRelatePersonRid = tmp.wRelatePersonRid, 
					eLog.wTitle = tmp.wTitle, 
					eLog.wContent = tmp.wContent, 
					eLog.wDateTime = tmp.wDateTime, 
					eLog.wIsImportant = ISNULL(tmp.wIsImportant, 'N'), 
					eLog.wIsProcessed = ISNULL(tmp.wIsProcessed, 'N'),
					eLog.wIsClosed = ISNULL(tmp.wIsClosed, 'N'),
					eLog.wUpdDt = dbo.fnUTC8Now(), 
					eLog.wUpdBy = tmp.wUpdBy,
					eLog.wCounterRid = tmp.wCounterRid
				FROM [dbo].[eCounterLog] eLog 
				INNER JOIN #sDataSet_SetCounterLog tmp ON eLog.RowID = tmp.RowID
            END;

        ELSE IF @pActionType = 'D'
            BEGIN
				UPDATE [dbo].[eCounterLog]
				SET wStatus = 'T', wUpdDt = dbo.fnUTC8Now()
				WHERE RowID IN (SELECT RowID FROM #sDataSet_SetCounterLog)
			END;

		IF @sBeginTranCount = 0 AND @@TRANCOUNT > 0
			BEGIN
				COMMIT;
			END

		--Return RowID affected
		IF @pReturnResultSet = 'Y'
			BEGIN
				SELECT RowID FROM #sDataSet_SetCounterLog;
			END
		RETURN;
	END TRY
	BEGIN CATCH
		DECLARE @sErrorNum INT,
				@sCatchErrorMessage NVARCHAR(4000),
				@xState INT,
				@sProcedureName VARCHAR(100),
				@sRtnCodeLog INT,
				@sErrMessageLog NVARCHAR(4000);

		SELECT  @sErrorNum = ERROR_NUMBER(),
				@sCatchErrorMessage = ERROR_MESSAGE(),
				@xState = XACT_STATE(),
				@sProcedureName = OBJECT_NAME(@@PROCID);

		IF ISNULL(@pErrCode, 0) = 0
			BEGIN
				SET @pErrCode = 999;
			END

		SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ', @sCatchErrorMessage);

		IF @sBeginTranCount = 0 AND (@xState = 1 OR @xState = -1)
			BEGIN
			-- transaction created within this sp
                ROLLBACK;
            END;

		-- Write Log
        EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName,
            @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
	END CATCH

	EXEC sp_xml_removedocument @sDocHandle;

	IF OBJECT_ID ('tempdb..#sDataSet_SetCounterLog') IS NOT NULL DROP TABLE sDataSet_SetCounterLog;
END;