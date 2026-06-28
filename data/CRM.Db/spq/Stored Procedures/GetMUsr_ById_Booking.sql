
CREATE PROCEDURE [spq].[GetMUsr_ById_Booking]
(
	@pRowId	as bigint,
	@pwLangCd varchar(10) = 'en-GB'
)
AS
BEGIN
    SET NOCOUNT ON
	
	SELECT 
		CASE WHEN @pwLangCd = 'en-GB' THEN wName ELSE wCName END AS wCName,
		wCName as ChName,
		RowID 
	FROM RollsMary.dbo.mUsr
	WHERE  @pRowId = RowID
END