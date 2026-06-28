CREATE PROCEDURE [util].[RecalInventory]
    (
      @pXML XML ,
      @pMainCompNo INT ,
      @pTestMode INT = 0 , -- 0: Normal(Non-Test), 1: UnitTest, 2: Scenario Test
      @pNonceToken VARCHAR(64) ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) OUTPUT
    )
    /*
    declare @pErrCode int, @pErrMsg NVARCHAR(200) 

        EXEC [test].[RecalInventory]
        @pXML = '<DataSet><Record wItemRid="10000000001006" wInWarehouseRid="10000000001007" wOutWarehouseRid="0" wPurchaseRid="10000000001196"/></DataSet>',
        --@pXML = '<DataSet><Record wItemRid="10000000001006" wInWarehouseRid="0" wOutWarehouseRid="0" wPurchaseRid="10000000001196"/></DataSet>',
        @pMainCompNo = 10,
        @pTestMode = 1,
        @pNonceToken = NULL,
        @pErrCode = @pErrCode OUTPUT,
        @pErrMsg = @pErrMsg OUTPUT
    */
AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

        DECLARE @sThisTableName VARCHAR(50) = 'eStockInventory' ,
            @sRecalInventoryXML NVARCHAR(MAX) = '' ,
            @sBeginTranCount INT = 0 ,
            @sDocHandle INT ,
            @sNow DATETIME2 = dbo.fnUTC8Now();

        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;

        SELECT  *
        INTO    #sDataSet_RecalInventory
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
    WITH ( wItemRid BIGINT, wInWarehouseRid BIGINT, wOutWarehouseRid BIGINT, wPurchaseRid BIGINT);        
        BEGIN TRY	                           
            -----------------Debug--------------------
            --SELECT  *
            --FROM    #sDataSet_RecalInventory;

            --WITH    ctePurchaseTest
            --          AS ( SELECT   'PURCHASE' AS wType ,
            --                        pd.RowID ,
            --                        pd.wQty AS wItemQty ,
            --                        ds.wItemRid ,
            --                        p.wInWarehouseRid AS wWarehouseRid ,
            --                        --ds.wOutWarehouseRid ,
            --                        pd.wPurchaseRid
            --               FROM     #sDataSet_RecalInventory ds
            --                        LEFT JOIN ePurchaseDtl pd ON pd.wItemRid = ds.wItemRid
            --                                                  AND ds.wPurchaseRid = pd.wPurchaseRid
            --                                                  AND pd.wStatus = 'A'
            --                        LEFT JOIN dbo.ePurchase p ON p.RowID = pd.wPurchaseRid
            --                                                  AND ( p.wInWarehouseRid = ds.wInWarehouseRid
            --                                                  OR p.wInWarehouseRid = ds.wOutWarehouseRid
            --                                                  )
            --                                                  AND p.wStatus = 'A'
            --                                                  AND p.wPurchaseStatus = 'COMPLETE'
            --             )
            --    SELECT  *
            --    FROM    ctePurchaseTest;

            --WITH    cteInMovementTest
            --          AS ( SELECT   'IN_MOVEMENT' AS wType ,
            --                        smi.RowID ,
            --                        smi.wQty AS wItemQty ,
            --                        smd.wItemRid ,
            --                        sm.wInWarehouseRid AS wWarehouseRid ,
            --                        --ds.wOutWarehouseRid ,
            --                        smi.wPurchaseRid
            --               FROM     dbo.eStockMovementItem smi
            --                        INNER JOIN dbo.eStockMovementDtl smd ON smd.RowID = smi.wStockMovementDtlRid
            --                        INNER JOIN dbo.eStockMovement sm ON sm.RowID = smd.wStockMovementRid
            --                        INNER JOIN #sDataSet_RecalInventory ds ON smd.wItemRid = ds.wItemRid
            --                                                  AND ds.wInWarehouseRid = sm.wInWarehouseRid
            --                                                  AND ds.wOutWarehouseRid = sm.wOutWarehouseRid
            --                                                  AND ds.wPurchaseRid = smi.wPurchaseRid
            --               WHERE    smd.wStatus = 'A'
            --                        AND sm.wStatus = 'A'
            --                        AND smi.wStatus = 'A'
            --                        AND sm.wMovementStatus = 'STOCK_IN'
            --             )
            --    SELECT  *
            --    FROM    cteInMovementTest;

            --WITH    cteOutMovementTest
            --          AS ( SELECT   'OUT_MOVEMENT' AS wType ,
            --                        smi.RowID ,
            --                        smi.wQty AS wItemQty ,
            --                        smd.wItemRid ,
            --                        --ds.wInWarehouseRid ,
            --                        sm.wOutWarehouseRid AS wWarehouseRid ,
            --                        smi.wPurchaseRid
            --               FROM     dbo.eStockMovementItem smi
            --                        INNER JOIN dbo.eStockMovementDtl smd ON smd.RowID = smi.wStockMovementDtlRid
            --                        INNER JOIN dbo.eStockMovement sm ON sm.RowID = smd.wStockMovementRid
            --                        INNER JOIN #sDataSet_RecalInventory ds ON smd.wItemRid = ds.wItemRid
            --                                                  AND ds.wOutWarehouseRid = sm.wOutWarehouseRid
            --                                                  AND ds.wInWarehouseRid = sm.wInWarehouseRid
            --                                                  AND ds.wPurchaseRid = smi.wPurchaseRid
            --               WHERE    smd.wStatus = 'A'
            --                        AND sm.wStatus = 'A'
            --                        AND smi.wStatus = 'A'
            --                        AND ( sm.wMovementStatus = 'STOCK_OUT'
            --                              OR sm.wMovementStatus = 'STOCK_IN'
            --                            )
            --             )
            --    SELECT  *
            --    FROM    cteOutMovementTest;

            --WITH    cteAdjustmentTest
            --          AS ( SELECT   'ADJUSTMENT' AS wType ,
            --                        sai.RowID ,
            --                        sai.wQty AS wItemQty ,
            --                        sad.wItemRid ,
            --                        sa.wWarehouseRid AS wWarehouseRid ,
            --                        --ds.wOutWarehouseRid ,
            --                        sai.wPurchaseRid
            --               FROM     dbo.eStockAdjustmentItem sai
            --                        INNER JOIN dbo.eStockAdjustmentDtl sad ON sad.RowID = sai.wStockAdjustmentDtlRid
            --                        INNER JOIN dbo.eStockAdjustment sa ON sa.RowID = sad.wStockAdjustmentRid
            --                        INNER JOIN #sDataSet_RecalInventory ds ON ds.wItemRid = sad.wItemRid
            --                                                  AND ( ds.wInWarehouseRid = sa.wWarehouseRid
            --                                                  OR ds.wOutWarehouseRid = sa.wWarehouseRid
            --                                                  )
            --                                                  AND ds.wPurchaseRid = sai.wPurchaseRid
            --               WHERE    sad.wStatus = 'A'
            --                        AND sa.wStatus = 'A'
            --                        AND sai.wStatus = 'A'
            --                        AND sa.wAdjustmentStatus = 'COMPLETE'
            --             )
            --    SELECT  *
            --    FROM    cteAdjustmentTest;

            --WITH    cteSalesTest
            --          AS ( SELECT   'SALES' AS wType ,
            --                        ssi.RowID ,
            --                        ssi.wQty AS wItemQty ,
            --                        ssd.wItemRid ,
            --                        --ds.wInWarehouseRid ,
            --                        ds.wOutWarehouseRid AS wWarehouseRid ,
            --                        ssi.wPurchaseRid
            --               FROM     dbo.eStockSalesItem ssi
            --                        INNER JOIN dbo.eStockSalesDtl ssd ON ssd.RowID = ssi.wStockSalesDtlRid
            --                        INNER JOIN dbo.eStockSales ss ON ss.RowID = ssd.wStockSalesRid
            --                        INNER JOIN #sDataSet_RecalInventory ds ON ds.wItemRid = ssd.wItemRid
            --                                                  AND ( ds.wOutWarehouseRid = ss.wOutWarehouseRid
            --                                                  OR ds.wInWarehouseRid = ss.wOutWarehouseRid
            --                                                  )
            --                                                  AND ds.wPurchaseRid = ssi.wPurchaseRid
            --               WHERE    ssd.wStatus = 'A'
            --                        AND ss.wStatus = 'A'
            --                        AND ssi.wStatus = 'A'
            --                        AND ss.wSalesStatus = 'COMPLETE'
            --             )
            --    SELECT  *
            --    FROM    cteSalesTest;
            -----------------EndDebug--------------------

            WITH    ctePurchase
                      AS ( SELECT   'PURCHASE' AS wType ,
                                    pd.wQty AS wItemQty ,
                                    ds.wItemRid ,
                                    p.wInWarehouseRid AS wWarehouseRid ,
                                    --ds.wOutWarehouseRid ,
                                    pd.wPurchaseRid
                           FROM     #sDataSet_RecalInventory ds
                                    LEFT JOIN ePurchaseDtl pd ON pd.wItemRid = ds.wItemRid
                                                                 AND ds.wPurchaseRid = pd.wPurchaseRid
                                                                 AND pd.wStatus = 'A'
                                    LEFT JOIN dbo.ePurchase p ON p.RowID = pd.wPurchaseRid
                                                                 AND ( p.wInWarehouseRid = ds.wInWarehouseRid
                                                                       OR p.wInWarehouseRid = ds.wOutWarehouseRid
                                                                     )
                                                                 AND p.wStatus = 'A'
                                                                 AND p.wPurchaseStatus = 'COMPLETE'
                         ),
                    cteInMovement
                      AS ( SELECT   'IN_MOVEMENT' AS wType ,
                                    smi.wQty AS wItemQty ,
                                    smd.wItemRid ,
                                    sm.wInWarehouseRid AS wWarehouseRid ,
                                    --ds.wOutWarehouseRid ,
                                    smi.wPurchaseRid
                           FROM     dbo.eStockMovementItem smi
                                    INNER JOIN dbo.eStockMovementDtl smd ON smd.RowID = smi.wStockMovementDtlRid
                                    INNER JOIN dbo.eStockMovement sm ON sm.RowID = smd.wStockMovementRid
                                    INNER JOIN #sDataSet_RecalInventory ds ON smd.wItemRid = ds.wItemRid
                                                                              AND (ds.wOutWarehouseRid = sm.wInWarehouseRid
                                                                                  OR ds.wInWarehouseRid = sm.wInWarehouseRid                                                                                       
                                                                                  )
                                                                              AND ds.wPurchaseRid = smi.wPurchaseRid
                           WHERE    smd.wStatus = 'A'
                                    AND sm.wStatus = 'A'
                                    AND smi.wStatus = 'A'
                                    AND sm.wMovementStatus = 'STOCK_IN'
                         ),
                    cteOutMovement
                      AS ( SELECT   'OUT_MOVEMENT' AS wType ,
                                    smi.wQty AS wItemQty ,
                                    CASE WHEN sm.wMovementStatus = 'STOCK_IN' THEN smi.wQty
                                         ELSE 0
                                    END AS wReleaseHoldQty ,				--狀態變為「入倉」後，停用數目要歸0  (Reset)
                                    smd.wItemRid ,
                                    --ds.wInWarehouseRid ,
                                    sm.wOutWarehouseRid AS wWarehouseRid ,
                                    smi.wPurchaseRid
                           FROM     dbo.eStockMovementItem smi
                                    INNER JOIN dbo.eStockMovementDtl smd ON smd.RowID = smi.wStockMovementDtlRid
                                    INNER JOIN dbo.eStockMovement sm ON sm.RowID = smd.wStockMovementRid
                                    INNER JOIN #sDataSet_RecalInventory ds ON smd.wItemRid = ds.wItemRid
                                                                              --AND ( ( ds.wOutWarehouseRid = sm.wOutWarehouseRid
                                                                              --        AND ( ds.wInWarehouseRid = sm.wInWarehouseRid
                                                                              --              OR ds.wInWarehouseRid = 0
                                                                              --            )
                                                                              --      )
                                                                              --      OR ( ds.wInWarehouseRid = sm.wOutWarehouseRid
                                                                              --         )
                                                                              --    )
                                                                              AND (ds.wOutWarehouseRid = sm.wOutWarehouseRid OR ds.wInWarehouseRid = sm.wOutWarehouseRid ) 
                                                                              AND ds.wPurchaseRid = smi.wPurchaseRid
                           WHERE    smd.wStatus = 'A'
                                    AND sm.wStatus = 'A'
                                    AND smi.wStatus = 'A'
                                    AND ( sm.wMovementStatus = 'STOCK_OUT'
                                          OR sm.wMovementStatus = 'STOCK_IN'
                                        )
                         ),
                    cteAdjustment
                      AS ( SELECT   'ADJUSTMENT' AS wType ,
                                    sai.wQty AS wItemQty ,
                                    sad.wItemRid ,
                                    sa.wWarehouseRid AS wWarehouseRid ,
                                    --ds.wOutWarehouseRid ,
                                    sai.wPurchaseRid
                           FROM     dbo.eStockAdjustmentItem sai
                                    INNER JOIN dbo.eStockAdjustmentDtl sad ON sad.RowID = sai.wStockAdjustmentDtlRid
                                    INNER JOIN dbo.eStockAdjustment sa ON sa.RowID = sad.wStockAdjustmentRid
                                    INNER JOIN #sDataSet_RecalInventory ds ON ds.wItemRid = sad.wItemRid
                                                                              AND ( ds.wInWarehouseRid = sa.wWarehouseRid
                                                                                    OR ds.wOutWarehouseRid = sa.wWarehouseRid
                                                                                  )
                                                                              AND ds.wPurchaseRid = sai.wPurchaseRid
                           WHERE    sad.wStatus = 'A'
                                    AND sa.wStatus = 'A'
                                    AND sai.wStatus = 'A'
                                    AND sa.wAdjustmentStatus = 'COMPLETE'
                         ),
                    cteSales
                      AS ( SELECT   'SALES' AS wType ,
                                    ssi.wQty AS wItemQty ,
                                    ds.wItemRid ,
                                    --ds.wInWarehouseRid ,
                                    --ds.wOutWarehouseRid AS wWarehouseRid ,
                                    ss.wOutWarehouseRid AS wWarehouseRid ,
                                    ssi.wPurchaseRid
                           FROM     dbo.eStockSalesItem ssi
                                    INNER JOIN dbo.eStockSalesDtl ssd ON ssd.RowID = ssi.wStockSalesDtlRid
                                    INNER JOIN dbo.eStockSales ss ON ss.RowID = ssd.wStockSalesRid
                                    INNER JOIN #sDataSet_RecalInventory ds ON ds.wItemRid = ssd.wItemRid
                                                                              AND ( ds.wOutWarehouseRid = ss.wOutWarehouseRid
                                                                                    OR ds.wInWarehouseRid = ss.wOutWarehouseRid
                                                                                  )
                                                                              AND ds.wPurchaseRid = ssi.wPurchaseRid
                           WHERE    ssd.wStatus = 'A'
                                    AND ss.wStatus = 'A'
                                    AND ssi.wStatus = 'A'
                                    AND ss.wSalesStatus = 'COMPLETE'
                         ),
                    cteData
                      AS (    --wWarehouseRid ,
                      --              p.wPurchaseRid ,
                      --              p.wItemRid ,
                      --              ( ISNULL(p.wItemQty, 0)
                      --                + ISNULL(i.wItemQty, 0)
                      --                - ISNULL(o.wItemQty, 0)
                      --                + ISNULL(a.wItemQty, 0) ) AS wQty ,
                      --              ISNULL(o.wItemQty, 0) AS wOnHoldQty ,
                      --              p.wItemQty AS wOriQty
                           SELECT   wType ,
                                    ISNULL(wItemQty, 0) AS wQty ,
                                    0 AS wReleaseHoldQty ,
                                    wItemRid ,
                                    wWarehouseRid ,
                                    wPurchaseRid
                           FROM     ctePurchase p
                           UNION ALL
                           SELECT   wType ,
                                    ISNULL(wItemQty, 0) AS wQty ,
                                    0 AS wReleaseHoldQty ,
                                    wItemRid ,
                                    wWarehouseRid ,
                                    wPurchaseRid
                           FROM     cteInMovement i
                           UNION ALL
                           SELECT   wType ,
                                    ISNULL(wItemQty, 0) AS wQty ,
                                    wReleaseHoldQty ,
                                    wItemRid ,
                                    wWarehouseRid ,
                                    wPurchaseRid
                           FROM     cteOutMovement o
                           UNION ALL
                           SELECT   wType ,
                                    ISNULL(wItemQty, 0) AS wQty ,
                                    0 AS wReleaseHoldQty ,
                                    wItemRid ,
                                    wWarehouseRid ,
                                    wPurchaseRid
                           FROM     cteAdjustment a
                           UNION ALL
                           SELECT   wType ,
                                    ISNULL(wItemQty, 0) AS wQty ,
                                    0 AS wReleaseHoldQty ,
                                    wItemRid ,
                                    wWarehouseRid ,
                                    wPurchaseRid
                           FROM     cteSales s
                         ),
                    cteResult
                      AS ( SELECT   CAST(0 AS BIGINT) AS RowID ,
                                    r.wWarehouseRid ,
                                    r.wPurchaseRid ,
                                    r.wItemRid ,
                                    SUM(r.wQty * CASE WHEN r.wType = 'OUT_MOVEMENT'
                                                           OR r.wType = 'SALES' THEN -1
                                                      ELSE 1
                                                 END) AS wQty ,
                                    SUM(CASE WHEN r.wType = 'OUT_MOVEMENT' THEN r.wQty - r.wReleaseHoldQty
                                             ELSE 0
                                        END) AS wOnHoldQty ,
                                    SUM(CASE WHEN r.wType = 'PURCHASE' THEN r.wQty
                                             ELSE 0
                                        END) AS wOriQty ,
                                    'N' AS RecordState
                           FROM     cteData r
                           GROUP BY r.wWarehouseRid ,
                                    r.wPurchaseRid ,
                                    r.wItemRid
                         )
                SELECT  CAST(0 AS BIGINT) AS RowID ,
                        r.wWarehouseRid ,
                        r.wPurchaseRid ,
                        r.wItemRid ,
                        SUM(r.wQty) AS wQty ,
                        SUM(wOnHoldQty) AS wOnHoldQty ,
                        SUM(wOriQty) AS wOriQty ,
                        'N' AS RecordState
                INTO    #sDataSet_RecalInventory_Result
                FROM    cteResult r
                WHERE   r.wWarehouseRid > 0
                        AND r.wPurchaseRid > 0
                        AND r.wItemRid > 0
                GROUP BY r.wWarehouseRid ,
                        r.wPurchaseRid ,
                        r.wItemRid;

            UPDATE  ri_result
            SET     RowID = ISNULL(si.RowID, 0) ,
                    RecordState = CASE WHEN si.RowID IS NULL THEN 'I'
                                       WHEN si.wQty <> ri_result.wQty
                                            OR si.wOnHoldQty <> ri_result.wOnHoldQty THEN 'U'
                                       ELSE 'N'
                                  END
            FROM    #sDataSet_RecalInventory_Result ri_result
                    LEFT JOIN dbo.eStockInventory si ON si.wItemRid = ri_result.wItemRid
                                                        AND si.wWarehouseRid = ri_result.wWarehouseRid
                                                        AND si.wPurchaseRid = ri_result.wPurchaseRid;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_RecalInventory_Result ri_result
                        WHERE   ri_result.wQty < 0 )
                BEGIN			 
                    SET @pErrMsg=dbo.fnGetErrorMsg('2007','zh-TW');
                    THROW 50001, @pErrMsg, 1;
                END;

            IF @pTestMode = 0
                BEGIN		
                    IF @sBeginTranCount = 0
                        BEGIN
                            BEGIN TRAN;
                        END;

                    SET @sRecalInventoryXML = ( SELECT  RowID ,
                                                        wWarehouseRid ,
                                                        wPurchaseRid ,
                                                        wItemRid ,
                                                        wQty ,
                                                        wOnHoldQty ,
                                                        wOriQty ,
                                                        RecordState
                                                FROM    #sDataSet_RecalInventory_Result tmp
                                              FOR
                                                XML RAW('Record') ,
                                                    ROOT('DataSet')
                                              );

                    --DECLARE @vTmp NVARCHAR(MAX);
                    ----SET @vTmp = (SELECT * FROM #sDataSet_SetHotelChange FOR XML RAW('Record'), ROOT ('DataSet'));
                    --SET @vTmp = CONVERT(NVARCHAR(MAX), @pXML);

                    --EXEC spa.WriteErrorLog @pMainCompNo = 0, -- int
                    --    @pCompNo = @pMainCompNo, -- int
                    --    @pLogCode = N'recal_xml', -- nvarchar(50)
                    --    @pLogInfo = @vTmp, -- nvarchar(max)
                    --    @pRtnCode = 0, -- int
                    --    @pErrMsg = '' -- nvarchar(2000)

                    EXEC spa.SetStockInventory @pXML = @sRecalInventoryXML, -- xml
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
                END;
            ELSE
                BEGIN
                    SELECT  *
                    FROM    #sDataSet_RecalInventory_Result; 
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

        IF OBJECT_ID('tempdb..#sDataSet_RecalInventory') IS NOT NULL
            DROP TABLE #sDataSet_RecalInventory;

        IF OBJECT_ID('tempdb..#sDataSet_RecalInventory_Result') IS NOT NULL
            DROP TABLE #sDataSet_RecalInventory_Result;
    END;