CREATE PROCEDURE [spa].[SetShowTicketPrice] (
    @pXML XML,
    @pActionType CHAR(1), -- I/U/D        
    @pMainCompNo INT,
    @pNonceToken VARCHAR(64),
    @pReturnResultSet CHAR(1) = 'N',
    @pErrCode INT = 0 OUTPUT,
    @pErrMsg NVARCHAR(200) = '' OUTPUT)
AS
BEGIN
    SET NOCOUNT ON;

    --select * from mShowTicketPrice; 

    DECLARE @sThisTableName  VARCHAR(50) = 'mShowTicketPrice', -- For RowID         
            @sBeginTranCount INT         = 0,
            @sRecCount       INT         = 0,
            @sRuningIndex    INT         = 1,
            @sRowID          BIGINT      = 0,
            @sSeqNo          BIGINT      = 0,
            @sDocHandle      INT;

    DECLARE @sReturnRowID TABLE (RowID BIGINT);

    EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;

    --          
    SELECT wRowNum = ROW_NUMBER() OVER (ORDER BY RowID),
           *
    INTO   #sDataSet_ShowTicketPrice
      FROM
           OPENXML(@sDocHandle, 'DataSet/Record', 1)
           WITH (RowID BIGINT,
                 wShowRid BIGINT,
                 wTicketType NVARCHAR(50),
                 wAmount NUMERIC(18, 4),
                 wCost NUMERIC(18, 4),
                 wCurrency VARCHAR(6),
                 wSeqNo INT,
                 wUpdBy BIGINT,
                 wUpdDt DATETIME2(7));

    --better don't put everything within try, for example        
    --getting mSysTable value        
    --getting currency, period, mCompany ...        

    BEGIN TRY
        -- Try to make the transaction scope as small as possible to reduce locking          
        IF @sBeginTranCount = 0
        BEGIN
            BEGIN TRAN;
        END;
        IF @pActionType = 'I'
        BEGIN
            -- Set RowID by Sequence        
            UPDATE #sDataSet_ShowTicketPrice
               SET RowID = 0;
            SELECT @sRecCount = COUNT(*)
              FROM #sDataSet_ShowTicketPrice;
            WHILE @sRuningIndex <= @sRecCount
            BEGIN
                EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;

                IF @sSeqNo = 0
                BEGIN
                    SELECT 
						@sSeqNo = ISNULL(MAX(wSeqNo), 1)
					FROM 
						dbo.mShowTicketPrice 
					WHERE 
						wShowRid = (SELECT TOP 1 wShowRid FROM #sDataSet_ShowTicketPrice);
                    
					SET @sSeqNo = @sSeqNo + 1;
                END;
                ELSE
                BEGIN
                    SET @sSeqNo = @sSeqNo + 1;
                END;
                UPDATE #sDataSet_ShowTicketPrice
                   SET RowID = @sRowID,
                       wSeqNo = @sSeqNo
                 WHERE wRowNum = @sRuningIndex;
                SET @sRuningIndex = @sRuningIndex + 1;
            END;

            -- MAIN Logic here, example here is inserting dataset to eIOUPenalty        
            INSERT INTO dbo.[mShowTicketPrice] ([RowID],
                                                [wShowRid],
                                                [wTicketType],
                                                [wAmount],
                                                [wCost],
                                                [wCurrCode],
                                                [wSeqNo],
                                                [wCrtBy],
                                                [wCrtDt],
                                                [wUpdBy],
                                                [wUpdDt])
            SELECT s.RowID,
                   s.wShowRid,
                   s.wTicketType,
                   s.wAmount,
                   s.wCost,
                   s.wCurrency,
                   s.wSeqNo,
                   s.wUpdBy,
                   dbo.fnUTC8Now(),
                   s.wUpdBy,
                   dbo.fnUTC8Now()
              FROM #sDataSet_ShowTicketPrice s;

        END;
        ELSE IF @pActionType = 'U'
        BEGIN

            UPDATE met
               SET met.wShowRid = tmp.wShowRid,
                   met.wTicketType = tmp.wTicketType,
                   met.wAmount = tmp.wAmount,
                   met.wCost = tmp.wCost,
                   met.wCurrCode = tmp.wCurrency,
                   met.wSeqNo = tmp.wSeqNo,
                   met.wUpdDt = tmp.wUpdDt,
                   met.wUpdBy = tmp.wUpdBy
              FROM dbo.mShowTicketPrice AS met
             INNER JOIN #sDataSet_ShowTicketPrice tmp
                ON met.RowID = tmp.RowID
             WHERE met.RowID = tmp.RowID;
        END;

        ELSE IF @pActionType = 'D'
        BEGIN

            DELETE met
              FROM dbo.mShowTicketPrice met
             INNER JOIN #sDataSet_ShowTicketPrice tmp
                ON met.RowID = tmp.RowID
             WHERE met.RowID = tmp.RowID;
        END;

        IF @sBeginTranCount = 0
       AND @@trancount > 0
        BEGIN
            COMMIT;
        END;

        -- Return RowID affected
        IF @pReturnResultSet = 'Y'
            SELECT RowID
              FROM #sDataSet_ShowTicketPrice;


        RETURN;
    END TRY
    BEGIN CATCH
        DECLARE @sErrorNum          INT,
                @sCatchErrorMessage NVARCHAR(4000),
                @xstate             INT,
                @sProcedureName     VARCHAR(100),
                @sRtnCodeLog        INT,
                @sErrMessageLog     NVARCHAR(4000);

        SELECT @sErrorNum = ERROR_NUMBER(),
               @sCatchErrorMessage = ERROR_MESSAGE(),
               @xstate = XACT_STATE(),
               @sProcedureName = OBJECT_NAME(@@PROCID);

        IF ISNULL(@pErrCode, 0) = 0
        BEGIN
            SET @pErrCode = 999;
        END;
        SET @pErrMsg
            = CONCAT(
                  @pErrMsg,
                  CHAR(10),
                  '(',
                  @sErrorNum,
                  ') ',
                  @sCatchErrorMessage,
                  CHAR(10),
                  CHAR(13),
                  CAST(@pXML AS NVARCHAR(MAX)));

        IF @sBeginTranCount = 0
       AND ( @xstate = 1
          OR @xstate = -1)
        BEGIN
            -- transaction created within this sp
            ROLLBACK;
        END;

        -- Write Log
        EXEC spa.WriteErrorLog @pMainCompNo,
                               @pMainCompNo,
                               @sProcedureName,
                               @pErrMsg,
                               @sRtnCodeLog OUTPUT,
                               @sErrMessageLog OUTPUT;
    END CATCH;
    EXEC sp_xml_removedocument @sDocHandle;

    IF OBJECT_ID('tempdb..#sDataSet_ShowTicketPrice') IS NOT NULL
        DROP TABLE #sDataSet_ShowTicketPrice;

END;