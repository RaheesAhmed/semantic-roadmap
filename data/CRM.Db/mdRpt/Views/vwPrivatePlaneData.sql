


CREATE VIEW [mdRpt].[vwPrivatePlaneData]
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
    ),
    tAirPort AS (
        SELECT RowID, wCode, wName = wCName, wCity FROM dbo.mAirport
    ),
    tPPRoute AS (
        SELECT 
            wBookingPrivatePlaneRid, 
            wLine, 
            wCityCd, 
            wIsReturn, 
            wDepartureAirportRid, 
            wArrivalAirportRid, 
            wTakeOffDt, 
            wArrivalDt  
        FROM dbo.ePrivatePlaneRouteDtl WHERE wStatus = 'A'
    ),
    tDepartureRoute AS (
        SELECT 
            r.*,
            a.wCode,
            a.wName,
            a.wCity
        FROM tPPRoute AS r
        LEFT JOIN tAirport AS a ON a.RowID = r.wDepartureAirportRid
        WHERE r.wLine = 1
    ),
    tDestRoute AS (
        SELECT
            dest.*,
            a.wCode,
            a.wName,
            a.wCity
        FROM (SELECT wBookingPrivatePlaneRid , MAX(wLine) AS wLine FROM tPPRoute WHERE wIsReturn != 'Y' GROUP BY wBookingPrivatePlaneRid) AS gdest
        INNER JOIN tPPRoute AS dest ON dest.wBookingPrivatePlaneRid = gdest.wBookingPrivatePlaneRid AND dest.wLine = gdest.wLine
        LEFT JOIN tAirport AS a ON a.RowID = dest.wArrivalAirportRid
    )

    SELECT
        ReservationNo = eb.wRefNo, 
        ReservationDt = FORMAT(eb.wDebitDt, 'yyyy-MM-dd'),
        DebitServiceCounterName = sc.wName ,
        OrderNo = pp.wOrderNo ,
        ReqAgentCode_Display = reqA.wAgentCode_Display,
        ReqAgentCodeByName = reqA.wCName,
        DebitAgentCode_Display = debitA.wAgentCode_Display,
        DebitAgentCodeByName = debitA.wCName,
        ReqDepartment = reqDept.wDeptName,
        ReqUsr = reqUsr.wCName,
        Payment = payment.wTitle,
        AsstBooker = eb.wAsstBooker ,
        TakeOffDt = CONVERT(VARCHAR(100), dpt.wTakeOffDt, 120),
        ArrivalDt = CONVERT(VARCHAR(100), dest.wArrivalDt, 120),
        Client = bm.wValue,
        TotalAmt = pp.wTotalAmt ,
        SupplierByName = CASE pp.wSupplier WHEN 'HO' THEN ho.wName WHEN 'TA' THEN ta.wName ELSE NULL END,
        RequestedServiceCounterName = msc.wName ,
        FollowedDepartment = followDept.wDeptName,
        FollowedStaff = followUsr.wCName,
        UpdByCName = usr.wCName,
        UpdDt=CONVERT(VARCHAR(100), pp.wUpdDt, 120),
        DepositAmt = eb.wDepositAmt ,
        EventCodeByName = mec.wCName
    FROM dbo.eBookingPrivatePlane AS pp 
    INNER JOIN dbo.eBooking AS eb ON eb.RowID = pp.wBookingRid
    LEFT JOIN tServiceCunter AS sc ON sc.RowID = eb.wDebitCounterRid
    LEFT JOIN tServiceCunter AS msc ON msc.RowID = eb.wReqCounterRid
    LEFT JOIN tAgent AS reqA ON reqA.wAgentCodeIn = eb.wReqAgentCodeIn
    LEFT JOIN tAgent AS debitA ON debitA.wAgentCodeIn = eb.wDebitAgentCodeIn
    LEFT JOIN tDepartment AS reqDept ON reqDept.wDeptCode = eb.wReqDepartment
    LEFT JOIN tDepartment AS followDept ON followDept.wDeptCode = eb.wDeptFollwedCd
    LEFT JOIN tUsr AS reqUsr ON reqUsr.RowID = eb.wReqUserRid
    LEFT JOIN tUsr AS followUsr ON followUsr.RowID = eb.wStaffFollwedRid
    LEFT JOIN tUsr AS usr ON usr.RowID = pp.wUpdBy
    LEFT JOIN dbo.mLookUp AS payment ON pp.wPaymentMethod = payment.wCode AND payment.wType = 'PAYMENT_TYPE' AND payment.wLangCd = 'zh-tw'
    LEFT JOIN tDepartureRoute AS dpt ON dpt.wBookingPrivatePlaneRid = pp.RowID
    LEFT JOIN tDestRoute AS dest ON dest.wBookingPrivatePlaneRid = pp.RowID
    LEFT JOIN stg.eBookingMisc bm ON bm.wBookingRid = pp.wBookingRid AND bm.wLangCd = 'zh-tw' AND bm.wItemCd = 'CUST_NAME'
    LEFT JOIN dbo.mHotel ho ON ho.RowID = pp.wHotelRid
    LEFT JOIN dbo.mTravelAgency ta ON ta.RowID = pp.wTravelAgencyRid
    LEFT JOIN dbo.mEventCode mec ON mec.RowID = eb.wEventCodeRid