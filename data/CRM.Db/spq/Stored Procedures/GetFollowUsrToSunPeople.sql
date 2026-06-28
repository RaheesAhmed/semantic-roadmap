CREATE PROCEDURE [spq].[GetFollowUsrToSunPeople]
    (
      @pAgentCodeIn VARCHAR(14) ,
      @pDeptFollowUsr NVARCHAR(MAX) OUTPUT
    )
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        DECLARE @sDeptFollowUsr NVARCHAR(MAX);

        SELECT @sDeptFollowUsr=STUFF((
                            SELECT CONCAT('\r\n','[(', t.wName, ')', u.wCName, IIF(NULLIF(u.wPrivateTel, '') IS NULL, NULL, '\r\n' + IIF(NULLIF(u.wPrivateTelCountryCode, '') IS NULL, NULL, '+' + REPLACE(u.wPrivateTelCountryCode, '+', '') + '-') + u.wPrivateTel), IIF(safd.wIsMainInCharge = 'Y', N'(主)', NULL), '](', 'user://', u.wUsrId, ')')
                            FROM RollsMary.dbo.mAgent AS a
                            INNER JOIN RollsMary.dbo.mAgentFollow AS saf ON saf.wAgentCodeIn = a.wAgentCodeIn AND saf.wStatus = 'A'
                            INNER JOIN RollsMary.dbo.mAgentFollowDtl AS safd ON safd.wAgentFollowRid = saf.RowID AND safd.wStatus = 'A'
                            INNER JOIN RollsMary.dbo.mDepartment AS sd ON sd.RowID = saf.wDeptRid
                            INNER JOIN RollsMary.dbo.mUsr AS u ON u.RowID = safd.wUsrRid
                            INNER JOIN RollsMary.dbo.mTeam AS t ON t.RowId = saf.wTeamRid
                            WHERE   NULLIF(sd.wUserLineGrp, '') IS NULL
                                AND NULLIF(saf.wYearMth, '') IS NULL
                                AND NULLIF(safd.wYearMth, '') IS NULL
                                AND a.wAgentType = 'GAMBLERS'
                                AND saf.wAgentCodeIn = @pAgentCodeIn
                                AND sd.wCode = 'DEVELOP'
                            FOR XML PATH('')), 1, 4, N'');

       SET @pDeptFollowUsr= IIF(@sDeptFollowUsr IS NULL,'', CONCAT('\r\n', N'MD跟進：\r\n', @sDeptFollowUsr));
    END;