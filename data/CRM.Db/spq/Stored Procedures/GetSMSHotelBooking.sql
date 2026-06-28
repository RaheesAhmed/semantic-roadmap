CREATE PROCEDURE [spq].[GetSMSHotelBooking]
    @pBookingRid BIGINT ,
    @pGuid VARCHAR(50) ,
    @pLangCd VARCHAR(30)
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;   
			
        SET @pLangCd = LOWER(@pLangCd);     
      
        SELECT  bh.RowID ,
                bh.wBookingRid ,
                bh.wRequestRid ,
                bh.wUseTravelAgency ,
                bh.wTravelAgencyRid ,
                bh.wRoomInProgress ,
                bh.wRoomCompleted ,
                bh.wRoomNotArrange ,
                bh.wRoomCancelled ,
                bh.wRoomUnQualified ,
                bh.wQuantity ,
                bh.wRegion ,
                bh.wIsAgentHotel ,
                bh.wStartDate ,
                bh.wEndDate ,
                bh.wDayOfStay ,
                bh.wBedType ,
                bh.wPaymentMethod ,
                bh.wReceiptNo ,
                bh.wRemark ,
                br.wQuickCollectKey ,
                hr.wName AS wRoomName ,
                h.wName AS wHotelName ,
                b.wBookingType ,
                b.wRefNo ,
                b.GUID ,
                b.wReqCounterRid ,
                b.wDebitCounterRid ,
                b.wReqCustomerRid ,
                b.wDebitCustomerRid ,
                b.wReqDepartment ,
                b.wReqUserRid ,
                b.wAsstBooker ,
                b.wAssBookerTel ,
                b.wDebitDt ,
                b.wExpDt ,
                b.wCancelDebitDt ,
                b.wCancelReasonCd ,
                b.wCancelBy ,
                b.wCancelDt ,
                b.wTravePkgRid ,
                b.wReqAgentCodeIn ,
                CASE WHEN @pLangCd = 'en-gb' THEN a_r.wEName
                     ELSE a_r.wCName
                END AS wReqAgentName ,
                a_r.wAgentCode_Display AS wReqAgentCode_Display ,
                b.wDebitAgentCodeIn ,
                CASE WHEN @pLangCd = 'en-gb' THEN a_d.wEName
                     ELSE a_d.wCName
                END AS wDebitAgentName ,
                a_d.wAgentCode_Display AS wDebitAgentCode_Display ,
                b.wApprovalAgentCodeIn ,
                CASE WHEN @pLangCd = 'en-gb' THEN a_a.wEName
                     ELSE a_a.wCName
                END AS wApprovalName ,
                a_a.wAgentCode_Display AS wApprovalAgentCode_Display ,
                b.wCrtDt ,
                b.wCrtBy ,
                CASE WHEN @pLangCd = 'en-gb' THEN u_crt.wCName
                     ELSE u_crt.wName
                END AS wCrtByName ,
                b.wUpdDt ,
                b.wUpdBy ,
                CASE WHEN @pLangCd = 'en-gb' THEN u.wName
                     ELSE u.wCName
                END AS wUpdByName ,
                scc.wTel AS wServiceCounterTel
        FROM    dbo.eBookingHotel bh
                INNER JOIN CRM.dbo.eBooking b ON bh.wBookingRid = b.RowID
                INNER JOIN CRM.dbo.eBookingRoom br ON br.wHotelBookingRid = bh.RowID
                INNER JOIN CRM.dbo.mHotelRoom hr ON hr.RowID = br.wHotelRoomRid
                INNER JOIN CRM.dbo.mHotel h ON h.RowID = hr.wHotelRid
                LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = b.wUpdBy
                LEFT JOIN RollsMary.dbo.mUsr u_crt ON u_crt.RowID = b.wCrtBy
                LEFT JOIN RollsMary.dbo.mAgent a_r ON a_r.wAgentCodeIn = b.wReqAgentCodeIn
                LEFT JOIN RollsMary.dbo.mAgent a_d ON a_d.wAgentCodeIn = b.wDebitAgentCodeIn
                LEFT JOIN RollsMary.dbo.mAgent a_a ON a_a.wAgentCodeIn = b.wApprovalAgentCodeIn
                LEFT JOIN CRM.dbo.mServiceCounter sc ON sc.RowID = b.wDebitCounterRid AND sc.wStatus = 'A'
		        LEFT JOIN CRM.dbo.mServiceCounterContact scc ON scc.wSeriverCounterRid =sc.RowID  AND scc.wContactType = 'CSSMS' AND scc.wDepartmentCode = 'ROOM'
        WHERE   b.RowID = @pBookingRid;
    END;