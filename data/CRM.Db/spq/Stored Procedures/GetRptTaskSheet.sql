CREATE PROC [spq].[GetRptTaskSheet]
(
    @pAgentCodeIn VARCHAR(14),
    @pDeptCd VARCHAR(30),
    @pCounterRid VARCHAR(MAX),
    @pFromDt DATETIME2(7),
    @pToDt DATETIME2(7),
    @pTaskSheetStatus VARCHAR(50),
    @pLangCd VARCHAR(10) = 'zh-TW'
)
AS
BEGIN
    SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
    SET @pDeptCd = NULLIF(@pDeptCd, '');
    SET @pCounterRid = NULLIF(@pCounterRid, '');
    SET @pTaskSheetStatus = NULLIF(@pTaskSheetStatus, '');
    SET @pLangCd = ISNULL(@pLangCd, 'zh-TW');
    SET @pFromDt = FORMAT(@pFromDt, 'yyyy-MM-dd 00:00:00');
    SET @pToDt = FORMAT(@pToDt, 'yyyy-MM-dd 23:59:59');

    DECLARE @tmpFilterCounter TABLE(wCounterRid BIGINT);
    DECLARE @tmpFilterStatus TABLE(wStatus VARCHAR(10));

    IF @pCounterRid IS NOT NULL
    BEGIN
        INSERT INTO @tmpFilterCounter (wCounterRid)
        SELECT CAST(item AS BIGINT)
        FROM dbo.fnSplit(@pCounterRid, ',')
        WHERE NULLIF(item, '') IS NOT NULL
    END;

    IF @pTaskSheetStatus IS NOT NULL
    BEGIN
        INSERT INTO @tmpFilterStatus (wStatus)
        SELECT item
        FROM dbo.fnSplit(@pTaskSheetStatus, ',')
        WHERE NULLIF(item, '') IS NOT NULL
    END;

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
            wUsrId AS wUsrNo,
            wName = CASE WHEN @pLangCd = 'en-GB' THEN wName ELSE wCName END
        FROM RollsMary.dbo.mUsr
    ),
    tTaskSheetStatus AS (
        SELECT
            wCode,
            wTitle
        FROM dbo.mLookUp
        WHERE wLangCd = @pLangCd AND wType = 'TASKSHEET_STATUS'
    )
	
    SELECT
        RowId = ts.RowID,
        ts.wDate,
        wServiceCounter = sc.wName,
        wDepartment = dept.wName,
        wUsrName = u.wName,
        u.wUsrNo,
        a.wAgentCode_Old,
        a.wAgentCode_Display,
        wCompanyName = CASE WHEN @pLangCd = 'en-GB' THEN c.wEName ELSE c.wCName END,
        ts.wIsInhouse,
        wTaskType = tsType.wTitle,
        wSubTaskType = tsSubType.wTitle,
        wTaskSheetContent = ts.wContent,
        wTaskSheetStatus = tss.wTitle,
        ts.wRemark,
        ts.wUpdDt
    INTO #tmpTaskSheet
    FROM dbo.eTaskSheet AS ts
    LEFT JOIN dbo.mServiceCounter AS sc ON sc.RowID = ts.wCounterRid
    LEFT JOIN RollsMary.dbo.mCompany AS c ON c.wCompNo = ts.wCompNo
    LEFT JOIN RollsMary.dbo.mAgent AS a ON a.wAgentCodeIn = ts.wRelateAgentCodeIn
    LEFT JOIN tDept AS dept ON dept.wCode = ts.wDeptCd
    LEFT JOIN tUsr AS u ON u.RowId = ts.wUsrRid
    LEFT JOIN tTaskSheetStatus AS tss ON tss.wCode = ts.wTaskSheetStatus
    LEFT JOIN dbo.mTaskSheetType AS tsType ON tsType.wDepartmentCode = ts.wDeptCd AND tsType.wCode = ts.wTaskType
    LEFT JOIN dbo.mTaskSheetType AS tsSubType ON tsSubType.wDepartmentCode = ts.wDeptCd AND tsSubType.wCode = ts.wSubTaskType AND tsSubType.wParentCode = ts.wTaskType
    LEFT JOIN @tmpFilterCounter AS fc ON fc.wCounterRid = ts.wCounterRid
    LEFT JOIN @tmpFilterStatus AS fs ON fs.wStatus = ts.wTaskSheetStatus
    WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = ts.wRelateAgentCodeIn)
        AND (@pDeptCd IS NULL OR @pDeptCd = ts.wDeptCd)
        AND (@pCounterRid IS NULL OR fc.wCounterRid IS NOT NULL)
        AND (@pTaskSheetStatus IS NULL OR fs.wStatus IS NOT NULL)
        AND (@pFromDt IS NULL OR @pFromDt <= ts.wDate)
        AND (@pToDt IS NULL OR @pToDt >= ts.wDate);

    SELECT
        rtsu.wTaskSheetRid,
        wRelatedUsrName = STUFF(
            (SELECT CONCAT(', ', CASE WHEN @pLangCd = 'en-GB' THEN u.wName ELSE u.wCName END)
            FROM dbo.eTaskSheetUsr AS stsu
            LEFT JOIN RollsMary.dbo.mUsr AS u ON u.RowID = stsu.wUsrRid
            WHERE stsu.wTaskSheetRid = rtsu.wTaskSheetRid FOR XML PATH('')), 1, 2, N''),
        wRelatedUsrNo = STUFF(
            (SELECT CONCAT(', ', u.wUsrId)
            FROM dbo.eTaskSheetUsr AS stsu
            LEFT JOIN RollsMary.dbo.mUsr AS u ON u.RowID = stsu.wUsrRid
            WHERE stsu.wTaskSheetRid = rtsu.wTaskSheetRid FOR XML PATH('')), 1, 2, N'')
    INTO #tmpUsr
    FROM dbo.eTaskSheetUsr AS rtsu
    INNER JOIN #tmpTaskSheet AS ts ON ts.RowId = rtsu.wTaskSheetRid AND rtsu.wTaskSheetRid > 0
    GROUP BY rtsu.wTaskSheetRid;

    SELECT
        wRefNo = ts.RowId,
        wDate,
        wServiceCounter,
        wDepartment,
        wUsrName,
        wAgentCode_Old,
        wAgentCode_Display,
        wCompanyName,
        wIsInhouse,
        wTaskType,
        wSubTaskType,
        wTaskSheetContent,
        wTaskSheetStatus,
        wRelatedUsrName,
        wRelatedUsrNo,
        wUsrNo,
        wRemark,
        wUpdDt
    FROM #tmpTaskSheet AS ts
    LEFT JOIN #tmpUsr As u ON u.wTaskSheetRid = ts.RowId
    ORDER BY ts.wDate DESC, ts.RowId DESC;

    IF OBJECT_ID('tempdb..#tmpTaskSheet') IS NOT NULL
        DROP TABLE #tmpTaskSheet;

    IF OBJECT_ID('tempdb..#tmpUsr') IS NOT NULL
        DROP TABLE #tmpUsr;
END;