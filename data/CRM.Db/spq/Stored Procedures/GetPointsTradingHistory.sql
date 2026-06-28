CREATE PROCEDURE [spq].[GetPointsTradingHistory] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;  

        SELECT  pth.RowID ,
                pth.wPointsTradingRid ,
                pth.wAgentCodeIn ,
                pth.wPointsType ,
                pth.wTradingType ,
                pth.wDiscountRatio ,
                pth.wPoint ,
                pth.wTradingDate ,
                pth.wCurrCode ,
                pth.wMoneyAmt ,
                pth.wProfit ,
                pth.wPaymentStatus ,
                pth.wRemark ,
                pth.wStatus ,
                pth.wCrtDt ,
                pth.wCrtBy ,
                pth.wUpdDt ,
                pth.wUpdBy,
                pth.wPaymentTime,
                pth.wDelReason  
        FROM    dbo.ePointsTradingHistory pth
        WHERE   pth.RowID = @pRowID;
    END;