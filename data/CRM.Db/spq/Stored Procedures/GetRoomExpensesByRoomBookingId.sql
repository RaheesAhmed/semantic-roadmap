CREATE PROCEDURE [spq].[GetRoomExpensesByRoomBookingId]
    (
      @pBookingRid BIGINT ,
      @pLangCd VARCHAR(10) = 'en-gb' ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1   
    )
AS
    BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
        SET NOCOUNT ON;  
   
    -- Insert statements for procedure here
	-- 刪除Join mLookup 
        WITH    tResult
                  AS ( SELECT   eb.wDebitDt AS wDebitDate ,--获取房间预订-其他消费list的扣数日期
                                SC.wName AS wDebitServiceCounter ,
                                daAgent.wAgentCode_Display AS wDebitAccount ,
                                '' AS wDebitClient ,
                                '' AS PaymentMethodName ,
                                ebr.wOrderNo AS OrderNo ,
                                et.wName AS wExpenseTypeName ,
                                est.wName AS wExpenseSubtypeName ,
                                '' AS wStatusName ,
                                ae.[RowID] ,
                                ae.[wOrderNo] ,
                                ae.[wBookingRid] ,
                                eb.wRefNo,
                                ae.[wRoomBookingRid] ,
                                ae.[wBookingRefRid] ,
                                ebr.[wHotelBookingRid] ,
                                ae.[wExpenseType] ,
                                ae.[wExpenseSubtype] ,
                                ae.[wPaymentMethod] ,
                                ae.[wReceiptNo] ,
                                ae.[wExpAmt] ,
                                ae.[wTotalAmt] ,
                                ae.[wCost] ,
                                ae.[wCurrcode] ,
                                ae.[wIsUseBlackCard] ,
                                ae.[wRemark] ,
                                ae.[wSeqNo] ,
                                ae.[wCrtDt] ,
                                ae.[wCrtBy] ,
                                ae.[wUpdDt] ,
                                ae.[wUpdBy] ,
                                ae.[wBookingStatus] ,
                                ae.[wSpaRid] ,
                                ae.[wRestaurantRid] ,
                                ae.[wTravelAgencyRid] ,
                                eb.wEventCodeRid ,
                                wAgentCodeIn = eb.wDebitAgentCodeIn
                       FROM     dbo.eAdditionalExpense ae
                                INNER JOIN eBookingRoom ebr ON ebr.RowID = ae.wRoomBookingRid
                                INNER JOIN eBookingHotel ebh ON ebh.RowID = ebr.wHotelBookingRid
                                INNER JOIN eBooking eb ON eb.RowID = ae.wBookingRefRid
								INNER JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn                                
                                INNER JOIN dbo.mServiceCounter SC ON SC.RowID = eb.wDebitCounterRid                                
                                INNER JOIN dbo.mExpenseType et ON et.RowID = ae.wExpenseType
                                LEFT JOIN dbo.mExpenseSubtype est ON est.RowID = ae.wExpenseSubtype
                       WHERE    ae.wRoomBookingRid = @pBookingRid
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     tResult
                     )
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            ORDER BY wUpdDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS  
     FETCH NEXT @pPageSize ROWS ONLY;  
    END;