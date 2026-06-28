-- 戶口跟進人
CREATE PROC [spq].[GetAgentFollowLst]
    @pAgentXML  XML,
    @pLangCd    VARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

        DECLARE @vAgent TABLE (wAgentCodeIn VARCHAR(30) PRIMARY KEY);

        IF @pAgentXML IS NOT NULL
        BEGIN
            INSERT INTO @vAgent (wAgentCodeIn)
            SELECT DISTINCT tmp.wAgentCodeIn
            FROM (
                SELECT wAgentCodeIn = T.tmp.value('@wAgentCodeIn',  'VARCHAR(14)')
                FROM @pAgentXML.nodes('DataSet/Record') T(tmp)
            ) tmp WHERE NULLIF(tmp.wAgentCodeIn, '') IS NOT NULL;
        END

        SELECT  ma.wAgentCodeIn,
                ma.wAgentType,
                wTeamRid = mt.RowId,
                wTeamName = mt.wName,
                wDeptCd = md.wCode,
                wDeptName = IIF(@pLangCd = 'en-GB', md.wEName, md.wCName),
                wUsrRid = mu.RowID,
                wUsrName = IIF(@pLangCd = 'en-GB', mu.wName, mu.wCName)
        FROM RollsMary.dbo.mAgent ma
        INNER JOIN RollsMary.dbo.mAgentFollow af ON af.wAgentCodeIn = ma.wAgentCodeIn
        INNER JOIN RollsMary.dbo.mAgentFollowDtl afd ON afd.wAgentFollowRid = af.RowID
        INNER JOIN RollsMary.dbo.mDepartment md ON md.RowID = af.wDeptRid
        INNER JOIN RollsMary.dbo.mTeam mt ON mt.RowId = af.wTeamRid
        INNER JOIN RollsMary.dbo.mUsr mu ON mu.RowID = afd.wUsrRid
        INNER JOIN @vAgent va ON va.wAgentCodeIn = ma.wAgentCodeIn
        WHERE af.wStatus = 'A' AND af.wYearMth = ''
            AND afd.wStatus = 'A' AND afd.wYearMth = '';
    END