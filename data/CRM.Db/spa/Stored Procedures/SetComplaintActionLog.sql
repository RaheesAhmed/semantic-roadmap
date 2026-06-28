CREATE PROC [spa].[SetComplaintActionLog]
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

        DECLARE @sThisTableName     VARCHAR(50) = 'eComplaintActionLog' , -- For RowID
                @sBeginTranCount    INT = 0 ,
                @sRecCount          INT = 0 ,
                @sRuningIndex       INT = 1 ,
                @sRowID             BIGINT = 0 ,
                @sNow               DATETIME2(7) = dbo.fnUTC8Now();

        DECLARE @vComplaintActionLog_DataSet TABLE (
            RowNum                  INT,
            RowID                   BIGINT,
            wComplaintRid           BIGINT,
            wTranDt                 DATETIME2(7),
            wRefNo                  VARCHAR(30),
            wAgentCodeIn            VARCHAR(14),
            wComplainantName        NVARCHAR(50),
            wPersonRid              BIGINT,
            wComplainantNickname    NVARCHAR(50),
            wComplainantTitle       NVARCHAR(30),
            wComplainantTel         VARCHAR(100),
            wType                   VARCHAR(30),
            wChannel                VARCHAR(30),
            wReceivedBy             BIGINT,
            wReceivedDeptCd         VARCHAR(30),
            wReceivedLocation       NVARCHAR(30),
            wComplainBy             BIGINT,
            wComplainDeptCd         VARCHAR(30),
            wComplainLocation       NVARCHAR(30),
            wComplainCompNo         INT,
            wContent                NVARCHAR(2000),
            wCancelRemark           NVARCHAR(500),
            wIntroduction           NVARCHAR(2000),
            wDealDt                 DATETIME2(7),
            wComplaintStatus        VARCHAR(30),
            wStatus                 CHAR(1),
            wCrtDt                  DATETIME2(7),
            wCrtBy                  BIGINT,
            wUpdDt                  DATETIME2(7),
            wUpdBy                  BIGINT,
            RecordState             CHAR(1) -- I/U/D
        );

        IF @pXML IS NOT NULL
        BEGIN
            INSERT INTO @vComplaintActionLog_DataSet (
                RowNum,
                RowID,
                wComplaintRid,
                wTranDt,
                wRefNo,
                wAgentCodeIn,
                wComplainantName,
                wPersonRid,
                wComplainantNickname,
                wComplainantTitle,
                wComplainantTel,
                wType,
                wChannel,
                wReceivedBy,
                wReceivedDeptCd,
                wReceivedLocation,
                wComplainBy,
                wComplainDeptCd,
                wComplainLocation,
                wComplainCompNo,
                wContent,
                wCancelRemark,
                wIntroduction,
                wDealDt,
                wComplaintStatus,
                wStatus,
                wCrtDt,
                wCrtBy,
                wUpdDt,
                wUpdBy,
                RecordState
            )
            SELECT RowNum = ROW_NUMBER() OVER (ORDER BY tmp.RowID),
                   tmp.*
            FROM ( SELECT   RowID                   = T.tmp.value('@RowID',                 'BIGINT'),
                            wComplaintRid           = T.tmp.value('@wComplaintRid',         'BIGINT'),
                            wTranDt                 = T.tmp.value('@wTranDt',               'DATETIME2(7)'),
                            wRefNo                  = T.tmp.value('@wRefNo',                'VARCHAR(30)'),
                            wAgentCodeIn            = T.tmp.value('@wAgentCodeIn',          'VARCHAR(14)'),
                            wComplainantName        = T.tmp.value('@wComplainantName',      'NVARCHAR(50)'),
                            wPersonRid              = T.tmp.value('@wPersonRid',            'BIGINT'),
                            wComplainantNickname    = T.tmp.value('@wComplainantNickname',  'NVARCHAR(50)'),
                            wComplainantTitle       = T.tmp.value('@wComplainantTitle',     'NVARCHAR(30)'),
                            wComplainantTel         = T.tmp.value('@wComplainantTel',       'VARCHAR(100)'),
                            wType                   = T.tmp.value('@wType',                 'VARCHAR(30)'),
                            wChannel                = T.tmp.value('@wChannel',              'VARCHAR(30)'),
                            wReceivedBy             = T.tmp.value('@wReceivedBy',           'BIGINT'),
                            wReceivedDeptCd         = T.tmp.value('@wReceivedDeptCd',       'VARCHAR(30)'),
                            wReceivedLocation       = T.tmp.value('@wReceivedLocation',     'NVARCHAR(30)'),
                            wComplainBy             = T.tmp.value('@wComplainBy',           'BIGINT'),
                            wComplainDeptCd         = T.tmp.value('@wComplainDeptCd',       'VARCHAR(30)'),
                            wComplainLocation       = T.tmp.value('@wComplainLocation',     'NVARCHAR(30)'),
                            wComplainCompNo         = T.tmp.value('@wComplainCompNo',       'INT'),
                            wContent                = T.tmp.value('@wContent',              'NVARCHAR(2000)'),
                            wCancelRemark           = T.tmp.value('@wCancelRemark',         'NVARCHAR(500)'),
                            wIntroduction           = T.tmp.value('@wIntroduction',         'NVARCHAR(2000)'),
                            wDealDt                 = T.tmp.value('@wDealDt',               'DATETIME2(7)'),
                            wComplaintStatus        = T.tmp.value('@wComplaintStatus',      'VARCHAR(30)'),
                            wStatus                 = T.tmp.value('@wStatus',               'CHAR(1)'),
                            wCrtDt                  = T.tmp.value('@wCrtDt',                'DATETIME2(7)'),
                            wCrtBy                  = T.tmp.value('@wCrtBy',                'BIGINT'),
                            wUpdDt                  = T.tmp.value('@wUpdDt',                'DATETIME2(7)'),
                            wUpdBy                  = T.tmp.value('@wUpdBy',                'BIGINT'),
                            RecordState             = T.tmp.value('@RecordState',           'CHAR(1)')
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
            IF EXISTS (SELECT 1 FROM @vComplaintActionLog_DataSet WHERE RecordState = 'I')
            BEGIN
                SET @sRuningIndex = 1;
                SET @sRecCount = (SELECT COUNT(1) FROM @vComplaintActionLog_DataSet);
                
                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    IF EXISTS (SELECT 1 FROM @vComplaintActionLog_DataSet WHERE RowNum = @sRuningIndex AND RecordState = 'I')
                    BEGIN
                        EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;

                        UPDATE @vComplaintActionLog_DataSet
                        SET RowID = @sRowID
                        WHERE RowNum = @sRuningIndex;
                    END

                    SET @sRuningIndex = @sRuningIndex + 1;
                END

                INSERT INTO dbo.eComplaintActionLog (
                    RowID,
                    wComplaintRid,
                    wTranDt,
                    wRefNo,
                    wAgentCodeIn,
                    wComplainantName,
                    wPersonRid,
                    wComplainantNickname,
                    wComplainantTitle,
                    wComplainantTel,
                    wType,
                    wChannel,
                    wReceivedBy,
                    wReceivedDeptCd,
                    wReceivedLocation,
                    wComplainBy,
                    wComplainDeptCd,
                    wComplainLocation,
                    wComplainCompNo,
                    wContent,
                    wCancelRemark,
                    wIntroduction,
                    wDealDt,
                    wComplaintStatus,
                    wStatus,
                    wCrtDt,
                    wCrtBy,
                    wUpdDt,
                    wUpdBy,
                    wRecStatus
                )
                SELECT  RowID,
                        wComplaintRid,
                        wTranDt,
                        wRefNo,
                        wAgentCodeIn,
                        wComplainantName,
                        wPersonRid,
                        wComplainantNickname,
                        wComplainantTitle,
                        wComplainantTel,
                        wType,
                        wChannel,
                        wReceivedBy,
                        wReceivedDeptCd,
                        wReceivedLocation,
                        wComplainBy,
                        wComplainDeptCd,
                        wComplainLocation,
                        wComplainCompNo,
                        wContent,
                        wCancelRemark,
                        wIntroduction,
                        wDealDt,
                        wComplaintStatus,
                        wStatus,
                        wCrtDt,
                        wCrtBy,
                        wUpdDt,
                        wUpdBy,
                        wRecStatus = 'A'
                FROM @vComplaintActionLog_DataSet
                WHERE RecordState = 'I';
            END

            -- update
            IF EXISTS (SELECT 1 FROM @vComplaintActionLog_DataSet WHERE RecordState = 'U')
            BEGIN
                UPDATE c_log
                SET -- RowID                   = tmp.RowID,
                    wComplaintRid           = tmp.wComplaintRid,
                    wTranDt                 = tmp.wTranDt,
                    wRefNo                  = tmp.wRefNo,
                    wAgentCodeIn            = tmp.wAgentCodeIn,
                    wComplainantName        = tmp.wComplainantName,
                    wPersonRid              = tmp.wPersonRid,
                    wComplainantNickname    = tmp.wComplainantNickname,
                    wComplainantTitle       = tmp.wComplainantTitle,
                    wComplainantTel         = tmp.wComplainantTel,
                    wType                   = tmp.wType,
                    wChannel                = tmp.wChannel,
                    wReceivedBy             = tmp.wReceivedBy,
                    wReceivedDeptCd         = tmp.wReceivedDeptCd,
                    wReceivedLocation       = tmp.wReceivedLocation,
                    wComplainBy             = tmp.wComplainBy,
                    wComplainDeptCd         = tmp.wComplainDeptCd,
                    wComplainLocation       = tmp.wComplainLocation,
                    wComplainCompNo         = tmp.wComplainCompNo,
                    wContent                = tmp.wContent,
                    wCancelRemark           = tmp.wCancelRemark,
                    wIntroduction           = tmp.wIntroduction,
                    wDealDt                 = tmp.wDealDt,
                    wComplaintStatus        = tmp.wComplaintStatus,
                    wStatus                 = tmp.wStatus,
                    wCrtDt                  = tmp.wCrtDt,
                    wCrtBy                  = tmp.wCrtBy,
                    wUpdDt                  = tmp.wUpdDt,
                    wUpdBy                  = tmp.wUpdBy
                    -- wRecStatus              = 'A'
                FROM dbo.eComplaintActionLog c_log
                INNER JOIN @vComplaintActionLog_DataSet tmp ON tmp.RowID = c_log.RowID
                WHERE tmp.RecordState = 'U';
            END

            -- delete
            IF EXISTS (SELECT 1 FROM @vComplaintActionLog_DataSet WHERE RecordState = 'D')
            BEGIN
                UPDATE c_log
                SET -- RowID                   = tmp.RowID,
                    wComplaintRid           = tmp.wComplaintRid,
                    wTranDt                 = tmp.wTranDt,
                    wRefNo                  = tmp.wRefNo,
                    wAgentCodeIn            = tmp.wAgentCodeIn,
                    wComplainantName        = tmp.wComplainantName,
                    wPersonRid              = tmp.wPersonRid,
                    wComplainantNickname    = tmp.wComplainantNickname,
                    wComplainantTitle       = tmp.wComplainantTitle,
                    wComplainantTel         = tmp.wComplainantTel,
                    wType                   = tmp.wType,
                    wChannel                = tmp.wChannel,
                    wReceivedBy             = tmp.wReceivedBy,
                    wReceivedDeptCd         = tmp.wReceivedDeptCd,
                    wReceivedLocation       = tmp.wReceivedLocation,
                    wComplainBy             = tmp.wComplainBy,
                    wComplainDeptCd         = tmp.wComplainDeptCd,
                    wComplainLocation       = tmp.wComplainLocation,
                    wComplainCompNo         = tmp.wComplainCompNo,
                    wContent                = tmp.wContent,
                    wCancelRemark           = tmp.wCancelRemark,
                    wIntroduction           = tmp.wIntroduction,
                    wDealDt                 = tmp.wDealDt,
                    wComplaintStatus        = tmp.wComplaintStatus,
                    wStatus                 = tmp.wStatus,
                    wCrtDt                  = tmp.wCrtDt,
                    wCrtBy                  = tmp.wCrtBy,
                    wUpdDt                  = tmp.wUpdDt,
                    wUpdBy                  = tmp.wUpdBy,
                    wRecStatus              = 'T'
                FROM dbo.eComplaintActionLog c_log
                INNER JOIN @vComplaintActionLog_DataSet tmp ON tmp.RowID = c_log.RowID
                WHERE tmp.RecordState = 'D';
            END
            
            IF @sBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                COMMIT;
            END;

            IF @pReturnResult = 'Y'
                SELECT RowID FROM @vComplaintActionLog_DataSet;
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