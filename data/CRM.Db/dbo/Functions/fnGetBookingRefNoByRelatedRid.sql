-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[fnGetBookingRefNoByRelatedRid]
(
	-- Add the parameters for the function here
	@pRelatedType VARCHAR(30),
	@pRelatedRid BIGINT
)
RETURNS VARCHAR(30)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @refNo VARCHAR(30),
			@vRelatedType VARCHAR(30);
	
	SET @refNo = '';
	SET @vRelatedType = LOWER(@pRelatedType);

	-- Add the T-SQL statements to compute the return value here
	IF @vRelatedType = 'ebooking'
	BEGIN
		SELECT @refNo = wRefNo
		FROM dbo.eBooking
		WHERE RowID = @pRelatedRid
    END
	ELSE IF @vRelatedType = 'ebookingroom'
	BEGIN
		SELECT @refNo = ISNULL(eb.wRefNo, '')
		FROM dbo.eBookingRoom ebr
		LEFT JOIN dbo.eBooking eb ON eb.RowID = ebr.wBookingRid
		WHERE ebr.RowID = @pRelatedRid
    END
	ELSE IF @vRelatedType = 'ebookingadditionexpense'
	BEGIN
		SELECT @refNo = ISNULL(eb.wRefNo, '')
		FROM dbo.eAdditionalExpense ae
		LEFT JOIN dbo.eBooking eb ON eb.RowID = ae.wBookingRid
		WHERE ae.RowID = @pRelatedRid
    END
	ELSE IF @vRelatedType = 'ecomplaint'
	BEGIN
		SELECT @refNo = ISNULL(wRefNo, '')
		FROM dbo.eComplaint
		WHERE RowID = @pRelatedRid
    END
	ELSE IF @vRelatedType = 'eHotelRequestdtl'   --酒店查詢RefNo
	BEGIN
		SELECT @refNo = ISNULL(hr.wRequestNo, '')
		FROM dbo.eHotelRequest hr
		INNER JOIN dbo.eHotelRequestDtl hrd ON hrd.wHotelRequestRid = hr.RowID
		WHERE hrd.RowID = @pRelatedRid
	END		

	-- Return the result of the function
	RETURN @refNo

END