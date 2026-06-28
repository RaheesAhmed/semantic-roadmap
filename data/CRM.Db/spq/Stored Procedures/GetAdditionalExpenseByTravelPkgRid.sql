CREATE PROCEDURE [spq].[GetAdditionalExpenseByTravelPkgRid]
(
    @pTravelPkgRid BIGINT ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1,
    @pLangCd VARCHAR(10) = 'zh-TW' 
)
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pTravelPkgRid = ISNULL(IIF(@pTravelPkgRid <= 0, NULL, @pTravelPkgRid), 0);
        SET @pLangCd = ISNULL(@pLangCd, 'zh-TW');
        SET @pPageSize = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 999);
        SET @pPageNum = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);

        WITH tResult AS (
            SELECT
                wCurrencyName = '' ,
                wDebitDate = eb.wDebitDt,
                eb.wDebitCounterRid ,
                wDebitServiceCounter = sc.wName ,
                wDebitAccount = daAgent.wAgentCode_Display ,
                wDebitClient = '' ,
                PaymentMethodName = '',
                OrderNo = ISNULL(bh.wOrderNo, ISNULL(bat.wOrderNo, '')) ,
                wExpenseTypeName = et.wName ,
                wExpenseSubtypeName = ISNULL(est.wName, '') ,
                wStatusName = '' ,
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
                wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END,
                wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END,
                eb.wGiftReasonCd, -- 送禮原因
                wAgentCodeIn = eb.wDebitAgentCodeIn
            FROM dbo.eAdditionalExpense AS ae
            INNER JOIN dbo.eBooking AS eb ON eb.RowID = ae.wBookingRefRid
            INNER JOIN dbo.mServiceCounter AS sc ON sc.RowID = eb.wDebitCounterRid
            LEFT JOIN RollsMary.dbo.mAgent AS daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
            LEFT JOIN dbo.eBookingHeli AS bh ON bh.wBookingRid = ae.wBookingRid
            LEFT JOIN dbo.eBookingAirTicket AS bat ON bat.wBookingRid = ae.wBookingRid
            LEFT JOIN dbo.mExpenseType AS et ON et.RowID = ae.wExpenseType
            LEFT JOIN dbo.mExpenseSubtype AS est ON est.RowID = ae.wExpenseSubtype
            LEFT JOIN RollsMary.dbo.mUsr AS usr ON usr.RowID = ae.wUpdBy
            LEFT JOIN RollsMary.dbo.mUsr AS crusr ON crusr.RowID = ae.wCrtBy
            WHERE @pTravelPkgRid = eb.wTravePkgRid
        ),
        tCount AS (
            SELECT wRecordCount = COUNT(1) FROM tResult
        )

        SELECT
            tResult.* ,
            wRecordCount
        FROM tResult , tCount
        ORDER BY wUpdDt DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY;
    END;