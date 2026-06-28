
CREATE PROCEDURE [spa].[SetPurchaseDtl]
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

        DECLARE @sThisTableName VARCHAR(50) = 'ePurchaseDtl' ,
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
        INTO    #sDataSet_SetPurchaseDtl
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
	WITH (
        RowID BIGINT, 
        wPurchaseRid BIGINT, 
        wCurrCode VARCHAR(3), 
        wCurrRate NUMERIC(12,6), 
        wUnitCost NUMERIC(18,4), 
        wQty INT, wStockInQty INT, 
        wItemRid BIGINT, 
        wInWarehouseRid BIGINT, 
        wStatus CHAR(1), 
        wCrtDt DATETIME2, 
        wCrtBy BIGINT, 
        wUpdDt DATETIME2, 
        wUpdBy BIGINT, 
        RecordState VARCHAR(1),
        wValidDate datetime2(7),
        wHandleStatus VARCHAR(10),
        wHandleRemark NVARCHAR(500));        
        BEGIN TRY	                
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            UPDATE  tmp
            SET     wInWarehouseRid = p.wInWarehouseRid
            FROM    #sDataSet_SetPurchaseDtl tmp
                    LEFT JOIN dbo.ePurchase p ON p.RowID = tmp.wPurchaseRid
            WHERE   p.wStatus = 'A';
        		
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetPurchaseDtl
                        WHERE   RecordState = 'I' )
                BEGIN
					-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetPurchaseDtl
                    SET     RowID = 0
                    WHERE   RecordState = 'I';
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetPurchaseDtl;

                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            IF EXISTS ( SELECT  1
                                        FROM    #sDataSet_SetPurchaseDtl
                                        WHERE   RecordState = 'I'
                                                AND wRowNum = @sRuningIndex )
                                BEGIN
                                    EXEC spq.GetRowID @pMainCompNo,
                                        @sThisTableName, @sRowID OUTPUT;
                                    UPDATE  #sDataSet_SetPurchaseDtl
                                    SET     RowID = @sRowID
                                    WHERE   wRowNum = @sRuningIndex;
                                END;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;	

                    INSERT  INTO [dbo].[ePurchaseDtl]
                            ( RowID ,
                              wPurchaseRid ,
                              wCurrCode ,
                              wCurrRate ,
                              wUnitCost ,
                              wQty ,
                              wStockInQty ,
                              wItemRid ,
                              wStatus ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy,
                              wValidDate,
                              wHandleStatus,
                              wHandleRemark
                            )
                            SELECT  RowID ,
                                    wPurchaseRid ,
                                    wCurrCode ,
                                    wCurrRate ,
                                    wUnitCost ,
                                    wQty ,
                                    wStockInQty ,
                                    wItemRid ,
                                    wStatus ,
                                    @sNow ,
                                    wCrtBy ,
                                    @sNow ,
                                    wUpdBy,
                                    wValidDate,
                                    ISNULL(wHandleStatus,''),
                                    ISNULL(wHandleRemark,'')
                            FROM    #sDataSet_SetPurchaseDtl
                            WHERE   RecordState = 'I';
                END;
			
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetPurchaseDtl
                        WHERE   RecordState = 'U' )
                BEGIN
                    UPDATE  pd_t
                    SET     wPurchaseRid = tmp.wPurchaseRid ,
                            wCurrCode = tmp.wCurrCode ,
                            wCurrRate = tmp.wCurrRate ,
                            wUnitCost = tmp.wUnitCost ,
                            wQty = tmp.wQty ,
                            wStockInQty = tmp.wStockInQty ,
                            wItemRid = tmp.wItemRid ,
                            wStatus = tmp.wStatus ,
                            wUpdDt = @sNow ,
                            wUpdBy = tmp.wUpdBy,
                            wValidDate = tmp.wValidDate,
                            wHandleStatus = ISNULL(tmp.wHandleStatus,''),
                            wHandleRemark = ISNULL(tmp.wHandleRemark,'')
                    FROM    [dbo].[ePurchaseDtl] pd_t
                            INNER JOIN #sDataSet_SetPurchaseDtl tmp ON pd_t.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'U';
                END;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetPurchaseDtl
                        WHERE   RecordState = 'D' )
                BEGIN
                    UPDATE  pd_t
                    SET     wStatus = 'T' ,
                            wUpdDt = @sNow
                    FROM    [dbo].[ePurchaseDtl] pd_t
                            INNER JOIN #sDataSet_SetPurchaseDtl tmp ON pd_t.RowID = tmp.RowID
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
            FROM    #sDataSet_SetPurchaseDtl;	
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
        IF OBJECT_ID('tempdb..#sDataSet_SetPurchaseDtl') IS NOT NULL
            DROP TABLE #sDataSet_SetPurchaseDtl;
    END;