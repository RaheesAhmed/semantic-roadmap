CREATE PROCEDURE [spa].[GenrateChangeCheckInRecord]
    @pRoomBookingRid    BIGINT ,
    @pUpdByRid          BIGINT ,
    @pMainCompNo        INT ,
    @pNewBookingStatus  VARCHAR(5) ,
    @pNonceToken        VARCHAR(64) ,
    @pHotelChangeRid    BIGINT = -1 OUTPUT,		--eHotelChange.RowRid
    @pErrCode           INT = 0 OUTPUT ,
    @pErrMsg            NVARCHAR(200) = '' OUTPUT
AS
    BEGIN
        DECLARE @sBookingRid        BIGINT = 0,
                @sOldBookingStatus  VARCHAR(5)= '';

        SELECT @sBookingRid = wBookingRid,
               @sOldBookingStatus = wBookingStatus
        FROM dbo.eBookingRoom
        WHERE RowID = @pRoomBookingRid;

        IF ( ( @sOldBookingStatus = 'P' AND @pNewBookingStatus = 'C' ) -- 訂單完成
            OR ( @sOldBookingStatus IN ( 'C', 'CI' ) AND @pNewBookingStatus = 'RF') -- 訂單退款
        )
        BEGIN
            DECLARE @sXMLBooking        XML,
                    @sXMLHotelChange    XML ,
                    @sCancelDebitDt     DATETIME2(7),
                    @sNow               DATETIME2(7) = dbo.fnUTC8Now();
            
            DECLARE @sTotalAmount       NUMERIC(18, 4) = 0 ,
                    @sTotalCost         NUMERIC(18, 4) = 0;

            -- 取消扣數日期
            SELECT @sCancelDebitDt = wCancelDebitDt	FROM dbo.eBooking WHERE RowID = @sBookingRid;
            
            SELECT  @sTotalAmount = SUM(ISNULL(wPrice,0) + ISNULL(wBreakfastPrice, 0) + ISNULL(wExtraBedPrice, 0)) , @sTotalCost = SUM(ISNULL(wCost, 0) + ISNULL(wBreakfastPrice, 0) + ISNULL(wExtraBedPrice, 0)) FROM dbo.eHotelCheckIn WHERE wRoomBookingRid = @pRoomBookingRid AND wStatus = 'A';

            -- 根據房間的eBooking數據生成更新入住日期eBooking數據
            SET @sXMLBooking = ( 
                SELECT  RowID = 0,
                        wBookingType = 'CHANGEHOTEL' ,
                        wRefNo = CONCAT(wRefNo, '-', @pNewBookingStatus) ,
                        wReqCounterRid ,
                        wDebitCounterRid ,
                        wReqAgentCodeIn ,
                        wDebitAgentCodeIn ,
                        wReqCustomerRid ,
                        wDebitCustomerRid ,
                        wReqDepartment ,
                        wReqUserRid ,
                        wAsstBooker ,
                        wAssBookerTel ,
                        wApprovalAgentCodeIn ,
                        wDebitDt = CASE WHEN @pNewBookingStatus = 'RF' THEN wCancelDebitDt ELSE wDebitDt END  ,
                        wExpDt ,
                        wCancelDebitDt ,
                        wCancelDt ,
                        wCancelBy ,
                        wCancelReasonCd ,
                        wOtherReason ,
                        wCrtBy = @pUpdByRid ,
                        wCrtDt = @sNow ,
                        wUpdBy = @pUpdByRid ,
                        wUpdDt = @sNow ,
                        wTravePkgRid ,
                        wEventCodeRid ,
                        wAsstBookerEmail ,
                        wDeptFollwedCd ,
                        wStaffFollwedRid ,
                        wStaffTelephone ,
                        wOwnerAuthTelephone ,
                        wDepositAmt,
                        wCoordinator,
                        wIsUser,
                        wUser
                FROM   dbo.eBooking
                WHERE  RowID = @sBookingRid
                FOR XML RAW('SetBookingResult'), ROOT('DataSet')
            );

            SET @sBookingRid = 0;
            IF @sXMLBooking IS NOT NULL
                EXEC [spa].[SetBooking] @sXMLBooking, 'I', @pMainCompNo, @pNonceToken, 'N', @sBookingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;

            -- eHotelChange
            SET @sXMLHotelChange = ( 
                SELECT  RowID = 0,
                        @sBookingRid AS wBookingRid ,
                        @pRoomBookingRid AS wRoomBookingRid ,
                        EBK.wAllotmentGroupRid AS wAllotmentRid ,
                        @pNewBookingStatus AS wAction ,
                        EB.wReqDepartment AS wRequestDeptCd ,
                        EB.wReqUserRid AS wRequestStaffRid ,
                        EB.wAsstBooker AS wAsstBooker ,
                        EB.wAssBookerTel AS wAsstBookerPhone ,
                        EBK.wStartDate AS wOriStartDate ,
                        EBK.wEndtDate AS wOriEndDate ,
                        wNewStartDate = EBK.wStartDate ,
                        wNewEndDate = IIF( @pNewBookingStatus = 'RF', EBK.wStartDate, EBK.wEndtDate),   --- 退款, NewEndDate 跟 wStartDate 一樣，這樣在計算 totalAmount 的時候可以變成 0
                        wDayOfStay = EBK.wDayOfStay ,
                        wDebitDt = IIF(@pNewBookingStatus = 'RF', @sCancelDebitDt, @sNow) ,
                        wExpDt = @sNow ,
                        '' AS wVoucherNo ,
                        EBK.wCashReceiptNo AS wCashReceiptNo ,
                        EBK.wCashTransferReceiptNo AS wCashTransferReceiptNo ,
                        EBK.wUseMemberCard AS wUseMemeberCard ,
                        EBK.wUseExtraAllotment AS wUseExtraAllotment ,
                        EBK.wUseUpAllotment AS wUseUpAllotment ,
                        EBK.wGetKeyMethod AS wGetKeyMethod ,
                        'N' AS wReGetKey ,
                        'N' AS wChangeCheckinPwd ,
                        EBK.wCurrCode AS wCurrCode ,
                        EBK.wPaymentMethod AS wPaymentMethod ,
                        EBK.wRemark AS wRemark ,
                        @sNow AS wCrtDt ,
                        @pUpdByRid AS wCrtBy ,
                        @sNow AS wUpdDt ,
                        @pUpdByRid AS wUpdBy ,
                        EB.wReqCounterRid AS wReqCounterRid ,
                        EBK.wOrderNo AS wOrderNo ,
                        ( CASE @pNewBookingStatus WHEN 'RF' THEN -1 * ISNULL(@sTotalAmount, 0) WHEN 'C' THEN ISNULL(@sTotalAmount, 0) ELSE 0 END ) AS wAmountChange ,  --退款，变动总值变成负数; 完成，變動總值為預訂總值
                        ( CASE @pNewBookingStatus WHEN 'RF' THEN -1 * ISNULL(@sTotalCost, 0) WHEN 'C' THEN ISNULL(@sTotalCost, 0) ELSE 0 END ) AS wCostChange ,      --退款，总成本变成负数；完成，變動總成本為預訂的總成本
                        ( CASE @pNewBookingStatus WHEN 'RF' THEN 0 ELSE ISNULL(@sTotalAmount, 0) END ) AS wTotalAmount ,		 --退款，总值为0；完成，总值为訂總值
                        ( CASE @pNewBookingStatus WHEN 'RF' THEN 0 ELSE ISNULL(@sTotalCost, 0) END ) AS wTotalCost ,			 --退款，總成本为0；完成，總成本為預訂總成本
                        'I' AS RecordState
                    FROM   dbo.eBookingRoom EBK
                    LEFT JOIN dbo.eBooking EB ON EB.RowID=EBK.wBookingRid
                    WHERE  EBK.RowID = @pRoomBookingRid
                    FOR XML RAW('Record') , ROOT('DataSet')
                );
										
                EXEC [spa].[SetHotelChange] @sXMLHotelChange, @pMainCompNo, 0, @pNonceToken, 'N', @sBookingRid, @pErrCode OUT, @pErrMsg OUT;

                SET @pHotelChangeRid = (SELECT TOP(1) RowID FROM dbo.eHotelChange WHERE wBookingRid = @sBookingRid);
            END;
    END;