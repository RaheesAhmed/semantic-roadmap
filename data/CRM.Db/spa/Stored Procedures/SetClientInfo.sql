CREATE PROCEDURE [spa].[SetClientInfo]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pPersonId BIGINT OUTPUT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT	
    )
AS
    BEGIN
        SET NOCOUNT ON;

		--select * from mPerson;

        DECLARE @sThisTableName VARCHAR(50) = 'mPerson' , -- For RowID
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
        INTO    #sDataSet_SetClientInfo
        FROM    OPENXML (@sDocHandle, 'DataSet/SetClientInfoResult', 1)
		WITH (
				RowID BIGINT ,
				wAgentCodeIn  NVARCHAR(14) ,
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

        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
      	        
            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetClientInfo
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetClientInfo;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetClientInfo
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;
						        
                    SET @pPersonId = @sRowID;

				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[mPerson]
                            ( [RowID] ,
                              [wAgentCodeIn] ,
                              [wCName] ,
                              [wEName] ,
                              [wNickname] ,
                              [wRole] ,
                              [wSpeakLangCd] ,
                              [wWritenLangCd] ,
                              [wGender] ,
                              [wBirthdate] ,
                              [wNationality] ,
                              [wProvince] ,
                              [wAddress] ,
                              [wTelBusiness] ,
                              [wTelHome] ,
                              [wTelOther] ,
                              [wStatus] ,
                              [wCrtBy] ,
                              [wCrtDt] ,
                              [wUpdBy] ,
                              [wUpdDt]
							    
							)
                            SELECT  s.RowID ,
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
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy ,
                                    dbo.fnUTC8Now()
                            FROM    #sDataSet_SetClientInfo s;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  met
                        SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
                                met.wAgentCodeIn = tmp.wAgentCodeIn ,
                                met.wCName = tmp.wCName ,
                                met.wEName = tmp.wEName ,
                                met.wNickname = tmp.wNickname ,
                                met.wRole = tmp.wRole ,
                                met.wSpeakLangCd = tmp.wSpeakLangCd ,
                                met.wWritenLangCd = tmp.wWritenLangCd ,
                                met.wGender = tmp.wGender ,
                                met.wBirthdate = tmp.wBirthdate ,
                                met.wNationality = tmp.wNationality ,
                                met.wProvince = tmp.wProvince ,
                                met.wAddress = tmp.wAddress ,
                                met.wTelBusiness = tmp.wTelBusiness ,
                                met.wTelHome = tmp.wTelHome ,
                                met.wTelOther = tmp.wTelOther ,
                                met.wStatus = tmp.wStatus ,
                                met.wUpdBy = tmp.wUpdBy ,
                                met.wUpdDt = dbo.fnUTC8Now()
                        FROM    dbo.mPerson AS met
                                INNER JOIN #sDataSet_SetClientInfo tmp ON met.RowID = tmp.RowID
                        WHERE   met.RowID = tmp.RowID;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN						
                            UPDATE  dbo.mPerson
                            SET     wStatus = 'T' ,
                                    wUpdDt = dbo.fnUTC8Now()
                            WHERE   RowID IN ( SELECT   RowID
                                               FROM     #sDataSet_SetClientInfo );
                        END;	

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

		 -- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetClientInfo;
          
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

        IF OBJECT_ID('tempdb..#sDataSet_SetClientInfo') IS NOT NULL
            DROP TABLE #sDataSet_SetClientInfo;    
		
    END;