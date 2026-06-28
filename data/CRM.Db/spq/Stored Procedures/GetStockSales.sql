
CREATE PROCEDURE [spq].[GetStockSales] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT  ss_t.RowID ,
                ss_t.wDebitCounterRid ,
                ss_t.wDebitCompNo ,
                ss_t.wOutWarehouseRid ,
                ss_t.wRefNo ,
                ss_t.wSalesType ,
                ss_t.wPaymentMethod ,
                ss_t.wSalesDt ,
                ss_t.wSalesDeptCd ,
                ss_t.wDebitDt ,
                ss_t.wSalesmanRid ,
                ss_t.wDebitAgentCodeIn ,
                ss_t.wRecipientAgentCodeIn ,
                ss_t.wCurrCode ,
                ss_t.wSalesTotalPrice ,
                ss_t.wExpenseAmount ,
                ss_t.wGiftReasonCd ,
                ss_t.wSalesStatus ,
                ss_t.wStatus ,
                ss_t.wCrtDt ,
                ss_t.wCrtBy ,
                ss_t.wUpdDt ,
                ss_t.wUpdBy ,
                ss_t.wCancelDebitBy ,
                ss_t.wCancelDebitDt ,
                ss_t.wCancelBy ,
                ss_t.wCancelDt ,
                ss_t.wCancelReasonCd ,
                ss_t.wCancelOtherReason ,
                'N' AS RecordState,
                ss_t.wTotalCost,
                ss_t.wRemark ,
                ss_t.wIsBorrowGoods,
                ss_t.wPickupDt 
        FROM    dbo.eStockSales ss_t
        WHERE   @pRowID = ss_t.RowID;                                                 
    END;