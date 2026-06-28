CREATE PROCEDURE [spq].[GetBookingTourGuideByTravelPkgRid]
    @pTravelPkgRid BIGINT ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1 ,
    @pLangCd VARCHAR(10) = 'en-GB'
AS
    BEGIN  
        SET NOCOUNT ON;

        SET @pTravelPkgRid = ISNULL(IIF(@pTravelPkgRid <= 0, NULL, @pTravelPkgRid), 0);
        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'en-GB');
        SET @pPageSize = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 999);
        SET @pPageNum = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);

        WITH tResult AS (
            SELECT
                btg.RowID ,
                btg.wBookingRid ,
                eb.wTravePkgRid ,
                eb.wRefNo ,
                btg.wRegion ,
                btg.wTravelAgencyRid ,
                wAgencyName = ta.wName ,
                btg.wOrderNo ,
                eb.wDebitDt ,
                btg.wStartDt ,
                btg.wEndtDt ,
                btg.wPaymentMethod ,
                btg.wReceiptNo ,
                btg.wExpenseAmt ,
                btg.wTotalAmt ,
                btg.wCurrCode ,
                btg.wRemark ,
                btg.wStatus ,
                btg.wLang ,
                btg.wBookingStatus ,
                btg.wCrtBy ,
                btg.wCrtDt ,
                btg.wUpdBy ,
                btg.wUpdDt ,
                btg.wIsUseBlackCard,
                wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END ,
                wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END
            FROM dbo.eBookingTourGuide btg
            INNER JOIN dbo.eBooking eb ON eb.RowID = btg.wBookingRid
            LEFT JOIN dbo.mTravelAgency ta ON ta.RowID = btg.wTravelAgencyRid
            LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = btg.wUpdBy
            LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = btg.wCrtBy
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