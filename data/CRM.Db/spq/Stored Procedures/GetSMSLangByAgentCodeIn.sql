
CREATE PROCEDURE [spq].[GetSMSLangByAgentCodeIn]
    @pAgentCodeIn VARCHAR(14) 
AS
    BEGIN	
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        

        
        SELECT  
                ( CASE WHEN wWrittenLang = 'ENG' THEN 'en-US'
                       WHEN wWrittenLang = 'CHN' THEN 'zh-CN'
                       WHEN wWrittenLang = 'HKG' THEN 'zh-TW'
                       WHEN wWrittenLang = 'JPN' THEN 'jp-JP'
		               WHEN wWrittenLang = 'KOR' THEN 'ko-KO'
		               WHEN wWrittenLang = 'TH'  THEN 'th-TH'
                       ELSE ''
                  END ) AS wLangCd
        FROM     RollsMary.dbo.mAgent a 
        WHERE  a.wAgentCodeIn= @pAgentCodeIn;


    END;