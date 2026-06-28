CREATE FUNCTION [dbo].[fnGetPersonNamesByRoomBookingID]
(
    @pwRoomID BIGINT,
	@pwLangCd Varchar(10) = 'en-GB'	
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @pwPersonNames NVARCHAR(MAX);

SELECT @pwPersonNames =
   CAST(COALESCE((CASE WHEN @pwPersonNames IS NULL OR @pwPersonNames!='' OR @pwPersonNames!=' ' THEN  @pwPersonNames + ', ' ELSE '' END), '') + CAST(
	CASE WHEN @pwLangCd='en-GB'	 THEN wEName
		 ELSE wCName 
		 END AS NVARCHAR(MAX)) AS NVARCHAR(MAX))
FROM mPerson p
INNER JOIN ePassengerDetails bcd ON bcd.wPersonRid = p.RowID
WHERE bcd.wRoomBookingRid = @pwRoomID

RETURN 
(
    SELECT @pwPersonNames
)
END