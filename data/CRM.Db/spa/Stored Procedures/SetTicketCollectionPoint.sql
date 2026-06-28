CREATE PROCEDURE [spa].[SetTicketCollectionPoint]
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

		--SELECT *FROM [mTicketCollectionPoint]

	    DECLARE @sThisTableName VARCHAR(50) = 'mTicketCollectionPoint' , -- For RowID
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
        INTO    #sDataSet_SetTicketCollectionPoint
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				RowID BIGINT ,
				wName  NVARCHAR(30) ,
				wCode  VARCHAR(10) ,
				wIsFerryTic char(1) ,
				wIsAirTic char(1) ,
				wIsCheckInService  char(1) ,
				wIsShowTic  char(1) ,
				wIsVisa char(1) ,
				wStatus VARCHAR(20) ,
				wSeqNo BIGINT ,
				wUpdBy BIGINT ,
				wUpdDt DATETIME2(7),
				wAddress NVARCHAR(500)
			);

		 --better don't put everything within try, for example
	     --getting mSysTable value
	     --getting currency, period, mCompany ...
		
		-- Check Uniqueness [wCode] update的时候不需要
		IF EXISTS(SELECT 1 FROM #sDataSet_SetTicketCollectionPoint tmp INNER JOIN dbo.mTicketCollectionPoint d ON tmp.wCode = d.wCode) AND @pActionType = 'I' BEGIN 
			SET @pErrMsg = N'Code already exsists, please use another code';
			THROW 50001, @pErrMsg, 1;
		END
	    
        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
	
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
	        
           

            --進行刪除操作或者中止要做checking 是否有使用的記錄 有就不给删除
            IF @pActionType ='D' OR EXISTS ( SELECT *  FROM #sDataSet_SetTicketCollectionPoint ds WHERE ds.wStatus ='T')
            BEGIN
              DECLARE @sTable TABLE( wTableIndex BIGINT IDENTITY(1,1) PRIMARY KEY, wTableName VARCHAR(30));
              DECLARE @sTableIndex INT = 0;
              DECLARE @sTableName VARCHAR(30);
              DECLARE @sErrMsg NVARCHAR(MAX);
              DECLARE @sSql NVARCHAR(MAX);

              INSERT INTO @sTable (wTableName) VALUES
               ('dbo.eVisaCollection'),
               ('dbo.eTicketCollection');            
              
              SELECT @sTableIndex = COUNT(1) FROM @sTable;

              WHILE @sTableIndex > 0
              BEGIN
                SELECT @sTableName = wTableName FROM @sTable WHERE wTableIndex = @sTableIndex;

                SET @sSql = CONCAT('SELECT TOP(1) @sErrMsg = dbo.fnGetErrorMsg(''3009'',''zh-TW'') FROM #sDataSet_SetTicketCollectionPoint AS ds INNER JOIN ',  @sTableName, ' AS airport ON airport.wTicCollPoint =  ds.wCode ');

                EXEC sp_executesql @sSql, N'@sErrMsg NVARCHAR(MAX) OUTPUT' , @sErrMsg = @sErrMsg OUTPUT   
                
                IF ISNULL(@sErrMsg, '') <> ''
                BEGIN
                    SET @pErrMsg = @sErrMsg;
                    THROW 50001, '', 1;
                END;

                SET @sTableIndex = @sTableIndex -1;
              END
            END

            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetTicketCollectionPoint
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetTicketCollectionPoint;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetTicketCollectionPoint
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[mTicketCollectionPoint]
                            (
								[RowID],
								[wName],
								[wCode],
								[wIsFerryTic],
								[wIsAirTic],
								[wIsCheckInService],
								[wIsShowTic],
								[wIsVisa],
								[wSeqNo],
								[wStatus],
								[wCrtBy],
								[wCrtDt],
								[wUpdBy],
								[wUpdDt],
								[wAddress]
								
							)
                            SELECT
	            	                s.RowID ,
									s.wName ,
									s.wCode ,
									s.wIsFerryTic ,
									s.wIsAirTic ,
									s.wIsCheckInService ,
									s.wIsShowTic ,
									s.wIsVisa,
									s.wSeqNo ,
									s.wStatus ,
									s.wUpdBy ,
									dbo.fnUTC8Now(),
									s.wUpdBy ,
									dbo.fnUTC8Now(),
									s.wAddress
                            FROM    #sDataSet_SetTicketCollectionPoint s;


                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  mtc
                        SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
								mtc.wCode = tmp.wCode ,
								mtc.wName = tmp.wName ,
								mtc.wIsFerryTic= tmp.wIsFerryTic ,
								mtc.wIsAirTic= tmp.wIsAirTic ,
								mtc.wIsCheckInService= tmp.wIsCheckInService ,
								mtc.wIsShowTic= tmp.wIsShowTic ,
								mtc.wIsVisa= tmp.wIsVisa ,
								mtc.wStatus= tmp.wStatus ,
								mtc.wSeqNo= tmp.wSeqNo ,
                                mtc.wUpdBy = tmp.wUpdBy ,
                                mtc.wUpdDt = dbo.fnUTC8Now(),
								mtc.wAddress=tmp.wAddress
                        FROM    dbo.mTicketCollectionPoint AS mtc
                                INNER JOIN #sDataSet_SetTicketCollectionPoint tmp ON mtc.RowID = tmp.RowID
                        WHERE   mtc.RowID = tmp.RowID;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN
                       UPDATE dbo.mTicketCollectionPoint
								SET 
								wStatus='T',
								wUpdDt = dbo.fnUTC8Now()
								WHERE   RowID IN (SELECT RowID FROM #sDataSet_SetTicketCollectionPoint  );
                        END;


	
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetTicketCollectionPoint;

           
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

		IF OBJECT_ID('tempdb..#sDataSet_SetTicketCollectionPoint') IS NOT NULL
			DROP TABLE #sDataSet_SetTicketCollectionPoint
		
    END;