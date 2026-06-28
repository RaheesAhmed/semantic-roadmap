
CREATE PROCEDURE [spq].[GetBookingTourGuide]
    @pRowID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        RowID, 
        wBookingRid, 
        wRegion, 
        wTravelAgencyRid, 
        wLang, 
        wOrderNo, 
        wStartDt, 
        wEndtDt, 
        wPaymentMethod, 
        wPeriod, 
        wExpenseAmt, 
        wTotalAmt, 
        wCost, 
        wAdditionalExp, 
        wCurrCode, 
        wRemark, 
        wStatus, 
        wBookingStatus, 
        wReceiptNo, 
        wSeqNo, 
        wCrtDt, 
        wCrtBy, 
        wUpdDt, 
        wUpdBy, 
        wIsUseBlackCard, 
        wUnqualifiedRid,
        wOldBookingStatus = wBookingStatus -- Update时，Record获取与保存，DB的前后两次状态是否发生变化，如果发生变化，不能Save（可能预订已经被另外一个用户确认过，同时只能有一个用户可以做状态转换保存）
    FROM dbo.eBookingTourGuide
	WHERE @pRowID = RowID                                                 
END;