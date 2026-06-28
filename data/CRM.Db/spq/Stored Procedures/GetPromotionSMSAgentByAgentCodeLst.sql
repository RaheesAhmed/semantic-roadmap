
CREATE PROCEDURE [spq].[GetPromotionSMSAgentByAgentCodeLst]
(
    @pAgentCode         NVARCHAR(MAX),
    @pLangCd            VARCHAR(10) = 'en-GB'
)
AS
    BEGIN
        SET NOCOUNT ON;	
        
        DECLARE @sYearMth VARCHAR(6);

        SET @pAgentCode = ISNULL(@pAgentCode, '');
        SET @pLangCd = ISNULL(@pLangCd, 'en-GB');
        
        -- 扣數戶口（wAgentCode、wAgentCode_Old、wAgentCode_Display）
        WITH tAgentCode AS (
            SELECT DISTINCT
                wAgentCode = item,
                wAgentCode_Old = item,
                wAgentCode_Src = item,
                wAgentCode_Display = item
            FROM dbo.fnSplit(@pAgentCode, ',')
        ),
        tAgentCodeIn AS (
            SELECT DISTINCT a.wAgentCodeIn
            FROM RollsMary.dbo.mAgent AS a
            INNER JOIN tAgentCode AS ac ON (a.wAgentCode = ac.wAgentCode OR a.wAgentCode_Old = ac.wAgentCode_Old OR a.wAgentCode_Display = ac.wAgentCode_Display)
            WHERE a.wStatus = 'A' AND a.wType != 'AUTH' AND a.wAgentLevel >= 3
        ),
        tTelSMS AS (
            SELECT
                s.wAgentCodeIn ,
                wSMSTel = STUFF((SELECT CONCAT(',', wDialCode, '-', wTel)
                                FROM [RollsMary].[dbo].[eUsrSMSTel]
                                WHERE wAgentCodeIn = s.wAgentCodeIn
                                FOR XML PATH('')), 1, 1, '')
            FROM RollsMary.dbo.eUsrSMSTel AS s
            WHERE wType = 'AGENT' AND wSMSGrp = 'SMS_GRP_PROMO'
            GROUP BY wAgentCodeIn
        )
	
        SELECT
            a.wAgentCode,
            a.wAgentCode_Old,
            a.wAgentCodeIn,
            a.wAgentCode_Display,
            wName = CASE WHEN @pLangCd = 'en-GB' THEN a.wEName ELSE a.wCName END,
            a.wSex,
            a.wNickName,
            wRolling = 0,
            sms.wSMSTel
        FROM RollsMary.dbo.mAgent AS a
        INNER JOIN tAgentCodeIn AS aci ON aci.wAgentCodeIn = a.wAgentCodeIn
        LEFT JOIN tTelSMS AS sms ON a.wAgentCodeIn = sms.wAgentCodeIn
        ORDER BY a.wAgentCode_Display
        OPTION(RECOMPILE);
    END;