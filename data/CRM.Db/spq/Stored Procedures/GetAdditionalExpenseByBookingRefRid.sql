
CREATE PROCEDURE [spq].[GetAdditionalExpenseByBookingRefRid]
(
    @pBookingRefRid BIGINT ,
    @pLangCd VARCHAR(10) = 'zh-TW'
)
AS
    BEGIN      
        SET NOCOUNT ON;
    
        SET @pBookingRefRid = ISNULL(@pBookingRefRid, 0);
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'zh-TW'));

        SELECT
            eb.wRefNo ,
            eb.wDebitDt ,
            wDebitServiceCounter = sc.wName ,
            eb.wDebitCounterRid ,
            daAgent.wAgentCode_Display ,
            wDebitAccount = eb.wDebitAgentCodeIn ,
            wDebitClientName = '' ,
            wDebitClient = eb.wDebitCustomerRid ,
            wExpenseTypeName = et.wName ,
            wExpenseSubtypeName = est.wName ,
            wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END,
            wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END,
            wParentRefNo = b.wRefNo,
            wParentBookingType = b.wBookingType,
            ae.*
        FROM dbo.eAdditionalExpense AS ae
        INNER JOIN dbo.eBooking AS eb ON  eb.RowID = ae.wBookingRefRid -- 其他消費本身
        INNER JOIN RollsMary.dbo.mAgent AS daAgent ON daAgent.wAgentCodeIn =  eb.wDebitAgentCodeIn
        INNER JOIN dbo.mServiceCounter AS sc ON sc.RowID =  eb.wDebitCounterRid                
        LEFT JOIN dbo.eBooking AS b ON b.RowID = ae.wBookingRid -- 相關預訂
        LEFT JOIN dbo.mExpenseType AS et ON et.RowID = ae.wExpenseType
        LEFT JOIN dbo.mExpenseSubtype AS est ON est.RowID = ae.wExpenseSubtype
        LEFT JOIN RollsMary.dbo.mUsr AS usr ON usr.RowID = ae.wUpdBy
        LEFT JOIN RollsMary.dbo.mUsr AS crusr ON crusr.RowID = ae.wCrtBy
        WHERE @pBookingRefRid = ae.wBookingRefRid;
    END;