
CREATE VIEW [mdRpt].[vwRestaurantData]
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
        ReservationDt = FORMAT(eb.wDebitDt, 'yyyy-MM-dd'), 
        DebitServiceCounter=sc.wName, 
        RequestedServiceCounter = msc.wName,
        ReqAgentCode_Display = reqA.wAgentCode_Display,
        ReqAgentCodeByName = reqA.wCName,
        DebitAgentCode_Display = debitA.wAgentCode_Display,
        DebitAgentCodeByName = debitA.wCName,
        ReqDepartment = reqDept.wDeptName,
        ReqUsr = reqUsr.wCName,
        FollowedDepartment = followDept.wDeptName,
        FollowedStaff = followUsr.wCName,
        AsstBooker = eb.wAsstBooker,
        AssBookerTel = eb.wAssBookerTel,
        ReserveName = erb.wReserveName,
        ReservePhoneNo = erb.wReservePhoneNo,
        RestName = mrs.wName,
        BookingDt = FORMAT(erb.wBookingDt, 'yyyy-MM-dd'),
        DiningArea= erb.wDiningArea,
        NoOfPpl = erb.wNoOfPpl,
        IsMinCharge= IIF( erb.wIsMinCharge = 'Y',  N'√',  ''),
        MinCharge = erb.wMinCharge,
        Remark = erb.wRemark,
        BookingStatus = bs.wTitle,
        CrtDt=FORMAT(erb.wCrtDt, 'yyyy-MM-dd'),
        UpdByCName = usr.wCName,
        UpdDt=FORMAT(erb.wUpdDt, 'yyyy-MM-dd'),
        EventCodeByName =mec.wCName
    FROM dbo.eBookingRestaurant AS erb
    INNER JOIN dbo.eBooking AS eb ON eb.RowID = erb.wBookingRid
    LEFT JOIN tServiceCunter sc ON sc.RowID = eb.wDebitCounterRid
    LEFT JOIN tServiceCunter msc ON msc.RowID = eb.wReqCounterRid
    LEFT JOIN tAgent AS reqA ON reqA.wAgentCodeIn = eb.wReqAgentCodeIn
    LEFT JOIN tAgent AS debitA ON debitA.wAgentCodeIn = eb.wDebitAgentCodeIn
    LEFT JOIN tDepartment AS reqDept ON reqDept.wDeptCode = eb.wReqDepartment
    LEFT JOIN tDepartment AS followDept ON followDept.wDeptCode = eb.wDeptFollwedCd
    LEFT JOIN tUsr AS reqUsr ON reqUsr.RowID = eb.wReqUserRid
    LEFT JOIN tUsr AS followUsr ON followUsr.RowID = eb.wStaffFollwedRid
    LEFT JOIN tUsr AS usr ON usr.RowID = erb.wUpdBy
    LEFT JOIN dbo.mRestaurant AS mrs ON mrs.RowID = erb.wRestaurantRid
    LEFT JOIN dbo.mLookUp AS bs ON erb.wBookingStatus  = bs.wCode AND bs.wType = 'RESTAURANT_BOOKING_STATUS' AND bs.wLangCd = 'zh-tw'
    LEFT JOIN dbo.mEventCode mec ON mec.RowID = eb.wEventCodeRid