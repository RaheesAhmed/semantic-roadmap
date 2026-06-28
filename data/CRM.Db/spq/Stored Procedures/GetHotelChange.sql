CREATE PROCEDURE [spq].[GetHotelChange] 
    @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

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
                'N' AS RecordState
        FROM dbo.eHotelChange WITH(NOLOCK)
        WHERE @pRowID = RowID;
    END;