

CREATE PROCEDURE [spq].[GetRptPointsTrading]
    @pAgentCodeIn VARCHAR(14) ,
    @pTradingStatus VARCHAR(30) ,
    @pTradingType VARCHAR(30),
    @pFromDate DATE ,
    @pToDate DATE ,
    @pLangCd VARCHAR(30) ,
    @pStatus CHAR(1) ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1
AS
    BEGIN
        SET NOCOUNT ON;	

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;   

        SET @pFromDate = ISNULL(@pFromDate, CAST('1900-01-01' AS DATETIME2));
        SET @pToDate = ISNULL(@pToDate, CAST('2099-12-31' AS DATETIME2));    					            
	
        WITH tmp AS(
            SELECT ptr.wPointsTradingRid , 
                   wRemark = STUFF((SELECT DISTINCT CONCAT( ',', CHAR(10), pr.wRemarks) 
                                   FROM dbo.ePointsTradingRemarks pr
                                   WHERE ptr.wPointsTradingRid = pr.wPointsTradingRid
                                   FOR XML PATH('')), 1, 2, N'')
            FROM   dbo.ePointsTradingRemarks ptr
            GROUP BY ptr.wPointsTradingRid
        ),
        cteData AS (
            SELECT
                pt.RowID , 
                pt.wRequestDt , 
                pt.wTargetExpiryDate ,
                pt.wTargetAmt ,
                pt.wTargetDiscountRatio ,
                pt.wAmtDone ,
                ag.wCName ,
                ag.wAgentCode_Display ,
                pt.wPointsType ,
                ps.wTitle AS wPointsTypeName ,
                pt.wTradingType ,
                ptt.wTitle AS wTradingTypeName ,
                pt.wTradingStatus ,
                pts.wTitle AS wTradingStatusName ,
                wOutstandAmt=pt.wTargetAmt-pt.wAmtDone,
                wFollowStaffName=CASE WHEN @pLangCd = 'en-GB' THEN staff.wName ELSE staff.wCName END ,
                wRemark = ISNULL(tmp.wRemark,'')
            FROM dbo.ePointsTrading pt 
            LEFT JOIN RollsMary.dbo.mAgent ag ON pt.wAgentCodeIn = ag.wAgentCodeIn
            LEFT JOIN RollsMary.dbo.mUsr staff ON staff.RowID = pt.wFollowStaffRid
            LEFT JOIN CRM.dbo.mLookUp ptt ON ptt.wCode = pt.wTradingType AND ptt.wType = 'POINTS_TRADING_TYPE' AND ptt.wLangCd = @pLangCd
            LEFT JOIN CRM.dbo.mLookUp ps ON ps.wCode = pt.wPointsType AND ps.wType = 'POINTS_TYPE' AND ps.wLangCd = @pLangCd
            LEFT JOIN CRM.dbo.mLookUp pts ON pts.wCode = pt.wTradingStatus AND pts.wType = 'POINTS_TRADING_STATUS' AND pts.wLangCd = @pLangCd
            LEFT JOIN tmp ON tmp.wPointsTradingRid = pt.RowID
            WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = '' OR pt.wAgentCodeIn = @pAgentCodeIn )
                AND ( @pTradingStatus IS NULL OR @pTradingStatus = '' OR pt.wTradingStatus = @pTradingStatus )
                AND (@pTradingType IS NULL OR @pTradingType = ''OR pt.wTradingType = @pTradingType)
                AND pt.wRequestDt >= @pFromDate
                AND ( pt.wRequestDt < DATEADD(DAY, 1, @pToDate) )
                AND (@pStatus IS NULL OR @pStatus ='' OR pt.wStatus = @pStatus)
        ),
        cteCount AS (
            SELECT wRecordCount = COUNT(*) FROM cteData
        )
        SELECT  d.* , c.wRecordCount
        FROM cteData d , cteCount c
        ORDER BY d.RowID DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	    FETCH NEXT @pPageSize ROWS ONLY
        OPTION ( RECOMPILE );
    END;