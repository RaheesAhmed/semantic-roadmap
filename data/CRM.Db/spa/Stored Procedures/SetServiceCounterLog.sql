CREATE PROCEDURE [spa].[SetServiceCounterLog]
    (
      @pXML XML ,      
	  @pMainCompNo INT ,
	  @pActionType CHAR(1), --I/U/D
	  @pNonceToken VARCHAR(64) ,
	  @pReturnResultSet CHAR(1) = 'N',
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) OUTPUT
    )
AS
    BEGIN
        SET NOCOUNT ON;
       
		--SELECT * FROM eServiceCounterLog;

        DECLARE @sThisTableName VARCHAR(50) = 'eServiceCounterLog' ,
            @sBeginTranCount	INT = 0 ,
            @sDocHandle			INT,
            @sRecCount			INT = 0,
	        @sRuningIndex		INT = 1,
			@sRowID				BIGINT = 0,
			@sNow				DATETIME2 = dbo.fnUTC8Now();

        DECLARE @sReturnRowID TABLE (RowID BIGINT);

        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ) ,
                *
        INTO    #sDataSet_SetServiceCounterLog
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (  
				RowID BIGINT,
				wConterRid BIGINT,
				wCode NVARCHAR(50), 
				wDateTime DATETIME2(7), 
				wStatus CHAR(1), 
				wCrtDt DATETIME2(7), 
				wCrtBy BIGINT, 
				wUpdDt DATETIME2(7), 
				wUpdBy BIGINT				
			  );        
        BEGIN TRY	                
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
        	IF EXISTS(SELECT 1 FROM #sDataSet_SetServiceCounterLog tmp INNER JOIN eServiceCounterLog es 
						on tmp.wConterRid=es.wConterRid and CONVERT(varchar(10), tmp.wDateTime,120)=CONVERT(varchar(10), es.wDateTime,120))
			  BEGIN
					SET @pActionType = 'U';
			  END;
			ELSE 	
			  BEGIN
                   SET  @pActionType = 'I';
              END; 		
            IF @pActionType = 'I'
                BEGIN
					-- Set RowID by Sequence
					UPDATE #sDataSet_SetServiceCounterLog
					SET RowID = 0 ;

					SELECT @sRecCount = COUNT(1) FROM #sDataSet_SetServiceCounterLog

					WHILE @sRuningIndex <= @sRecCount BEGIN
							BEGIN
								EXEC spq.GetRowId @pMainCompNo, @sThisTableName, @sRowID OUTPUT
								UPDATE #sDataSet_SetServiceCounterLog
								SET RowID = @sRowID WHERE wRowNum = @sRuningIndex
							END
						SET @sRuningIndex = @sRuningIndex + 1;
					END	

                    INSERT  INTO [dbo].[eServiceCounterLog]
                      ( 
						RowID,
						wConterRid,
						wCode, 
						wDateTime, 
						wStatus, 
						wCrtDt, 
						wCrtBy, 
						wUpdDt, 
						wUpdBy
					   )
                      SELECT 
					   RowID,
					   wConterRid,
					   wCode, 
					   wDateTime, 
					   wStatus, 
					   dbo.Fnutc8now(), 
					   wCrtBy, 
					   wUpdDt, 
					   wUpdBy 
					   FROM #sDataSet_SetServiceCounterLog
                END;			
			 ELSE IF @pActionType = 'U'
                BEGIN			
					UPDATE  scl_t
                    SET     
					    scl_t.wCode=tmp.wCode, 
						scl_t.wDateTime=tmp.wDateTime, 
						scl_t.wStatus=tmp.wStatus, 
						--scl_t.wCrtDt=tmp.wCrtDt, 
						--scl_t.wCrtBy=tmp.wCrtBy, 
						scl_t.wUpdDt=tmp.wUpdDt, 
						scl_t.wUpdBy=tmp.wUpdBy
                    FROM    [dbo].[eServiceCounterLog] scl_t
                            INNER JOIN #sDataSet_SetServiceCounterLog tmp 
							ON  scl_t.wConterRid = tmp.wConterRid and CONVERT(varchar(10), scl_t.wDateTime,120)=CONVERT(varchar(10), tmp.wDateTime,120)
                END;          

           IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
					COMMIT;
                END;

			-- Return RowID List
			IF @pReturnResultSet = 'Y'
			BEGIN
				SELECT  RowID
				FROM #sDataSet_SetServiceCounterLog;
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
			SET @pErrCode = ERROR_NUMBER();
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
        IF OBJECT_ID('tempdb..#sDataSet_SetServiceCounterLog') IS NOT NULL
            DROP TABLE #sDataSet_SetServiceCounterLog;
    END;