CREATE PROCEDURE [spa].[SetCashTransferCageDtl]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
    )
AS 
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sThisTableName VARCHAR(50) = 'eCashTransferCageDtl' , -- For RowID 
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
                
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
        
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
        
 
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetCashTransferCageDtl
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
        WITH (
                
            RowID BIGINT, 
            wCashTranID BIGINT, 
            wCageCodeIn VARCHAR(14), 
            wAmount NUMERIC(18,4), 
            wCurrCd VARCHAR(30), 
            wCurrRate NUMERIC(18,4), 
            wCrtDt DATETIME2(7), 
            wCrtBy BIGINT, 
            wUpdDt DATETIME2(7), 
            wUpdBy BIGINT

        );
        
        BEGIN TRY
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF @pActionType = 'I'
                BEGIN
                -- Set RowID by Sequence
                    UPDATE  #sDataSet_SetCashTransferCageDtl
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetCashTransferCageDtl;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
                    
                            UPDATE  #sDataSet_SetCashTransferCageDtl
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
                
                    INSERT  INTO dbo.[eCashTransferCageDtl]
                            ( RowID ,
                              wCashTranID ,
                              wCageCodeIn ,
                              wAmount ,
                              wCurrCd ,
                              wCurrRate ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy
                            )
                            SELECT
                                    RowID ,
                                    wCashTranID ,
                                    wCageCodeIn ,
                                    wAmount ,
                                    wCurrCd ,
                                    wCurrRate ,
                                    wCrtDt ,
                                    wCrtBy ,
                                    wUpdDt ,
                                    wUpdBy
                            FROM    #sDataSet_SetCashTransferCageDtl s;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  d
                        SET     							
                                wCashTranID = tmp.wCashTranID ,
                                wCageCodeIn = tmp.wCageCodeIn ,
                                wAmount = tmp.wAmount ,
                                wCurrCd = tmp.wCurrCd ,
                                wCurrRate = tmp.wCurrRate ,                              
                                wUpdDt = dbo.fnUTC8Now() ,
                                wUpdBy = tmp.wUpdBy
                        FROM    dbo.eCashTransferCageDtl AS d
                                INNER JOIN #sDataSet_SetCashTransferCageDtl tmp ON d.RowID = tmp.RowID
                        WHERE   d.RowID = tmp.RowID;
                    END;
                

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
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
                    SET @pErrCode = 999;
                END;
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ',
                                  @sCatchErrorMessage);
            
            IF @sBeginTranCount = 0
                BEGIN
                    IF @xstate != 0
                        ROLLBACK;
                    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo,
                        @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT,
                        @sErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;

        END CATCH;
    
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetCashTransferCageDtl') IS NOT NULL
            DROP TABLE #sDataSet_SetCashTransferCageDtl;		
    END;