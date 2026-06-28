CREATE PROCEDURE [spq].[GetBookingHeli]
    @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

        SELECT 
            RowID, 
            wBookingRid, 
            wTicketId, 
            wOrderNo, 
            wBookingLocation, 
            wUseBlackCardFlag, 
            wPaymentMethod, 
            wReceiptNo, 
            wRouteRid, 
            wDepartDt, 
            wDepartDateTime = FORMAT(wDepartDt, 'yyyy-MM-dd HH:mm:ss'), -- 時間要用字符串，否則有時區偏差問題
            wUnitAmt, 
            wQuantity, 
            wExpAmt, 
            wTotalAmt, 
            wCost, 
            wCurrCode, 
            wAdditionalExp, 
            wRemark, 
            wSeqNo, 
            wCrtDt, 
            wCrtBy, 
            wUpdDt, 
            wUpdBy, 
            wBookingStatus, 
            wStatus, 
            wHandlingFee, 
            wIsCharteredFlight, 
            wChangeOrderCount, 
            wUnqualifiedRid,
            wOldBookingStatus = wBookingStatus -- Update时，Record获取与保存，DB的前后两次状态是否发生变化，如果发生变化，不能Save（可能预订已经被另外一个用户确认过，同时只能有一个用户可以做状态转换保存）
        FROM dbo.eBookingHeli bh_t
        WHERE @pRowID = RowID                                                 
    END;