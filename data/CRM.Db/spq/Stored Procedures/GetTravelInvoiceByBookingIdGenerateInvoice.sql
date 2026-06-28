CREATE PROCEDURE [spq].[GetTravelInvoiceByBookingIdGenerateInvoice]     
@pwBookingRid BIGINT,   
@pwLangCd VARCHAR(10) ='en-GB'    
AS    
BEGIN    
SELECT  
 BH.RowID
,BH.wBookingRid
,BH.wRequestRid
,BH.wUseTravelAgency
,BH.wTravelAgencyRid
,BH.wRoomInProgress
,BH.wRoomCompleted
,BH.wRoomNotArrange
,BH.wRoomCancelled
,BH.wRegion
,BH.wIsAgentHotel
,BH.wStartDate
,BH.wEndDate
,BH.wDayOfStay
,BH.wBedType
,BH.wPaymentMethod
,BH.wReceiptNo
,BH.wRemark
,BH.wSeqNo
,BH.wCrtDt
,BH.wCrtBy
,BH.wUpdDt
,BH.wUpdBy
, 'clientName' AS wClientName
, 'OrderNo' AS wOrderNo
, 'Account' AS wAccount
, 'Remark' AS wRemark
, 'HotelName' AS wHotelName
, 'A' AS wStatus
FROM [dbo].[ebookingHotel] BH 

   where BH.wBookingRid = @pwBookingRid
  
END