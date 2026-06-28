
CREATE PROCEDURE [spq].[GetBookingFerryByBookingRid]
(
    @pBookingRid BIGINT ,
    @pLangCd VARCHAR(10)
)
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pBookingRid = ISNULL(@pBookingRid, 0);
		SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-GB'));

        SELECT
            bf.RowID ,
            eb.wDebitDt ,
            bf.wBookingRid ,
            eb.wRefNo ,
            wDebitServiceCounter = eb.wDebitCounterRid,
            wDebitServiceCounterName = sc.wName ,
            wDebitAccount = eb.wDebitAgentCodeIn,
            eb.wDepositAmt ,
            daAgent.wAgentCode_Display ,
            wDebitClient = eb.wDebitCustomerRid,
            wDebitClientName = '' ,
            bf.wPaymentMethod ,
            bf.wTotalAmt ,
            bf.wRouteRid ,
            bf.wDepartDt ,
            bf.wQuantity ,
            bf.wClassCd ,
            bf.wTicketType ,
            bf.wCurrCode ,
            bf.wOrderNo ,
            bf.wReceiptNo ,
            bf.wUnitAmt ,
            bf.wSeqNo ,
            bf.wExpAmt ,
            bf.wCost ,
            bf.wRemark ,
            bf.wStatus ,
            bf.wBookingStatus ,
            bf.wUnqualifiedRid ,
            bf.wUseBlackCard ,
            bf.wWaived ,
            bf.wCrtDt ,
            bf.wCrtBy ,
            bf.wUpdDt ,
            bf.wUpdBy ,
            bf.wTravelAgencyRid ,
            bf.wTicketId,
            wRoute = IIF(r.RowID IS NULL, N'', CONCAT(r.wRouteFrom, IIF(r.wIsTwoWay = 'Y', '<->', '->'), r.wRouteTo)),
            wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END,
            wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END,
            bf.wURLType  ,
            bf.wURLAddress  
        FROM dbo.eBookingFerry AS bf
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = bf.wBookingRid
        INNER JOIN RollsMary.dbo.mAgent AS daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
        INNER JOIN dbo.mServiceCounter AS sc ON sc.RowID = eb.wDebitCounterRid
        LEFT JOIN dbo.mRoute AS r ON r.RowID = bf.wRouteRid
        LEFT JOIN RollsMary.dbo.mUsr AS usr ON usr.RowID = bf.wUpdBy
        LEFT JOIN RollsMary.dbo.mUsr AS crusr ON crusr.RowID = bf.wCrtBy
        WHERE @pBookingRid = bf.wBookingRid
    END;