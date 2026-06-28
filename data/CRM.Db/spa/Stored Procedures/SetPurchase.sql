
CREATE PROCEDURE [spa].[SetPurchase]
    (
      @pXML XML ,
      @pMainCompNo INT ,
      @pTestMode INT = 0 , -- 0: Normal(Non-Test), 1: UnitTest, 2: Scenario Test
      @pNonceToken VARCHAR(64) ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) OUTPUT
    )
AS /*
	DECLARE @pErrCode INT, @pErrMsg NVARCHAR(200);

	EXEC spa.SetPurchase 
	@pXML = N'<DataSet><Record RowID="0" wLotNo="LN123456" wBatchNo="BN123456" wVendorRid="1000010101" wInWarehouseRid="1000010101" wCurrCode="HKD" wCurrRate="1" wCost="2" wType="PURCHASE" wRemarks="" wPurchaseStatus="OPEN" wStatus="A" wCrtDt="2017-01-01" wUpdDt="2017-01-03" RecordState="I"/></DataSet>',
    @pMainCompNo = 10, -- int
    @pTestMode = 1, -- int
    @pNonceToken = '', -- varchar(64)
    @pErrCode = @pErrCode OUTPUT, -- int
    @pErrMsg = @pErrMsg OUTPUT -- nvarchar(200)	
	
	SELECT @pErrCode, @pErrMsg;

	DECLARE @pErrCode INT, @pErrMsg NVARCHAR(200);
	EXEC spa.SetPurchase 
	@pXML = N'<DataSet><Record RowID="10000000010002" wLotNo="990001-1322" wBatchNo="BN123456" wVendorRid="99000000010001" wInWarehouseRid="10000000010002" wCurrCode="HKD" wCurrRate="1" wCost="1000" wType="PURCHASE" wRemarks="" wPurchaseStatus="OPEN" wStatus="A" wCrtDt="2017-01-01" wUpdDt="2017-01-03" RecordState="U"/></DataSet>',
    @pMainCompNo = 10, -- int
    @pTestMode = 1, -- int
    @pNonceToken = '', -- varchar(64)
    @pErrCode = @pErrCode OUTPUT, -- int
    @pErrMsg = @pErrMsg OUTPUT -- nvarchar(200)	
	
	SELECT @pErrCode, @pErrMsg;
*/
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

        DECLARE @sThisTableName VARCHAR(50) = 'ePurchase' ,
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
        INTO    #sDataSet_SetPurchase
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
	WITH (
         RowID BIGINT, 
         wLotNo VARCHAR(50),
         wBatchNo VARCHAR(50), 
         wVendorRid BIGINT,
         wInWarehouseRid BIGINT, 
         wAgentCodeIn VARCHAR(14), 
         wCurrCode CHAR(3), 
         wCurrRate NUMERIC(12,6), 
         wCost NUMERIC(18, 4), 
         wType VARCHAR(30), 
         wRemarks NVARCHAR(500), 
         wPurchaseStatus VARCHAR(30), 
         wPayExpiryDt DATETIME2, 
         wSettleBy BIGINT, 
         wSettleDt DATETIME2,  
         wStatus CHAR(1), 
         wCrtDt DATETIME2, 
         wCrtBy BIGINT, 
         wUpdDt DATETIME2, 
         wUpdBy BIGINT, 
         RecordState VARCHAR(1),
         wNoticeRecord NVARCHAR(300),
         wStoreLocation NVARCHAR(300),
         wMaturityDate DATETIME2,
         wGuestCodeIn VARCHAR(14),
         wReceiptDate DATETIME2,
         wNotifier NVARCHAR(50),
         wTelephone  VARCHAR(100),
         wServiceCounterRid BIGINT,
         wPurchaseCounterRid BIGINT
         );
         
         UPDATE #sDataSet_SetPurchase SET wNotifier = ISNULL(wNotifier, ''), wTelephone = ISNULL(wTelephone, ''), wServiceCounterRid = ISNULL(wServiceCounterRid, 0);
                 
        BEGIN TRY	        
			-- check next step valid or not
            IF ( SELECT COUNT(*)
                 FROM   #sDataSet_SetPurchase ds
                        INNER JOIN mProcess p ON p.wProcessType = 'INVENTORY_PURCHASE'
                                                 AND p.wScopeType = 'STATE'
                                                 AND p.wCurrectStepValue = ds.wPurchaseStatus
                 WHERE  p.wPreviousStepValue = ''
                        AND ds.RecordState = 'I'
               )
                + ( SELECT  COUNT(*)
                    FROM    #sDataSet_SetPurchase ds
                            INNER JOIN mProcess p ON p.wProcessType = 'INVENTORY_PURCHASE'
                                                     AND p.wScopeType = 'STATE'
                                                     AND p.wCurrectStepValue = ds.wPurchaseStatus
                            INNER JOIN dbo.ePurchase pur ON pur.RowID = ds.RowID
                    WHERE   ( p.wPreviousStepValue = pur.wPurchaseStatus
                              OR pur.wPurchaseStatus = ds.wPurchaseStatus
                            )
                            AND ds.RecordState = 'U'
                  ) + ( SELECT  COUNT(*)
                        FROM    #sDataSet_SetPurchase ds
                        WHERE   ds.RecordState = 'D'
                      ) <> ( SELECT COUNT(*)
                             FROM   #sDataSet_SetPurchase
                           )
                BEGIN			                    
                    SET @pErrMsg=dbo.fnGetErrorMsg('1001','zh-TW');
                    THROW 70002, @pErrMsg, 1;
                END;

            --添加 AND (p.wPurchaseStatus='COMPLETE' OR p.wStatus!='T')条件 
            --1.如果同一个批次号码 只要有「完成」的记录，这个批次号码就不可以再重用
            --2.如果同一个批次号码的采购单從來沒有完成過就中止了，那麼這個批次号码就可以重用
            IF EXISTS ( SELECT 1
                        FROM dbo.ePurchase p
                        INNER JOIN #sDataSet_SetPurchase ds ON RIGHT(p.wLotNo,LEN(p.wLotNo)- 7) = RIGHT(ds.wLotNo,LEN(ds.wLotNo)- 7)
                                                               AND p.wBatchNo = ds.wBatchNo 
                                                               AND ds.RecordState = 'I'
                                                               AND (p.wPurchaseStatus='COMPLETE' OR p.wStatus!='T'))
                BEGIN				 
                    SET @pErrMsg=dbo.fnGetErrorMsg('2003','zh-TW');
                    THROW 50001,  @pErrMsg, 1;
                END;
			
            -- 如果是刪除,check 這條記錄是否做過 貨存調整,轉倉,銷售 中任何一個操作 
            IF EXISTS ( SELECT 1
                        FROM #sDataSet_SetPurchase
                        WHERE RecordState = 'D' )
               BEGIN
                    IF ( SELECT COUNT(*)
                         FROM dbo.eStockAdjustmentItem adjustitem
                         INNER JOIN dbo.eStockAdjustmentDtl adjustdtl ON adjustdtl.RowID=adjustitem.wStockAdjustmentDtlRid AND adjustdtl.wStatus='A'
                         INNER JOIN dbo.eStockAdjustment adjust ON adjust.RowID=adjustdtl.wStockAdjustmentRid AND (adjust.wStatus='A' OR adjust.wAdjustmentStatus='COMPLETE')
                         INNER JOIN #sDataSet_SetPurchase tmp ON adjustitem.wPurchaseRid=tmp.RowID AND adjustitem.wStatus='A'
                         )+
                       ( SELECT COUNT(*)
                         FROM dbo.eStockSalesItem salesitem
                         INNER JOIN dbo.eStockSalesDtl salesdtl ON salesdtl.RowID=salesitem.wStockSalesDtlRid AND salesdtl.wStatus='A'
                         INNER JOIN  dbo.eStockSales sales ON sales.RowID=salesdtl.wStockSalesRid AND (sales.wStatus='A' OR sales.wSalesStatus='COMPLETE')
                         INNER JOIN #sDataSet_SetPurchase tmp ON salesitem.wPurchaseRid=tmp.RowID AND salesitem.wStatus='A'
                       )+
                       ( SELECT COUNT(*)
                         FROM dbo.eStockMovementItem movementitem
                         INNER JOIN dbo.eStockMovementDtl movementdtl ON movementdtl.RowID=movementitem.wStockMovementDtlRid AND movementdtl.wStatus='A'
                         INNER JOIN dbo.eStockMovement movement ON movement.RowID=movementdtl.wStockMovementRid AND movement.wStatus='A'
                         INNER JOIN #sDataSet_SetPurchase tmp ON movementitem.wPurchaseRid=tmp.RowID AND movementitem.wStatus='A'
                       )>0                      
                       BEGIN;
                            SET @pErrMsg=dbo.fnGetErrorMsg('2004','zh-TW');
                            THROW 50001, @pErrMsg, 1;
                       END;
               END;
            	        
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;							 
        		
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetPurchase
                        WHERE   RecordState = 'I' )
                BEGIN
					-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetPurchase
                    SET     RowID = 0
                    WHERE   RecordState = 'I';
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetPurchase;

                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            IF EXISTS ( SELECT  1
                                        FROM    #sDataSet_SetPurchase
                                        WHERE   RecordState = 'I'
                                                AND wRowNum = @sRuningIndex )
                                BEGIN
                                    EXEC spq.GetRowID @pMainCompNo,
                                        @sThisTableName, @sRowID OUTPUT;
                                    UPDATE  #sDataSet_SetPurchase
                                    SET     RowID = @sRowID
                                    WHERE   wRowNum = @sRuningIndex;
                                END;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;                 

                    INSERT  INTO [dbo].[ePurchase]
                            ( RowID ,
                              wLotNo ,
                              wBatchNo ,
                              wVendorRid ,
                              wInWarehouseRid ,
                              wAgentCodeIn ,
                              wCurrCode ,
                              wCurrRate ,
                              wCost ,
                              wType ,
                              wRemarks ,
                              wPurchaseStatus ,
                              wPayExpiryDt ,
                              wSettleBy ,
                              wSettleDt ,
                              wStatus ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy,
                              wNoticeRecord,
                              wStoreLocation,
                              wMaturityDate,
                              wGuestCodeIn,
                              wNotifier,
                              wTelephone,
                              wServiceCounterRid,
                              wPurchaseCounterRid
                            )
                            SELECT  RowID ,
                                    wLotNo ,
                                    wBatchNo ,
                                    wVendorRid ,
                                    wInWarehouseRid ,
                                    wAgentCodeIn ,
                                    wCurrCode ,
                                    wCurrRate ,
                                    wCost ,
                                    wType ,
                                    wRemarks ,
                                    wPurchaseStatus ,
                                    wPayExpiryDt ,
                                    wSettleBy ,
                                    wSettleDt ,
                                    wStatus ,
                                    wCrtDt ,
                                    wCrtBy ,
                                    wUpdDt ,
                                    wUpdBy,
                                    wNoticeRecord,
                                    wStoreLocation,
                                    wMaturityDate,
                                    wGuestCodeIn,
                                    wNotifier,
                                    wTelephone,
                                    wServiceCounterRid,
                                    wPurchaseCounterRid
                            FROM    #sDataSet_SetPurchase
                            WHERE   RecordState = 'I';
                END;
			
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetPurchase
                        WHERE   RecordState = 'U' )
                BEGIN
                    UPDATE  p_t
                    SET     wLotNo = tmp.wLotNo ,
                            wBatchNo = tmp.wBatchNo ,
                            wVendorRid = tmp.wVendorRid ,
                            wInWarehouseRid = tmp.wInWarehouseRid ,
                            wAgentCodeIn = tmp.wAgentCodeIn ,
                            wCurrCode = tmp.wCurrCode ,
                            wCurrRate = tmp.wCurrRate ,
                            wCost = tmp.wCost ,
                            wType = tmp.wType ,
                            wRemarks = tmp.wRemarks ,
                            wPurchaseStatus = tmp.wPurchaseStatus ,
                            wPayExpiryDt = tmp.wPayExpiryDt ,
                            wSettleBy = tmp.wSettleBy ,
                            wSettleDt = tmp.wSettleDt ,
                            wStatus = tmp.wStatus ,
                            wUpdDt = tmp.wUpdDt ,
                            wUpdBy = tmp.wUpdBy,
                            wNoticeRecord=tmp.wNoticeRecord,
                            wStoreLocation=tmp.wStoreLocation,
                            wMaturityDate=tmp.wMaturityDate,
                            wTelephone=tmp.wTelephone,
                            wNotifier=tmp.wNotifier,
                            wGuestCodeIn =tmp.wGuestCodeIn,
                            wReceiptDate =tmp.wReceiptDate,
                            wServiceCounterRid = tmp.wServiceCounterRid,
                            wPurchaseCounterRid = tmp.wPurchaseCounterRid
                    FROM    [dbo].[ePurchase] p_t
                            INNER JOIN #sDataSet_SetPurchase tmp ON p_t.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'U';
                END;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetPurchase
                        WHERE   RecordState = 'D' )
                BEGIN			
                    UPDATE  p_t
                    SET     wStatus = 'T' ,
                            wUpdDt = @sNow
                    FROM    [dbo].[ePurchase] p_t
                            INNER JOIN #sDataSet_SetPurchase tmp ON p_t.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'D';                    					
                END; 			

			 -- Recal Inventory
            SET @sRecalInventoryXML = ( SELECT  DISTINCT
                                                pd.wItemRid ,
                                                tmp.wInWarehouseRid ,
                                                CAST(0 AS BIGINT) AS wOutWarehouseRid ,
                                                pd.wPurchaseRid
                                        FROM    #sDataSet_SetPurchase tmp
                                                LEFT JOIN dbo.ePurchaseDtl pd ON pd.wPurchaseRid = tmp.RowID
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
            
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetPurchase
                        WHERE   RecordState = 'D' )
                BEGIN			               
                    -------------刪除后庫存記錄也要刪除---------------------                  
                    UPDATE  In_t
                    SET     wStatus = 'T' ,
                            wUpdDt = @sNow
                    FROM    [dbo].[eStockInventory] In_t
                            INNER JOIN #sDataSet_SetPurchase tmp ON In_t.wPurchaseRid = tmp.RowID
                    WHERE   tmp.RecordState = 'D';                                                                          					
                END;

            -- 2019-04-18： OP#25483，更新同一批次的存放位置 /通知記錄 / 備註
            ----------------------------------------------------------------------------
            UPDATE p
            SET wStoreLocation = tmp.wStoreLocation,
                wNoticeRecord = tmp.wNoticeRecord,
                wRemarks = tmp.wRemarks
            FROM dbo.ePurchase p
            INNER JOIN #sDataSet_SetPurchase tmp ON tmp.wLotNo = p.wLotNo
            ----------------------------------------------------------------------------

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
            FROM    #sDataSet_SetPurchase;	
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
        IF OBJECT_ID('tempdb..#sDataSet_SetPurchase') IS NOT NULL
            DROP TABLE #sDataSet_SetPurchase;
    END;