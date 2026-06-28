
CREATE PROCEDURE [spq].[GetDeptReqRoomLogLst]
	@pAgentCodeIn VARCHAR(30),
    @pLangCd VARCHAR(10) = 'zh-TW',
    @pPageSize INT = 100,
    @pPageNum INT = 1
AS
BEGIN
    SET NOCOUNT ON;	  
	
    SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
    SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');
    SET @pPageSize = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 100);
    SET @pPageNum = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);

    WITH tResult AS (
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
        WHERE dlog.wStatus = 'A'
            AND @pAgentCodeIn = dlog.wAgentCodeIn
    ),
    tCount AS (
        SELECT wRecordCount = COUNT(1) FROM tResult
    )

    SELECT 
        tResult.*, 
        wRecordCount
    FROM tResult, tCount
    ORDER BY tResult.wCrtDt DESC
    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
    FETCH NEXT @pPageSize ROWS ONLY
    OPTION (RECOMPILE );                                             
END;