

CREATE VIEW [mdRpt].[vwAirTicketData]
AS
    WITH tDepartment AS (
        SELECT DISTINCT 
            wDeptCode = wCode,
            wDeptName = wCName
        FROM RollsMary.[mdRpt].[vwDepartment]
        WHERE wIsRealDept = 'Y' AND NULLIF(wUserLineGrp, '') IS NULL AND wActive = 'A'
    ),
    tAirRouteDtl AS (
        SELECT 
            RowID, 
            wTypeRid, 
            wLine, 
            wFlightType, 
            wClassCd, 
            wAirline, 
            wIsReturn, 
            wDepartureAirportRid, 
            wArrivalAirportRid,
            wTakeOffDt,
            wArrivalDt,
            wDepartFlightNo
        FROM CRM.dbo.eAirTicketRouteDtl WHERE wType = 'AIRTICKET' AND wStatus = 'A'
    ),
    tNotReturnAirRouteDtl AS (
        SELECT * FROM tAirRouteDtl WHERE wIsReturn = 'N'
    ),
    tFirstReturnAirRouteDtl AS (
        SELECT
            wTypeRid,
            wLine = MIN(wLine)
        FROM tAirRouteDtl WHERE wIsReturn = 'Y' AND wLine != 1 GROUP BY wTypeRid
    ),
    tReturnAirRouteDtl AS (
        SELECT ard.*
        FROM tAirRouteDtl AS ard
        INNER JOIN tFirstReturnAirRouteDtl AS frard ON frard.wTypeRid = ard.wTypeRid AND frard.wLine = ard.wLine
        WHERE ard.wIsReturn = 'Y'
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
        DebitServiceCounter=sc.wName, 
        ReqAgentCode_Display = reqA.wAgentCode_Display,
        ReqAgentCodeByName = reqA.wCName,
        DebitAgentCode_Display = debitA.wAgentCode_Display,
        DebitAgentCodeByName = debitA.wCName,
        ReqDepartment = reqDept.wDeptName,
        ReqUsr = reqUsr.wCName,
        AsstBooker = eb.wAsstBooker,
        OrderNo = bat.wOrderNo ,
        FlightType=flightType.wTitle,
        FirstTakeOffDt =CONVERT(VARCHAR(100), dptAP.wTakeOffDt, 120) ,
        FirstDepartFlightNo = dptAP.wDepartFlightNo ,
        SecondTakeOffDt =CONVERT(VARCHAR(100), ISNULL(rtnAP.wTakeOffDt, secAP.wTakeOffDt), 120)  ,
        SecondDepartFlightNo = ISNULL(rtnAP.wDepartFlightNo, secAP.wDepartFlightNo),
        Airline=airline.wTitle ,
        Client = bm.wValue,
        ClassCdByName=class.wTitle,
        TotalAmt=bat.wTotalAmt ,
        Payment=payment.wTitle,
        TravelAgencyRidByName = ta.wName,
        RequestedServiceCounter = msc.wName,
        FollowedDepartment = followDept.wDeptName,
        FollowedStaff = followUsr.wCName,
        DepositAmt=eb.wDepositAmt ,
        UpdByCName = usr.wCName,
        UpdDt=CONVERT(VARCHAR(100), bat.wUpdDt, 120),
        BookingStatus = bs.wTitle,
        EventCodeByName =mec.wCName
    FROM dbo.eBookingAirTicket AS bat
    INNER JOIN dbo.eBooking AS eb ON eb.RowID = bat.wBookingRid
    LEFT JOIN tServiceCunter sc ON sc.RowID = eb.wDebitCounterRid
    LEFT JOIN tServiceCunter msc ON msc.RowID = eb.wReqCounterRid
    LEFT JOIN tAgent AS reqA ON reqA.wAgentCodeIn = eb.wReqAgentCodeIn
    LEFT JOIN tAgent AS debitA ON debitA.wAgentCodeIn = eb.wDebitAgentCodeIn
    LEFT JOIN tDepartment AS reqDept ON reqDept.wDeptCode = eb.wReqDepartment
    LEFT JOIN tDepartment AS followDept ON followDept.wDeptCode = eb.wDeptFollwedCd
    LEFT JOIN tUsr AS reqUsr ON reqUsr.RowID = eb.wReqUserRid
    LEFT JOIN tUsr AS followUsr ON followUsr.RowID = eb.wStaffFollwedRid
    LEFT JOIN tUsr AS usr ON usr.RowID = bat.wUpdBy
    LEFT JOIN dbo.mLookUp AS flightType ON bat.wFlightType = flightType.wCode AND flightType.wType = 'AIR_TICKET_TYPE' AND flightType.wLangCd = 'zh-tw'
    LEFT JOIN tNotReturnAirRouteDtl AS dptAP ON dptAP.wLine = 1 AND dptAP.wTypeRid = bat.RowID
    LEFT JOIN tNotReturnAirRouteDtl AS secAP ON secAP.wLine = 2 AND secAP.wTypeRid = bat.RowID
    LEFT JOIN tReturnAirRouteDtl rtnAP ON rtnAP.wTypeRid = bat.RowID
    LEFT JOIN dbo.mLookUp AS airline ON dptAP.wAirline = airline.wCode AND airline.wType = 'AIRLINES' AND airline.wLangCd = 'zh-tw'
    LEFT JOIN stg.eBookingMisc bm ON bm.wBookingRid = bat.wBookingRid AND bm.wLangCd = 'zh-tw' AND bm.wItemCd = 'CUST_NAME'
    LEFT JOIN dbo.mLookUp AS class ON dptAP.wClassCd = class.wCode AND class.wType = 'AIR_CLASS' AND class.wLangCd = 'zh-tw'
    LEFT JOIN dbo.mLookUp AS payment ON bat.wPaymentMethod = payment.wCode AND payment.wType = 'PAYMENT_TYPE' AND payment.wLangCd = 'zh-tw'
    LEFT JOIN dbo.mTravelAgency ta ON ta.RowID = bat.wTravelAgencyRid
    LEFT JOIN dbo.mLookUp AS bs ON bat.wBookingStatus  = bs.wCode AND bs.wType = 'AIR_TICKET_BOOKING_STATUS' AND bs.wLangCd = 'zh-tw'
    LEFT JOIN dbo.mEventCode mec ON mec.RowID = eb.wEventCodeRid