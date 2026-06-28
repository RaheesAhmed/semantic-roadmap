CREATE PROCEDURE [spq].[GetBookingHotel]
    @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;  

        SELECT  RowID,
                wBookingRid,
                wRequestRid,
                wUseTravelAgency,
                wTravelAgencyRid,
                wRoomInProgress,
                wRoomCompleted,
                wRoomNotArrange,
                wRoomCancelled,
                wRoomUnQualified,
                wQuantity,
                wRegion,
                wIsAgentHotel,
                wStartDate,
                wEndDate,
                wDayOfStay,
                wBedType,
                wPaymentMethod,
                wReceiptNo,
                wRemark,
                wSeqNo,
                wCrtDt,
                wCrtBy,
                wUpdDt,
                wUpdBy,
                wBookingStatus,
                wCounterRid,
                wStatus
        FROM dbo.eBookingHotel WITH(NOLOCK)
        WHERE @pRowID = RowID;
    END;