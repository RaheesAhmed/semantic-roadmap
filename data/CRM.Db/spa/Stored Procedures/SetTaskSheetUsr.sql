

CREATE PROCEDURE [spa].[SetTaskSheetUsr]
    (
      @pXML XML ,
      @pActionType CHAR(1) , --I/U/D
      @pMainCompNo INT ,
	  @pErrCode INT = 0 OUTPUT ,    
      @pErrMsg NVARCHAR(200) OUTPUT
    )
AS
    BEGIN
        SET NOCOUNT ON;

	    --SELECT * FROM eTaskSheetUsr;

        DECLARE @sThisTableName VARCHAR(50) = 'eTaskSheetUsr' ,
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );

        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ) ,*
        INTO #sDataSet_TaskSheetUsr
        FROM OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
			[RowID] BIGINT ,
			[wTaskSheetRid] BIGINT ,
			[wUsrRid] BIGINT ,
	        [wStatus] CHAR(1) ,
	        [wDeptCd] VARCHAR(30) ,
	        [wRemark] NVARCHAR(500),
	        [wCrtDt] DATETIME2(7) ,
	        [wCrtBy] BIGINT ,
	        [wUpdDt] DATETIME2(7) ,
	        [wUpdBy] BIGINT
		); 
			       
        BEGIN TRY	                
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
        		
            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE #sDataSet_TaskSheetUsr
                    SET RowID = 0;

                    SELECT  @sRecCount = COUNT(1)
                    FROM    #sDataSet_TaskSheetUsr;

                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
                            UPDATE #sDataSet_TaskSheetUsr
                            SET RowID = @sRowID
                            WHERE wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;	

                    INSERT INTO [dbo].[eTaskSheetUsr]
                        ( [RowID],
						  [wTaskSheetRid],
			              [wUsrRid],
	                      [wStatus],
	                      [wDeptCd],
	                      [wRemark],
	                      [wCrtDt],
	                      [wCrtBy],
	                      [wUpdDt],
	                      [wUpdBy]
				         )
                   SELECT [RowID],
						  [wTaskSheetRid],
			              [wUsrRid],
	                      [wStatus],
	                      [wDeptCd],
	                      [wRemark],
	                      dbo.fnUTC8Now(),
	                      [wCrtBy],
	                      dbo.fnUTC8Now(),
	                      [wUpdBy]
                   FROM #sDataSet_TaskSheetUsr;
                END;		
            ELSE IF @pActionType = 'U'
                BEGIN
                   UPDATE taskSheetUsr
                        SET taskSheetUsr.wDeptCd = tmp.wDeptCd ,
                            taskSheetUsr.wUsrRid = tmp.wUsrRid ,
							taskSheetUsr.wStatus = tmp.wStatus,
							taskSheetUsr.wRemark = tmp.wRemark,
                            taskSheetUsr.wUpdDt = dbo.fnUTC8Now() ,
                            taskSheetUsr.wUpdBy = tmp.wUpdBy 
                        FROM [dbo].[eTaskSheetUsr] taskSheetUsr
                             INNER JOIN #sDataSet_TaskSheetUsr tmp ON taskSheetUsr.RowID = tmp.RowID;
                END;
            ELSE IF @pActionType = 'D'
                BEGIN
                   UPDATE [dbo].[eTaskSheetUsr]
                   SET wStatus = 'T' ,
                       wUpdDt = dbo.fnUTC8Now()
                   WHERE RowID IN (SELECT RowID FROM #sDataSet_TaskSheetUsr );
                END;

            IF @sBeginTranCount = 0
                AND @@TRANCOUNT > 0
                BEGIN
                    COMMIT;
                END;

            RETURN;
        END TRY
        BEGIN CATCH
            DECLARE @sErrorNum INT ,
                @sCatchErrorMessage NVARCHAR(4000) ,
                @xState INT ,
                @sProcedureName VARCHAR(100) ,
                @sRtnCodeLog INT ,
                @sErrMessageLog NVARCHAR(4000);

            SELECT  @sErrorNum = ERROR_NUMBER() ,
                    @sCatchErrorMessage = ERROR_MESSAGE() ,
                    @xState = XACT_STATE() ,
                    @sProcedureName = OBJECT_NAME(@@PROCID);

            IF ISNULL(@pErrCode, 0) = 0
                BEGIN
                    SET @pErrCode = 999;
                END;

            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ',
                                  @sCatchErrorMessage);

            IF @sBeginTranCount = 0
                AND ( @xState = 1
                      OR @xState = -1
                    )
                BEGIN
			-- transaction created within this sp
                    ROLLBACK;
                END;

		-- Write Log
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName,
                @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH;

        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_TaskSheetUsr') IS NOT NULL
            DROP TABLE #sDataSet_TaskSheetUsr;
    END;