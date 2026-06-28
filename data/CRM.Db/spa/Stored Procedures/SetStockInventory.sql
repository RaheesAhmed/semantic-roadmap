
CREATE PROCEDURE [spa].[SetStockInventory]
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

        DECLARE @sThisTableName VARCHAR(50) = 'eStockInventory' ,
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
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetStockInventory
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
    WITH (
         RowID BIGINT, wWarehouseRid BIGINT, wPurchaseRid BIGINT, wItemRid BIGINT, wQty INT, wOnHoldQty INT, wOriQty INT, RecordState VARCHAR(1));        
        BEGIN TRY	                
            --SELECT  *
            --FROM    #sDataSet_SetStockInventory;

            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
                
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetStockInventory
                        WHERE   RecordState = 'I' )
                BEGIN
                    -- Set RowID by Sequence
                    UPDATE  #sDataSet_SetStockInventory
                    SET     RowID = 0
                    WHERE   RecordState = 'I';
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetStockInventory;

                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            IF EXISTS ( SELECT  1
                                        FROM    #sDataSet_SetStockInventory
                                        WHERE   RecordState = 'I'
                                                AND wRowNum = @sRuningIndex )
                                BEGIN
                                    EXEC spq.GetRowID @pMainCompNo,
                                        @sThisTableName, @sRowID OUTPUT;
                                    UPDATE  #sDataSet_SetStockInventory
                                    SET     RowID = @sRowID
                                    WHERE   wRowNum = @sRuningIndex;
                                END;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;	

                    INSERT  INTO [dbo].[eStockInventory]
                            ( RowID ,
                              wWarehouseRid ,
                              wPurchaseRid ,
                              wItemRid ,
                              wQty ,
                              wOnHoldQty ,
                              wOriQty ,
                              wStatus ,
                              wCrtDt ,
                              wUpdDt
                            )
                            SELECT  RowID ,
                                    wWarehouseRid ,
                                    wPurchaseRid ,
                                    wItemRid ,
                                    wQty ,
                                    wOnHoldQty ,
                                    wOriQty ,
                                    'A' ,
                                    @sNow ,
                                    @sNow
                            FROM    #sDataSet_SetStockInventory
                            WHERE   RecordState = 'I';
                END;
            
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetStockInventory
                        WHERE   RecordState = 'U' )
                BEGIN
                    UPDATE  si_t
                    SET     wWarehouseRid = tmp.wWarehouseRid ,
                            wPurchaseRid = tmp.wPurchaseRid ,
                            wItemRid = tmp.wItemRid ,
                            wQty = tmp.wQty ,
                            wOnHoldQty = tmp.wOnHoldQty ,
                            wOriQty = tmp.wOriQty ,
                            wUpdDt = @sNow
                    FROM    [dbo].[eStockInventory] si_t
                            INNER JOIN #sDataSet_SetStockInventory tmp ON si_t.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'U';
                END;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetStockInventory
                        WHERE   RecordState = 'D' )
                BEGIN			
                   UPDATE  si_t
                    SET     wStatus = 'T' ,
                            wUpdDt = @sNow
                    FROM    [dbo].[eStockInventory] si_t
                            INNER JOIN #sDataSet_SetStockInventory tmp ON si_t.RowID = tmp.RowID
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
            --SELECT  RowID
            --FROM    #sDataSet_SetStockInventory;	
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
        IF OBJECT_ID('tempdb..#sDataSet_SetStockInventory') IS NOT NULL
            DROP TABLE #sDataSet_SetStockInventory;
    END;