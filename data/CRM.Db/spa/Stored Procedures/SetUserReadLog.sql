CREATE PROC [spa].[SetUserReadLog]
    @pXML       XML,
    @pErrCode   INT OUTPUT,
    @pErrMsg    NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pErrCode = 0;
        SET @pErrMsg  = '';

        DECLARE @pMainCompNo INT = 10;

        DECLARE @sThisTableName     VARCHAR(50) = 'eUserReadLog' , -- For RowID
                @sBeginTranCount    INT = 0 ,
                @sRecCount          INT = 0 ,
                @sRuningIndex       INT = 1 ,
                @sRowID             BIGINT = 0 ,
                @sNow               DATETIME2(7) = dbo.fnUTC8Now();

        DECLARE @vUserReadLog_DataSet TABLE (
            wADAccount      VARCHAR(50),
            wTable          VARCHAR(255),
            wTableRid       BIGINT,
            wLatestLogRid   BIGINT,
            wLatestDt       DATETIME2(7)
        );

        IF @pXML IS NOT NULL
        BEGIN
            INSERT INTO @vUserReadLog_DataSet (
                wADAccount,
                wTable,
                wTableRid,
                wLatestLogRid,
                wLatestDt
            )
            SELECT  tmp.wADAccount,
                    tmp.wTable,
                    tmp.wTableRid,
                    tmp.wLatestLogRid,
                    tmp.wLatestDt 
            FROM (
                SELECT RowNum = ROW_NUMBER() OVER (PARTITION BY tmp.wADAccount, tmp.wTable, tmp.wTableRid ORDER BY tmp.wLatestLogRid DESC),
                       tmp.wADAccount,
                       tmp.wTable,
                       tmp.wTableRid,
                       tmp.wLatestLogRid,
                       wLatestDt = @sNow
                FROM (  SELECT wADAccount    = T.tmp.value('@wADAccount',       'VARCHAR(50)'),
                               wTable        = T.tmp.value('@wTable',           'VARCHAR(255)'),
                               wTableRid     = T.tmp.value('@wTableRid',        'BIGINT'),
                               wLatestLogRid = T.tmp.value('@wLatestLogRid',    'BIGINT')
                        FROM @pXML.nodes('DataSet/Record') T(tmp)
                ) tmp WHERE ISNULL(tmp.wLatestLogRid, 0) > 0
            ) tmp WHERE tmp.RowNum = 1; -- 當同一條記錄，有多條閱讀記錄，只取LogRid最大的一條
        END

        SET @sBeginTranCount = @@trancount;

        BEGIN TRY
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;

            -- update latest reading time
            UPDATE r_log
            SET wLatestLogRid   = tmp.wLatestLogRid,
                wLatestDt       = tmp.wLatestDt
            FROM @vUserReadLog_DataSet tmp
            LEFT JOIN dbo.eAdviceActionLog a_log ON a_log.wAdviceRid = tmp.wTableRid AND a_log.RowID = tmp.wLatestLogRid AND tmp.wTable = 'eAdvice'
            LEFT JOIN dbo.eComplaintActionLog c_log ON c_log.wComplaintRid = tmp.wTableRid AND c_log.RowID = tmp.wLatestLogRid AND tmp.wTable = 'eComplaint'
            LEFT JOIN dbo.eUserReadLog r_log ON r_log.wADAccount = tmp.wADAccount AND r_log.wTable = tmp.wTable AND r_log.wTableRid = tmp.wTableRid
            WHERE r_log.wADAccount IS NOT NULL -- 曾經讀過相關訊息，更新閱讀位置
                AND tmp.wLatestLogRid > r_log.wLatestLogRid -- 只能往前讀，不能Set已讀過的值
                AND (a_log.RowID IS NOT NULL OR c_log.RowID IS NOT NULL); -- 必須要在Log table中揾到相關的record，不能隨便set data

            -- insert new reading log
            INSERT INTO dbo.eUserReadLog (
                wADAccount,
                wTable,
                wTableRid,
                wLatestLogRid,
                wLatestDt
            )
            SELECT tmp.wADAccount,
                   tmp.wTable,
                   tmp.wTableRid,
                   tmp.wLatestLogRid,
                   tmp.wLatestDt
            FROM @vUserReadLog_DataSet tmp
            LEFT JOIN dbo.eAdviceActionLog a_log ON a_log.wAdviceRid = tmp.wTableRid AND a_log.RowID = tmp.wLatestLogRid AND tmp.wTable = 'eAdvice'
            LEFT JOIN dbo.eComplaintActionLog c_log ON c_log.wComplaintRid = tmp.wTableRid AND c_log.RowID = tmp.wLatestLogRid AND tmp.wTable = 'eComplaint'
            LEFT JOIN dbo.eUserReadLog r_log ON r_log.wADAccount = tmp.wADAccount AND r_log.wTable = tmp.wTable AND r_log.wTableRid = tmp.wTableRid
            WHERE r_log.wADAccount IS NULL -- 從來未讀過相關訊息，新增閱讀位置
                AND (a_log.RowID IS NOT NULL OR c_log.RowID IS NOT NULL); -- 必須要在Log table中揾到相關的record，不能隨便set data

            IF @sBeginTranCount = 0 AND @@trancount > 0
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