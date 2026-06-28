CREATE Proc [spq].[GetVIPPersonLstByAgentCode]
    @pAgentCode NVARCHAR(30),
    @pLangCd VARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

        DECLARE @sAgentCodeIn VARCHAR(14);

        SELECT TOP(1) 
            @sAgentCodeIn = wAgentCodeIn
        FROM RollsMary.dbo.mAgent
        WHERE wStatus='A'
            AND ( wAgentCode = @pAgentCode 
               Or wAgentCode_Old = @pAgentCode 
               Or wAgentCode_Src = @pAgentCode 
               Or wAgentCode_Display = @pAgentCode 
            )
            AND  wType NOT IN ('AUTH');

        SELECT
            wVIPPersonRid = mp.RowID,
            mp.wPersonName,
            ma.wAgentCodeIn,
            ma.wAgentCode_Display,
            wAgentName = IIF(@pLangCd = 'zh-TW', ma.wCName, ma.wEName)
        FROM dbo.mVIPPerson mp
        INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = mp.wAgentCodeIn
        WHERE mp.wAgentCodeIn = @sAgentCodeIn
            AND mp.wStatus = 'A';
    END;