CREATE PROCEDURE [spq].[GetComplaintFollowLst] (
	  @pComplaintRid BIGINT,
	  @pStatus CHAR(1),
	  @pLangCd VARCHAR(30),
	  @pPageSize INT = 999,
	  @pPageNum INT = 1
)
AS
BEGIN
	SET NOCOUNT ON;
	IF @@TRANCOUNT = 0
		SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

	WITH tResult AS (
		SELECT
			-- PRINT [dbo].[fnGetAllFieldNameInTable]('eComplaintFollow', 'cf', 'N', '', '', '')
			cf.RowID, cf.wComplaintRid, cf.wTranDt, cf.wFollowBy, cf.wFollowDeptCd, cf.wContent, cf.wSolveDt, cf.wSolveContent, cf.wPreventContent, cf.wUpdDt, cf.wUpdBy

			,CASE WHEN @pLangCd = 'en-GB' THEN usr.wName ELSE usr.wCName END AS wUpdByCName
			,CASE WHEN @pLangCd = 'en-GB' THEN crusr.wName ELSE crusr.wCName END AS wCreatedByCName
        FROM
			dbo.eComplaintFollow cf
		LEFT JOIN 
			[RollsMary].[dbo].[mUsr] usr ON usr.RowID = cf.wUpdBy 
		LEFT JOIN
			[RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = cf.wCrtBy
		WHERE
			(@pComplaintRid = 0 OR cf.wComplaintRid = @pComplaintRid)
		AND
			(@pStatus = ' ' OR cf.wStatus = @pStatus)
		 ),tCount AS (
			SELECT wRecordCount = COUNT(*) FROM tResult
	)

	SELECT 
		tResult.*, wRecordCount
	FROM 
		tResult, tCount
	ORDER BY 
		tResult.RowID
	OFFSET @pPageSize * (@pPageNum - 1) ROWS
	FETCH NEXT @pPageSize ROWS ONLY;

		
END