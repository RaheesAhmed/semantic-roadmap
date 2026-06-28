CREATE PROCEDURE [spq].[GetTravelInvoiceByBookingId]  --  19000000010095        
@pwBookingRid BIGINT,       
@pwLangCd VARCHAR(10) ='en-GB'        
AS        
BEGIN 
declare @Count AS INT 
set @count = 1   
  
SELECT      
 BH.RowID    
,BH.wBookingRid     
,wBookingRid AS wInvoiceNo  
,BH.wTravelAgencyRid     
,BH.wStartDate    
,BH.wEndDate    
,BH.wDayOfStay    
,BH.wBedType     
,BH.wCrtDt    
,BH.wCrtBy    
,BH.wUpdDt    
,BH.wUpdBy  
,(select ROWID from mperson where ROWID = 19000000010267) AS wPresonRid   -- Client 
,wRemark AS wRemarks
,BH.wDayOfStay AS wNumberOfRoom
, 'A' AS wStatus
,BH.wBookingRid AS wHotelRid
,  (SELECT  @count +  count(*) from eTravelAgencyInvoice (nolock))     AS OrderNo
, 'HotelName' AS wHotelName 
, 'clientName' AS wClientName  
, wRemark AS wAgentCode   -- AgentCode for Account
FROM [dbo].[ebookingHotel] BH    where BH.wBookingRid = @pwBookingRid    
END