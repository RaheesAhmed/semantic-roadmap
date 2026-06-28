-- Only one record per time
CREATE PROC [spa].[SetReqBookingHotelChange]
    @pReqBookingXML         XML,
    @pReqBookingHotelXML    XML,
    @pMainCompNo            INT,
    @pRefTable              VARCHAR(50) OUTPUT,
    @pRefRid                BIGINT OUTPUT,
    @pRefNo                 VARCHAR(50) OUTPUT,
    @pErrCode               INT OUTPUT,
    @pErrMsg                NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        -- dbml
        ------------------------------------
        --DECLARE @vResult TABLE(RowID BIGINT NOT NULL, wBookingType VARCHAR(30) NOT NULL, wRefTable VARCHAR(50) NOT NULL, wRefRid BIGINT NOT NULL);
        --SELECT RowID, wBookingType, wRefTable, wRefRid FROM @vResult;
        ------------------------------------
        
        DECLARE @sNewReqStatus  VARCHAR(10),
                @sOldReqStatus  VARCHAR(10),
                @sNow           DATETIME2(7) = dbo.fnUTC8Now();

        -- dbo.eReqBooking
        ------------------------------------------------------------------------
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
        FROM @pReqBookingXML.nodes('/DataSet/Record') T(tmp);
        ------------------------------------------------------------------------

        -- dbo.eBookingHotel
        ------------------------------------------------------------------------
        DECLARE @vReqBookingHotel_DateSet TABLE (
            RowNum              INT IDENTITY(1, 1),
            RowID               BIGINT,
            wGUID               VARCHAR(36),
            wReqBookingRid      BIGINT,
            wHotelRid           BIGINT,
            wHotelRoomRid       BIGINT,
            wCheckInDate        DATE,
            wCheckOutDate       DATE,
            wBigBedRoomQty      INT,
            wTwinBedRoomQty     INT,
            wSuiteRoom1Qty      INT,
            wSuiteRoom2Qty      INT,
            wSuiteRoom3Qty      INT,
            wRemark             NVARCHAR(4000),
            -- wStatus             CHAR(1),
            -- wCrtBy              BIGINT,
            -- wCrtDt              DATETIME2(7),
            wUpdBy              BIGINT,
            -- wUpdDt              DATETIME2(7),
            RecordState         CHAR(1) -- I/U/D
        );
        
        INSERT INTO @vReqBookingHotel_DateSet (
            RowID,
            wGUID,
            wReqBookingRid,
            wHotelRid,
            wHotelRoomRid,
            wCheckInDate,
            wCheckOutDate,
            wBigBedRoomQty,
            wTwinBedRoomQty,
            wSuiteRoom1Qty,
            wSuiteRoom2Qty,
            wSuiteRoom3Qty,
            wRemark,
            -- wStatus,
            -- wCrtBy,
            -- wCrtDt,
            wUpdBy,
            -- wUpdDt,
            RecordState
        )
        SELECT  RowID               = T.tmp.value('@RowID',             'BIGINT'),
                wGUID               = T.tmp.value('@wGUID',             'VARCHAR(36)'),
                wReqBookingRid      = T.tmp.value('@wReqBookingRid',    'BIGINT'),
                wHotelRid           = T.tmp.value('@wHotelRid',         'BIGINT'),
                wHotelRoomRid       = T.tmp.value('@wHotelRoomRid',     'BIGINT'),
                wCheckInDate        = T.tmp.value('@wCheckInDate',      'DATE'),
                wCheckOutDate       = T.tmp.value('@wCheckOutDate',     'DATE'),
                wBigBedRoomQty      = T.tmp.value('@wBigBedRoomQty',    'INT'),
                wTwinBedRoomQty     = T.tmp.value('@wTwinBedRoomQty',   'INT'),
                wSuiteRoom1Qty      = T.tmp.value('@wSuiteRoom1Qty',    'INT'),
                wSuiteRoom2Qty      = T.tmp.value('@wSuiteRoom2Qty',    'INT'),
                wSuiteRoom3Qty      = T.tmp.value('@wSuiteRoom3Qty',    'INT'),
                wRemark             = T.tmp.value('@wRemark',           'NVARCHAR(4000)'),
                -- wStatus             = T.tmp.value('@wStatus',           'CHAR(1)'),
                -- wCrtBy              = T.tmp.value('@wCrtBy',            'BIGINT'),
                -- wCrtDt              = T.tmp.value('@wCrtDt',            'DATETIME2(7)'),
                wUpdBy              = T.tmp.value('@wUpdBy',            'BIGINT'),
                -- wUpdDt              = T.tmp.value('@wUpdDt',            'DATETIME2(7)'),
                RecordState         = T.tmp.value('@RecordState',       'CHAR(1)')
        FROM @pReqBookingHotelXML.nodes('/DataSet/Record') T(tmp);
        ------------------------------------------------------------------------

        -- Checking
        ------------------------------------------------------------------------
        SET @pErrCode = 0;
        SET @pErrMsg = '';

        IF (SELECT COUNT(1) FROM @vReqBooking_DataSet) <> 1 OR (SELECT COUNT(1) FROM @vReqBookingHotel_DateSet) <> 1
        BEGIN
            SET @pErrCode = 50001;
            SET @pErrMsg = N'Only one record per time';
        END
        ------------------------------------------------------------------------

        -- 訂務需求批核，在“部門酒店訂房 - 中央訂房部” 生成一條房間需求記錄
        ------------------------------------------------------------------------
        IF @pErrMsg = ''
        BEGIN
            SELECT @sNewReqStatus   = ISNULL(tmp.wReqStatus, ''),
                   -- (1)新加Record，OldReqStatus = ''；
                   -- (2)修改Record，Record不存在，OldReqStatus = ''；
                   -- (3)修改Record，已經有相關訂務訂單，OldReqStatus = ''
                   -- (4)否則，OldReqStatus = dbo.eReqBooking.wReqStatus
                   @sOldReqStatus   = IIF(tmp.RecordState = 'I' OR  rb.RowID IS NULL OR rb.wRefRid > 0, '', rb.wReqStatus)
            FROM @vReqBooking_DataSet tmp
            LEFT JOIN dbo.eReqBooking rb WITH(NOLOCK) ON rb.RowID = tmp.RowID
            WHERE tmp.RecordState IN ('I', 'U');

            -- 確認派房，在部門酒店訂房生成一條記錄
            IF @sOldReqStatus = 'TP' AND @sNewReqStatus = 'P'
            BEGIN
                DECLARE @vXML XML;

                SET @vXML = (
                    SELECT  RowID               = 0,
                            wRequestNo          = '',
                            wRequestDepartment  = 'ROOM',
                            wAgentCodeIn        = rb.wAgentCodeIn,
                            wHotelRid           = rbh.wHotelRid,
                            wRoomRid            = ISNULL(rbh.wHotelRoomRid, ''),
                            wBigBedQty          = rbh.wBigBedRoomQty,
                            wTwinBedQty         = rbh.wTwinBedRoomQty,
                            wSuiteRoom1Qty      = rbh.wSuiteRoom1Qty,
                            wSuiteRoom2Qty      = rbh.wSuiteRoom2Qty,
                            wSuiteRoom3Qty      = rbh.wSuiteRoom3Qty,
                            wDayOfStay          = DATEDIFF(DAY, rbh.wCheckInDate, rbh.wCheckOutDate),
                            wStartDate          = rbh.wCheckInDate,
                            wEndDate            = rbh.wCheckOutDate,
                            wRemark             = ISNULL(rbh.wRemark, ''),
                            wStaffFollowedRid   = ISNULL(rb.wFollowUserRid, 0),
                            wDeptFollowedCode   = 'ROOM', -- OP#25033， 跟進部門 = 'ROOM'
                            wStatus             = 'A',
                            wRespFlag           = 'N',
                            wCrtDt              = @sNow,
                            wCrtBy              = rb.wUpdBy,
                            wUpdDt              = @sNow,
                            wUpdBy              = rb.wUpdBy,
                            wEventRid           = 0,
                            wIsNewReqRoom       = 'Y',
                            wIsCancel           = 'N',
                            wCancelDt           = NULL,
                            wTotalAmt           = 0,
                            wApplyStaffRid      = rb.wReqUserRid,
                            wApplyDepartment    = rb.wReqDeptCd,
                            wGUID               = NEWID(),
                            wIsReqBooking       = 'Y'
                    FROM @vReqBooking_DataSet rb, @vReqBookingHotel_DateSet rbh
                    FOR XML RAW('Record'), ROOT('DataSet')
                );

                IF @vXML IS NOT NULL
                BEGIN
                    DECLARE @vResult TABLE (RowID BIGINT, wRequestNo VARCHAR(30));

                    INSERT INTO @vResult(RowID, wRequestNo)
                    EXEC spa.SetDeptRequsetRoom @pXML           = @vXML,
                                                @pActionType    = 'I',
                                                @pMainCompNo    = @pMainCompNo,
                                                @pReturnResult  = 'Y',
                                                @pTestMode      = 0,
                                                @pErrCode       = @pErrCode OUTPUT,
                                                @pErrMsg        = @pErrMsg OUTPUT;

                    IF NULLIF(@pErrMsg, '') IS NULL
                    BEGIN
                        SELECT  @pRefTable  = 'eDeptReqRoom', 
                                @pRefRid    = RowID,
                                @pRefNo     = wRequestNo
                        FROM @vResult r
                    END
                END
            END
        END
    END