
CREATE PROCEDURE [spq].[GetBookingHeliByBookingRid]
    @pBookingRid BIGINT = 0 ,
    @pLangCd VARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;
	
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        

        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));
        SET @pBookingRid = ISNULL(@pBookingRid, 0);
        	
        SELECT
            bh.RowID ,
            bh.wBookingRid ,
            eb.wRefNo,
            bh.wTicketId ,
            bh.wOrderNo ,
            eb.wDebitDt ,
            bh.wBookingLocation ,
            bh.wUseBlackCardFlag ,
            bh.wPaymentMethod ,
            bh.wReceiptNo ,
            bh.wRouteRid ,
            eb.wDebitAgentCodeIn ,
            eb.wDebitCustomerRid ,
            eb.wDebitCounterRid ,
            bh.wDepartDt ,
            wDepartDateTime = FORMAT(bh.wDepartDt, 'yyyy-MM-dd HH:mm:ss'), -- 時間要用字符串，否則有時區偏差問題
            bh.wUnitAmt ,
            bh.wQuantity ,
            bh.wExpAmt ,
            bh.wTotalAmt ,
            bh.wCost ,
            bh.wHandlingFee ,
            bh.wCurrCode ,
            bh.wStatus ,
            bh.wBookingStatus ,
            bh.wUnqualifiedRid ,
            bh.wAdditionalExp ,
            bh.wRemark ,
            bh.wSeqNo ,
            bh.wIsCharteredFlight ,
            bh.wChangeOrderCount,
            bh.wCrtDt ,
            bh.wCrtBy ,
            bh.wUpdDt ,
            bh.wUpdBy ,
            wUpdByCName = IIF(@pLangCd = 'en-gb', usr.wName, usr.wCName),
            wCreatedByCName = IIF(@pLangCd = 'en-gb', crusr.wName, crusr.wCName)
        FROM dbo.eBookingHeli bh
        INNER JOIN dbo.eBooking eb ON eb.RowID = bh.wBookingRid
        LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = bh.wUpdBy
        LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = bh.wCrtBy
        WHERE   @pBookingRid = bh.wBookingRid
    END;