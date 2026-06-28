CREATE PROC [spa].[SetReqBooking]
    @pXML           XML,
    @pMainCompNo    INT,
    @pReturnResult  CHAR(1) = 'N',
    @pTestMode      INT,
    @pErrCode       INT OUTPUT,
    @pErrMsg        NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        -- dbml
        -------------------------------------------------
        -- DECLARE @vResult TABLE (RowID BIGINT PRIMARY KEY);
        -- SELECT * FROM @vResult;
        -------------------------------------------------

        DECLARE @sThisTable         VARCHAR(50) = 'eReqBooking',
                @sBeginTranCount    INT = 0 ,
                @sRecCount          INT = 0 ,
                @sRuningIndex       INT = 1 ,
                @sRowID             BIGINT = 0 ,
                @sNow               DATETIME2(7) = dbo.fnUTC8Now(),
                @sErrMsg            NVARCHAR(200);
        
        DECLARE @vReqBooking_DataSet TABLE (
            RowNum          INT IDENTITY(1, 1),
            RowID           BIGINT,
	        wGUID           VARCHAR(36),
	        wBookingType    VARCHAR(30),
	        wRefTable       VARCHAR(50),
	        wRefRid         BIGINT,
            wRefNo			VARCHAR(50),
	        wAgentCodeIn    VARCHAR(14),
	        wReqDeptCd      VARCHAR(30),
	        wReqUserRid     BIGINT,
	        wFollowDeptCd   VARCHAR(30),
	        wFollowUserRid  BIGINT,
	        wReqStatus      VARCHAR(10),
            wOldRowID       BIGINT,      -- DB保存的RowID，RecordState = U/D時，Get到的值不能為空
            wOldGUID        VARCHAR(36),
            wOldRefRid      BIGINT,
            wOldReqStatus   VARCHAR(10), -- 上一次保存的需求狀態
	        -- wStatus         CHAR(1),
	        -- wCrtBy          BIGINT,
	        -- wCrtDt          DATETIME2(7), -- 默認取系統時間
	        wUpdBy          BIGINT,
	        -- wUpdDt          DATETIME2(7), -- 默認取系統時間
            RecordState    CHAR(1) -- I/U/D
        );

        INSERT INTO @vReqBooking_DataSet (
            RowID,
            wGUID,
            wBookingType,
            wRefTable,
            wRefRid,
            wRefNo,
            wAgentCodeIn,
            wReqDeptCd,
            wReqUserRid,
            wFollowDeptCd,
            wFollowUserRid,
            wReqStatus,
            -- wStatus,
            -- wCrtBy,
            -- wCrtDt,
            wUpdBy,
            -- wUpdDt,
            RecordState
        )
        SELECT  RowID           = T.tmp.value('@RowID',             'BIGINT'),
	            wGUID           = T.tmp.value('@wGUID',             'VARCHAR(36)'),
	            wBookingType    = T.tmp.value('@wBookingType',      'VARCHAR(30)'),
	            wRefTable       = T.tmp.value('@wRefTable',         'VARCHAR(50)'),
	            wRefRid         = T.tmp.value('@wRefRid',           'BIGINT'),
                wRefNo          = T.tmp.value('@wRefNo',            'VARCHAR(50)'),
	            wAgentCodeIn    = T.tmp.value('@wAgentCodeIn',      'VARCHAR(14)'),
	            wReqDeptCd      = T.tmp.value('@wReqDeptCd',        'VARCHAR(30)'),
	            wReqUserRid     = T.tmp.value('@wReqUserRid',       'BIGINT'),
	            wFollowDeptCd   = T.tmp.value('@wFollowDeptCd',     'VARCHAR(30)'),
	            wFollowUserRid  = T.tmp.value('@wFollowUserRid',    'BIGINT'),
	            wReqStatus      = T.tmp.value('@wReqStatus',        'VARCHAR(10)'),
	            -- wStatus         = T.tmp.value('@wStatus',           'CHAR(1)'),
	            -- wCrtBy          = T.tmp.value('@wUpdBy',            'BIGINT'),
	            -- wCrtDt          = T.tmp.value('@wUpdDt',            'DATETIME2(7)'),
	            wUpdBy          = T.tmp.value('@wUpdBy',            'BIGINT'),
	            -- wUpdDt          = T.tmp.value('@wUpdDt',            'DATETIME2(7)'),
                RecordState     = T.tmp.value('@RecordState',       'CHAR(1)')
        FROM @pXML.nodes('/DataSet/Record') T(tmp);
        
        -- 需求狀態
        ----------------------------------------------------------------------
        DECLARE @vReqStatus TABLE (wCode VARCHAR(10) PRIMARY KEY)
        INSERT INTO @vReqStatus
        SELECT wCode
        FROM dbo.mLookUp 
        WHERE wStatus = 'A' AND wType = 'REQBOOKING_STATUS'
        GROUP BY wCode;
        ----------------------------------------------------------------------

        -- Checking
        ----------------------------------------------------------------------------------
        UPDATE tmp
        SET wOldRowID = rb.RowID,
            wOldGUID = CONVERT(VARCHAR(36), rb.wGUID),
            wOldRefRid = rb.wRefRid,
            wOldReqStatus = rb.wReqStatus
        FROM @vReqBooking_DataSet tmp
        LEFT JOIN dbo.eReqBooking rb WITH(NOLOCK) ON rb.RowID = tmp.RowID
        WHERE tmp.RecordState IN ('U', 'D');
        
        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBooking_DataSet tmp WHERE tmp.RecordState IN ('U', 'D') AND NULLIF(NULLIF(tmp.wGUID, ''), '00000000-0000-0000-0000-000000000000') IS NULL)
            SET @sErrMsg = N'wGUID is invalid';

        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBooking_DataSet tmp WHERE tmp.RecordState IN ('U', 'D') AND tmp.wGUID <> tmp.wOldGUID)
            SET @sErrMsg = N'保存失敗，訂務需求已被修改';

        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBooking_DataSet tmp WHERE tmp.RecordState IN ('U', 'D') AND tmp.wOldRowID IS NULL)
            SET @sErrMsg = N'ReqBooking.RowID is invalid';
            
        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBooking_DataSet tmp WHERE tmp.RecordState IN ('I', 'U') AND ISNULL(tmp.wAgentCodeIn, '') = '')
            SET @sErrMsg = N'AgentCode is invalid';
        
        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBooking_DataSet tmp WHERE tmp.RecordState IN ('I', 'U') AND ISNULL(tmp.wReqDeptCd, '') = '')
            SET @sErrMsg = N'ReqDept is invalid';

        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBooking_DataSet tmp WHERE tmp.RecordState IN ('I', 'U') AND ISNULL(tmp.wReqUserRid, 0) <= 0 )
            SET @sErrMsg = N'ReqUser is invalid';

        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBooking_DataSet tmp LEFT JOIN @vReqStatus rs ON rs.wCode = tmp.wReqStatus WHERE rs.wCode IS NULL)
            SET @sErrMsg = N'ReqStatus is invalid';

        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBooking_DataSet tmp WHERE tmp.RecordState IN ('U', 'D') AND tmp.wOldRefRid <= 0 AND ((tmp.wReqStatus <> 'RJ' AND tmp.wOldReqStatus = 'RJ') OR (tmp.wReqStatus <> 'CL' AND tmp.wOldReqStatus = 'CL')))
            SET @sErrMsg = N'保存失敗，訂務需求已拒絕或取消';

        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBooking_DataSet tmp WHERE tmp.RecordState = 'U' AND tmp.wOldReqStatus = 'NEW' AND tmp.wReqStatus NOT IN ('NEW', 'TP', 'CL'))
            SET @sErrMsg = N'保存失敗，訂務需求未確認';

        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBooking_DataSet tmp WHERE tmp.RecordState = 'U' AND tmp.wOldReqStatus <> 'NEW' AND tmp.wReqStatus = 'NEW')
            SET @sErrMsg = N'保存失敗，訂務需求已確認';

        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBooking_DataSet tmp WHERE tmp.RecordState = 'U' AND tmp.wOldReqStatus = 'TP' AND tmp.wReqStatus = 'C')
            SET @sErrMsg = N'保存失敗，訂務需求未後批核';

        -- 已批核需求不能刪除
        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBooking_DataSet tmp WHERE tmp.wOldReqStatus <> 'TP' AND tmp.wOldRefRid <= 0 AND (tmp.wReqStatus = 'CL' OR tmp.RecordState = 'D'))
            SET @sErrMsg = N'刪除失敗，只有[待處理]的訂務需求可以刪除！';
        ----------------------------------------------------------------------------------

        SET @pErrCode = 0;
        SET @pErrMsg  = '';
        SET @sBeginTranCount = @@TRANCOUNT;
        
        BEGIN TRY
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END

            IF @sErrMsg IS NOT NULL
                THROW 50001, @sErrMsg, 1;

            -- INSERT: wRecordState = 'I'
            ----------------------------------------------------------------------------------
            IF EXISTS (SELECT 1 FROM @vReqBooking_DataSet WHERE RecordState = 'I')
            BEGIN
                SET @sRuningIndex = 1;
                SET @sRecCount = (SELECT COUNT(1) FROM @vReqBooking_DataSet);

                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    IF EXISTS (SELECT 1 FROM @vReqBooking_DataSet WHERE RowNum = @sRuningIndex AND RecordState = 'I')
                    BEGIN
                        EXEC spq.GetRowID @pMainCompNo, @sThisTable, @sRowID OUTPUT;
                        
                        UPDATE @vReqBooking_DataSet SET RowID = @sRowID WHERE RowNum = @sRuningIndex;
                    END

                    SET @sRuningIndex = @sRuningIndex + 1;
                END

                INSERT INTO dbo.eReqBooking (
                    RowID,
                    wGUID,
                    wBookingType,
                    wRefTable,
                    wRefRid,
                    wRefNo,
                    wAgentCodeIn,
                    wReqDeptCd,
                    wReqUserRid,
                    wFollowDeptCd,
                    wFollowUserRid,
                    wReqStatus,
                    wStatus,
                    wCrtBy,
                    wCrtDt,
                    wUpdBy,
                    wUpdDt
                )
                SELECT RowID,
                       NEWID(),
                       wBookingType,
                       ISNULL(wRefTable, ''),
                       ISNULL(wRefRid, 0),
                       ISNULL(wRefNo, ''),
                       wAgentCodeIn,
                       ISNULL(wReqDeptCd, ''),
                       wReqUserRid,
                       ISNULL(wFollowDeptCd, ''),
                       ISNULL(wFollowUserRid, 0),
                       -- wReqStatus,
                       wReqStatus = 'TP', -- 一落單，狀態就喺處理中
                       wStatus = 'A',
                       wCrtBy = wUpdBy,
                       wCrtDt = @sNow,
                       wUpdBy,
                       wUpdDt = @sNow
                FROM @vReqBooking_DataSet 
                WHERE RecordState = 'I'
            END
            
            -- UPDATE： wRecordState = 'U'
            ----------------------------------------------------------------------------------
            IF EXISTS (SELECT 1 FROM @vReqBooking_DataSet WHERE RecordState = 'U')
            BEGIN
                UPDATE rb
                SET -- RowID               = tmp.RowID,
                    wGUID               = NEWID(),
                    wBookingType        = tmp.wBookingType,
                    wRefTable           = IIF(rb.wRefTable = '', ISNULL(tmp.wRefTable, ''), rb.wRefTable),
                    wRefRid             = IIF(rb.wRefRid <= 0, ISNULL(tmp.wRefRid, 0), rb.wRefRid), -- 如果已經關聯到訂單，不能重新關聯到另外一張單
                    wRefNo              = IIF(rb.wRefNo = '', ISNULL(tmp.wRefNo, ''), rb.wRefNo),
					wAgentCodeIn        = tmp.wAgentCodeIn,
                    -- wReqDeptCd          = ISNULL(tmp.wReqDeptCd, ''), -- 落佐單之後，要求人，要求部門都唔可以再轉
                    -- wReqUserRid         = tmp.wReqUserRid,
                    wFollowDeptCd       = ISNULL(tmp.wFollowDeptCd, rb.wFollowDeptCd),
                    wFollowUserRid      = ISNULL(tmp.wFollowUserRid, rb.wFollowUserRid), 
                    wReqStatus          = tmp.wReqStatus,
                    -- wStatus             = tmp.wStatus,
                    -- wCrtBy              = tmp.wCrtBy,
                    -- wCrtDt              = tmp.wCrtDt,
                    wUpdBy              = tmp.wUpdBy,
                    wUpdDt              = @sNow
                FROM dbo.eReqBooking rb
                INNER JOIN @vReqBooking_DataSet tmp ON tmp.RowID = rb.RowID
                WHERE tmp.RecordState = 'U';
            END

            -- DELETE: wRecordState = 'D'
            ----------------------------------------------------------------------------------
            IF EXISTS (SELECT 1 FROM @vReqBooking_DataSet WHERE RecordState = 'D')
            BEGIN
                UPDATE rb
                SET -- RowID               = tmp.RowID,
                    wGUID               = NEWID(),
                    -- wBookingType        = tmp.wBookingType,
                    -- wRefTable           = IIF(rb.wRefTable = '', ISNULL(tmp.wRefTable, ''), rb.wRefTable),
                    -- wRefRid             = IIF(rb.wRefRid <= 0, ISNULL(tmp.wRefRid, 0), rb.wRefRid), -- 如果已經關聯到訂單，不能重新關聯到另外一張單
                    -- wRefNo              = IIF(rb.wRefNo = '', ISNULL(tmp.wRefNo, ''), rb.wRefNo),
					-- wAgentCodeIn        = tmp.wAgentCodeIn,
                    -- wReqDeptCd          = ISNULL(tmp.wReqDeptCd, ''),
                    -- wReqUserRid         = tmp.wReqUserRid,
                    -- wFollowDeptCd       = ISNULL(tmp.wFollowDeptCd, ''),
                    -- wFollowUserRid      = tmp.wFollowUserRid, 
                    wReqStatus          = 'DL',
                    wStatus             = 'T',                  -- 偽刪除
                    -- wCrtBy              = tmp.wCrtBy,
                    -- wCrtDt              = tmp.wCrtDt,
                    wUpdBy              = tmp.wUpdBy,
                    wUpdDt              = @sNow
                FROM dbo.eReqBooking rb
                INNER JOIN @vReqBooking_DataSet tmp ON tmp.RowID = rb.RowID
                WHERE tmp.RecordState = 'D';
            END

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
                SELECT RowID FROM @vReqBooking_DataSet;
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
    END