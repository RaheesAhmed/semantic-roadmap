
CREATE PROCEDURE [spq].[GetCRMReportLst] 
(
	@pUsrId AS VARCHAR(15),
	@pMsg   AS NVARCHAR(100) OUTPUT
)
AS
BEGIN TRY
	SET NOCOUNT ON;
	DECLARE @dRoleRid	AS bigint,
			@dRoleCd	AS varchar(15);

	SET @pUsrId = ISNULL(@pUsrId,'');
	SELECT @dRoleCd = wRoleCd FROM [RollsMary].[dbo].[mUsr] WHERE wUsrId = @pUsrId AND wStatus = 'ACTIVE';
	SELECT @dRoleRid =  RowID FROM [RollsMary].[dbo].[mRole] WHERE wRoleCd = @dRoleCd;
		
	SELECT 
		mf.wFunctionCd, 
		mf.wParentCd,
		mf.wSort, 
		mp.wSort AS wParentSort, 
		[RollsMary].[dbo].[fnRptCanPrintOrExport](mf.wFunctionCd, 'PRINT', mrf.wRoleRid) AS wCanPrint,
		[RollsMary].[dbo].[fnRptCanPrintOrExport](mf.wFunctionCd, 'EXPORT', mrf.wRoleRid) AS wCanExport,
		CASE WHEN mfa.wActionType IS NULL THEN 'N' ELSE 'Y' END AS wCheckAgent
	FROM [RollsMary].[dbo].[mFunction] AS mf
	LEFT JOIN [RollsMary].[dbo].[mRoleFunction] AS mrf
		ON mf.wFunctionCd = mrf.wFunctionCd AND mf.wActionType = mrf.wActionType AND mrf.wRoleRid = @dRoleRid
	LEFT JOIN [RollsMary].[dbo].[mUsr] AS mu 
		ON mu.wRoleCd = mrf.wRoleCd
	LEFT OUTER JOIN [RollsMary].[dbo].[mFunction] AS mp 
		ON mp.wFunctionCd = mf.wParentCd AND mp.wActionType = 'EXPORT'
	LEFT JOIN [RollsMary].[dbo].[mFunction] AS mfa 
		ON mfa.wFunctionCd = mf.wFunctionCd AND mfa.wActionType = 'RPT_CHECK_AGENT'
	WHERE mf.wStatus = 'A'
		AND mf.wActionType = 'CRMREPORT' 
		AND mrf.wStatus = 'A'
		AND ( mu.wUsrId = @pUsrId OR @pUsrId = '')
		AND mu.wStatus = 'ACTIVE'
		GROUP BY mf.wFunctionCd, mf.wParentCd, mf.wSort, mrf.wRoleRid, mp.wSort,mfa.wActionType
		ORDER BY mp.wSort, mf.wSort;

	SET @pMsg = 'OK';
END TRY
BEGIN CATCH
	SET @pMsg = 'SYSTEM_ERROR';

	-- Raise an error with the details of the exception
	DECLARE @ErrMsg AS NVARCHAR(4000), @ErrSeverity AS INT, @dRtnCode AS INT;
	SELECT @ErrMsg = ERROR_MESSAGE(),@ErrSeverity = ERROR_SEVERITY();

	EXEC [spa].[WriteErrorLog]
	--(
		@pMainCompNo = NULL
		,@pCompNo = NULL
		,@pLogCode = '[spq].[GetReportList]' -- Name of stored procedure or predined event code
		,@pLogInfo = @ErrMsg -- User define log message
		,@pRtnCode = @dRtnCode OUTPUT
		,@pErrMsg = @ErrMsg OUTPUT;
	--)
	RAISERROR (@ErrMsg, @ErrSeverity, 1);
END CATCH