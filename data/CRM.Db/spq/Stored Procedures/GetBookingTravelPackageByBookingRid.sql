CREATE PROCEDURE [spq].[GetBookingTravelPackageByBookingRid]
(
@pBookingRid BIGINT ,
@pLangCd VARCHAR(10)
)
AS
    BEGIN
        SET NOCOUNT ON;
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        

        SET @pBookingRid = ISNULL(IIF(@pBookingRid <= 0, NULL, @pBookingRid), 0);
        SET @pLangCd = LOWER(ISNULL(NULLIF(@pLangCd, ''), 'en-gb'));

        SELECT
            pkg.RowID ,
            pkg.wBookingRid ,
            pkg.wStartDt ,
            wStatDate = FORMAT(pkg.wStartDt, 'yyyy-MM-dd HH:mm:ss'), -- DateTime類型會有時區問題，此處轉成字符串，Client再轉成DateTime
            pkg.wEndDt ,
            wEndDate = FORMAT(pkg.wEndDt, 'yyyy-MM-dd HH:mm:ss'), -- DateTime類型會有時區問題，此處轉成字符串，Client再轉成DateTime
            pkg.wDeptCd ,
            pkg.wDestCd ,
            pkg.wPkgTypeCd ,
            pkg.wPaymentMethod ,
            pkg.wCurrCode ,
            pkg.wExpAmt ,
            pkg.wTotalAmt ,
            pkg.wTotalCost ,
            pkg.wRemark ,
            pkg.wBookingStatus ,
            pkg.wUnqualifiedRid ,
            pkg.wTravelAgencyRid ,
            pkg.wReceiptNo ,
            pkg.wSeqNo ,
            pkg.wCrtDt ,
            pkg.wCrtBy ,
            pkg.wUpdDt ,
            pkg.wUpdBy ,
            pkg.wStatus,
            pkg.wOrderNo,
            pkg.wTravelPkgTypeRid,
            eb.wRefNo ,
            eb.wBookingType ,
            wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END ,
            wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END,
            wDebitServiceCounter = eb.wDebitCounterRid ,
            wDebitServiceCounterName = sc.wName ,
            wDebitAccount = eb.wDebitAgentCodeIn ,
            wDebitAccountName = CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName ELSE daAgent.wCName END ,
            wDebitClient = eb.wDebitCustomerRid
        FROM dbo.eBookingTravelPackage AS pkg
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = pkg.wBookingRid
        INNER JOIN RollsMary.dbo.mAgent AS daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
        INNER JOIN dbo.mServiceCounter AS sc ON sc.RowID = eb.wDebitCounterRid
        LEFT JOIN RollsMary.dbo.mUsr AS usr ON usr.RowID = pkg.wUpdBy
        LEFT JOIN RollsMary.dbo.mUsr AS crusr ON crusr.RowID = pkg.wCrtBy
        WHERE @pBookingRid = pkg.wBookingRid;
    END;