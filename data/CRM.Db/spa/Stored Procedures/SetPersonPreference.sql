CREATE PROCEDURE [spa].[SetPersonPreference]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT,
	  @pNonceToken VARCHAR(64),
	  @pReturnResultSet CHAR(1) = 'N',
	  @pPersonRid BIGINT,
	  @pErrCode INT = 0 OUTPUT,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
	)
AS
BEGIN
        SET NOCOUNT ON;

		---SELECT * FROM mPersonPerference;

	    DECLARE @sThisTableName VARCHAR(50) = 'mPersonPerference' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
			@sSeqNo INT = 0,
            @sDocHandle INT;
			
	        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );

		SET @sBeginTranCount = @@trancount;
	    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetPersonPreference
        FROM    OPENXML (@sDocHandle, 'DataSet/SetPersonPreferenceResult', 1)
		WITH (
				RowID BIGINT ,
				wPersonRid BIGINT,
				wPerferenceType  VARCHAR(30) ,
				wPerferenceSubType VARCHAR(30),
				wRemark NVARCHAR(500),
				wSeqNo INT ,
				wUpdBy BIGINT ,
				wUpdDt DATETIME2(7)
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
	        
            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetPersonPreference
                    SET     RowID = 0,wSeqNo = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetPersonPreference;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;

							IF @sSeqNo = 0
								BEGIN
									Select @sSeqNo = ISNULL(MAX(wSeqNo),1) From dbo.[mPersonPerference]
									SET @sSeqNo = @sSeqNo + 1
								END
								ELSE
								BEGIN
								  SET @sSeqNo = @sSeqNo + 1
							END

                            UPDATE  #sDataSet_SetPersonPreference
                            SET     RowID = @sRowID,
									wPersonRid = @pPersonRid,
									wSeqNo = @sSeqNo
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[mPersonPerference]
                            (
								[RowID],
								[wPersonRid],
								[wPerferenceType],
								[wPerferenceSubType],
								[wRemark],
								[wSeqNo],						
								[wCrtBy],
								[wCrtDt],
								[wUpdBy],
								[wUpdDt]
							)
                            SELECT
	            	                s.RowID ,
									s.wPersonRid,								
									s.wPerferenceType,
									s.wPerferenceSubType,
									s.wRemark,
									s.wSeqNo,				
									s.wUpdBy,
									dbo.fnUTC8Now(),
									s.wUpdBy,
									dbo.fnUTC8Now()
                            FROM    #sDataSet_SetPersonPreference s;
                END;

				ELSE
                IF @pActionType = 'U'
                    BEGIN
                        
						DELETE FROM mPersonPerference
						WHERE wPersonRid = @pPersonRid

						--DELETE FROM dbo.mPersonPerference
      --                  WHERE wPersonRid IN ( SELECT  wPersonRID FROM #sDataSet_SetPersonPreference );

						UPDATE  #sDataSet_SetPersonPreference
					SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetPersonPreference;
                    WHILE @sRuningIndex <= @sRecCount
                BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetPersonPreference
                            SET     RowID = @sRowID,
									wPersonRid = @pPersonRid
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
            INSERT  INTO dbo.[mPersonPerference]
                            (
								[RowID],
								[wPersonRid],
								[wPerferenceType],
								[wPerferenceSubType],
								[wRemark],
								[wSeqNo],						
								[wCrtBy],
								[wCrtDt],
								[wUpdBy],
								[wUpdDt]
							)
                            SELECT
	            	                s.RowID ,
									s.wPersonRid,								
									s.wPerferenceType,
									s.wPerferenceSubType,
									s.wRemark,
									s.wSeqNo,				
									s.wUpdBy,
									dbo.fnUTC8Now(),
									s.wUpdBy,
									dbo.fnUTC8Now()
                            FROM    #sDataSet_SetPersonPreference s;
                    END;   
					
	 	IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;	
				
		-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetPersonPreference;				    
           
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
	
        EXEC sp_xml_removedocument @sDocHandle;

		IF OBJECT_ID('tempdb..#sDataSet_SetPersonPreference') IS NOT NULL DROP TABLE #sDataSet_SetPersonPreference;
		
END;