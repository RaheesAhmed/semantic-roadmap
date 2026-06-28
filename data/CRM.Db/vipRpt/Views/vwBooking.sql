




CREATE VIEW [vipRpt].[vwBooking]
AS
SELECT RowID,
       wRefNo,
       wBookingType,
       wCancelDt,
       wDebitDt,
       wBookingStatus,
       wReqAgentCodeIn,
       wDebitAgentCodeIn,
       wReqDepartment,
       wReqUserRid,
       wDeptFollwedCd,
       wStaffFollwedRid,
       wAsstBooker,
       wEventCodeRid,
       wDebitCounterRid,
       wReqCounterRid
FROM dbo.eBooking;