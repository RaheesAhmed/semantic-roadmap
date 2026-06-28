CREATE PROCEDURE [spq].[GetBookingFerry]
(
    @pRowID BIGINT
)
AS
    BEGIN
        SET NOCOUNT ON;

        SELECT 
            RowID, 
            wBookingRid,
            wClassCd,
            wTicketType,
            wPaymentMethod,
            wRouteRid,
            wDepartDt,
            wCurrCode,
            wExpAmt,
            wQuantity,
            wTotalAmt,
            wCost,
            wRemark,
            wCrtDt,
            wCrtBy,
            wUpdDt,
            wUpdBy,
            wOrderNo,
            wUnitAmt,
            wSeqNo,
            wTicketId,
            wStatus,
            wUseBlackCard,
            wReceiptNo,
            wBookingStatus,
            wWaived,
            wUnqualifiedRid,
            wTravelAgencyRid,
            wOldBookingStatus = wBookingStatus, -- Update时，Record获取与保存，DB的前后两次状态是否发生变化，如果发生变化，不能Save（可能预订已经被另外一个用户确认过，同时只能有一个用户可以做状态转换保存）
            wURLType,
            wURLAddress
        FROM dbo.eBookingFerry 
        WHERE @pRowID = RowID 
    END;