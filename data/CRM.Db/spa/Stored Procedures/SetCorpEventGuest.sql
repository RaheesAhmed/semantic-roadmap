CREATE PROCEDURE [spa].[SetCorpEventGuest]
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
EXEC [spa].[SetCorpEventGuest]
	N'<DataSet><Record RowID="-1" wCorpEventRid="1" wAgentCodeIn="1000010180" wGuestName="測試" wPersonRid="-1" wGuestInvited="5" wGuestAttend="3" wRemark="測試" wStatus="A" wCrtDt="2017-02-20T00:00:00" wCrtBy="1" wUpdDt="2017-02-20T00:00:00" wUpdBy="1"/></DataSet>',
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

        DECLARE @sThisTableName VARCHAR(50) = 'eCorpEventGuest' , -- For RowID 
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
			
        DECLARE @vXMLCorpEvent NVARCHAR(MAX) = '' ,
            @vXMLCorpEventAgent NVARCHAR(MAX) = '';
	        
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
	    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetCorpEventGuest
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eCorpEventGuest', '', 'Y', '', '', '')
			RowID BIGINT, wCorpEventRid BIGINT, wAgentCodeIn VARCHAR(14), wGuestName NVARCHAR(50), 
			wPersonRid BIGINT, wGuestInvited INT, wGuestAttend INT,wCfmGuestAttend INT, wRemark NVARCHAR(500), 
			wStatus CHAR(1), wCrtDt DATETIME2, wCrtBy BIGINT, wUpdDt DATETIME2, wUpdBy BIGINT

		);

		 --better don't put everything within try, for example
	     --getting mSysTable value
	     --getting currency, period, mCompany ...

		 -- Update wPersonRid if wGuestName is same with any
        UPDATE  ds
        SET     ds.wPersonRid = p.RowID
        FROM    #sDataSet_SetCorpEventGuest ds
                INNER JOIN dbo.mPerson p ON ds.wGuestName = p.wCName
                                            AND p.wStatus = 'A'
                                            AND p.wAgentCodeIn = ds.wAgentCodeIn;
	    
        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetCorpEventGuest
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetCorpEventGuest;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetCorpEventGuest
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eCorpEventGuest
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eCorpEventGuest', '', 'N', '', '', '')
                    INSERT  INTO dbo.[eCorpEventGuest]
                            ( RowID ,
                              wCorpEventRid ,
                              wAgentCodeIn ,
                              wGuestName ,
                              wPersonRid ,
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
								-- PRINT [dbo].[fnGetAllFieldNameInTable]('eCorpEventGuest', '', 'N', '', 'Y', 's')
                                    RowID ,
                                    wCorpEventRid ,
                                    wAgentCodeIn ,
                                    wGuestName ,
                                    wPersonRid ,
                                    wGuestInvited ,
                                    wGuestAttend ,
									wCfmGuestAttend,
                                    wRemark ,
                                    wStatus ,
                                    dbo.fnUTC8Now() ,
                                    wCrtBy ,
                                    dbo.fnUTC8Now() ,
                                    wUpdBy
                            FROM    #sDataSet_SetCorpEventGuest s;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  d
                        SET     -- PRINT [dbo].[fnGetAllFieldNameInTable]('eCorpEventGuest', '', 'N', '', 'Y', 'tmp')							
                                wCorpEventRid = tmp.wCorpEventRid ,
                                wAgentCodeIn = tmp.wAgentCodeIn ,
                                wGuestName = tmp.wGuestName ,
                                wPersonRid = tmp.wPersonRid ,
                                wGuestInvited = tmp.wGuestInvited ,
                                wGuestAttend = tmp.wGuestAttend ,
								wCfmGuestAttend=tmp.wCfmGuestAttend,
                                wRemark = tmp.wRemark ,
                                wStatus = tmp.wStatus ,
                                wCrtDt = tmp.wCrtDt ,
                                wCrtBy = tmp.wCrtBy ,
                                wUpdDt = dbo.fnUTC8Now() ,
                                wUpdBy = tmp.wUpdBy
                        FROM    dbo.eCorpEventGuest AS d
                                INNER JOIN #sDataSet_SetCorpEventGuest tmp ON d.RowID = tmp.RowID
                        WHERE   d.RowID = tmp.RowID;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN						
                            UPDATE  d
                            SET     wStatus = 'T'
                            FROM    dbo.eCorpEventGuest d
                                    INNER JOIN #sDataSet_SetCorpEventGuest t ON d.RowID = t.RowID;
                        END;
			-----------------------------------------------------------------------------------
			-- Update back the invited and attend guest in eCorpEvent & eCorpEventAgent tables
			-----------------------------------------------------------------------------------
            SELECT  ceg.wCorpEventRid ,
                    ceg.wAgentCodeIn ,
                    wGuestInvited = ISNULL(SUM(ceg.wGuestInvited), 0) ,
                    wGuestAttend = ISNULL(SUM(ceg.wGuestAttend), 0),
					wCfmGuestAttend=ISNULL(SUM(ceg.wCfmGuestAttend), 0)
            INTO    #tmpCountSummary
            FROM    eCorpEventGuest ceg
            WHERE   ceg.wCorpEventRid IN (
                    SELECT  wCorpEventRid
                    FROM    #sDataSet_SetCorpEventGuest )
                    AND ceg.wStatus = 'A'
            GROUP BY ceg.wCorpEventRid ,
                    ceg.wAgentCodeIn;

            SET @vXMLCorpEventAgent = ( SELECT 
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eCorpEventAgent', 'cea', 'N', '', '', '')
                                                cea.RowID ,
                                                cea.wCorpEventRid ,
                                                cea.wAgentCodeIn ,
                                                cea.wResponseType ,
                                                tmp.wGuestInvited ,
                                                tmp.wGuestAttend ,
												tmp.wCfmGuestAttend,
                                                cea.wRemark ,
                                                cea.wStatus ,
                                                cea.wCrtDt ,
                                                cea.wCrtBy ,
                                                cea.wUpdDt ,
                                                cea.wUpdBy
                                        FROM    eCorpEventAgent cea
                                                INNER JOIN #tmpCountSummary tmp ON cea.wCorpEventRid = tmp.wCorpEventRid
                                                              AND cea.wAgentCodeIn = tmp.wAgentCodeIn
                                      FOR
                                        XML RAW('Record') ,
                                            ROOT('DataSet')
                                      );

			-- PRINT @vXMLCorpEventAgent;
            EXEC spa.SetCorpEventAgent @vXMLCorpEventAgent, 'U', @pMainCompNo,
                @pNonceToken, 'N', @pErrCode, @pErrMsg;

            SET @vXMLCorpEvent = ( SELECT 
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eCorpEvent', 'ce', 'N', '', '', '')
                                            ce.RowID ,
                                            ce.wName ,
                                            ce.wCategory ,
                                            ce.wSubCategory ,
                                            ce.wStartDt ,
                                            ce.wEndDt ,
                                            ce.wIsCharged ,
                                            ce.wRemark ,
                                            wGuestInvited = ISNULL(SUM(tmp.wGuestInvited),
                                                              0) ,
                                            wGuestAttend = ISNULL(SUM(tmp.wGuestAttend),
                                                              0) ,
											wCfmGuestAttend = ISNULL(SUM(tmp.wCfmGuestAttend),
                                                              0) ,
                                            ce.wStatus ,
                                            ce.wCrtDt ,
                                            ce.wCrtBy ,
                                            ce.wUpdDt ,
                                            ce.wUpdBy
                                   FROM     eCorpEvent ce
                                            INNER JOIN #tmpCountSummary tmp ON ce.RowID = tmp.wCorpEventRid
                                   GROUP BY ce.RowID ,
                                            ce.wName ,
                                            ce.wCategory ,
                                            ce.wSubCategory ,
                                            ce.wStartDt ,
                                            ce.wEndDt ,
                                            ce.wIsCharged ,
                                            ce.wRemark ,
                                            ce.wStatus ,
                                            ce.wCrtDt ,
                                            ce.wCrtBy ,
                                            ce.wUpdDt ,
                                            ce.wUpdBy
                                 FOR
                                   XML RAW('Record') ,
                                       ROOT('DataSet')
                                 );
			
			--PRINT @vXMLCorpEvent;
            EXEC spa.SetCorpEvent @vXMLCorpEvent, 'U', @pMainCompNo,
                @pNonceToken, 'N', @pErrCode, @pErrMsg;
			-----------------------------------------------------------------------------------
			-- END Update back the invited and attend guest in eCorpEvent & eCorpEventAgent tables
			-----------------------------------------------------------------------------------

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetCorpEventGuest;
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

        IF OBJECT_ID('tempdb..#sDataSet_SetCorpEventGuest') IS NOT NULL
            DROP TABLE #sDataSet_SetCorpEventGuest;		
        IF OBJECT_ID('tempdb..#tmpCountSummary') IS NOT NULL
            DROP TABLE #tmpCountSummary;
    END;