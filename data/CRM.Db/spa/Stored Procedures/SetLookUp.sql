CREATE PROCEDURE [spa].[SetLookUp]
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
		
		-- SELECT * FROM [mLookUp];

	    DECLARE @sThisTableName VARCHAR(50) = 'mLookUp' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sDocHandle INT;
			
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
	        
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
	    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
		  
        SELECT  wRowNum = ROW_NUMBER() over (Order by [wType],wCode,wParentCode,wLangCd),*
        INTO    #sDataSet_SetLookUp
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				--RowID BIGINT ,
				wType  VARCHAR(50) ,
				wCode  VARCHAR(30) ,
				wParentCode VARCHAR(30) ,
				wLangCd VARCHAR(10) ,
				wSeqNo SMAllINT ,
				wTitle NVARCHAR(50) ,
				wDescr NVARCHAR(500) ,
				wStatus VARCHAR(20) ,
				wCanEdit Char,
				wCanSelect Char,
				wUpdBy BIGINT ,
				wUpdDt DATETIME2(7)
			);

		 --better don't put everything within try, for example
	     --getting mSysTable value
	     --getting currency, period, mCompany ...
	    
        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
	
			DECLARE @sErrorMsg VARCHAR(MAX)='';
	
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
	        
			IF @pActionType IN ('I','U')
				BEGIN
					SELECT @sErrorMsg=CASE WHEN	ISNULL(s.wType,'')='' THEN 'Type is missing.' 
										   WHEN	ISNULL(s.wCode,'')='' THEN 'Code is missing.'	
										   WHEN	ISNULL(s.wLangCd,'')='' THEN 'Language is missing.'
										   WHEN	s.wSeqNo <=0 THEN 'Sequence is missing.'
										   WHEN	ISNULL(s.wTitle,'')='' THEN 'Title is missing.'	
										   WHEN	ISNULL(s.wStatus,'')='' THEN 'Status is missing.'
									  END
					 FROM #sDataSet_SetLookUp s
				END

		
	        IF(@pActionType='U')
				BEGIN 
					SELECT @sErrorMsg=CASE WHEN	ml.wSeqNo<>tmp.wSeqNo THEN 'Sequence number cannot be changed  for terminated objects'	
											   WHEN	ml.wTitle<>tmp.wTitle THEN 'Title cannot be changed  for terminated objects'	
											   WHEN	ml.wDescr<>tmp.wDescr THEN 'Description cannot be changed  for terminated objects'	
											   WHEN	ml.wCanEdit<>tmp.wCanEdit THEN 'CanEdit cannot be changed  for terminated objects'	
											   WHEN	ml.wCanSelect<>tmp.wCanSelect THEN 'CanSelect cannot be changed  for terminated objects'	
											   WHEN	ml.wStatus<>tmp.wStatus THEN 'Status cannot be changed  for terminated objects'	
										  END
					FROM dbo.mLookUp AS ml
									INNER JOIN #sDataSet_SetLookUp tmp ON ml.wType = tmp.wType AND ml.wCode = tmp.wCode AND ml.wLangCd = tmp.wLangCd 
							WHERE   ml.wType = tmp.wType AND ml.wCode = tmp.wCode AND ml.wLangCd = tmp.wLangCd and ml.wStatus='T' ; 
				END	

			IF @sErrorMsg <> ''
				THROW 50001,@sErrorMsg,5;

            IF @pActionType = 'I'
                BEGIN
				
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[mLookUp]
                            (
								  [wType],
								  [wCode],
								  [wParentCode],
								  [wLangCd],
								  [wSeqNo],
								  [wTitle],
								  [wDescr],
								  [wStatus],
								  [wCanEdit],
								  [wCanSelect],
								  [wCrtBy],
								  [wCrtDt],
								  [wUpdBy],
								  [wUpdDt]
								
							)
                            SELECT
								  s.wType,
								  s.wCode,
								  s.wParentCode,
								  s.wLangCd,
								  s.wSeqNo,
								  s.wTitle,
								  s.wDescr,
								  s.wStatus,
								  s.wCanEdit,
								  s.wCanSelect,
								  s.wUpdBy ,
								  dbo.fnUTC8Now(),
								  s.wUpdBy ,
								  dbo.fnUTC8Now()
									
                            FROM    #sDataSet_SetLookUp s;


                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  ml
                        SET    
								ml.wSeqNo = tmp.wSeqNo ,
								ml.wTitle = tmp.wTitle ,
								ml.wDescr = tmp.wDescr ,
								ml.wStatus = tmp.wStatus ,
								ml.wCanEdit = tmp.wCanEdit ,
								ml.wCanSelect = tmp.wCanSelect ,
								ml.wUpdBy = tmp.wUpdBy ,
                                ml.wUpdDt = dbo.fnUTC8Now()
                        FROM    dbo.mLookUp AS ml
                                INNER JOIN #sDataSet_SetLookUp tmp ON ml.wType = tmp.wType AND ml.wCode = tmp.wCode AND ml.wLangCd = tmp.wLangCd 
                        WHERE   ml.wType = tmp.wType AND ml.wCode = tmp.wCode AND ml.wLangCd = tmp.wLangCd  ; 
                    END;
                ELSE
                    IF @pActionType = 'D'
                    BEGIN
							DECLARE @wType  VARCHAR(50)
							DECLARE @wCode  VARCHAR(30)
							DECLARE @wParentCode VARCHAR(30)
							DECLARE @wLangCd VARCHAR(10)
							DECLARE @wStatus VARCHAR(20)					

							DECLARE cur_delete_lookup CURSOR
							STATIC FOR 
								Select wType,wCode,wParentCode,wLangCd,wStatus from #sDataSet_SetLookUp
								OPEN cur_delete_lookup
								IF @@CURSOR_ROWS > 0
									BEGIN 
										FETCH NEXT FROM cur_delete_lookup INTO  @wType,@wCode,@wParentCode,@wLangCd ,@wStatus
										WHILE @@Fetch_status = 0
										BEGIN	
										 UPDATE dbo.mLookUp SET wStatus='T',wUpdDt = dbo.fnUTC8Now()  WHERE wType = @wType AND wCode = @wCode ANd wParentCode = @wParentCode AND wLangCd = @wLangCd																							  																													
											--Delete from mLookUp Where wType = @wType AND wCode = @wCode ANd wParentCode = @wParentCode AND wLangCd = @wLangCd																							
									
											FETCH NEXT FROM cur_delete_lookup INTO @wType,@wCode,@wParentCode,@wLangCd, @wStatus
										END								
									END
									CLOSE cur_delete_lookup
									DEALLOCATE cur_delete_lookup                        
							END;
						


	
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

            -- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetLookUp;

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

		IF OBJECT_ID('tempdb..#sDataSet_SetLookUp') IS NOT NULL DROP TABLE #sDataSet_SetLookUp;
		
END;