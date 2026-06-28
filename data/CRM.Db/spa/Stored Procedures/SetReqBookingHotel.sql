CREATE PROC [spa].[SetReqBookingHotel]
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
        --DECLARE @vResult TABLE (RowID BIGINT PRIMARY KEY);
        --SELECT * FROM @vResult;
        -------------------------------------------------

        DECLARE @sThisTable         VARCHAR(50) = 'eReqBookingHotel',
                @sBeginTranCount    INT = 0 ,
                @sRecCount          INT = 0 ,
                @sRuningIndex       INT = 1 ,
                @sRowID             BIGINT = 0 ,
                @sNow               DATETIME2(7) = dbo.fnUTC8Now(),
                @sErrMsg            NVARCHAR(200);

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
            wOldRowID           BIGINT,      -- DB保存的RowID，RecordState = U/D時，Get到的值不能為空
            wOldGUID            VARCHAR(36),
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
        FROM @pXML.nodes('/DataSet/Record') T(tmp);

        -- Checking
        ----------------------------------------------------------------------------------
        UPDATE tmp
        SET wOldRowID = rbh.RowID,
            wOldGUID = CONVERT(VARCHAR(36), rbh.wGUID)
        FROM @vReqBookingHotel_DateSet tmp
        LEFT JOIN dbo.eReqBookingHotel rbh WITH(NOLOCK) ON rbh.RowID = tmp.RowID
        WHERE tmp.RecordState IN ('U', 'D');
        
        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBookingHotel_DateSet tmp WHERE tmp.RecordState IN ('U', 'D') AND NULLIF(NULLIF(tmp.wGUID, ''), '00000000-0000-0000-0000-000000000000') IS NULL)
            SET @sErrMsg = N'wGUID is invalid';
            
        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBookingHotel_DateSet tmp WHERE tmp.RecordState IN ('U', 'D') AND tmp.wOldGUID <> tmp.wGUID)
            SET @sErrMsg = N'保存失敗，訂務需求已被修改';

        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBookingHotel_DateSet tmp WHERE tmp.RecordState IN ('I', 'U') AND ISNULL(tmp.wReqBookingRid, 0) <= 0)
            SET @sErrMsg = N'ReqBookingHotel.ReqBookingRid is invalid';
        
        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBookingHotel_DateSet tmp WHERE tmp.RecordState IN ('I', 'U') AND ISNULL(tmp.wHotelRid, 0) <= 0)
            SET @sErrMsg = N'Hotel is invalid';

        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBookingHotel_DateSet tmp WHERE tmp.RecordState IN ('I', 'U') AND tmp.wCheckInDate IS NULL OR tmp.wCheckOutDate IS NULL OR tmp.wCheckInDate >= tmp.wCheckOutDate)
            SET @sErrMsg = N'CheckInDate or CheckOutDate is invalid';

        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBookingHotel_DateSet tmp WHERE tmp.RecordState IN ('I', 'U') AND ISNULL(tmp.wBigBedRoomQty, 0) + ISNULL(tmp.wTwinBedRoomQty, 0) + ISNULL(tmp.wSuiteRoom1Qty, 0) + ISNULL(tmp.wSuiteRoom2Qty, 0) + ISNULL(tmp.wSuiteRoom3Qty, 0) <= 0)
            SET @sErrMsg = N'RoomQty is invalid';

        IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM @vReqBookingHotel_DateSet tmp WHERE tmp.RecordState IN ('U', 'D') AND tmp.wOldRowID IS NULL)
            SET @sErrMsg = N'ReqBookingHotel.RowID is invalid';
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

            -- INSERT: RecordState = 'I'
            ----------------------------------------------------------------------------------
            IF EXISTS (SELECT 1 FROM @vReqBookingHotel_DateSet WHERE RecordState = 'I')
            BEGIN
                SET @sRuningIndex = 1;
                SET @sRecCount = (SELECT COUNT(1) FROM @vReqBookingHotel_DateSet);

                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    IF EXISTS (SELECT 1 FROM @vReqBookingHotel_DateSet WHERE RowNum = @sRuningIndex AND RecordState = 'I')
                    BEGIN
                        EXEC spq.GetRowID @pMainCompNo, @sThisTable, @sRowID OUTPUT;
                        
                        UPDATE @vReqBookingHotel_DateSet SET RowID = @sRowID WHERE RowNum = @sRuningIndex;
                    END

                    SET @sRuningIndex = @sRuningIndex + 1;
                END

                INSERT INTO dbo.eReqBookingHotel (
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
                    wStatus,
                    wCrtBy,
                    wCrtDt,
                    wUpdBy,
                    wUpdDt
                )
                SELECT RowID,
                       NEWID(),
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
                       ISNULL(wRemark, ''),
                       wStatus = 'A',
                       wCrtBy = wUpdBy,
                       wCrtDt = @sNow,
                       wUpdBy,
                       wUpdDt = @sNow
                FROM @vReqBookingHotel_DateSet
                WHERE RecordState = 'I';
            END
            
            -- UPDATE： RecordState = 'U'
            ----------------------------------------------------------------------------------
            IF EXISTS (SELECT 1 FROM @vReqBookingHotel_DateSet WHERE RecordState = 'U')
            BEGIN
                UPDATE rbh
                SET -- RowID           = tmp.RowID,
                    wGUID           = NEWID(),
                    -- wReqBookingRid  = tmp.wReqBookingRid,
                    wHotelRid       = tmp.wHotelRid,
                    wHotelRoomRid   = tmp.wHotelRoomRid,
                    wCheckInDate    = tmp.wCheckInDate,
                    wCheckOutDate   = tmp.wCheckOutDate,
                    wBigBedRoomQty  = tmp.wBigBedRoomQty,
                    wTwinBedRoomQty = tmp.wTwinBedRoomQty,
                    wSuiteRoom1Qty  = tmp.wSuiteRoom1Qty,
                    wSuiteRoom2Qty  = tmp.wSuiteRoom2Qty,
                    wSuiteRoom3Qty  = tmp.wSuiteRoom3Qty,
                    wRemark         = ISNULL(tmp.wRemark, ''),
                    -- wStatus         = tmp.wStatus,
                    -- wCrtBy          = tmp.wCrtBy,
                    -- wCrtDt          = tmp.wCrtDt,
                    wUpdBy          = tmp.wUpdBy,
                    wUpdDt          = @sNow
                FROM dbo.eReqBookingHotel rbh
                INNER JOIN @vReqBookingHotel_DateSet tmp ON tmp.RowID = rbh.RowID
                WHERE tmp.RecordState = 'U';
            END

            -- DELETE: RecordState = 'D'
            ----------------------------------------------------------------------------------
            IF EXISTS (SELECT 1 FROM @vReqBookingHotel_DateSet WHERE RecordState = 'D')
            BEGIN
                UPDATE rbh
                SET -- RowID           = tmp.RowID,
                    wGUID           = NEWID(),
                    -- wReqBookingRid  = tmp.wReqBookingRid,
                    -- wHotelRid       = tmp.wHotelRid,
                    -- wHotelRoomRid   = tmp.wHotelRoomRid,
                    -- wCheckInDate    = tmp.wCheckInDate,
                    -- wCheckOutDate   = tmp.wCheckOutDate,
                    -- wBigBedRoomQty  = tmp.wBigBedRoomQty,
                    -- wTwinBedRoomQty = tmp.wTwinBedRoomQty,
                    -- wSuiteRoom1Qty  = tmp.wSuiteRoom1Qty,
                    -- wSuiteRoom2Qty  = tmp.wSuiteRoom2Qty,
                    -- wSuiteRoom3Qty  = tmp.wSuiteRoom3Qty,
                    -- wRemark         = tmp.wRemark,
                    wStatus         = 'T',
                    -- wCrtBy          = tmp.wCrtBy,
                    -- wCrtDt          = tmp.wCrtDt,
                    wUpdBy          = tmp.wUpdBy,
                    wUpdDt          = @sNow
                FROM dbo.eReqBookingHotel rbh
                INNER JOIN @vReqBookingHotel_DateSet tmp ON tmp.RowID = rbh.RowID
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
                SELECT RowID FROM @vReqBookingHotel_DateSet;
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