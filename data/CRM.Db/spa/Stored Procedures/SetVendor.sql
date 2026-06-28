
CREATE PROCEDURE [spa].[SetVendor]
    (
      @pXML XML ,      
	  @pMainCompNo INT ,
	  @pTestMode INT = 0, -- 0: Normal(Non-Test), 1: UnitTest, 2: Scenario Test
	  @pNonceToken VARCHAR(64) ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) OUTPUT
    )
AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

		-- dbml
		--declare @sRtnList table (
		--	RowID bigint not null
		--)
		--Select * from @sRtnList
		--return


        DECLARE @sThisTableName VARCHAR(50) = 'mVendor' ,
            @sBeginTranCount	INT = 0 ,
            @sDocHandle			INT,
            @sRecCount			INT = 0,
	        @sRuningIndex		INT = 1,
			@sRowID				BIGINT = 0,
			@sNow				DATETIME2 = dbo.fnUTC8Now();
        
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ) ,
                *
        INTO    #sDataSet_SetVendor FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
	WITH (
         RowID BIGINT, wCName NVARCHAR(100), wEName VARCHAR(100), wAddress NVARCHAR(500), wTel VARCHAR(100), wGracePeriod INT, wStatus CHAR(1), wCrtDt DATETIME2, wUpdDt DATETIME2, RecordState VARCHAR(1));        
        BEGIN TRY	                
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
        		
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetVendor WHERE   RecordState = 'I' )
                BEGIN
					-- Set RowID by Sequence
					UPDATE #sDataSet_SetVendor SET RowID = 0 WHERE RecordState = 'I';
					SELECT @sRecCount = COUNT(*) FROM #sDataSet_SetVendor

					WHILE @sRuningIndex <= @sRecCount BEGIN
						 IF EXISTS ( SELECT  1	FROM #sDataSet_SetVendor WHERE RecordState = 'I' AND wRowNum = @sRuningIndex)
							BEGIN
								EXEC spq.GetRowId @pMainCompNo, @sThisTableName, @sRowID OUTPUT
								UPDATE #sDataSet_SetVendor SET RowID = @sRowID WHERE wRowNum = @sRuningIndex
							END
						SET @sRuningIndex = @sRuningIndex + 1;
					END	

                    INSERT  INTO [dbo].[mVendor]
                            ( RowID, wCName, wEName, wAddress, wTel, wGracePeriod, wStatus, wCrtDt, wUpdDt)
                            SELECT RowID, wCName, wEName, wAddress, wTel, wGracePeriod, wStatus, @sNow, @sNow FROM #sDataSet_SetVendor WHERE   RecordState = 'I';
                END;
			
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetVendor WHERE RecordState = 'U' )
                BEGIN
                    UPDATE  v_t SET     wCName = tmp.wCName, wEName = tmp.wEName, wAddress = tmp.wAddress, wTel = tmp.wTel, wGracePeriod = tmp.wGracePeriod, wStatus = tmp.wStatus, wCrtDt = tmp.wCrtDt, wUpdDt = @sNow FROM [dbo].[mVendor] v_t INNER JOIN #sDataSet_SetVendor tmp ON v_t.RowID = tmp.RowID					
                    WHERE tmp.RecordState = 'U';
                END;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetVendor WHERE RecordState = 'D' )
                BEGIN			
                    UPDATE  v_t
                    SET     wStatus = 'T' ,
                            wUpdDt = @sNow
                    FROM    [dbo].[mVendor] v_t
                            INNER JOIN #sDataSet_SetVendor tmp ON v_t.RowID = tmp.RowID
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
            SELECT  RowID
            FROM #sDataSet_SetVendor;	
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
                    SET @pErrCode = 70001;
                END;

            SET @pErrMsg = CONCAT('(', @sErrorNum, ') ', @sCatchErrorMessage);

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
        IF OBJECT_ID('tempdb..#sDataSet_SetVendor') IS NOT NULL
            DROP TABLE #sDataSet_SetVendor;
    END;