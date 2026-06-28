
CREATE PROCEDURE [spa].[SetStockMovementDtl]
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
		--	RowID bigint not null,
  --        TempRowID BIGINT
		--)
		--Select * from @sRtnList
		--return

        DECLARE @sThisTableName VARCHAR(50) = 'eStockMovementDtl' ,
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
        INTO    #sDataSet_SetStockMovementDtl
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
	    WITH (
           RowID BIGINT, 
           wStockMovementRid BIGINT, 
           wSalesType VARCHAR(30), 
           wAgentCodeIn VARCHAR(14), 
           wTotalCostHKD NUMERIC(18,4), 
           wItemRid BIGINT, 
           wItemQty INT, 
           wStatus CHAR(1), 
           wCrtDt DATETIME2, 
           wCrtBy BIGINT, 
           wUpdDt DATETIME2, 
           wUpdBy BIGINT, 
           RecordState VARCHAR(1),
           TempRowID BIGINT,
           wPurchaseRid BIGINT
        );        
        BEGIN TRY	             
            IF NOT EXISTS ( SELECT  1
                            FROM    dbo.eStockInventory si
                                    INNER JOIN #sDataSet_SetStockMovementDtl ds ON ds.wItemRid = si.wItemRid 
                                    INNER JOIN dbo.eStockMovement sm ON sm.wOutWarehouseRid = si.wWarehouseRid
                                                                        AND sm.RowID = ds.wStockMovementRid )
                AND EXISTS ( SELECT 1
                             FROM   #sDataSet_SetStockMovementDtl ds
                                    INNER JOIN dbo.eStockMovement sm ON sm.RowID = ds.wStockMovementRid
                             WHERE  sm.wMovementStatus IN ( 'STOCK_IN', 'STOCK_OUT' ) )
                BEGIN
			  ;
                    SET @pErrMsg=dbo.fnGetErrorMsg('2005','zh-TW');
                    THROW 50001, @pErrMsg, 1;
                END;
				   
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
        		
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetStockMovementDtl
                        WHERE   RecordState = 'I' )
                BEGIN
					-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetStockMovementDtl
                    SET     RowID = 0
                    WHERE   RecordState = 'I';
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetStockMovementDtl;

                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            IF EXISTS ( SELECT  1
                                        FROM    #sDataSet_SetStockMovementDtl
                                        WHERE   RecordState = 'I'
                                                AND wRowNum = @sRuningIndex )
                                BEGIN
                                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
                                    UPDATE  #sDataSet_SetStockMovementDtl
                                    SET     RowID = @sRowID
                                    WHERE   wRowNum = @sRuningIndex;
                                END;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;	

                    INSERT  INTO [dbo].[eStockMovementDtl]
                            ( RowID ,
                              wStockMovementRid ,
                              wSalesType ,
                              wAgentCodeIn ,
                              wTotalCostHKD ,
                              wItemRid ,
                              wItemQty ,
                              wStatus ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy ,
                              wPurchaseRid
                            )
                            SELECT  RowID ,
                                    wStockMovementRid ,
                                    wSalesType ,
                                    wAgentCodeIn ,
                                    wTotalCostHKD ,
                                    wItemRid ,
                                    wItemQty ,
                                    wStatus ,
                                    @sNow ,
                                    wCrtBy ,
                                    @sNow ,
                                    wUpdBy,
                                    ISNULL(wPurchaseRid,0)
                            FROM    #sDataSet_SetStockMovementDtl
                            WHERE   RecordState = 'I';
                END;
			
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetStockMovementDtl
                        WHERE   RecordState = 'U' )
                BEGIN
                    UPDATE  smd_t
                    SET     wStockMovementRid = tmp.wStockMovementRid ,
                            wSalesType = tmp.wSalesType ,
                            wAgentCodeIn = tmp.wAgentCodeIn ,
                            wTotalCostHKD = tmp.wTotalCostHKD ,
                            wItemRid = tmp.wItemRid ,
                            wItemQty = tmp.wItemQty ,
                            wStatus = tmp.wStatus ,
                            wUpdDt = @sNow ,
                            wUpdBy = tmp.wUpdBy,
                            wPurchaseRid = ISNULL(tmp.wPurchaseRid,0)
                    FROM    [dbo].[eStockMovementDtl] smd_t
                            INNER JOIN #sDataSet_SetStockMovementDtl tmp ON smd_t.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'U';
                END;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetStockMovementDtl
                        WHERE   RecordState = 'D' )
                BEGIN			
                    UPDATE  smd_t
                    SET     wStatus = 'T' ,
                            wUpdDt = @sNow
                    FROM    [dbo].[eStockMovementDtl] smd_t
                            INNER JOIN #sDataSet_SetStockMovementDtl tmp ON smd_t.RowID = tmp.RowID
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
            SELECT  RowID,TempRowID
            FROM    #sDataSet_SetStockMovementDtl;	
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
        IF OBJECT_ID('tempdb..#sDataSet_SetStockMovementDtl') IS NOT NULL
            DROP TABLE #sDataSet_SetStockMovementDtl;
    END;