CREATE PROCEDURE [spq].[GetLookupType] 
AS
BEGIN
	SET NOCOUNT ON;
    
	SELECT DISTINCT ml.wType
	FROM mLookUp ml
	ORDER BY 
		ml.wType
END