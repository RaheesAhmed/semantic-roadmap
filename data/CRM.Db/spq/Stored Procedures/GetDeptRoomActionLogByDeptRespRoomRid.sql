CREATE PROC [spq].[GetDeptRoomActionLogByDeptRespRoomRid]
    @pDeptRespRoomRid   BIGINT,
    @pLangCd            VARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

        SELECT resp_log.RowID,
               resp_log.wDeptReqRoomRid,
               resp_log.wDeptRespRoomRid,
               resp_log.wHotelRid,
               resp_log.wRoomRid,
               wHotelCd = h.wCode,
               wHotelName = IIF(@pLangCd = 'en-GB', h.wEname, h.wName),
               wHotelRoomCd = ISNULL(hr.wCode, ''),
               wHotelRoomName = ISNULL(IIF(@pLangCd = 'en-GB', hr.wEname, hr.wName), ''),
               resp_log.wBigBedQty,
               resp_log.wTwinBedQty,
               resp_log.wSuiteRoom1Qty,
               resp_log.wSuiteRoom2Qty,
               resp_log.wSuiteRoom3Qty,
               wStartDate = FORMAT(resp_log.wStartDate, 'yyyy-MM-dd'),
               wEndDate = FORMAT(resp_log.wEndDate, 'yyyy-MM-dd'),
               resp_log.wDayOfStay,
               resp_log.wRemark,
               resp_log.wTotalAmount,
               resp_log.wIsApproved,
               resp_log.wDeptStatus,
               resp_log.wRepStatus,
               resp_log.wIsExtRoom,
               wDeptStatusName = '',  -- 部門狀態名稱，係界面Set Value
               wDeptStatusColor = '', -- 部門狀態顏色，係界面Set Value
               wRepStatusName = '',   -- 要求狀態名稱，係界面Set Value
               wRepStatusColor = '',  -- 要求狀態顏色，係界面Set Value
               wBookingRefNo = ISNULL(eb.wRefNo, ''), -- 預訂編號
               wUpdDt = FORMAT(resp_log.wUpdDt, 'yyyy-MM-dd HH:mm'),
               wUpdBy = CONCAT(upd.wCName, CHAR(10), upd.wName)
        FROM dbo.eDeptRespRoomActionLog resp_log
        INNER JOIN dbo.eDeptRespRoom resp ON resp.RowID = resp_log.wDeptRespRoomRid AND resp.wDeptReqRoomRid = resp_log.wDeptReqRoomRid
        INNER JOIN dbo.eDeptReqRoom req ON req.RowID = resp_log.wDeptReqRoomRid
        INNER JOIN dbo.mHotel h ON h.RowID = resp_log.wHotelRid
        LEFT JOIN dbo.mHotelRoom hr ON hr.RowID = resp_log.wRoomRid
        LEFT JOIN dbo.eBooking eb ON eb.RowID = resp_log.wBookingRid
        LEFT JOIN RollsMary.dbo.mUsr upd ON upd.RowID = resp_log.wUpdBy
        WHERE resp_log.wRecStatus = 'A'
            AND resp.RowID = @pDeptRespRoomRid;

    END