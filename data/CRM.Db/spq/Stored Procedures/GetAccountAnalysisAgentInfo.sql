
CREATE PROCEDURE [spq].[GetAccountAnalysisAgentInfo]
    @pAgentCodeIn VARCHAR(14) ,
    @pLangCd VARCHAR(30)
AS
    BEGIN
        SET NOCOUNT ON;
        IF @@TRANCOUNT = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

	;
        WITH    cteAgentBal
                  AS ( SELECT   wAgentCodeIn ,
                                wCapital = ISNULL(SUM(ab.wCapitalAmt
                                                      + ab.wForeignCapitalAmt),
                                                  0)
                       FROM     RollsMary.dbo.mAgentBal ab
                       WHERE    ab.wAgentCodeIn = @pAgentCodeIn
                       GROUP BY wAgentCodeIn
                     )
            SELECT
		-- Agent Account 
                    a.wAgentCodeIn ,
                    a.wAgentCode_Display ,
                    wName = CASE WHEN @pLangCd = 'zh-TW' THEN a.wCName
                                 ELSE a.wEName
                            END ,
		-- Owner
                    wOwnerName = CASE WHEN @pLangCd = 'zh-TW' THEN aOwn.wCName
                                      ELSE aOwn.wEName
                                 END ,
		-- Follow Team
                    wFollowTeamName = t.wName ,
		-- Share holder
                    wIsShareholder = CASE WHEN ISNULL(ab.wCapital, 0) > 0
                                          THEN 'Y'
                                          ELSE 'N'
                                     END ,
		-- Level
                    a.wAccountType , 
		-- Line Level
                    a.wAgentLevel , 
		-- Account Type
                    a.wAgentType ,
		-- Upline Agent
                    a.wUpLvlAgentCodeIn ,
                    wUpLvlName = CASE WHEN @pLangCd = 'zh-TW' THEN a.wCName
                                      ELSE a.wEName
                                 END ,
                    wUpLvlAgentCode_Display = aUp.wAgentCode_Display , 
		-- Account Status
                    a.wStatus
            FROM    RollsMary.dbo.mAgent a
                    LEFT JOIN RollsMary.dbo.mAgentExt ae ON a.wAgentCodeIn = ae.wAgentCodeIn
                    LEFT JOIN RollsMary.dbo.mAgent aOwn ON a.wAgentCode = aOwn.wAgentCode
                                                           AND aOwn.wType = 'AUTH'
                                                           AND aOwn.wAuthIdentity = 'OWNER'
                                                           AND aOwn.wStatus = 'A'
                    LEFT JOIN RollsMary.dbo.mAgentFollow af ON ae.wAgentCodeIn = af.wAgentCodeIn
                                                              AND a.wStatus = 'A'
                    LEFT JOIN RollsMary.dbo.mTeam t ON af.wTeamRid = t.RowId
                    LEFT JOIN cteAgentBal ab ON a.wAgentCodeIn = ab.wAgentCodeIn
                    LEFT JOIN RollsMary.dbo.mAgent aUp ON a.wUpLvlAgentCodeIn = aUp.wAgentCodeIn
            WHERE   a.wAgentCodeIn = @pAgentCodeIn;

    END;