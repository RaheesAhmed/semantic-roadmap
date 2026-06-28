CREATE PROCEDURE [spq].[GetStockSalesItemLstByItem]
    @pWarehouseRid BIGINT ,
    @pItemRid BIGINT ,
    @pAgentCodeIn VARCHAR(14) ,
    @pQty INT
AS
    BEGIN
        SET NOCOUNT ON;	  	
                
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 
            
        ----------result set-----------
        /*
        DECLARE @sResultSet TABLE
            (
              RowID BIGINT NOT NULL ,
              wRowNum BIGINT NULL ,
              wPurchaseRid BIGINT NOT NULL ,
              wLotNo VARCHAR(50) NOT NULL ,
              wBatchNo VARCHAR(50) NOT NULL ,
              wQty INT NOT NULL ,
              wRunningTotalQty INT NULL ,
              wCost NUMERIC NOT NULL ,
              wUnitCost NUMERIC NOT NULL ,
              wCurrCode CHAR(3) NOT NULL ,
              wCurrRate NUMERIC NOT NULL ,
              wStatus CHAR(1) NOT NULL ,
              RecordState CHAR(1) NULL
            );     
        SELECT  *
        FROM    @sResultSet;
        RETURN;
        */
        ---------end result set--------			        

        DECLARE @sLastRowNum AS INT;
    
        SET @pAgentCodeIn = ISNULL(@pAgentCodeIn, '');
        SET @pQty = ISNULL(@pQty, 0);

        SELECT  si.RowID ,
                wRowNum = ROW_NUMBER() OVER ( ORDER BY p.wAgentCodeIn DESC, p.wUpdDt ASC ) ,
                si.wPurchaseRid ,
                p.wLotNo ,
                p.wBatchNo ,
                si.wQty ,
                wRunningTotalQty=SUM(CASE WHEN si.wQty<=0 THEN 0 ELSE si.wQty END) OVER ( ORDER BY p.wAgentCodeIn DESC, p.wUpdDt ASC ROWS UNBOUNDED PRECEDING ),
                p.wCost ,--采购总成本
                dtl.wUnitCost,--每个货品成本
                p.wCurrCode ,
                p.wCurrRate ,
                si.wStatus ,
                CAST('N' AS CHAR(1)) AS RecordState
        INTO    #sDataSet_GetStockSalesItemLstByItem
        FROM    dbo.eStockInventory si
                LEFT JOIN dbo.ePurchase p ON p.RowID = si.wPurchaseRid AND si.wStatus ='A'
                LEFT JOIN dbo.ePurchaseDtl dtl ON p.RowID=dtl.wPurchaseRid AND si.wItemRid=dtl.wItemRid AND dtl.wStatus = 'A'
        WHERE   si.wWarehouseRid = @pWarehouseRid
                AND si.wItemRid = @pItemRid
                AND ( p.wAgentCodeIn = @pAgentCodeIn		-- 只有客人預訂 / 一般銷售, 但採購Stock數是分開, 即街客不可拿取客人預訂D貨
                --      OR @pAgentCodeIn = ''
                      );
					  
        SELECT  ssi.RowID ,
                ssi.wRowNum ,
                ssi.wPurchaseRid ,
                ssi.wLotNo ,
                ssi.wBatchNo ,
                ssi.wQty ,
                ssi.wRunningTotalQty,
                ssi.wCost ,
                ssi.wUnitCost,
                ssi.wCurrCode ,
                ssi.wCurrRate ,
                ssi.wStatus ,
                CAST('N' AS CHAR(1)) AS RecordState
        INTO    #sDataSet_GetStockSalesItemLstByItem_Result
        FROM    #sDataSet_GetStockSalesItemLstByItem ssi
        WHERE   ssi.wRunningTotalQty < @pQty 

        SET @sLastRowNum = ISNULL(( SELECT  MAX(wRowNum)
                                    FROM    #sDataSet_GetStockSalesItemLstByItem_Result
                                  ), 0) + 1;

        IF @sLastRowNum <= ( SELECT MAX(wRowNum)
                             FROM   #sDataSet_GetStockSalesItemLstByItem
                           )
            BEGIN
                INSERT  INTO #sDataSet_GetStockSalesItemLstByItem_Result
                        ( RowID ,
                          wRowNum ,
                          wPurchaseRid ,
                          wLotNo ,
                          wBatchNo ,
                          wQty ,
                          wRunningTotalQty ,
                          wCost ,
                          wUnitCost,
                          wCurrCode ,
                          wCurrRate ,
                          wStatus ,
                          RecordState
                        )
                        SELECT  ssi.RowID ,
                                ssi.wRowNum ,
                                ssi.wPurchaseRid ,
                                ssi.wLotNo ,
                                ssi.wBatchNo ,
                                ssi.wQty - ( ssi.wRunningTotalQty - @pQty ) AS wQty ,
                                ssi.wRunningTotalQty ,
                                ssi.wCost ,
                                ssi.wUnitCost,
                                ssi.wCurrCode ,
                                ssi.wCurrRate ,
                                ssi.wStatus ,
                                CAST('N' AS CHAR(1)) AS RecordState
                        FROM    #sDataSet_GetStockSalesItemLstByItem ssi
                        WHERE   ssi.wRowNum = @sLastRowNum;
            END;

        SELECT  ssi.RowID ,
                ssi.wRowNum ,
                ssi.wPurchaseRid ,
                ssi.wLotNo ,
                ssi.wBatchNo ,
                ssi.wQty ,
                ssi.wRunningTotalQty ,
                ssi.wCost ,
                ssi.wUnitCost,
                ssi.wCurrCode ,
                ssi.wCurrRate ,
                ssi.wStatus ,
                CAST('N' AS CHAR(1)) AS RecordState
        FROM    #sDataSet_GetStockSalesItemLstByItem_Result ssi
        WHERE  ssi.wQty > 0; ---如果wQty<=0 则不需要读出来了，该批次号已经用完了

        IF OBJECT_ID('tempdb..#sDataSet_GetStockSalesItemLstByItem') IS NOT NULL
            DROP TABLE #sDataSet_GetStockSalesItemLstByItem;    

        IF OBJECT_ID('tempdb..#sDataSet_GetStockSalesItemLstByItem_Result') IS NOT NULL
            DROP TABLE #sDataSet_GetStockSalesItemLstByItem_Result;     
    END;