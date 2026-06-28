CREATE PROCEDURE [spa].[SetServiceCounter]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pStrCounterId BIGINT OUTPUT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT   
	)
AS
    BEGIN
        SET NOCOUNT ON;

        --SELECT * FROM [mServiceCounter]

        DECLARE @sThisTableName VARCHAR(50) = 'mServiceCounter' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
           --@sRowID BIGINT = 0 ,
            @sDocHandle INT;
			
	        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );

        SET @sBeginTranCount = @@trancount;	        
        
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
	    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetServiceCounter
        FROM    OPENXML (@sDocHandle, 'DataSet/SetServiceCounterResult', 1)
		WITH (
				RowID BIGINT ,
				wCode  NVARCHAR(20) ,
				wName  NVARCHAR(40) ,
				wSmsRoomID INT ,
				wRollexCompNo INT ,
				wRegion  VARCHAR(20) ,
				wDefaultHotelCode  NVARCHAR(20),
				wCollectionPointCd VARCHAR(30),
				wCurrCode VARCHAR(6) ,
				wRemark NVARCHAR(1000) ,
				wStatus VARCHAR(20) ,
				wSeqNo INT,
				wStoreAgentCodeIn VARCHAR(14) ,
				wHandlingFee NUMERIC(18, 4) ,
				wUpdBy BIGINT ,
				wUpdDt DATETIME2(7),
				wAddress NVARCHAR(500),
                wSMSName NVARCHAR(50),
                wTransferSMSName NVARCHAR(50)
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

            --進行刪除操作要做checking 是否有使用的記錄 有就不给删除
            IF (@pActionType='D' OR EXISTS(SELECT * FROM #sDataSet_SetServiceCounter ds WHERE ds.wStatus='T')) AND
               EXISTS (
                  SELECT * FROM #sDataSet_SetServiceCounter ds
                  INNER JOIN dbo.eBooking eb ON ds.RowID = eb.wDebitCounterRid OR ds.RowID = eb.wReqCounterRid
               )
               BEGIN                          
                    SET @pErrMsg=[dbo].[fnGetErrorMsg]('3006','zh-TW');
                    THROW 50001, '', 1;
               END;

            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetServiceCounter
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetServiceCounter;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @pStrCounterId OUTPUT;
					
                            UPDATE  #sDataSet_SetServiceCounter
                            SET     RowID = @pStrCounterId
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[mServiceCounter]
                            ( [RowID] ,
                              [wCode] ,
                              [wName] ,
                              [wSmsRoomID] ,
                              [wRollexCompNo] ,
                              [wRegion] ,
                              [wDefaultHotelCode] ,
                              [wCurrCode] ,
                              [wRemark] ,
                              [wStatus] ,
                              [wSeqNo] ,
                              [wStoreAgentCodeIn],
                              [wHandlingFee],
                              [wCrtBy] ,
                              [wCrtDt] ,
                              [wUpdBy] ,
                              [wUpdDt] ,
                              [wAddress],
                              [wSMSName],
                              [wTransferSMSName]
                            )
                            SELECT  s.RowID ,
                                    s.wCode ,
                                    s.wName ,
                                    s.wSmsRoomID ,
                                    s.wRollexCompNo ,
                                    s.wRegion ,
                                    s.wDefaultHotelCode ,
                                    s.wCurrCode ,
                                    s.wRemark ,
                                    s.wStatus ,
                                    s.wSeqNo ,
                                    s.wStoreAgentCodeIn ,
                                    s.wHandlingFee ,
                                    s.wUpdBy ,
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy ,
                                    dbo.fnUTC8Now(),
                                    s.wAddress,
                                    ISNULL(s.wSMSName,''),
                                    ISNULL(s.wTransferSMSName,'')
                            FROM    #sDataSet_SetServiceCounter s;


                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  msc
                        SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
                                msc.wCode = tmp.wCode ,
                                msc.wName = tmp.wName ,
                                msc.wSmsRoomID = tmp.wSmsRoomID ,
                                msc.wRollexCompNo = tmp.wRollexCompNo ,
                                msc.wRegion = tmp.wRegion ,
                                msc.wDefaultHotelCode = tmp.wDefaultHotelCode ,
                                msc.wCurrCode = tmp.wCurrCode ,
                                msc.wRemark = tmp.wRemark ,
                                msc.wStatus = tmp.wStatus ,
                                msc.wSeqNo = tmp.wSeqNo ,
                                msc.wStoreAgentCodeIn = tmp.wStoreAgentCodeIn ,
                                msc.wHandlingFee = tmp.wHandlingFee ,
                                msc.wUpdBy = tmp.wUpdBy ,
                                msc.wUpdDt = dbo.fnUTC8Now(),
                                msc.wAddress =tmp.wAddress ,
                                msc.wSMSName = tmp.wSMSName,
                                msc.wTransferSMSName = tmp.wTransferSMSName
                        FROM    dbo.mServiceCounter AS msc
                                INNER JOIN #sDataSet_SetServiceCounter tmp ON msc.RowID = tmp.RowID
                        WHERE   msc.RowID = tmp.RowID;

                        SET @pStrCounterId = ( SELECT TOP 1
                                                        RowID
                                               FROM     #sDataSet_SetServiceCounter
                                             );
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN                          
							
                            SET @pStrCounterId = ( SELECT TOP 1
                                                            RowID
                                                   FROM     #sDataSet_SetServiceCounter
                                                 );

							--EXEC [spa].[SetServiceCounterContact] @pXML,@pActionType,@pMainCompNo, @pStrCounterId, @pErrCode OUTPUT, @pErrMsg OUTPUT; 

							--EXEC [spa].[SetServiceCounterContact] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pStrCounterId, @pErrCode OUTPUT, @pErrMsg OUTPUT; 	

							--DELETE  
       --                     WHERE   RowID IN (
       --                             SELECT  RowID
       --                             FROM     );
	   
                     					
                            UPDATE  dbo.mServiceCounter
                            SET     wStatus = 'T' ,
                                    wUpdDt = dbo.fnUTC8Now()
                            WHERE   RowID IN ( SELECT   RowID
                                               FROM     #sDataSet_SetServiceCounter );

                        END;
          
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;		
                END;

		  -- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetServiceCounter;
         			
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
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ', @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0
                AND ( @xstate = 1
                      OR @xstate = -1
                    )
                BEGIN
				-- transaction created within this sp
                    ROLLBACK;
                END;
	        
	        -- Write Log
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH;
  
	
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetServiceCounter') IS NOT NULL
            DROP TABLE #sDataSet_SetServiceCounter
		
    END;