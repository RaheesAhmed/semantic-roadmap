CREATE PROCEDURE [spq].[GetSMSSendToSunPeople]
(	  
    @pReqAgentCodeIn VARCHAR(14)  --- 使用戶口
)
AS
BEGIN
    SET NOCOUNT ON;

    --條件 : (要同時滿足以下2個條件)
    --1. 使用戶口的 [系統身份] = "玩家" <-- [系統身份] 是"代理" 的不用 (mAgent.wAgentType)
    --2. 使用戶口的 跟進人只有 [市場部同事] <-- 意思是沒有VIP部門的人在跟這個戶口 
　
    --*我們把同時符合這2個條件的戶口, 會統一標籤戶口Label : "MD轉介" 
　
    --發送對象 : 
    --1. 正在follow 這個戶口的 [跟進人] (現時的跟進人，不包括之前的，wYearMth=null)
    --2. sunpeople chat group : "=bw5I3"

    IF @@TRANCOUNT = 0
        SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

    SET @pReqAgentCodeIn = NULLIF(@pReqAgentCodeIn, '');

    SELECT
        u.wADAccount 
    FROM RollsMary.dbo.mAgent AS a
    INNER JOIN RollsMary.dbo.mAgentFollow AS f ON f.wAgentCodeIn = a.wAgentCodeIn AND f.wStatus = 'A'
    INNER JOIN RollsMary.dbo.mAgentFollowDtl AS l ON l.wAgentFollowRid = f.RowID AND l.wStatus = 'A'
    INNER JOIN RollsMary.dbo.mDepartment AS d ON d.RowID = f.wDeptRid
    INNER JOIN RollsMary.dbo.mUsr AS u ON u.RowID = l.wUsrRid
    WHERE (@pReqAgentCodeIn IS NOT NULL AND @pReqAgentCodeIn = a.wAgentCodeIn)
        AND NULLIF(f.wYearMth, '') IS NULL --只發給當前戶口跟進人，之前的戶口跟進人唔發： wYearMth IS NULL
        AND NULLIF(l.wYearMth, '') IS NULL --只發給當前戶口跟進人，之前的戶口跟進人唔發： wYearMth IS NULL
        AND NULLIF(d.wUserLineGrp, '') IS NULL
        AND NULLIF(u.wADAccount, '') IS NOT NULL
        AND a.wAgentType = 'GAMBLERS'
        AND d.wCode = 'DEVELOP'
    GROUP BY u.wADAccount;
END