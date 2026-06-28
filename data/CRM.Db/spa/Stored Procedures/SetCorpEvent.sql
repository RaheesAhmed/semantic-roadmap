CREATE PROCEDURE [spa].[SetCorpEvent]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
	)
/* Test
DECLARE @vErrCode INT, @vErrMsg NVARCHAR(200)
EXEC spa.setcorpEvent 
	N'<DataSet><Record RowID="-1" wName="春茗" wCategory="EVENT" wSubCategory="" wStartDt="2017-01-01" wEndDt="2017-01-03" wIsCharged="Y" wRemark="測試" wGuestInvited="0" wGuestAttend="0" wStatus="A" wCrtDt="2017-02-20T00:00:00" wCrtBy="1" wUpdDt="2017-02-20T00:00:00" wUpdBy="1"/></DataSet>',
	'I', 99, '', @vErrCode, @vErrMsg
SELECT @vErrCode, @vErrMsg
*/
AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @vThisTableName VARCHAR(50) = 'eCorpEvent' , -- For RowID 
            @vBeginTranCount INT = 0 ,
            @vRecCount INT = 0 ,
            @vRuningIndex INT = 1 ,
            @vRowID BIGINT = 0 ,
            @vNow DATETIME2 ,
            @vDocHandle INT;
	        
        SET @vBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '' ,
                @vNow = dbo.fnUTC8Now();
	    
        -- dbml
		--declare @vRtnList table (
		--	RowID bigint not null
		--)
		--Select * from @vRtnList
		--return

        EXEC sp_xml_preparedocument @vDocHandle OUTPUT, @pXML;
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetCorpEvent
        FROM    OPENXML (@vDocHandle, 'DataSet/Record', 1)
		WITH (
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eCorpEvent', '', 'Y', '', '', '')
			RowID BIGINT, wName NVARCHAR(100), wCategory VARCHAR(30), wSubCategory VARCHAR(30),
			wStartDt DATETIME2, wEndDt DATETIME2,
			wIsCharged CHAR(1), wRemark NVARCHAR(500), wGuestInvited INT, wGuestAttend INT, wCfmGuestAttend INT,
			wStatus CHAR(1), wCrtDt DATETIME2, wCrtBy BIGINT, wUpdDt DATETIME2, wUpdBy BIGINT
		);

		 --better don't put everything within try, for example
	     --getting mSysTable value
	     --getting currency, period, mCompany ...
	    
        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
            IF @vBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetCorpEvent
                    SET     RowID = 0;
                    SELECT  @vRecCount = COUNT(*)
                    FROM    #sDataSet_SetCorpEvent;
                    WHILE @vRuningIndex <= @vRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @vThisTableName,
                                @vRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetCorpEvent
                            SET     RowID = @vRowID
                            WHERE   wRowNum = @vRuningIndex;
                            SET @vRuningIndex = @vRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eCorpEvent
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eCorpEvent', '', 'N', '', '', '')
                    INSERT  INTO dbo.[eCorpEvent]
                            ( RowID ,
                              wName ,
                              wCategory ,
                              wSubCategory ,
                              wIsCharged ,
                              wStartDt ,
                              wEndDt ,
                              wRemark ,
                              wGuestInvited ,
                              wGuestAttend ,
							  wCfmGuestAttend,
                              wStatus ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy
							)
                            SELECT
								-- PRINT [dbo].[fnGetAllFieldNameInTable]('eCorpEvent', '', 'N', '', 'Y', 's')
                                    RowID ,
                                    wName ,
                                    wCategory ,
                                    wSubCategory ,
                                    wIsCharged ,
                                    wStartDt ,
                                    wEndDt ,
                                    wRemark ,
                                    wGuestInvited ,
                                    wGuestAttend ,
									wCfmGuestAttend,
                                    wStatus ,
                                    @vNow ,
                                    wCrtBy ,
                                    @vNow ,
                                    wUpdBy
                            FROM    #sDataSet_SetCorpEvent s;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  d
                        SET     -- PRINT [dbo].[fnGetAllFieldNameInTable]('eCorpEvent', '', 'N', '', 'Y', 'tmp')							
                                wName = tmp.wName ,
                                wCategory = tmp.wCategory ,
                                wSubCategory = tmp.wSubCategory ,
                                wIsCharged = tmp.wIsCharged ,
                                wStartDt = tmp.wStartDt ,
                                wEndDt = tmp.wEndDt ,
                                wRemark = tmp.wRemark ,
                                wGuestInvited = tmp.wGuestInvited ,
                                wGuestAttend = tmp.wGuestAttend ,
								wCfmGuestAttend=tmp.wCfmGuestAttend,
                                wStatus = tmp.wStatus ,
                                wCrtDt = tmp.wCrtDt ,
                                wCrtBy = tmp.wCrtBy ,
                                wUpdDt = @vNow ,
                                wUpdBy = tmp.wUpdBy
                        FROM    dbo.eCorpEvent AS d
                                INNER JOIN #sDataSet_SetCorpEvent tmp ON d.RowID = tmp.RowID
                        WHERE   d.RowID = tmp.RowID;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN						
                            UPDATE  d
                            SET     wStatus = 'T'
                            FROM    dbo.eCorpEvent d
                                    INNER JOIN #sDataSet_SetCorpEvent t ON d.RowID = t.RowID;
                        END;

            IF @vBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetCorpEvent;

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
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @vErrorNum, ') ',
                                  @vCatchErrorMessage);
			
            IF @vBeginTranCount = 0
                BEGIN
                    IF @xstate != 0
                        ROLLBACK;
                    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo,
                        @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT,
                        @vErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;

        END CATCH;
	
        EXEC sp_xml_removedocument @vDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetCorpEvent') IS NOT NULL
            DROP TABLE #sDataSet_SetCorpEvent;
    END;