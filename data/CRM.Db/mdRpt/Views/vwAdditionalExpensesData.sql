

CREATE VIEW [mdRpt].[vwAdditionalExpensesData]
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
        DebitServiceCounter=sc.wName,
        ReqAgentCode_Display = reqA.wAgentCode_Display,
        ReqAgentCodeByName = reqA.wCName,
        DebitAgentCode_Display = debitA.wAgentCode_Display,
        DebitAgentCodeByName = debitA.wCName,
        AsstBooker = eb.wAsstBooker,
        OrderNo = ae.wOrderNo ,
        TotalAmt = ae.wTotalAmt, 
        ExpenseTypeName = et.wName, 
        ExpenseSubtypeName = est.wName ,
        RestaurantName = r.wName,
        Payment = payment.wTitle,
        ParentRefNo = b.wRefNo,
        ReqDepartment = reqDept.wDeptName,
        ReqUsr = reqUsr.wCName,
        FollowedDepartment = followDept.wDeptName,
        FollowedStaff = followUsr.wCName,
        UpdByCName = usr.wCName,
        UpdDt = FORMAT(ae.wUpdDt, 'yyyy-MM-dd HH:mm:ss'),
        BookingStatus = bs.wTitle,
        EventCodeByName =mec.wCName
    FROM dbo.eAdditionalExpense AS ae 
    INNER JOIN dbo.eBooking AS eb ON eb.RowID = ae.wBookingRefRid AND ae.wStatus = 'A'
    INNER JOIN dbo.mServiceCounter sc ON sc.RowID = eb.wDebitCounterRid
    LEFT JOIN dbo.mExpenseType et ON et.RowID = ae.wExpenseType 
    LEFT JOIN dbo.mExpenseSubtype est ON est.RowID = ae.wExpenseSubtype
    LEFT JOIN dbo.mRestaurant r ON r.RowID = ae.wRestaurantRid
    LEFT JOIN dbo.mLookUp AS payment ON ae.wPaymentMethod = payment.wCode AND payment.wType = 'PAYMENT_TYPE' AND payment.wLangCd = 'zh-tw'
    LEFT JOIN dbo.eBooking b ON b.RowID = ae.wBookingRid
    LEFT JOIN tAgent AS reqA ON reqA.wAgentCodeIn = eb.wReqAgentCodeIn
    LEFT JOIN tAgent AS debitA ON debitA.wAgentCodeIn = eb.wDebitAgentCodeIn
    LEFT JOIN tDepartment AS reqDept ON reqDept.wDeptCode = eb.wReqDepartment
    LEFT JOIN tDepartment AS followDept ON followDept.wDeptCode = eb.wDeptFollwedCd
    LEFT JOIN tUsr AS usr ON usr.RowID = ae.wUpdBy
    LEFT JOIN tUsr AS reqUsr ON reqUsr.RowID = eb.wReqUserRid
    LEFT JOIN tUsr AS followUsr ON followUsr.RowID = eb.wStaffFollwedRid
    LEFT JOIN dbo.mLookUp AS bs ON ae.wBookingStatus = bs.wCode AND bs.wType = 'ADDITIONAL_EXPENSES_STATUS' AND bs.wLangCd = 'zh-tw'
    LEFT JOIN dbo.mEventCode mec ON mec.RowID = eb.wEventCodeRid