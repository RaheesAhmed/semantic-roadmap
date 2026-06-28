CREATE PROCEDURE [spa].[SetAccountAnalysis]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT,
	  @pNonceToken VARCHAR(64) ,
	  @pReturnResultSet CHAR(1) = 'N',
	  @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT 
	)
AS
    BEGIN
        SET NOCOUNT ON;
		--select * from eAccountAnalysis
	    DECLARE @sThisTableName VARCHAR(50) = 'eAccountAnalysis' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
			
	        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
	        
        SET @sBeginTranCount = @@trancount;
	    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #DataSet_SetAccountAnalysis
        FROM    OPENXML (@sDocHandle, 'DataSet/SetAccountAnalysisResult', 1)
		WITH (
				RowID  BIGINT,
				wListSameNameAccount NVARCHAR(200),
				wRelationship NVARCHAR(100),
				wUplineRelation NVARCHAR(100),
				wOtherBettingType NVARCHAR(200),
				wOperation NVARCHAR(100),
				wBRolling NVARCHAR(100),
				wCardGame NVARCHAR(200),
				wTripRecord NVARCHAR(200),
				wReturnToMarketingDept NVARCHAR(100),
				wWorkWithCash NVARCHAR(100),
				wEventsWithSpecialApproval NVARCHAR(200),
				wOtherLineGroup NVARCHAR(100),
				wRemarks NVARCHAR(500),
				wAgentCodeIn VARCHAR(14),
				wAccountStatus VARCHAR(5),
				wAccountSubStatus VARCHAR(5),
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

		DECLARE @rowId BIGINT 
		SET @rowId = (SELECT RowID FROM #DataSet_SetAccountAnalysis) 
		IF @rowId = 0 
		BEGIN
		  SET @pActionType = 'I' 
		END
		ELSE
		BEGIN
		  SET @pActionType = 'U'
	    END

            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #DataSet_SetAccountAnalysis
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #DataSet_SetAccountAnalysis;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #DataSet_SetAccountAnalysis
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[eAccountAnalysis]
                            (
								RowID,
								wListSameNameAccount,
								wRelationship,
								wUplineRelation,
								wOtherBettingType,
								wOperation,
								wBRolling,
								wCardGame,
								wTripRecord,
								wReturnToMarketingDept,
								wWorkWithCash,
								wEventsWithSpecialApproval,
								wOtherLineGroup,
								wRemarks,
								wAgentCodeIn,
								wAccountStatus,
								wAccountSubStatus,
								wCrtDt,
								wCrtBy,
								wUpdDt,
								wUpdBy
							)
                            SELECT
	            	            s.RowID,
								s.wListSameNameAccount,
								s.wRelationship,
								s.wUplineRelation,
								s.wOtherBettingType,
								s.wOperation,
								s.wBRolling,
								s.wCardGame,
								s.wTripRecord,
								s.wReturnToMarketingDept,
								s.wWorkWithCash,
								s.wEventsWithSpecialApproval,
								s.wOtherLineGroup,
								s.wRemarks,
								s.wAgentCodeIn,
								s.wAccountStatus,
								s.wAccountSubStatus,
								s.wCrtDt,
								s.wCrtBy,
								s.wUpdDt,
								s.wUpdBy
                            FROM    #DataSet_SetAccountAnalysis s;

                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                    DECLARE @temp INT 
                    SET @temp= (SELECT COUNT(*)  FROM    dbo.eAccountAnalysis AS eaa
                                INNER JOIN #DataSet_SetAccountAnalysis tmp ON eaa.RowID = tmp.RowID
                        WHERE   eaa.RowID = tmp.RowID)
                        
                        UPDATE  eaa
                        SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
								eaa.wListSameNameAccount = tmp.wListSameNameAccount,
								eaa.wRelationship = tmp.wRelationship,
								eaa.wUplineRelation = tmp.wUplineRelation,
								eaa.wOtherBettingType = tmp.wOtherBettingType,
								eaa.wOperation = tmp.wOperation,
								eaa.wBRolling = tmp.wBRolling,
								eaa.wCardGame = tmp.wCardGame,
								eaa.wTripRecord = tmp.wTripRecord,
								eaa.wReturnToMarketingDept = tmp.wReturnToMarketingDept,
								eaa.wWorkWithCash = tmp.wWorkWithCash,
								eaa.wEventsWithSpecialApproval = tmp.wEventsWithSpecialApproval,
								eaa.wOtherLineGroup = tmp.wOtherLineGroup,
								eaa.wRemarks = tmp.wRemarks,
								eaa.wAgentCodeIn = tmp.wAgentCodeIn,
								eaa.wAccountStatus = tmp.wAccountStatus,
								eaa.wAccountSubStatus = tmp.wAccountSubStatus,
								eaa.wCrtDt = tmp.wCrtDt,
								eaa.wCrtBy = tmp.wCrtBy,
								eaa.wUpdDt =  tmp.wUpdDt,
								eaa.wUpdBy = tmp.wUpdBy
                        FROM    dbo.eAccountAnalysis AS eaa
                                INNER JOIN #DataSet_SetAccountAnalysis tmp ON eaa.RowID = tmp.RowID
                        WHERE   eaa.RowID = tmp.RowID;
                    END;                
           
			IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

            -- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #DataSet_SetAccountAnalysis;

            RETURN;
        END TRY
       BEGIN CATCH
            DECLARE @vErrorNum INT ,
                @vCatchErrorMessage NVARCHAR(4000) ,
                @xstate INT ,
                @vProcedureName VARCHAR(100) ,
                @vRtnCodeLog INT ,
                @vErrMessageLog NVARCHAR(4000);
	        
			SET  @vErrorNum = ERROR_NUMBER();
			SET  @vCatchErrorMessage = ERROR_MESSAGE();
			SET  @xstate = XACT_STATE();
			SET  @vProcedureName = OBJECT_NAME(@@PROCID);
			
            IF ISNULL(@pErrCode, 0) = 0
                BEGIN
                    SET @pErrCode = 999;
                END;
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @vErrorNum, ') ',
                                  @vCatchErrorMessage);
			
			IF @sBeginTranCount = 0 BEGIN
				IF @xstate != 0
					ROLLBACK;
	            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT, @vErrMessageLog OUTPUT;
			END
			ELSE
				THROW;

        END CATCH;
	
        EXEC sp_xml_removedocument @sDocHandle;

		IF OBJECT_ID('tempdb..#DataSet_SetAccountAnalysis') IS NOT NULL
			DROP TABLE #DataSet_SetAccountAnalysis
    END;