CREATE PROCEDURE [test].[GetAdditionalExpensesByBookingId]
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
        WITH    tResult
                  AS ( SELECT   luphCur.wTitle AS wCurrencyName ,
                                '' AS wDebitDate ,
                                b.wDebitCounterRid ,
                                sc.wName AS wDebitServiceCounter ,
                                daAgent.wAgentCode_Display AS wDebitAccount ,
                                '' AS wDebitClient ,
                                ISNULL(luphtc.wTitle, '') AS PaymentMethodName ,
                                ISNULL(bh.wOrderNo, ISNULL(bat.wOrderNo, '')) AS OrderNo ,
                                et.wName AS wExpenseTypeName ,
                                ISNULL(est.wName, '') AS wExpenseSubtypeName ,
                                ISNULL(luphts.wTitle, '') AS wStatusName ,
                                ae.RowID ,
                                ae.wBookingRefRid ,
                                ae.wBookingRid ,
                                eb.wRefNo ,
                                eb.wCancelDt ,
                                eb.wCancelDebitDt ,
                                eb.wCancelReasonCd ,
                                eb.wOtherReason ,
                                ae.wCost ,
                                ae.wCrtBy ,
                                ae.wCrtDt ,
                                ae.wCurrcode ,
                                ae.wExpAmt ,
                                ae.wExpenseSubtype ,
                                ae.wExpenseType ,
                                ae.wIsUseBlackCard ,
                                ae.wOrderNo ,
                                ae.wPaymentMethod ,
                                ae.wReceiptNo ,
                                ae.wRemark ,
                                ae.wRoomBookingRid ,
                                ae.wSeqNo ,
                                ae.wBookingStatus ,
                                ae.wUnqualifiedRid ,
                                ae.wTotalAmt ,
                                ae.wUpdBy ,
                                ae.wUpdDt ,
                                ae.wSpaRid ,
                                ae.wRestaurantRid ,
                                ae.wTravelAgencyRid ,
                                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     dbo.eAdditionalExpense ae
                                INNER JOIN dbo.eBooking b ON b.RowID = ae.wBookingRefRid
                                LEFT JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.wAgentCodeIn = b.wDebitAgentCodeIn
                                INNER JOIN dbo.mServiceCounter sc ON sc.RowID = b.wDebitCounterRid
                                LEFT JOIN dbo.eBooking eb ON ae.wBookingRid = eb.RowID
                                LEFT JOIN dbo.eBookingHeli bh ON bh.wBookingRid = ae.wBookingRefRid
                                LEFT JOIN dbo.eBookingAirTicket bat ON bat.wBookingRid = ae.wBookingRefRid
                                LEFT JOIN dbo.mExpenseType et ON et.RowID = ae.wExpenseType
                                LEFT JOIN dbo.mExpenseSubtype est ON est.RowID = ae.wExpenseSubtype
                                LEFT JOIN dbo.mLookUp luphtc ON luphtc.wCode = ae.wPaymentMethod
                                                              AND luphtc.wType = 'PAYMENT_TYPE'
                                                              AND luphtc.wLangCd = @pLangCd
                                LEFT JOIN dbo.mLookUp luphCur ON luphCur.wCode = ae.wCurrcode
                                                              AND luphCur.wType = 'CURRENCY'
                                                              AND luphCur.wLangCd = @pLangCd
                                LEFT JOIN dbo.mLookUp luphts ON luphts.wCode = ae.wBookingStatus
                                                              AND luphts.wType = 'ADDITIONAL_EXPENSES_STATUS'
                                                              AND luphts.wLangCd = @pLangCd
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ae.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ae.wCrtBy
                       WHERE    ae.wBookingRefRid = @pBookingRid
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