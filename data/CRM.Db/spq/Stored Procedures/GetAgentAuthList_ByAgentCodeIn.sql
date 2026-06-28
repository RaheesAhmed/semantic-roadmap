CREATE PROCEDURE [spq].[GetAgentAuthList_ByAgentCodeIn]
    @pAgentCodeIn VARCHAR(14) ,
    @pLangCd VARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 

        SELECT wAgentCodeIn ,
               wNickName ,
               wCName = IIF(@pLangCd = 'en-GB', wEName, wCName),
               wSex ,
               wTel = CAST('' AS VARCHAR(MAX)), -- 不要在此處用子查詢，會慢很多
               wAuthIdentity = ISNULL(wAuthIdentity, 'AUTH')
        INTO #vResult
        FROM RollsMary.dbo.mAgent
        WHERE wUpLvlAgentCodeIn = @pAgentCodeIn
            AND wType = 'AUTH'
            --AND wAuthIdentity IN('AUTH','BOSS','CLIENT','FAMILY','OWNER','PARTNER','STAFF','WARRANTOR') 
            AND wStatus = 'A';

        -- Update返個電話
        UPDATE r 
        SET wTel = STUFF((SELECT CONCAT(',+', wDialCode, '-', wTel)
                          FROM RollsMary.dbo.eUsrSMSTel
                          WHERE wAgentCodeIn = r.wAgentCodeIn AND wSMSGrp = 'TEL_GRP_TEL' 
                          FOR XML PATH('')), 1, 1, N'')
        FROM #vResult r;

        SELECT * FROM #vResult;

        IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
            DROP TABLE #vResult;
    END;