CREATE PROCEDURE [spq].[GetVIPPersonShip]
    @pVIPPersonRid BIGINT
AS
    BEGIN
        SET NOCOUNT ON;      
	
        SELECT 
            wVIPPersonRid,
            wVIPPersonRefRid,
            wIsBirthday, -- 是否生成生日記錄(wVIPPersonRid == wVIPPersonRefRid)
            wUpdBy,
            wUpdDt
        FROM dbo.eVIPPersonShip
	    WHERE @pVIPPersonRid = wVIPPersonRid                                                
    END;