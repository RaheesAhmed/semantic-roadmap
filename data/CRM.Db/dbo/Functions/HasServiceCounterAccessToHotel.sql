CREATE FUNCTION [dbo].[HasServiceCounterAccessToHotel]
(
	@pwCounterRid BIGINT ,
	@pwHotelCodes  VARCHAR (MAX)	
)
RETURNS BIT
AS
BEGIN
	DECLARE @hasAccess BIT = 0
	DECLARE  @tempHotelList TABLE(
		data VARCHAR(100)
		)
		
		INSERT INTO @tempHotelList(data)
		SELECT splitdata
		FROM dbo.Split(@pwHotelCodes, ',') s
		
	IF EXISTS (SELECT DISTINCT sc.RowID
	FROM
		dbo.mServiceCounter sc
		INNER JOIN dbo.mAllotmentGroupDtl agd ON sc.RowID = agd.wCounterRid
		INNER JOIN dbo.mAllotmentGroup ag ON agd.wAllotmentGroupRid = ag.RowID
		INNER JOIN dbo.eAllotmentHotelDtl ahd ON ag.RowID = ahd.wAllotmentGroupRid
		INNER JOIN dbo.eAllotmentHotel ah ON ahd.wAllotmentHotelRid= ah.RowID
		INNER JOIN	dbo.mHotel h ON h.RowID = ah.wHotelRid 
	WHERE h.wCode IN (SELECT data FROM @tempHotelList) AND sc.RowID = @pwCounterRid)
	BEGIN
		SET @hasAccess  = 1
	END

	-- Return the result of the function
	RETURN 
(
    SELECT @hasAccess
)


END