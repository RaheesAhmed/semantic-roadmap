CREATE PROCEDURE [spa].[SetClientTravelDocInfo]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pPersonId BIGINT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT		  
    )
AS
    BEGIN
        SET NOCOUNT ON;
		--select * from mPersonTravelDoc;
        DECLARE @sThisTableName VARCHAR(50) = 'mPersonTravelDoc' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
	   
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );  
		
        SET @sBeginTranCount = @@trancount;       
        	    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetClientTravelDocInfo
        FROM    OPENXML (@sDocHandle, 'DataSet/SetClientTravelDocInfoResult', 1)
		WITH (
				RowID BIGINT,
				wPersonRID BIGINT,
				wRefRID BIGINT,
				wIDType  VARCHAR(30),
				wIDNo  VARCHAR(30),
				wEnglishPinyin NVARCHAR(100),
				wIssueAt  VARCHAR(20),
				wExpiryDate DATE,
				wRemark  NVARCHAR(30),
				wStatus  CHAR(1),
			    wCrtDt DATETIME2(7),
				wCrtBy BIGINT,
				wUpdDt DATETIME2(7),
				wUpdBy BIGINT
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
                    UPDATE  #sDataSet_SetClientTravelDocInfo
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetClientTravelDocInfo;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetClientTravelDocInfo
                            SET     RowID = @sRowID ,
                                    wPersonRID = @pPersonId
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;
				
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[mPersonTravelDoc]
                            ( [RowID] ,
                              [wPersonRID] ,
                              [wRefRID] ,
                              [wIDType] ,
                              [wIDNo] ,
                              [wEnglishPinyin] ,
                              [wIssueAt] ,
                              [wExpiryDate] ,
                              [wRemark] ,
                              [wStatus] ,
                              [wCrtBy] ,
                              [wCrtDt] ,
                              [wUpdBy] ,
                              [wUpdDt]
								
							)
                            SELECT  mpt.RowID ,
                                    mpt.wPersonRID ,
                                    mpt.wRefRID ,
                                    mpt.wIDType ,
                                    mpt.wIDNo ,
                                    mpt.wEnglishPinyin ,
                                    mpt.wIssueAt ,
                                    mpt.wExpiryDate ,
                                    mpt.wRemark ,
                                    mpt.wStatus ,
                                    mpt.wUpdBy ,
                                    dbo.fnUTC8Now() ,
                                    mpt.wUpdBy ,
                                    dbo.fnUTC8Now()
                            FROM    #sDataSet_SetClientTravelDocInfo mpt;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN					
                        UPDATE  mptdt
                        SET     mptdt.[wPersonRID] = tmp.[wPersonRID] ,
                                mptdt.[wRefRID] = tmp.[wRefRID] ,
                                mptdt.[wIDType] = tmp.[wIDType] ,
                                mptdt.[wIDNo] = tmp.[wIDNo] ,
                                mptdt.[wEnglishPinyin] = tmp.[wEnglishPinyin] ,
                                mptdt.[wIssueAt] = tmp.[wIssueAt] ,
                                mptdt.[wExpiryDate] = tmp.[wExpiryDate] ,
                                mptdt.[wRemark] = tmp.[wRemark] ,
                                mptdt.[wStatus] = tmp.[wStatus] ,
                                mptdt.[wUpdBy] = tmp.[wUpdBy] ,
                                mptdt.[wUpdDt] = dbo.fnUTC8Now()
                        FROM    dbo.mPersonTravelDoc AS mptdt
                                INNER JOIN #sDataSet_SetClientTravelDocInfo tmp ON mptdt.[RowID] = tmp.[RowID]
                        WHERE   mptdt.RowID = tmp.RowID
                                AND tmp.RowID > 0;

                        DELETE  FROM #sDataSet_SetClientTravelDocInfo
                        WHERE   RowID > 0;
                        BEGIN 
                            SELECT  @sRecCount = COUNT(*)
                            FROM    #sDataSet_SetClientTravelDocInfo;

                            WHILE @sRuningIndex <= @sRecCount
                                BEGIN
                                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
                                    UPDATE  #sDataSet_SetClientTravelDocInfo
                                    SET     RowID = @sRowID ,
                                            wPersonRID = @pPersonId
                                    WHERE   wRowNum = @sRuningIndex;
                                    SET @sRuningIndex = @sRuningIndex + 1;
                                END;    		        
                            INSERT  INTO dbo.[mPersonTravelDoc]
                                    ( [RowID] ,
                                      [wPersonRID] ,
                                      [wRefRID] ,
                                      [wIDType] ,
                                      [wIDNo] ,
                                      [wEnglishPinyin] ,
                                      [wIssueAt] ,
                                      [wExpiryDate] ,
                                      [wRemark] ,
                                      [wStatus] ,
                                      [wCrtBy] ,
                                      [wCrtDt] ,
                                      [wUpdBy] ,
                                      [wUpdDt]
								
								    )
                                    SELECT  mpt.RowID ,
                                            mpt.wPersonRID ,
                                            mpt.wRefRID ,
                                            mpt.wIDType ,
                                            mpt.wIDNo ,
                                            mpt.wEnglishPinyin ,
                                            mpt.wIssueAt ,
                                            mpt.wExpiryDate ,
                                            mpt.wRemark ,
                                            mpt.wStatus ,
                                            mpt.wUpdBy ,
                                            dbo.fnUTC8Now() ,
                                            mpt.wUpdBy ,
                                            dbo.fnUTC8Now()
                                    FROM    #sDataSet_SetClientTravelDocInfo mpt;		
                        END;								
                    END; 
	
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

	  -- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetClientTravelDocInfo;
            RETURN;      
	   
        END TRY
        BEGIN CATCH
            DECLARE @vErrorNum INT ,
                @vCatchErrorMessage NVARCHAR(4000) ,
                @xstate INT ,
                @vProcedureName VARCHAR(100) ,
                @vRtnCodeLog INT ,
                @vErrMessageLog NVARCHAR(4000);
	        
            SET @vErrorNum = ERROR_NUMBER();
            SET @vCatchErrorMessage = ERROR_MESSAGE();
            SET @xstate = XACT_STATE();
            SET @vProcedureName = OBJECT_NAME(@@PROCID);
			
            IF ISNULL(@pErrCode, 0) = 0
                BEGIN
                    SET @pErrCode = 999;
                END;
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @vErrorNum, ') ', @vCatchErrorMessage);
			
            IF @sBeginTranCount = 0
                BEGIN
                    IF @xstate != 0
                        ROLLBACK;
                    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT, @vErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;

        END CATCH;
	
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetClientTravelDocInfo') IS NOT NULL
            DROP TABLE #sDataSet_SetClientTravelDocInfo;     
    END;