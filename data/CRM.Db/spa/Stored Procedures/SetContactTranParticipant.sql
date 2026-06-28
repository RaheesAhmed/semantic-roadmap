CREATE PROCEDURE [spa].[SetContactTranParticipant]
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
        DECLARE @sThisTableName VARCHAR(50) = 'eContactTranParticipant' , -- For RowID 
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
			
	        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
	        
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';

	    -- dbml
		--declare @sRtnList table (
		--	RowID bigint not null
		--)
		--Select * from @sRtnList
		--return

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetContactTranParticipant
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eContactTranParticipant', '', 'Y', '', '', '')
			RowID BIGINT, wContactTranRid BIGINT, wAgentCodeIn VARCHAR(14), wParticipated CHAR(1), wStatus CHAR(1), wCrtDt DATETIME2, wCrtBy BIGINT, wUpdDt DATETIME2, wUpdBy BIGINT
		);		 
	    
        BEGIN TRY		    
            IF @pActionType = 'I'
                AND EXISTS ( SELECT 1
                             FROM   dbo.eContactTranParticipant ctp
                                    INNER JOIN #sDataSet_SetContactTranParticipant tmp ON ctp.wContactTranRid = tmp.wContactTranRid
                                                              AND ctp.wAgentCodeIn = tmp.wAgentCodeIn )
                BEGIN
                    THROW 50001, 'User already exists, cannot insert duplicated user for the same contact', 1;
                END;

            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF @pActionType = 'I'
                BEGIN
		  -- Set RowID by Sequence
                    UPDATE  #sDataSet_SetContactTranParticipant
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetContactTranParticipant;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetContactTranParticipant
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
					-- MAIN Logic here, example here is inserting dataset to eContactTranParticipant
					-- PRINT [dbo].[fnGetAllFieldNameInTable]('eContactTranParticipant', '', 'N', '', '', '')
                    INSERT  INTO dbo.[eContactTranParticipant]
                            ( RowID ,
                              wContactTranRid ,
                              wAgentCodeIn ,
                              wParticipated ,
                              wStatus ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy

                            )
                            SELECT
									-- PRINT [dbo].[fnGetAllFieldNameInTable]('eContactTranParticipant', '', 'N', '', 'Y', 's')
                                    RowID = s.RowID ,
                                    wContactTranRid = s.wContactTranRid ,
                                    wAgentCodeIn = s.wAgentCodeIn ,
                                    wParticipated = s.wParticipated ,
                                    wStatus = s.wStatus ,
                                    wCrtDt = dbo.fnUTC8Now() ,
                                    wCrtBy = s.wCrtBy ,
                                    wUpdDt = dbo.fnUTC8Now() ,
                                    wUpdBy = s.wUpdBy
                            FROM    #sDataSet_SetContactTranParticipant s;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  d
                        SET     -- PRINT [dbo].[fnGetAllFieldNameInTable]('eContactTranParticipant', '', 'N', '', 'Y', 'tmp')                                
                                wContactTranRid = tmp.wContactTranRid ,
                                wAgentCodeIn = tmp.wAgentCodeIn ,
                                wParticipated = tmp.wParticipated ,
                                wStatus = tmp.wStatus ,
                                wCrtDt = tmp.wCrtDt ,
                                wCrtBy = tmp.wCrtBy ,
                                wUpdDt = dbo.fnUTC8Now() ,
                                wUpdBy = tmp.wUpdBy
                        FROM    dbo.eContactTranParticipant AS d
                                INNER JOIN #sDataSet_SetContactTranParticipant tmp ON d.RowID = tmp.RowID
                        WHERE   d.RowID = tmp.RowID;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN						
                            UPDATE  d
                            SET     wStatus = 'T'
                            FROM    dbo.eContactTranParticipant d
                                    INNER JOIN #sDataSet_SetContactTranParticipant t ON d.RowID = t.RowID;
                        END;

            -- 【Calendar】-->【Mary】
            IF EXISTS (SELECT 1 FROM #sDataSet_SetContactTranParticipant WHERE ISNULL(RowID, 0) > 0) 
            BEGIN
                DECLARE c_ContactTranParticipant CURSOR FOR SELECT RowID FROM #sDataSet_SetContactTranParticipant WHERE ISNULL(RowID, 0) > 0;
                OPEN c_ContactTranParticipant;
                FETCH NEXT FROM c_ContactTranParticipant INTO @sRowID
                WHILE @@fetch_status = 0
                BEGIN
                    EXEC util.WriteMaryAgentActivitiesApiLog @pBookingRid = @sRowID, @pBookingType = 'eContactTranParticipant';

                    FETCH NEXT FROM c_ContactTranParticipant INTO @sRowID;
                END;
                CLOSE c_ContactTranParticipant;
                DEALLOCATE c_ContactTranParticipant;
            END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetContactTranParticipant;

        END TRY
        BEGIN CATCH
            DECLARE @sErrorNum INT ,
                @sCatchErrorMessage NVARCHAR(4000) ,
                @xstate INT ,
                @sProcedureName VARCHAR(100) ,
                @sRtnCodeLog INT ,
                @sErrMessageLog NVARCHAR(4000);
	        
            SET @sErrorNum = ERROR_NUMBER();
            SET @sCatchErrorMessage = ERROR_MESSAGE();
            SET @xstate = XACT_STATE();
            SET @sProcedureName = OBJECT_NAME(@@PROCID);
			
            IF ISNULL(@pErrCode, 0) = 0
                BEGIN
                    SET @pErrCode = 999;
                END;
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ', @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0
                BEGIN
                    IF @xstate != 0
                        ROLLBACK;
                    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;

        END CATCH;
	
        EXEC sp_xml_removedocument @sDocHandle;
        IF OBJECT_ID('tempdb..#sDataSet_SetContactTranParticipant') IS NOT NULL
            DROP TABLE #sDataSet_SetContactTranParticipant;
    END;