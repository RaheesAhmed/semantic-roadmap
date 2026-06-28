CREATE PROCEDURE [spq].[GetPrivatePlaneRouteDtlLst]
	@pBookingPrivatePlaneRid BIGINT,
    @pStatus CHAR(1) ,
	@pLangCd VARCHAR(10)   
AS
BEGIN
	SET NOCOUNT ON;	  	
				
    IF @@trancount = 0 SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
	SELECT
	   [RowID]
      ,[wBookingPrivatePlaneRid]
      ,[wLine]
      ,[wCityCd]
      ,[wIsReturn]
      ,[wDepartureAirportRid]
      ,[wArrivalAirportRid]
      ,[wTakeOffDt]
      ,[wArrivalDt]
      ,[wStatus]
      ,[wCrtDt]
      ,[wCrtBy]
      ,[wUpdDt]
      ,[wUpdBy]
      ,[wIsDestination]
	FROM dbo.ePrivatePlaneRouteDtl	
	WHERE (@pBookingPrivatePlaneRid IS NULL OR wBookingPrivatePlaneRid=@pBookingPrivatePlaneRid)
	AND (@pStatus ='' OR @pStatus=' ' OR wStatus=@pStatus)
	ORDER BY wLine;

END;