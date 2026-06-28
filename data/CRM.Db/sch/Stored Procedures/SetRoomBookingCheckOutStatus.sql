CREATE PROCEDURE [sch].[SetRoomBookingCheckOutStatus]
AS
    BEGIN

-- This is running every day to set room booking status 'Check-Out' if Check-out date is less than today's date.
        SET NOCOUNT ON;

        UPDATE  EBR
        SET     EBR.wBookingStatus = 'CO' ,
                EBR.wUpdDt = dbo.fnUTC8Now()
        FROM    dbo.eBookingRoom EBR
        WHERE   EBR.wStatus = 'A'
                AND EBR.wBookingStatus = 'CI'
                AND CAST(EBR.wEndtDate AS DATE) < CAST(dbo.fnUTC8Now() AS DATE);

		-- wDismiss no need use  -- 2017-10-17 ligy
        --UPDATE  CHK
        --SET     CHK.wDismiss = 'Y' ,
        --        CHK.wUpdDt = dbo.fnUTC8Now()
        --FROM    dbo.eHotelCheckIn CHK
        --        INNER JOIN ( SELECT *
        --                     FROM   dbo.eBookingRoom
        --                     WHERE  wBookingStatus = 'CO'
        --                   ) EBR ON EBR.RowID = CHK.wRoomBookingRid;

    END;