
CREATE PROCEDURE [util].[RecalRoomUsage]
AS
BEGIN


UPDATE ly SET ly.wBookedQty = a.wBookedQty, ly.wExtraQty = a.wExtraQty FROM (
			SELECT ald.RowId, ald.wRoomRid, ald.wAllotmentGroupRid, ald.wDate, ald.wAllotmentQty, 
				(SELECT COUNT(1) FROM dbo.eHotelCheckIn AS e LEFT JOIN ( SELECT t.* FROM dbo.eHotelChange AS t INNER JOIN
							(SELECT MAX(RowID) AS RowID from dbo.eHotelChange GROUP BY wRoomBookingRid) AS g ON t.RowID = g.RowID) AS hc ON hc.wRoomBookingRid = e.wRoomBookingRid
					LEFT JOIN dbo.eBookingRoom AS br ON br.RowID = e.wRoomBookingRid
					WHERE e.wRoomRid = ald.wRoomRid AND e.wAllotmentGroupRid = ald.wAllotmentGroupRid 
						 AND e.wBookingDate = ald.wDate AND e.wStatus = 'A' AND e.wDismiss != 'Y' AND br.wBookingStatus IN ('C','CI')) 
					AS wBookedQty, 
		
				(SELECT COUNT(1) FROM dbo.eHotelCheckIn AS e LEFT JOIN ( SELECT t.* FROM dbo.eHotelChange AS t INNER JOIN
							(SELECT MAX(RowID) AS RowID from dbo.eHotelChange GROUP BY wRoomBookingRid) AS g ON t.RowID = g.RowID) AS hc ON hc.wRoomBookingRid = e.wRoomBookingRid
					LEFT JOIN dbo.eBookingRoom AS br ON br.RowID = e.wRoomBookingRid
					WHERE e.wExtraRoom = 'Y' AND e.wRoomRid = ald.wRoomRid AND e.wAllotmentGroupRid = ald.wAllotmentGroupRid 
						 AND e.wBookingDate = ald.wDate AND e.wStatus = 'A' AND e.wDismiss != 'Y' AND br.wBookingStatus IN ('C','CI'))
					AS wExtraQty
			 FROM dbo.eAllotmentHotelDaily AS ald 
					INNER JOIN	dbo.eHotelCheckIn AS e ON ald.wRoomRid = e.wRoomRid AND ald.wAllotmentGroupRid = e.wAllotmentGroupRid AND ald.wDate = e.wBookingDate AND e.wStatus = 'A'		
					GROUP BY ald.RowId, ald.wRoomRid, ald.wAllotmentGroupRid, ald.wDate, ald.wAllotmentQty
					--ORDER BY ald.wRoomRid, ald.wAllotmentGroupRid, ald.wDate DESC
			) AS a
			INNER JOIN dbo.eAllotmentHotelDaily AS ly ON a.RowId = ly.RowId
WHERE  --a.wAllotmentQty + a.wExtraQty < a.wBookedQty
	 ly.wBookedQty <> a.wBookedQty OR ly.wExtraQty <> a.wExtraQty;

END