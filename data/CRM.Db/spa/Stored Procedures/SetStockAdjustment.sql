CREATE PROCEDURE [spa].[SetStockAdjustment]
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

        DECLARE @sThisTableName VARCHAR(50) = 'eStockAdjustment' ,
            @sBeginTranCount INT = 0 ,
            @sDocHandle INT ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sRecalInventoryXML NVARCHAR(MAX) = '' ,
            @sNow DATETIME2 = dbo.fnUTC8Now();
        
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ) ,
                *
        INTO    #sDataSet_SetStockAdjustment
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
    WITH (
         RowID BIGINT, wWarehouseRid BIGINT, wApprovalByRid BIGINT, wAdjustDt DATETIME2, wRemarks NVARCHAR(500), wAdjustmentStatus VARCHAR(30), wStatus CHAR(1), wCrtDt DATETIME2, wCrtBy BIGINT, wUpdDt DATETIME2, wUpdBy BIGINT, RecordState VARCHAR(1));        
        BEGIN TRY	
            -- check next step valid or not
            IF ( SELECT COUNT(*)
                 FROM   #sDataSet_SetStockAdjustment ds
                        INNER JOIN mProcess p ON p.wProcessType = 'INVENTORY_ADJUSTMENT'
                                                 AND p.wScopeType = 'STATE'
                                                 AND p.wCurrectStepValue = ds.wAdjustmentStatus
                 WHERE  p.wPreviousStepValue = ''
                        AND ds.RecordState = 'I'
               )
                + ( SELECT  COUNT(*)
                    FROM    #sDataSet_SetStockAdjustment ds
                            INNER JOIN mProcess p ON p.wProcessType = 'INVENTORY_ADJUSTMENT'
                                                     AND p.wScopeType = 'STATE'
                                                     AND p.wCurrectStepValue = ds.wAdjustmentStatus
                            INNER JOIN dbo.eStockAdjustment sa ON sa.RowID = ds.RowID
                    WHERE   ( p.wPreviousStepValue = sa.wAdjustmentStatus
                              OR sa.wAdjustmentStatus = ds.wAdjustmentStatus
                            )
                            AND ds.RecordState = 'U'
                  ) + ( SELECT  COUNT(*)
                        FROM    #sDataSet_SetStockAdjustment ds
                        WHERE   ds.RecordState = 'D'
                      ) <> ( SELECT COUNT(*)
                             FROM   #sDataSet_SetStockAdjustment
                           )
                BEGIN			                    
                    ;
                    SET @pErrMsg=[dbo].[fnGetErrorMsg]('2002','zh-TW');
                    THROW 70002, @pErrMsg, 1;
                END;
                                
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;			
                
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetStockAdjustment
                        WHERE   RecordState = 'I' )
                BEGIN
                    -- Set RowID by Sequence
                    UPDATE  #sDataSet_SetStockAdjustment
                    SET     RowID = 0
                    WHERE   RecordState = 'I';
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetStockAdjustment;

                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            IF EXISTS ( SELECT  1
                                        FROM    #sDataSet_SetStockAdjustment
                                        WHERE   RecordState = 'I'
                                                AND wRowNum = @sRuningIndex )
                                BEGIN
                                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
                                    UPDATE  #sDataSet_SetStockAdjustment
                                    SET     RowID = @sRowID
                                    WHERE   wRowNum = @sRuningIndex;
                                END;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;	

                    INSERT  INTO [dbo].[eStockAdjustment]
                            ( RowID ,
                              wWarehouseRid ,
                              wApprovalByRid ,
                              wAdjustDt ,
                              wRemarks ,
                              wAdjustmentStatus ,
                              wStatus ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy
                            )
                            SELECT  RowID ,
                                    wWarehouseRid ,
                                    wApprovalByRid ,
                                    wAdjustDt ,
                                    wRemarks ,
                                    wAdjustmentStatus ,
                                    wStatus ,
                                    @sNow ,
                                    wCrtBy ,
                                    @sNow ,
                                    wUpdBy
                            FROM    #sDataSet_SetStockAdjustment
                            WHERE   RecordState = 'I';
                END;
            
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetStockAdjustment
                        WHERE   RecordState = 'U' )
                BEGIN
                    UPDATE  sa_t
                    SET     wWarehouseRid = tmp.wWarehouseRid ,
                            wApprovalByRid = tmp.wApprovalByRid ,
                            wAdjustDt = tmp.wAdjustDt ,
                            wRemarks = tmp.wRemarks ,
                            wAdjustmentStatus = tmp.wAdjustmentStatus ,
                            wStatus = tmp.wStatus ,
                            wUpdDt = @sNow ,
                            wUpdBy = tmp.wUpdBy
                    FROM    [dbo].[eStockAdjustment] sa_t
                            INNER JOIN #sDataSet_SetStockAdjustment tmp ON sa_t.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'U';
                END;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetStockAdjustment
                        WHERE   RecordState = 'D' )
                BEGIN			
                    UPDATE  sa_t
                    SET     wStatus = 'T' ,
                            wUpdDt = @sNow
                    FROM    [dbo].[eStockAdjustment] sa_t
                            INNER JOIN #sDataSet_SetStockAdjustment tmp ON sa_t.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'D';
                END;  
            
            -- Recal Inventory
            SET @sRecalInventoryXML = ( SELECT  DISTINCT
                                                sad.wItemRid ,
                                                tmp.wWarehouseRid AS wInWarehouseRid ,
                                                CAST(0 AS BIGINT) AS wOutWarehouseRid ,
                                                sai.wPurchaseRid AS wPurchaseRid
                                        FROM    #sDataSet_SetStockAdjustment tmp
                                                LEFT JOIN dbo.eStockAdjustmentDtl sad ON sad.wStockAdjustmentRid = tmp.RowID
                                                LEFT JOIN dbo.eStockAdjustmentItem sai ON sai.wStockAdjustmentDtlRid = sad.RowID
                                      FOR
                                        XML RAW('Record') ,
                                            ROOT('DataSet')
                                      );         

            EXEC util.RecalInventory @pXML = @sRecalInventoryXML, -- xml
                @pMainCompNo = @pMainCompNo, -- int
                @pTestMode = @pTestMode, -- int
                @pNonceToken = @pNonceToken, -- varchar(64)
                @pErrCode = @pErrCode OUTPUT, -- int
                @pErrMsg = @pErrMsg OUTPUT; -- nvarchar(200)                	               

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
            FROM    #sDataSet_SetStockAdjustment;	
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
                    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;             			
                              
        END CATCH;

        EXEC sp_xml_removedocument @sDocHandle;
        IF OBJECT_ID('tempdb..#sDataSet_SetStockAdjustment') IS NOT NULL
            DROP TABLE #sDataSet_SetStockAdjustment;
    END;