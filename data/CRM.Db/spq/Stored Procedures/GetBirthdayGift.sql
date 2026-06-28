CREATE PROCEDURE [spq].[GetBirthdayGift]
    @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        SELECT 
            RowID,
            wBirthdayRid,
            wGiftReason,
            wGiftDescription,
            wBudgetCurrency,
            wBudgetAmt,
            wCostCurrency ,
            wCostAmt,
            wContactWay,
            wTelNumber,
            wWhatsappNumber,
            wWeChatNumber,
            wWeChatName,
            wRemark ,
            wSource,
            wStatus,
            wCrtBy,
            wCrtDt,
            wUpdBy,
            wUpdDt,
            wActionType = CHAR(85)  
        FROM dbo.eBirthdayGift
        WHERE @pRowID = RowID                                                 
    END;