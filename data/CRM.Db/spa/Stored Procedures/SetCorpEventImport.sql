CREATE PROCEDURE [spa].[SetCorpEventImport]
    (
      @pXML XML ,
      @pCorpEventRid BIGINT,
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
	)
AS 
    BEGIN
        SET NOCOUNT ON;
  --       --dbml
		--declare @sRtnList table (
		--	RowID bigint not null
		--)
		--Select * from @sRtnList
		--return

        DECLARE @sGuestTableName VARCHAR(50) = 'eCorpEventGuest' , -- For eCorpEventGuest RowID 
            @sAgentTableName VARCHAR(50) = 'eCorpEventAgent' , -- For eCorpEventAgent RowID 
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sAgentRecCount INT = 0 ,
            @sAgentRuningIndex INT = 1 ,
            @sAgentRowID BIGINT = 0 ,
            @sDocHandle INT;
			
        DECLARE @vXMLCorpEvent NVARCHAR(MAX) = '';
	        
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
	    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	     
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetCorpEventGuest
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
			RowID BIGINT, wCorpEventRid BIGINT, wAgentCodeIn VARCHAR(14), wGuestName NVARCHAR(50), 
			wPersonRid BIGINT, wGuestInvited INT, wGuestAttend INT,wCfmGuestAttend INT, --wRemark NVARCHAR(500), 
			wStatus CHAR(1), wCrtDt DATETIME2, wCrtBy BIGINT, wUpdDt DATETIME2, wUpdBy BIGINT
            );
       
        UPDATE  ds
        SET     ds.wCorpEventRid=ce.RowID,
                ds.wCrtBy=ce.wUpdBy,
                ds.wUpdBy=ce.wUpdBy,
                ds.wStatus='A'
        FROM    #sDataSet_SetCorpEventGuest ds
        INNER JOIN dbo.eCorpEvent ce ON ce.RowID=ds.wCorpEventRid;

		 -- Update wPersonRid if wGuestName is same with any
        UPDATE  ds
        SET     ds.wPersonRid = p.RowID,
                ds.wCorpEventRid=ce.RowID,
                ds.wCrtBy=ce.wUpdBy,
                ds.wUpdBy=ce.wUpdBy,
                ds.wStatus='A'
        FROM    #sDataSet_SetCorpEventGuest ds
        INNER JOIN dbo.eCorpEvent ce ON ce.RowID=ds.wCorpEventRid
        INNER JOIN dbo.mPerson p ON ds.wGuestName = p.wCName AND p.wStatus = 'A' AND p.wAgentCodeIn = ds.wAgentCodeIn;

        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
               
            BEGIN
                   DELETE FROM dbo.eCorpEventGuest
                   WHERE RowID IN(SELECT e.RowID FROM dbo.eCorpEventGuest e 
                                         INNER JOIN #sDataSet_SetCorpEventGuest s ON s.wCorpEventRid=e.wCorpEventRid AND s.wAgentCodeIn=e.wAgentCodeIn );

				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetCorpEventGuest
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetCorpEventGuest ;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sGuestTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetCorpEventGuest
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        

                    INSERT  INTO dbo.[eCorpEventGuest]
                            ( RowID ,
                              wCorpEventRid ,
                              wAgentCodeIn ,
                              wGuestName ,
                              wPersonRid ,
                              wGuestInvited ,
                              wGuestAttend ,
							  wCfmGuestAttend,
                              --wRemark ,
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
                                    --wRemark ,
                                    wStatus ,
                                    dbo.fnUTC8Now() ,
                                    wCrtBy ,
                                    dbo.fnUTC8Now() ,
                                    wUpdBy
                            FROM    #sDataSet_SetCorpEventGuest;

                    UPDATE  d
                    SET     -- PRINT [dbo].[fnGetAllFieldNameInTable]('eCorpEventGuest', '', 'N', '', 'Y', 'tmp')							
                            wCorpEventRid = tmp.wCorpEventRid ,
                            wAgentCodeIn = tmp.wAgentCodeIn ,
                            wGuestName = tmp.wGuestName ,
                            wPersonRid = tmp.wPersonRid ,
                            wGuestInvited = tmp.wGuestInvited ,
                            wGuestAttend = tmp.wGuestAttend ,
                    		wCfmGuestAttend=tmp.wCfmGuestAttend,
                            --wRemark = tmp.wRemark ,
                            wStatus = tmp.wStatus ,
                            wCrtBy = tmp.wCrtBy ,
                            wUpdDt = dbo.fnUTC8Now() ,
                            wUpdBy = tmp.wUpdBy
                    FROM    dbo.eCorpEventGuest AS d
                    INNER JOIN #sDataSet_SetCorpEventGuest tmp ON d.wAgentCodeIn = tmp.wAgentCodeIn AND d.wGuestName = tmp.wGuestName AND tmp.wCorpEventRid=d.wCorpEventRid;
                   
			-----------------------------------------------------------------------------------
			-- Update eCorpEventAgent tables
			-----------------------------------------------------------------------------------

                    CREATE TABLE #sDataSet_SetCorpEventAgent (
                        RowID BIGINT, 
                        wCorpEventRid BIGINT, 
                        wAgentCodeIn VARCHAR(14), 
                        wResponseType VARCHAR(30), 
                    	wGuestInvited INT, 
                        wGuestAttend INT,
                        wCfmGuestAttend INT, 
                        --wRemark NVARCHAR(500), 
                        wStatus CHAR(1), 
                    	wCrtDt DATETIME2, 
                        wCrtBy BIGINT, 
                        wUpdDt DATETIME2, 
                        wUpdBy BIGINT,
                        wRowNum INT
                        );
                   
                    INSERT INTO #sDataSet_SetCorpEventAgent
                           (wCorpEventRid,
                            wAgentCodeIn,
                            wGuestInvited,
                            wGuestAttend,
                            wCfmGuestAttend,
                            wRowNum
                           )
                           SELECT 
                                 ceg.wCorpEventRid ,
                                 ceg.wAgentCodeIn ,
                                 wGuestInvited = ISNULL(SUM(ceg.wGuestInvited), 0) ,
                                 wGuestAttend = ISNULL(SUM(ceg.wGuestAttend), 0),
                                 wCfmGuestAttend=ISNULL(SUM(ceg.wCfmGuestAttend), 0),
                                 ROW_NUMBER() OVER ( ORDER BY ceg.wCorpEventRid )
                           FROM  dbo.eCorpEventGuest ceg
                           WHERE ceg.wCorpEventRid =@pCorpEventRid
                               AND ceg.wAgentCodeIn NOT IN (SELECT  wAgentCodeIn FROM eCorpEventAgent WHERE wCorpEventRid  =@pCorpEventRid )
                               AND ceg.wStatus = 'A'
                           GROUP BY ceg.wCorpEventRid , ceg.wAgentCodeIn;
                   
                    UPDATE  ds
                    SET     ds.wResponseType='ATTEND',
                            ds.wStatus='A',
                            ds.wCorpEventRid=ce.RowID,
                            ds.wCrtBy=ce.wUpdBy,
                            ds.wUpdBy=ce.wUpdBy
                    FROM    #sDataSet_SetCorpEventAgent ds
                    INNER JOIN dbo.eCorpEvent ce ON ce.RowID=ds.wCorpEventRid;
                   
               
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetCorpEventAgent
                    SET     RowID = 0;
                    SELECT  @sAgentRecCount = COUNT(*)
                    FROM    #sDataSet_SetCorpEventAgent;
                    WHILE   @sAgentRuningIndex <= @sAgentRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sAgentTableName,
                                @sAgentRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetCorpEventAgent
                            SET     RowID = @sAgentRowID
                            WHERE   wRowNum = @sAgentRuningIndex;
                            SET @sAgentRuningIndex = @sAgentRuningIndex + 1;
                        END;    		        
				
                    INSERT  INTO dbo.[eCorpEventAgent]
                            ( RowID ,
                              wCorpEventRid ,
                              wAgentCodeIn ,
                              wResponseType ,
                              wGuestInvited ,
                              wGuestAttend ,
							  wCfmGuestAttend,
                              --wRemark ,
                              wStatus ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy
							)
                            SELECT 
                                    RowID ,
                                    wCorpEventRid ,
                                    wAgentCodeIn ,
                                    wResponseType,
                                    wGuestInvited ,
                                    wGuestAttend ,
									wCfmGuestAttend,
                                    --wRemark ,
                                    wStatus,
                                    dbo.fnUTC8Now() ,
                                    wCrtBy ,
                                    dbo.fnUTC8Now() ,
                                    wUpdBy
                            FROM    #sDataSet_SetCorpEventAgent;
                

            -----------------------------------------------------------------------------------
			-- Update back the invited and attend guest in eCorpEvent  tables
			-----------------------------------------------------------------------------------

            SELECT  ceg.wCorpEventRid ,
                    ceg.wAgentCodeIn ,
                    wGuestInvited = ISNULL(SUM(ceg.wGuestInvited), 0) ,
                    wGuestAttend = ISNULL(SUM(ceg.wGuestAttend), 0),
					wCfmGuestAttend=ISNULL(SUM(ceg.wCfmGuestAttend), 0)
            INTO    #tmpCountSummary
            FROM    eCorpEventGuest ceg
            WHERE   ceg.wCorpEventRid IN ( SELECT  wCorpEventRid FROM #sDataSet_SetCorpEventGuest ) 
                AND ceg.wStatus = 'A'
            GROUP BY ceg.wCorpEventRid , ceg.wAgentCodeIn;

            UPDATE  cea
            SET     cea.wResponseType='ATTEND',
                    cea.wStatus='A',
                    cea.wGuestInvited=tmp.wGuestInvited,
                    cea.wGuestAttend=tmp.wGuestAttend,
                    cea.wCfmGuestAttend=tmp.wCfmGuestAttend
            FROM    dbo.eCorpEventAgent cea
            INNER JOIN #tmpCountSummary tmp ON cea.wCorpEventRid = tmp.wCorpEventRid AND cea.wAgentCodeIn = tmp.wAgentCodeIn
            INNER JOIN #sDataSet_SetCorpEventGuest ceg ON ceg.wCorpEventRid = tmp.wCorpEventRid AND ceg.wAgentCodeIn = tmp.wAgentCodeIn;

            SET @vXMLCorpEvent = ( SELECT 
                                            ce.RowID ,
                                            ce.wName ,
                                            ce.wCategory ,
                                            ce.wSubCategory ,
                                            ce.wStartDt ,
                                            ce.wEndDt ,
                                            ce.wIsCharged ,
                                            ce.wRemark ,
                                            wGuestInvited = ISNULL(SUM(tmp.wGuestInvited),0) ,
                                            wGuestAttend = ISNULL(SUM(tmp.wGuestAttend),0) ,
											wCfmGuestAttend = ISNULL(SUM(tmp.wCfmGuestAttend),0) ,
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
            EXEC spa.SetCorpEvent @vXMLCorpEvent, 'U', @pMainCompNo, @pNonceToken, 'N', @pErrCode, @pErrMsg;

			-----------------------------------------------------------------------------------
			-- END Update back the invited and attend guest in eCorpEvent & eCorpEventAgent tables
			-----------------------------------------------------------------------------------
             END;
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

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
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ',  @sCatchErrorMessage);
			
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
        IF OBJECT_ID('tempdb..#sDataSet_SetCorpEventAgent') IS NOT NULL
            DROP TABLE #sDataSet_SetCorpEventAgent;	
        IF OBJECT_ID('tempdb..#tmpCountSummary') IS NOT NULL
            DROP TABLE #tmpCountSummary;
        
    END;