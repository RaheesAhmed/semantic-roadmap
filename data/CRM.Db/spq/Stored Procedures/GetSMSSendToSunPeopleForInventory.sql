CREATE PROCEDURE [spq].[GetSMSSendToSunPeopleForInventory]
(	  
    @pAgentCodeIn VARCHAR(14)  --- 使用戶口
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @@TRANCOUNT = 0
        SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

    SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
    DECLARE @sIsMainInCharge CHAR(1);

    --一個戶口 可以有幾個VIP跟進人，其中有一個係主，如果有勾選發給主要跟進人，如果沒有勾選，就全部發
    IF EXISTS(SELECT 1 FROM RollsMary.dbo.mAgent AS a
    INNER JOIN RollsMary.dbo.mAgentFollow AS f ON f.wAgentCodeIn = a.wAgentCodeIn AND f.wStatus = 'A'
    INNER JOIN RollsMary.dbo.mAgentFollowDtl AS l ON l.wAgentFollowRid = f.RowID AND l.wStatus = 'A'
    INNER JOIN RollsMary.dbo.mDepartment AS d ON d.RowID = f.wDeptRid
    INNER JOIN RollsMary.dbo.mUsr AS u ON u.RowID = l.wUsrRid
    WHERE (@pAgentCodeIn IS NOT NULL AND a.wAgentCodeIn = @pAgentCodeIn) 
        AND NULLIF(f.wYearMth, '') IS NULL
        AND NULLIF(l.wYearMth, '') IS NULL
        AND NULLIF(d.wUserLineGrp, '') IS NULL
        AND l.wIsMainInCharge = 'Y'
        AND d.wCode = 'HOUSEKEEPER')
    BEGIN
        SET @sIsMainInCharge = 'Y';
    END

    SELECT
        u.RowID,
        u.wCName,
        u.wName,
        u.wADAccount
    FROM RollsMary.dbo.mAgent AS a
    INNER JOIN RollsMary.dbo.mAgentFollow AS f ON f.wAgentCodeIn = a.wAgentCodeIn AND f.wStatus = 'A'
    INNER JOIN RollsMary.dbo.mAgentFollowDtl AS l ON l.wAgentFollowRid = f.RowID AND l.wStatus = 'A'
    INNER JOIN RollsMary.dbo.mDepartment AS d ON d.RowID = f.wDeptRid
    INNER JOIN RollsMary.dbo.mUsr AS u ON u.RowID = l.wUsrRid
    WHERE (@pAgentCodeIn IS NOT NULL AND a.wAgentCodeIn = @pAgentCodeIn) 
        AND NULLIF(f.wYearMth, '') IS NULL
        AND NULLIF(l.wYearMth, '') IS NULL
        AND NULLIF(d.wUserLineGrp, '') IS NULL
        AND ((@sIsMainInCharge IS NULL AND d.wCode IN ('DEVELOP', 'HOUSEKEEPER'))
            OR (d.wCode = 'DEVELOP' OR (d.wCode = 'HOUSEKEEPER' AND l.wIsMainInCharge = 'Y'))
            )

    END