
CREATE PROCEDURE [spa].[SetCustomQuery]
    (
      @pXML XML ,
      @pMainCompNo INT ,
      @pTestMode INT = 0 , -- 0: Normal(Non-Test), 1: UnitTest, 2: Scenario Test
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
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

        DECLARE @sThisTableName VARCHAR(50) = 'mCustomQuery' ,
            @sBeginTranCount INT = 0 ,
            @sDocHandle INT ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sNow DATETIME2 = dbo.fnUTC8Now();
        
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ) ,
                *
        INTO    #sDataSet_SetCustomQuery
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
         RowID BIGINT, wQueryCd VARCHAR(50), wQueryName NVARCHAR(50), wQueryCategory VARCHAR(30), wStatus CHAR(1), wCrtBy BIGINT, wCrtDt DATETIME2, wUpdBy BIGINT, wUpdDt DATETIME2, RecordState VARCHAR(1));        
        BEGIN TRY	                
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
        		
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetCustomQuery
                        WHERE   RecordState = 'I' )
                BEGIN
					-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetCustomQuery
                    SET     RowID = 0
                    WHERE   RecordState = 'I';

                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetCustomQuery;

                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            IF EXISTS ( SELECT  1
                                        FROM    #sDataSet_SetCustomQuery
                                        WHERE   RecordState = 'I'
                                                AND wRowNum = @sRuningIndex )
                                BEGIN
                                    EXEC spq.GetRowID @pMainCompNo,
                                        @sThisTableName, @sRowID OUTPUT;
                                    UPDATE  #sDataSet_SetCustomQuery
                                    SET     RowID = @sRowID
                                    WHERE   wRowNum = @sRuningIndex;
                                END;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;	

                    INSERT  INTO [dbo].[mCustomQuery]
                            ( RowID ,
                              wQueryCategory ,
                              wQueryCd ,
                              wQueryName ,                              
                              wStatus ,
                              wCrtBy ,
                              wCrtDt ,
                              wUpdBy ,
                              wUpdDt
                            )
                            SELECT  RowID ,
                                    wQueryCategory ,
                                    wQueryCd ,
                                    wQueryName ,                                    
                                    wStatus ,
                                    wCrtBy ,
                                    wCrtDt ,
                                    wUpdBy ,
                                    wUpdDt
                            FROM    #sDataSet_SetCustomQuery
                            WHERE   RecordState = 'I';
                END;
			
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetCustomQuery
                        WHERE   RecordState = 'U' )
                BEGIN
                    UPDATE  cq_t
                    SET     wQueryCategory = tmp.wQueryCategory ,
                            wQueryCd = tmp.wQueryCd ,
                            wQueryName = tmp.wQueryName ,                            
                            wStatus = tmp.wStatus ,
                            wCrtBy = tmp.wCrtBy ,
                            wCrtDt = tmp.wCrtDt ,
                            wUpdBy = tmp.wUpdBy ,
                            wUpdDt = @sNow
                    FROM    [dbo].[mCustomQuery] cq_t
                            INNER JOIN #sDataSet_SetCustomQuery tmp ON cq_t.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'U';
                END;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetCustomQuery
                        WHERE   RecordState = 'D' )
                BEGIN			
                    --;THROW 70002, 'Deleted operation is not allowed', 1;
                    UPDATE  cq_t
                    SET     wStatus = 'T' ,
                            wUpdDt = @sNow
                    FROM    [dbo].[mCustomQuery] cq_t
                            INNER JOIN #sDataSet_SetCustomQuery tmp ON cq_t.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'D';
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
            IF @pReturnResultSet = 'Y'
                BEGIN
                    SELECT  RowID
                    FROM    #sDataSet_SetCustomQuery;
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

            SET @pErrMsg = CONCAT('(', @sErrorNum, ') ', @sCatchErrorMessage);

            IF @sBeginTranCount = 0
                BEGIN
                    IF @xstate != 0
                        ROLLBACK;

                    -- Write Log
                    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo,
                        @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT,
                        @sErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;             			
                              
        END CATCH;

        EXEC sp_xml_removedocument @sDocHandle;
        IF OBJECT_ID('tempdb..#sDataSet_SetCustomQuery') IS NOT NULL
            DROP TABLE #sDataSet_SetCustomQuery;
    END;