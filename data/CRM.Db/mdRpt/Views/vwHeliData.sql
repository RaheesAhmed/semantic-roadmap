

CREATE VIEW [mdRpt].[vwHeliData]
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
    )

    SELECT
        ReservationNo = eb.wRefNo, 
        ReservationDt = CONVERT(VARCHAR(100), eb.wDebitDt, 120), 
        DebitServiceCounter=sc.wName,
        ReqAgentCode_Display = reqA.wAgentCode_Display,
        ReqAgentCodeByName = reqA.wCName,
        DebitAgentCode_Display = debitA.wAgentCode_Display,
        DebitAgentCodeByName = debitA.wCName,
        AsstBooker = eb.wAsstBooker ,
        AssBookerTel = eb.wAssBookerTel ,
        OrderNo = ebh.wOrderNo ,
        BookingLocation = l.wTitle,
        DepartDt =CONVERT(VARCHAR(100), ebh.wDepartDt, 120),
        Quantity = ebh.wQuantity ,
        TotalAmt = ebh.wTotalAmt,
        Payment = payment.wTitle,
        Remark = ebh.wRemark ,
        IsCharteredFlight = ebh.wIsCharteredFlight ,
        ReqDepartment = reqDept.wDeptName,
        ReqUsr = reqUsr.wCName,
        FollowedDepartment = followDept.wDeptName,
        FollowedStaff = followUsr.wCName,
        UpdByCName=usr.wCName,
        UpdDt=CONVERT(VARCHAR(100), ebh.wUpdDt, 120),
        BookingStatus = bs.wTitle,
        EventCodeByName = mec.wCName
    FROM dbo.eBookingHeli AS ebh
    INNER JOIN dbo.eBooking AS eb ON eb.RowID = ebh.wBookingRid AND ebh.wStatus = 'A'
    LEFT JOIN dbo.mServiceCounter sc ON sc.RowID = eb.wDebitCounterRid
    LEFT JOIN tAgent AS reqA ON reqA.wAgentCodeIn = eb.wReqAgentCodeIn
    LEFT JOIN tAgent AS debitA ON debitA.wAgentCodeIn = eb.wDebitAgentCodeIn
    LEFT JOIN dbo.mLookUp AS l ON ebh.wBookingLocation = l.wCode AND l.wType = 'HELICOPTER_BOOKING_LOCATION' AND l.wLangCd = 'zh-tw'
    LEFT JOIN dbo.mLookUp AS payment ON ebh.wPaymentMethod = payment.wCode AND payment.wType = 'PAYMENT_TYPE' AND payment.wLangCd = 'zh-tw'
    LEFT JOIN tDepartment AS reqDept ON reqDept.wDeptCode = eb.wReqDepartment
    LEFT JOIN tDepartment AS followDept ON followDept.wDeptCode = eb.wDeptFollwedCd
    LEFT JOIN tUsr AS reqUsr ON reqUsr.RowID = eb.wReqUserRid
    LEFT JOIN tUsr AS followUsr ON followUsr.RowID = eb.wStaffFollwedRid
    LEFT JOIN tUsr AS usr ON usr.RowID = ebh.wUpdBy
    LEFT JOIN dbo.mLookUp AS bs ON ebh.wBookingStatus = bs.wCode AND bs.wType = 'HELICOPTER_BOOKING_STATUS' AND bs.wLangCd = 'zh-tw'
    LEFT JOIN dbo.mEventCode mec ON mec.RowID = eb.wEventCodeRid