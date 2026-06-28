
CREATE PROCEDURE [spa].[SetItem]
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

        DECLARE @sThisTableName VARCHAR(50) = 'mItem' ,
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
        INTO    #sDataSet_SetItem FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
	    WITH (
           RowID BIGINT, 
           wCategoryRid BIGINT, 
           wCName NVARCHAR(100), 
           wEName VARCHAR(100), 
           wPrice DECIMAL, 
           wCurrCode VARCHAR(3), 
           wBarcode VARCHAR(1000), 
           wIsSerialItem CHAR(1), 
           wStatus CHAR(1), 
           wCrtDt DATETIME2, 
           wUpdDt DATETIME2, 
           RecordState VARCHAR(1)
        );        
        BEGIN TRY	                
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
        	           
            --進行刪除操作或者中止要做checking 是否有使用的記錄 有就不给删除
            IF EXISTS ( SELECT * FROM #sDataSet_SetItem WHERE wStatus='T')
            BEGIN
              DECLARE @sTable TABLE( wTableIndex BIGINT IDENTITY(1,1) PRIMARY KEY, wTableName VARCHAR(30));
              DECLARE @sTableIndex INT = 0;
              DECLARE @sTableName VARCHAR(30);
              DECLARE @sErrMsg NVARCHAR(MAX);
              DECLARE @sSql NVARCHAR(MAX);

              INSERT INTO @sTable (wTableName) VALUES
               ('dbo.ePurchaseDtl'),
               ('dbo.eStockMovementDtl'),
               ('dbo.eStockAdjustmentDtl'),
               ('dbo.eStockSalesDtl');            
              
              SELECT @sTableIndex = COUNT(1) FROM @sTable;

              WHILE @sTableIndex > 0
              BEGIN
                SELECT @sTableName = wTableName FROM @sTable WHERE wTableIndex = @sTableIndex;

                SET @sSql = CONCAT('SELECT TOP(1) @sErrMsg = dbo.fnGetErrorMsg(''3004'',''zh-TW'') FROM #sDataSet_SetItem AS ds INNER JOIN ',  @sTableName, ' AS stock ON stock.wItemRid =  ds.RowID ');

                EXEC sp_executesql @sSql, N'@sErrMsg NVARCHAR(MAX) OUTPUT' , @sErrMsg = @sErrMsg OUTPUT   
                
                IF ISNULL(@sErrMsg, '') <> ''
                BEGIN
                    SET @pErrMsg=dbo.fnGetErrorMsg('3004','zh-TW');
                   THROW 70002, @pErrMsg, 1;
                END;

                SET @sTableIndex = @sTableIndex -1;
              END
            END


            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetItem WHERE   RecordState = 'I' )
                BEGIN
					-- Set RowID by Sequence
					UPDATE #sDataSet_SetItem SET RowID = 0 WHERE RecordState = 'I';
					SELECT @sRecCount = COUNT(*) FROM #sDataSet_SetItem

					WHILE @sRuningIndex <= @sRecCount BEGIN
						 IF EXISTS ( SELECT  1	FROM #sDataSet_SetItem WHERE RecordState = 'I' AND wRowNum = @sRuningIndex)
							BEGIN
								EXEC spq.GetRowId @pMainCompNo, @sThisTableName, @sRowID OUTPUT
								UPDATE #sDataSet_SetItem SET RowID = @sRowID WHERE wRowNum = @sRuningIndex
							END
						SET @sRuningIndex = @sRuningIndex + 1;
					END	

                    INSERT  INTO [dbo].[mItem]
                            ( RowID, wCategoryRid, wCName, wEName, wPrice, wCurrCode, wBarcode, wIsSerialItem, wStatus, wCrtDt, wUpdDt)
                            SELECT RowID, wCategoryRid, wCName, wEName, wPrice, wCurrCode, wBarcode, wIsSerialItem, wStatus, @sNow, @sNow FROM #sDataSet_SetItem WHERE   RecordState = 'I';
                END;
			
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetItem WHERE RecordState = 'U' )
                BEGIN
                    UPDATE  i_t SET     wCategoryRid = tmp.wCategoryRid, wCName = tmp.wCName, wEName = tmp.wEName, wPrice = tmp.wPrice, wCurrCode = tmp.wCurrCode, wBarcode = tmp.wBarcode, wIsSerialItem = tmp.wIsSerialItem, wStatus = tmp.wStatus, wCrtDt = tmp.wCrtDt, wUpdDt = @sNow FROM [dbo].[mItem] i_t INNER JOIN #sDataSet_SetItem tmp ON i_t.RowID = tmp.RowID					
                    WHERE tmp.RecordState = 'U';
                END;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetItem WHERE RecordState = 'D' )
                BEGIN			
                    UPDATE  i_t
                    SET     wStatus = 'T' ,
                            wUpdDt = @sNow
                    FROM    [dbo].[mItem] i_t
                            INNER JOIN #sDataSet_SetItem tmp ON i_t.RowID = tmp.RowID
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
            FROM #sDataSet_SetItem;	
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
					EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName,
						@pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;             			
                              
        END CATCH;

        EXEC sp_xml_removedocument @sDocHandle;
        IF OBJECT_ID('tempdb..#sDataSet_SetItem') IS NOT NULL
            DROP TABLE #sDataSet_SetItem;
    END;