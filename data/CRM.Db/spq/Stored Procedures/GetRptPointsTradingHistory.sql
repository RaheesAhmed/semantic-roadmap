

CREATE PROCEDURE [spq].[GetRptPointsTradingHistory]
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
	
        WITH ctePointsTrading AS (
             SELECT 
                RowID,
                wTradingStatus ,
                wAgentCodeIn,
                wTradingType
             FROM dbo.ePointsTrading pt
             WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = '' OR pt.wAgentCodeIn = @pAgentCodeIn )
                 AND ( @pTradingStatus IS NULL OR @pTradingStatus = '' OR pt.wTradingStatus = @pTradingStatus )
                 AND (@pTradingType IS NULL OR @pTradingType = ''OR pt.wTradingType = @pTradingType)
                 AND pt.wRequestDt >= @pFromDate
                 AND ( pt.wRequestDt < DATEADD(DAY, 1, @pToDate) )
                 AND (@pStatus IS NULL OR @pStatus ='' OR pt.wStatus = @pStatus) 
        ),
        cteData AS ( 
            SELECT 
                pth.RowID ,
                pth.wPointsTradingRid ,
                pth.wAgentCodeIn ,
                ptt.wTitle AS wTradingTypeName ,
                pth.wDiscountRatio ,
                pth.wPoint ,
                pth.wTradingDate ,
                pth.wCurrCode ,
                pth.wMoneyAmt ,
                pth.wProfit ,
                pts.wTitle AS wPaymentStatusName ,
                pth.wRemark ,                            
                pth.wPaymentTime,
                pth.wCrtDt,
                --ps.wTitle AS wStatusName,
                ps.wTitle AS wPointsTypeName,
                wUpdByName = CASE WHEN @pLangCd = 'en-GB' THEN u.wName ELSE u.wCName END,
                ag.wAgentCode_Display ,
                wInAgentCode_Display = CASE WHEN cpt.wTradingType = 'BUY'THEN agt.wAgentCode_Display ELSE ag.wAgentCode_Display END , --買入戶口
                wInCName = CASE WHEN cpt.wTradingType = 'BUY'THEN agt.wCName ELSE ag.wCName END , --買入戶口名稱
                wOutAgentCode_Display = CASE WHEN cpt.wTradingType = 'BUY'THEN ag.wAgentCode_Display ELSE agt.wAgentCode_Display END ,--買出戶口
                wOutCName = CASE WHEN cpt.wTradingType = 'BUY'THEN ag.wCName ELSE agt.wCName END , --買出戶口名稱
                wStatusName = CASE WHEN pth.wStatus = 'A' THEN N'有效' ELSE N'中止' END
            FROM dbo.ePointsTradingHistory pth
            LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = pth.wUpdBy
            INNER JOIN ctePointsTrading cpt ON pth.wPointsTradingRid=cpt.RowID
            LEFT JOIN CRM.dbo.mLookUp ptt ON ptt.wCode = pth.wTradingType AND ptt.wType = 'POINTS_TRADING_TYPE' AND ptt.wLangCd = @pLangCd 
            LEFT JOIN CRM.dbo.mLookUp pts ON pts.wCode = pth.wPaymentStatus AND pts.wType = 'POINTS_TRADING_HISTORY_STATUS' AND pts.wLangCd = @pLangCd 
            --LEFT JOIN CRM.dbo.mLookUp ps ON ps.wCode = cpt.wTradingStatus AND ps.wType = 'POINTS_TRADING_STATUS' AND ps.wLangCd = @pLangCd
            LEFT JOIN CRM.dbo.mLookUp ps ON ps.wCode = pth.wPointsType AND ps.wType = 'POINTS_TYPE' AND ps.wLangCd = @pLangCd
            LEFT JOIN RollsMary.dbo.mAgent ag ON pth.wAgentCodeIn = ag.wAgentCodeIn        
            LEFT JOIN RollsMary.dbo.mAgent agt ON agt.wAgentCodeIn = cpt.wAgentCodeIn                               
        ),
        cteCount AS ( 
            SELECT wRecordCount = COUNT(*) FROM cteData
        )

        SELECT d.* ,
               c.wRecordCount
        FROM cteData d ,
             cteCount c
        ORDER BY d.RowID DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION ( RECOMPILE );
    END;