CREATE PROCEDURE [spq].[GetBookingVisa]
    @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

        SELECT 
            RowId, 
            wBookingRid, 
            wOrderNo, 
            wApplyDt, 
            wPlaceOfIssue, 
            wCurrCode, 
            wPaymentMethod, 
            wExpAmt, 
            wTotalAmt, 
            wStatus, 
            wCrtBy, 
            wCrtDt, 
            wUpdBy, 
            wUpdDt, 
            wReceiptNo, 
            wTravelAgencyRid, 
            wQuantity, 
            wUnitPrice, 
            wCost, 
            wAdditionalExp, 
            wRemark, 
            wBookingStatus, 
            wUseBlackCard, 
            wUnqualifiedRid,
            wOldBookingStatus = wBookingStatus -- Update时，Record获取与保存，DB的前后两次状态是否发生变化，如果发生变化，不能Save（可能预订已经被另外一个用户确认过，同时只能有一个用户可以做状态转换保存）    
        FROM dbo.eBookingVisa
        WHERE @pRowID = RowID                                                 
    END;