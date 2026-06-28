CREATE PROCEDURE [spa].[SetExpenseType]
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
		
		-- SELECT wExpCat AS wExpenseCategory,* from dbo.mExpenseType;
	    
        DECLARE @sThisTableName VARCHAR(50) = 'mExpenseType' , -- For RowID 
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
        
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetExpenseType
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				RowID BIGINT ,
				wCode  NVARCHAR(30) ,
				wName  NVARCHAR(50) ,
				wExpenseCategory VARCHAR(30) ,
				wGiftType VARCHAR(30) ,
				wGiftSubtype VARCHAR(30) ,
				wStatus VARCHAR(20) ,
				wSeqNo INT ,
				wUpdBy BIGINT ,
				wUpdDt DATETIME2(7)
			);

		 --better don't put everything within try, for example
	     --getting mSysTable value
	     --getting currency, period, mCompany ...
	    
        BEGIN TRY

            DECLARE @pErrorMsg VARCHAR(MAX);
		    -- Try to make the transaction scope as small as possible to reduce locking
	
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
	        
            IF EXISTS ( SELECT  *
                        FROM    mExpenseType AS MEXPENSETYPE
                                INNER JOIN #sDataSet_SetExpenseType TEMPEXPENSETYPE ON TEMPEXPENSETYPE.wCode = MEXPENSETYPE.wCode
                                                              AND TEMPEXPENSETYPE.RowID != MEXPENSETYPE.RowID )
                THROW 50001, 'Code already exist.', 1;

            IF @pActionType IN ( 'I', 'U' )
                BEGIN
                    SELECT  @pErrorMsg = CASE WHEN ISNULL(tmp.wCode, '') = ''
                                              THEN 'Code name cannot be null.'
                                              WHEN ISNULL(tmp.wName, '') = ''
                                              THEN 'Name cannot be null.'
                                              WHEN ISNULL(tmp.wGiftType, '') = ''
                                              THEN 'Gift type cannot be null.'
                                              WHEN ISNULL(tmp.wExpenseCategory,
                                                          '') = ''
                                              THEN 'Expense category cannot be null.'
                                              WHEN ISNULL(tmp.wGiftSubtype, '') = ''
                                              THEN 'Gift sub type cannot be null.'
                                         END
                    FROM    #sDataSet_SetExpenseType tmp;
                END;

            IF ( @pErrorMsg <> '' )
                THROW 51000, @pErrorMsg, 1;  

            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetExpenseType
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetExpenseType;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetExpenseType
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[mExpenseType]
                            ( [RowID] ,
                              [wCode] ,
                              [wName] ,
                              [wExpCat] ,
                              [wGiftType] ,
                              [wGiftSubtype] ,
                              [wSeqNo] ,
                              [wStatus] ,
                              [wCrtBy] ,
                              [wCrtDt] ,
                              [wUpdBy] ,
                              [wUpdDt]
								
							)
                            SELECT  s.RowID ,
                                    s.wCode ,
                                    s.wName ,
                                    s.wExpenseCategory ,
                                    s.wGiftType ,
                                    s.wGiftSubtype ,
                                    s.wSeqNo ,
                                    s.wStatus ,
                                    s.wUpdBy ,
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy ,
                                    dbo.fnUTC8Now()
                            FROM    #sDataSet_SetExpenseType s;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        IF EXISTS (SELECT 1 FROM #sDataSet_SetExpenseType ds INNER JOIN CRM.dbo.eAdditionalExpense e ON e.wExpenseType=ds.RowID WHERE ds.wStatus='T')
                           BEGIN
                               SET @pErrMsg =N'该消費類型已被使用,不能删除或终止';	
                           END;
                        ELSE
                           BEGIN
                               UPDATE  met
                               SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
                                       met.wCode = tmp.wCode ,
                                       met.wName = tmp.wName ,
                                       met.wExpCat = tmp.wExpenseCategory ,
                                       met.wGiftType = tmp.wGiftType ,
                                       met.wGiftSubtype = tmp.wGiftSubtype ,
                                       met.wStatus = tmp.wStatus ,
                                       met.wSeqNo = tmp.wSeqNo ,
                                       met.wUpdBy = tmp.wUpdBy ,
                                       met.wUpdDt = dbo.fnUTC8Now()
                               FROM    dbo.mExpenseType AS met
                                       INNER JOIN #sDataSet_SetExpenseType tmp ON met.RowID = tmp.RowID
                               WHERE   met.RowID = tmp.RowID;
                        END;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN
                        IF EXISTS (SELECT 1 FROM #sDataSet_SetExpenseType ds INNER JOIN CRM.dbo.eAdditionalExpense e ON e.wExpenseType=ds.RowID )
                           BEGIN
                               SET @pErrMsg =N'该消費類型已被使用,不能删除或终止';	
                           END;
                        ELSE
                           BEGIN						
                               UPDATE  dbo.mExpenseType
                               SET     wStatus = 'T' ,
                                       wUpdDt = dbo.fnUTC8Now()
                               WHERE   RowID IN (
                                       SELECT  RowID
                                       FROM    #sDataSet_SetExpenseType );
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
                FROM    #sDataSet_SetExpenseType;
				           
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

        IF OBJECT_ID('tempdb..#sDataSet_SetExpenseType') IS NOT NULL
            DROP TABLE #sDataSet_SetExpenseType;
		
    END;