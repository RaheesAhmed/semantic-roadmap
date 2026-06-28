
CREATE PROCEDURE [spa].[SetStockSalesDtl]
    (
      @pXML XML ,
      @pMainCompNo INT ,
      @pCompNo INT ,
	  --@pServiceCounterRid BIGINT,
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
  --      	TempRowID bigint not null
		--)
		--Select * from @sRtnList
		--return

        DECLARE @sThisTableName VARCHAR(50) = 'eStockSalesDtl' ,
            @sBeginTranCount INT = 0 ,
            @sDocHandle INT ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sNow DATETIME2 = dbo.fnUTC8Now() ,
            @sCompNo INT ,
            @sCageCodeIn VARCHAR(14);

        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
		
        SELECT  @sCageCodeIn = wCageCodeIn
        FROM    RollsMary.dbo.mCage
        WHERE   wCompNo = @pCompNo;

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ) ,
                *
        INTO    #sDataSet_SetStockSalesDtl
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
			 RowID BIGINT, 
             wStockSalesRid BIGINT, 
             wItemRid BIGINT, 
             wTotalCostHKD NUMERIC(18,4), 
             wTotalPriceHKD NUMERIC(18,4), 
             wUnitPriceHKD NUMERIC(18, 4),
			 wQty INT, 
             wStatus CHAR(1), 
             wCrtDt DATETIME2, 
             wCrtBy BIGINT, 
             wUpdDt DATETIME2, 
             wUpdBy BIGINT, 
             RecordState VARCHAR(1),
             TempRowID BIGINT,
             wLotNo VARCHAR(50)
             );        
		 
        BEGIN TRY	                
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
        	
            --SET @sCompNo = ( SELECT TOP 1
            --                        wRollexCompNo
            --                 FROM   dbo.mServiceCounter
            --                 WHERE  RowID = @pServiceCounterRid
            --               );

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetStockSalesDtl
                        WHERE   RecordState = 'I' )
                BEGIN
					-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetStockSalesDtl
                    SET     RowID = 0
                    WHERE   RecordState = 'I';
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetStockSalesDtl;

                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            IF EXISTS ( SELECT  1
                                        FROM    #sDataSet_SetStockSalesDtl
                                        WHERE   RecordState = 'I'
                                                AND wRowNum = @sRuningIndex )
                                BEGIN
                                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
                                    UPDATE  #sDataSet_SetStockSalesDtl
                                    SET     RowID = @sRowID
                                    WHERE   wRowNum = @sRuningIndex;
                                END;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;	

                    INSERT  INTO [dbo].[eStockSalesDtl]
                            ( RowID ,
                              wStockSalesRid ,
                              wItemRid ,
                              wTotalCostHKD ,
                              wTotalPriceHKD ,
                              wUnitPriceHKD ,
                              wQty ,
                              wStatus ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy ,
                              wLotNo
                            )
                            SELECT  RowID ,
                                    wStockSalesRid ,
                                    wItemRid ,
                                    wTotalCostHKD ,
                                    wTotalPriceHKD ,
                                    wUnitPriceHKD ,
                                    wQty ,
                                    wStatus ,
                                    @sNow ,
                                    wCrtBy ,
                                    @sNow ,
                                    wUpdBy,
                                    ISNUll(wLotNo,'')
                            FROM    #sDataSet_SetStockSalesDtl
                            WHERE   RecordState = 'I';
                END;
			
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetStockSalesDtl
                        WHERE   RecordState = 'U' )
                BEGIN				

                    UPDATE  ssd_t
                    SET     wStockSalesRid = tmp.wStockSalesRid ,
                            wItemRid = tmp.wItemRid ,
                            wTotalCostHKD = tmp.wTotalCostHKD ,
                            wTotalPriceHKD = tmp.wTotalPriceHKD ,
                            wUnitPriceHKD = tmp.wUnitPriceHKD ,
                            wQty = tmp.wQty ,
                            wStatus = tmp.wStatus ,
                            wUpdDt = @sNow ,
                            wUpdBy = tmp.wUpdBy
                    FROM    [dbo].[eStockSalesDtl] ssd_t
                            INNER JOIN #sDataSet_SetStockSalesDtl tmp ON ssd_t.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'U';
                END;


            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetStockSalesDtl
                        WHERE   RecordState = 'D' )
                BEGIN			
                    UPDATE  ssd_t
                    SET     wStatus = 'T' ,
                            wUpdDt = @sNow
                    FROM    [dbo].[eStockSalesDtl] ssd_t
                            INNER JOIN #sDataSet_SetStockSalesDtl tmp ON ssd_t.RowID = tmp.RowID
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
            FROM    #sDataSet_SetStockSalesDtl;	
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
        IF OBJECT_ID('tempdb..#sDataSet_SetStockSalesDtl') IS NOT NULL
            DROP TABLE #sDataSet_SetStockSalesDtl;
    END;