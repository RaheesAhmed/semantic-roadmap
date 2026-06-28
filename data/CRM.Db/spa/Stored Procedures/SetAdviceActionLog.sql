CREATE PROC [spa].[SetAdviceActionLog]
    @pXML           XML,
    @pReturnResult  CHAR(1) = 'N',
    @pErrCode       INT OUTPUT,
    @pErrMsg        NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pErrCode = 0;
        SET @pErrMsg  = '';

        DECLARE @pMainCompNo INT = 10;

        DECLARE @sThisTableName     VARCHAR(50) = 'eAdviceActionLog' , -- For RowID
                @sBeginTranCount    INT = 0 ,
                @sRecCount          INT = 0 ,
                @sRuningIndex       INT = 1 ,
                @sRowID             BIGINT = 0 ,
                @sNow               DATETIME2(7) = dbo.fnUTC8Now();

        DECLARE @vAdviceActionLog_DataSet TABLE (
            RowNum              INT,
            RowID               BIGINT,
            wAdviceRid          BIGINT,
            wAim                NVARCHAR(200),
            wDate               DATE,
            wAgentCodeIn        VARCHAR(14),
            wReceivedBy         BIGINT,
            wReceivedDeptCd     VARCHAR(30),
            wType               VARCHAR(30),
            wSubType            VARCHAR(30),
            wContent            NVARCHAR(2000),
            wIsHighPriority     CHAR(1),
            wRefNo              VARCHAR(30),
            wDealDt             DATETIME2(7),
            wAdviceStatus       VARCHAR(20),
            wStatus             CHAR(1),
            wCrtDt              DATETIME2(7),
            wCrtBy              BIGINT,
            wUpdDt              DATETIME2(7),
            wUpdBy              BIGINT,
            RecordState         CHAR(1) -- I/U/D
        );

        IF @pXML IS NOT NULL
        BEGIN
            INSERT INTO @vAdviceActionLog_DataSet (
                RowNum,
                RowID,
                wAdviceRid,
                wAim,
                wDate,
                wAgentCodeIn,
                wReceivedBy,
                wReceivedDeptCd,
                wType,
                wSubType,
                wContent,
                wIsHighPriority,
                wRefNo,
                wDealDt,
                wAdviceStatus,
                wStatus,
                wCrtDt,
                wCrtBy,
                wUpdDt,
                wUpdBy,
                RecordState
            )
            SELECT RowNum = ROW_NUMBER() OVER (ORDER BY tmp.RowID),
                   tmp.*
            FROM ( SELECT   RowID            = T.tmp.value('@RowID',            'BIGINT'),
                            wAdviceRid       = T.tmp.value('@wAdviceRid',       'BIGINT'),
                            wAim             = T.tmp.value('@wAim',             'NVARCHAR(200)'),
                            wDate            = T.tmp.value('@wDate',            'DATE'),
                            wAgentCodeIn     = T.tmp.value('@wAgentCodeIn',     'VARCHAR(14)'),
                            wReceivedBy      = T.tmp.value('@wReceivedBy',      'BIGINT'),
                            wReceivedDeptCd  = T.tmp.value('@wReceivedDeptCd',  'VARCHAR(30)'),
                            wType            = T.tmp.value('@wType',            'VARCHAR(30)'),
                            wSubType         = T.tmp.value('@wSubType',         'VARCHAR(30)'),
                            wContent         = T.tmp.value('@wContent',         'NVARCHAR(2000)'),
                            wIsHighPriority  = T.tmp.value('@wIsHighPriority',  'CHAR(1)'),
                            wRefNo           = T.tmp.value('@wRefNo',           'VARCHAR(30)'),
                            wDealDt          = T.tmp.value('@wDealDt',          'DATETIME2(7)'),
                            wAdviceStatus    = T.tmp.value('@wAdviceStatus',    'VARCHAR(20)'),
                            wStatus          = T.tmp.value('@wStatus',          'CHAR(1)'),
                            wCrtDt           = T.tmp.value('@wCrtDt',           'DATETIME2(7)'),
                            wCrtBy           = T.tmp.value('@wCrtBy',           'BIGINT'),
                            wUpdDt           = T.tmp.value('@wUpdDt',           'DATETIME2(7)'),
                            wUpdBy           = T.tmp.value('@wUpdBy',           'BIGINT'),
                            RecordState      = T.tmp.value('@RecordState',      'CHAR(1)')
                    FROM @pXML.nodes('/DataSet/Record') T(tmp)
            ) tmp;
        END

        SET @sBeginTranCount = @@trancount;

        BEGIN TRY
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;

            -- insert
            IF EXISTS (SELECT 1 FROM @vAdviceActionLog_DataSet WHERE RecordState = 'I')
            BEGIN
                SET @sRuningIndex = 1;
                SET @sRecCount = (SELECT COUNT(1) FROM @vAdviceActionLog_DataSet);
                
                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    IF EXISTS (SELECT 1 FROM @vAdviceActionLog_DataSet WHERE RowNum = @sRuningIndex AND RecordState = 'I')
                    BEGIN
                        EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;

                        UPDATE @vAdviceActionLog_DataSet
                        SET RowID = @sRowID
                        WHERE RowNum = @sRuningIndex;
                    END

                    SET @sRuningIndex = @sRuningIndex + 1;
                END

                INSERT INTO dbo.eAdviceActionLog (
                    RowID,
                    wAdviceRid,
                    wAim,
                    wDate,
                    wAgentCodeIn,
                    wReceivedBy,
                    wReceivedDeptCd,
                    wType,
                    wSubType,
                    wContent,
                    wIsHighPriority,
                    wRefNo,
                    wDealDt,
                    wAdviceStatus,
                    wStatus,
                    wCrtDt,
                    wCrtBy,
                    wUpdDt,
                    wUpdBy,
                    wRecStatus
                )
                SELECT  RowID,
                        wAdviceRid,
                        wAim,
                        wDate,
                        wAgentCodeIn,
                        wReceivedBy,
                        wReceivedDeptCd,
                        wType,
                        wSubType,
                        wContent,
                        wIsHighPriority,
                        wRefNo,
                        wDealDt,
                        wAdviceStatus,
                        wStatus,
                        wCrtDt,
                        wCrtBy,
                        wUpdDt,
                        wUpdBy,
                        wRecStatus = 'A'
                FROM @vAdviceActionLog_DataSet
                WHERE RecordState = 'I';
            END

            -- update
            IF EXISTS (SELECT 1 FROM @vAdviceActionLog_DataSet WHERE RecordState = 'U')
            BEGIN
                UPDATE a_log
                SET -- RowID           = tmp.RowID,
                    wAdviceRid      = tmp.wAdviceRid,
                    wAim            = tmp.wAim,
                    wDate           = tmp.wDate,
                    wAgentCodeIn    = tmp.wAgentCodeIn,
                    wReceivedBy     = tmp.wReceivedBy,
                    wReceivedDeptCd = tmp.wReceivedDeptCd,
                    wType           = tmp.wType,
                    wSubType        = tmp.wSubType,
                    wContent        = tmp.wContent,
                    wIsHighPriority = tmp.wIsHighPriority,
                    wRefNo          = tmp.wRefNo,
                    wDealDt         = tmp.wDealDt,
                    wAdviceStatus   = tmp.wAdviceStatus,
                    wStatus         = tmp.wStatus,
                    wCrtDt          = tmp.wCrtDt,
                    wCrtBy          = tmp.wCrtBy,
                    wUpdDt          = tmp.wUpdDt,
                    wUpdBy          = tmp.wUpdBy
                    -- wRecStatus      = 'A'
                FROM dbo.eAdviceActionLog a_log
                INNER JOIN @vAdviceActionLog_DataSet tmp ON tmp.RowID = a_log.RowID
                WHERE tmp.RecordState = 'U';
            END

            -- delete
            IF EXISTS (SELECT 1 FROM @vAdviceActionLog_DataSet WHERE RecordState = 'D')
            BEGIN
                UPDATE a_log
                SET -- RowID           = tmp.RowID,
                    wAdviceRid      = tmp.wAdviceRid,
                    wAim            = tmp.wAim,
                    wDate           = tmp.wDate,
                    wAgentCodeIn    = tmp.wAgentCodeIn,
                    wReceivedBy     = tmp.wReceivedBy,
                    wReceivedDeptCd = tmp.wReceivedDeptCd,
                    wType           = tmp.wType,
                    wSubType        = tmp.wSubType,
                    wContent        = tmp.wContent,
                    wIsHighPriority = tmp.wIsHighPriority,
                    wRefNo          = tmp.wRefNo,
                    wDealDt         = tmp.wDealDt,
                    wAdviceStatus   = tmp.wAdviceStatus,
                    wStatus         = tmp.wStatus,
                    wCrtDt          = tmp.wCrtDt,
                    wCrtBy          = tmp.wCrtBy,
                    wUpdDt          = tmp.wUpdDt,
                    wUpdBy          = tmp.wUpdBy,
                    wRecStatus      = 'T'
                FROM dbo.eAdviceActionLog a_log
                INNER JOIN @vAdviceActionLog_DataSet tmp ON tmp.RowID = a_log.RowID
                WHERE tmp.RecordState = 'D';
            END
            
            IF @sBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                COMMIT;
            END;

            IF @pReturnResult = 'Y'
                SELECT RowID FROM @vAdviceActionLog_DataSet;
        END TRY
        BEGIN CATCH
            DECLARE @sErrorNum INT ,
                    @sCatchErrorMessage NVARCHAR(4000) ,
                    @xstate INT ,
                    @sProcedureName VARCHAR(100) ,
                    @sRtnCodeLog INT ,
                    @sErrMessageLog NVARCHAR(4000);
	        
            SELECT  @sErrorNum = ERROR_NUMBER() ,
                    @sCatchErrorMessage = ERROR_MESSAGE() ,
                    @xstate = XACT_STATE() ,
                    @sProcedureName = OBJECT_NAME(@@PROCID);
			
            IF ISNULL(@pErrCode, 0) = 0
            BEGIN
                SET @pErrCode = 999;
            END;
            
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ', @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0 AND ( @xstate = 1 OR @xstate = -1 )
                ROLLBACK;
            ELSE
                THROW;
	        
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH
    END