CREATE FUNCTION [dbo].[fnGetBookingStatusErrorMsg](
    @pActionType CHAR(1) , -- I/U/D 
    @pBookingType VARCHAR(30),
    @pCurrentBookingStatus VARCHAR(5), -- DB當前的狀態
    @pOldBookingStatus VARCHAR(5), -- 上一次Get數據時的狀態（客戶端回傳狀態）
    @pNewBookingStatus VARCHAR(5), -- Save數據時的新狀態（可能改變狀態，也可以沒有改變）,
    @pLangCd VARCHAR(10) = 'zh-TW'
)
RETURNS NVARCHAR(MAX)
AS
    BEGIN
        DECLARE @sErrorMsg NVARCHAR(MAX) = '';
        SET @pActionType = ISNULL(@pActionType, ' ');
        SET @pBookingType = NULLIF(@pBookingType, '');
        SET @pCurrentBookingStatus = UPPER(NULLIF(@pCurrentBookingStatus, ''));
        SET @pOldBookingStatus = UPPER(NULLIF(@pOldBookingStatus, ''));
        SET @pNewBookingStatus = UPPER(NULLIF(@pNewBookingStatus, ''));
        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

        -- 預訂類型
        DECLARE @vBookingType AS TABLE( wBookingType VARCHAR(30), wBookingStatusType VARCHAR(50) );
        INSERT INTO @vBookingType(wBookingType, wBookingStatusType)
        VALUES  ('LEADING_SERVICE',    'LEADING_SERVICE_STATUS'), 
                ('ADDITIONALEXPENSES', 'ADDITIONAL_EXPENSES_STATUS'), 
                ('Visa',               'VISA_APPLICATION_STATUS'), 
                ('SHOWTICKET',         'PERFORMANCE_TICKET_STATUS'), 
                ('TOUR',               'TOUR_GUIDE_STATUS'), 
                ('PP',                 'PRIVATE_PLANE_BOOKING_STATUS'), 
                ('TRAVEL_PACKAGE',     'TRAVEL_PACKAGE_STATUS'),
                ('PickUp_SERVICE',     'PICK_UP_SERVICE_STATUS'), 
                ('ROOM',               'ROOM_BOOKING_STATUS'), 
                ('HELI',               'HELICOPTER_BOOKING_STATUS'), 
                ('RESTAURANT',         'RESTAURANT_BOOKING_STATUS'), 
                ('AIRTICKET',          'AIR_TICKET_BOOKING_STATUS'),
                ('CHK_IN_SVC',         'BOARDING_SERVICE_BOOKING_STATUS'), 
                ('FERRY',              'FERRY_STATUS');

        -- 預訂狀態
        DECLARE @vBookingStatus AS TABLE( wBookingStatus VARCHAR(5) );
        INSERT INTO @vBookingStatus(wBookingStatus)
        SELECT DISTINCT lu.wCode
        FROM dbo.mLookUp AS lu
        INNER JOIN @vBookingType AS bt ON bt.wBookingStatusType = lu.wType
        WHERE @pBookingType = bt.wBookingType AND @pLangCd = lu.wLangCd;

        -- 非 I/U/D 操作視為非法操作
        -- 如果已經有錯誤，不再Check
        IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType NOT IN ('I', 'U', 'D')
            SET @sErrorMsg = N'非法操作！';
        
        --  任何操作，在eBooking找不到的預訂類型，均無效
        -- 如果已經有錯誤，不再Check
        IF NULLIF(@sErrorMsg, '') IS NULL AND (@pBookingType IS NULL OR NOT EXISTS (SELECT 1 FROM @vBookingType WHERE wBookingType = @pBookingType))
            SET @sErrorMsg = N'無效預訂類型！';

        -- 更新（U）或刪除（D），當前DB預訂狀態必須有效（非Insert操作，wBookingStatus必须要传值）
        -- 如果已經有錯誤，不再Check
        IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType IN ('U', 'D') AND (@pCurrentBookingStatus IS NULL OR NOT EXISTS (SELECT 1 FROM @vBookingStatus WHERE wBookingStatus = @pCurrentBookingStatus))
            SET @sErrorMsg = N'無效預訂狀態(CurrentBookingStatus)。' + ' - ' + ISNULL(@pCurrentBookingStatus, 'NULL');
           
        -- 更新（U）或刪除（D），上一次Get到的預訂狀態必須有效（非Insert操作，wOldBookingStatus必须要传值）
        IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType IN ('U', 'D') AND (@pOldBookingStatus IS NULL OR NOT EXISTS (SELECT 1 FROM @vBookingStatus WHERE wBookingStatus = @pOldBookingStatus))
            SET @sErrorMsg = N'無效預訂狀態(OldBookingStatus)。' + ' - ' + ISNULL(@pOldBookingStatus, 'NULL');

        -- 任何操作，更新預訂狀態都必須要有效
        IF NULLIF(@sErrorMsg, '') IS NULL AND (@pNewBookingStatus IS NULL OR NOT EXISTS (SELECT 1 FROM @vBookingStatus WHERE wBookingStatus = @pNewBookingStatus))
            SET @sErrorMsg = N'無效預訂狀態(NewBookingStatus)。' + ' - ' + ISNULL(@pNewBookingStatus, 'NULL');
        
        -- 预订Get到上一次保存的状态与DB不一致，可能因为另外一个用户对此单进行了某些操作
        -- 只能前后两次的状态一致才可以保存，否则同时操作一条record，可能会导致射数错乱
        -- 如果已經有錯誤，不再Check
        IF @pBookingType <> 'ROOM'
        BEGIN
            IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType IN ('U', 'D') AND  @pOldBookingStatus <> @pCurrentBookingStatus
            BEGIN
                SET @sErrorMsg =   CASE WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'P'  THEN N'保存失敗！訂單已取消。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'CL' THEN N'保存失败！訂單已取消，不能重复取消。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'UQ' THEN N'保存失败！訂單已取消，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'DL' THEN N'保存失败！訂單已取消，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'C'  THEN N'保存失败！訂單已取消，不能确认消费。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'RF' THEN N'保存失败！訂單已取消，不能退款。'
                                       
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'P'  THEN N'保存失败！訂單已不達標。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'CL' THEN N'保存失败！訂單已不達標，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'UQ' THEN N'保存失败！訂單已不達標，不能重複設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'DL' THEN N'保存失败！訂單已不達標，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'C'  THEN N'保存失败！訂單已不達標，不能確認消費。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'RF' THEN N'保存失败！訂單已不達標，不能退款。'

                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'P'  THEN N'保存失败！訂單已刪除。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'CL' THEN N'保存失败！訂單已刪除，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'UQ' THEN N'保存失败！訂單已刪除，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'DL' THEN N'保存失败！訂單已刪除，不能重複刪除。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'C'  THEN N'保存失败！訂單已刪除，不能確認消費。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'RF' THEN N'保存失败！訂單已刪除，不能退款。'

                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'P'  THEN N'保存失败！訂單已完成。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'CL' THEN N'保存失败！訂單已完成，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'UQ' THEN N'保存失败！訂單已完成，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'DL' THEN N'保存失败！訂單已完成，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'C'  THEN N'保存失败！訂單已完成，不能重複確認消費。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'RF' THEN N'保存失败！訂單已完成，不能退款。'

                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'P'  THEN N'保存失败！訂單已退款。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'CL' THEN N'保存失败！訂單已退款，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'UQ' THEN N'保存失败！訂單已退款，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'DL' THEN N'保存失败！訂單已退款，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'C'  THEN N'保存失败！訂單已退款，不能確認消費。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'RF' THEN N'保存失败！訂單已退款，不能重複退款。'
                                    END
            END
        END
        ELSE
        BEGIN
            IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType IN ('U', 'D') AND  @pOldBookingStatus <> @pCurrentBookingStatus
            BEGIN
                SET @sErrorMsg =   CASE WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'P'  THEN N'保存失敗！房間預訂已取消。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'CL' THEN N'保存失败！房間預訂已取消，不能重复取消。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'UQ' THEN N'保存失败！房間預訂已取消，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'DL' THEN N'保存失败！房間預訂已取消，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'C'  THEN N'保存失败！房間預訂已取消，不能确认消费。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'RF' THEN N'保存失败！房間預訂已取消，不能退款。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'CI' THEN N'保存失败！房間預訂已取消，不能入住。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'CO' THEN N'保存失败！房間預訂已取消，不能退房。'
                                       
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'P'  THEN N'保存失败！房間預訂已不達標。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'CL' THEN N'保存失败！房間預訂已不達標，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'UQ' THEN N'保存失败！房間預訂已不達標，不能重複設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'DL' THEN N'保存失败！房間預訂已不達標，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'C'  THEN N'保存失败！房間預訂已不達標，不能確認消費。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'RF' THEN N'保存失败！房間預訂已不達標，不能退款。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'CI' THEN N'保存失败！房間預訂已不達標，不能入住。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'CO' THEN N'保存失败！房間預訂已不達標，不能退房。'

                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'P'  THEN N'保存失败！房間預訂已刪除。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'CL' THEN N'保存失败！房間預訂已刪除，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'UQ' THEN N'保存失败！房間預訂已刪除，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'DL' THEN N'保存失败！房間預訂已刪除，不能重複刪除。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'C'  THEN N'保存失败！房間預訂已刪除，不能確認消費。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'RF' THEN N'保存失败！房間預訂已刪除，不能退款。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'CI' THEN N'保存失败！房間預訂已刪除，不能入住。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'RF' THEN N'保存失败！房間預訂已刪除，不能退房。'

                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'P'  THEN N'保存失败！房間預訂已完成。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'CL' THEN N'保存失败！房間預訂已完成，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'UQ' THEN N'保存失败！房間預訂已完成，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'DL' THEN N'保存失败！房間預訂已完成，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'C'  THEN N'保存失败！房間預訂已完成，不能重複確認消費。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'RF' THEN N'保存失败！房間預訂已完成，不能退款。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'CI' THEN N'保存失败！房間預訂已完成，不能入住。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'CO' THEN N'保存失败！房間預訂已完成，不能退房。'

                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'P'  THEN N'保存失败！房間預訂已退款。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'CL' THEN N'保存失败！房間預訂已退款，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'UQ' THEN N'保存失败！房間預訂已退款，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'DL' THEN N'保存失败！房間預訂已退款，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'C'  THEN N'保存失败！房間預訂已退款，不能確認消費。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'RF' THEN N'保存失败！房間預訂已退款，不能重複退款。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'CI' THEN N'保存失败！房間預訂已退款，不能入住。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'CO' THEN N'保存失败！房間預訂已退款，不能退房。'

                                        WHEN @pCurrentBookingStatus = 'CI' AND @pNewBookingStatus = 'P'  THEN N'保存失败！房間已入住。'
                                        WHEN @pCurrentBookingStatus = 'CI' AND @pNewBookingStatus = 'CL' THEN N'保存失败！房間已入住，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'CI' AND @pNewBookingStatus = 'UQ' THEN N'保存失败！房間已入住，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'CI' AND @pNewBookingStatus = 'DL' THEN N'保存失败！房間已入住，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'CI' AND @pNewBookingStatus = 'C'  THEN N'保存失败！房間已入住，不能確認消費。'
                                        WHEN @pCurrentBookingStatus = 'CI' AND @pNewBookingStatus = 'RF' THEN N'保存失败！房間已入住，不能退款。'
                                        WHEN @pCurrentBookingStatus = 'CI' AND @pNewBookingStatus = 'CI' THEN N'保存失败！房間已入住，不能重複入住。'
                                        WHEN @pCurrentBookingStatus = 'CI' AND @pNewBookingStatus = 'CO' THEN N'保存失败！房間已入住，不能退房。'

                                        WHEN @pCurrentBookingStatus = 'CO' AND @pNewBookingStatus = 'P'  THEN N'保存失败！房間已退房。'
                                        WHEN @pCurrentBookingStatus = 'CO' AND @pNewBookingStatus = 'CL' THEN N'保存失败！房間已退房，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'CO' AND @pNewBookingStatus = 'UQ' THEN N'保存失败！房間已退房，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'CO' AND @pNewBookingStatus = 'DL' THEN N'保存失败！房間已退房，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'CO' AND @pNewBookingStatus = 'C'  THEN N'保存失败！房間已退房，不能確認消費。'
                                        WHEN @pCurrentBookingStatus = 'CO' AND @pNewBookingStatus = 'RF' THEN N'保存失败！房間已退房，不能退款。'
                                        WHEN @pCurrentBookingStatus = 'CO' AND @pNewBookingStatus = 'CI' THEN N'保存失败！房間已退房，不能入住。'
                                        WHEN @pCurrentBookingStatus = 'CO' AND @pNewBookingStatus = 'CO' THEN N'保存失败！房間已退房，不能重複退房。'
                                    END
            END
        END;

        -- 預訂狀態不能退回之前的某一個狀態，例如：完成，不能變成處理中、取消、不達標
        -- 如果已經有錯誤，不再Check
        IF @pBookingType <> 'ROOM'
        BEGIN
            IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType = 'U'
            BEGIN
                SET @sErrorMsg =   CASE WHEN @pCurrentBookingStatus = 'P' AND @pNewBookingStatus = 'RF' THEN N'保存失敗！處理中的訂單，不能退款。'

                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'P'  THEN N'保存失敗！訂單已取消，不能設置處理中。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'UQ' THEN N'保存失敗！訂單已取消，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'DL' THEN N'保存失敗！訂單已取消，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'C'  THEN N'保存失敗！訂單已取消，不能確認消費。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'RF' THEN N'保存失敗！訂單已取消，不能退款。'

                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'P'  THEN N'保存失敗！訂單已不達標，不能設置處理中。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'CL' THEN N'保存失敗！訂單已不達標，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'DL' THEN N'保存失敗！訂單已不達標，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'C'  THEN N'保存失敗！訂單已不達標，不能確認消費。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'RF' THEN N'保存失敗！訂單已不達標，不能退款。'

                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'P'  THEN N'保存失敗！訂單已刪除，不能設置處理中。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'CL' THEN N'保存失敗！訂單已刪除，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'UQ' THEN N'保存失敗！訂單已刪除，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'C'  THEN N'保存失敗！訂單已刪除，不能確認消費。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'RF' THEN N'保存失敗！訂單已刪除，不能退款。'

                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'P'  THEN N'保存失敗！訂單已完成，不能設置處理中。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'CL' AND @pBookingType <> 'RESTAURANT' THEN N'保存失敗！訂單已完成，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'UQ' THEN N'保存失敗！訂單已完成，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'DL' THEN N'保存失敗！訂單已完成，不能刪除，只有【處理中】的訂單才能刪除。'

                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'P'  THEN N'保存失敗！訂單已退款，不能設置處理中。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'CL' THEN N'保存失敗！訂單已退款，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'UQ' THEN N'保存失敗！訂單已退款，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'DL' THEN N'保存失敗！訂單已退款，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'C'  THEN N'保存失敗！訂單已退款，不能確認消費。'
                                    END
            END
        END
        ELSE
        BEGIN
            IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType = 'U' -- Next Booking Status
            BEGIN
                SET @sErrorMsg =   CASE WHEN @pCurrentBookingStatus = 'P' AND @pNewBookingStatus = 'RF' THEN N'保存失敗！處理中的房間，不能退款。'
                                        WHEN @pCurrentBookingStatus = 'P' AND @pNewBookingStatus = 'CI' THEN N'保存失敗！處理中的房間，不能入住。'
                                        WHEN @pCurrentBookingStatus = 'P' AND @pNewBookingStatus = 'CO' THEN N'保存失敗！處理中的房間，不能退房。'

                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'P'  THEN N'保存失敗！房間預訂已取消，不能設置處理中。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'UQ' THEN N'保存失敗！房間預訂已取消，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'DL' THEN N'保存失敗！房間預訂已取消，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'C'  THEN N'保存失敗！房間預訂已取消，不能確認消費。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'RF' THEN N'保存失敗！房間預訂已取消，不能退款。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'CI' THEN N'保存失敗！房間預訂已取消，不能入住。'
                                        WHEN @pCurrentBookingStatus = 'CL' AND @pNewBookingStatus = 'CO' THEN N'保存失敗！房間預訂已取消，不能退房。'

                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'P'  THEN N'保存失敗！房間預訂已不達標，不能設置處理中。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'CL' THEN N'保存失敗！房間預訂已不達標，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'DL' THEN N'保存失敗！房間預訂已不達標，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'C'  THEN N'保存失敗！房間預訂已不達標，不能確認消費。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'RF' THEN N'保存失敗！房間預訂已不達標，不能退款。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'CI' THEN N'保存失敗！房間預訂已不達標，不能入住。'
                                        WHEN @pCurrentBookingStatus = 'UQ' AND @pNewBookingStatus = 'CO' THEN N'保存失敗！房間預訂已不達標，不能退房。'

                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'P'  THEN N'保存失敗！房間預訂已刪除，不能設置處理中。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'CL' THEN N'保存失敗！房間預訂已刪除，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'UQ' THEN N'保存失敗！房間預訂已刪除，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'C'  THEN N'保存失敗！房間預訂已刪除，不能確認消費。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'RF' THEN N'保存失敗！房間預訂已刪除，不能退款。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'CI' THEN N'保存失敗！房間預訂已刪除，不能入住。'
                                        WHEN @pCurrentBookingStatus = 'DL' AND @pNewBookingStatus = 'CO' THEN N'保存失敗！房間預訂已刪除，不能退房。'

                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'P'  THEN N'保存失敗！房間預訂已完成。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'CL' THEN N'保存失敗！房間預訂已完成，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'UQ' THEN N'保存失敗！房間預訂已完成，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'DL' THEN N'保存失敗！房間預訂已完成，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'C' AND @pNewBookingStatus = 'CO' THEN N'保存失敗！房間未入住，不能退房'

                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'P'  THEN N'保存失敗！房間預訂已退款，不能設置處理中。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'CL' THEN N'保存失敗！房間預訂已退款，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'UQ' THEN N'保存失敗！房間預訂已退款，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'DL' THEN N'保存失敗！房間預訂已退款，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'C'  THEN N'保存失敗！房間預訂已退款，不能確認消費。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'CI' THEN N'保存失敗！房間預訂已退款，不能入住。'
                                        WHEN @pCurrentBookingStatus = 'RF' AND @pNewBookingStatus = 'CO' THEN N'保存失敗！房間預訂已退款，不能退房。'

                                        WHEN @pCurrentBookingStatus = 'CI' AND @pNewBookingStatus = 'P'  THEN N'保存失敗！房間入住，不能設置處理中。'
                                        WHEN @pCurrentBookingStatus = 'CI' AND @pNewBookingStatus = 'CL' THEN N'保存失敗！房間入住，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'CI' AND @pNewBookingStatus = 'UQ' THEN N'保存失敗！房間入住，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'CI' AND @pNewBookingStatus = 'DL' THEN N'保存失敗！房間入住，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'CI' AND @pNewBookingStatus = 'C'  THEN N'保存失敗！房間入住，不能確認消費。'

                                        WHEN @pCurrentBookingStatus = 'CO' AND @pNewBookingStatus = 'P'  THEN N'保存失敗！房間已退房，不能設置處理中。'
                                        WHEN @pCurrentBookingStatus = 'CO' AND @pNewBookingStatus = 'CL' THEN N'保存失敗！房間已退房，不能取消。'
                                        WHEN @pCurrentBookingStatus = 'CO' AND @pNewBookingStatus = 'UQ' THEN N'保存失敗！房間已退房，不能設置不達標。'
                                        WHEN @pCurrentBookingStatus = 'CO' AND @pNewBookingStatus = 'DL' THEN N'保存失敗！房間已退房，不能刪除，只有【處理中】的訂單才能刪除。'
                                        WHEN @pCurrentBookingStatus = 'CO' AND @pNewBookingStatus = 'C'  THEN N'保存失敗！房間已退房，不能確認消費。'
                                        WHEN @pCurrentBookingStatus = 'CO' AND @pNewBookingStatus = 'RF' THEN N'保存失敗！房間已退房，不能退款。'
                                    END
            END
        END;
            
        -- 只有【處理中】的訂單才可以刪除
        -- 如果已經有錯誤，不再Check
        IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType = 'D'
        BEGIN
            SET @sErrorMsg = CASE WHEN @pCurrentBookingStatus = 'P' THEN NULL
                                  ELSE N'保存失敗！只有【處理中】的訂單才能刪除。'
                                  END;
        END;

        RETURN @sErrorMsg;
    END;