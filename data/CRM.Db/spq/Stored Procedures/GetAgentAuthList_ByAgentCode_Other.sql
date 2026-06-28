
CREATE PROCEDURE [spq].[GetAgentAuthList_ByAgentCode_Other]
    (
      @pAgentCode NVARCHAR(20) ,
      @pwLangCd VARCHAR(10)
    )
AS
    BEGIN
		SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 

		DECLARE @vResultSet TABLE (
			wAgentCodeIn VARCHAR(14), 
			wNickName NVARCHAR(200),
			wCName NVARCHAR(200),
			wSex VARCHAR(10),
			wTel VARCHAR(MAX),
			wAuthIdentity VARCHAR(50)
		);
			

		INSERT @vResultSet (wAgentCodeIn, wNickName, wCName, wSex, wTel, wAuthIdentity)
        SELECT  wAgentCodeIn ,
                wNickName ,
                CASE WHEN @pwLangCd = 'en-GB' THEN wEName
                     ELSE wCName
                END AS wCName ,
                wSex ,
                wTel = '' ,
                wAuthIdentity
        FROM    RollsMary.dbo.mAgent
        WHERE   ( wAgentCode_Old = @pAgentCode
                  OR wAgentCode = @pAgentCode
                )
                AND wType = 'AUTH'
				--AND wAuthIdentity IN('AUTH','BOSS','CLIENT','FAMILY','OWNER','PARTNER','STAFF','WARRANTOR') 
                AND wStatus = 'A';
		
		UPDATE
			t
		SET
			wTel = SUBSTRING((SELECT ',+' + ust.wDialCode + '-' + wTel FROM RollsMary.dbo.eUsrSMSTel ust WHERE wAgentCodeIn = t.wAgentCodeIn AND ust.wSMSGrp = 'TEL_GRP_TEL' FOR XML PATH('')),2,200000)
		FROM
			@vResultSet t;

		SELECT * FROM @vResultSet;

    END;