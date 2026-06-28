CREATE PROCEDURE [spa].[SetActionAffectedTableLog]
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
-- wActionSp VARCHAR(100), wActionType CHAR(1), wNonceToken VARCHAR(40), wRefTableName VARCHAR(100), wRefRid BIGINT, wType VARCHAR(50), wCrtDt DATETIME2
DECLARE @vErrCode INT, @vErrMsg NVARCHAR(200)
EXEC spa.SetActionAffectedTableLog 
	N'<DataSet><Record wActionSp="Test" wActionType="I" wNonceToken="1234-1234-1234-1234-1234-1234" wRefTableName="eTest" wRefRid="1" wType="SMS_NEW" wCrtDt="2017-02-20T00:00:00" wCrtBy="1" wUpdDt="2017-02-20T00:00:00" wUpdBy="1"/></DataSet>',	'I', 99, '', @


vErrCode, @vErrMsg
SELECT @vErrCode, @vErrMsg
SELECT * FROM eActionAffectedTableLog
*/
AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @sThisTableName VARCHAR(50) = 'eActionAffectedTableLog' , -- For RowID 
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
	        
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0, @pErrMsg = '';
	    
        -- dbml
		--declare @sRtnList table (
		--	RowID bigint not null
		--)
		--Select * from @sRtnList
		--return

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wCrtDt ) ,
                *
        INTO    #sDataSet_SetActionAffectedTableLog
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eActionAffectedTableLog', '', 'Y', '', '', '')
			wActionSp VARCHAR(100), wActionType CHAR(1), wNonceToken VARCHAR(40), wRefTableName VARCHAR(100), wRefRid BIGINT, wType VARCHAR(50), wCrtDt DATETIME2
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
				
				-- MAIN Logic here, example here is inserting dataset to eActionAffectedTableLog
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eActionAffectedTableLog', '', 'N', '', '', '')
                    INSERT  INTO dbo.eActionAffectedTableLog
                            ( wActionSp, wActionType, wNonceToken, wRefTableName, wRefRid, wType, wCrtDt )
                            SELECT
								-- PRINT [dbo].[fnGetAllFieldNameInTable]('eActionAffectedTableLog', '', 'N', '', 'Y', 's')
                                    wActionSp = ISNULL(s.wActionSp,''), wActionType = s.wActionType, wNonceToken = ISNULL(s.wNonceToken,''), wRefTableName = s.wRefTableName, wRefRid = s.wRefRid, wType = s.wType, 
                                    wCrtDt = dbo.fnUTC8Now()
                            FROM    #sDataSet_SetActionAffectedTableLog s;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  d
                        SET     -- PRINT [dbo].[fnGetAllFieldNameInTable]('eActionAffectedTableLog', '', 'N', '', 'Y', 'tmp')                                
                                wActionSp = ISNULL(tmp.wActionSpm,''), wActionType = tmp.wActionType, wNonceToken = ISNULL(tmp.wNonceToken,''), wRefTableName = tmp.wRefTableName, wRefRid = tmp.wRefRid, wType = tmp.wType, wCrtDt = tmp.wCrtDt
                        FROM    dbo.eActionAffectedTableLog AS d
                                INNER JOIN #sDataSet_SetActionAffectedTableLog tmp ON d.RowID = tmp.RowID
                        WHERE   d.RowID = tmp.RowID;
                END;
              --ELSE
                --    IF @pActionType = 'D'
                --        BEGIN						
                --            UPDATE  d
                --            SET     wStatus = 'T'
                --            FROM    dbo.eActionAffectedTableLog d
                --                    INNER JOIN #sDataSet_SetActionAffectedTableLog t ON d.RowID = t.RowID;
                --        END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  *
                FROM    #sDataSet_SetActionAffectedTableLog;

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

        IF OBJECT_ID('tempdb..#sDataSet_SetActionAffectedTableLog') IS NOT NULL
            DROP TABLE #sDataSet_SetActionAffectedTableLog;
    END;