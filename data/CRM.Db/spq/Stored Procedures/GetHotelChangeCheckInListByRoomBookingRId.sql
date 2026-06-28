CREATE PROCEDURE [spq].[GetHotelChangeCheckInListByRoomBookingRId]
    @pRoombookingRid BIGINT ,
    @pLangCd VARCHAR(10) = 'en-GB'
AS
    BEGIN  
        SET NOCOUNT ON;  

        IF @@TRANCOUNT = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        SELECT  CNG.RowID ,
                CNG.wRoomBookingRid ,
                CASE WHEN @pLangCd = 'en-GB' THEN agnt.wEName
                     ELSE agnt.wCName
                END AS DebitAccount ,
                agnt.wAgentCode_Display ,
                HTL.wName ,
                BH.wIsAgentHotel ,
                LKPBEDTYP.wTitle AS wBedType ,
                BR.wRoomNo ,
                CNG.wUseExtraAllotment ,
                CASE WHEN @pLangCd = 'en-GB' THEN USR.wName
                     ELSE USR.wCName
                END AS wReqStaff ,
                CNG.wAction ,
                LKPACTION.wTitle AS wActionName ,
                ALT.wName AS wAllotmentName ,
                CNG.wDayOfStay ,
                BR.wTotalAmount ,
				CNG.wAmountChange, --更改入住日期后變動總值
				CNG.wOriStartDate AS wCheckInDate,
				CNG.wOriEndDate AS wCheckOutDate,
                CNG.wNewStartDate AS wCheckInDateAfter ,
                CNG.wNewEndDate AS wCheckOutDateAfter ,
                CNG.wOrderNo ,
                LUPPAYMENT.wTitle AS wPaymentMethod ,
                EBK.wReqDepartment ,
                CNG.wUpdDt ,
                CASE WHEN @pLangCd = 'en-GB' THEN mUpdUsr.wName
                     ELSE mUpdUsr.wCName
                END AS wUpdBy ,
                LUPDEPT.wTitle AS wRequestedDepartment ,
                agnt.wAgentCodeIn
        FROM    ( SELECT    *
                  FROM      dbo.eHotelChange
                  WHERE     wRoomBookingRid = @pRoombookingRid				  
                ) CNG
                INNER JOIN ( SELECT *
                             FROM   dbo.eBookingRoom
                             WHERE  RowID = @pRoombookingRid
                                    AND wStatus = 'A'
                           ) BR ON BR.RowID = CNG.wRoomBookingRid
                INNER JOIN dbo.eBookingHotel BH ON BH.RowID = BR.wHotelBookingRid
                INNER JOIN dbo.eBooking EBK ON EBK.RowID = BH.wBookingRid
                INNER JOIN dbo.eBooking EB ON EB.RowID = CNG.wBookingRid
                INNER JOIN RollsMary.dbo.mAgent agnt ON agnt.wAgentCodeIn = EBK.wDebitAgentCodeIn
                                                        --AND agnt.wType = 'AGENT'
                LEFT JOIN dbo.mAllotmentGroup ALT ON ALT.RowID = BR.wAllotmentGroupRid
                LEFT JOIN dbo.mLookUp LUPPAYMENT ON LUPPAYMENT.wCode = BR.wPaymentMethod
                                                    AND LUPPAYMENT.wType = 'PAYMENT_TYPE_HOTEL'
                                                    AND LUPPAYMENT.wLangCd = @pLangCd
                LEFT JOIN dbo.mLookUp LKPBEDTYP ON LKPBEDTYP.wCode = BR.wBedType
                                                   AND LKPBEDTYP.wType = 'BED_TYPE'
                                                   AND LKPBEDTYP.wLangCd = @pLangCd
                LEFT JOIN dbo.mLookUp LKPACTION ON LKPACTION.wCode = CNG.wAction
                                                   AND LKPACTION.wType = 'HOTEL_BOOKING_ACTION'
                                                   AND LKPACTION.wLangCd = @pLangCd
                INNER JOIN [dbo].[mHotel] HTL ON HTL.RowID = BR.wHotelRid
                LEFT JOIN dbo.mLookUp LUPDEPT ON LUPDEPT.wCode = EB.wReqDepartment
                                                 AND LUPDEPT.wType = 'DEPARTMENT'
                                                 AND LUPDEPT.wLangCd = @pLangCd
                LEFT JOIN RollsMary.dbo.[mUsr] USR ON USR.RowID = EBK.wReqUserRid
                LEFT JOIN RollsMary.dbo.[mUsr] mUpdUsr ON [mUpdUsr].RowID = CNG.[wUpdBy]
        ORDER BY CNG.wCrtDt DESC;

    END;