
CREATE VIEW [mdRpt].[vwFerryData]
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
        ReservationDt = FORMAT(eb.wDebitDt, 'yyyy-MM-dd'), 
        ReqAgentCode_Display = reqA.wAgentCode_Display, 
        ReqAgentCodeByName = reqA.wCName,
        DebitAgentCode_Display = debitA.wAgentCode_Display,
        DebitAgentCodeByName = debitA.wCName,
        AsstBooker=eb.wAsstBooker,
        AssBookerTel=eb.wAssBookerTel,
        OrderNo=bf.wOrderNo,
        TicketType=tt.wTitle,
        FerryRoute= CASE WHEN r.wIsTwoWay = 'Y' THEN lpFrom.wTitle + '<->' + lpTo.wTitle ELSE lpFrom.wTitle + '->' + lpTo.wTitle END,
        DepartDt = CONVERT(VARCHAR(100), bf.wDepartDt, 120),
        ClassCdByName = classType.wTitle, 
        UnitAmt=bf.wUnitAmt,
        Quantity=bf.wQuantity,
        TotalAmt=bf.wTotalAmt,
        Payment = payment.wTitle,
        Remark=bf.wRemark,
        TicCollPointByName=mtc.wName,
        IsCollected=IIF( tc.wIsCollected = 'TRUE',  'Y',  'N'),
        DepositAmt=eb.wDepositAmt,
        ReqDepartment = reqDept.wDeptName,
        FollowedDepartment = followDept.wDeptName,
        FollowedStaff = followUsr.wCName,
        UpdByCName=usr.wCName,
        UpdDt=CONVERT(VARCHAR(100), bf.wUpdDt, 120),
        BookingStatus = bs.wTitle
    FROM dbo.eBookingFerry AS bf 
    INNER JOIN dbo.eBooking AS eb ON bf.wBookingRid = eb.RowID
    LEFT JOIN dbo.mRoute r ON r.RowID = bf.wRouteRid
    LEFT JOIN dbo.mLookUp AS lpTo ON lpTo.wCode = r.wRouteTo AND lpTo.wLangCd = 'zh-tw' 
                                     AND ( r.wVehicle = 'FERRY' AND lpTo.wType = 'FERRY_ROUTE_LOCATION' )
    LEFT JOIN dbo.mLookUp AS lpFrom ON lpFrom.wCode = r.wRouteFrom AND lpFrom.wLangCd = 'zh-tw'
                                       AND ( r.wVehicle = 'FERRY' AND lpFrom.wType = 'FERRY_ROUTE_LOCATION' )
    LEFT JOIN dbo.mLookUp AS tt ON bf.wTicketType = tt.wCode AND tt.wType = 'FERRY_TICKET_TYPE' AND tt.wLangCd = 'zh-tw'
    LEFT JOIN tAgent AS reqA ON reqA.wAgentCodeIn = eb.wReqAgentCodeIn
    LEFT JOIN tAgent AS debitA ON debitA.wAgentCodeIn = eb.wDebitAgentCodeIn
    LEFT JOIN dbo.mLookUp AS classType ON bf.wClassCd = classType.wCode AND classType.wType = 'FERRY_CLASS' AND classType.wLangCd = 'zh-tw'
    LEFT JOIN dbo.mLookUp AS payment ON bf.wPaymentMethod = payment.wCode AND payment.wType = 'PAYMENT_TYPE' AND payment.wLangCd = 'zh-tw'
    LEFT JOIN dbo.eTicketCollection tc ON tc.wBookingRid = bf.wBookingRid
    LEFT JOIN dbo.mTicketCollectionPoint mtc ON mtc.wCode = tc.wTicCollPoint AND mtc.wIsFerryTic = 'Y'
    LEFT JOIN tDepartment AS reqDept ON reqDept.wDeptCode = eb.wReqDepartment
    LEFT JOIN tDepartment AS followDept ON followDept.wDeptCode = eb.wDeptFollwedCd
    LEFT JOIN tUsr AS followUsr ON followUsr.RowID = eb.wStaffFollwedRid
    LEFT JOIN tUsr AS usr ON usr.RowID = bf.wUpdBy
    LEFT JOIN dbo.mLookUp AS bs ON bf.wBookingStatus = bs.wCode AND bs.wType = 'FERRY_STATUS' AND bs.wLangCd = 'zh-tw'