CREATE PROC [test].[GetHotelLstForReqBooking]
AS
    BEGIN
        SET NOCOUNT ON;

        SELECT  RowID,
                wCode,
                wName,
                wEname,
                wJname,
                wThname,
                wKname,
                wRegion,
                wCurrCode,
                wIsEnable = IIF(wStatus = 'A', 'Y', 'N')
        FROM dbo.mHotel
        WHERE wIsBase = '1';
    END