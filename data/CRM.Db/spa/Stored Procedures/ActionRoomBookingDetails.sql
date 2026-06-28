CREATE PROCEDURE [spa].[ActionRoomBookingDetails]
    @pXMLBooking            XML = NULL ,
    @pXMLRoomBookingDetail  XML = NULL ,
    @pXMLPassengerDetail    XML = NULL ,
    @pXMLPassengerTravelDoc XML = NULL ,
    @pXMLHotelCheckIn       XML = NULL ,
    @pActionType            CHAR(1) ,
    @pMainCompNo            INT ,
    @pNonceToken            VARCHAR(64) ,
    @pRoomBookingDetailRid  BIGINT = 0 ,
    @pBookingRid            BIGINT = 0 OUTPUT ,
    @pBookingRoomRid        BIGINT = 0 OUTPUT ,
    @pSeqNo                 INT    = 0 OUTPUT ,
    @pErrCode               INT    = 0 OUTPUT ,
    @pErrMsg                NVARCHAR(200) = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- SELECT COUNT(*) AS wRecordCount  FROM eBookingRoom

    DECLARE @sBeginTranCount    INT = 0 ,
            @sUseAgencyAlloment CHAR(1), -- 使用外館房
            @sUseExtraAllotment CHAR(1), -- 使用額外房
            @sOldBookingStatus  VARCHAR(5),
            @sNewBookingStatus  VARCHAR(5), 
            @sHasAlloment       INT = 0, ---是否有房額： 大於 0 就代表有 alloment
            @sXMLHotelCheckIn   XML;

    SET	@pErrCode = 0 ;
    SET @pErrMsg = '';
    SET @sBeginTranCount = @@trancount;

    BEGIN TRY
        -- Try to make the transaction scope as small as possible to reduce locking
        DECLARE @vBooking TABLE( RowID BIGINT, wDebitCounterRid BIGINT);

        INSERT INTO @vBooking
        SELECT  RowID = T.tmp.value('@RowID', 'BIGINT'),
                wDebitCounterRid = T.tmp.value('@wDebitCounterRid', 'BIGINT')
        FROM @pXMLBooking.nodes('/DataSet/SetBookingResult') T(tmp);

        ---------------------------------------------------------

        DECLARE	@vBookingRoom TABLE (
            RowID BIGINT NULL ,
            wHotelBookingRid BIGINT NULL ,
            wRequestRid BIGINT NULL ,
            wHotelRid BIGINT NULL ,
            wHotelRoomRid BIGINT NULL ,
            wCounterRid BIGINT NULL ,
            wTravelAgencyRid BIGINT NULL ,
            wOrderNo NVARCHAR(60) NULL ,
            wBedType VARCHAR(30) NULL ,
            wStartDate DATE NULL ,
            wEndtDate DATE NULL ,
            wDayOfStay INT NULL ,
            wPaymentMethod VARCHAR(30) NULL ,
            wReceiptNo NVARCHAR(50) NULL ,
            wVoucherNo VARCHAR(40) NULL ,
            wConfirmationNo NVARCHAR(40) NULL ,
            wCashReceiptNo NVARCHAR(40) NULL ,
            wCashTransferReceiptNo VARCHAR(40) NULL ,
            wGetKeyMethod VARCHAR(30) NULL ,
            wCurrCode CHAR(3) NULL ,
            wUseMemberCard CHAR(1) NULL DEFAULT ( 'N' ) ,
            wIncludeBreakfast CHAR(1) NULL DEFAULT ( 'N' ) ,
            wUseExtraAllotment CHAR(1) NULL DEFAULT ( 'N' ) ,
            wUseUpAllotment CHAR(1) NULL DEFAULT ( 'N' ) ,
            wTotalAmount DECIMAL(18, 4) NULL DEFAULT ( (0) ) ,
            wAdditionalFee DECIMAL(18, 4) NULL DEFAULT ( (0) ) ,
            wActualTotalAmount DECIMAL(18, 4) NULL ,
            wTotalCost DECIMAL(18, 4) NULL ,
            wRoomNo NVARCHAR(20) NULL DEFAULT ( '' ) ,
            wGetKeyPasscode VARCHAR(10) NULL DEFAULT ( '' ) ,
            wHasStaffGetKey CHAR(1) NULL DEFAULT ( 'N' ) ,
            wHasClientGetKey CHAR(1) NULL DEFAULT ( 'N' ) ,
            wReGetKeyDate DATE NULL ,
            wSmsCount INT NULL ,
            wIsConsigned CHAR(1) NULL DEFAULT ( 'N' ) ,
            wSameFloor CHAR(1) NULL DEFAULT ( 'N' ) ,
            wRoomExpenseState VARCHAR(30) NULL ,
            wCallCustomer CHAR(1) NULL DEFAULT ( 'N' ) ,
            wQuickCollectKey CHAR(1) NULL DEFAULT ( 'N' ) ,
            wIsCleaning CHAR(1) NULL DEFAULT ( 'N' ) ,
            wWarmReminderSMS CHAR(1) NULL DEFAULT ( 'N' ) ,
            wNoteRemark CHAR(1) NULL DEFAULT ( 'N' ) ,
            wIsConnectedRoom CHAR(1) NULL DEFAULT ( 'N' ) ,
            wRemark NVARCHAR(500) NULL DEFAULT ( '' ) ,
            wCrtDt DATETIME2 NULL ,
            wCrtBy BIGINT NULL ,
            wUpdDt DATETIME2 NULL ,
            wUpdBy BIGINT NULL ,
            wAllotmentGroupRid BIGINT NULL ,
            wRoomSMSSent CHAR(1) NULL DEFAULT ( 'N' ) ,
            wDisplayAgencyHotel CHAR(1) NULL DEFAULT ( 'N' ) ,
            wUseAgencyAllotment CHAR(1) NULL DEFAULT ( 'N' ) ,
            wStatus CHAR(1) NULL DEFAULT ( 'A' ) ,
            wSeqNo INT NULL DEFAULT ( (1) ) ,
            wBookingStatus VARCHAR(5) NULL DEFAULT ( 'P' ) ,
            wUnqualifiedRid BIGINT NULL DEFAULT ( (0) ) ,
            wBookingRid BIGINT NULL DEFAULT ( (0) ) ,
            wCheckoutRemarks NVARCHAR(500) NULL,
            wIsSmoke CHAR(1) NULL DEFAULT ( 'N' ) ,
            wIsExtraBed CHAR(1) NULL DEFAULT ( 'N' )
        );
    
        INSERT INTO @vBookingRoom ( 
            RowID ,
            wHotelBookingRid ,
            wRequestRid ,
            wHotelRid ,
            wHotelRoomRid ,
            wCounterRid ,
            wTravelAgencyRid ,
            wOrderNo ,
            wBedType ,
            wStartDate ,
            wEndtDate ,
            wDayOfStay ,
            wPaymentMethod ,
            wReceiptNo ,
            wVoucherNo ,
            wConfirmationNo ,
            wCashReceiptNo ,
            wCashTransferReceiptNo ,
            wGetKeyMethod ,
            wCurrCode ,
            wUseMemberCard ,
            wIncludeBreakfast ,
            wUseExtraAllotment ,
            wUseUpAllotment ,
            wTotalAmount ,
            wAdditionalFee ,
            wActualTotalAmount ,
            wTotalCost ,
            wRoomNo ,
            wGetKeyPasscode ,
            wHasStaffGetKey ,
            wHasClientGetKey ,
            wReGetKeyDate ,
            wSmsCount ,
            wIsConsigned ,
            wSameFloor ,
            wRoomExpenseState ,
            wCallCustomer ,
            wQuickCollectKey ,
            wIsCleaning ,
            wWarmReminderSMS ,
            wNoteRemark ,
            wIsConnectedRoom ,
            wIsSmoke,
            wIsExtraBed,
            wRemark ,
            wCrtDt ,
            wCrtBy ,
            wUpdDt ,
            wUpdBy ,
            wAllotmentGroupRid ,
            wRoomSMSSent ,
            wDisplayAgencyHotel ,
            wUseAgencyAllotment ,
            wStatus ,
            wSeqNo ,
            wBookingStatus ,
            wUnqualifiedRid ,
            wBookingRid ,
            wCheckoutRemarks
        )
        SELECT  T.tmp.value('@RowID[1]', 'bigint') AS RowID,
                T.tmp.value('@wHotelBookingRid[1]', 'bigint') AS wHotelBookingRid,
                T.tmp.value('@wRequestRid[1]', 'bigint') AS wRequestRid,
                T.tmp.value('@wHotelRid[1]', 'bigint') AS wHotelRid,
                T.tmp.value('@wHotelRoomRid[1]', 'bigint') AS wHotelRoomRid,
                T.tmp.value('@wCounterRid[1]', 'bigint') AS wCounterRid,
                T.tmp.value('@wTravelAgencyRid[1]', 'bigint') AS wTravelAgencyRid,
                T.tmp.value('@wOrderNo[1]', 'nvarchar(60)') AS wOrderNo,
                T.tmp.value('@wBedType[1]', 'varchar(30)') AS wBedType,
                T.tmp.value('@wStartDate[1]', 'date') AS wStartDate,
                T.tmp.value('@wEndtDate[1]', 'date') AS wEndtDate,
                T.tmp.value('@wDayOfStay[1]', 'int') AS wDayOfStay,
                T.tmp.value('@wPaymentMethod[1]', 'varchar(30)') AS wPaymentMethod,
                T.tmp.value('@wReceiptNo[1]', 'nvarchar(50)') AS wReceiptNo,
                T.tmp.value('@wVoucherNo[1]', 'varchar(40)') AS wVoucherNo,
                T.tmp.value('@wConfirmationNo[1]', 'nvarchar(40)') AS wConfirmationNo,
                T.tmp.value('@wCashReceiptNo[1]', 'nvarchar(40)') AS wCashReceiptNo,
                T.tmp.value('@wCashTransferReceiptNo[1]', 'varchar(40)') AS wCashTransferReceiptNo,
                T.tmp.value('@wGetKeyMethod[1]', 'varchar(30)') AS wGetKeyMethod,
                T.tmp.value('@wCurrCode[1]', 'char(3)') AS wCurrCode,
                T.tmp.value('@wUseMemberCard[1]', 'char(1)') AS wUseMemberCard,
                T.tmp.value('@wIncludeBreakfast[1]', 'char(1)') AS wIncludeBreakfast,
                T.tmp.value('@wUseExtraAllotment[1]', 'char(1)') AS wUseExtraAllotment,
                T.tmp.value('@wUseUpAllotment[1]', 'char(1)') AS wUseUpAllotment,
                T.tmp.value('@wTotalAmount[1]', 'decimal(18,4)') AS wTotalAmount,
                T.tmp.value('@wAdditionalFee[1]', 'decimal(18,4)') AS wAdditionalFee,
                T.tmp.value('@wActualTotalAmount[1]', 'decimal(18,4)') AS wActualTotalAmount,
                T.tmp.value('@wTotalCost[1]', 'decimal(18,4)') AS wTotalCost,
                T.tmp.value('@wRoomNo[1]', 'nvarchar(20)') AS wRoomNo,
                T.tmp.value('@wGetKeyPasscode[1]', 'varchar(10)') AS wGetKeyPasscode,
                T.tmp.value('@wHasStaffGetKey[1]', 'char(1)') AS wHasStaffGetKey,
                T.tmp.value('@wHasClientGetKey[1]', 'char(1)') AS wHasClientGetKey,
                T.tmp.value('@wReGetKeyDate[1]', 'date') AS wReGetKeyDate,
                T.tmp.value('@wSmsCount[1]', 'int') AS wSmsCount,
                T.tmp.value('@wIsConsigned[1]', 'char(1)') AS wIsConsigned,
                T.tmp.value('@wSameFloor[1]', 'char(1)') AS wSameFloor,
                T.tmp.value('@wRoomExpenseState[1]', 'varchar(30)') AS wRoomExpenseState,
                T.tmp.value('@wCallCustomer[1]', 'char(1)') AS wCallCustomer,
                T.tmp.value('@wQuickCollectKey[1]', 'char(1)') AS wQuickCollectKey,
                T.tmp.value('@wIsCleaning[1]', 'char(1)') AS wIsCleaning,
                T.tmp.value('@wWarmReminderSMS[1]', 'char(1)') AS wWarmReminderSMS,
                T.tmp.value('@wNoteRemark[1]', 'char(1)') AS wNoteRemark,
                T.tmp.value('@wIsConnectedRoom[1]', 'char(1)') AS wIsConnectedRoom,
                T.tmp.value('@wIsSmoke[1]', 'char(1)') AS wIsSmoke,
                T.tmp.value('@wIsExtraBed[1]', 'char(1)') AS wIsExtraBed,
                T.tmp.value('@wRemark[1]', 'nvarchar(500)') AS wRemark,
                T.tmp.value('@wCrtDt[1]', 'datetime2') AS wCrtDt,
                T.tmp.value('@wCrtBy[1]', 'bigint') AS wCrtBy,
                T.tmp.value('@wUpdDt[1]', 'datetime2') AS wUpdDt,
                T.tmp.value('@wUpdBy[1]', 'bigint') AS wUpdBy,
                T.tmp.value('@wAllotmentGroupRid[1]', 'bigint') AS wAllotmentGroupRid,
                T.tmp.value('@wRoomSMSSent[1]', 'char(1)') AS wRoomSMSSent,
                T.tmp.value('@wDisplayAgencyHotel[1]', 'char(1)') AS wDisplayAgencyHotel,
                T.tmp.value('@wUseAgencyAllotment[1]', 'char(1)') AS wUseAgencyAllotment,
                T.tmp.value('@wStatus[1]', 'char(1)') AS wStatus,
                T.tmp.value('@wSeqNo[1]', 'int') AS wSeqNo,
                T.tmp.value('@wBookingStatus[1]', 'varchar(5)') AS wBookingStatus,
                T.tmp.value('@wUnqualifiedRid[1]', 'bigint') AS wUnqualifiedRid,
                T.tmp.value('@wBookingRid[1]', 'bigint') AS wBookingRid,
                T.tmp.value('@wCheckoutRemarks[1]', 'nvarchar(500)') AS wCheckoutRemarks
        FROM @pXMLRoomBookingDetail.nodes('/DataSet/Record') T(tmp);
        ---------------------------------------------------------

        DECLARE	@vHotelCheckIn TABLE (
            RowID BIGINT NULL ,
            wRoomBookingRid BIGINT NULL ,
            wHotelRid BIGINT NULL ,
            wRoomRid BIGINT NULL ,
            wAllotmentGroupRid BIGINT NULL ,
            wRoomNo NVARCHAR(20) NULL ,
            wBookingDate DATE NULL ,
            wCurrCode CHAR(3) NULL ,
            wPrice DECIMAL(18, 4) NULL DEFAULT ( (0) ) ,
            wCost DECIMAL(18, 4) NULL DEFAULT ( (0) ) ,
            wBreakfastPrice NUMERIC(18, 4) NOT NULL,
            wExtraBedPrice NUMERIC(18, 4) NOT NULL,
            wIncludeBreakfast CHAR(1) NULL DEFAULT ( 'N' ) ,
            wExtraRoom CHAR(1) NULL DEFAULT ( 'N' ) ,
            wDismiss CHAR(1) NULL DEFAULT ( 'N' ) ,
            wExtent CHAR(1) NULL DEFAULT ( 'N' ) ,
            wAgencyRoom CHAR(1) NULL DEFAULT ( 'N' ) ,
            wStatus CHAR(1) NULL DEFAULT ( 'A' ) ,
            wBookingStatus VARCHAR(5) NULL DEFAULT ( 'P' ) ,
            wCrtDt DATETIME2 NULL ,
            wCrtBy BIGINT NULL ,
            wUpdDt DATETIME2 NULL ,
            wUpdBy BIGINT NULL
        );
    
        INSERT INTO @vHotelCheckIn ( 
            RowID ,
            wRoomBookingRid ,
            wHotelRid ,
            wRoomRid ,
            wAllotmentGroupRid ,
            wRoomNo ,
            wBookingDate ,
            wCurrCode ,
            wPrice ,
            wCost ,
            wBreakfastPrice,
            wExtraBedPrice,
            wIncludeBreakfast ,
            wExtraRoom ,
            wDismiss ,
            wExtent ,
            wAgencyRoom ,
            wStatus ,
            wCrtDt ,
            wCrtBy ,
            wUpdDt ,
            wUpdBy
        )
        SELECT	T.tmp.value('@RowID[1]', 'bigint') AS RowID,
                T.tmp.value('@wRoomBookingRid[1]', 'bigint') AS wRoomBookingRid,
                T.tmp.value('@wHotelRid[1]', 'bigint') AS wHotelRid,
                T.tmp.value('@wRoomRid[1]', 'bigint') AS wRoomRid,
                T.tmp.value('@wAllotmentGroupRid[1]', 'bigint') AS wAllotmentGroupRid,
                T.tmp.value('@wRoomNo[1]', 'nvarchar(20)') AS wRoomNo,
                T.tmp.value('@wBookingDate[1]', 'date') AS wBookingDate,
                T.tmp.value('@wCurrCode[1]', 'char(3)') AS wCurrCode,
                T.tmp.value('@wPrice[1]', 'decimal(18,4)') AS wPrice,
                T.tmp.value('@wCost[1]', 'decimal(18,4)') AS wCost,
                T.tmp.value('@wBreakfastPrice[1]', 'decimal(18,4)') AS wBreakfastPrice,
                T.tmp.value('@wExtraBedPrice[1]', 'decimal(18,4)') AS wExtraBedPrice,
                T.tmp.value('@wIncludeBreakfast[1]', 'char(1)') AS wIncludeBreakfast,
                T.tmp.value('@wExtraRoom[1]', 'char(1)') AS wExtraRoom,
                T.tmp.value('@wDismiss[1]', 'char(1)') AS wDismiss,
                T.tmp.value('@wExtent[1]', 'char(1)') AS wExtent,
                T.tmp.value('@wAgencyRoom[1]', 'char(1)') AS wAgencyRoom,
                T.tmp.value('@wStatus[1]', 'char(1)') AS wStatus,
                T.tmp.value('@wCrtDt[1]', 'datetime2') AS wCrtDt,
                T.tmp.value('@wCrtBy[1]', 'bigint') AS wCrtBy,
                T.tmp.value('@wUpdDt[1]', 'datetime2') AS wUpdDt,
                T.tmp.value('@wUpdBy[1]', 'bigint') AS wUpdBy
        FROM @pXMLHotelCheckIn.nodes('/DataSet/GetHotelDailyCheckInRecordByRoombookingIdResult') T(tmp);
        ---------------------------------------------------------

         -- Old Value
        SELECT @sOldBookingStatus = wBookingStatus 
        FROM dbo.eBookingRoom 
        WHERE RowID = @pRoomBookingDetailRid;
        -- New Value
        SELECT @sNewBookingStatus = wBookingStatus, 
               @sUseAgencyAlloment = wUseAgencyAllotment, 
               @sUseExtraAllotment = wUseExtraAllotment 
        FROM @vBookingRoom 
        WHERE RowID = @pRoomBookingDetailRid;
        
        -- 由P --> C，CL，UQ，RF，按金必須為0，退按金（房間完成后依然可以設按金，P->C不可以設置按金，如果要設，必須完成單后，再設；如果確認消費時有輸入按金，自動變0）
        SET @sOldBookingStatus = ISNULL(@sOldBookingStatus, '');
        SET @sNewBookingStatus = ISNULL(@sNewBookingStatus, '');
        IF(@pXMLBooking IS NOT NULL AND ((@sOldBookingStatus = 'P' AND @sNewBookingStatus = 'C') OR @sNewBookingStatus IN ('CL', 'UQ', 'RF', 'CO')))
            SET @pXMLBooking.modify('replace value of(/DataSet[1]/SetBookingResult[1]/@wDepositAmt) with ("0")')
        ---------------------------------------------------------

        -- P状态下不Check房额
        IF @sNewBookingStatus NOT IN ('P', 'CL', 'UQ', 'RF')
        BEGIN
            SELECT @sHasAlloment = COUNT(1) 
            FROM @vBookingRoom AS t 
            INNER JOIN @vBooking AS eb ON t.wBookingRid=eb.RowID
            INNER JOIN dbo.eAllotmentHotel AS ah ON t.wHotelRid = ah.wHotelRid AND t.wHotelRoomRid = ah.wRoomRid
            INNER JOIN dbo.eAllotmentHotelDtl AS ahd ON ah.RowID = ahd.wAllotmentHotelRid
            INNER JOIN dbo.mAllotmentGroupDtl AS agd ON ahd.wAllotmentGroupRid = agd.wAllotmentGroupRid AND agd.wCounterRid = eb.wDebitCounterRid
            WHERE t.wUseAgencyAllotment = 'N' AND t.RowID = @pRoomBookingDetailRid;
            
            IF @sUseAgencyAlloment = 'N' AND @sHasAlloment = 0
                THROW 50001, N'選擇的扣數場館沒有相應的房額，請確認', 1;

            IF @sUseAgencyAlloment = 'N' AND @sHasAlloment > 0
            BEGIN
                SET @sHasAlloment = 0;
                SELECT @sHasAlloment = COUNT(1) 
                FROM @vBookingRoom AS t 
                INNER JOIN dbo.eAllotmentHotelDaily AS ahd ON t.wAllotmentGroupRid = ahd.wAllotmentGroupRid AND ahd.wRoomRid = t.wHotelRoomRid
                        AND ahd.wDate >= t.wStartDate
                        AND ahd.wDate <= t.wEndtDate
                        AND ahd.wStatus = 'A'
                WHERE t.wUseExtraAllotment = 'N' AND t.RowID = @pRoomBookingDetailRid;

                IF @sUseExtraAllotment = 'N' AND @sHasAlloment = 0 -- 此處判斷房額方法有bug，如果預訂多天，部份滿足，另外一部門不滿足，此時@sHasAlloment > 0
                    THROW 50001, N'沒有足夠房額', 1;
            END
        END
        ---------------------------------------------------------

        -- Reset HotelCheckIn
        UPDATE	@vHotelCheckIn	SET	wBookingStatus = @sNewBookingStatus, wRoomBookingRid = @pRoomBookingDetailRid;

        SET @sXMLHotelCheckIn = ( SELECT * FROM @vHotelCheckIn FOR XML RAW('GetHotelDailyCheckInRecordByRoombookingIdResult') , ROOT('DataSet'));
                       
        -- Check外館房的總值、總成本是否發生變化，因為完成、退款有射數，總值不能變，否則數據會對不上         
        IF ((@sNewBookingStatus = @sOldBookingStatus AND @sOldBookingStatus = 'C') OR @sNewBookingStatus = 'RF') AND @sUseAgencyAlloment = 'Y'
        BEGIN
            DECLARE @sOldPrice numeric(18,4), @sOldCost numeric(18,4), @sNewPrice numeric(18,4), @sNewCost numeric(18,4);
            SELECT @sOldPrice = SUM(ISNULL(wAmountChange,0)), @sOldCost = SUM(ISNULL(wCostChange,0)) FROM dbo.eHotelChange WHERE wRoomBookingRid = @pRoomBookingDetailRid;

            --SELECT * FROM dbo.eHotelChange AS hc INNER JOIN @vHotelCheckIn AS t ON hc.wRoomBookingRid = t.wRoomBookingRid AND t.wStatus = 'A'
            --SELECT @sOldPrice = SUM(ISNULL(wPrice,0)), @sOldCost = SUM(ISNULL(wCost,0)) FROM dbo.eHotelCheckIn WHERE wRoomBookingRid = @pRoomBookingDetailRid AND wStatus = 'A';
            SELECT @sNewPrice = SUM(ISNULL(wPrice,0) + ISNULL(wBreakfastPrice, 0) + ISNULL(wExtraBedPrice, 0)), @sNewCost = SUM(ISNULL(wCost,0) + ISNULL(wBreakfastPrice, 0) + ISNULL(wExtraBedPrice, 0)) FROM @vHotelCheckIn WHERE wRoomBookingRid = @pRoomBookingDetailRid;
        
            IF ISNULL(@sNewPrice, 0) != ISNULL(@sOldPrice, 0) --OR ISNULL(@sNewCost, 0) != ISNULL(@sOldCost, 0) --成本的checking 拿掉
                THROW 50001, N'輸入金額及成本與總值不符', 1;
        END
        IF @sBeginTranCount = 0
        BEGIN
            BEGIN TRAN;
        END;

        DECLARE	@pResetAllotment VARCHAR(1) = 'N' , -- 重新分配房間配額數量
                @sInsertCheckInFirst VARCHAR(1) = 'N';

        IF @pRoomBookingDetailRid > 0
            SELECT @pResetAllotment = IIF(wBookingStatus IN ( 'C', 'CI', 'CO', 'RF' ), 'Y', 'N') FROM dbo.eBookingRoom WHERE RowID = @pRoomBookingDetailRid;

        IF @pActionType = 'U'
            AND @pXMLHotelCheckIn IS NOT NULL
            AND ( NOT EXISTS ( SELECT	1
                               FROM		dbo.eHotelCheckIn
                               WHERE	wRoomBookingRid = @pRoomBookingDetailRid
                                        AND wStatus = 'A' )
                  OR NOT EXISTS ( SELECT	1
                                  FROM		dbo.eHotelChange
                                  WHERE		wRoomBookingRid = @pRoomBookingDetailRid
                                            AND wAction = 'C' )
                )
            SET @sInsertCheckInFirst = 'Y';

        --由於按金插入數據的時候拿不到 hotel 的資料，所以此處需要用此參數傳值到 setBooking -- navin  -- 2017-11-03
        SELECT TOP 1 @pBookingRid = wHotelBookingRid FROM @vBookingRoom;

        IF @pXMLBooking IS NOT NULL
            EXEC [spa].[SetBooking] @pXMLBooking, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;
           
        IF @sInsertCheckInFirst = 'Y'
            EXEC [spa].[SetHotelCheckIn] @sXMLHotelCheckIn, @pActionType, @pMainCompNo, @pNonceToken, @pResetAllotment, 'N', @pRoomBookingDetailRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;
          
        IF @pXMLPassengerDetail IS NOT NULL AND @pActionType != 'I' AND ISNULL(@pRoomBookingDetailRid, -1) > 0
            EXEC [spa].[SetPassengerDetailsRoomBooking] @pXMLPassengerDetail, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pRoomBookingDetailRid, 0, 0, @pErrCode OUTPUT, @pErrMsg OUTPUT;
         
        IF @pXMLRoomBookingDetail IS NOT NULL
            EXEC [spa].[SetRoomBookingDetails] @pXMLRoomBookingDetail, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pRoomBookingDetailRid OUTPUT, @pSeqNo OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;
          
        IF @pBookingRid IS NOT NULL	AND @pSeqNo IS NOT NULL
            UPDATE	dbo.eBooking
            SET		wRefNo = CONCAT(SUBSTRING(wRefNo, 0, CASE WHEN CHARINDEX('-', wRefNo) = 0 THEN LEN(wRefNo) + 2
                                                              ELSE CHARINDEX('-', wRefNo)
                                                         END), '-', FORMAT(@pSeqNo, '000'))
            WHERE	RowID = @pBookingRid;
         
        IF @pXMLPassengerDetail IS NOT NULL AND @pActionType = 'I'
            EXEC [spa].[SetPassengerDetailsRoomBooking] @pXMLPassengerDetail, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pRoomBookingDetailRid, 0, 0, @pErrCode OUTPUT, @pErrMsg OUTPUT;	
                 			
        IF @pXMLPassengerTravelDoc IS NOT NULL
            EXEC [spa].[SetPassengerTravelDocRoomBooking] @pXMLPassengerTravelDoc, 'I', @pMainCompNo, @pNonceToken, 'N', @pRoomBookingDetailRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;

        IF @sInsertCheckInFirst = 'N'  --AND @pXMLHotelCheckIn IS NOT NULL -- 如果取消、不達標不傳入住記錄（因為沒有房額），@pXMLHotelCheckIn IS NOT NULL就不會把P時的入住記錄T掉，入住記錄就會有問題
            EXEC [spa].[SetHotelCheckIn] @sXMLHotelCheckIn, @pActionType, @pMainCompNo, @pNonceToken, @pResetAllotment, 'N', @pRoomBookingDetailRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;
                -- EXEC [spa].[SetActivityLog] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pRoomBookingDetailRid, @pErrCode OUTPUT, @pErrMsg OUTPUT; 
            
        SET @pBookingRoomRid = @pRoomBookingDetailRid;

        -- 【Calendar】 --> 【Mary】
        IF @pBookingRid IS NOT NULL AND @pBookingRid > 0 BEGIN
            EXEC util.WriteMaryAgentActivitiesApiLog @pBookingRid = @pBookingRid, @pBookingType = 'ROOM';
        END;

        -- Update RollsMary.dbo.eExpTran 中的 remark.
        IF @pActionType = 'U'
        BEGIN
            DECLARE @vXMLUpdExp NVARCHAR(MAX) = '' ,
                        @vErrCode INT = 0 ,
                        @vErrMsg NVARCHAR(MAX);

            SET @vXMLUpdExp = (SELECT e.* 
                    FROM RollsMary.dbo.eExpTran AS e 
                         INNER JOIN dbo.eHotelChange AS hc ON e.wBookingActionRid = hc.RowID AND e.wRefRid = hc.wRoomBookingRid
                         INNER JOIN dbo.eBookingRoom br ON hc.wRoomBookingRid = br.RowID
                         INNER JOIN dbo.eBookingHotel bh ON br.wHotelBookingRid = bh.RowID AND bh.wBookingRid = e.wBookingRid
                     WHERE e.wExpGroup = 'RCRM' AND e.wExpType = 'I' AND e.wDeductType = 'DC' AND e.wIsDeposit <> 'Y' AND hc.wRoomBookingRid = @pRoomBookingDetailRid
                FOR XML RAW('Record') , ROOT('DataSet')
            );

            IF @vXMLUpdExp != ''
            BEGIN
                EXEC spa.SetCrmExpTran @pXML = @vXMLUpdExp, -- xml
                    @pActionType = 'U', -- char(1)
                    @pMainCompNo = @pMainCompNo, -- int
                    @pNonceToken = @pNonceToken, -- varchar(64)
                    @pErrCode = @vErrCode OUTPUT, -- int
                    @pErrMsg = @vErrMsg OUTPUT; -- nvarchar(200)
                IF @vErrCode != 0
                    BEGIN
                        SET @pErrMsg = @vErrMsg;
                        THROW 50001, @pErrMsg, 1;
                    END;
            END;			
        END

        IF @sBeginTranCount = 0 AND @@trancount > 0
        BEGIN
            COMMIT;		
        END;
                    
        RETURN;
    END TRY
    BEGIN CATCH
        DECLARE	@sErrorNum INT ,
            @sCatchErrorMessage NVARCHAR(4000) ,
            @xstate INT ,
            @sProcedureName VARCHAR(100) ,
            @sRtnCodeLog INT ,
            @sErrMessageLog NVARCHAR(4000);
            
        SELECT	@sErrorNum = ERROR_NUMBER() ,
                @sCatchErrorMessage = ERROR_MESSAGE() ,
                @xstate = XACT_STATE() ,
                @sProcedureName = OBJECT_NAME(@@PROCID);
            
        IF ISNULL(@pErrCode, 0) = 0
            BEGIN
                SET @pErrCode = 999;
            END;
        
        SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ', @sCatchErrorMessage);
        
        IF @sBeginTranCount = 0
        BEGIN
            IF (@xstate = 1 OR @xstate = -1) AND @@TRANCOUNT > 0
                ROLLBACK;

            -- Write Log
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END;
        ELSE
            THROW;
    END CATCH;
END;