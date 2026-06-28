CREATE PROCEDURE [spq].[GetAgentAuthTelByCodeIn]
    @pAgentCodeIn VARCHAR(14)
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        WITH tmp AS(
            SELECT et.wAgentCodeIn,
                   et.wSMSGrp,
                   wTel=(STUFF((SELECT ',' + ( '+'+ eus.wDialCode +'-'+ eus.wTel) from RollsMary.dbo.eUsrSMSTel eus where eus.wAgentCodeIn=et.wAgentCodeIn  AND eus.wSMSGrp=et.wSMSGrp for xml path('')),1,1,''))
            FROM RollsMary.dbo.eUsrSMSTel et
            INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn=et.wAgentCodeIn
            WHERE et.wSMSGrp = 'SMS_GRP_EXPENSE'
                AND ma.wStatus = 'A'
                AND ((ma.wAgentCodeIn = @pAgentCodeIn AND ma.wType = 'AGENT')
                    OR (ma.wUpLvlAgentCodeIn = @pAgentCodeIn AND ma.wType = 'AUTH' AND ma.wAuthIdentity IN ('AUTH')) 
                )
            GROUP BY et.wAgentCodeIn ,wSMSGrp
        )

        SELECT ma.wAuthIdentity,
               wAuthIdentityName = CASE WHEN ma.wAuthIdentity='AUTH' THEN N'授權人'
                                        WHEN ma.wAuthIdentity='OWNER' THEN N'戶主'
                                        WHEN ma.wAuthIdentity='AGENT' THEN N'戶主'
                                        WHEN ma.wType = 'AGENT' THEN N'戶口' 
                                        ELSE '' END,
              ma.wCName,
              ma.wAgentCodeIn, 
              tmp.wTel,
              tmp.wSMSGrp
         FROM RollsMary.dbo.mAgent ma
         INNER JOIN tmp  ON ma.wAgentCodeIn=tmp.wAgentCodeIn      
    END;