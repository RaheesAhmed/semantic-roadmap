CREATE PROCEDURE [spa].[SetStockSales]
    (
      @pXML XML ,
      @pMainCompNo INT ,
      @pCompNo INT ,
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
        /*
        declare @sRtnList table (
            RowID bigint not null
        )
        Select * from @sRtnList
        return
        */

        DECLARE @sThisTableName VARCHAR(50) = 'eStockSales' ,
            @sBeginTranCount INT = 0 ,
            @sDocHandle INT ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sRecalInventoryXML NVARCHAR(MAX) = '' ,
            @sXMLeGift NVARCHAR(MAX) = '' ,
            @sNow DATETIME2 = dbo.fnUTC8Now() ,
            @sCageCodeIn VARCHAR(14),
            @sNewLine CHAR(2) = CHAR(13) + CHAR(10);
        
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';

        SELECT  @sCageCodeIn = wCageCodeIn
        FROM    RollsMary.dbo.mCage
        WHERE   wCompNo = @pCompNo;
    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ) ,
                *
        INTO    #sDataSet_SetStockSales
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
        WITH (
            RowID BIGINT, 
            wDebitCompNo INT, 
            wDebitCounterRid BIGINT, 
            wOutWarehouseRid BIGINT, 
            wRefNo VARCHAR(50),  
            wSalesType VARCHAR(30), 
            wPaymentMethod VARCHAR(30), 
            wGiftReasonCd VARCHAR(30), 
            wSalesDt DATETIME2,  
            wSalesDeptCd VARCHAR(39), 
            wDebitDt DATETIME2, 
            wSalesmanRid BIGINT, 
            wRecipientAgentCodeIn VARCHAR(14), 
            wCurrCode VARCHAR(6), 
            wDebitAgentCodeIn VARCHAR(14), 
            wSalesTotalPrice NUMERIC(18,4), 
            wExpenseAmount NUMERIC(18,4), 
            wSalesStatus VARCHAR(30), 
            wStatus CHAR(1), 
            wCrtDt DATETIME2, 
            wCrtBy BIGINT, 
            wUpdDt DATETIME2, 
            wUpdBy BIGINT, 
            wCancelDebitBy BIGINT, 
            wCancelDebitDt  DATETIME2, 
            wCancelBy BIGINT, 
            wCancelDt DATETIME2, 
            wCancelReasonCd VARCHAR(30), 
            wCancelOtherReason NVARCHAR(200), 
            RecordState VARCHAR(1),
            wTotalCost NUMERIC(18, 4),
            wRemark NVARCHAR(500),
            wIsBorrowGoods CHAR(1),
            wPickupDt datetime2(7)
        );        
        BEGIN TRY	                
            -- check next step valid or not
            IF ( SELECT COUNT(*)
                 FROM   #sDataSet_SetStockSales ds
                        INNER JOIN mProcess p ON p.wProcessType = 'INVENTORY_SALES'
                                                 AND p.wScopeType = 'STATE'
                                                 AND p.wCurrectStepValue = ds.wSalesStatus
                 WHERE  p.wPreviousStepValue = ''
                        AND ds.RecordState = 'I'
               ) + ( SELECT COUNT(*)
                     FROM   #sDataSet_SetStockSales ds
                            INNER JOIN mProcess p ON p.wProcessType = 'INVENTORY_SALES'
                                                     AND p.wScopeType = 'STATE'
                                                     AND p.wCurrectStepValue = ds.wSalesStatus
                            INNER JOIN dbo.eStockSales ss ON ss.RowID = ds.RowID
                     WHERE  ( p.wPreviousStepValue = ss.wSalesStatus
                              OR ss.wSalesStatus = ds.wSalesStatus
                            )
                            AND ds.RecordState = 'U'
                   ) + ( SELECT COUNT(*)
                         FROM   #sDataSet_SetStockSales ds
                         WHERE  ds.RecordState = 'D'
                       ) <> ( SELECT    COUNT(*)
                              FROM      #sDataSet_SetStockSales
                            )
                BEGIN			                    
                    ;
                    SET @pErrMsg=dbo.fnGetErrorMsg('2002','zh-TW');
                    THROW 70002, @pErrMsg, 1;
                END;

            IF EXISTS ( SELECT  1
                        FROM    eStockSales ss
                                INNER JOIN #sDataSet_SetStockSales ds ON ss.wRefNo = ds.wRefNo
                                                                         AND ss.wStatus = ds.wStatus
                                                                         AND ds.RecordState = 'I' )
                BEGIN
             ;
                    SET @pErrMsg=dbo.fnGetErrorMsg('2006','zh-TW');
                    THROW 50001, @pErrMsg, 1;
                END;

            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
                            
            
            ---------------------------------------------------------------------------------------------
            -- Add eGift record
            ---------------------------------------------------------------------------------------------
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetStockSales tmp
                                INNER JOIN dbo.eStockSales ss ON ss.RowID = tmp.RowID
                                INNER JOIN dbo.eStockSalesDtl ssd ON ssd.wStockSalesRid = tmp.RowID
                                                                     AND ( tmp.RecordState = 'U'
                                                                           OR tmp.RecordState = 'D'
                                                                         )
                                                                     AND ( tmp.wDebitAgentCodeIn <> ''
                                                                           OR tmp.wDebitAgentCodeIn <> ss.wDebitAgentCodeIn
                                                                         ) 
                                                                     AND ss.wPaymentMethod='GC')
                BEGIN
                    --SELECT  '#sDataSet_SetStockSales' ,
                    --        tmp.*
                    --FROM    #sDataSet_SetStockSales tmp
                    --        INNER JOIN dbo.eStockSales ss ON ss.RowID = tmp.RowID
                    --        INNER JOIN dbo.eStockSalesDtl ssd ON ssd.wStockSalesRid = tmp.RowID
                    --                                             AND ( tmp.RecordState = 'U'
                    --                                                   OR tmp.RecordState = 'D'
                    --                                                 )
                    --                                             AND ( tmp.wRecipientAgentCodeIn <> ''
                    --                                                   OR tmp.wRecipientAgentCodeIn <> ss.wRecipientAgentCodeIn
                    --                                                 )
                    --SELECT  'eStockSales' ,
                    --        ss.*
                    --FROM    #sDataSet_SetStockSales tmp
                    --        INNER JOIN dbo.eStockSales ss ON ss.RowID = tmp.RowID
                    --        INNER JOIN dbo.eStockSalesDtl ssd ON ssd.wStockSalesRid = tmp.RowID
                    --                                             AND ( tmp.RecordState = 'U'
                    --                                                   OR tmp.RecordState = 'D'
                    --                                                 )
                    --                                             AND ( tmp.wRecipientAgentCodeIn <> ''
                    --                                                   OR tmp.wRecipientAgentCodeIn <> ss.wRecipientAgentCodeIn
                    --                                                 )

                    CREATE TABLE #sSalesDtlList
                    (
                        RowID BIGINT,
                        wRemark NVARCHAR(500)
                    );
                    
                    WITH cteDtl AS 
                     (SELECT  tmp.RowID, CASE WHEN ISNULL(g.wRemark, '') = '' THEN ISNULL(i.wCName,'') + ' x ' + CAST(ssd.wQty AS VARCHAR(10)) + ' | ' + ISNULL(d.wCName,'')
                                                     ELSE g.wRemark
                                                END AS wRemark 
                                FROM     #sDataSet_SetStockSales tmp
                                                INNER JOIN dbo.eStockSales ss ON ss.RowID = tmp.RowID
                                                INNER JOIN dbo.eStockSalesDtl ssd ON ssd.wStockSalesRid = tmp.RowID
                                                                                     AND ( tmp.RecordState = 'U'
                                                                                           OR tmp.RecordState = 'D'
                                                                                         )
                                                                                     AND ( tmp.wDebitAgentCodeIn <> ''
                                                                                           OR tmp.wDebitAgentCodeIn <> ss.wDebitAgentCodeIn
                                                                                         )
                                                INNER JOIN dbo.mItem i ON i.RowID = ssd.wItemRid
                                                LEFT JOIN eGift g ON g.wRefTableRid = tmp.RowID
                                                                     AND g.wStatus = 'A'
                                                LEFT JOIN RollsMary.dbo.mDepartment d ON d.wCode = g.wReqDeptCd
                                                                                         AND d.wActive = 'A'
                       )
                       INSERT INTO #sSalesDtlList ( RowID, wRemark )				   
                           SELECT d.RowID, 
                            STUFF(
                                (SELECT DISTINCT ','  + cteDtl.wRemark
                                    FROM cteDtl           
                                    FOR XML PATH (''))
                                    , 1, 1, '') AS wRemark 				   
                           FROM cteDtl d
                           GROUP BY d.RowID
                                  
                    UPDATE s SET wRemark =REPLACE(wRemark, ',', @sNewLine) 
                    FROM #sSalesDtlList s

                    SET @sXMLeGift = ( SELECT   g.RowID AS RowID ,
                                                0 AS wRefBookingRid ,
                                                @sThisTableName AS wRefTableName ,
                                                tmp.RowID AS wRefTableRid ,
                                                tmp.wSalesStatus AS wOriActionType ,
                                                tmp.wDebitCounterRid AS wDebitCounterRid ,
                                                0 AS wReqCounterRid ,
                                                @pCompNo AS wCompNo ,
                                                @sCageCodeIn AS wCageCodeIn ,
                                                tmp.wSalesDeptCd AS wReqDeptCd ,
                                                tmp.wSalesmanRid AS wReqStaffRid ,
                                                tmp.wDebitAgentCodeIn AS wReqAgentCodeIn ,
                                                GETDATE() AS wDate ,
                                                a.wCName AS wRecipient ,
                                                -- 'HKD' AS wCurrCode , --2018-12-14： OP#24284，送禮特批中的金額貨幣現在默認為HKD，應該跟Booking中的貨幣
                                                tmp.wCurrCode AS wCurrCode ,
                                                tmp.wSalesTotalPrice * CASE WHEN tmp.RecordState = 'D' THEN -1
                                                                            ELSE 1
                                                                       END AS wAmount ,
                                                '02' AS wType , --送禮
                                                '0208' AS wSubType , --其他禮物
                                                --CASE WHEN ISNULL(g.wRemark, '') = '' THEN ISNULL(i.wCName,'') + ' x ' + CAST(ssd.wQty AS VARCHAR(10)) + ' | ' + ISNULL(d.wCName,'')
                                                --    ELSE g.wRemark
                                                --END AS wRemark ,
                                                ssd.wRemark , 
                                                0 AS wEventCodeRid ,
                                                'A' AS wStatus ,
                                                tmp.wCrtDt ,
                                                tmp.wCrtBy ,
                                                tmp.wUpdDt ,
                                                tmp.wUpdBy ,
                                                CASE 
                                                    --WHEN ( ( tmp.wRecipientAgentCodeIn = ''
             --                                                 AND ss.wRecipientAgentCodeIn <> ''
             --                                               )
             --                                               OR tmp.RecordState = 'D'
             --                                             )
             --                                             AND ISNULL(g.wRefTableRid, '') <> '' THEN 'D'
                                                     WHEN ( ( tmp.wDebitAgentCodeIn <> ''
                                                              AND tmp.wSalesStatus = 'COMPLETE'
                                                              AND ss.wSalesStatus = 'OPEN'
                                                              AND tmp.RecordState = 'U' -- no need to handle RecordState = 'I'
                                                            )
                                                            AND ISNULL(g.wRefTableRid, 0) <= 0
                                                          )
                                                          OR tmp.RecordState = 'D' THEN 'I'
                                                     ELSE 'U'
                                                END AS RecordState ,
                                                ISNULL(ss.wGiftReasonCd,'') AS wReasonCd ,
                                                wIsReceived = CASE WHEN g.RowID IS NULL THEN 'Y' ELSE g.wIsReceived END,
                                                tmp.wTotalCost AS wCost
                                       FROM     #sDataSet_SetStockSales tmp
                                                INNER JOIN dbo.eStockSales ss ON ss.RowID = tmp.RowID
                                                INNER JOIN #sSalesDtlList ssd ON ssd.RowID = tmp.RowID
                                                --INNER JOIN dbo.eStockSalesDtl ssd ON ssd.wStockSalesRid = tmp.RowID
                                                --                                     AND ( tmp.RecordState = 'U'
                                                --                                          OR tmp.RecordState = 'D'
                                                --                                         )
                                                --                                     AND ( tmp.wRecipientAgentCodeIn <> ''
                                                --                                           OR tmp.wRecipientAgentCodeIn <> ss.wRecipientAgentCodeIn
                                                --                                         )
                                                --INNER JOIN dbo.mItem i ON i.RowID = ssd.wItemRid
                                                LEFT JOIN eGift g ON g.wRefTableRid = tmp.RowID
                                                                     AND g.wStatus = 'A'
                                                LEFT JOIN RollsMary.dbo.mDepartment d ON d.wCode = g.wReqDeptCd
                                                                                         AND d.wActive = 'A'
                                                
                                                INNER JOIN RollsMary.dbo.mAgent a ON a.wAgentCodeIn = ss.wDebitAgentCodeIn
                                     FOR
                                       XML RAW('Record') ,
                                           ROOT('DataSet')
                                     );
                                                         
                    EXEC spa.SetGift @sXMLeGift, -- xml
                        @pMainCompNo, -- int
                        @pTestMode = 0, -- int
                        @pNonceToken = '', -- varchar(64)
                        @pReturnResultSet = 'N', -- char(1)
                        @pErrCode = 0, -- int
                        @pErrMsg = N''; -- nvarchar(200)     
                END;               
                ---------------------------------------------------------------------------------------------
                -- End Add eGift record
                ---------------------------------------------------------------------------------------------
                
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetStockSales
                        WHERE   RecordState = 'I' )
                BEGIN

                    IF NOT EXISTS ( SELECT  1
                                    FROM    sys.objects
                                    WHERE   object_id = OBJECT_ID('seqeStockSalesRefNo')
                                            AND type = 'SO' )
                        BEGIN
                            CREATE SEQUENCE seqeStockSalesRefNo START WITH 1 INCREMENT BY 1 MAXVALUE 9999999 CYCLE
                        END								

                    -- Set RowID by Sequence , wRefNo Auto Generate (yymmdd +sequence)
                    UPDATE  #sDataSet_SetStockSales
                    SET     RowID = 0
                    WHERE   RecordState = 'I';
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetStockSales;

                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            IF EXISTS ( SELECT  1
                                        FROM    #sDataSet_SetStockSales
                                        WHERE   RecordState = 'I'
                                                AND wRowNum = @sRuningIndex )
                                BEGIN
                                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
                                    UPDATE  #sDataSet_SetStockSales
                                    SET     RowID = @sRowID ,
                                            wRefNo = CONVERT(VARCHAR(6), SYSDATETIME(), 12) + FORMAT(NEXT VALUE FOR dbo.seqeStockSalesRefNo, '0000000')
                                    WHERE   wRowNum = @sRuningIndex;
                                END;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;	

                    INSERT  INTO [dbo].[eStockSales]
                                (	
                                    RowID ,
                                    wDebitCompNo ,
                                    wDebitCounterRid ,
                                    wOutWarehouseRid ,
                                    wRefNo ,
                                    wSalesType ,
                                    wPaymentMethod ,
                                    wSalesDt ,
                                    wSalesDeptCd ,
                                    wDebitDt ,
                                    wSalesmanRid ,
                                    wDebitAgentCodeIn ,
                                    wRecipientAgentCodeIn ,
                                    wCurrCode ,
                                    wSalesTotalPrice ,
                                    wExpenseAmount ,
                                    wGiftReasonCd ,
                                    wSalesStatus ,
                                    wStatus ,
                                    wCrtDt ,
                                    wCrtBy ,
                                    wUpdDt ,
                                    wUpdBy ,
                                    wCancelDebitBy ,
                                    wCancelDebitDt ,
                                    wCancelBy ,
                                    wCancelDt ,
                                    wCancelReasonCd ,
                                    wCancelOtherReason,
                                    wTotalCost,
                                    wRemark,
                                    wIsBorrowGoods 
                            )
                            SELECT  									
                                    RowID ,
                                    wDebitCompNo ,
                                    wDebitCounterRid ,
                                    wOutWarehouseRid ,
                                    wRefNo ,
                                    wSalesType ,
                                    wPaymentMethod ,
                                    wSalesDt ,
                                    wSalesDeptCd ,
                                    wDebitDt ,
                                    wSalesmanRid ,
                                    wDebitAgentCodeIn ,
                                    wRecipientAgentCodeIn ,
                                    wCurrCode ,
                                    wSalesTotalPrice ,
                                    wExpenseAmount ,
                                    wGiftReasonCd ,
                                    wSalesStatus ,
                                    wStatus ,
                                    @sNow ,
                                    wCrtBy ,
                                    @sNow ,
                                    wUpdBy ,
                                    wCancelDebitBy ,
                                    wCancelDebitDt ,
                                    wCancelBy ,
                                    wCancelDt ,
                                    wCancelReasonCd ,
                                    ISNULL(wCancelOtherReason,''),
                                    wTotalCost,
                                    wRemark,
                                    wIsBorrowGoods  
                            FROM    #sDataSet_SetStockSales
                            WHERE   RecordState = 'I';
                END;
            

            -- Recal Inventory
            SET @sRecalInventoryXML = ( SELECT  DISTINCT
                                                ssd.wItemRid ,
                                                CAST(0 AS BIGINT) AS wInWarehouseRid ,
                                                tmp.wOutWarehouseRid ,
                                                ssi.wPurchaseRid
                                        FROM    #sDataSet_SetStockSales tmp
                                                LEFT JOIN dbo.eStockSalesDtl ssd ON ssd.wStockSalesRid = tmp.RowID
                                                LEFT JOIN dbo.eStockSalesItem ssi ON ssi.wStockSalesDtlRid = ssd.RowID
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
                        FROM    #sDataSet_SetStockSales
                        WHERE   RecordState = 'U' )
                BEGIN
                    UPDATE  ss_t
                    SET     wDebitCounterRid = tmp.wDebitCounterRid ,
                            wDebitCompNo = tmp.wDebitCompNo ,
                            wOutWarehouseRid = tmp.wOutWarehouseRid ,
                            wRefNo = tmp.wRefNo ,
                            wSalesType = tmp.wSalesType ,
                            wPaymentMethod = tmp.wPaymentMethod ,                           
                            wSalesDt = tmp.wSalesDt ,
                            wSalesDeptCd = tmp.wSalesDeptCd ,
                            wDebitDt = tmp.wDebitDt ,
                            wSalesmanRid = tmp.wSalesmanRid ,
                            wDebitAgentCodeIn = tmp.wDebitAgentCodeIn ,
                            wRecipientAgentCodeIn = tmp.wRecipientAgentCodeIn ,
                            wCurrCode = tmp.wCurrCode ,
                            wSalesTotalPrice = tmp.wSalesTotalPrice ,
                            wExpenseAmount = tmp.wExpenseAmount ,
                            wSalesStatus = tmp.wSalesStatus ,
                            wGiftReasonCd = tmp.wGiftReasonCd ,
                            wStatus = tmp.wStatus ,
                            wUpdDt = @sNow ,
                            wUpdBy = tmp.wUpdBy, 
                            wCancelDebitBy  = tmp.wCancelDebitBy ,
                            wCancelDebitDt  = CASE WHEN tmp.wSalesStatus ='REFUND' THEN tmp.wCancelDebitDt ELSE NULL END ,
                            wCancelBy  = tmp.wCancelBy ,
                            wCancelDt  = CASE WHEN tmp.wSalesStatus IN ('VOID', 'REFUND') THEN tmp.wCancelDt ELSE NULL END ,
                            wCancelReasonCd = tmp.wCancelReasonCd ,
                            wCancelOtherReason = ISNULL(tmp.wCancelOtherReason ,''),
                            wTotalCost =tmp.wTotalCost,
                            wRemark =tmp.wRemark,
                            wIsBorrowGoods =tmp.wIsBorrowGoods,
                            wPickupDt =tmp.wPickupDt 
                    FROM    [dbo].[eStockSales] ss_t
                            INNER JOIN #sDataSet_SetStockSales tmp ON ss_t.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'U';
                END;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetStockSales
                        WHERE   RecordState = 'D' )
                BEGIN			
                    UPDATE  ss_t
                    SET     wStatus = 'T' ,
                            wUpdDt = @sNow 
                            --wCancelDebitDt  = CASE WHEN tmp.wSalesStatus ='REFUND' THEN @sNow ELSE NULL END ,
                            --wCancelDt  = CASE WHEN tmp.wSalesStatus ='VOID' THEN @sNow ELSE NULL END 
                    FROM    [dbo].[eStockSales] ss_t
                            INNER JOIN #sDataSet_SetStockSales tmp ON ss_t.RowID = tmp.RowID
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
            FROM    #sDataSet_SetStockSales;	
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
        IF OBJECT_ID('tempdb..#sDataSet_SetStockSales') IS NOT NULL
            DROP TABLE #sDataSet_SetStockSales;
        IF OBJECT_ID('tempdb..#sSalesDtlList') IS NOT NULL
            DROP TABLE #sSalesDtlList;
        
    END;