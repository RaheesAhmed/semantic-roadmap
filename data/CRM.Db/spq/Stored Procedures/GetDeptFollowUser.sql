CREATE PROCEDURE [spq].[GetDeptFollowUser]
    @pAgentCodeIn VARCHAR(14)
AS
    BEGIN

    SELECT
        a.wAgentCode ,
        a.wAgentCode_Display ,
        a.wAgentCodeIn ,
        af.wDeptRid ,
        afd.wUsrRid ,
        d.wCode AS wDeptCode
    FROM RollsMary.dbo.mAgent a
    INNER JOIN RollsMary.dbo.mAgentFollow af ON a.wAgentCodeIn = af.wAgentCodeIn AND af.wStatus = 'A' 
    INNER JOIN RollsMary.dbo.mAgentFollowDtl afd ON af.RowID = afd.wAgentFollowRid AND afd.wStatus = 'A'
    INNER JOIN RollsMary.dbo.mDepartment d ON af.wDeptRid = d.RowID AND d.wCode = 'DEVELOP'
    WHERE a.wAgentType = 'GAMBLERS' 
        AND a.wAgentCodeIn = @pAgentCodeIn
        AND NULLIF(af.wYearMth, '') IS NULL
        AND NULLIF(afd.wYearMth, '') IS NULL
        AND NULLIF(d.wUserLineGrp, '') IS NULL
    ORDER BY afd.wIsMainInCharge DESC, afd.wUpdDt
    OPTION(RECOMPILE);
END;