CREATE PROCEDURE [spq].[GetPointsTrading]
    @pRowID BIGINT ,
    @pLangCd VARCHAR(10) ,
    @pStatus CHAR(1)
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;      
			  
        SELECT  pt.RowID ,
                pt.wRequestDt ,
                pt.wTargetExpiryDate ,
                pt.wTargetAmt ,
                pt.wTargetDiscountRatio ,
                pt.wAmtDone ,
                pt.wAgentCodeIn ,
                ag.wAgentCode_Display ,
                pt.wPointsType ,
                pt.wTradingType ,
                pt.wTradingStatus ,
                pt.wStatus ,
                pt.wCrtDt ,
                pt.wCrtBy ,
                CASE WHEN @pLangCd = 'en-GB' THEN u_cb.wName
                     ELSE u_cb.wCName
                END AS wLatestCreatedByCName ,
                pt.wUpdDt ,
                pt.wUpdBy ,
                CASE WHEN @pLangCd = 'en-GB' THEN u.wName
                     ELSE u.wCName
                END AS wUpdByName,
                pt.wOutstandAmt,
                pt.wFollowStaffRid 
        FROM    dbo.ePointsTrading pt
                LEFT JOIN RollsMary.dbo.mAgent ag ON pt.wAgentCodeIn = ag.wAgentCodeIn
                LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = pt.wUpdBy
                LEFT JOIN RollsMary.dbo.mUsr u_cb ON u_cb.RowID = pt.wCrtBy
        WHERE   pt.RowID = @pRowID
                AND pt.wStatus = @pStatus;
    END;