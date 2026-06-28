CREATE PROCEDURE [spq].[GetBookingPrivatePlane]
    @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;
	
        SELECT 
            RowID, 
            wBookingRid, 
            wPlaneModel, 
            wSupplier, 
            wHotelRid, 
            wTravelAgencyRid, 
            wSeatNo, 
            wOrderNo, 
            wIsSmoking, 
            wServiceLang, 
            wHasWifi, 
            wNoOfServiceStaff, 
            wExpAmt, 
            wTotalAmt, 
            wPaymentMethod, 
            wReceiptNo, 
            wCurrCode, 
            wExtraFee, 
            wConfirmPassengerNo, 
            wRemark, 
            wChangeOrderCount, 
            wBookingNo, 
            wCancelDt, 
            wCancelReason, 
            wStatus, 
            wCrtDt, 
            wCrtBy, 
            wUpdDt, 
            wUpdBy, 
            wBookingType, 
            wTotalCost, 
            wIsUseBlackCard, 
            wUnqualifiedRid,
            wBookingStatus,
            wOldBookingStatus = wBookingStatus -- Update时，Record获取与保存，DB的前后两次状态是否发生变化，如果发生变化，不能Save（可能预订已经被另外一个用户确认过，同时只能有一个用户可以做状态转换保存）
        FROM dbo.eBookingPrivatePlane
        WHERE @pRowID = RowID                                                 
    END;