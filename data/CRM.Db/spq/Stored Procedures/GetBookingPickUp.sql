CREATE PROCEDURE [spq].[GetBookingPickUp]
	@pRowID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        RowID, 
        wBookingRid, 
        wOrderNo, 
        wServiceType, 
        wApplyDt, 
        wDriverName, 
        wDriverPhone, 
        wCarNo, 
        wQuantity, 
        wCurrCode, 
        wPaymentMethod, 
        wExpenseAmt, 
        wTotalAmt, 
        wTotalCost, 
        wRemark, 
        wStatus, 
        wReceiptNo, 
        wSeqNo, 
        wCrtDt, 
        wCrtBy, 
        wUpdDt, 
        wUpdBy, 
        wTravelAgencyRid, 
        wRelatedOrderNo, 
        wDisplayName, 
        wUnitPrice, 
        wAdditionalExp, 
        wUseBlackCard, 
        wBookingStatus, 
        wFlightNo, 
        wDepartAirport, 
        wDestination,
        wDepartDt, 
        wArrivalDt, 
        wUnqualifiedRid,
        wOldBookingStatus = wBookingStatus -- Update时，Record获取与保存，DB的前后两次状态是否发生变化，如果发生变化，不能Save（可能预订已经被另外一个用户确认过，同时只能有一个用户可以做状态转换保存）    
    FROM dbo.eBookingPickUpService
	WHERE @pRowID = RowID                                                 
END;