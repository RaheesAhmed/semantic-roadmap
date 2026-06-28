CREATE PROCEDURE [spq].[GetPriceCostAndHandlingFee]
	@pRouteRid BIGINT, 
	@pDepartureDate DATE
	
AS  
BEGIN  
	DECLARE  @pIsSpecialPeriodExists BIT = 0
	IF EXISTS(SELECT 1 FROM eTicketPricing 
	WHERE wRouteId = @pRouteRid 
	AND (@pDepartureDate BETWEEN wStartDate AND wEndDate) 
	AND wIsSpecialPeriod = 'Y' AND wVehicleType ='HELI' 
	AND wStatus ='A')
	
	BEGIN
		SET @pIsSpecialPeriodExists = 1
	END 
	SELECT wAmount,ISNULL(wHandlingFee,0) AS wHandlingFee,wCost,wCharteredAmount,wCharteredHandlingFee,wCharteredCost
	FROM eTicketPricing 
	WHERE wRouteId = @pRouteRid AND wVehicleType ='HELI' 
	AND wStatus ='A' AND 
	((@pIsSpecialPeriodExists = 1 AND @pDepartureDate BETWEEN wStartDate AND wEndDate AND wIsSpecialPeriod = 'Y')
	OR(@pIsSpecialPeriodExists =0 AND @pDepartureDate >= wStartDate  AND wIsSpecialPeriod = 'N'))
	ORDER BY wUpdDt desc
END