CREATE PROCEDURE [spa].[SetAlterationOfShare]
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
		--SELECT * FROM eAlterationOfShare

	    DECLARE @sThisTableName VARCHAR(50) = 'eAlterationOfShare' , -- For RowID
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
        INTO    #sDataSet_SetAlterationOfShare
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				 RowID BIGINT
				,wDate DATE
				,wAgentCodeIn VARCHAR(14)
				,wRegionCode VARCHAR(3)
				,wReasonOfAlteration NVARCHAR(500)
				,wActionCode VARCHAR(4)
				,wCurrCode VARCHAR(6)
				,wNumberOfSharesChanged	NUMERIC(18, 2)
				,wCurrentShares	NUMERIC(18, 2)
				,wHandler BIGINT
				,wStatus CHAR(1)
				,wCrtDt	DATETIME2(7)
				,wCrtBy	BIGINT
				,wUpdDt	DATETIME2(7)
				,wUpdBy	BIGINT
			);

        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
	
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
	        
            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetAlterationOfShare
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetAlterationOfShare;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,@sRowID OUTPUT;
                            UPDATE  #sDataSet_SetAlterationOfShare
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
			        	-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
				
					INSERT  INTO dbo.[eAlterationOfShare]
					(
							 [RowID]
							,[wDate]
							,[wAgentCodeIn]
							,[wRegionCode]
							,[wReasonOfAlteration]
							,[wActionCode]
							,[wCurrCode]
							,[wNumberOfSharesChanged]
							,[wCurrentShares]
							,[wStatus]
							,[wCrtDt]
							,[wCrtBy]
							,[wUpdDt]
							,[wUpdBy]
							,[wHandler]
					)

					SELECT	 s.RowID
							,s.wDate
							,s.wAgentCodeIn
							,s.wRegionCode
							,s.wReasonOfAlteration
							,s.wActionCode
							,s.wCurrCode
							,s.wNumberOfSharesChanged
							,s.wCurrentShares
							,'A'
							,dbo.fnUTC8Now()
							,s.wCrtBy
							,dbo.fnUTC8Now()
							,s.wUpdBy
							,s.wHandler
					FROM    #sDataSet_SetAlterationOfShare s;
				END
            ELSE
            IF @pActionType = 'U'
                BEGIN
                     UPDATE  met
                     SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
							 met.wDate = tmp.wDate
							,met.wAgentCodeIn = tmp.wAgentCodeIn
							,met.wRegionCode = tmp.wRegionCode 
							,met.wReasonOfAlteration = tmp.wReasonOfAlteration
							,met.wActionCode = tmp.wActionCode 
							,met.wCurrCode = tmp.wCurrCode 
							,met.wNumberOfSharesChanged = tmp.wNumberOfSharesChanged 
							,met.wCurrentShares = tmp.wCurrentShares 
							,met.wUpdDt =dbo.fnUTC8Now()
							,met.wUpdBy =  tmp.wUpdBy
							,met.wHandler =tmp.wHandler
                     FROM    dbo.eAlterationOfShare AS met
                             INNER JOIN #sDataSet_SetAlterationOfShare tmp ON met.RowID = tmp.RowID
                     WHERE   met.RowID = tmp.RowID;
                    END;
            ELSE
            IF @pActionType = 'D'
                 BEGIN
				 UPDATE  met
				 SET
						met.wStatus = 'T',
						met.wUpdDt =dbo.fnUTC8Now(),
						met.wUpdBy =  tmp.wUpdBy
						FROM    dbo.eAlterationOfShare AS met
						INNER JOIN #sDataSet_SetAlterationOfShare tmp ON met.RowID = tmp.RowID
						WHERE   met.RowID = tmp.RowID;
                            
				END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetAlterationOfShare;
            
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

		IF OBJECT_ID('tempdb..#sDataSet_SetAlterationOfShare') IS NOT NULL DROP TABLE #sDataSet_SetAlterationOfShare
    END;