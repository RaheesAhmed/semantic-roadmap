CREATE PROCEDURE [spq].[GetGenerateInvoice]   --19000000010095        
@pwBookingRid BIGINT,       
@pwLangCd VARCHAR(10) ='en-GB'        
AS        
BEGIN        
SELECT      
 BH.RowID    
,BH.wBookingRid    
,BH.wRequestRid     
,BH.wTravelAgencyRid     
,BH.wStartDate    
,BH.wEndDate    
,BH.wDayOfStay    
,BH.wBedType     
,BH.wCrtDt    
,BH.wCrtBy    
,BH.wUpdDt    
,BH.wUpdBy    
  
, (select ROWID from mperson where ROWID = 19000000010267) AS wPresonRid  
, wBookingRid AS wRoomBookingRid  
,wBookingRid AS wInvoiceNo  
,  wBookingRid AS wHotelRid  
, wBookingRid AS wRoomRid  
, wBedType AS wNumberOfRoom  
, 'clientName' AS wClientName    
, wBookingRid AS wOrderNo    
, 'Account' AS wAccount    
, 'Test Remark' AS wRemarks    
, 'HotelName' AS wHotelName    
, 'A' AS wStatus    
, wBedType AS wNoOfRooms    
, wBookingRid AS wAgentCode  
FROM [dbo].[ebookingHotel] BH    where BH.wBookingRid = @pwBookingRid    
END