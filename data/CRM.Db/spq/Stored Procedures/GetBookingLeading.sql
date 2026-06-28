
CREATE PROCEDURE [spq].[GetBookingLeading]
	@pRowID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        RowID, 
        wBookingRid, 
        wRegion, 
        wOrderNo, 
        wNoofPolice, 
        wStartDt, 
        wCurrCode, 
        wPaymentMethod, 
        wReceiptNo, 
        wExpenseAmt, 
        wTotalAmt, 
        wTotalCost, 
        wRemark, 
        wStatus, 
        wSeqNo, 
        wCrtDt, 
        wCrtBy, 
        wUpdDt, 
        wUpdBy, 
        wTravelAgencyRid, 
        wLang, 
        wAdditionalExp, 
        wBookingStatus, 
        wUseBlackCard, 
        wUnqualifiedRid, 
        wOldBookingStatus = wBookingStatus -- Update时，Record获取与保存，DB的前后两次状态是否发生变化，如果发生变化，不能Save（可能预订已经被另外一个用户确认过，同时只能有一个用户可以做状态转换保存）    
    FROM dbo.eBookingLeading
	WHERE @pRowID = RowID                                                 
END;