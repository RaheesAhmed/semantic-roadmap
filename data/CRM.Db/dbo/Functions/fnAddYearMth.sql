CREATE FUNCTION [dbo].[fnAddYearMth] (
	@sYearMth		AS VARCHAR(6),
    @sNumberToAdd	AS INT
)
RETURNS VARCHAR(6)
AS
BEGIN
	DECLARE 
    	@sTemp	DATETIME2,
        @sRtn	VARCHAR(6)
    IF LEN(@sYearMth) = 6 BEGIN
	    SET @sTemp = DATEADD(MONTH, @sNumberToAdd, @sYearMth + '01');
	    SET @sRtn = LEFT(CONVERT(VARCHAR(12), CONVERT(DATETIME2,@sTemp,111),112),6)
    END
    
    RETURN @sRtn;
END