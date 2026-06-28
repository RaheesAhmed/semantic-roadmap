
CREATE PROCEDURE [spq].[GetVIPPersonShipLst]
    @pVIPPersonRid BIGINT,
    @pLangCd VARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;      
	    
        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

        SELECT
            ps.wVIPPersonRid, 
            ps.wVIPPersonRefRid,
            mp.wPersonName,
            eps.wIsBirthday,
            ma.wAgentCodeIn, 
            ma.wAgentCode_Display,
            wAgentName = IIF(@pLangCd = 'zh-TW', ma.wCName, ma.wEName),
            wIsSelf = IIF(ps.wVIPPersonRid = ps.wVIPPersonRefRid, 'Y', 'N'),
            mp.wStatus,
            ps.wUpdBy, 
            ps.wUpdDt
        FROM dbo.eVIPPersonShip ps
        INNER JOIN dbo.mVIPPerson mp ON mp.RowID = ps.wVIPPersonRefRid -- 相關客戶
        INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = mp.wAgentCodeIn
        INNER JOIN dbo.eVIPPersonShip eps ON eps.wVIPPersonRid = ps.wVIPPersonRefRid
	    WHERE ps.wVIPPersonRid = @pVIPPersonRid
            AND eps.wVIPPersonRid = eps.wVIPPersonRefRid
    END;