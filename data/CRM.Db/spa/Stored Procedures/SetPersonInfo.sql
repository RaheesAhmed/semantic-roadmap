CREATE PROCEDURE [spa].[SetPersonInfo]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT,
	  @pNonceToken VARCHAR(64),
	  @pReturnResultSet CHAR(1) = 'N',
	  @pPersonRid BigINT OUTPUT,
	  @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
	)
AS
    BEGIN
        SET NOCOUNT ON;

		---- SELECT TOP 1 * FROM mPerson;


	    DECLARE @sThisTableName VARCHAR(50) = 'mPerson' , -- For RowID
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
        INTO    #sDataSet_SetPerson
        FROM    OPENXML (@sDocHandle, 'DataSet/SetPersonInfoResult', 1)
		WITH (
				RowID BIGINT ,
				wAgentCodeIn  VARCHAR(14) ,
				wCName  NVARCHAR(50) ,
				wEName VARCHAR(100) ,
				wNickname NVARCHAR(50) ,
				wRole NCHAR(10) ,
				wSpeakLangCd VARCHAR(10) ,
				wWritenLangCd VARCHAR(10) ,
				wGender CHAR(1) ,
				wBirthdate DATE,
				wNationality VARCHAR(30) ,
				wProvince NVARCHAR(50) ,
				wAddress NVARCHAR(200) ,
				wTelBusiness VARCHAR(50) ,
				wTelHome VARCHAR(50) ,
				wTelOther VARCHAR(100) ,
				wStatus CHAR(1) ,
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
                UPDATE  #sDataSet_SetPerson
                SET     RowID = 0;
                SELECT  @sRecCount = COUNT(*)
                FROM    #sDataSet_SetPerson;
                WHILE @sRuningIndex <= @sRecCount
                    BEGIN
                        EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                            @sRowID OUTPUT;
					
                        UPDATE  #sDataSet_SetPerson
                        SET     RowID = @sRowID
                        WHERE   wRowNum = @sRuningIndex;
                        SET @sRuningIndex = @sRuningIndex + 1;
                    END;  

				SET @pPersonRid =@sRowID;
				
			-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                INSERT  INTO dbo.[mPerson]
                        (
							[RowID],
							[wAgentCodeIn],
							[wCName],
							[wEName],
							[wNickname],
							[wRole],
							[wSpeakLangCd],
							[wWritenLangCd],
							[wGender],
							[wBirthdate],
							[wNationality],
							[wProvince],
							[wAddress],
							[wTelBusiness],
							[wTelHome],
							[wTelOther],
							[wStatus],
							[wCrtBy],
							[wCrtDt],
							[wUpdBy],
							[wUpdDt]
							    
						)
                        SELECT
	            	            s.RowID ,
								s.wAgentCodeIn ,
								s.wCName ,
								s.wEName ,
								s.wNickname ,
								s.wRole ,
								s.wSpeakLangCd ,
								s.wWritenLangCd ,
								s.wGender ,
								s.wBirthdate ,
								s.wNationality ,
								s.wProvince ,
								s.wAddress ,
								s.wTelBusiness ,
								s.wTelHome ,
								s.wTelOther ,
								s.wStatus ,
								s.wUpdBy ,
								dbo.fnUTC8Now(),
								s.wUpdBy ,
								dbo.fnUTC8Now()
                        FROM    #sDataSet_SetPerson s;
            END;
            
			IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetPerson;
       
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
		
		IF OBJECT_ID('tempdb..#sDataSet_SetPerson') IS NOT NULL
			DROP TABLE #sDataSet_SetPerson
END;