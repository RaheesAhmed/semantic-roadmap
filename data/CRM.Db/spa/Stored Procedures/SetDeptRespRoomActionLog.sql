CREATE PROC [spa].[SetDeptRespRoomActionLog]
    @pXML           XML,
    @pMainCompNo    INT,
    @pReturnResult  CHAR(1) = 'N',
    @pTestMode      INT = 0,
    @pErrCode       INT OUTPUT,
    @pErrMsg        NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        -- dbml
        ----------------------------------
        --DECLARE @vResult TABLE (RowID BIGINT NOT NULL);
        --SELECT * FROM @vResult;
        ----------------------------------

        SET @pErrCode = 0;
        SET @pErrMsg  = '';

        DECLARE @sThisTableName     VARCHAR(50) = 'eDeptRespRoomActionLog' , -- For RowID
                @sBeginTranCount    INT = 0 ,
                @sRecCount          INT = 0 ,
                @sRuningIndex       INT = 1 ,
                @sRowID             BIGINT = 0 ,
                @sNow               DATETIME2(7) = dbo.fnUTC8Now();

        DECLARE @vDeptRespRoomActionLog_DataSet TABLE (
            RowNum              INT,
            RowID               BIGINT,
            wDeptReqRoomRid     BIGINT,
            wDeptRespRoomRid    BIGINT,
            wBookingRid         BIGINT,
            wGUID               UNIQUEIDENTIFIER,
            wHotelRid           BIGINT,
            wRoomRid            BIGINT,
            wBigBedQty          INT,
            wTwinBedQty         INT,
            wSuiteRoom1Qty      INT,
            wSuiteRoom2Qty      INT,
            wSuiteRoom3Qty      INT,
            wDayOfStay          INT,
            wStartDate          DATE,
            wEndDate            DATE,
            wIsApproved         CHAR(1),
            wTotalAmount        NUMERIC(18, 4),
            wRemark             NVARCHAR(4000),
            wCancelReason       NVARCHAR(500),
            wStatus             VARCHAR(20),
            wDeptStatus         VARCHAR(20),
            wRepStatus          VARCHAR(20),
            wIsExtRoom          CHAR(1),
            wCrtDt              DATETIME2(7),
            wCrtBy              BIGINT,
            wUpdDt              DATETIME2(7),
            wUpdBy              BIGINT,
            RecordState         CHAR(1) -- I/U/D
        );

        IF @pXML IS NOT NULL
        BEGIN
            INSERT INTO @vDeptRespRoomActionLog_DataSet (
                RowNum,
                RowID,
                wDeptReqRoomRid,
                wDeptRespRoomRid,
                wBookingRid,
                wGUID,
                wHotelRid,
                wRoomRid,
                wBigBedQty,
                wTwinBedQty,
                wSuiteRoom1Qty,
                wSuiteRoom2Qty,
                wSuiteRoom3Qty,
                wDayOfStay,
                wStartDate,
                wEndDate,
                wIsApproved,
                wTotalAmount,
                wRemark,
                wCancelReason,
                wStatus,
                wDeptStatus,
                wRepStatus,
                wIsExtRoom,
                wCrtDt,
                wCrtBy,
                wUpdDt,
                wUpdBy,
                RecordState
            )
            SELECT RowNum = ROW_NUMBER() OVER (ORDER BY tmp.RowID),
                   tmp.*
            FROM ( SELECT RowID            = T.tmp.value('@RowID',            'BIGINT'),
                          wDeptReqRoomRid  = T.tmp.value('@wDeptReqRoomRid',  'BIGINT'),
                          wDeptRespRoomRid = T.tmp.value('@wDeptRespRoomRid', 'BIGINT'),
                          wBookingRid      = T.tmp.value('@wBookingRid',      'BIGINT'),
                          wGUID            = T.tmp.value('@wGUID',            'UNIQUEIDENTIFIER'),
                          wHotelRid        = T.tmp.value('@wHotelRid',        'BIGINT'),
                          wRoomRid         = T.tmp.value('@wRoomRid',         'BIGINT'),
                          wBigBedQty       = T.tmp.value('@wBigBedQty',       'INT'),
                          wTwinBedQty      = T.tmp.value('@wTwinBedQty',      'INT'),
                          wSuiteRoom1Qty   = T.tmp.value('@wSuiteRoom1Qty',   'INT'),
                          wSuiteRoom2Qty   = T.tmp.value('@wSuiteRoom2Qty',   'INT'),
                          wSuiteRoom3Qty   = T.tmp.value('@wSuiteRoom3Qty',   'INT'),
                          wDayOfStay       = T.tmp.value('@wDayOfStay',       'INT'),
                          wStartDate       = T.tmp.value('@wStartDate',       'DATE'),
                          wEndDate         = T.tmp.value('@wEndDate',         'DATE'),
                          wIsApproved      = T.tmp.value('@wIsApproved',      'CHAR(1)'),
                          wTotalAmount     = T.tmp.value('@wTotalAmount',     'NUMERIC(18, 4)'),
                          wRemark          = T.tmp.value('@wRemark',          'NVARCHAR(4000)'),
                          wCancelReason    = T.tmp.value('@wCancelReason',    'NVARCHAR(500)'),
                          wStatus          = T.tmp.value('@wStatus',          'VARCHAR(20)'),
                          wDeptStatus      = T.tmp.value('@wDeptStatus',      'VARCHAR(20)'),
                          wRepStatus       = T.tmp.value('@wRepStatus',       'VARCHAR(20)'),
                          wIsExtRoom       = T.tmp.value('@wIsExtRoom',       'CHAR(1)'),
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
            IF EXISTS (SELECT 1 FROM @vDeptRespRoomActionLog_DataSet WHERE RecordState = 'I')
            BEGIN
                SET @sRuningIndex = 1;
                SET @sRecCount = (SELECT COUNT(1) FROM @vDeptRespRoomActionLog_DataSet);
                
                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    IF EXISTS (SELECT 1 FROM @vDeptRespRoomActionLog_DataSet WHERE RowNum = @sRuningIndex AND RecordState = 'I')
                    BEGIN
                        EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;

                        UPDATE @vDeptRespRoomActionLog_DataSet
                        SET RowID = @sRowID
                        WHERE RowNum = @sRuningIndex;
                    END

                    SET @sRuningIndex = @sRuningIndex + 1;
                END

                INSERT INTO dbo.eDeptRespRoomActionLog (
                    RowID,
                    wDeptReqRoomRid,
                    wDeptRespRoomRid,
                    wBookingRid,
                    wGUID,
                    wHotelRid,
                    wRoomRid,
                    wBigBedQty,
                    wTwinBedQty,
                    wSuiteRoom1Qty,
                    wSuiteRoom2Qty,
                    wSuiteRoom3Qty,
                    wDayOfStay,
                    wStartDate,
                    wEndDate,
                    wIsApproved,
                    wTotalAmount,
                    wRemark,
                    wCancelReason,
                    wStatus,
                    wDeptStatus,
                    wRepStatus,
                    wIsExtRoom,
                    wCrtDt,
                    wCrtBy,
                    wUpdDt,
                    wUpdBy,
                    wRecStatus
                )
                SELECT RowID,
                       wDeptReqRoomRid,
                       wDeptRespRoomRid,
                       wBookingRid,
                       wGUID,
                       wHotelRid,
                       wRoomRid,
                       wBigBedQty,
                       wTwinBedQty,
                       wSuiteRoom1Qty,
                       wSuiteRoom2Qty,
                       wSuiteRoom3Qty,
                       wDayOfStay,
                       wStartDate,
                       wEndDate,
                       wIsApproved,
                       wTotalAmount,
                       wRemark,
                       wCancelReason,
                       wStatus,
                       wDeptStatus,
                       wRepStatus,
                       wIsExtRoom,
                       wCrtDt,
                       wCrtBy,
                       wUpdDt,
                       wUpdBy,
                       wRecStatus = 'A'
                    FROM @vDeptRespRoomActionLog_DataSet
                    WHERE RecordState = 'I';
            END

            -- update
            IF EXISTS (SELECT 1 FROM @vDeptRespRoomActionLog_DataSet WHERE RecordState = 'U')
            BEGIN
                UPDATE resp_log
                SET -- RowID             = tmp.RowID,
                    wDeptReqRoomRid   = tmp.wDeptReqRoomRid,
                    wDeptRespRoomRid  = tmp.wDeptRespRoomRid,
                    wBookingRid       = tmp.wBookingRid,
                    wGUID             = tmp.wGUID,
                    wHotelRid         = tmp.wHotelRid,
                    wRoomRid          = tmp.wRoomRid,
                    wBigBedQty        = tmp.wBigBedQty,
                    wTwinBedQty       = tmp.wTwinBedQty,
                    wSuiteRoom1Qty    = tmp.wSuiteRoom1Qty,
                    wSuiteRoom2Qty    = tmp.wSuiteRoom2Qty,
                    wSuiteRoom3Qty    = tmp.wSuiteRoom3Qty,
                    wDayOfStay        = tmp.wDayOfStay,
                    wStartDate        = tmp.wStartDate,
                    wEndDate          = tmp.wEndDate,
                    wIsApproved       = tmp.wIsApproved,
                    wTotalAmount      = tmp.wTotalAmount,
                    wRemark           = tmp.wRemark,
                    wCancelReason     = tmp.wCancelReason,
                    wStatus           = tmp.wStatus,
                    wDeptStatus       = tmp.wDeptStatus,
                    wRepStatus        = tmp.wRepStatus,
                    wIsExtRoom        = tmp.wIsExtRoom,
                    wCrtDt            = tmp.wCrtDt,
                    wCrtBy            = tmp.wCrtBy,
                    wUpdDt            = tmp.wUpdDt,
                    wUpdBy            = tmp.wUpdBy
                    -- wRecStatus         = 'A'
                FROM dbo.eDeptRespRoomActionLog resp_log
                INNER JOIN @vDeptRespRoomActionLog_DataSet tmp ON tmp.RowID = resp_log.RowID
                WHERE tmp.RecordState = 'U';
            END

            -- delete
            IF EXISTS (SELECT 1 FROM @vDeptRespRoomActionLog_DataSet WHERE RecordState = 'D')
            BEGIN
                UPDATE resp_log
                SET -- RowID             = tmp.RowID,
                    wDeptReqRoomRid   = tmp.wDeptReqRoomRid,
                    wDeptRespRoomRid  = tmp.wDeptRespRoomRid,
                    wBookingRid       = tmp.wBookingRid,
                    wGUID             = tmp.wGUID,
                    wHotelRid         = tmp.wHotelRid,
                    wRoomRid          = tmp.wRoomRid,
                    wBigBedQty        = tmp.wBigBedQty,
                    wTwinBedQty       = tmp.wTwinBedQty,
                    wSuiteRoom1Qty    = tmp.wSuiteRoom1Qty,
                    wSuiteRoom2Qty    = tmp.wSuiteRoom2Qty,
                    wSuiteRoom3Qty    = tmp.wSuiteRoom3Qty,
                    wDayOfStay        = tmp.wDayOfStay,
                    wStartDate        = tmp.wStartDate,
                    wEndDate          = tmp.wEndDate,
                    wIsApproved       = tmp.wIsApproved,
                    wTotalAmount      = tmp.wTotalAmount,
                    wRemark           = tmp.wRemark,
                    wCancelReason     = tmp.wCancelReason,
                    wStatus           = tmp.wStatus,
                    wDeptStatus       = tmp.wDeptStatus,
                    wRepStatus        = tmp.wRepStatus,
                    wIsExtRoom        = tmp.wIsExtRoom,
                    wCrtDt            = tmp.wCrtDt,
                    wCrtBy            = tmp.wCrtBy,
                    wUpdDt            = tmp.wUpdDt,
                    wUpdBy            = tmp.wUpdBy,
                    wRecStatus         = 'T'
                FROM dbo.eDeptRespRoomActionLog resp_log
                INNER JOIN @vDeptRespRoomActionLog_DataSet tmp ON tmp.RowID = resp_log.RowID
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
                SELECT RowID FROM @vDeptRespRoomActionLog_DataSet;
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