
CREATE PROCEDURE [spq].[GetGift]
    @pRowID BIGINT ,
    @pLangCd VARCHAR(30)
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT  g_t.RowID ,
                g_t.wRefBookingRid ,
                g_t.wRefTableName ,
                g_t.wRefTableRid ,
                g_t.wOriActionType ,
                g_t.wDebitCounterRid, -- 扣數櫃台
                g_t.wReqCounterRid , -- 要求櫃台
                g_t.wCompNo ,
                g_t.wCageCodeIn ,
                g_t.wReqDeptCd ,
                g_t.wReqStaffRid ,
                CASE WHEN wRefTableName = 'eStockSales' THEN ss.wDebitAgentCodeIn
                     WHEN g_t.wRefTableName = 'eBooking' THEN b.wReqAgentCodeIn
                     ELSE g_t.wReqAgentCodeIn
                END AS wReqAgentCodeIn ,
                g_t.wDate ,
                CASE WHEN wRefTableName = 'eStockSales' THEN CASE WHEN @pLangCd = 'en-GB' THEN a_ss.wEName
                                                                  ELSE a_ss.wCName
                                                             END
                     WHEN g_t.wRefTableName = 'eBooking' THEN CASE WHEN @pLangCd = 'en-GB' THEN a_booking_recipient.wEName
                                                                   ELSE a_booking_recipient.wCName
                                                              END
                     ELSE g_t.wRecipient
                END AS wRecipient ,
                g_t.wCurrCode ,
                g_t.wAmount ,
                g_t.wType ,
                g_t.wSubType ,
                g_t.wReasonCd ,
                g_t.wIsReceived ,
                g_t.wRemark ,
                g_t.wEventCodeRid ,
                g_t.wStatus ,
                g_t.wCrtDt ,
                g_t.wCrtBy ,
                g_t.wUpdDt ,
                g_t.wUpdBy ,
                'N' AS RecordState ,
                b.wRefNo AS wBookingRefNo ,
                ss.wRefNo AS wStockSalesRefNo ,
                wItemCName = i.wCName ,
                wItemQty = ssd.wQty ,
                wItemTotalPriceHKD = ssd.wTotalPriceHKD,
                g_t.wCost 
        FROM dbo.eGift g_t
        LEFT JOIN dbo.eStockSales ss ON ss.RowID = g_t.wRefTableRid AND g_t.wRefTableName = 'eStockSales'
        LEFT JOIN dbo.eBooking b ON b.RowID = g_t.wRefTableRid AND g_t.wRefTableName = 'eBooking'
        LEFT JOIN RollsMary.dbo.mAgent a_ss ON ss.wDebitAgentCodeIn = a_ss.wAgentCodeIn
        LEFT JOIN RollsMary.dbo.mAgent a_booking_recipient ON a_booking_recipient.wAgentCodeIn = b.wApprovalAgentCodeIn
        LEFT JOIN dbo.eStockSalesDtl ssd ON g_t.wRefTableRid = ssd.RowID
        LEFT JOIN dbo.mItem i ON ssd.wItemRid = i.RowID
        WHERE @pRowID = g_t.RowID;                                                 
    END;