
CREATE PROCEDURE [spq].[GetCounterLogSheet]
(
	@pCounterName	NVARCHAR(100) = null,
	@pDate			DATE = null,
	@pLangCd		VARCHAR(10) = 'en-GB',
	@pPageNum		INT = 1,
	@pPageSize		INT = 999
)
AS
	BEGIN
		SET NOCOUNT ON;

		IF @@TRANCOUNT = 0 
			SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 

		SET @pCounterName = ISNULL(@pCountername, '');
		SET @pDate = ISNULL(@pDate, GETDATE());
		SET @pLangCd = ISNULL(@pLangCd, 'en-GB');
		SET @pPageNum = ISNULL(@pPageNum, 1);
		SET @pPageSize = ISNULL(@pPageSize, 999);
		
		WITH tLog AS (
			SELECT wCounterRid, COUNT(wCounterRid) AS wCount
			FROM [dbo].[eCounterLog] 
			WHERE CONVERT(VARCHAR(10), wCrtDt ,120)=CONVERT(VARCHAR(10), @pDate, 120) AND wStatus = 'A'
			GROUP BY wCounterRid
		),
		tCounter AS (
			SELECT 
				  msv.RowID AS wCounterRid,
				  msv.wCode AS wCounterCode, 
				  msv.wName AS wCounterName,
				  mc.RowID AS wCompRid,
				  mc.wCompNo AS wCompNo,
				  (CASE @pLangCd WHEN 'en-GB' THEN mc.wEName ELSE mc.wCName END) AS wCompName
			FROM [CRM].[dbo].mServiceCounter msv
			LEFT JOIN [RollsMary].[dbo].[mCompany] mc ON mc.wCompNo = msv.wRollexCompNo
			--WHERE msv.wStatus = 'A'
		),
		tResult AS(
				SELECT
				    tCounter.wCounterRid AS wCounterRid,
					tCounter.wCounterCode AS wCounterCode, 
					tCounter.wCounterName AS wCounterName,
					ISNULL(tCounter.wCompRid, 0) AS wCompRid,
					ISNULL(tCounter.wCompNo, 0) AS wCompNo, 
					tCounter.wCompName AS wCompName,
					@pDate AS wDate, 
					ISNULL(tLog.wCount, 0) AS wCount,
					ISNULL(esLog.wStatus, (CASE WHEN DATEDIFF(HOUR, CAST(@pDate AS DATE), GETDATE()) < 32 THEN 'A' ELSE 'T' END)) AS wStatus				
				FROM tCounter
				LEFT JOIN tLog ON tLog.wCounterRid = tCounter.wCounterRid
				LEFT JOIN eServiceCounterLog esLog on esLog.wConterRid=tCounter.wCounterRid and CONVERT(varchar(100), esLog.wDateTime, 23)=CONVERT(VARCHAR(10), @pDate, 120)
				WHERE @pCounterName = '' OR tCounter.wCounterName like CONCAT('%', @pCounterName, '%')
		), 
		tCount AS (
			SELECT COUNT(1) AS wRecordCount FROM tResult
		)

		SELECT tResult.*, wRecordCount FROM tResult, tCount
		ORDER BY tResult.wCompNo
		OFFSET @pPageSize * (@pPageNum - 1) ROWS
		FETCH NEXT @pPageSize ROWS ONLY
		OPTION  ( RECOMPILE );
	END;