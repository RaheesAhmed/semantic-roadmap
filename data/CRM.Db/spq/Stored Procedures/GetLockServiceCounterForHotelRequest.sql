CREATE PROCEDURE [spq].[GetLockServiceCounterForHotelRequest] 
(
	@pwHotelRequestRid BIGINT
)

AS
BEGIN

		-- SET NOCOUNT ON added to prevent extra result sets from

		-- interfering with SELECT statements.
		 SET NOCOUNT ON;

		 SELECT	wLockCounterRid 
		 FROM eHotelRequest
		 WHERE RowID = @pwHotelRequestRid

END;