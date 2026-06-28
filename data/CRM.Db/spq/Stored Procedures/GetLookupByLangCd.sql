CREATE PROCEDURE [spq].[GetLookupByLangCd] (
	@pwLangCd		Varchar(10)
)
AS
BEGIN
	SET NOCOUNT ON;
    
	SELECT ml.wTitle as Title , ml.wType , ml.wCode , ml.wParentCode, ml.wDescr
	FROM mLookUp ml
	WHERE  ml.wStatus = 'A'
		AND  ml.wLangCd = @pwLangCd
	ORDER BY 
		ml.wSeqNo
END