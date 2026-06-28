CREATE PROC [spa].[SetReqBookingFilterLog]
    @pXML           XML,
    @pSetQty        CHAR(1) = 'N',
    @pReturnResult  CHAR(1) = 'N',
    @pTestMode      INT,
    @pErrCode       INT OUTPUT,
    @pErrMsg        NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        -- dbml
        ----------------------------------------------------------
        --DECLARE @vResult TABLE (wUserRid BIGINT, wShouldUpdate CHAR(1));

        --SELECT * FROM @vResult;
        ----------------------------------------------------------

        DECLARE @pMainCompNo INT = 10;

        DECLARE @sBeginTranCount    INT = 0 ,
                @sNow               DATETIME2(7) = dbo.fnUTC8Now(),
                @sExpirationDate    DATE = DATEADD(DAY, 30, dbo.fnUTC8Now()); -- 30天到期（連續30天沒有使用訂務需求，推送計算自動失效）

        CREATE TABLE #vReqBookingFilterLog_DataSet (
            wUserRid        BIGINT,
            wProgressQty    INT,
            wUpdDt          DATETIME2(7),
            wAgentCodeIn    NVARCHAR(100),
            wBookingType    VARCHAR(30),
            wReqUser        BIGINT,
            wReqDeptCd      VARCHAR(30),
            wReqStatus      VARCHAR(10),
            wStartDate      VARCHAR(20),
            wEndDate        VARCHAR(20),
            wHotelRid       BIGINT,
            wShouldUpdate   CHAR(1) DEFAULT('N')
        );

        INSERT INTO #vReqBookingFilterLog_DataSet(
            wUserRid,
            wProgressQty,
            wUpdDt,
            wAgentCodeIn,
            wBookingType,
            wReqUser,
            wReqDeptCd,
            wReqStatus,
            wStartDate,
            wEndDate,
            wHotelRid
        )
        SELECT  wUserRid        = T.tmp.value('@wUserRid',      'BIGINT'),
                wProgressQty    = T.tmp.value('@wProgressQty',  'INT'),
                wUpdDt          = T.tmp.value('@wUpdDt',        'DATETIME2(7)'),
                wAgentCodeIn    = T.tmp.value('@wAgentCodeIn',  'NVARCHAR(100)'),
                wBookingType    = T.tmp.value('@wBookingType',  'VARCHAR(30)'),
                wReqUser        = T.tmp.value('@wReqUser',      'BIGINT'),
                wReqDeptCd      = T.tmp.value('@wReqDeptCd',    'VARCHAR(30)'),
                wReqStatus      = T.tmp.value('@wReqStatus',    'VARCHAR(10)'),
                wStartDate      = T.tmp.value('@wStartDate',    'VARCHAR(20)'),
                wEndDate        = T.tmp.value('@wEndDate',      'VARCHAR(20)'),
                wHotelRid       = T.tmp.value('@wHotelRid',     'BIGINT')
        FROM @pXML.nodes('DataSet/Record') T(tmp);
        
        UPDATE tmp
        SET wShouldUpdate = 'Y'
        FROM #vReqBookingFilterLog_DataSet tmp
        LEFT JOIN dbo.eReqBookingFilterLog rbfl WITH(NOLOCK) ON rbfl.wUserRid = tmp.wUserRid
        WHERE rbfl.wUserRid IS NULL
            OR rbfl.wAgentCodeIn <> tmp.wAgentCodeIn
            OR rbfl.wBookingType <> tmp.wBookingType
            OR rbfl.wReqUser <> tmp.wReqUser
            OR rbfl.wReqDeptCd <> tmp.wReqDeptCd
            OR rbfl.wReqStatus <> tmp.wReqStatus
            OR rbfl.wStartDate <> tmp.wStartDate
            OR rbfl.wEndDate <> tmp.wEndDate
            OR rbfl.wHotelRid <> tmp.wHotelRid;

        SET @pErrCode = 0;
        SET @pErrMsg  = '';
        SET @sBeginTranCount = @@TRANCOUNT;
        
        BEGIN TRY
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END
            
            -- update old record if UserRid exists
            ----------------------------------------------------------------------------------
            UPDATE rbfl
            SET wUserRid        = tmp.wUserRid,
                wProgressQty    = ISNULL(tmp.wProgressQty, 0),
                wExpirationDate = @sExpirationDate,
                wUpdDt          = IIF(@pSetQty <> 'Y' OR tmp.wProgressQty = rbfl.wProgressQty, rbfl.wUpdDt, @sNow), -- 如果數字為空或不改變，不設當前時間，不執行推送
                wAgentCodeIn    = ISNULL(tmp.wAgentCodeIn, ''),
                wBookingType    = ISNULL(tmp.wBookingType, ''),
                wReqUser        = ISNULL(tmp.wReqUser, ''),
                wReqDeptCd      = ISNULL(tmp.wReqDeptCd, ''),
                wReqStatus      = ISNULL(tmp.wReqStatus, ''),
                wStartDate      = ISNULL(tmp.wStartDate, ''),
                wEndDate        = ISNULL(tmp.wEndDate, ''),
                wHotelRid       = ISNULL(tmp.wHotelRid, 0)
            FROM dbo.eReqBookingFilterLog rbfl
            INNER JOIN #vReqBookingFilterLog_DataSet tmp ON tmp.wUserRid = rbfl.wUserRid;

            -- insert new record if UserRid doesn't exist
            ----------------------------------------------------------------------------------
            INSERT INTO dbo.eReqBookingFilterLog (
                wUserRid,
                wProgressQty,
                wExpirationDate,
                wUpdDt,
                wAgentCodeIn,
                wBookingType,
                wReqUser,
                wReqDeptCd,
                wReqStatus,
                wStartDate,
                wEndDate,
                wHotelRid
            )
            SELECT  wUserRid        = tmp.wUserRid,
                    wProgressQty    = ISNULL(tmp.wProgressQty, 0),
                    wExpirationDate = @sExpirationDate,
                    wUpdDt          = @sNow,
                    wAgentCodeIn    = ISNULL(tmp.wAgentCodeIn, ''),
                    wBookingType    = ISNULL(tmp.wBookingType, ''),
                    wReqUser        = ISNULL(tmp.wReqUser, ''),
                    wReqDeptCd      = ISNULL(tmp.wReqDeptCd, ''),
                    wReqStatus      = ISNULL(tmp.wReqStatus, ''),
                    wStartDate      = ISNULL(tmp.wStartDate, ''),
                    wEndDate        = ISNULL(tmp.wEndDate, ''),
                    wHotelRid       = ISNULL(tmp.wHotelRid, 0)
            FROM #vReqBookingFilterLog_DataSet tmp
            LEFT JOIN dbo.eReqBookingFilterLog rbfl ON rbfl.wUserRid = tmp.wUserRid
            WHERE rbfl.wUserRid IS NULL
                AND ISNULL(tmp.wUserRid, 0) > 0;

            ----------------------------------------------------------------------------------
            IF @sBeginTranCount = 0 AND @@TRANCOUNT > 0
            BEGIN
                IF @pTestMode = 1
                    ROLLBACK TRAN
                ELSE
                    COMMIT TRAN;
            END

            -- return result
            ----------------------------------------------------------------------------------
            IF @pReturnResult = 'Y'
                SELECT wUserRid, wShouldUpdate FROM #vReqBookingFilterLog_DataSet;
            ----------------------------------------------------------------------------------
        END TRY
        BEGIN CATCH
            DECLARE @xstate INT ,
                    @sProcedureName VARCHAR(100) ,
                    @sCatchErrorCode INT ,
                    @sCatchErrorMessage NVARCHAR(4000) ,
                    @sRtnCodeLog INT ,
                    @sErrMessageLog NVARCHAR(4000);
	        
            SET @xstate             = XACT_STATE();
            SET @sProcedureName     = OBJECT_NAME(@@PROCID);
            SET @sCatchErrorCode    = ERROR_NUMBER();
            SET @sCatchErrorMessage = ERROR_MESSAGE();
            
            SET @pErrCode = IIF(ISNULL(@pErrCode, 0) = 0, @sCatchErrorCode, @pErrCode);
            SET @pErrMsg = CONCAT(IIF(ISNULL(@pErrMsg, '') = '', '', @pErrMsg + CHAR(10)), '(', @sCatchErrorCode, ') ', @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0 AND ( @xstate = 1 OR @xstate = -1 )
            BEGIN
                ROLLBACK TRAN;
            END
            ELSE
                THROW;
	        
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH

        IF OBJECT_ID('tempdb..#vReqBookingFilterLog_DataSet') IS NOT NULL
            DROP TABLE #vReqBookingFilterLog_DataSet;
    END