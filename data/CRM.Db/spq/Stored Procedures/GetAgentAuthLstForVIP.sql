CREATE PROCEDURE [spq].[GetAgentAuthLstForVIP] (
    @pAgentCodeIn VARCHAR(14) ,
    @pLangCd VARCHAR(10)
)
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 

        SELECT
            ma.wAgentCodeIn ,
            ma.wNickName ,
            wCName = IIF(@pLangCd = 'en-GB', ma.wEName, ma.wCName),
            ma.wSex ,
            wTel = STUFF((SELECT ',+' + ust.wDialCode + '-' + wTel
                          FROM RollsMary.dbo.eUsrSMSTel ust
                          WHERE wAgentCodeIn = ma.wAgentCodeIn
                              AND ust.wSMSGrp = 'TEL_GRP_TEL'
                              FOR XML PATH('')), 1, 2, N''),
            wAuthIdentity = ISNULL(ma.wAuthIdentity, 'AUTH')
            FROM RollsMary.dbo.mAgent AS ma
            WHERE ( ma.wUpLvlAgentCodeIn = @pAgentCodeIn)
                AND ma.wType = 'AUTH'
                AND ma.wStatus = 'A'
                AND (NULLIF(ma.wAuthIdentity, '') IS NULL OR ma.wAuthIdentity = 'AUTH' OR ma.wAuthIdentity = 'OWNER' OR ma.wAuthIdentity = 'BOSS');
    END;