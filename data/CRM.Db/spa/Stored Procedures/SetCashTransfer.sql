CREATE PROCEDURE [spa].[SetCashTransfer]
    (
      @pXML XML ,
      @pXMLTransferCentre XML ,
      @pMainCompNo INT ,
      @pMainCageCodeIn VARCHAR(14) ,
      @pMainCounter VARCHAR(2) ,
      @pCompNo INT ,
      @pCageCodeIn VARCHAR(14) ,
      @pAuthBy BIGINT ,
      @pType VARCHAR(20) ,
      @pRemark NVARCHAR(500) ,
      @pTestMode INT = 0 , -- 0: Normal(Non-Test), 1: UnitTest, 2: Scenario Test
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pCashTransferRid BIGINT OUTPUT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
    )
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sThisTableName VARCHAR(50) = 'eCashTransfer' ,
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sNow DATETIME2 = dbo.fnUTC8Now() ,
            @sGuid VARCHAR(30) ,
            @sTryRun CHAR(1) ,
            @sIsAutoAdjust CHAR(1) ,
            @sXMLStr NVARCHAR(MAX) = '',
            @sUpdBy BIGINT;

        DECLARE @refNo VARCHAR(30);

        SET @sBeginTranCount = @@trancount;
        SET @sTryRun = IIF(( @pTestMode != 0 ), 'Y', 'N');
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
    
        DECLARE  @tbl TABLE(
            wRowNum				  int				  NULL,
            RowID                 bigint              NULL,
            wRefNo                varchar(30)         NULL,
            wInCounterRid         bigint              NULL,
            wInAgentCodeIn        varchar(14)         NULL,
            wOutAgentCodeIn       varchar(14)         NULL,
            wIsAuthorized         char(1)             NULL DEFAULT('N'),
            wIsByPass             char(1)             NULL DEFAULT('N'),
            wIsIVRProcess         char(1)             NULL DEFAULT('N'),
            wInCurrCd             varchar(30)         NULL DEFAULT(''),
            wOutCurrCd            varchar(30)         NULL,
            wInCurrRate           numeric(18,4)       NULL DEFAULT((0)),
            wOutCurrRate          numeric(18,4)       NULL,
            wInAmount             numeric(18,4)       NULL DEFAULT((0)),
            wOutAmount            numeric(18,4)       NULL DEFAULT((0)),
            wIsAutoAdjust         char(1)             NULL DEFAULT('Y'),
            wTranDt               datetime2           NULL,
            wRollexCompNo         int                 NULL DEFAULT((0)),
            wDepositor            nvarchar(100)       NULL DEFAULT(''),
            wRemark               nvarchar(500)       NULL,
            wStatus               char(1)             NULL DEFAULT('A'),
            wCashTransferStatus   varchar(5)          NULL,
            wTransferGUID         varchar(30)         NULL,
            wRelatedBookingRefNo  varchar(500)        NULL,
            wCrtBy                bigint              NULL,
            wCrtDt                datetime2(7)        NULL,
            wUpdBy                bigint              NULL,
            wUpdDt                datetime2(7)        NULL,
            RecordState			  VARCHAR(1)		  NULL,
            wExchangeFxRate       numeric(12,6)       NULL DEFAULT((0))
        );
        
        --SELECT * FROM @tbl;
        --RETURN;
        INSERT INTO @tbl(
            wRowNum,
            RowID,
            wRefNo,
            wInCounterRid,
            wInAgentCodeIn,
            wOutAgentCodeIn,
            wIsAuthorized,
            wIsByPass,
            wIsIVRProcess,
            wInCurrCd,
            wOutCurrCd,
            wInCurrRate,
            wOutCurrRate,
            wInAmount,
            wOutAmount,
            wIsAutoAdjust,
            wTranDt,
            wRollexCompNo,
            wDepositor,
            wRemark,
            wStatus,
            wCashTransferStatus,
            wTransferGUID,
            wRelatedBookingRefNo,
            wCrtBy,
            wCrtDt,
            wUpdBy,
            wUpdDt,
            RecordState,
            wExchangeFxRate
        )
        (SELECT
            wRowNum = ROW_NUMBER() OVER ( ORDER BY b.value('@wUpdDt[1]', 'datetime2(7)')),
            b.value('@RowID[1]', 'bigint') AS RowID,
            b.value('@wRefNo[1]', 'varchar(30)') AS wRefNo,
            b.value('@wInCounterRid[1]', 'bigint') AS wInCounterRid,
            b.value('@wInAgentCodeIn[1]', 'varchar(14)') AS wInAgentCodeIn,
            b.value('@wOutAgentCodeIn[1]', 'varchar(14)') AS wOutAgentCodeIn,
            b.value('@wIsAuthorized[1]', 'char(1)') AS wIsAuthorized,
            b.value('@wIsByPass[1]', 'char(1)') AS wIsByPass,
            b.value('@wIsIVRProcess[1]', 'char(1)') AS wIsIVRProcess,
            b.value('@wInCurrCd[1]', 'varchar(30)') AS wInCurrCd,
            b.value('@wOutCurrCd[1]', 'varchar(30)') AS wOutCurrCd,
            b.value('@wInCurrRate[1]', 'numeric(18,4)') AS wInCurrRate,
            b.value('@wOutCurrRate[1]', 'numeric(18,4)') AS wOutCurrRate,
            b.value('@wInAmount[1]', 'numeric(18,4)') AS wInAmount,
            b.value('@wOutAmount[1]', 'numeric(18,4)') AS wOutAmount,
            b.value('@wIsAutoAdjust[1]', 'char(1)') AS wIsAutoAdjust,
            b.value('@wTranDt[1]', 'datetime2') AS wTranDt,
            b.value('@wRollexCompNo[1]', 'int') AS wRollexCompNo,
            b.value('@wDepositor[1]', 'nvarchar(100)') AS wDepositor,
            b.value('@wRemark[1]', 'nvarchar(500)') AS wRemark,
            b.value('@wStatus[1]', 'char(1)') AS wStatus,
            b.value('@wCashTransferStatus[1]', 'varchar(5)') AS wCashTransferStatus,
            b.value('@wTransferGUID[1]', 'varchar(30)') AS wTransferGUID,
            b.value('@wRelatedBookingRefNo[1]', 'varchar(500)') AS wRelatedBookingRefNo,
            b.value('@wCrtBy[1]', 'bigint') AS wCrtBy,
            b.value('@wCrtDt[1]', 'datetime2(7)') AS wCrtDt,
            b.value('@wUpdBy[1]', 'bigint') AS wUpdBy,
            b.value('@wUpdDt[1]', 'datetime2(7)') AS wUpdDt,
            b.value('@RecordState[1]', 'varchar(1)') AS RecordState,
            b.value('@wExchangeFxRate[1]', 'numeric(12,6)') AS wExchangeFxRate
            FROM @pXML.nodes('/DataSet/Record') a(b));

        BEGIN TRY
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF EXISTS ( SELECT  1
                        FROM    @tbl
                        WHERE   RecordState = 'I' )
                BEGIN
                    
                    SET @sGuid = RollsMary.dbo.fnGetGuid(@pMainCompNo, 'CTC');

                    EXEC RollsMary.spa.SetTransferCentre @pXMLTransferCentre, @sTryRun,
                        '', 'N', @sGuid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;

                    IF @pErrCode != 0
                        BEGIN
                            RAISERROR (@pErrMsg, 16, 1);
                        END;

                    IF NOT EXISTS ( SELECT  1
                                    FROM    sys.objects
                                    WHERE   object_id = OBJECT_ID('seqeCashTransferRefNo')
                                            AND type = 'SO' )
                        BEGIN
                            CREATE SEQUENCE seqeCashTransferRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999;
                        END;

                    UPDATE  @tbl
                    SET     RowID = 0
                    WHERE   RecordState = 'I';

                    SELECT  @sRecCount = COUNT(1)
                    FROM    @tbl;

                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            IF EXISTS ( SELECT  1
                                        FROM    @tbl
                                        WHERE   RecordState = 'I'
                                                AND wRowNum = @sRuningIndex )
                                BEGIN
                                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @pCashTransferRid OUTPUT;

                                    SET @refNo = (SELECT TOP(1) wRefNo FROM @tbl WHERE wRowNum = @sRuningIndex);

                                    IF NULLIF(@refNo, '') IS NULL
                                        SET @refNo = 'TI' + FORMAT(NEXT VALUE FOR[dbo].[seqeCashTransferRefNo], '000000');
                                    
                                    IF EXISTS (SELECT 1 FROM dbo.eCashTransfer WHERE wRefNo = @refNo)
                                        THROW 50001, N'存卡轉賬單號已存在!', 1;

                                    UPDATE  @tbl
                                    SET     RowID = @pCashTransferRid ,
                                            wRefNo = @refNo,
                                            wTransferGUID = @sGuid
                                    WHERE   wRowNum = @sRuningIndex;
                                END;

                            SET @sRuningIndex = @sRuningIndex + 1;
                        END; 				   

                --wRelatedBookingRefNo will be updated in SetCashTransferDtl later
                    INSERT  INTO [dbo].[eCashTransfer]
                            ( RowID ,
                              wRefNo ,
                              wInCounterRid ,
                              wInAgentCodeIn ,
                              wOutAgentCodeIn ,
                              wIsAuthorized ,
                              wIsByPass,
                              wIsIVRProcess,
                              wInCurrCd,
                              wOutCurrCd,
                              wInCurrRate,
                              wOutCurrRate,
                              wInAmount,
                              wOutAmount,
                              wIsAutoAdjust,
                              wTranDt,
                              wRollexCompNo,
                              wDepositor,
                              wRemark ,
                              wStatus ,
                              wCashTransferStatus ,
                              wTransferGUID ,
                              wRelatedBookingRefNo ,
                              wCrtBy ,
                              wCrtDt ,
                              wUpdBy ,
                              wUpdDt ,
                              wExchangeFxRate
                            )
                            SELECT  s.RowID ,
                                    s.wRefNo ,
                                    s.wInCounterRid ,
                                    s.wInAgentCodeIn ,
                                    s.wOutAgentCodeIn ,
                                    s.wIsAuthorized ,
                                    s.wIsByPass,
                                    s.wIsIVRProcess,
                                    s.wInCurrCd,
                                    s.wOutCurrCd,
                                    s.wInCurrRate,
                                    s.wOutCurrRate,
                                    s.wInAmount,
                                    s.wOutAmount,
                                    s.wIsAutoAdjust,
                                    s.wTranDt,
                                    s.wRollexCompNo,
                                    s.wDepositor,
                                    s.wRemark ,
                                    s.wStatus ,
                                    s.wCashTransferStatus ,
                                    s.wTransferGUID ,
                                    s.wRelatedBookingRefNo ,
                                    s.wUpdBy ,
                                    @sNow ,
                                    s.wUpdBy ,
                                    @sNow ,
                                    wExchangeFxRate
                            FROM    @tbl s
                            WHERE   RecordState = 'I';
                END;
            
            IF EXISTS ( SELECT  1
                        FROM    @tbl
                        WHERE   RecordState = 'U' )
                BEGIN
                --wRelatedBookingRefNo will be updated in SetCashTransferDtl later
                    UPDATE  ect
                    SET     [wRefNo] = tmp.wRefNo ,
                            [wInCounterRid] = tmp.wInCounterRid ,
                            [wInAgentCodeIn] = tmp.wInAgentCodeIn ,
                            [wOutAgentCodeIn] = tmp.wOutAgentCodeIn ,
                            [wIsAuthorized] = tmp.wIsAuthorized ,
                            wIsByPass=tmp.wIsByPass,
                            wIsIVRProcess=tmp.wIsIVRProcess,
                            wInCurrCd = tmp.wInCurrCd,
                            wOutCurrCd = tmp.wOutCurrCd,
                            wInCurrRate = tmp.wInCurrRate,
                            wOutCurrRate = tmp.wOutCurrRate,
                            wInAmount = tmp.wInAmount,
                            wOutAmount = tmp.wOutAmount,
                            wIsAutoAdjust = tmp.wIsAutoAdjust,
                            wTranDt = tmp.wTranDt,
                            wRollexCompNo = tmp.wRollexCompNo,
                            wDepositor = tmp.wDepositor,
                            [wRemark] = tmp.wRemark ,
                            [wStatus] = tmp.wStatus ,
                            [wCashTransferStatus] = tmp.wCashTransferStatus ,
                            [wTransferGUID] = tmp.wTransferGUID ,
                            [wRelatedBookingRefNo] = tmp.wRelatedBookingRefNo ,
                            [wUpdBy] = tmp.wUpdBy ,
                            [wUpdDt] = @sNow
                    FROM    [dbo].[eCashTransfer] AS ect
                            INNER JOIN @tbl tmp ON ect.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'U';
                END;

            IF EXISTS ( SELECT  1
                        FROM    @tbl
                        WHERE   RecordState = 'D' )
                BEGIN
                    SELECT TOP 1
                            @sUpdBy = wUpdBy
                    FROM    @tbl;

                    --EXEC RollsMary.spa.SetTransferCentreRollBack @pMainCompNo,
                    --    @pMainCageCodeIn, @pMainCounter, @pType, @pRemark,
                    --    @sGuid, 'Y', 'Y', @sUpdBy, @pAuthBy, @pNonceToken, '',
                    --    @pErrCode, @pErrMsg;	
                    
                    SELECT   @sGuid = ect.wTransferGUID  
                    FROM    [dbo].[eCashTransfer] AS ect
                            INNER JOIN @tbl tmp ON ect.RowID = tmp.RowID;		   						

                    EXEC RollsMary.spa.SetTransferCentreRollBack @pMainCompNo,
                        @pMainCageCodeIn, @pMainCounter, @pType, @pRemark,
                        @sGuid, @sTryRun, 'Y', @sUpdBy, @pAuthBy, @pNonceToken, '',
                        @pErrCode, @pErrMsg;	

                    IF @pErrCode != 0
                        BEGIN
                            RAISERROR (@pErrMsg, 16, 1);
                        END;

                --wTransferRollBackGUID is obsolete, if rollbackGUID is requied, pls look for  RollsMary.dbo.eTransferCentre.wRollBackGuid
                    UPDATE  ect
                    SET     [wCashTransferStatus] = 'DL' ,
                            [wUpdDt] = @sNow ,
                            [wUpdBy] = tmp.wUpdBy
                    FROM    [dbo].[eCashTransfer] AS ect
                            INNER JOIN @tbl tmp ON ect.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'D';
                END;

            SET @pCashTransferRid = ( SELECT TOP 1
                                                [RowID]
                                      FROM      @tbl
                                    );


             --- insert cagecodein record to eCashTranferCageDtl
            SELECT TOP 1 @sIsAutoAdjust = wIsAutoAdjust FROM @tbl WHERE RecordState = 'I';
            IF @sIsAutoAdjust = 'N'
            BEGIN
                SET @sXMLStr = '';
                DECLARE @transfer TABLE(
                    wCageCodeIn         varchar(14),
                    wAmount             numeric(18,4),
                    wCurrCd             varchar(30), 
                    wCurrRate           numeric(18,4),
                    wTransferTranType   varchar(10)
                );
    
                INSERT INTO @transfer(
                    wCageCodeIn,
                    wAmount,
                    wCurrCd,
                    wCurrRate,
                    wTransferTranType 
                )
                (SELECT
                    b.value('@wCageCodeIn[1]', 'varchar(14)') AS wCageCodeIn,
                    b.value('@wAmount[1]', 'numeric(18,4)') AS wAmount,
                    b.value('@wCurrCode[1]', 'varchar(30)') AS wCurrCode,
                    b.value('@wFxRateToHKD[1]', 'numeric(18,4)') AS wFxRateToHKD,
                    b.value('@wTransferTranType[1]', 'varchar(10)') AS wTransferTranType
                    FROM @pXMLTransferCentre.nodes('/DataSet/TransferModelDtl') a(b));

                SET @sXMLStr = (
                    SELECT 0 AS RowID, @pCashTransferRid AS wCashTranID, wCageCodeIn, wAmount, wCurrCd, wCurrRate,
                        (SELECT TOP 1 wUpdBy FROM @tbl) wCrtBy,
                        (SELECT TOP 1 wUpdBy FROM @tbl) wUpdBy,
                        (SELECT TOP 1 wUpdDt FROM @tbl) wCrtDt,
                        (SELECT TOP 1 wUpdDt FROM @tbl) wUpdDt
                        FROM @transfer 
                        WHERE wTransferTranType = 'FROM'
                      FOR XML RAW('Record'),
                        ROOT('DataSet')
                    );
                                                  ;
                EXEC [spa].[SetCashTransferCageDtl] @sXMLStr , 'I', @pMainCompNo, @pErrCode OUTPUT , @pErrMsg OUTPUT;
            END

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    IF @pTestMode = 1
                        ROLLBACK;
                    ELSE
                        COMMIT;
                END;

            -- Return RowID affected
            IF @pReturnResultSet = 'Y'
                BEGIN
                    SELECT  RowID, wTransferGUID
                    FROM    @tbl;
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
                    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo,
                        @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT,
                        @sErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;
        END CATCH;		
    END;