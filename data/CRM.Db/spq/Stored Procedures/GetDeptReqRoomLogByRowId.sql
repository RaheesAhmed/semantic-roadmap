
CREATE PROCEDURE [spq].[GetDeptReqRoomLogByRowId]
	@pRowID BIGINT,
    @pLangCd VARCHAR(10) = 'zh-TW'
AS
BEGIN
    SET NOCOUNT ON;	  
	
    SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

    SELECT 
        dlog.RowID, 
        dlog.wAgentCodeIn, 
        dlog.wRemark, 
        wRemarkDt = FORMAT(dlog.wRemarkDt, 'yyyy-MM-dd HH:mm:ss'), 
        dlog.wStatus,
        dlog.wCrtDt,
        wUpdByDept = CASE mu.wDept WHEN 'DEVELOP'   THEN 'MD'
                                   WHEN 'ROOM'      THEN 'CS'
                                   WHEN 'HOUSEKEEPER' THEN 'VIP'
                                   ELSE NULL
                     END,
        wUpdByName = IIF(@pLangCd = 'en-GB', mu.wName, mu.wCName), 
        dlog.wUpdDt
    FROM dbo.eDeptReqRoomLog dlog
    LEFT JOIN RollsMary.dbo.mUsr mu ON mu.RowID = dlog.wUpdBy
    WHERE @pRowID = dlog.RowID;                                           
END;