
CREATE PROCEDURE [spq].[GetBookingLeadingByTravelPkgRid]
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
                bl.RowID ,
                bl.wBookingRid ,
                eb.wRefNo ,
                bl.wRegion ,
                bl.wTravelAgencyRid ,
                wAgencyName = ta.wName ,
                bl.wLang ,
                bl.wOrderNo ,
                bl.wNoofPolice ,
                bl.wStartDt ,
                bl.wPaymentMethod ,
                bl.wReceiptNo ,
                bl.wExpenseAmt ,
                bl.wTotalAmt ,
                bl.wTotalCost ,
                bl.wAdditionalExp ,
                bl.wCurrCode ,
                bl.wRemark ,
                bl.wStatus ,
                bl.wBookingStatus ,
                bl.wUnqualifiedRid ,
                bl.wUseBlackCard ,
                bl.wCrtBy ,
                bl.wCrtDt ,
                bl.wUpdBy ,
                bl.wUpdDt ,
                bl.wSeqNo ,
                wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END ,
                wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END
            FROM dbo.eBookingLeading bl
            INNER JOIN dbo.eBooking eb ON eb.RowID = bl.wBookingRid                                              
            LEFT JOIN dbo.mTravelAgency ta ON ta.RowID = bl.wTravelAgencyRid
            LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = bl.wUpdBy
            LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = bl.wCrtBy
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