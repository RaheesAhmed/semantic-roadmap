CREATE PROCEDURE [spq].[GetAgentSMSPreference]
    (
      /*
		EXEC  [spq].[GetAgentSMSPreference] '1000031235', 'SMS_CRM_ADDITIONALEXPENSESBOOKING'
		*/
      @pAgentCodeIn VARCHAR(14) ,
      @pSmsType NVARCHAR(50)
    )
AS
    BEGIN
        SET NOCOUNT ON;
        IF @@TRANCOUNT = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        SELECT  wAgentCodeIn ,
                wSmsType ,
                wIsIgnore ,
                wUpdDt ,
                wUpdBy
        FROM    dbo.mAgentSMSPreference m
        WHERE   m.wAgentCodeIn = @pAgentCodeIn
                AND m.wSmsType = @pSmsType;
    END;