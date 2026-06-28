CREATE PROCEDURE [spa].[SetCorpEventAgent]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
	)
AS /* Test 
DECLARE @vErrCode INT, @vErrMsg NVARCHAR(200)
EXEC [spa].[SetCorpEventAgent]
	N'<DataSet><Record RowID="-1" wCorpEventRid="1" wAgentCodeIn="1000010180" wResponseType="ATTEND" wGuestInvited="0" wGuestAttend="0" wRemark="測試" wStatus="A" wCrtDt="2017-02-20T00:00:00" wCrtBy="1" wUpdDt="2017-02-20T00:00:00" wUpdBy="1"/></DataSet>',
	'I', 99, '', @vErrCode, @vErrMsg
SELECT @vErrCode, @vErrMsg
*/
    BEGIN
        SET NOCOUNT ON;
		-- dbml
		--declare @sRtnList table (
		--	RowID bigint not null
		--)
		--Select * from @sRtnList
		--return

        DECLARE @sThisTableName VARCHAR(50) = 'eCorpEventAgent' , -- For RowID 
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT ,
            @vXMLUpdateGuest NVARCHAR(MAX) = N'';
			
	        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
	        
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
	    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetCorpEventAgent
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eCorpEventAgent', '', 'Y', '', '', '')
			RowID BIGINT, wCorpEventRid BIGINT, wAgentCodeIn VARCHAR(14), wResponseType VARCHAR(30), 
			wGuestInvited INT, wGuestAttend INT,wCfmGuestAttend INT, wRemark NVARCHAR(500), wStatus CHAR(1), 
			wCrtDt DATETIME2, wCrtBy BIGINT, wUpdDt DATETIME2, wUpdBy BIGINT
		);

		 --better don't put everything within try, for example
	     --getting mSysTable value
	     --getting currency, period, mCompany ...
	    
        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
			-- Check Agent exists or not
            IF @pActionType = 'I'
                AND EXISTS ( SELECT 1
                             FROM   dbo.eCorpEventAgent cea
                                    INNER JOIN #sDataSet_SetCorpEventAgent tmp ON cea.wCorpEventRid = tmp.wCorpEventRid
                                                              AND tmp.wAgentCodeIn = cea.wAgentCodeIn )
                BEGIN
                    THROW 50001, 'Agent already exists, cannot insert duplicate agent for the same event', 1;
                END;

            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetCorpEventAgent
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetCorpEventAgent;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetCorpEventAgent
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eCorpEventAgent
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eCorpEventAgent', '', 'N', '', '', '')
                    INSERT  INTO dbo.[eCorpEventAgent]
                            ( RowID ,
                              wCorpEventRid ,
                              wAgentCodeIn ,
                              wResponseType ,
                              wGuestInvited ,
                              wGuestAttend ,
							  wCfmGuestAttend,
                              wRemark ,
                              wStatus ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy
							)
                            SELECT
								-- PRINT [dbo].[fnGetAllFieldNameInTable]('eCorpEventAgent', '', 'N', '', 'Y', 's')
                                    RowID ,
                                    wCorpEventRid ,
                                    wAgentCodeIn ,
                                    wResponseType ,
                                    wGuestInvited ,
                                    wGuestAttend ,
									wCfmGuestAttend,
                                    wRemark ,
                                    wStatus ,
                                    dbo.fnUTC8Now() ,
                                    wCrtBy ,
                                    dbo.fnUTC8Now() ,
                                    wUpdBy
                            FROM    #sDataSet_SetCorpEventAgent s;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  d
                        SET     -- PRINT [dbo].[fnGetAllFieldNameInTable]('eCorpEventAgent', '', 'N', '', 'Y', 'tmp')							
                                wCorpEventRid = tmp.wCorpEventRid ,
                                wAgentCodeIn = tmp.wAgentCodeIn ,
                                wResponseType = tmp.wResponseType ,
                                wGuestInvited = tmp.wGuestInvited ,
                                wGuestAttend = tmp.wGuestAttend ,
								wCfmGuestAttend=tmp.wCfmGuestAttend,
                                wRemark = tmp.wRemark ,
                                wStatus = tmp.wStatus ,
                                wCrtDt = tmp.wCrtDt ,
                                wCrtBy = tmp.wCrtBy ,
                                wUpdDt = dbo.fnUTC8Now() ,
                                wUpdBy = tmp.wUpdBy
                        FROM    dbo.eCorpEventAgent AS d
                                INNER JOIN #sDataSet_SetCorpEventAgent tmp ON d.RowID = tmp.RowID
                        WHERE   d.RowID = tmp.RowID AND d.RowID >0;

						--當代理邀請名單的回復不等於參加時，要更新貴賓名單的確認出席人數為0
						UPDATE  ceg
                        SET     
								wCfmGuestAttend=0
                        FROM    dbo.eCorpEventGuest ceg
                                INNER JOIN #sDataSet_SetCorpEventAgent t ON ceg.wCorpEventRid = t.wCorpEventRid
                                AND ceg.wAgentCodeIn = t.wAgentCodeIn
						WHERE t.wResponseType='-1' OR t.wResponseType='ABSENT'

                        --更新節目管理列表上的確認出席人數
                        SELECT  ceg.wCorpEventRid ,
                                wGuestInvited = ISNULL(SUM(ceg.wGuestInvited), 0) ,
                                wGuestAttend = ISNULL(SUM(ceg.wGuestAttend), 0),
                        		wCfmGuestAttend=ISNULL(SUM(ceg.wCfmGuestAttend), 0)
                        INTO    #tmpCountSummary
                        FROM    eCorpEventGuest ceg
                        WHERE   ceg.wCorpEventRid IN (
                                SELECT  wCorpEventRid
                                FROM    #sDataSet_SetCorpEventAgent )
                                AND ceg.wStatus = 'A'
                        GROUP BY ceg.wCorpEventRid ;

                        UPDATE ce
                        SET wGuestInvited = tmp.wGuestInvited,
                            wGuestAttend = tmp.wGuestAttend ,
                        	wCfmGuestAttend = tmp.wCfmGuestAttend
                        FROM eCorpEvent ce
                        INNER JOIN #tmpCountSummary tmp ON ce.RowID = tmp.wCorpEventRid

                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN						
                            UPDATE  d
                            SET     wStatus = 'T'
                            FROM    dbo.eCorpEventAgent d
                                    INNER JOIN #sDataSet_SetCorpEventAgent t ON d.RowID = t.RowID;

							-- UPDATE Guest Status Also
                            SELECT  @vXMLUpdateGuest = ( SELECT
                                                              ceg.RowID ,
                                                              ceg.wCorpEventRid ,
                                                              ceg.wAgentCodeIn ,
                                                              ceg.wGuestName ,
                                                              ceg.wPersonRid ,
                                                              ceg.wGuestInvited ,
                                                              ceg.wGuestAttend ,
															  ceg.wCfmGuestAttend,
                                                              ceg.wRemark ,
                                                              wStatus = 'T' ,
                                                              ceg.wCrtDt ,
                                                              ceg.wCrtBy ,
                                                              ceg.wUpdDt ,
                                                              ceg.wUpdBy
                                                         FROM dbo.eCorpEventGuest ceg
                                                              INNER JOIN #sDataSet_SetCorpEventAgent t ON ceg.wCorpEventRid = t.wCorpEventRid
                                                              AND ceg.wAgentCodeIn = t.wAgentCodeIn
                                                         WHERE
                                                              ceg.wStatus = 'A'
                                                       FOR
                                                         XML RAW('Record') ,
                                                             ROOT('DataSet')
                                                       );
							
                            EXEC [spa].[SetCorpEventGuest] @vXMLUpdateGuest,
                                'D', @pMainCompNo, @pNonceToken, 'N',
                                @pErrCode, @pErrMsg;
                        END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetCorpEventAgent;

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
        IF OBJECT_ID('tempdb..#sDataSet_SetCorpEventAgent') IS NOT NULL
            DROP TABLE #sDataSet_SetCorpEventAgent;
        IF OBJECT_ID('tempdb..#tmpCountSummary') IS NOT NULL
            DROP TABLE #tmpCountSummary;
    END;