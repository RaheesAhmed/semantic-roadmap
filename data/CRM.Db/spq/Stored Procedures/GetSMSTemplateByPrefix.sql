
CREATE PROCEDURE [spq].[GetSMSTemplateByPrefix]
    (
      @pTemplateTypePrefix VARCHAR(50)
    )
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;  

        SELECT  DISTINCT
                s1.wTemplateType ,
                s1.wLang
        FROM    [RollsMary].[dbo].[mSMSLexL1] s1
        WHERE   (s1.wTemplateType LIKE @pTemplateTypePrefix + '%'
			AND s1.wTemplateType NOT LIKE '%REMINDER' AND @pTemplateTypePrefix !='SMS_CRM_PURCHASE_REMINDER')
            OR(s1.wTemplateType = @pTemplateTypePrefix AND @pTemplateTypePrefix ='SMS_CRM_PURCHASE_REMINDER');
		
    END;