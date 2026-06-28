CREATE PROC [spq].[GetSMSDeptRespRoomRemind]
    @pDeptRespRoomRid   BIGINT,
    @pLangCd            VARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');
        SET @pDeptRespRoomRid = ISNULL(IIF(@pDeptRespRoomRid < 0, NULL, @pDeptRespRoomRid), 0);

        DECLARE @vRequestStatus TABLE (
            wCode   VARCHAR(30),
            wTitle  NVARCHAR(50),
            PRIMARY KEY(wCode, wTitle)
        );

        INSERT INTO @vRequestStatus(wCode, wTitle)
        SELECT wCode, wTitle
        FROM dbo.mLookUp
        WHERE wType = 'DEPTROOM_RESPONSE_STATUS' AND wLangCd = @pLangCd;

        DECLARE @vDeptStatus TABLE (
            wCode   VARCHAR(30),
            wTitle  NVARCHAR(50),
            PRIMARY KEY(wCode, wTitle)
        );

        INSERT INTO @vDeptStatus(wCode, wTitle)
        SELECT wCode, wTitle
        FROM dbo.mLookUp
        WHERE wType = 'DEPTROOM_PROCESS_STATUS' AND wLangCd = @pLangCd;

        SELECT 
            ma.wAgentCodeIn,
            ma.wAgentCode_Display,
            wAgentName = IIF(@pLangCd = 'en-GB', ma.wEName, ma.wCName),
            req.wRequestNo, -- 需求編號,
            wHotelRefNo = eb.wRefNo, -- 酒店單編號
            wHotelName = ISNULL(mh.wName, ''),
            wHotelRoomName = ISNULL(mhr.wName, ''),
            wRoomCount = resp.wBigBedQty + resp.wTwinBedQty + resp.wSuiteRoom1Qty + resp.wSuiteRoom1Qty + resp.wSuiteRoom2Qty + resp.wSuiteRoom3Qty, -- 房間數量
            wCheckInDate = FORMAT(resp.wStartDate, 'yyyy-MM-dd'),
            wCheckOutDate = FORMAT(resp.wEndDate, 'yyyy-MM-dd'),
            wRequestStatus = ISNULL(rs.wTitle, ''), -- 需求狀態
            wDeptStatus = ISNULL(ds.wTitle, ''), -- 部門狀態
            resp.wCancelReason, -- 取消原因
            wUpdDt = FORMAT(resp.wUpdDt, 'yyyy-MM-dd HH:mm:ss'),
            wStaffName = mu.wName,
            wStaffTel = IIF(NULLIF(mu.wPrivateTelCountryCode, '') IS NULL, '', IIF(CHARINDEX('+', mu.wPrivateTelCountryCode) > 0, '', '+') + mu.wPrivateTelCountryCode + '-') + ISNULL(mu.wPrivateTel, '') -- 跟進同事電話
        FROM dbo.eDeptRespRoom resp
        INNER JOIN dbo.eDeptReqRoom req ON req.RowID = resp.wDeptReqRoomRid
        INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = req.wAgentCodeIn
        LEFT JOIN dbo.mHotel mh ON mh.RowID = resp.wHotelRid
        LEFT JOIN dbo.mHotelRoom mhr ON mhr.RowID = resp.wRoomRid
        LEFT JOIN dbo.eBooking eb ON eb.RowID = resp.wBookingRid
        LEFT JOIN RollsMary.dbo.mUsr mu ON mu.RowID = req.wStaffFollowedRid
        LEFT JOIN @vRequestStatus rs ON rs.wCode = resp.wRepStatus
        LEFT JOIN @vDeptStatus ds ON ds.wCode = resp.wDeptStatus
        WHERE resp.RowID = @pDeptRespRoomRid;
    END