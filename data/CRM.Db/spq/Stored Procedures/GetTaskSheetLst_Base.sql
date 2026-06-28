CREATE PROCEDURE [spq].[GetTaskSheetLst_Base]
(
    @pCompNo INT ,
    @pRelatedType VARCHAR(30) ,
    @pRelatedRid BIGINT ,
    @pStatus CHAR(1) ,
    @pLangCd VARCHAR(30) ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1
)
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
    
        SET @pCompNo = NULLIF(@pCompNo, 0);
        SET @pRelatedType = NULLIF(@pRelatedType, '');
        SET @pRelatedRid = NULLIF(@pRelatedRid, 0);
        SET @pStatus = NULLIF(@pStatus, ' ');
        SET @pLangCd = ISNULL(@pLangCd, 'zh-TW');
        SET @pPageSize = ISNULL(@pPageSize, 999);
        SET @pPageNum = ISNULL(@pPageNum, 1);

        WITH cteData AS (
            SELECT
                ts.RowID ,
                ts.wCompNo ,
                ts.wCounterRid ,
                wServiceCounterName = sc.wName ,
                ts.wDeptCd ,
                ts.wUsrRid ,
                wStaffName = CASE WHEN @pLangCd = 'en-GB' THEN usr.wName ELSE usr.wCName END ,
                ts.wDate ,
                ts.wTaskType ,
                ts.wSubTaskType ,
                ts.wIsInhouse ,
                ts.wContent ,
                ts.wRemark ,
                ts.wRelateAgentCodeIn ,
                ts.wRelatedType ,
                ts.wRelatedRid ,
                ts.wHasDoc ,
                ts.wStatus ,
                ts.wCrtDt ,
                ts.wCrtBy ,
                ts.wUpdDt ,
                ts.wUpdBy ,
                ts.wFollowUpDt ,
                ts.wFollowUpBy ,
                ts.wTaskSheetStatus ,
                wTaskTypeTitle = tst.wTitle ,
                wSubTaskTypeTitle = tstSub.wTitle ,
                wDepartment = CASE WHEN @pLangCd = 'en-GB' THEN dept.wEName ELSE dept.wCName END,
                wUpdByCName = CASE WHEN @pLangCd = 'en-GB' THEN u.wName ELSE u.wCName END ,
                wCreatedByCName = CASE WHEN @pLangCd = 'en-GB' THEN cu.wName ELSE cu.wCName END,
                wRelateAgentCode_Display = a_r.wAgentCode_Display ,
                wRelateAgentName  = CASE WHEN @pLangCd = 'en-gb' THEN a_r.wEName ELSE a_r.wCName END ,
                wAgentCode_Display = a_r.wAgentCode_Display ,
                wAgentCodeIn = ts.wRelateAgentCodeIn
            FROM dbo.eTaskSheet ts
            LEFT JOIN dbo.mServiceCounter sc ON sc.RowID = ts.wCounterRid
            LEFT JOIN [RollsMary].[dbo].[mUsr] u ON u.RowID = ts.wUpdBy
            LEFT JOIN [RollsMary].[dbo].[mUsr] cu ON cu.RowID = ts.wCrtBy
            LEFT JOIN RollsMary.dbo.mDepartment dept ON dept.wCode = ts.wDeptCd AND dept.wIsRealDept = 'Y' AND NULLIF(dept.wUserLineGrp, '') IS NULL -- 部門不是mLookup中的DEPARTMENT
            LEFT JOIN dbo.mTaskSheetType tst ON tst.wCode = ts.wTaskType AND tst.wDepartmentCode = ts.wDeptCd
            LEFT JOIN dbo.mTaskSheetType tstSub ON tstSub.wCode = ts.wSubTaskType AND tstSub.wParentCode = ts.wTaskType AND tstSub.wDepartmentCode = ts.wDeptCd
            LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ts.wUsrRid
            LEFT JOIN RollsMary.dbo.mAgent a_r ON a_r.wAgentCodeIn = ts.wRelateAgentCodeIn
            WHERE (@pCompNo IS NULL OR ts.wCompNo = @pCompNo )
                AND (@pRelatedType IS NULL OR ts.wRelatedType = @pRelatedType)
                AND (@pRelatedRid IS NULL OR ts.wRelatedRid = @pRelatedRid)
                AND (@pStatus Is NULL OR ts.wStatus = @pStatus)
        ),
        cteCount AS (
            SELECT wRecordCount = COUNT(1) FROM cteData
        )

        SELECT
            d.* ,
            c.wRecordCount
        FROM cteData d ,
             cteCount c
        ORDER BY wUpdDt Desc
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );
    END;