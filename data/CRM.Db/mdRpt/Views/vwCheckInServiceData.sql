


CREATE VIEW [mdRpt].[vwCheckInServiceData]
AS
    WITH tDepartment AS (
        SELECT DISTINCT 
            wDeptCode = wCode,
            wDeptName = wCName
        FROM RollsMary.[mdRpt].[vwDepartment]
        WHERE wIsRealDept = 'Y' AND NULLIF(wUserLineGrp, '') IS NULL AND wActive = 'A'
    ),
    tServiceCunter AS (
        SELECT RowID, wName FROM dbo.mServiceCounter
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
        DebitServiceCounterName = SC.wName ,
        OrderNo = ecis.wOrderNo ,
        ReqAgentCode_Display = reqA.wAgentCode_Display,
        ReqAgentCodeByName = reqA.wCName,
        DebitAgentCode_Display = debitA.wAgentCode_Display,
        DebitAgentCodeByName = debitA.wCName,
        ReqDepartment = reqDept.wDeptName,
        ReqUsr = reqUsr.wCName,
        AsstBooker = eb.wAsstBooker ,
        Payment = payment.wTitle,
        DepartDt = CONVERT(VARCHAR(100), ecis.wDepartDt, 120),
        FlightNo = ecis.wFlightNo,
        ArrivalTimeToG15nG16 = CONVERT(VARCHAR(100), ecis.wArrivalTimeToG15nG16, 120) ,
        Quantity = CAST(ecis.wQuantity AS INT),
        RequestedServiceCounterName = msc.wName,
        FollowedDepartment = followDept.wDeptName,
        FollowedStaff = followUsr.wCName,
        VIPRoom = IIF( ecis.wVIPRoom = 'Y',  N'√',  ''),
        TotalAmt = ecis.wTotalAmt,
        Client = bm.wValue,
        TicCollPointByName = mtc.wName,
        DepositAmt = eb.wDepositAmt,
        TravelAgencyRidByName = ta.wName ,
        BookingStatus = bs.wTitle,
        UpdByCName = usr.wCName,
        UpdDt=CONVERT(VARCHAR(100), ecis.wUpdDt, 120),
        EventCodeByName = mec.wCName
    FROM dbo.eBookingCheckInService AS ecis
    INNER JOIN dbo.eBooking AS eb ON eb.RowID = ecis.wBookingRid
    INNER JOIN tServiceCunter AS SC ON SC.RowID = eb.wDebitCounterRid
    LEFT JOIN tServiceCunter AS msc ON msc.RowID = eb.wReqCounterRid
    LEFT JOIN tAgent AS reqA ON reqA.wAgentCodeIn = eb.wReqAgentCodeIn
    LEFT JOIN tAgent AS debitA ON debitA.wAgentCodeIn = eb.wDebitAgentCodeIn
    LEFT JOIN tDepartment AS reqDept ON reqDept.wDeptCode = eb.wReqDepartment
    LEFT JOIN tDepartment AS followDept ON followDept.wDeptCode = eb.wDeptFollwedCd
    LEFT JOIN tUsr AS reqUsr ON reqUsr.RowID = eb.wReqUserRid
    LEFT JOIN tUsr AS followUsr ON followUsr.RowID = eb.wStaffFollwedRid
    LEFT JOIN tUsr AS usr ON usr.RowID = ecis.wUpdBy
    LEFT JOIN dbo.mLookUp AS payment ON ecis.wPaymentMethod = payment.wCode AND payment.wType = 'PAYMENT_TYPE' AND payment.wLangCd = 'zh-tw'
    LEFT JOIN dbo.eTicketCollection AS tc ON tc.wBookingRid = ecis.wBookingRid
    LEFT JOIN dbo.mTicketCollectionPoint AS mtc ON mtc.wCode = tc.wTicCollPoint
    LEFT JOIN dbo.mTravelAgency ta ON ta.RowID = ecis.wSupplier
    LEFT JOIN dbo.mLookUp AS bs ON ecis.wBookingStatus  = bs.wCode AND bs.wType = 'BOARDING_SERVICE_BOOKING_STATUS' AND bs.wLangCd = 'zh-tw'
    LEFT JOIN dbo.mEventCode mec ON mec.RowID = eb.wEventCodeRid
    LEFT JOIN stg.eBookingMisc bm ON bm.wBookingRid = ecis.wBookingRid AND bm.wLangCd = 'zh-tw' AND bm.wItemCd = 'CUST_NAME'