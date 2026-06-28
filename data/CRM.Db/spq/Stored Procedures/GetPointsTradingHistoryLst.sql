
CREATE PROCEDURE [spq].[GetPointsTradingHistoryLst]
    @pPointsTradingRid BIGINT ,
    @pLangCd VARCHAR(30) ,
    @pStatus CHAR(1) ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1
AS
    BEGIN
        SET NOCOUNT ON;	
    
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        WITH cteData AS ( 
            SELECT   
                pth.RowID ,
                pth.wPointsTradingRid ,
                pth.wAgentCodeIn ,
                ag.wAgentCode_Display ,
                pth.wTradingType ,
                pth.wDiscountRatio ,
                pth.wPoint ,
                pth.wTradingDate ,
                pth.wCurrCode ,
                pth.wMoneyAmt ,
                pth.wProfit ,
                pth.wPaymentStatus ,
                pth.wRemark ,
                pth.wCrtDt ,
                wCrtByName=CASE WHEN @pLangCd = 'en-GB' THEN u_cb.wName ELSE u_cb.wCName END  ,
                pth.wCrtBy ,
                pth.wUpdDt ,
                pth.wUpdBy ,
                wUpdByName=CASE WHEN @pLangCd = 'en-GB' THEN u.wName ELSE u.wCName END ,
                pth.wPaymentTime,
                pth.wStatus 
            FROM dbo.ePointsTradingHistory pth
            LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = pth.wUpdBy
            LEFT JOIN RollsMary.dbo.mUsr u_cb ON u_cb.RowID = pth.wCrtBy
            LEFT JOIN RollsMary.dbo.mAgent ag ON pth.wAgentCodeIn = ag.wAgentCodeIn
            WHERE pth.wPointsTradingRid = @pPointsTradingRid
                AND (@pStatus IS NULL OR @pStatus=' ' OR pth.wStatus = @pStatus)
        ),
        cteCount AS ( 
            SELECT wRecordCount = COUNT(*) FROM cteData
        )
        SELECT  d.* , c.wRecordCount
        FROM cteData d ,
             cteCount c
        ORDER BY d.wUpdDt DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	    FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );

    END;