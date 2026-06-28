CREATE PROCEDURE [spq].[GetBookingAirTicketByBookingRid]
(
    @pBookingRid BIGINT ,
    @pLangCd VARCHAR(10) = 'zh-TW'
)
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pBookingRid = ISNULL(@pBookingRid, 0);
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'zh-TW'));

        SELECT
            bat.RowID ,
            bat.wBookingRid ,
            bat.wSeqNo ,
            bat.wOrderNo ,
            bat.wFlightType ,
            bat.wTravelAgencyRid ,
            bat.wExpiryDt ,
            bat.wQuantity ,
            bat.wExpAmt ,
            bat.wTotalAmt ,
            bat.wTotalCost ,
            bat.wIsRefund ,
            bat.wChangeTicket ,
            bat.wPaymentMethod ,
            bat.wReceiptNo ,
            bat.wCurrCode ,
            bat.wAdditionalExp ,
            bat.wRemark ,
            bat.wBookingStatus ,
            bat.wUnqualifiedRid ,
            bat.wStatus ,
            bat.wCrtDt ,
            bat.wCrtBy ,
            bat.wUpdDt ,
            bat.wUpdBy ,
            eb.wRefNo ,
            eb.wTravePkgRid,
            wUpdByCName = IIF(@pLangCd = 'en-gb', usr.wName, usr.wCName),
            wCreatedByCName = IIF(@pLangCd = 'en-gb', cusr.wName, cusr.wCName)
        FROM dbo.eBookingAirTicket AS bat
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = bat.wBookingRid
        LEFT JOIN RollsMary.dbo.mUsr AS usr ON usr.RowID = bat.wUpdBy
        LEFT JOIN RollsMary.dbo.mUsr AS cusr ON cusr.RowID = bat.wCrtBy
        WHERE @pBookingRid = bat.wBookingRid;		
    END;