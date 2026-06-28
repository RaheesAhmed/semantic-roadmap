CREATE PROC [spq].[GetAllotmentRoomLstForBooking]
    @pHotelRid BIGINT,
    @pAllotmentGroupRid BIGINT,
    @pServiceCounterRid BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pHotelRid = IIF(@pHotelRid <= 0, NULL, @pHotelRid);
        SET @pAllotmentGroupRid = IIF(@pAllotmentGroupRid <= 0, NULL, @pAllotmentGroupRid);
        SET @pServiceCounterRid = IIF(@pServiceCounterRid <= 0, NULL, @pServiceCounterRid);
        
        SELECT DISTINCT 
            wAllotmentGroupRid = ag.RowID, 
            wHotelRid = h.RowID, 
            wRoomRid = hr.RowID,
            wServiceCounterRid = agd.wCounterRid,
            wAllotmentGroupName = ag.wCode + ' - ' + ag.wName,
            wHotelName = h.wCode + IIF(NULLIF(h.wCode, '') IS NULL, '',  ' - ') + h.wName,
            wRoomName = hr.wCode + IIF(NULLIF(hr.wCode , '') IS NULL, '', ' - ') + hr.wName,
            wStatus = IIF(hr.wStatus = 'T' OR a.wStatus = 'T', 'T', 'A')
        FROM dbo.eAllotmentHotel a
        INNER JOIN dbo.mHotel h ON h.RowID = a.wHotelRid
        INNER JOIN dbo.mHotelRoom hr ON hr.RowID = a.wRoomRid
        INNER JOIN dbo.eAllotmentHotelDtl ad ON ad.wAllotmentHotelRid = a.RowID
        INNER JOIN dbo.mAllotmentGroup ag ON ag.RowID = ad.wAllotmentGroupRid
        INNER JOIN dbo.mAllotmentGroupDtl agd ON agd.wAllotmentGroupRid = ag.RowID
        WHERE -- a.wStatus = 'A'
            (@pHotelRid IS NULL OR @pHotelRid = h.RowID)
            AND (@pAllotmentGroupRid IS NULL OR @pAllotmentGroupRid = ag.RowID )
            AND (@pServiceCounterRid IS NULL OR @pServiceCounterRid = agd.wCounterRid);
    END