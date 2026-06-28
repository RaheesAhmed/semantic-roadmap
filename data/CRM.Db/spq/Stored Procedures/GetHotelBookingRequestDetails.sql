-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [spq].[GetHotelBookingRequestDetails] 
(
@RowID bigInt 
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	select
		RowID
      ,[wRequestNo]
      ,[wReqCounterRid]
      ,[wDebitCounterRid]
      ,[wReqAgentCodeIn]
      ,[wDebitAgentCodeIn]
      ,[wReqCustomerRid]
      ,[wDebitCustomerRid]
      ,[wReqDepartment]
      ,[wReqUserRid]
      ,[wAsstBooker]
      ,[wAssBookerTel]
      ,[wApprovalAgentCodeIn]
      ,[wRegion]
      ,[wNumberOfRoom]
      ,[wStartDate]
      ,[wEndDate]
      ,[wDayOfStay]
      ,[wHotelCodeSCV]
      ,[wIsAgentHotel]
      ,[wBedType]
      ,[wLockCounterRid]
      ,[wStatus]
      ,[wRemark]     
      ,[wCrtDt]
      ,[wCrtBy]
      ,[wUpdDt]
      ,[wUpdBy]
  FROM eHotelRequest
    where RowID=@RowID
END