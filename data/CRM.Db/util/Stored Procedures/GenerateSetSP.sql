CREATE PROCEDURE [util].[GenerateSetSP]
    @pTableName VARCHAR(50) ,
    @pCreate CHAR(1) -- 'Y'/'N' -> 'Y':Create Directly
AS /*
	EXEC [util].[GenerateSetSP] @pTableName='mWarehouse', @pCreate='Y'
*/
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;   

        DECLARE @sSQLString NVARCHAR(MAX) ,
            @sTableAlias VARCHAR(100) ,
            @sTempTableName VARCHAR(1000) ,
            @sFieldsString VARCHAR(MAX) ,
            @sFieldsAliasString VARCHAR(MAX) ,
            @sFieldsTypeString VARCHAR(MAX) ,
            @sFieldsUpdateString VARCHAR(MAX);

        WITH    CTE
                  AS ( SELECT   @pTableName AS oldVal ,
                                1 AS TotalLen ,
                                SUBSTRING(@pTableName, 1, 1) AS newVal ,
                                ASCII(SUBSTRING(@pTableName, 1, 1)) AS AsciVal
                       UNION ALL
                       SELECT   oldVal ,
                                TotalLen + 1 AS TotalLen ,
                                SUBSTRING(@pTableName, TotalLen + 1, 1) AS newVal ,
                                ASCII(SUBSTRING(@pTableName, TotalLen + 1, 1)) AS AsciVal
                       FROM     CTE
                       WHERE    CTE.TotalLen <= LEN(@pTableName)
                     )
            SELECT  @sTableAlias = ISNULL(@sTableAlias, '') + LOWER(newVal)
            FROM    CTE
                    INNER JOIN master..spt_values AS m ON CTE.AsciVal = m.number
                                                          AND CTE.AsciVal BETWEEN 65 AND 90;

        SET @sTableAlias = @sTableAlias + '_t';

        SET @sTempTableName = '#sDataSet_Set' + SUBSTRING(@pTableName, 2,
                                                          LEN(@pTableName) - 1);

        SET @sFieldsString = [dbo].[fnGetAllFieldNameInTable](@pTableName, '',
                                                              'N', 'N', 'N',
                                                              '');

        SET @sFieldsAliasString = [dbo].[fnGetAllFieldNameInTable](@pTableName,
                                                              @sTableAlias,
                                                              'N', '', '', '');

        SET @sFieldsTypeString = [dbo].[fnGetAllFieldNameInTable](@pTableName,
                                                              '', 'Y', 'N',
                                                              'N', '');

        SET @sFieldsUpdateString = REPLACE(REPLACE([dbo].[fnGetAllFieldNameInTable](@pTableName,
                                                              '', 'N', 'N',
                                                              'Y', 'tmp'),
                                                   'RowID = tmp.RowID, ', ''),
                                           'wUpdDt = tmp.wUpdDt',
                                           'wUpdDt = @sNow');

        SET @sSQLString = '
CREATE PROCEDURE [spa].[Set' + SUBSTRING(@pTableName, 2, LEN(@pTableName) - 1)
            + ']
    (
      @pXML XML ,      
	  @pMainCompNo INT ,
	  @pTestMode INT = 0, -- 0: Normal(Non-Test), 1: UnitTest, 2: Scenario Test
	  @pNonceToken VARCHAR(64) ,
	  @pReturnResultSet CHAR(1) = ''N'',
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) OUTPUT
    )
AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

		----------result set-----------
		--DECLARE @sResultSet TABLE (
		--  RowID  BIGINT
		--)     
		--SELECT * FROM @sResultSet; RETURN
		---------end result set--------

        DECLARE @sThisTableName VARCHAR(50) = ''' + @pTableName + ''' ,
            @sBeginTranCount	INT = 0 ,
            @sDocHandle			INT,
            @sRecCount			INT = 0,
	        @sRuningIndex		INT = 1,
			@sRowID				BIGINT = 0,
			@sNow				DATETIME2 = dbo.fnUTC8Now();
        
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '''';
    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ) ,
                *
        INTO    ' + @sTempTableName + '
        FROM    OPENXML (@sDocHandle, ''DataSet/Record'', 1)
		WITH (
         ' + @sFieldsTypeString + ', RecordState VARCHAR(1));        
        BEGIN TRY	                
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
        		
            IF EXISTS ( SELECT  1
                        FROM    ' + @sTempTableName + '
						WHERE   RecordState = ''I'' )
                BEGIN
					-- Set RowID by Sequence
					UPDATE ' + @sTempTableName + '
					SET RowID = 0 WHERE RecordState = ''I'';

					SELECT @sRecCount = COUNT(*) FROM ' + @sTempTableName + '

					WHILE @sRuningIndex <= @sRecCount BEGIN
						 IF EXISTS ( SELECT 1 FROM ' + @sTempTableName + '
									 WHERE RecordState = ''I'' AND wRowNum = @sRuningIndex)
							BEGIN
								EXEC spq.GetRowId @pMainCompNo, @sThisTableName, @sRowID OUTPUT
								UPDATE ' + @sTempTableName + '
								SET RowID = @sRowID WHERE wRowNum = @sRuningIndex
							END
						SET @sRuningIndex = @sRuningIndex + 1;
					END	

                    INSERT  INTO [dbo].[' + @pTableName + ']
                            ( ' + @sFieldsString + ')
                            SELECT ' + REPLACE(@sFieldsString,
                                               'wCrtDt, wUpdDt',
                                               '@sNow, @sNow') + ' FROM ' + @sTempTableName + '
							WHERE   RecordState = ''I'';
                END;
			
            IF EXISTS ( SELECT  1
                        FROM    ' + @sTempTableName + '
						WHERE RecordState = ''U'' )
                BEGIN
                    UPDATE ' + @sTableAlias + ' SET '
            + @sFieldsUpdateString + ' FROM [dbo].[' + @pTableName + '] '
            + @sTableAlias + ' INNER JOIN ' + @sTempTableName + ' tmp ON '
            + @sTableAlias + '.RowID = tmp.RowID					
                    WHERE tmp.RecordState = ''U'';
                END;

            IF EXISTS ( SELECT  1
                        FROM ' + @sTempTableName + '
						WHERE RecordState = ''D'' )
                BEGIN			
                    --;THROW 70002, ''Deleted operation is not allowed'', 1;
					UPDATE  ' + @sTableAlias + '
                    SET     wStatus = ''T'' ,
                            wUpdDt = @sNow
                    FROM    [dbo].[' + @pTableName + '] ' + @sTableAlias + '
                            INNER JOIN ' + @sTempTableName + ' tmp ON ' + @sTableAlias + '.RowID = tmp.RowID
                    WHERE   tmp.RecordState = ''D'';
                END;          

           IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    IF @pTestMode = 1
						ROLLBACK;
					ELSE
						COMMIT;
                END;

			-- Return RowID List
			IF @pReturnResultSet = ''Y''
			BEGIN
				SELECT  RowID
				FROM ' + @sTempTableName + ';
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
			SET @pErrCode = ERROR_NUMBER();
            SET @sCatchErrorMessage = ERROR_MESSAGE();
            SET @xstate = XACT_STATE();
            SET @sProcedureName = OBJECT_NAME(@@PROCID);
		
            IF ISNULL(@pErrCode, 0) = 0
                BEGIN
                    SET @pErrCode = 70001;
                END;

            SET @pErrMsg = CONCAT(''('', @sErrorNum, '') '', @sCatchErrorMessage);

            IF @sBeginTranCount = 0
                BEGIN
                    IF @xstate != 0
                        ROLLBACK;

                    -- Write Log
					EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName,
						@pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;             			
                              
        END CATCH;

        EXEC sp_xml_removedocument @sDocHandle;
        IF OBJECT_ID(''tempdb..' + @sTempTableName + ''') IS NOT NULL
            DROP TABLE ' + @sTempTableName + ';
    END;';

        IF @pCreate = 'Y'
            BEGIN	    	
                EXEC sp_executesql @sSQLString;
            END;

        PRINT CAST(@sSQLString AS NTEXT);
    END;