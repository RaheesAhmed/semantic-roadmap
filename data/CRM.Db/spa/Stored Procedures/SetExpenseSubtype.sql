CREATE PROCEDURE [spa].[SetExpenseSubtype]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT

	)
AS
    BEGIN
        SET NOCOUNT ON;

		--SELECT * FROM [mExpenseSubtype];
			
        DECLARE @sThisTableName VARCHAR(50) = 'mExpenseSubtype' , -- For RowID
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
	    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowId ) ,
                *
        INTO    #sDataSet_SetExpenseSubtype
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				RowId BIGINT ,				
				wCode NVARCHAR(30) ,				
				wName  NVARCHAR(50) ,
				wExpenseTypeId  BIGINT ,
				wExpCat  VARCHAR(10) ,
				wGiftType VARCHAR(10) ,
				wGiftSubtype VARCHAR(10) ,
				wStatus CHAR(1) ,
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
				-- Set RowId by Sequence
                    UPDATE  #sDataSet_SetExpenseSubtype
                    SET     RowId = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetExpenseSubtype;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetExpenseSubtype
                            SET     RowId = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[mExpenseSubtype]
                            ( [RowID] ,
                              [wCode] ,
                              [wName] ,
                              [wExpenseTypeId] ,
                              [wExpCat] ,
                              [wGiftType] ,
                              [wGiftSubtype] ,
                              [wStatus] ,
                              [wSeqNo] ,
                              [wCrtDt] ,
                              [wCrtBy] ,
                              [wUpdDt] ,
                              [wUpdBy] 
							)
                            SELECT  s.RowId ,
                                    s.wCode ,
                                    s.wName ,
                                    s.wExpenseTypeId ,
                                    s.wExpCat ,
                                    s.wGiftType ,
                                    s.wGiftSubtype ,
                                    s.wStatus ,
                                    s.wSeqNo ,
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy ,
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy
                            FROM    #sDataSet_SetExpenseSubtype s;


                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        IF EXISTS (SELECT 1 FROM #sDataSet_SetExpenseSubtype ds INNER JOIN CRM.dbo.eAdditionalExpense e ON e.wExpenseSubType=ds.RowID WHERE ds.wStatus='T')
                           BEGIN
                               SET @pErrMsg =N'该消費副類型已被使用,不能删除或终止';	
                           END;
                      ELSE
                           BEGIN
                               UPDATE  mscc
                               SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string								
                                       mscc.wCode = tmp.wCode ,
                                       mscc.wName = tmp.wName ,
                                       mscc.wExpenseTypeId = tmp.wExpenseTypeId ,
                                       mscc.wExpCat = tmp.wExpCat ,
                                       mscc.wGiftType = tmp.wGiftType ,
                                       mscc.wGiftSubtype = tmp.wGiftSubtype ,
                                       mscc.wStatus = tmp.wStatus ,
                                       mscc.wSeqNo = tmp.wSeqNo ,
                                       mscc.wUpdBy = tmp.wUpdBy ,
                                       mscc.wUpdDt = dbo.fnUTC8Now()
                               FROM    dbo.mExpenseSubtype AS mscc
                                       INNER JOIN #sDataSet_SetExpenseSubtype tmp ON mscc.RowID = tmp.RowId
                               WHERE   mscc.RowID = tmp.RowId;
                           END;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN
                        IF EXISTS (SELECT 1 FROM #sDataSet_SetExpenseSubtype ds INNER JOIN CRM.dbo.eAdditionalExpense e ON e.wExpenseSubType=ds.RowID )
                           BEGIN
                               SET @pErrMsg =N'该消費副類型已被使用,不能删除或终止';	
                           END;
                     ELSE	
                           BEGIN					
                               UPDATE  dbo.mExpenseSubtype
                               SET     wStatus = 'T' ,
                                       wUpdDt = dbo.fnUTC8Now()
                               WHERE   RowID IN (
                                       SELECT  RowId
                                       FROM    #sDataSet_SetExpenseSubtype );
                           END;
                        END;
	
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN					
                    COMMIT;
                END; 
				
			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowId
                FROM    #sDataSet_SetExpenseSubtype;				       
			
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

        IF OBJECT_ID('tempdb..#sDataSet_SetExpenseSubtype') IS NOT NULL
            DROP TABLE #sDataSet_SetExpenseSubtype;		
    END;