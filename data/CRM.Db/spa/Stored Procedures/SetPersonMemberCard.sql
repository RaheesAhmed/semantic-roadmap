CREATE PROCEDURE [spa].[SetPersonMemberCard]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT,
	  @pNonceToken VARCHAR(64),
	  @pReturnResultSet CHAR(1) = 'N',
	  @pPersonRid BigINT,
	  @pErrCode INT = 0 OUTPUT,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
	)
AS
    BEGIN
        SET NOCOUNT ON;

	    DECLARE @sThisTableName VARCHAR(50) = 'mPersonMemberCard' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
			
		----SELECT * FROM [mPersonMemberCard];
	        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );

		SET @sBeginTranCount = @@trancount;
	       
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ),*
        INTO    #sDataSet_SetPersonMemberCard
        FROM    OPENXML (@sDocHandle, 'DataSet/SetPersonMemberCardResult', 1)
		WITH (
				RowID BIGINT ,
				wPersonRID  BIGINT ,
				wCardType  NVARCHAR(30) ,
				wCardNo NVARCHAR(50) ,
				wExpiryDate DATE,
			    wRemark NVARCHAR(500), 
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
                    UPDATE  #sDataSet_SetPersonMemberCard
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetPersonMemberCard;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetPersonMemberCard
                            SET     RowID = @sRowID,
									wPersonRID = @pPersonRid
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[mPersonMemberCard]
                            (
								[RowID],
								[wPersonRID],
								[wCardType],
								[wCardNo],
								[wExpiryDate],
								[wRemark],
								[wStatus],
								[wCrtBy],
								[wCrtDt],
								[wUpdBy],
								[wUpdDt]
							)
                            SELECT
	            	                s.RowID ,
									s.wPersonRID ,
									s.wCardType ,
									s.wCardNo ,
									s.wExpiryDate ,
									s.wRemark,
									s.wStatus ,
									s.wUpdBy ,
									dbo.fnUTC8Now(),
									s.wUpdBy ,
									dbo.fnUTC8Now()
                            FROM    #sDataSet_SetPersonMemberCard s;
                END;
            ELSE IF @pActionType = 'U'
                    BEGIN
                        
						DELETE FROM mPersonMemberCard
						WHERE wPersonRID = @pPersonRid

						--DELETE FROM dbo.mPersonMemberCard
      --                  WHERE wPersonRID IN ( SELECT  wPersonRID FROM #sDataSet_SetPersonMemberCard );

						-- Set RowID by Sequence
						UPDATE  #sDataSet_SetPersonMemberCard
						SET     RowID = 0;
						SELECT  @sRecCount = COUNT(*)
						FROM    #sDataSet_SetPersonMemberCard;
						WHILE @sRuningIndex <= @sRecCount
							BEGIN
								EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
								UPDATE  #sDataSet_SetPersonMemberCard
								SET     RowID = @sRowID,
										wPersonRID = @pPersonRid
								WHERE   wRowNum = @sRuningIndex;
								SET @sRuningIndex = @sRuningIndex + 1;
							END;    		        
				
						-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
						INSERT  INTO dbo.[mPersonMemberCard]
                            (
								[RowID],
								[wPersonRID],
								[wCardType],
								[wCardNo],
								[wExpiryDate],
								[wRemark],
								[wStatus],
								[wCrtBy],
								[wCrtDt],
								[wUpdBy],
								[wUpdDt]
							)
                            SELECT
	            	                s.RowID ,
									s.wPersonRID ,
									s.wCardType ,
									s.wCardNo ,
									s.wExpiryDate ,
									s.wRemark,
									s.wStatus ,
									s.wUpdBy ,
									dbo.fnUTC8Now(),
									s.wUpdBy ,
									dbo.fnUTC8Now()
                            FROM    #sDataSet_SetPersonMemberCard s;

                    END;

         IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

		-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetPersonMemberCard;
           
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

		IF OBJECT_ID('tempdb..#sDataSet_SetPersonMemberCard') IS NOT NULL DROP TABLE #sDataSet_SetPersonMemberCard;
END;