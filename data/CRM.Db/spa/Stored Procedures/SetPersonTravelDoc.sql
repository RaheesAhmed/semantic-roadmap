CREATE PROCEDURE [spa].[SetPersonTravelDoc]
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
		
		--SELECT * FROM mPersonTravelDoc;

	    DECLARE @sThisTableName VARCHAR(50) = 'mPersonTravelDoc' , -- For RowID
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
        
		SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ),*
        INTO    #sDataSet_SetPersonTravelDoc
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				RowID BIGINT,
				wPersonRID BIGINT,
				wIDType  VARCHAR(30),
				wIDNo  VARCHAR(30),
				wEnglishPinyin NVARCHAR(100),
				wIssueAt  VARCHAR(20),
				wExpiryDate DATE,
				wRemark  NVARCHAR(30),
				wStatus  CHAR(1),
				wRefRID BIGINT,
			    wCrtDt DATETIME2(7),
				wCrtBy BIGINT,
				wUpdDt DATETIME2(7),
				wUpdBy BIGINT
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
                    UPDATE  #sDataSet_SetPersonTravelDoc
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetPersonTravelDoc;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetPersonTravelDoc
                            SET    RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[mPersonTravelDoc]
                            (
								[RowID],
								[wPersonRID],
								[wIDType],
								[wIDNo],
								[wEnglishPinyin],
								[wIssueAt],
								[wExpiryDate],
								[wRemark],
								[wStatus],
								[wRefRID],
								[wCrtBy],
								[wCrtDt],
								[wUpdBy],
								[wUpdDt]
								
							)
                            SELECT
	            	                mpt.RowID,
									mpt.wPersonRID,
									mpt.wIDType,
									mpt.wIDNo,
									mpt.wEnglishPinyin,
									mpt.wIssueAt,
									mpt.wExpiryDate,
									mpt.wRemark,
									mpt.wStatus,
									mpt.wRefRID,
									mpt.wUpdBy,
									dbo.fnUTC8Now(),
									mpt.wUpdBy,
									dbo.fnUTC8Now()
                            FROM    #sDataSet_SetPersonTravelDoc mpt;


                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  mpt
                        SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
								mpt.RowID = tmp.RowID,
								mpt.wPersonRID = tmp.wPersonRID,
								mpt.wIDType = tmp.wIDType,
								mpt.wIDNo = tmp.wIDNo,
								mpt.wEnglishPinyin=tmp.wEnglishPinyin,
								mpt.wIssueAt = tmp.wIssueAt,
								mpt.wExpiryDate = tmp.wExpiryDate,
								mpt.wRemark = tmp.wRemark ,
								mpt.wStatus = tmp.wStatus,
								mpt.wRefRID =tmp.wRefRID,
								mpt.wUpdBy = tmp.wUpdBy,
								mpt.wUpdDt = dbo.fnUTC8Now()
                  FROM    dbo.mPersonTravelDoc AS mpt
                                INNER JOIN #sDataSet_SetPersonTravelDoc tmp ON mpt.RowID = tmp.RowID
                        WHERE   mpt.RowID = tmp.RowID;
                    END;
                ELSE                    
					IF @pActionType = 'D'
                        BEGIN						
                           UPDATE dbo.mPersonTravelDoc
								SET 
								wStatus='T',
								wUpdDt = dbo.fnUTC8Now() 
								WHERE   RowID IN (SELECT RowID FROM #sDataSet_SetPersonTravelDoc );
                        END;


	
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;


			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetPersonTravelDoc
           
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

		IF OBJECT_ID('tempdb..#sDataSet_SetPersonTravelDoc') IS NOT NULL DROP TABLE #sDataSet_SetPersonTravelDoc;
		
END;