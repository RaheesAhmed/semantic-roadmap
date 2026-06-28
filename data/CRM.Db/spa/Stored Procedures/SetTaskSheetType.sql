CREATE PROCEDURE [spa].[SetTaskSheetType]
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

		--SELECT TOP 1 CAST(1 AS BIGINT) wRowNum,* FROM dbo.mTaskSheetType;

        DECLARE @sThisTableName VARCHAR(50) = 'mTaskSheetType' , -- For RowID 
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
	        
        --DECLARE @sReturnRowID TABLE ( RowID BIGINT );
	    
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
	    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wDepartmentCode, wParentCode, wCode ) ,
                *
        INTO    #sDataSet_SetTaskSheetType
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('mTaskSheetType', '', 'Y', '', '', '')
			  wDepartmentCode VARCHAR(30), 
              wCode VARCHAR(30), 
              wParentCode VARCHAR(30), 
              wTitle NVARCHAR(100),
			  wStatus CHAR(1), 
              wCrtDt DATETIME2, 
              wCrtBy BIGINT, 
              wUpdDt DATETIME2, 
              wUpdBy BIGINT
			);
-- if parent is terminate, cannot access the child
        IF EXISTS ( SELECT  *
                    FROM    #sDataSet_SetTaskSheetType tmp
                            INNER JOIN mTaskSheetType t ON tmp.wParentCode = t.wCode
                                                           AND tmp.wParentCode <> ''
                                                           AND t.wStatus = 'T' )
            THROW 50001, 'Cannot modify the task sheet type if parent is terminated', 1;

		 --better don't put everything within try, for example
	     --getting mSysTable value
	     --getting currency, period, mCompany ...
	    
        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
	
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
                	                  
            --進行刪除操作或者中止要做checking 是否有使用的記錄 有就不给删除
            IF EXISTS( SELECT *  FROM #sDataSet_SetTaskSheetType ds
                                 INNER JOIN  dbo.eTaskSheet eT ON ds.wCode = eT.wTaskType OR ds.wCode = eT.wSubTaskType
                                 WHERE ds.wStatus = 'T')

               BEGIN                           
                   SET @pErrMsg=[dbo].[fnGetErrorMsg]('3008','zh-TW');
                   THROW 50001, '', 1;
               END;  

            IF @pActionType = 'I'
                BEGIN
                    IF EXISTS ( SELECT  1
                                FROM    dbo.mTaskSheetType AS ts
                                        INNER JOIN #sDataSet_SetTaskSheetType ds ON (ds.wDepartmentCode = ts.wDepartmentCode AND ds.wCode = ts.wCode) 
											OR (ds.wDepartmentCode = ts.wDepartmentCode AND ds.wParentCode = ts.wParentCode AND ds.wTitle = ts.wTitle)
							 )
                        THROW 50001, 'Code or Option name already exists', 1;
				-- Set RowID by Sequence
                    --UPDATE  #sDataSet_SetTaskSheetType
                    --SET     RowID = 0;
                    --SELECT  @sRecCount = COUNT(*)
                    --FROM    #sDataSet_SetTaskSheetType;
                    --WHILE @sRuningIndex <= @sRecCount
                    --    BEGIN
                    --        EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                    --            @sRowID OUTPUT;
					
                    --        UPDATE  #sDataSet_SetTaskSheetType
                    --        SET     RowID = @sRowID
                    --        WHERE   wRowNum = @sRuningIndex;
                    --        SET @sRuningIndex = @sRuningIndex + 1;
                    --    END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to mTaskSheetType
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('mTaskSheetType', '', 'N', '', '', '')
                    INSERT  INTO dbo.[mTaskSheetType]
                            ( wDepartmentCode ,
                              wCode ,
                              wParentCode ,
                              wTitle ,
                              wStatus ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy
                            )
                            SELECT
							-- PRINT [dbo].[fnGetAllFieldNameInTable]('mTaskSheetType', '', 'N', '', 'Y', 's')
                                    wDepartmentCode ,
                                    wCode ,
                                    wParentCode ,
                                    wTitle ,
                                    wStatus ,
                                    wCrtDt ,
                                    wCrtBy ,
                                    wUpdDt ,
                                    wUpdBy
                            FROM    #sDataSet_SetTaskSheetType s;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  d
                        SET     -- PRINT [dbo].[fnGetAllFieldNameInTable]('mTaskSheetType', '', 'N', '', 'Y', 'tmp')
                                wDepartmentCode = tmp.wDepartmentCode ,
                                wCode = tmp.wCode ,
                                wParentCode = tmp.wParentCode ,
                                wTitle = tmp.wTitle ,
                                wStatus = tmp.wStatus ,
                                wCrtDt = tmp.wCrtDt ,
                                wCrtBy = tmp.wCrtBy ,
                                wUpdDt = dbo.fnUTC8Now() ,
                                wUpdBy = tmp.wUpdBy
                        FROM    dbo.mTaskSheetType AS d
                                INNER JOIN #sDataSet_SetTaskSheetType tmp ON d.wDepartmentCode = tmp.wDepartmentCode
                                                                             AND d.wCode = tmp.wCode;

                        UPDATE  d
                        SET     wStatus = CASE WHEN t.wStatus = 'T' THEN 'T'
                                               ELSE d.wStatus
                                          END ,
                                d.wUpdDt = dbo.fnUTC8Now() ,
                                d.wUpdBy = t.wUpdBy
                        FROM    dbo.mTaskSheetType d
                                INNER JOIN #sDataSet_SetTaskSheetType t ON ( t.wParentCode = ''
                                                                             AND d.wParentCode = t.wCode
                                                                             AND d.wCode <> t.wCode
                                                                           )
                                                                           AND d.wStatus <> 'T';

                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN						
                            UPDATE  d
                            SET     wStatus = 'T' ,
                                    d.wUpdDt = dbo.fnUTC8Now() ,
                                    d.wUpdBy = t.wUpdBy
                            FROM    dbo.mTaskSheetType d
                                    INNER JOIN #sDataSet_SetTaskSheetType t ON d.wDepartmentCode = t.wDepartmentCode
                                                                               AND d.wCode = t.wCode
                                                                               OR ( t.wParentCode = ''
                                                                                    AND d.wParentCode = t.wCode
                                                                                  );
                        END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetTaskSheetType;

         
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

        IF OBJECT_ID('tempdb..#sDataSet_SetTaskSheetType') IS NOT NULL
            DROP TABLE #sDataSet_SetTaskSheetType;
    END;