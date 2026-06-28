CREATE PROCEDURE [spa].[SetServiceCounterContact]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT,	  
	  @pNonceToken VARCHAR(64), 
	  @pReturnResultSet CHAR(1) = 'N',
	  @pStrCounterId BIGINT,
	  @pErrCode INT = 0 OUTPUT,
      @pErrMsg NVARCHAR(200) = '' OUTPUT  
	)
AS
    BEGIN
        SET NOCOUNT ON;

		--SELECT *FROM [mServiceCounterContact]

		DECLARE @sThisTableName VARCHAR(50) = 'mServiceCounterContact' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
			
	    SET @sBeginTranCount = @@trancount;
		
		SELECT  @pErrCode = 0 ,
                @pErrMsg = '';	       

        DECLARE @sReturnRowID TABLE ( RowID BIGINT );	          
	    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetServiceCounterContact
        FROM    OPENXML (@sDocHandle, 'DataSet/SetServiceCounterContactResult', 1)
		WITH (
				RowID BIGINT ,
				wSeriverCounterRid  BIGINT ,
				wDepartmentCode VARCHAR(30) ,				
				wContactType  VARCHAR(10) ,
				wTel  VARCHAR(30) ,
				wEmail VARCHAR(100) ,
				wIsUsingApp CHAR(1) ,
				wSeqNo INT,
				wCrtBy BIGINT ,
				wCrtDt DATETIME2(7),
				wUpdBy BIGINT ,
				wUpdDt DATETIME2(7)
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
                    UPDATE  #sDataSet_SetServiceCounterContact
                    SET     RowID = 0,
							wSeriverCounterRid = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetServiceCounterContact;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetServiceCounterContact
                            SET     RowID = @sRowID,
									wSeriverCounterRid = @pStrCounterId
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[mServiceCounterContact]
                            (
								[RowID] ,
								[wSeriverCounterRid] ,
								[wDepartmentCode] ,
								[wContactType] ,
								[wTel] ,
								[wEmail] ,
								[wIsUsingApp] ,
								[wSeqNo] ,
								[wCrtDt] ,
								[wCrtBy] ,															
								[wUpdDt],
								[wUpdBy] 
							)
                            SELECT
	            	                s.RowID ,
									s.wSeriverCounterRid ,
									s.wDepartmentCode ,
									s.wContactType ,
									s.wTel ,
									s.wEmail ,
									s.wIsUsingApp ,
									s.wSeqNo ,
									dbo.fnUTC8Now(),									
									s.wUpdBy,
									dbo.fnUTC8Now(),
									s.wUpdBy 								
                            FROM  #sDataSet_SetServiceCounterContact s;


                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN

						DELETE from  dbo.mServiceCounterContact Where wSeriverCounterRid = @pStrCounterId AND RowID not in (Select RowID From #sDataSet_SetServiceCounterContact Where RowID > 0)

                        UPDATE  mscc
                        SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
								mscc.wSeriverCounterRid = tmp.wSeriverCounterRid ,
								mscc.wDepartmentCode = tmp.wDepartmentCode ,
								mscc.wContactType= tmp.wContactType ,
								mscc.wTel= tmp.wTel ,
								mscc.wEmail= tmp.wEmail ,
								mscc.wIsUsingApp= tmp.wIsUsingApp ,
								mscc.wSeqNo= tmp.wSeqNo ,															
                                mscc.wUpdBy = tmp.wUpdBy ,
                                mscc.wUpdDt = dbo.fnUTC8Now()
                        FROM    dbo.mServiceCounterContact AS mscc
                                INNER JOIN #sDataSet_SetServiceCounterContact tmp ON mscc.RowID = tmp.RowID
                        WHERE   mscc.RowID = tmp.RowID AND tmp.RowID > 0;
					

                    SELECT  @sRecCount = COUNT(*)					
                    FROM    #sDataSet_SetServiceCounterContact s Where s.RowID < 1;

					Select wRowNum1 = ROW_NUMBER() OVER ( ORDER BY RowID ),*
					INTO #Temp 
					from #sDataSet_SetServiceCounterContact s Where s.RowID < 1

                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #Temp
                            SET     RowID = @sRowID,
									wSeriverCounterRid = @pStrCounterId
                            WHERE   wRowNum1 = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END; 




						-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[mServiceCounterContact]
                            (
								[RowID] ,
								[wSeriverCounterRid] ,
								[wDepartmentCode] ,
								[wContactType] ,
								[wTel] ,
								[wEmail] ,
								[wIsUsingApp] ,
								[wSeqNo] ,
								[wCrtDt] ,
								[wCrtBy] ,															
								[wUpdDt],
								[wUpdBy] 
							)
                            SELECT
	            	                s.RowID ,
									s.wSeriverCounterRid ,
									s.wDepartmentCode ,
									s.wContactType ,
									s.wTel ,
									s.wEmail ,
									s.wIsUsingApp ,
									s.wSeqNo ,
									dbo.fnUTC8Now(),									
									s.wUpdBy,
									dbo.fnUTC8Now(),
									s.wUpdBy 								
                            FROM  #Temp s;

							DROP table #Temp;
			END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN							

                            DELETE  dbo.mServiceCounterContact
                            WHERE   wSeriverCounterRid IN (
                                    SELECT  wSeriverCounterRid
                                    FROM    #sDataSet_SetServiceCounterContact );


                        END;     

			 IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetServiceCounterContact;

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

		IF OBJECT_ID('tempdb..#sDataSet_SetServiceCounterContact') IS NOT NULL
			DROP TABLE #sDataSet_SetServiceCounterContact		
		
    END;