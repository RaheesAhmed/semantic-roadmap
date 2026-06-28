CREATE PROCEDURE [spq].[GetMaxRecieptNoFerry] (
    @pRecieptNo	BIGINT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
    SELECT  @pRecieptNo = MAX(wReceiptNo) 
    FROM [CRM].[dbo].[eBookingFerry]
END