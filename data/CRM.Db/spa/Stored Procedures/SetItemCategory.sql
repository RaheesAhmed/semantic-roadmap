
CREATE PROCEDURE [spa].[SetItemCategory]
    (
      @pXML XML ,
      @pMainCompNo INT ,
      @pTestMode INT = 0 , -- 0: Normal(Non-Test), 1: UnitTest, 2: Scenario Test
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

        DECLARE @sThisTableName VARCHAR(50) = 'mItemCategory' ,
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
        INTO    #sDataSet_SetItemCategory
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
	WITH (
           RowID BIGINT, 
           wCName NVARCHAR(100), 
           wEName VARCHAR(100), 
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
        		
             --進行刪除操作要做checking 是否有使用的記錄 有就不给删除
            IF  EXISTS ( SELECT * FROM #sDataSet_SetItemCategory WHERE wStatus='T') AND
                (
                    EXISTS ( SELECT * FROM #sDataSet_SetItemCategory ds
                             INNER JOIN dbo.mItem item ON ds.RowID = item.wCategoryRid
                             INNER JOIN dbo.ePurchaseDtl purchase ON purchase.wItemRid = item.RowID
                            ) OR
                    EXISTS ( SELECT * FROM #sDataSet_SetItemCategory ds
                             INNER JOIN dbo.mItem item ON ds.RowID = item.wCategoryRid
                             INNER JOIN dbo.eStockMovementDtl movement ON movement.wItemRid = item.RowID
                            ) OR
                    EXISTS ( SELECT * FROM #sDataSet_SetItemCategory ds
                             INNER JOIN dbo.mItem item ON ds.RowID = item.wCategoryRid
                             INNER JOIN dbo.eStockAdjustmentDtl adjust ON adjust.wItemRid = item.RowID
                            ) OR
                     EXISTS ( SELECT * FROM #sDataSet_SetItemCategory ds
                             INNER JOIN dbo.mItem item ON ds.RowID = item.wCategoryRid
                             INNER JOIN dbo.eStockSalesDtl sales ON sales.wItemRid = item.RowID
                            )                   
                )              
                BEGIN                           
                    SET @pErrMsg=[dbo].[fnGetErrorMsg]('3003','zh-TW');
                    THROW 50001, @pErrMsg, 1;
                END;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetItemCategory
                        WHERE   RecordState = 'I' )
                BEGIN
					-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetItemCategory
                    SET     RowID = 0
                    WHERE   RecordState = 'I';
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetItemCategory;

                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            IF EXISTS ( SELECT  1
                                        FROM    #sDataSet_SetItemCategory
                                        WHERE   RecordState = 'I'
                                                AND wRowNum = @sRuningIndex )
                                BEGIN
                                    EXEC spq.GetRowID @pMainCompNo,
                                        @sThisTableName, @sRowID OUTPUT;
                                    UPDATE  #sDataSet_SetItemCategory
                                    SET     RowID = @sRowID
                                    WHERE   wRowNum = @sRuningIndex;
                                END;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;	

                    INSERT  INTO [dbo].[mItemCategory]
                            ( RowID ,
                              wCName ,
                              wEName ,
                              wStatus ,
                              wCrtDt ,
                              wUpdDt
                            )
                            SELECT  RowID ,
                                    wCName ,
                                    wEName ,
                                    wStatus ,
                                    @sNow ,
                                    @sNow
                            FROM    #sDataSet_SetItemCategory
                            WHERE   RecordState = 'I';
                END;
			
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetItemCategory
                        WHERE   RecordState = 'U' )
                BEGIN
                    UPDATE  ic_t
                    SET     wCName = tmp.wCName ,
                            wEName = tmp.wEName ,
                            wStatus = tmp.wStatus ,
                            wCrtDt = tmp.wCrtDt ,
                            wUpdDt = @sNow
                    FROM    [dbo].[mItemCategory] ic_t
                            INNER JOIN #sDataSet_SetItemCategory tmp ON ic_t.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'U';
                END;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetItemCategory
                        WHERE   RecordState = 'D' )
                BEGIN			
                    UPDATE  ic_t
                    SET     wStatus = 'T' ,
                            wUpdDt = @sNow
                    FROM    [dbo].[mItemCategory] ic_t
                            INNER JOIN #sDataSet_SetItemCategory tmp ON ic_t.RowID = tmp.RowID
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
            FROM    #sDataSet_SetItemCategory;	
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
        IF OBJECT_ID('tempdb..#sDataSet_SetItemCategory') IS NOT NULL
            DROP TABLE #sDataSet_SetItemCategory;
    END;