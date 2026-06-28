CREATE PROCEDURE [spa].[SetShowDetails]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D  
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pShowID BIGINT OUTPUT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT      
    )
AS
    BEGIN  
        SET NOCOUNT ON;  

	--	SELECT *FROM [mShow]
     
        DECLARE @sThisTableName VARCHAR(50) = 'mShow' ,-- For RowID  
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sSeqNo BIGINT= 0 ,
            @sDocHandle INT;  
              
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );  
           
        SET @sBeginTranCount = @@trancount;  
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
         
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;  
       
     --    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #DataSet_SetShowDetails
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)  
		  WITH (  
			RowID BIGINT,		
				wName NVARCHAR(50),		
				wVenue NVARCHAR(50),		
				wStartDate DATE,		
				wEndDate DATE,		
				wShowCatCode VARCHAR(10),		
				
				wIsExtraName CHAR(1),		
				wIsFullDay CHAR(1),		
				wHaveTicket CHAR(1),
				wContent NVARCHAR(500),		
				wStatus CHAR(1),		
				wSeqNo INT,		
				wPerformanceDt DATETIME2(7),	
				wCrtDt DATETIME2(7),		
				wCrtBy BIGINT,		
				wUpdDt DATETIME2(7),		
				wUpdBy BIGINT
				,wPerformanceArea NVARCHAR(100)
				,wSupplier BIGINT 
		   );  

		      --- Leading Field Validation Start
        DECLARE @errorMsg VARCHAR(MAX);	
        IF @pActionType IN ( 'I', 'U' )
            BEGIN
                SELECT  @errorMsg = CASE WHEN RTRIM(ISNULL(ef.wName, '')) = ''
                                         THEN 'Name is missing'
                                         WHEN RTRIM(ISNULL(ef.wVenue, '')) = ''
                                         THEN 'Venue is missing'
                                    END
                FROM    #DataSet_SetShowDetails ef;
            END;
        IF @errorMsg <> ''
            THROW 50001, @errorMsg, 1;
			--- Leading Field Validation end
  
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
                    UPDATE  #DataSet_SetShowDetails
                    SET     RowID = 0;  
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #DataSet_SetShowDetails;  
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN  
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;  
       
                            IF @sSeqNo = 0
                                BEGIN
                                    SELECT  @sSeqNo = ISNULL(MAX(wSeqNo), 1)
                                    FROM    dbo.mShow;
                                    SET @sSeqNo = @sSeqNo + 1;
                                END;
                            ELSE
                                BEGIN
                                    SET @sSeqNo = @sSeqNo + 1;
                                END;

                            UPDATE  #DataSet_SetShowDetails
                            SET     RowID = @sRowID ,
                                    wSeqNo = @sSeqNo
                            WHERE   wRowNum = @sRuningIndex;  
                            SET @sRuningIndex = @sRuningIndex + 1;  
                        END;                
          
                    SET @pShowID = @sRowID;  	    
  
   -- MAIN Logic here, example here is inserting dataset to eIOUPenalty  
                    INSERT  INTO dbo.[mShow]
                            ( RowID ,
                              wName ,
                              wVenue ,
                              wStartDate ,
                              wEndDate ,
                              wShowCatCode ,
                              wIsExtraName ,
                              wIsFullDay ,
                              wHaveTicket ,
                              wContent ,
                              wStatus ,
                              wSeqNo ,
                              wPerformanceDt ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy ,
                              wPerformanceArea ,
                              wSupplier
					        )
                            SELECT  s.RowID ,
                                    s.wName ,
                                    s.wVenue ,
                                    s.wStartDate ,
                                    s.wEndDate ,
                                    s.wShowCatCode ,
                                    s.wIsExtraName ,
                                    s.wIsFullDay ,
                                    s.wHaveTicket ,
                                    s.wContent ,
                                    s.wStatus ,
                                    s.wSeqNo ,
                                    s.wPerformanceDt ,
                                    dbo.fnUTC8Now() ,
                                    s.wCrtBy ,
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy ,
                                    s.wPerformanceArea ,
                                    s.wSupplier
                            FROM    #DataSet_SetShowDetails s;        
                END;    
  
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                         IF EXISTS (SELECT 1 FROM #DataSet_SetShowDetails ds INNER JOIN CRM.dbo.eBookingShow e ON e.wShowRid=ds.RowID WHERE ds.wStatus='T')
                            BEGIN
                                SET @pErrMsg =N'该門票價格已被使用,不能删除或终止';	
                            END;
                        ELSE
                            BEGIN
                                UPDATE  met
                                SET     met.wName = tmp.wName ,
                                        met.wVenue = tmp.wVenue ,
                                        met.wStartDate = tmp.wStartDate ,
                                        met.wEndDate = tmp.wEndDate ,
                                        met.wShowCatCode = tmp.wShowCatCode ,
                                        met.wIsExtraName = tmp.wIsExtraName ,
                                        met.wIsFullDay = tmp.wIsFullDay ,
                                        met.wHaveTicket = tmp.wHaveTicket ,
                                        met.wContent = tmp.wContent ,
                                        met.wStatus = tmp.wStatus ,
                                        met.wSeqNo = tmp.wSeqNo ,
                                        met.wPerformanceDt = tmp.wPerformanceDt ,
                                        met.wUpdBy = tmp.wUpdBy ,
                                        met.wUpdDt = tmp.wUpdDt ,
                                        met.wPerformanceArea = tmp.wPerformanceArea ,
                                        met.wSupplier = tmp.wSupplier
                                FROM    dbo.mShow AS met
                                        INNER JOIN #DataSet_SetShowDetails tmp ON met.RowID = tmp.RowID
                                WHERE   met.RowID = tmp.RowID; 
                            END;  
                    END;  

                ELSE
                    IF @pActionType = 'D'
                        BEGIN
                            IF EXISTS (SELECT 1 FROM #DataSet_SetShowDetails ds INNER JOIN CRM.dbo.eBookingShow e ON e.wShowRid=ds.RowID )
                               BEGIN
                                   SET @pErrMsg =N'该門票價格已被使用,不能删除或终止';	
                               END;
                            ELSE
                               BEGIN
                                   UPDATE  ms
                                   SET     ms.wStatus = 'T' ,
                                           wUpdDt = dbo.fnUTC8Now()
                                   FROM    dbo.mShow AS ms
                                           INNER JOIN #DataSet_SetShowDetails tmp ON ms.RowID = tmp.RowID
                                   WHERE   ms.RowID = tmp.RowID;
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
                FROM    #DataSet_SetShowDetails;	 
        
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

        IF OBJECT_ID('tempdb..#DataSet_SetShowDetails') IS NOT NULL
            DROP TABLE #DataSet_SetShowDetails;
     
    END;