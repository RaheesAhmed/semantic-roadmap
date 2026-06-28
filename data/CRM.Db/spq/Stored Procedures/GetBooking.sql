CREATE PROCEDURE [spq].[GetBooking] ( @pBookingId BIGINT )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
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
				b.wUseTravelPkg,
                b.wTravePkgRid ,
                b.wEventCodeRid ,
                b.wAsstBookerEmail ,
                b.wDeptFollwedCd ,
                b.wStaffFollwedRid ,
                b.wStaffTelephone ,
                b.wOwnerAuthTelephone ,
                b.wDepositAmt ,
                b.wGiftReasonCd,
                b.wDepositDebitDt, -- 按金扣數日期
                b.wBookingStatus,
                b.wCoordinator,
                b.wIsUser,
                b.wUser
        FROM    dbo.eBooking b
        WHERE   @pBookingId = b.RowID
    END;