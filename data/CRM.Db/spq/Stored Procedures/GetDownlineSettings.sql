--sp_helptext 'spq.GetDownlineSettings'


CREATE PROCEDURE [spq].[GetDownlineSettings]
    (
      @pAgentCodeIn VARCHAR(14) ,
      @pForDownline INT ,
      @pUplineSettingType VARCHAR(5) ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1 ,
      @pLangCd VARCHAR(10) = 'en-gb'
    )
AS
    BEGIN
  
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
        IF @pForDownline = 1
        BEGIN
            SELECT  * ,
                    1 AS wRecordCount
            FROM    dbo.mAccountRelationshipDownlineSetting
            WHERE   wAgentCodeIn = @pAgentCodeIn;
        END;
        ELSE
        BEGIN
            DECLARE @vAgentLevel INT ,
                    @vUplinerAgentCodeIn VARCHAR(14);

            SELECT @vAgentLevel = wAgentLevel
            FROM RollsMary.dbo.mAgent
            WHERE wAgentCodeIn = @pAgentCodeIn;

            SELECT @vUplinerAgentCodeIn = wLvlAgentCodeIn
            FROM RollsMary.dbo.mAgentLevel
            WHERE wAgentCodeIn = @pAgentCodeIn AND wAgentLevel = ( @vAgentLevel - 1 );

            IF ( @pUplineSettingType = 'DEF' )
            BEGIN
                IF NOT EXISTS(SELECT 1 FROM dbo.mAccountRelationshipDownlineSetting WHERE wAgentCodeIn=@pAgentCodeIn)
                    SET @pAgentCodeIn=null

                SELECT
                    ISNULL(upline.RowID,downline.RowID) AS RowID,
                    upline.wIsMeetingReminder,
                    upline.wIsEventReminder,
                    upline.wIsGiftReminder,
                    upline.wGiftRemark,
                    upline.wIsInvitationReminder,
                    upline.wIsBirthdayReminder,
                    upline.wIsProvideRepaymentStatus,
                    upline.wBirthdayMealPresentArrangement,
                    upline.wTargetAchievedGift,
                    upline.wEventInvitation,
                    upline.wWaytoRemind,
                    upline.wWaytoRemindRemarks,
                    upline.wIsResponsibleForExpenses,
                    upline.wUplineSettingsType,
                    ISNULL(upline.wAgentCodeIn,downline.wAgentCodeIn) AS wAgentCodeIn ,
                    ISNULL(upline.wDownlineAgentCodeIn,downline.wDownlineAgentCodeIn) AS wDownlineAgentCodeIn, 
                    ISNULL(upline.wCrtDt,downline.wCrtDt) AS wCrtDt,
                    ISNULL(upline.wCrtBy,downline.wCrtBy) AS wCrtBy,
                    ISNULL(upline.wUpdDt,downline.wUpdDt) AS wUpdDt,
                    ISNULL(upline.wUpdBy,downline.wUpdBy) AS wUpdBy,
                    1 AS wRecordCount
                FROM dbo.mAccountRelationshipDownlineSetting  upline
                INNER JOIN RollsMary.dbo.mAgent a ON upline.wAgentCodeIn =a.wUpLvlAgentCodeIn 
                LEFT JOIN dbo.mAccountRelationshipDownlineSetting downline ON downline.wAgentCodeIn=a.wAgentCodeIn
                WHERE (@pAgentCodeIn IS NULL OR downline.wAgentCodeIn = @pAgentCodeIn)
                    AND downline.wDownlineAgentCodeIn IS NULL
                    AND upline.wDownlineAgentCodeIn IS NULL
                    AND upline.wAgentCodeIn = @vUplinerAgentCodeIn;
            END
            ELSE
            BEGIN
                DECLARE @wUplineSettingsType VARCHAR(5);
                        
                SELECT @wUplineSettingsType = wUplineSettingsType
                FROM dbo.mAccountRelationshipDownlineSetting
                WHERE  wAgentCodeIn = @vUplinerAgentCodeIn AND wDownlineAgentCodeIn = @pAgentCodeIn

                --PRINT @wUplineSettingsType;

                IF ( LEN(@wUplineSettingsType) > 0 AND @wUplineSettingsType = 'DEF')
                BEGIN
                    SELECT
                        ISNULL(upline.RowID,downline.RowID) AS RowID,
                        downline.wIsMeetingReminder,
                        downline.wIsEventReminder,
                        downline.wIsGiftReminder,
                        downline.wGiftRemark,
                        downline.wIsInvitationReminder,
                        downline.wIsBirthdayReminder,
                        downline.wIsProvideRepaymentStatus,
                        downline.wBirthdayMealPresentArrangement,
                        downline.wTargetAchievedGift,
                        downline.wEventInvitation,
                        downline.wWaytoRemind,
                        downline.wWaytoRemindRemarks,
                        downline.wIsResponsibleForExpenses,
                        downline.wUplineSettingsType,
                        ISNULL(upline.wAgentCodeIn,downline.wAgentCodeIn) AS wAgentCodeIn ,
                        ISNULL(upline.wDownlineAgentCodeIn,downline.wDownlineAgentCodeIn) AS wDownlineAgentCodeIn, 
                        ISNULL(upline.wCrtDt,downline.wCrtDt) AS wCrtDt,
                        ISNULL(upline.wCrtBy,downline.wCrtBy) AS wCrtBy,
                        ISNULL(upline.wUpdDt,downline.wUpdDt) AS wUpdDt,
                        ISNULL(upline.wUpdBy,downline.wUpdBy) AS wUpdBy,
                        1 AS wRecordCount
                    FROM dbo.mAccountRelationshipDownlineSetting downline
                    LEFT JOIN dbo.mAccountRelationshipDownlineSetting upline ON upline.wDownlineAgentCodeIn = downline.wAgentCodeIn AND upline.wAgentCodeIn = @vUplinerAgentCodeIn
                    WHERE downline.wAgentCodeIn = @pAgentCodeIn AND downline.wDownlineAgentCodeIn IS NULL;
                END
                ELSE
                BEGIN
                    SELECT
                        * ,
                        1 AS wRecordCount
                    FROM dbo.mAccountRelationshipDownlineSetting
                    WHERE wAgentCodeIn = @vUplinerAgentCodeIn
                        AND wDownlineAgentCodeIn = @pAgentCodeIn
                        AND wUplineSettingsType <> 'DEF';
                END;
            END;
        END;
    END;