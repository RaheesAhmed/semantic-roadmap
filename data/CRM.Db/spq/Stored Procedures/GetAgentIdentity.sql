CREATE PROCEDURE [spq].[GetAgentIdentity]
    @pAgentCode NVARCHAR(20)
AS
BEGIN
    DECLARE @sAgentCode NVARCHAR(20);
    DECLARE @sAgentCodeIn VARCHAR(14);
	DECLARE @sAgentCode_Src NVARCHAR(20);
	DECLARE @sAgentCode_Old NVARCHAR(20);
	DECLARE @sAgentCode_Display NVARCHAR(30);
    DECLARE @sCName NVARCHAR(30);
	DECLARE @sEName NVARCHAR(40);

    SELECT TOP 1 
        @sAgentCode = wAgentCode,
        @sAgentCodeIn = wAgentCodeIn,
        @sAgentCode_Src = wAgentCode_Src,
	    @sAgentCode_Old = wAgentCode_Old,
	    @sAgentCode_Display = wAgentCode_Display,
        @sCName = wCName,
	    @sEName = wEName
    FROM RollsMary.dbo.mAgent
    WHERE wStatus='A'
        AND wType NOT IN ('AUTH')
        AND (wAgentCode=@pAgentCode Or wAgentCode_Old=@pAgentCode Or wAgentCode_Src=@pAgentCode Or wAgentCode_Display=@pAgentCode )

    SELECT
        wAgentCode = @sAgentCode,
        wAgentCodeIn = @sAgentCodeIn,
        wAgentCode_Src = @sAgentCode_Src ,
        wAgentCode_Old = @sAgentCode_Old,
        wAgentCode_Display = @sAgentCode_Display,
        wCName = @sCName,
        wEName = @sEName,
        wShareLevel,
        wAgentLevel,
        wIsCapital,
        wDirectCredit,
        wIsCredit,
        wAgentType,
        wIsDownLevel,
        wAgentIdentity
    FROM RollsMary.dbo.fnGetAgentIdentity(@sAgentCodeIn);
END