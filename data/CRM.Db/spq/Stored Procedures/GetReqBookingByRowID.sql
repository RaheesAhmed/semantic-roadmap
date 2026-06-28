CREATE PROC [spq].[GetReqBookingByRowID]
    @pRowID     BIGINT,
    @pLangCd    VARCHAR(10) = 'zh-TW'
AS
    BEGIN
        SET NOCOUNT ON;

        SELECT rb.RowID,
               wGUID = CONVERT(VARCHAR(100), rb.wGUID),
               rb.wBookingType,
               rb.wRefNo,
               rb.wAgentCodeIn,
               ma.wAgentCode_Display,
               wAgentCName = ma.wCName,
               wAgentEName = ma.wEName,
               wAgentNickName = ma.wNickName,
               rb.wReqDeptCd,
               rb.wReqUserRid,
               wReqUserName = CONCAT(ISNULL(req_mu.wCName, ''), IIF(ISNULL(req_mu.wCName, '') = '' OR ISNULL(req_mu.wName, '') = '', '', CHAR(10)), ISNULL(req_mu.wName, '')),
               rb.wFollowDeptCd,
               rb.wFollowUserRid,
               wFollowUserName = CONCAT(ISNULL(fol_mu.wCName, ''), IIF(ISNULL(fol_mu.wCName, '') = '' OR ISNULL(fol_mu.wName, '') = '', '', CHAR(10)), ISNULL(fol_mu.wName, '')),
               rb.wReqStatus,
               wCrtDt = FORMAT(rb.wCrtDt, 'yyyy-MM-dd HH:mm:ss'),
               wUpdDt = FORMAT(rb.wUpdDt,  'yyyy-MM-dd HH:mm:ss'),
               wDetail = CONVERT(XML, '<Detail/>')
        INTO #vResult
        FROM dbo.eReqBooking rb
        INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = rb.wAgentCodeIn
        LEFT JOIN RollsMary.dbo.mUsr req_mu ON req_mu.RowID = rb.wReqUserRid
        LEFT JOIN RollsMary.dbo.mUsr fol_mu ON fol_mu.RowID = rb.wFollowUserRid
        WHERE rb.wStatus = 'A'
            AND rb.RowID = @pRowID;

        IF EXISTS (SELECT 1 FROM #vResult WHERE wBookingType = 'HOTEL')
        BEGIN
            UPDATE r
            SET wDetail = ISNULL((
                SELECT RowID,
                       wGUID,
                       wHotelRid,
                       wHotelRoomRid,
                       wCheckInDate = FORMAT(wCheckInDate, 'yyyy-MM-dd'),
                       wCheckOutDate = FORMAT(wCheckOutDate, 'yyyy-MM-dd'),
                       wBigBedRoomQty,
                       wTwinBedRoomQty,
                       wSuiteRoom1Qty,
                       wSuiteRoom2Qty,
                       wSuiteRoom3Qty,
                       wRemark
                FROM dbo.eReqBookingHotel 
                WHERE wStatus = 'A'
                    AND wReqBookingRid = r.RowID 
                FOR XML RAW('Detail')
            ), '<Detail/>')
            FROM #vResult r
        END

        SELECT * FROM #vResult;

        IF OBJECT_ID('tempdb..#vResult')  IS NOT NULL
            DROP TABLE #vResult;
    END