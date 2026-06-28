CREATE PROCEDURE [spa].[SetStockMovement]
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

        DECLARE @sThisTableName VARCHAR(50) = 'eStockMovement' ,
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
        INTO    #sDataSet_SetStockMovement
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
        WITH (
          RowID BIGINT, 
          wOutWarehouseRid BIGINT, 
          wOutUsrRid BIGINT, 
          wOutDt DATETIME2, 
          wInWarehouseRid BIGINT, 
          wInUsrRid BIGINT, 
          wInDt DATETIME2,
          wRemarks NVARCHAR(500), 
          wMovementStatus VARCHAR(30), 
          wStatus CHAR(1), 
          wCrtDt DATETIME2, 
          wCrtBy BIGINT, 
          wUpdDt DATETIME2, 
          wUpdBy BIGINT, 
          RecordState VARCHAR(1));        
        BEGIN TRY	  
            --只有狀態改變才做狀態改變的check        
            IF NOT EXISTS( SELECT COUNT(*)
                           FROM #sDataSet_SetStockMovement ds
                           INNER JOIN dbo.eStockMovement sm ON sm.RowID = ds.RowID AND ds.wMovementStatus =sm.wMovementStatus)
            BEGIN
              -- check next step valid or not
              IF( SELECT COUNT(*)
                   FROM #sDataSet_SetStockMovement ds
                   INNER JOIN dbo.mProcess p ON p.wProcessType = 'INVENTORY_MOVEMENT'
                                                 AND p.wScopeType = 'STATE'
                                                 AND p.wCurrectStepValue = ds.wMovementStatus
                                                 AND p.wStatus='A'
                   WHERE p.wPreviousStepValue = ''
                         AND ds.RecordState = 'I'
                )+ 
                ( SELECT COUNT(*)
                  FROM #sDataSet_SetStockMovement ds
                  INNER JOIN dbo.mProcess p ON p.wProcessType = 'INVENTORY_MOVEMENT'
                                                     AND p.wScopeType = 'STATE'
                                                     AND p.wCurrectStepValue = ds.wMovementStatus
                                                     AND p.wStatus='A'
                  INNER JOIN dbo.eStockMovement sm ON sm.RowID = ds.RowID
                  WHERE ( p.wPreviousStepValue = sm.wMovementStatus OR sm.wMovementStatus = ds.wMovementStatus )
                         AND ds.RecordState = 'U'
                 ) + 
                 ( SELECT COUNT(*)
                   FROM #sDataSet_SetStockMovement ds
                   WHERE ds.RecordState = 'D'
                 ) <> 
                 ( SELECT COUNT(*)
                   FROM #sDataSet_SetStockMovement
                 )
                 BEGIN			                    
                   SET @pErrMsg=dbo.fnGetErrorMsg('2002','zh-TW');
                   THROW 70002, @pErrMsg, 1;
                 END;          
            END;       

            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;    
            IF EXISTS ( SELECT 1 FROM #sDataSet_SetStockMovement WHERE RecordState = 'I')
                BEGIN
                    -- Set RowID by Sequence
                    UPDATE #sDataSet_SetStockMovement
                    SET RowID = 0
                    WHERE RecordState = 'I';
                    SELECT @sRecCount = COUNT(*)
                    FROM #sDataSet_SetStockMovement;

                    WHILE @sRuningIndex <= @sRecCount
                       BEGIN
                         IF EXISTS ( SELECT 1 FROM #sDataSet_SetStockMovement WHERE RecordState = 'I' AND wRowNum = @sRuningIndex )
                            BEGIN
                              EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
                              UPDATE #sDataSet_SetStockMovement
                              SET RowID = @sRowID
                               WHERE wRowNum = @sRuningIndex;
                            END;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;	

                    INSERT INTO [dbo].[eStockMovement]
                            ( RowID ,
                              wOutWarehouseRid ,
                              wOutUsrRid ,
                              wOutDt ,
                              wInWarehouseRid ,
                              wInUsrRid ,
                              wInDt ,
                              wRemarks ,
                              wMovementStatus ,
                              wStatus ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy
                            )
                            SELECT RowID ,
                                   wOutWarehouseRid ,
                                   wOutUsrRid ,
                                   wOutDt ,
                                   wInWarehouseRid ,
                                   wInUsrRid ,
                                   wInDt ,
                                   wRemarks ,
                                   wMovementStatus ,
                                   wStatus ,
                                   @sNow ,
                                   wCrtBy ,
                                   @sNow ,
                                   wUpdBy
                            FROM #sDataSet_SetStockMovement
                            WHERE RecordState = 'I';
                END;
            
            -- Recal Inventory
            SET @sRecalInventoryXML = ( SELECT DISTINCT
                                          smd.wItemRid ,
                                          tmp.wInWarehouseRid ,
                                          tmp.wOutWarehouseRid ,
                                          smi.wPurchaseRid
                                        FROM #sDataSet_SetStockMovement tmp
                                        LEFT JOIN dbo.eStockMovementDtl smd ON smd.wStockMovementRid = tmp.RowID
                                        LEFT JOIN dbo.eStockMovementItem smi ON smi.wStockMovementDtlRid = smd.RowID
                                        GROUP BY smd.wItemRid ,
                                                 tmp.wInWarehouseRid ,
                                                 tmp.wOutWarehouseRid ,
                                                 smi.wPurchaseRid
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

            IF EXISTS ( SELECT 1 FROM #sDataSet_SetStockMovement WHERE RecordState = 'U' )
                BEGIN
                  UPDATE sm_t
                    SET wOutWarehouseRid = tmp.wOutWarehouseRid ,
                        wOutUsrRid = tmp.wOutUsrRid ,
                        wOutDt = tmp.wOutDt ,
                        wInWarehouseRid = tmp.wInWarehouseRid ,
                        wInUsrRid = tmp.wInUsrRid ,
                        wInDt = tmp.wInDt ,
                        wRemarks = tmp.wRemarks ,
                        wMovementStatus = tmp.wMovementStatus ,
                        wStatus = tmp.wStatus ,
                        wUpdDt = @sNow ,
                        wUpdBy = tmp.wUpdBy
                    FROM [dbo].[eStockMovement] sm_t
                    INNER JOIN #sDataSet_SetStockMovement tmp ON sm_t.RowID = tmp.RowID
                    WHERE tmp.RecordState = 'U';
                END;

            IF EXISTS ( SELECT 1 FROM #sDataSet_SetStockMovement WHERE RecordState = 'D' )
                BEGIN			
                    UPDATE sm_t
                    SET wStatus = 'T', wUpdDt = @sNow
                    FROM [dbo].[eStockMovement] sm_t
                    INNER JOIN #sDataSet_SetStockMovement tmp ON sm_t.RowID = tmp.RowID
                    WHERE tmp.RecordState = 'D';
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
            FROM    #sDataSet_SetStockMovement;	
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
        IF OBJECT_ID('tempdb..#sDataSet_SetStockMovement') IS NOT NULL
            DROP TABLE #sDataSet_SetStockMovement;
    END;