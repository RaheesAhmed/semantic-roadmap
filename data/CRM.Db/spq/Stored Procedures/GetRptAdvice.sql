CREATE PROC [spq].[GetRptAdvice]
(
    @pDeptCd VARCHAR(30),
    @pFromDt DATETIME2(7),
    @pToDt DATETIME2(7),
    @pAdviceStatus VARCHAR(20),
    @pLangCd VARCHAR(10)
)
AS
BEGIN
    SET @pDeptCd = NULLIF(@pDeptCd, '');
    SET @pAdviceStatus = NULLIF(@pAdviceStatus, '');
    SET @pFromDt = FORMAT(@pFromDt, 'yyyy-MM-dd 00:00:00');
    SET @pToDt = FORMAT(@pToDt, 'yyyy-MM-dd 23:59:59');
    SET @pLangCd = ISNULL(@pLangCd, 'zh-TW');

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
    tAdviceStatus AS (
        SELECT
            wCode,
            wTitle
        FROM dbo.mLookUp
        WHERE wLangCd = @pLangCd AND wType = 'ADVICE_STATUS'
    ),
    tAdviceType AS (
        SELECT
            wCode,
            wTitle
        FROM dbo.mLookUp
        WHERE wLangCd = @pLangCd AND wType = 'ADVICE_TYPE'
    ),
    tAdviceSubType AS (
        SELECT
            wCode,
            wTitle
        FROM dbo.mLookUp
        WHERE wLangCd = @pLangCd AND wType = 'ADVICE_SUB_TYPE'
    )

    SELECT
        RowId = a.RowID,
        wAdviceStatus = tas.wTitle,
        a.wDate,
        a.wAim,
        ma.wAgentCode_Old,
        ma.wAgentCode_Display,
        wAdviceType = tat.wTitle,
        wAdviceSubType = tast.wTitle,
        a.wIsHighPriority,
        a.wContent,
        wDepartment = dept.wName,
        wUsrName = u.wName,
        wReceivedDt = a.wCrtDt
    INTO #tmpAdvice
    FROM dbo.eAdvice AS a
    LEFT JOIN tAdviceStatus AS tas ON tas.wCode = a.wAdviceStatus
    LEFT JOIN RollsMary.dbo.mAgent AS ma ON ma.wAgentCodeIn = a.wAgentCodeIn
    LEFT JOIN tAdviceType AS tat ON tat.wCode = a.wType
    LEFT JOIN tAdviceSubType AS tast ON tast.wCode = a.wSubType
    LEFT JOIN tDept AS dept ON dept.wCode = a.wReceivedDeptCd
    LEFT JOIN tUsr AS u ON u.RowId = a.wReceivedBy
    WHERE (@pDeptCd IS NULL OR @pDeptCd = a.wReceivedDeptCd )
        AND (@pAdviceStatus IS NULL OR @pAdviceStatus = a.wAdviceStatus)
        AND (@pFromDt IS NULL OR @pFromDt <= a.wDate)
        AND (@pToDt IS NULL OR @pToDt >= a.wDate)

    SELECT
        rts.wRelatedRid,
        wLastFollowDt = MAX(rts.wUpdDt),
        wRelatedUsrName = STUFF(
            (SELECT CONCAT(', ', CASE WHEN @pLangCd = 'en-GB' THEN u.wName ELSE u.wCName END)
            FROM dbo.eTaskSheet AS sts
            INNER JOIN dbo.eTaskSheetUsr AS tsu ON tsu.wTaskSheetRid = sts.RowID AND tsu.wTaskSheetRid > 0
            LEFT JOIN RollsMary.dbo.mUsr AS u ON u.RowID = tsu.wUsrRid
            WHERE sts.wRelatedType = 'eAdvice' AND sts.wRelatedRid = rts.wRelatedRid FOR XML PATH('')), 1, 2, N''),
        wRelateUsrNo = STUFF(
            (SELECT CONCAT(', ', u.wUsrId)
            FROM dbo.eTaskSheet AS sts
            INNER JOIN dbo.eTaskSheetUsr AS tsu ON tsu.wTaskSheetRid = sts.RowID AND tsu.wTaskSheetRid > 0
            LEFT JOIN RollsMary.dbo.mUsr AS u ON u.RowID = tsu.wUsrRid
            WHERE sts.wRelatedType = 'eAdvice' AND sts.wRelatedRid = rts.wRelatedRid FOR XML PATH('')), 1, 2, N'')
    INTO #tmpUsr
    FROM dbo.eTaskSheet AS rts
    INNER JOIN #tmpAdvice AS rta ON rts.wRelatedType = 'eAdvice' AND rts.wRelatedRid = rta.RowId AND rts.wRelatedRid > 0
    GROUP BY rts.wRelatedRid

    SELECT
        wRefNo = RowId,
        wAdviceStatus,
        wDate,
        wAim,
        wAgentCode_Old,
        wAgentCode_Display,
        wAdviceType,
        wAdviceSubType,
        wIsHighPriority,
        wContent,
        wDepartment,
        wUsrName,
        wLastFollowDt,
        wRelatedUsrName,
        wRelateUsrNo,
        wReceivedDt
    FROM #tmpAdvice AS ta
    LEFT JOIN #tmpUsr AS tu ON tu.wRelatedRid = ta.RowId

    IF OBJECT_ID('tempdb..#tmpAdvice') IS NOT NULL
        DROP TABLE #tmpAdvice;

    IF OBJECT_ID('tempdb..#tmpUsr') IS NOT NULL
        DROP TABLE #tmpUsr;
END;