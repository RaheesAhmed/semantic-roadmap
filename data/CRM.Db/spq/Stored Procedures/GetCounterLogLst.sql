
CREATE PROCEDURE [spq].[GetCounterLogLst]
	@pCounterRid    BIGINT,
	@pDate		    DATE,
	@pLangCd		VARCHAR(30) = 'en-GB',
	@pPageNum		INT = 1,
	@pPageSize		INT = 999
AS
	BEGIN
		SET NOCOUNT ON;

		SET @pCounterRid = ISNULL(@pCounterRid, 0);
		SET @pDate = ISNULL(@pDate, GETDATE());
		SET @pLangCd = ISNULL(@pLangCd, 'en-GB');
		SET @pPageNum = ISNULL(@pPageNum, 1);
		SET @pPageSize = ISNULL(@pPageSize, 999);

		WITH tUsr AS (
				SELECT 
					RowID, 
					wUsrId, 
					(CASE WHEN @pLangCd = 'en-GB' THEN mUsr.wName ELSE mUsr.wCName END) AS wUsrName 
				FROM [RollsMary].[dbo].[mUsr]
		),
		tPerson AS (
			SELECT 
				RowID,
				(CASE WHEN @pLangCd = 'en-GB' THEN wEName ELSE wCName END) AS wUsrName 
			FROM [dbo].[mPerson]
		),
		tAgent AS (
			SELECT 
				wAgentCodeIn,
				wAgentCode_Display AS wAgentCode 
			FROM [RollsMary].[dbo].[mAgent]
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
			INNER JOIN [RollsMary].[dbo].[mCompany] mc ON mc.wCompNo = msv.wRollexCompNo
		),
		tDept AS (
			SELECT 
				  wCode AS wDeptCd, 
				  wTitle AS wDeptName 
				  FROM [dbo].[mLookUp] 
				  WHERE wLangCd = @pLangCd AND wType = 'DEPARTMENT'
		),
		tLookUp As(
			SELECT 
				wCode, 
				wTitle
			FROM [dbo].[mLookUp]
			WHERE wLangCd = @pLangCd AND wType = 'SERVICE_COUNTER_LOG'
		),
		tResult AS(
				SELECT
					eLog.RowID	AS RowID,
					eLog.wCounterRid AS wCounterRid,
					tCounter.wCounterCode AS wCounterCode,
					tCounter.wCounterName AS wCounterName,
					tCounter.wCompRid AS wCompRid,
					tCounter.wCompNo AS wCompNo,
					tCounter.wCompName AS wCompName, 
					tDept.wDeptCd AS wDeptCd,
					tDept.wDeptName AS wDeptName,
					tLookUp.wCode AS wLookUpCode,
					tLookUp.wTitle AS wLookUpTitle,
					eLog.wTitle AS wTitle, 
					eLog.wContent AS wContent, 
					tUsr.RowID AS wUserRid,
					tUsr.wUsrName AS wUserName,
					eLog.wDateTime AS wEventDateTime,
					elog.wIsImportant AS wIsImportantEvent,
					elog.wIsProcessed AS wEventStatus,
					elog.wRelateAgentCodeIn AS wRelateAgentCodeIn, 
					tAgent.wAgentCode as wRelateAgentCode,
					tPerson.RowID AS wRelatePersonRid,
					tPerson.wUsrName AS wRelatePersonName,
					mcUsr.RowID AS wCrtByRid,
					mcUsr.wUsrName AS wCrtByName,
					eLog.wStatus AS wLogStatus,
					eLog.wIsClosed AS wIsClosed
				FROM [dbo].[eCounterLog] eLog
				LEFT JOIN tDept ON tDept.wDeptCd = eLog.wDeptCd
				LEFT JOIN tAgent ON tAgent.wAgentCodeIn = eLog.wRelateAgentCodeIn
				LEFT JOIN tCounter ON tCounter.wCounterRid = eLog.wCounterRid
				LEFT JOIN tUsr ON tUsr.RowID = eLog.wUserRid
				LEFT JOIN tUsr mcUsr ON mcUsr.RowID = eLog.wCrtBy
				LEFT JOIN tPerson ON tPerson.RowID = eLog.wRelatePersonRid
				LEFT JOIN tLookUp ON tLookUp.wCode = eLog.wType
				WHERE --eLog.wStatus = 'A' and 
				eLog.wCounterRid = @pCounterRid AND CONVERT(VARCHAR(10), eLog.wCrtDt ,120)=CONVERT(VARCHAR(10), @pDate, 120)
			),
			tCount AS(
				SELECT COUNT(1) as wRecordCount FROM tResult
			)

			SELECT tResult.*, wRecordCount FROM tResult, tCount
			ORDER BY RowID DESC
			OFFSET @pPageSize * (@pPageNum - 1) ROWS
			FETCH NEXT @pPageSize ROWS ONLY
			--OPTION  ( RECOMPILE ); 
		END;