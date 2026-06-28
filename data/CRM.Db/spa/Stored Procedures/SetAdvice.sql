CREATE PROCEDURE [spa].[SetAdvice]
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
        DECLARE @sThisTableName VARCHAR(50) = 'eAdvice' , -- For RowID 
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
	        
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
        INTO    #sDataSet_SetAdvice
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
        WITH (
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eAdvice', '', 'Y', '', '', '')
            RowID BIGINT, 
            wAim NVARCHAR(200), 
            wDate DATE, 
            wAgentCodeIn VARCHAR(14), 
            wReceivedBy BIGINT, 
            wReceivedDeptCd VARCHAR(30), 
            wType VARCHAR(30), 
            wSubType VARCHAR(30), 
            wIsHighPriority CHAR(1), 
            wAdviceStatus VARCHAR(20), 
            wContent NVARCHAR(2000), 
            wStatus CHAR(1), 
            wCrtDt DATETIME2, 
            wCrtBy BIGINT, 
            wUpdDt DATETIME2, 
            wUpdBy BIGINT,
            wRefNo VARCHAR(30)
        );
	    
        BEGIN TRY		    
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF @pActionType = 'I'
                BEGIN
                    IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqeAdviceRefNo') AND type = 'SO') BEGIN
                                CREATE SEQUENCE seqeAdviceRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999
                            END

				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetAdvice
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetAdvice;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;

                            UPDATE  #sDataSet_SetAdvice
                            SET     RowID = @sRowID,
                                    wRefNo = 'AD' + FORMAT(NEXT VALUE FOR dbo.seqeAdviceRefNo, '0000000')
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eAdvice
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eAdvice', '', 'N', '', '', '')
                    INSERT  INTO dbo.eAdvice
                            ( RowID ,
                              wAim ,
                              wDate ,
                              wAgentCodeIn ,
                              wReceivedBy ,
                              wReceivedDeptCd ,
                              wType ,
                              wSubType ,
                              wIsHighPriority ,
                              wAdviceStatus ,
                              wContent ,
                              wStatus ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy ,
                              wRefNo ,
                              wDealDt
							)
                            SELECT
								-- PRINT [dbo].[fnGetAllFieldNameInTable]('eAdvice', '', 'N', '', 'Y', 's')
                                    RowID = s.RowID ,
                                    wAim = s.wAim ,
                                    wDate = s.wDate ,
                                    wAgentCodeIn = s.wAgentCodeIn ,
                                    wReceivedBy = s.wReceivedBy ,
                                    wReceivedDeptCd = s.wReceivedDeptCd ,
                                    wType = s.wType ,
                                    wSubType = s.wSubType ,
                                    wIsHighPriority = s.wIsHighPriority ,
                                    wAdviceStatus = s.wAdviceStatus ,
                                    wContent = s.wContent ,
                                    wStatus = s.wStatus ,
                                    wCrtDt = dbo.fnUTC8Now() ,
                                    wCrtBy = s.wUpdBy ,
                                    wUpdDt = dbo.fnUTC8Now() ,
                                    wUpdBy = s.wUpdBy,
                                    wRefNo=s.wRefNo,
                                    wDealDt = dbo.fnUTC8Now()
                            FROM    #sDataSet_SetAdvice s;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  d
                        SET     -- PRINT [dbo].[fnGetAllFieldNameInTable]('eAdvice', '', 'N', '', 'Y', 'tmp')                                
                                wAim = tmp.wAim ,
                                wDate = tmp.wDate ,
                                wAgentCodeIn = tmp.wAgentCodeIn ,
                                wReceivedBy = tmp.wReceivedBy ,
                                wReceivedDeptCd = tmp.wReceivedDeptCd ,
                                wType = tmp.wType ,
                                wSubType = tmp.wSubType ,
                                wIsHighPriority = tmp.wIsHighPriority ,
                                wAdviceStatus = tmp.wAdviceStatus ,
                                wContent = tmp.wContent ,
                                wStatus = tmp.wStatus ,
                                --wCrtDt = tmp.wCrtDt ,
                                --wCrtBy = tmp.wCrtBy ,
                                wUpdDt = dbo.fnUTC8Now() ,
                                wUpdBy = tmp.wUpdBy,
                                wRefNo=tmp.wRefNo,
                                wDealDt = IIF(d.wAdviceStatus = tmp.wAdviceStatus, d.wDealDt, dbo.fnUTC8Now()) -- 處理狀態沒有發生改變，處理日期不修改
                        FROM    dbo.eAdvice AS d
                                INNER JOIN #sDataSet_SetAdvice tmp ON d.RowID = tmp.RowID
                        WHERE   d.RowID = tmp.RowID;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN						
                            UPDATE  d
                            SET     wStatus = 'T',
                                    wDealDt = dbo.fnUTC8Now()
                            FROM    dbo.eAdvice d
                                    INNER JOIN #sDataSet_SetAdvice t ON d.RowID = t.RowID;
                        END;

            -- 2019-04-25：OP#28045，Write change Log
            -----------------------------------------------------------------------------------------
            DECLARE @vAdviceXML XML;
            SET @vAdviceXML = (SELECT RowID FROM #sDataSet_SetAdvice FOR XML RAW('Record'), ROOT('DataSet'));
            EXEC spa.SetAdviceChange @pAdviceXML     = @vAdviceXML,
                                     @pSendSunPeople = 'Y',
                                     @pErrCode       = @pErrCode OUTPUT,
                                     @pErrMsg        = @pErrMsg OUTPUT;
            -----------------------------------------------------------------------------------------
            

            -- 【Calendar】-->【Mary】
            -----------------------------------------------------------------------------------------
            IF EXISTS (SELECT 1 FROM #sDataSet_SetAdvice WHERE ISNULL(RowID, 0) > 0) 
            BEGIN
                DECLARE c_Advice CURSOR FOR SELECT RowID FROM #sDataSet_SetAdvice WHERE ISNULL(RowID, 0) > 0;
                OPEN c_Advice;
                FETCH NEXT FROM c_Advice INTO @sRowID
                WHILE @@fetch_status = 0
                BEGIN
                    EXEC util.WriteMaryAgentActivitiesApiLog @pBookingRid = @sRowID, @pBookingType = 'eAdvice';

                    FETCH NEXT FROM c_Advice INTO @sRowID;
                END;
                CLOSE c_Advice;
                DEALLOCATE c_Advice;
            END;
            -----------------------------------------------------------------------------------------

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetAdvice;

            RETURN;
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
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ',
                                  @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0
                BEGIN
                    IF @xstate != 0
                        ROLLBACK;
                    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo,
                        @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT,
                        @sErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;

        END CATCH;
	
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetAdvice') IS NOT NULL
            DROP TABLE #sDataSet_SetAdvice;
    END;