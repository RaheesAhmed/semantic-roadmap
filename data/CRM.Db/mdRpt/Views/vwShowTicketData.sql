
CREATE VIEW [mdRpt].[vwShowTicketData]
AS
    WITH tDepartment AS (
        SELECT DISTINCT 
            wDeptCode = wCode,
            wDeptName = wCName
        FROM RollsMary.[mdRpt].[vwDepartment]
        WHERE wIsRealDept = 'Y' AND NULLIF(wUserLineGrp, '') IS NULL AND wActive = 'A'
    ),
    tUsr AS (
        SELECT RowID, wCName FROM RollsMary.[mdRpt].[vwUsr]
    ),
    tAgent AS (
        SELECT wAgentCodeIn, wAgentCode_Display, wCName FROM Rollsmary.[mdRpt].[vwAgent]
    ),
    tServiceCunter AS (
        SELECT RowID, wName FROM dbo.mServiceCounter
    )

    SELECT
        ReservationNo = eb.wRefNo,
        TicCollPointByName = mtc.wName,
        IsCollected = IIF( tc.wIsCollected = 'true',  N'√',  ''),
        HaveTicket = IIF( ebs.wHaveTicket = 'Y',  N'√',  ''),
        ReservationDt =  CONVERT(VARCHAR(100), eb.wDebitDt, 120),
        DebitServiceCounterName = SC.wName,
        ReqDepartment = reqDept.wDeptName,
        ReqUsr = reqUsr.wCName,
        FollowedDepartment = followDept.wDeptName,
        FollowedStaff = followUsr.wCName,
        DebitAgentCode_Display = debitA.wAgentCode_Display,
        DebitAgentCodeByName = debitA.wCName,
        ReqAgentCode_Display = reqA.wAgentCode_Display,
        ReqAgentCodeByName = reqA.wCName,
        AsstBooker = eb.wAsstBooker,
        AssBookerTel = eb.wAssBookerTel,
        OrderNo = ebs.wOrderNo,
        ShowName = ms.wName,
        OtherName = ebs.wOtherName,
        ShowDt = CONVERT(VARCHAR(100), ebs.wShowDt, 120),
        TotalQuantity = ebs.wTotalQuantity,
        TotalAmt = ebs.wTotalAmt,
        TravelAgencyRidByName = ta.wName,
        RequestedServiceCounterName = msc.wName,
        BookingStatus = bs.wTitle,
        UpdByCName = usr.wCName,
        UpdDt=CONVERT(VARCHAR(100), ebs.wUpdDt, 120),
        EventCodeByName = mec.wCName
    FROM dbo.eBookingShow AS ebs 
    INNER JOIN dbo.eBooking AS eb ON eb.RowID = ebs.wBookingRid
    INNER JOIN tServiceCunter AS SC ON SC.RowID = eb.wDebitCounterRid
    LEFT JOIN tServiceCunter AS msc ON msc.RowID = eb.wReqCounterRid
    LEFT JOIN dbo.eTicketCollection AS tc ON tc.wBookingRid = ebs.wBookingRid
    LEFT JOIN dbo.mTicketCollectionPoint AS mtc ON mtc.wCode = tc.wTicCollPoint
    LEFT JOIN tDepartment AS reqDept ON reqDept.wDeptCode = eb.wReqDepartment
    LEFT JOIN tDepartment AS followDept ON followDept.wDeptCode = eb.wDeptFollwedCd
    LEFT JOIN tUsr AS reqUsr ON reqUsr.RowID = eb.wReqUserRid
    LEFT JOIN tUsr AS followUsr ON followUsr.RowID = eb.wStaffFollwedRid
    LEFT JOIN tUsr AS usr ON usr.RowID = ebs.wUpdBy
    LEFT JOIN tAgent AS reqA ON reqA.wAgentCodeIn = eb.wReqAgentCodeIn
    LEFT JOIN tAgent AS debitA ON debitA.wAgentCodeIn = eb.wDebitAgentCodeIn
    LEFT JOIN dbo.mShow AS ms ON ms.RowID = ebs.wShowRid
    LEFT JOIN dbo.mTravelAgency AS ta ON ta.RowID = ebs.wTravelAgencyRid
    LEFT JOIN dbo.mLookUp AS bs ON ebs.wBookingStatus  = bs.wCode AND bs.wType = 'PERFORMANCE_TICKET_STATUS' AND bs.wLangCd = 'zh-tw'
    LEFT JOIN dbo.mEventCode mec ON mec.RowID = eb.wEventCodeRid