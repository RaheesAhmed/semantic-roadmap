CREATE PROC [test].[SUNTrip_SetHotelChange]
    @pXML                   XML ,
    @pActionType            CHAR(1) ,
    @pMainCompNo            INT ,
    @pNonceToken            VARCHAR(64) ,
    @pBookingRid            BIGINT OUTPUT,
    @pHotelChangeRid        BIGINT OUTPUT,
    @pErrCode               INT = 0 OUTPUT ,
    @pErrMsg                NVARCHAR(200) = '' OUTPUT
AS  
    BEGIN
        SET NOCOUNT ON;

        SET @pErrCode = 0 ;
        SET @pErrMsg = '';

        DECLARE @sRowID BIGINT,
                @sRuningIndex INT,
                @sRecordCount INT,
                @sBeginTranCount INT,
                @sNow DATETIME2(7) = GETDATE();	

        DECLARE @sOldHotelChangeStatus VARCHAR(10),
                @sNewHotelChangeStatus VARCHAR(10);
                
        SET @sBeginTranCount = @@trancount;
		
        DECLARE @vDataSet_HotelChange TABLE (
            RowID               BIGINT,
            wHotelBookingRid    BIGINT,
            wRoomBookingRid     BIGINT,
            wHotelRid           BIGINT,
            wHotelRoomRid       BIGINT,
            wAllotmentRid       BIGINT,
            wAction             VARCHAR(5),
            wHotelChangeStatus  VARCHAR(10)
        );

        DECLARE @vBooking TABLE (
            RowNum               INT IDENTITY(1, 1),
            RowID                BIGINT             NOT NULL,
            wBookingType         VARCHAR(30)        NOT NULL,
            wRefNo               VARCHAR(30)        NOT NULL,
            [GUID]               UNIQUEIDENTIFIER   NOT NULL,
            wReqCounterRid       BIGINT             NOT NULL,
            wDebitCounterRid     BIGINT             NOT NULL,
            wReqAgentCodeIn      VARCHAR(14)        NOT NULL,
            wDebitAgentCodeIn    VARCHAR(14)        NOT NULL,
            wReqCustomerRid      BIGINT             NOT NULL,
            wDebitCustomerRid    BIGINT             NOT NULL,
            wReqDepartment       VARCHAR(30)        NOT NULL,
            wReqUserRid          BIGINT             NOT NULL,
            wAsstBooker          NVARCHAR(50)       NOT NULL,
            wAssBookerTel        VARCHAR(100)       NOT NULL,
            wApprovalAgentCodeIn VARCHAR(14)        NOT NULL,
            wDebitDt             DATETIME2(7)       NOT NULL,
            wExpDt               DATETIME2(7)       NOT NULL,
            wCancelDebitDt       DATETIME2(7)       NULL,
            wCancelReasonCd      VARCHAR(30)        NULL,
            wCancelBy            BIGINT             NULL,
            wCancelDt            DATETIME2(7)       NULL,
            wCrtDt               DATETIME2(7)       NOT NULL,
            wCrtBy               BIGINT             NOT NULL,
            wUpdDt               DATETIME2(7)       NOT NULL,
            wUpdBy               BIGINT             NOT NULL,
            wTravePkgRid         BIGINT             NOT NULL,
            wEventCodeRid        BIGINT             NOT NULL,
            wAsstBookerEmail     NVARCHAR(50)       NOT NULL,
            wDeptFollwedCd       VARCHAR(30)        NOT NULL,
            wStaffFollwedRid     BIGINT             NOT NULL,
            wStaffTelephone      VARCHAR(100)       NOT NULL,
            wOwnerAuthTelephone  VARCHAR(100)       NOT NULL,
            wOtherReason         NVARCHAR(200)      NOT NULL,
            wDepositAmt          NUMERIC(18, 4)     NOT NULL,
            wGiftReasonCd        VARCHAR(30)        NOT NULL,
            wUseTravelPkg        CHAR(1)            NULL,
            -- wHasDeposit          CHAR(1)            NOT NULL,
            wDepositDebitDt      DATETIME2(7)       NOT NULL,
            wBookingStatus       VARCHAR(10)        NOT NULL,
            wCoordinator         NVARCHAR(50)       NOT NULL,
            wUser                NVARCHAR(50)       NOT NULL,
            wIsUser              CHAR(1)            NOT NULL
        );

        DECLARE @vHotelChange TABLE (
            RowNum                  INT IDENTITY(1, 1),
            RowID                   BIGINT          NOT NULL,
            wRoomBookingRid         BIGINT          NOT NULL,
            wAllotmentRid           BIGINT          NOT NULL,
            wAction                 VARCHAR(5)      NOT NULL,
            wOriStartDate           DATE            NOT NULL,
            wOriEndDate             DATE            NOT NULL,
            wNewStartDate           DATE            NOT NULL,
            wNewEndDate             DATE            NOT NULL,
            wDayOfStay              INT             NOT NULL,
            wVoucherNo              VARCHAR(40)     NOT NULL,
            wCashReceiptNo          NVARCHAR(40)    NOT NULL,
            wCashTransferReceiptNo  VARCHAR(40)     NOT NULL,
            wUseMemeberCard         CHAR(1)         NOT NULL,
            wUseExtraAllotment      CHAR(1)         NOT NULL,
            wUseUpAllotment         CHAR(1)         NOT NULL,
            wGetKeyMethod           VARCHAR(30)     NOT NULL,
            wReGetKey               CHAR(1)         NOT NULL,
            wChangeCheckinPwd       CHAR(1)         NOT NULL,
            wCurrCode               CHAR(3)         NOT NULL,
            wPaymentMethod          VARCHAR(30)     NOT NULL,
            wRemark                 NVARCHAR(500)   NOT NULL,
            wCrtDt                  DATETIME2(7)    NOT NULL,
            wCrtBy                  BIGINT          NOT NULL,
            wUpdDt                  DATETIME2(7)    NOT NULL,
            wUpdBy                  BIGINT          NOT NULL,
            wOrderNo                NVARCHAR(60)    NOT NULL,
            wAmountChange           NUMERIC(18, 4)  NOT NULL,
            wBookingRid             BIGINT          NOT NULL,
            wCostChange             NUMERIC(18, 4)  NOT NULL,
            wTotalAmount            NUMERIC(18, 4)  NOT NULL,
            wTotalCost              NUMERIC(18, 4)  NOT NULL,
            wDateChange             NVARCHAR(64)    NULL,
            wHotelChangeNo          NVARCHAR(30)    NULL,
            wHotelChangeStatus      VARCHAR(10)     NOT NULL
        );

        DECLARE @vHotelCheckIn TABLE (
            RowNum                  INT IDENTITY(1, 1),
            RowID                   BIGINT          NOT NULL,
            wRoomBookingRid         BIGINT          NOT NULL,
            wHotelRid               BIGINT          NOT NULL,
            wRoomRid                BIGINT          NOT NULL,
            wAllotmentGroupRid      BIGINT          NOT NULL,
            wRoomNo                 NVARCHAR(20)    NOT NULL,
            wBookingDate            DATE            NOT NULL,
            wCurrCode               CHAR(3)         NOT NULL,
            wPrice                  NUMERIC(18, 4)  NOT NULL,
            wCost                   NUMERIC(18, 4)  NOT NULL,
            wIncludeBreakfast       CHAR(1)         NOT NULL,
            wExtraRoom              CHAR(1)         NOT NULL,
            wDismiss                CHAR(1)         NOT NULL,
            wExtent                 CHAR(1)         NOT NULL,
            wAgencyRoom             CHAR(1)         NOT NULL,
            wStatus                 CHAR(1)         NOT NULL,
            wCrtDt                  DATETIME2(7)    NOT NULL,
            wCrtBy                  BIGINT          NOT NULL,
            wUpdDt                  DATETIME2(7)    NOT NULL,
            wUpdBy                  BIGINT          NOT NULL,
            wHotelChangeRid         BIGINT          NOT NULL,
            wBreakfastPrice         NUMERIC(18, 4)  NOT NULL,
            wExtraBedPrice          NUMERIC(18, 4)  NOT NULL,
            wExtraBed               CHAR(1)         NOT NULL
        );

        INSERT INTO @vDataSet_HotelChange
        SELECT  RowID                 = T.tmp.value('@RowID',                'BIGINT'),
                wHotelBookingRid      = T.tmp.value('@wHotelBookingRid',     'BIGINT') ,
                wRoomBookingRid       = T.tmp.value('@wRoomBookingRid',      'BIGINT'),
                wHotelRid             = T.tmp.value('@wHotelRid',            'BIGINT'),
                wHotelRoomRid         = T.tmp.value('@wHotelRoomRid',        'BIGINT'),
                wAllotmentRid         = T.tmp.value('@wAllotmentRid',        'BIGINT'),
                wAction               = T.tmp.value('@wAction',              'VARCHAR(5)'),
                wHotelChangeStatus    = T.tmp.value('@wHotelChangeStatus',   'VARCHAR(10)')
        FROM @pXML.nodes('DataSet/GetHotelChangeDateCheckInByBookingRoomIdResult') T(tmp);

        INSERT INTO @vBooking
        SELECT  RowID                = T.tmp.value('@RowID',                'BIGINT'),
                wBookingType         = T.tmp.value('@wBookingType',         'VARCHAR(30)'),
                wRefNo               = T.tmp.value('@wRefNo',               'VARCHAR(30)'),
                [GUID]               = NEWID(), --T.tmp.value('@GUID',                 'UNIQUEIDENTIFIER'),
                wReqCounterRid       = T.tmp.value('@wReqCounterRid',       'BIGINT'),
                wDebitCounterRid     = T.tmp.value('@wDebitCounterRid',     'BIGINT'),
                wReqAgentCodeIn      = T.tmp.value('@wReqAgentCodeIn',      'VARCHAR(14)'),
                wDebitAgentCodeIn    = T.tmp.value('@wDebitAgentCodeIn',    'VARCHAR(14)'),
                wReqCustomerRid      = T.tmp.value('@wReqCustomerRid',      'BIGINT'),
                wDebitCustomerRid    = T.tmp.value('@wDebitCustomerRid',    'BIGINT'),
                wReqDepartment       = T.tmp.value('@wReqDepartment',       'VARCHAR(30)'),
                wReqUserRid          = T.tmp.value('@wReqUserRid',          'BIGINT'),
                wAsstBooker          = T.tmp.value('@wAsstBooker',          'NVARCHAR(50)'),
                wAssBookerTel        = T.tmp.value('@wAssBookerTel',        'VARCHAR(100)'),
                wApprovalAgentCodeIn = T.tmp.value('@wApprovalAgentCodeIn', 'VARCHAR(14)'),
                wDebitDt             = T.tmp.value('@wDebitDt',             'DATETIME2(7)'),
                wExpDt               = T.tmp.value('@wExpDt',               'DATETIME2(7)'),
                wCancelDebitDt       = T.tmp.value('@wCancelDebitDt',       'DATETIME2(7)'),
                wCancelReasonCd      = T.tmp.value('@wCancelReasonCd',      'VARCHAR(30)'),
                wCancelBy            = T.tmp.value('@wCancelBy',            'BIGINT'),
                wCancelDt            = T.tmp.value('@wCancelDt',            'DATETIME2(7)'),
                wCrtDt               = T.tmp.value('@wCrtDt',               'DATETIME2(7)'),
                wCrtBy               = T.tmp.value('@wCrtBy',               'BIGINT'),
                wUpdDt               = T.tmp.value('@wUpdDt',               'DATETIME2(7)'),
                wUpdBy               = T.tmp.value('@wUpdBy',               'BIGINT'),
                wTravePkgRid         = T.tmp.value('@wTravePkgRid',         'BIGINT'),
                wEventCodeRid        = T.tmp.value('@wEventCodeRid',        'BIGINT'),
                wAsstBookerEmail     = T.tmp.value('@wAsstBookerEmail',     'NVARCHAR(50)'),
                wDeptFollwedCd       = T.tmp.value('@wDeptFollwedCd',       'VARCHAR(30)'),
                wStaffFollwedRid     = T.tmp.value('@wStaffFollwedRid',     'BIGINT'),
                wStaffTelephone      = T.tmp.value('@wStaffTelephone',      'VARCHAR(100)'),
                wOwnerAuthTelephone  = T.tmp.value('@wOwnerAuthTelephone',  'VARCHAR(100)'),
                wOtherReason         = T.tmp.value('@wOtherReason',         'NVARCHAR(200)'),
                wDepositAmt          = T.tmp.value('@wDepositAmt',          'NUMERIC(18, 4)'),
                wGiftReasonCd        = T.tmp.value('@wGiftReasonCd',        'VARCHAR(30)'),
                wUseTravelPkg        = T.tmp.value('@wUseTravelPkg',        'CHAR(1)'),
                -- wHasDeposit          = T.tmp.value('@wHasDeposit',          'CHAR(1)'),
                wDepositDebitDt      = T.tmp.value('@wDepositDebitDt',      'DATETIME2(7)'),
                wBookingStatus       = T.tmp.value('@wBookingStatus',       'VARCHAR(10)'),
                wCoordinator         = T.tmp.value('@wCoordinator',         'NVARCHAR(50)'),
                wUser                = T.tmp.value('@wUser',                'NVARCHAR(50)'),
                wIsUser              = T.tmp.value('@wIsUser',              'CHAR(1)')
        FROM @pXML.nodes('DataSet/SetBookingResult') T(tmp);

        INSERT INTO @vHotelChange
        SELECT  RowID                   = T.tmp.value('@RowID',                 'BIGINT'),
                wRoomBookingRid         = T.tmp.value('@wRoomBookingRid',       'BIGINT'),
                wAllotmentRid           = T.tmp.value('@wAllotmentRid',         'BIGINT'),
                wAction                 = T.tmp.value('@wAction',               'VARCHAR(5)'),
                wOriStartDate           = T.tmp.value('@wOriStartDate',         'DATE'),
                wOriEndDate             = T.tmp.value('@wOriEndDate',           'DATE'),
                wNewStartDate           = T.tmp.value('@wNewStartDate',         'DATE'),
                wNewEndDate             = T.tmp.value('@wNewEndDate',           'DATE'),
                wDayOfStay              = T.tmp.value('@wDayOfStay',            'INT'),
                wVoucherNo              = T.tmp.value('@wVoucherNo',            'VARCHAR(40)'),
                wCashReceiptNo          = T.tmp.value('@wCashReceiptNo',        'NVARCHAR(40)'),
                wCashTransferReceiptNo  = T.tmp.value('@wCashTransferReceiptNo','VARCHAR(40)'),
                wUseMemeberCard         = T.tmp.value('@wUseMemeberCard',       'CHAR(1)'),
                wUseExtraAllotment      = T.tmp.value('@wUseExtraAllotment',    'CHAR(1)'),
                wUseUpAllotment         = T.tmp.value('@wUseUpAllotment',       'CHAR(1)'),
                wGetKeyMethod           = T.tmp.value('@wGetKeyMethod',         'VARCHAR(30)'),
                wReGetKey               = T.tmp.value('@wReGetKey',             'CHAR(1)'),
                wChangeCheckinPwd       = T.tmp.value('@wChangeCheckinPwd',     'CHAR(1)'),
                wCurrCode               = T.tmp.value('@wCurrCode',             'CHAR(3)'),
                wPaymentMethod          = T.tmp.value('@wPaymentMethod',        'VARCHAR(30)'),
                wRemark                 = T.tmp.value('@wRemark',               'NVARCHAR(500)'),
                wCrtDt                  = T.tmp.value('@wCrtDt',                'DATETIME2(7)'),
                wCrtBy                  = T.tmp.value('@wCrtBy',                'BIGINT'),
                wUpdDt                  = T.tmp.value('@wUpdDt',                'DATETIME2(7)'),
                wUpdBy                  = T.tmp.value('@wUpdBy',                'BIGINT'),
                wOrderNo                = T.tmp.value('@wOrderNo',              'NVARCHAR(60)'),
                wAmountChange           = T.tmp.value('@wAmountChange',         'NUMERIC(18, 4)'),
                wBookingRid             = T.tmp.value('@wBookingRid',           'BIGINT'),
                wCostChange             = T.tmp.value('@wCostChange',           'NUMERIC(18, 4)'),
                wTotalAmount            = T.tmp.value('@wTotalAmount',          'NUMERIC(18, 4)'),
                wTotalCost              = T.tmp.value('@wTotalCost',            'NUMERIC(18, 4)'),
                wDateChange             = T.tmp.value('@wDateChange',           'NVARCHAR(64)'),
                wHotelChangeNo          = T.tmp.value('@wHotelChangeNo',        'NVARCHAR(30)'),
                wHotelChangeStatus      = T.tmp.value('@wHotelChangeStatus',    'VARCHAR(10)')
        FROM @pXML.nodes('DataSet/Record') T(tmp);

        INSERT INTO @vHotelCheckIn
        SELECT  RowID                   = T.tmp.value('@RowID',                 'BIGINT'),
                wRoomBookingRid         = T.tmp.value('@wRoomBookingRid',       'BIGINT'),
                wHotelRid               = T.tmp.value('@wHotelRid',             'BIGINT'),
                wRoomRid                = T.tmp.value('@wRoomRid',              'BIGINT'),
                wAllotmentGroupRid      = T.tmp.value('@wAllotmentGroupRid',    'BIGINT'),
                wRoomNo                 = T.tmp.value('@wRoomNo',               'NVARCHAR(20)'),
                wBookingDate            = T.tmp.value('@wBookingDate',          'DATE'),
                wCurrCode               = T.tmp.value('@wCurrCode',             'CHAR(3)'),
                wPrice                  = T.tmp.value('@wPrice',                'NUMERIC(18, 4)'),
                wCost                   = T.tmp.value('@wCost',                 'NUMERIC(18, 4)'),
                wIncludeBreakfast       = T.tmp.value('@wIncludeBreakfast',     'CHAR(1)'),
                wExtraRoom              = T.tmp.value('@wExtraRoom',            'CHAR(1)'),
                wDismiss                = T.tmp.value('@wDismiss',              'CHAR(1)'),
                wExtent                 = T.tmp.value('@wExtent',               'CHAR(1)'),
                wAgencyRoom             = T.tmp.value('@wAgencyRoom',           'CHAR(1)'),
                wStatus                 = T.tmp.value('@wStatus',               'CHAR(1)'),
                wCrtDt                  = T.tmp.value('@wCrtDt',                'DATETIME2(7)'),
                wCrtBy                  = T.tmp.value('@wUpdBy',                'BIGINT'),
                wUpdDt                  = T.tmp.value('@wCrtDt',                'DATETIME2(7)'),
                wUpdBy                  = T.tmp.value('@wUpdBy',                'BIGINT'),
                wHotelChangeRid         = 0, --T.tmp.value('@wHotelChangeRid',       'BIGINT'),
                wBreakfastPrice         = T.tmp.value('@wBreakfastPrice',       'NUMERIC(18, 4)'),
                wExtraBedPrice          = T.tmp.value('@wExtraBedPrice',        'NUMERIC(18, 4)'),
                wExtraBed               = T.tmp.value('@wExtraBed',             'CHAR(1)')
        FROM @pXML.nodes('DataSet/GetHotelDailyCheckInRecordByRoombookingIdResult') T(tmp);

        BEGIN TRY
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;

            DECLARE @sBookingRoomRid BIGINT;

            SET @sBookingRoomRid = (SELECT TOP(1) wRoomBookingRid FROM @vDataSet_HotelChange);
            
            IF @pActionType = 'I' AND EXISTS (SELECT 1 FROM @vHotelChange WHERE wHotelChangeStatus = 'P')
            BEGIN
                IF EXISTS (SELECT 1 FROM dbo.eHotelChange WHERE wRoomBookingRid = @sBookingRoomRid AND wHotelChangeStatus = 'P')
                BEGIN
                    SET @pErrCode = 50002;

                    THROW @pErrCode, N'有更改入住記錄等待回覆中', 1;
                END
                
                -- dbo.eBooking
                ------------------------------------------------------------------------------------
                SET @sRuningIndex = 1;
                SET @sRecordCount = (SELECT COUNT(1) FROM @vBooking);

                WHILE @sRuningIndex <= @sRecordCount
                BEGIN
                    EXEC spq.GetRowId @pMainCompNo, 'eBooking', @sRowID OUTPUT;
						
                    UPDATE @vBooking SET RowID = @sRowID WHERE RowNum = @sRuningIndex;

                    SET @sRuningIndex = @sRuningIndex + 1;
                END

                INSERT INTO dbo.eBooking(
                    RowID,
                    wBookingType,
                    wRefNo,
                    [GUID],
                    wReqCounterRid,
                    wDebitCounterRid,
                    wReqAgentCodeIn,
                    wDebitAgentCodeIn,
                    wReqCustomerRid,
                    wDebitCustomerRid,
                    wReqDepartment,
                    wReqUserRid,
                    wAsstBooker,
                    wAssBookerTel,
                    wApprovalAgentCodeIn,
                    wDebitDt,
                    wExpDt,
                    wCancelDebitDt,
                    wCancelReasonCd,
                    wCancelBy,
                    wCancelDt,
                    wCrtDt,
                    wCrtBy,
                    wUpdDt,
                    wUpdBy,
                    wTravePkgRid,
                    wEventCodeRid,
                    wAsstBookerEmail,
                    wDeptFollwedCd,
                    wStaffFollwedRid,
                    wStaffTelephone,
                    wOwnerAuthTelephone,
                    wOtherReason,
                    wDepositAmt,
                    wGiftReasonCd,
                    wUseTravelPkg,
                    wHasDeposit,
                    wDepositDebitDt,
                    wBookingStatus,
                    wCoordinator,
                    wUser,
                    wIsUser
                )
                SELECT  RowID,
                        wBookingType,
                        wRefNo,
                        NEWID(),
                        wReqCounterRid,
                        wDebitCounterRid,
                        wReqAgentCodeIn,
                        wDebitAgentCodeIn,
                        wReqCustomerRid,
                        wDebitCustomerRid,
                        wReqDepartment,
                        wReqUserRid,
                        wAsstBooker,
                        wAssBookerTel,
                        wApprovalAgentCodeIn,
                        wDebitDt,
                        wExpDt,
                        wCancelDebitDt,
                        wCancelReasonCd,
                        wCancelBy,
                        wCancelDt,
                        wCrtDt,
                        wCrtBy,
                        wUpdDt,
                        wUpdBy,
                        wTravePkgRid,
                        wEventCodeRid,
                        wAsstBookerEmail,
                        wDeptFollwedCd,
                        wStaffFollwedRid,
                        wStaffTelephone,
                        wOwnerAuthTelephone,
                        wOtherReason,
                        wDepositAmt,
                        wGiftReasonCd,
                        wUseTravelPkg,
                        wHasDeposit = CASE WHEN ISNULL(wDepositAmt, 0) != 0 THEN 'Y' ELSE 'N' END, -- INSERT，按金不等於0， wHasDeposit = 'Y' ELSE 'N'
                        wDepositDebitDt,
                        wBookingStatus,
                        wCoordinator,
                        wUser,
                        wIsUser
                FROM @vBooking;
                ------------------------------------------------------------------------------------

                -- dbo.eHotelChange
                ------------------------------------------------------------------------------------
                SET @sRuningIndex = 1;
                SET @sRecordCount = (SELECT COUNT(1) FROM @vHotelChange);
                SET @pBookingRid = (SELECT TOP(1) RowID FROM @vBooking);

                IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqeHotelChangeNo') AND type = 'SO')
                    CREATE SEQUENCE seqeHotelChangeNo START WITH 100000000000 INCREMENT BY 1 MAXVALUE 99999999999999	

                WHILE @sRuningIndex <= @sRecordCount
                BEGIN
                    EXEC spq.GetRowId @pMainCompNo, 'eHotelChange', @sRowID OUTPUT;
						
                    UPDATE @vHotelChange 
                    SET RowID = @sRowID, 
                        wBookingRid = @pBookingRid,
                        wHotelChangeNo = NEXT VALUE FOR dbo.seqeHotelChangeNo
                    WHERE RowNum = @sRuningIndex;

                    SET @sRuningIndex = @sRuningIndex + 1;
                END

                INSERT INTO dbo.eHotelChange (
                    RowID,
                    wRoomBookingRid,
                    wAllotmentRid,
                    wAction,
                    wOriStartDate,
                    wOriEndDate,
                    wNewStartDate,
                    wNewEndDate,
                    wDayOfStay,
                    wVoucherNo,
                    wCashReceiptNo,
                    wCashTransferReceiptNo,
                    wUseMemeberCard,
                    wUseExtraAllotment,
                    wUseUpAllotment,
                    wGetKeyMethod,
                    wReGetKey,
                    wChangeCheckinPwd,
                    wCurrCode,
                    wPaymentMethod,
                    wRemark,
                    wCrtDt,
                    wCrtBy,
                    wUpdDt,
                    wUpdBy,
                    wOrderNo,
                    wAmountChange,
                    wBookingRid,
                    wCostChange,
                    wTotalAmount,
                    wTotalCost,
                    wDateChange,
                    wHotelChangeNo,
                    wHotelChangeStatus
                )
                SELECT  RowID,
                        wRoomBookingRid,
                        wAllotmentRid,
                        wAction,
                        wOriStartDate,
                        wOriEndDate,
                        wNewStartDate,
                        wNewEndDate,
                        wDayOfStay,
                        wVoucherNo,
                        wCashReceiptNo,
                        wCashTransferReceiptNo,
                        wUseMemeberCard,
                        wUseExtraAllotment,
                        wUseUpAllotment,
                        wGetKeyMethod,
                        wReGetKey,
                        wChangeCheckinPwd,
                        wCurrCode,
                        wPaymentMethod,
                        wRemark,
                        wCrtDt,
                        wCrtBy,
                        wUpdDt,
                        wUpdBy,
                        wOrderNo,
                        wAmountChange,
                        wBookingRid,
                        wCostChange,
                        wTotalAmount,
                        wTotalCost,
                        wDateChange,
                        wHotelChangeNo,
                        wHotelChangeStatus
                FROM @vHotelChange;

                ------------------------------------------------------------------------------------

                -- dbo.eHotelCheckIn的wStatus = 'T'，否則會影響到dbo.eBookingRoom的入住記錄（在SunTrip確認前，不應該影響）
                ------------------------------------------------------------------------------------
                SET @sRuningIndex = 1;
                SET @sRecordCount = (SELECT COUNT(1) FROM @vHotelCheckIn);
                SET @pHotelChangeRid = (SELECT TOP(1) RowID FROM @vHotelChange);
                
                WHILE @sRuningIndex <= @sRecordCount
                BEGIN
                    EXEC spq.GetRowId @pMainCompNo, 'eHotelCheckIn', @sRowID OUTPUT;
						
                    UPDATE @vHotelCheckIn 
                    SET RowID = @sRowID, 
                        wRoomBookingRid = @sBookingRoomRid,
                        wHotelChangeRid = @pHotelChangeRid, 
                        wStatus = 'T' 
                    WHERE RowNum = @sRuningIndex;

                    SET @sRuningIndex = @sRuningIndex + 1;
                END

                INSERT INTO dbo.eHotelCheckIn (
                    RowID,
                    wRoomBookingRid,
                    wHotelRid,
                    wRoomRid,
                    wAllotmentGroupRid,
                    wRoomNo,
                    wBookingDate,
                    wCurrCode,
                    wPrice,
                    wCost,
                    wIncludeBreakfast,
                    wExtraRoom,
                    wDismiss,
                    wExtent,
                    wAgencyRoom,
                    wStatus,
                    wCrtDt,
                    wCrtBy,
                    wUpdDt,
                    wUpdBy,
                    wHotelChangeRid,
                    wBreakfastPrice,
                    wExtraBedPrice,
                    wExtraBed
                )
                SELECT  RowID,
                        wRoomBookingRid,
                        wHotelRid,
                        wRoomRid,
                        wAllotmentGroupRid,
                        wRoomNo,
                        wBookingDate,
                        wCurrCode,
                        wPrice,
                        wCost,
                        wIncludeBreakfast,
                        wExtraRoom,
                        wDismiss,
                        wExtent,
                        wAgencyRoom,
                        wStatus,
                        wCrtDt,
                        wCrtBy,
                        wUpdDt,
                        wUpdBy,
                        wHotelChangeRid,
                        wBreakfastPrice,
                        wExtraBedPrice,
                        wExtraBed
                FROM @vHotelCheckIn;
                ------------------------------------------------------------------------------------
            END

            -- 不更新dbo.eHotelCheckIn
            IF @pActionType = 'U'
            BEGIN
                SELECT TOP(1) @sOldHotelChangeStatus = hc.wHotelChangeStatus,
                              @sNewHotelChangeStatus = tmp.wHotelChangeStatus
                FROM @vHotelChange tmp
                INNER JOIN dbo.eHotelChange hc ON hc.RowID = tmp.RowID;

                SET @pBookingRid = (SELECT TOP(1) RowID FROM @vBooking);
                SET @pHotelChangeRid = (SELECT TOP(1) RowID FROM @vHotelChange);

                IF @sOldHotelChangeStatus IN ('P', 'CL1', 'CL2')
                BEGIN
                    -- dbo.eBooking
                    UPDATE eb
                    SET -- RowID = tmp.RowID,
                        -- wBookingType = tmp.wBookingType,
                        -- wRefNo = tmp.wRefNo,
                        [GUID] = NEWID(),
                        wReqCounterRid = tmp.wReqCounterRid,
                        wDebitCounterRid = tmp.wDebitCounterRid,
                        wReqAgentCodeIn = tmp.wReqAgentCodeIn,
                        wDebitAgentCodeIn = tmp.wDebitAgentCodeIn,
                        wReqCustomerRid = tmp.wReqCustomerRid,
                        wDebitCustomerRid = tmp.wDebitCustomerRid,
                        wReqDepartment = tmp.wReqDepartment,
                        wReqUserRid = tmp.wReqUserRid,
                        wAsstBooker = tmp.wAsstBooker,
                        wAssBookerTel = tmp.wAssBookerTel,
                        wApprovalAgentCodeIn = tmp.wApprovalAgentCodeIn,
                        wDebitDt = tmp.wDebitDt,
                        wExpDt = tmp.wExpDt,
                        wCancelDebitDt = tmp.wCancelDebitDt,
                        wCancelReasonCd = tmp.wCancelReasonCd,
                        wCancelBy = tmp.wCancelBy,
                        wCancelDt = tmp.wCancelDt,
                        wCrtDt = tmp.wCrtDt,
                        wCrtBy = tmp.wCrtBy,
                        wUpdDt = tmp.wUpdDt,
                        wUpdBy = tmp.wUpdBy,
                        wTravePkgRid = tmp.wTravePkgRid,
                        wEventCodeRid = tmp.wEventCodeRid,
                        wAsstBookerEmail = tmp.wAsstBookerEmail,
                        wDeptFollwedCd = tmp.wDeptFollwedCd,
                        wStaffFollwedRid = tmp.wStaffFollwedRid,
                        wStaffTelephone = tmp.wStaffTelephone,
                        wOwnerAuthTelephone = tmp.wOwnerAuthTelephone,
                        wOtherReason = tmp.wOtherReason,
                        wDepositAmt = tmp.wDepositAmt,
                        wGiftReasonCd = tmp.wGiftReasonCd,
                        wUseTravelPkg = tmp.wUseTravelPkg,
                        wHasDeposit = CASE WHEN eb.wHasDeposit = 'Y' OR ISNULL(tmp.wDepositAmt, 0) != 0 THEN 'Y' ELSE 'N' END, -- UPDATE，按金不等於0 OR wHasDeposit = 'Y'， wHasDeposit = 'Y' ELSE 'N'（如果已經Set過按金的，就不能再Set回N）
                        wDepositDebitDt = tmp.wDepositDebitDt,
                        wBookingStatus = tmp.wBookingStatus,
                        wCoordinator = tmp.wCoordinator,
                        wUser = tmp.wUser,
                        wIsUser = tmp.wIsUser
                    FROM dbo.eBooking eb
                    INNER JOIN @vBooking tmp ON tmp.RowID = eb.RowID

                    -- dbo.eHotelChange
                    UPDATE hc
                    SET -- RowID = tmp.RowID,
                        -- wRoomBookingRid = tmp.wRoomBookingRid,
                        wAllotmentRid = tmp.wAllotmentRid,
                        wAction = tmp.wAction,
                        wOriStartDate = tmp.wOriStartDate,
                        wOriEndDate = tmp.wOriEndDate,
                        wNewStartDate = tmp.wNewStartDate,
                        wNewEndDate = tmp.wNewEndDate,
                        wDayOfStay = tmp.wDayOfStay,
                        wVoucherNo = tmp.wVoucherNo,
                        wCashReceiptNo = tmp.wCashReceiptNo,
                        wCashTransferReceiptNo = tmp.wCashTransferReceiptNo,
                        wUseMemeberCard = tmp.wUseMemeberCard,
                        wUseExtraAllotment = tmp.wUseExtraAllotment,
                        wUseUpAllotment = tmp.wUseUpAllotment,
                        wGetKeyMethod = tmp.wGetKeyMethod,
                        wReGetKey = tmp.wReGetKey,
                        wChangeCheckinPwd = tmp.wChangeCheckinPwd,
                        wCurrCode = tmp.wCurrCode,
                        wPaymentMethod = tmp.wPaymentMethod,
                        wRemark = tmp.wRemark,
                        wCrtDt = tmp.wCrtDt,
                        wCrtBy = tmp.wCrtBy,
                        wUpdDt = tmp.wUpdDt,
                        wUpdBy = tmp.wUpdBy,
                        wOrderNo = tmp.wOrderNo,
                        wAmountChange = tmp.wAmountChange,
                        -- wBookingRid = tmp.wBookingRid,
                        wCostChange = tmp.wCostChange,
                        wTotalAmount = tmp.wTotalAmount,
                        wTotalCost = tmp.wTotalCost,
                        wDateChange = tmp.wDateChange,
                        -- wHotelChangeNo = tmp.wHotelChangeNo,
                        wHotelChangeStatus = IIF(hc.wHotelChangeStatus = 'P', tmp.wHotelChangeStatus, hc.wHotelChangeStatus)
                    FROM dbo.eHotelChange hc
                    INNER JOIN @vHotelChange tmp ON tmp.RowID = hc.RowID;
                END
            END

            -- SunTrip: Hold住房額
            IF @pActionType = 'I'
            BEGIN
                UPDATE ahd
                SET wOnHoldQty = IIF (hci.wExtraRoom = 'Y', wOnHoldQty, wOnHoldQty + 1), -- 如果不是使用額外房，Hold住房額數量加1
                    wUpdBy = hci.wUpdBy,
                    wUpdDt = @sNow
                FROM dbo.eAllotmentHotelDaily ahd
                INNER JOIN dbo.eHotelCheckIn hci ON ahd.wDate = hci.wBookingDate AND ahd.wRoomRid = hci.wRoomRid AND ahd.wAllotmentGroupRid = hci.wAllotmentGroupRid
                INNER JOIN @vHotelChange hc ON hc.RowID = hci.wHotelChangeRid
                WHERE hci.wDismiss <> 'Y'
                    AND hc.wHotelChangeStatus = 'P'
                    AND ahd.wDate NOT BETWEEN hc.wOriStartDate AND hc.wOriEndDate;
            END

            -- SunTrip確認交易： T掉待覆更新入住日期、退回Hold住嘅房額
            IF @pActionType = 'U' AND @sOldHotelChangeStatus = 'P' AND @sNewHotelChangeStatus IN ('C', 'CL1', 'CL2')
            BEGIN
                UPDATE ahd
                SET wOnHoldQty = IIF (hci.wExtraRoom = 'Y', wOnHoldQty, IIF(wOnHoldQty - 1 < 0, 0, wOnHoldQty - 1)), -- 如果不是使用額外房，Hold住房額數量減1
                    wUpdBy = hci.wUpdBy,
                    wUpdDt = @sNow
                FROM dbo.eAllotmentHotelDaily ahd
                INNER JOIN dbo.eHotelCheckIn hci ON ahd.wDate = hci.wBookingDate AND ahd.wRoomRid = hci.wRoomRid AND ahd.wAllotmentGroupRid = hci.wAllotmentGroupRid
                INNER JOIN @vHotelChange hc ON hc.RowID = hci.wHotelChangeRid
                WHERE hci.wDismiss <> 'Y'
                    AND ahd.wDate NOT BETWEEN hc.wOriStartDate AND hc.wOriEndDate;

                -- 刪除舊記錄
                IF @sNewHotelChangeStatus = 'C'
                BEGIN
                    DELETE hc FROM dbo.eHotelChange hc INNER JOIN @vHotelChange tmp ON tmp.RowID = hc.RowID;
                    -- DELETE hci FROM dbo.eHotelCheckIn hci INNER JOIN @vHotelChange tmp ON tmp.RowID = hci.wHotelChangeRid;
                END
            END

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
			
            SET @pErrMsg = @sCatchErrorMessage;
			
            IF @sBeginTranCount = 0
            BEGIN
                IF @xstate = 1 OR @xstate = -1
                    ROLLBACK;

                EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
            END
            ELSE 
                THROW;
        END CATCH;
    END