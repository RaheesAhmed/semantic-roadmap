
CREATE PROCEDURE [spq].[GetAgentLstByAngentCodeLst]
(
    @pAgentCode         NVARCHAR(MAX),
    @pLangCd            VARCHAR(10) = 'en-GB'
)
AS
BEGIN
    SET NOCOUNT ON;	

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
		FROM tAgentCode AS ac
		INNER JOIN RollsMary.dbo.mAgent AS a ON (REPLACE(a.wAgentCode, ' ', '') = ac.wAgentCode OR a.wAgentCode_Old = ac.wAgentCode_Old OR REPLACE(a.wAgentCode_Display, ' ', '') = ac.wAgentCode_Display)
		WHERE a.wStatus = 'A' AND a.wType NOT IN ('AUTH')
	)
	
    SELECT
		wAgentCode=REPLACE(wAgentCode, ' ', ''),
		a.wAgentCode_Old,
		a.wAgentCodeIn,
		wAgentCode_Display=REPLACE(wAgentCode_Display, ' ', ''),
		wName = CASE WHEN @pLangCd = 'en-GB' THEN a.wEName ELSE a.wCName END,
		a.wNickName
    FROM RollsMary.dbo.mAgent AS a
	INNER JOIN tAgentCodeIn AS aci ON aci.wAgentCodeIn = a.wAgentCodeIn
    ORDER BY a.wAgentCode_Display
END