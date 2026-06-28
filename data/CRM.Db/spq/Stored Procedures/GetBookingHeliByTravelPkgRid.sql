CREATE PROCEDURE [spq].[GetBookingHeliByTravelPkgRid]
    @pTravelPkgRid BIGINT = 0 ,
    @pLangCd VARCHAR(10) = 'en-GB'
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pTravelPkgRid = ISNULL(@pTravelPkgRid, 0);
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-GB'));
	
        SELECT
            bh.RowID ,
            bh.wBookingRid ,
            eb.wRefNo ,
            bh.wTicketId ,
            bh.wOrderNo ,
            bh.wBookingLocation ,
            bh.wUseBlackCardFlag ,
            bh.wPaymentMethod ,
            bh.wReceiptNo ,
            bh.wRouteRid ,
            wRoute = CONCAT(r.wRouteFrom, IIF(r.wIsTwoWay = 'Y', '<->', '->'), r.wRouteTo),
            bh.wDepartDt ,
            wDepartDateTime = FORMAT(bh.wDepartDt, 'yyyy-MM-dd HH:mm:ss'), -- 時間要用字符串，否則有時區偏差問題
            bh.wUnitAmt ,
            bh.wQuantity ,
            bh.wExpAmt ,
            bh.wTotalAmt ,
            bh.wCost ,
            bh.wCurrCode ,
            bh.wAdditionalExp ,
            bh.wRemark ,
            bh.wSeqNo ,
            bh.wCrtDt ,
            bh.wCrtBy ,
            bh.wUpdDt ,
            bh.wUpdBy ,
            bh.wBookingStatus ,
            bh.wHandlingFee ,
            eb.wDebitDt ,
            eb.wDebitAgentCodeIn,
            eb.wDebitCustomerRid,
            eb.wDebitCounterRid ,
            eb.wTravePkgRid ,
            wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END,
            wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END
        FROM CRM.dbo.eBookingHeli bh
        INNER JOIN dbo.eBooking eb ON eb.RowID = bh.wBookingRid
        LEFT JOIN dbo.mRoute r ON r.RowID = bh.wRouteRid
        LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = bh.wUpdBy
        LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = bh.wCrtBy
        WHERE @pTravelPkgRid = eb.wTravePkgRid
    END;