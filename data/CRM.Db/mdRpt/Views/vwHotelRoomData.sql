

CREATE VIEW [mdRpt].[vwHotelRoomData]
AS
    WITH tDepartment AS (
        SELECT DISTINCT 
            wDeptCode = wCode,
            wDeptName = wCName
        FROM RollsMary.[mdRpt].[vwDepartment]
        WHERE wIsRealDept = 'Y' AND NULLIF(wUserLineGrp, '') IS NULL AND wActive = 'A'
    )

    SELECT
        ReservationNo = brB.wRefNo, 
        ReservationDt = hcB.wDebitDt, 
        ReqAgentCodeIn = reqA.wAgentCodeIn, 
        ReqAgentCode = reqA.wAgentCode, 
        ReqAgentCode_Old = reqA.wAgentCode_Old,
        DebitAgentCodeIn = debitA.wAgentCodeIn,
        DebitAgentCode = debitA.wAgentCode,
        DebitAgentCode_Old = debitA.wAgentCode_Old,
        Hotel = h.wName,
        [Location] = region.wTitle, 
        RoomType = hr.wName, 
        [Status] = actionType.wTitle, 
        CheckinDt = (CASE hc.wAction  WHEN 'C'   THEN FORMAT(hc.wNewStartDate, 'yyyy-MM-dd')
                                      WHEN 'RF'  THEN FORMAT(hc.wOriStartDate, 'yyyy-MM-dd')
                                      WHEN 'EX'  THEN FORMAT(hc.wOriEndDate, 'yyyy-MM-dd')
                                      WHEN 'ECI' THEN FORMAT(hc.wNewStartDate, 'yyyy-MM-dd')
                                      WHEN 'LC'	 THEN FORMAT(hc.wOriStartDate, 'yyyy-MM-dd')
                                      WHEN 'ECO' THEN FORMAT(hc.wNewEndDate, 'yyyy-MM-dd')
                                      ELSE NULL END),
        CheckoutDt = (CASE hc.wAction WHEN 'C'	 THEN FORMAT(hc.wNewEndDate, 'yyyy-MM-dd')
                                      WHEN 'RF'	 THEN FORMAT(hc.wOriEndDate, 'yyyy-MM-dd')
                                      WHEN 'EX'	 THEN FORMAT(hc.wNewEndDate, 'yyyy-MM-dd')
                                      WHEN 'ECI' THEN FORMAT(hc.wOriStartDate, 'yyyy-MM-dd')
                                      WHEN 'LC'	 THEN FORMAT(hc.wNewStartDate, 'yyyy-MM-dd')
                                      WHEN 'ECO' THEN FORMAT(hc.wOriEndDate, 'yyyy-MM-dd')
                                      ELSE NULL END),
        Currency = hc.wCurrCode,
        Payment = payment.wTitle,
        RoomPrice = hc.wAmountChange,
        RoomCost = hc.wCostChange,
        FollowedDepartment = followDept.wDeptName,
        FollowedStaff = followUsr.wCName,
        ReqDepartment = reqDept.wDeptName,
        ReqUsr = reqUsr.wCName
    FROM dbo.eHotelChange AS hc 
    INNER JOIN dbo.eBookingRoom AS br ON hc.wRoomBookingRid = br.RowID 
    INNER JOIN dbo.eBooking AS brB ON br.wBookingRid = brB.RowID
    INNER JOIN dbo.ebooking AS hcB ON hc.wBookingRid = hcB.RowID
    INNER JOIN dbo.mHotel AS h ON br.wHotelRid = h.RowID 
    LEFT JOIN dbo.mLookUp AS region ON h.wRegion = region.wCode AND region.wType = 'REGION' AND region.wLangCd = 'zh-tw'
    LEFT JOIN RollsMary.mdRpt.vwAgent AS reqA ON reqA.wAgentCodeIn = hcB.wReqAgentCodeIn
    LEFT JOIN RollsMary.mdRpt.vwAgent AS debitA ON debitA.wAgentCodeIn = hcB.wDebitAgentCodeIn
    LEFT JOIN dbo.mHotelRoom AS hr ON br.wHotelRoomRid = hr.RowID
    LEFT JOIN dbo.mLookUp AS actionType ON hc.wAction = actionType.wCode AND actionType.wType = 'HOTEL_BOOKING_ACTION' AND actionType.wLangCd = 'zh-tw'
    LEFT JOIN dbo.mLookUp AS payment ON hc.wPaymentMethod = payment.wCode AND payment.wType = 'PAYMENT_TYPE_HOTEL' AND payment.wLangCd = 'zh-tw'
    LEFT JOIN tDepartment AS reqDept ON reqDept.wDeptCode = hcB.wReqDepartment
    LEFT JOIN tDepartment AS followDept ON followDept.wDeptCode = hcB.wDeptFollwedCd
    LEFT JOIN RollsMary.mdRpt.vwUsr AS reqUsr ON reqUsr.RowID = hcB.wReqUserRid
    LEFT JOIN RollsMary.mdRpt.vwUsr AS followUsr ON followUsr.RowID = hcB.wStaffFollwedRid