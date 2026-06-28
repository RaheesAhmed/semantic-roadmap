
CREATE PROCEDURE [spq].[GetBookingRestaurant]
    @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;
	  	
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        SELECT
            RowID,
            wBookingRid,
            wRestaurantRid,
            wNoOfPpl,
            wBookingDt,
            wDiningArea,
            wRemark,
            wStatus,
            wCrtBy,
            wCrtDt,
            wUpdDt,
            wUpdBy,
            wReserveName,
            wReservePhoneNo,
            wIsMinCharge,
            wMinCharge,
            wAdditionalExp,
            wAcceptBTM,
            wUnqualifiedRid,
            wTravelAgencyRid,
            wBookingStatus,
            wOldBookingStatus = wBookingStatus, -- Update时，Record获取与保存，DB的前后两次状态是否发生变化，如果发生变化，不能Save（可能预订已经被另外一个用户确认过，同时只能有一个用户可以做状态转换保存）
            wCurrCode
        FROM dbo.eBookingRestaurant
        WHERE @pRowID = RowID
    END;