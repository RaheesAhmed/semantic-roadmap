CREATE PROCEDURE [spq].[GetRoomPricingDetailsByRoomIdAllotmentId]
    @pwRoomId BIGINT ,
    @pwAllotmentGroupId BIGINT ,
    @pwStartDate DATE ,
    @pwEndDate DATE
AS
    BEGIN

        SET NOCOUNT ON;

        SELECT  wRoomRid ,
                wAllotmentGroupRid ,
                wDate ,
                wAllotmentQty ,
                wExtraQty ,
                wOnHoldQty,
                wBookedQty ,
                wRoomLeftQty = wAllotmentQty + wExtraQty - wOnHoldQty - wBookedQty,
                wRoomPrice ,
                wBreakfastPrice ,
                wRoomCost,
                wExtraBedPrice
        FROM    dbo.eAllotmentHotelDaily (NOLOCK)
        WHERE   wRoomRid = @pwRoomId
                AND wAllotmentGroupRid = @pwAllotmentGroupId
                AND wDate >= @pwStartDate
                AND wDate <= @pwEndDate
                AND wStatus = 'A';

    END;