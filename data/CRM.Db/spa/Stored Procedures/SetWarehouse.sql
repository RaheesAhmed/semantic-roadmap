
CREATE PROCEDURE [spa].[SetWarehouse]
    (
      @pXML XML ,
      @pMainCompNo INT ,
      @pTestMode INT = 0 , -- 0: Normal(Non-Test), 1: UnitTest, 2: Scenario Test
      @pNonceToken VARCHAR(64) ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) OUTPUT
    )
AS /* Sample
EXEC spa.SetWarehouse 
	@pXML = N'<DataSet><Record RowID="0" wDepartmentCode="ACS" wCName="??" wEName="Alliance" wStatus="A" wIsDefault="N" wCounterRid=0 wCrtDt="2017-01-01" wUpdDt="2017-01-03" RecordState="I"/></DataSet>', -- xml
	@pMainCompNo = 10, -- int
	@pTestMode = 1, -- int
	@pNonceToken = '', -- varchar(64)
	@pErrCode = 0, -- int
	@pErrMsg = N'' -- nvarchar(200)	
*/
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

        DECLARE @sThisTableName VARCHAR(50) = 'mWarehouse' ,
            @sBeginTranCount INT = 0 ,
            @sDocHandle INT ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sNow DATETIME2 = dbo.fnUTC8Now();
        
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
        
		-- dbml
		--declare @sRtnList table (
		--	RowID bigint not null
		--)
		--Select * from @sRtnList
		--RETURN
        
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ) ,
                *
        INTO    #sDataSet_SetWarehouse
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
	    WITH (
           RowID BIGINT, 
           wDepartmentCode VARCHAR(30), 
           wCName NVARCHAR(100), 
           wEName VARCHAR(100), 
           wCounterRid BIGINT, 
           wIsDefault CHAR(1), 
           wStatus CHAR(1), 
           wCrtDt DATETIME2, 
           wUpdDt DATETIME2, 
           RecordState VARCHAR(1)
        );        
        BEGIN TRY

            --進行刪除操作要做checking 是否有使用的記錄 有就不给删除
            IF  EXISTS ( SELECT * FROM #sDataSet_SetWarehouse WHERE wStatus='T') AND
                (
                    EXISTS ( SELECT * FROM #sDataSet_SetWarehouse ds                             
                             INNER JOIN dbo.ePurchase purchase ON purchase.wInWarehouseRid = ds.RowID
                            ) OR
                    EXISTS ( SELECT * FROM #sDataSet_SetWarehouse ds
                             INNER JOIN dbo.eStockMovement movement ON movement.wInWarehouseRid = ds.RowID OR movement.wOutWarehouseRid = ds.RowID
                            ) OR
                    EXISTS ( SELECT * FROM #sDataSet_SetWarehouse ds
                             INNER JOIN dbo.eStockAdjustment adjust ON adjust.wWarehouseRid = ds.RowID
                            ) OR
                     EXISTS ( SELECT * FROM #sDataSet_SetWarehouse ds
                             INNER JOIN dbo.eStockSales sales ON sales.wOutWarehouseRid = ds.RowID
                            )                   
                )              
                BEGIN                           
                    SET @pErrMsg=[dbo].[fnGetErrorMsg]('3005','zh-TW');
                    THROW 50001, @pErrMsg, 1;
                END;         

			-- check next step valid or not
            IF ( ( SELECT   COUNT(*)
                   FROM     #sDataSet_SetWarehouse wh
                            INNER JOIN dbo.mWarehouse w ON w.wDepartmentCode = wh.wDepartmentCode
                                                           AND w.wCounterRid = wh.wCounterRid
                                                           AND w.wIsDefault = wh.wIsDefault
                   WHERE    wh.RecordState = 'I'
                            AND w.wStatus = 'A'
                            AND w.wIsDefault = 'Y'
                 ) + ( SELECT   COUNT(*)
                       FROM     #sDataSet_SetWarehouse wh
                                INNER JOIN dbo.mWarehouse w ON w.wDepartmentCode = wh.wDepartmentCode
                                                               AND w.wCounterRid = wh.wCounterRid
                                                               AND w.wIsDefault = wh.wIsDefault
                       WHERE    wh.RecordState = 'U'
                                AND w.wStatus = 'A'
                                AND w.wIsDefault = 'Y'
                                AND w.RowID <> wh.RowID
                     ) ) > 0
                BEGIN			                    
                    ;
                    THROW 70003, 'not allow to duplicate default setting', 1;
                END;
					                
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
        		
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetWarehouse
                        WHERE   RecordState = 'I' )
                BEGIN
					-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetWarehouse
                    SET     RowID = 0
                    WHERE   RecordState = 'I';
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetWarehouse;

                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            IF EXISTS ( SELECT  1
                                        FROM    #sDataSet_SetWarehouse
                                        WHERE   RecordState = 'I'
                                                AND wRowNum = @sRuningIndex )
                                BEGIN
                                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
                                    UPDATE  #sDataSet_SetWarehouse
                                    SET     RowID = @sRowID
                                    WHERE   wRowNum = @sRuningIndex;
                                END;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;	

                    INSERT  INTO [dbo].[mWarehouse]
                            ( RowID ,
                              wDepartmentCode ,
                              wCName ,
                              wEName ,
                              wCounterRid ,
                              wIsDefault ,
                              wStatus ,
                              wCrtDt ,
                              wUpdDt
                            )
                            SELECT  RowID ,
                                    wDepartmentCode ,
                                    wCName ,
                                    wEName ,
                                    wCounterRid ,
                                    wIsDefault ,
                                    wStatus ,
                                    @sNow ,
                                    @sNow
                            FROM    #sDataSet_SetWarehouse
                            WHERE   RecordState = 'I';
                END;
			
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetWarehouse
                        WHERE   RecordState = 'U' )
                BEGIN
                    UPDATE  w_t
                    SET     wDepartmentCode = tmp.wDepartmentCode ,
                            wCName = tmp.wCName ,
                            wEName = tmp.wEName ,
                            wCounterRid = tmp.wCounterRid ,
                            wIsDefault = tmp.wIsDefault ,
                            wStatus = tmp.wStatus ,
                            wCrtDt = tmp.wCrtDt ,
                            wUpdDt = @sNow
                    FROM    [dbo].[mWarehouse] w_t
                            INNER JOIN #sDataSet_SetWarehouse tmp ON w_t.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'U';
                END;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetWarehouse
                        WHERE   RecordState = 'D' )
                BEGIN			
                    UPDATE  w_t
                    SET     wStatus = 'T' ,
                            wUpdDt = @sNow
                    FROM    [dbo].[mWarehouse] w_t
                            INNER JOIN #sDataSet_SetWarehouse tmp ON w_t.RowID = tmp.RowID
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
            FROM    #sDataSet_SetWarehouse;	
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
        IF OBJECT_ID('tempdb..#sDataSet_SetWarehouse') IS NOT NULL
            DROP TABLE #sDataSet_SetWarehouse;
    END;