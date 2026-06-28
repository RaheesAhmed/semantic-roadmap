CREATE PROC [spq].[GetAgentFollowForVIP]
    @pXMLAgentCodeIn XML,
    @pLangCd VARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

        DECLARE @vAgentCodeIn TABLE (
            wAgentCodeIn VARCHAR(30) PRIMARY KEY
        );   

        IF @pXMLAgentCodeIn IS NOT NULL
        BEGIN
            INSERT INTO @vAgentCodeIn ( wAgentCodeIn )
            SELECT DISTINCT
                wAgentCodeIn = T.tmp.value('@wAgentCodeIn', 'VARCHAR(30)')
            FROM @pXMLAgentCodeIn.nodes('DataSet/Record') AS T(tmp);
        END;

        WITH tAgentFollow AS (
            SELECT  af.RowID,
                    af.wTeamRid,
                    af.wDeptRid,
                    af.wAgentCodeIn,
                    wDeptCd = IIF(md.wCode = 'HOUSEKEEPER', 'VIP', 'MD')
            FROM RollsMary.dbo.mAgentFollow af
            INNER JOIN RollsMary.dbo.mDepartment AS md ON md.RowID = af.wDeptRid
            WHERE NULLIF(af.wYearMth, '') IS NULL AND af.wStatus = 'A'
                AND md.wCode IN ('HOUSEKEEPER', 'DEVELOP') AND md.wActive = 'A' -- 只需要取VIP（HOUSEKEEPER）、MD（DEVELOP）跟進
        ),
        tAgentFollowDtl AS (
            SELECT afd.RowID,
                   afd.wAgentFollowRid,
                   afd.wUsrRid,
                   wUsrCName = mu.wCName, 
                   wUsrName  = mu.wName
            FROM RollsMary.dbo.mAgentFollowDtl afd
            INNER JOIN RollsMary.dbo.mUsr AS mu ON mu.RowID = afd.wUsrRid
            WHERE NULLIF(afd.wYearMth, '') IS NULL AND afd.wStatus = 'A'
        ),
        tAgentFollowTeam AS (
            SELECT mt.RowId,
                   mt.wName
            FROM RollsMary.dbo.mTeam mt
            WHERE NULLIF(mt.wYearMth, '') IS NULL AND mt.wStatus = 'A'
                
        )

        SELECT
            af.wAgentCodeIn,
            af.wDeptRid,
            af.wDeptCd,
            wTeamRid = team.RowId,
            wTeamName = team.wName,
            wUsrRid = ISNULL(afd.wUsrRid, 0),
            wUsrName = IIF(@pLangCd = 'zh-TW', afd.wUsrCName, afd.wUsrName)
        FROM tAgentFollow af
        INNER JOIN @vAgentCodeIn ta ON ta.wAgentCodeIn = af.wAgentCodeIn
        INNER JOIN tAgentFollowTeam team ON team.RowId = af.wTeamRid
        LEFT JOIN tAgentFollowDtl afd ON afd.wAgentFollowRid = af.RowID
    END;