CREATE PROC [spq].[GetRptComplaint]
(
    @pRefNo VARCHAR(30),
    @pAgentCodeIn VARCHAR(14),
    @pFromDt DATETIME2(7),
    @pToDt DATETIME2(7),
    @pComplaintStatus VARCHAR(30),
    @pStatus CHAR(1) ,
    @pLangCd VARCHAR(10) = 'zh-TW'
)
AS
BEGIN
    SET @pRefNo = NULLIF(@pRefNo, '');
    SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
    SET @pComplaintStatus = NULLIF(@pComplaintStatus, '');
    SET @pStatus = NULLIF(@pStatus, '');
    SET @pLangCd = ISNULL(@pLangCd, 'zh-TW');
    SET @pFromDt = FORMAT(@pFromDt, 'yyyy-MM-dd 00:00:00');
    SET @pToDt = FORMAT(@pToDt, 'yyyy-MM-dd 23:59:59');

    WITH tDept AS (
        SELECT
            wCode,
            wName = CASE WHEN @pLangCd = 'en-GB' THEN wEName ELSE wCName END
        FROM RollsMary.dbo.mDepartment
        WHERE NULLIF(wUserLineGrp, '') IS NULL AND wIsRealDept = 'Y'
    ),
    tUsr AS (
        SELECT
            RowId = RowID,
            wName = CASE WHEN @pLangCd = 'en-GB' THEN wName ELSE wCName END
        FROM RollsMary.dbo.mUsr
    ),
    tComplaintType AS (
        SELECT
            wCode,
            wTitle
        FROM dbo.mLookUp
        WHERE wLangCd = @pLangCd AND wType = 'COMPLAINT_CATEGORY'
    ),
    tComplaintFrom AS (
        SELECT
            wCode,
            wTitle
        FROM dbo.mLookUp
        WHERE wLangCd = @pLangCd AND wType = 'COMPLAINT_FROM'
    ),
    tComplaintStatus As (
        SELECT
            wCode,
            wTitle
        FROM dbo.mLookUp
        WHERE wLangCd = @pLangCd AND wType = 'OTHER_COMPLAINT'
    )

    SELECT
        RowId = c.RowID,
        c.wTranDt,
        c.wRefNo,
        a.wAgentCode_Old,
        a.wAgentCode_Display,
        wReceivedDept = rdept.wName,
        wReceivedUsr = rusr.wName,
        wComplaintDept = cdept.wName,
        wComplaintUsr = cusr.wName,
        wComplaintType = ct.wTitle,
        wComplaintFrom = cf.wTitle,
        wComplaintContent = c.wContent,
        wComplaintStatus = cs.wTitle,
        wUpdDt = c.wUpdDt,
        wUpdBy = uusr.wName,
        wReceivedLocation,
        wComplainCompNo=CASE WHEN @pLangCd = 'en-GB' THEN comp.wEName ELSE comp.wCName END
    INTO #tmpComplaint
    FROM dbo.eComplaint AS c
    LEFT JOIN RollsMary.dbo.mAgent AS a ON a.wAgentCodeIn = c.wAgentCodeIn
    LEFT JOIN tDept AS rdept ON rdept.wCode = c.wReceivedDeptCd -- 接收投訴部門
    LEFT JOIN tDept AS cdept ON cdept.wCode = c.wComplainDeptCd -- 投訴部門
    LEFT JOIN tUsr AS rusr ON rusr.RowId = c.wReceivedBy -- 接收投訴人
    LEFT JOIN tUsr AS cusr ON cusr.RowId = c.wComplainBy -- 投訴人
    LEFT JOIN tComplaintType AS ct ON ct.wCode = c.wType -- 種類
    LEFT JOIN tComplaintFrom AS cf ON cf.wCode = c.wChannel -- 來源
    LEFT JOIN tComplaintStatus AS cs ON cs.wCode = c.wComplaintStatus
    LEFT JOIN tUsr AS uusr ON uusr.RowId = c.wUpdBy
    LEFT JOIN  RollsMary.dbo.mCompany AS comp ON c.wComplainCompNo=comp.wCompNo
    WHERE (@pRefNo IS NULL OR @pRefNo = c.wRefNo)
        AND (@pAgentCodeIn IS NULL OR @pAgentCodeIn = c.wAgentCodeIn)
        AND (@pComplaintStatus IS NULL OR @pComplaintStatus = c.wComplaintStatus)
        AND (@pStatus IS NULL OR @pStatus = c.wStatus)
        AND (@pFromDt IS NULL OR @pFromDt <= c.wTranDt)
        AND (@pToDt IS NULL OR @pToDt >= c.wTranDt)

    SELECT
        rcf.wComplaintRid,
        wUserName = STUFF(
            (SELECT CONCAT(', ', CASE WHEN @pLangCd = 'en-GB' THEN u.wName ELSE u.wCName END)
            FROM dbo.eComplaintFollow AS scf
            LEFT JOIN RollsMary.dbo.mUsr AS u ON u.RowID = scf.wFollowBy
            WHERE scf.wComplaintRid = rcf.wComplaintRid FOR XML PATH('')), 1, 2, N''),
        wUserNo = STUFF(
            (SELECT CONCAT(', ', u.wUsrId)
            FROM dbo.eComplaintFollow AS scf
            LEFT JOIN RollsMary.dbo.mUsr AS u ON u.RowID = scf.wFollowBy
            WHERE scf.wComplaintRid = rcf.wComplaintRid FOR XML PATH('')), 1, 2, N'')
    INTO #tmpUsr
    FROM dbo.eComplaintFollow AS rcf
    INNER JOIN #tmpComplaint AS c ON c.RowId = rcf.wComplaintRid AND rcf.wComplaintRid > 0
    GROUP BY rcf.wComplaintRid

    SELECT
        wTranDt,
        wRefNo,
        wAgentCode_Old,
        wAgentCode_Display,
        wReceivedDept,
        wReceivedUsr,
        wComplaintType,
        wComplaintFrom,
        wComplaintDept,
        wComplaintUsr,
        wComplaintContent,
        wComplaintStatus,
        wUserName,
        wUserNo,
        wUpdDt,
        wUpdBy,
        wReceivedLocation,
        wComplainCompNo
    FROM #tmpComplaint AS c
    LEFT JOIN #tmpUsr AS u ON u.wComplaintRid = c.RowId
    ORDER BY wRefNo DESC

    IF OBJECT_ID('tempdb..#tmpComplaint') IS NOT NULL
        DROP TABLE #tmpComplaint;

    IF OBJECT_ID('tempdb..#tmpUsr') IS NOT NULL
        DROP TABLE #tmpUsr;
END;