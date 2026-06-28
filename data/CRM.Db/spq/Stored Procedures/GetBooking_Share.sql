
CREATE PROCEDURE [spq].[GetBooking_Share] ( @pBookingRid BIGINT )
AS
    BEGIN
        SET NOCOUNT ON;
		
        SET @pBookingRid = ISNULL(@pBookingRid, 0);

        SELECT  b.RowID ,
                b.wBookingType ,
                b.wRefNo ,
                b.[GUID] wGUID ,
                b.wReqCounterRid ,
                b.wDebitCounterRid ,
                b.wReqAgentCodeIn ,
                b.wDebitAgentCodeIn ,
                b.wReqCustomerRid ,
                b.wDebitCustomerRid ,
                b.wReqDepartment ,
                b.wReqUserRid ,
                b.wAsstBooker ,
                b.wAssBookerTel ,
                b.wApprovalAgentCodeIn ,
                b.wDebitDt ,
                b.wExpDt ,
                b.wCancelDebitDt ,
                b.wCancelReasonCd ,
                b.wOtherReason ,
                b.wCancelBy ,
                b.wCancelDt ,
                b.wCrtDt ,
                b.wCrtBy ,
                b.wUpdDt ,
                b.wUpdBy ,
                b.wTravePkgRid ,
                b.wEventCodeRid ,
                b.wAsstBookerEmail ,
                b.wDeptFollwedCd ,
                b.wStaffFollwedRid ,
                b.wStaffTelephone ,
                b.wOwnerAuthTelephone ,
                b.wDepositAmt ,
                b.wGiftReasonCd
        FROM    dbo.eBooking b
        WHERE   b.RowID = @pBookingRid;

    END;