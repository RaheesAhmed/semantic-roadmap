CREATE PROCEDURE [spq].[GetBookingVisaByTravelPkgRid]
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
		       
        WITH tPassnger AS (
            SELECT wBookingRid ,
                   wTotalAmount = SUM(wAmount),
                   wTotalCost = SUM(wCost)
            FROM dbo.ePassengerDetails
            WHERE wStatus = 'A' AND wPassengerBookingStatus IN ( 'P', 'C', 'RF' )
            GROUP BY wBookingRid
        ),
        tResult AS (
           SELECT
                bv.RowId ,
                eb.wRefNo ,
                eb.wTravePkgRid ,
                bv.wBookingRid ,
                bv.wOrderNo ,
                bv.wUseBlackCard ,
                bv.wApplyDt ,
                bv.wPlaceOfIssue ,
                wAgencyName = mta.wName ,
                bv.wCurrCode ,
                wPaymentMethodCode = bv.wPaymentMethod ,
                bv.wExpAmt ,
                wTotalAmt = ISNULL(p.wTotalAmount, 0) ,
                wCost = ISNULL(p.wTotalCost, 0) ,
                bv.wBookingStatus ,
                bv.wUnqualifiedRid ,
                bv.wStatus ,
                bv.wCrtBy ,
                bv.wCrtDt ,
                bv.wUpdBy ,
                bv.wUpdDt ,
                bv.wTravelAgencyRid ,
                bv.wQuantity ,
                bv.wAdditionalExp ,
                bv.wRemark ,
                bv.wReceiptNo ,
                wDebitAccount = eb.wDebitAgentCodeIn ,
                eb.wDebitDt ,
                wDebitServiceCounter = eb.wDebitCounterRid ,
                wDebitClientName = '',
                eb.wReqDepartment ,
                wServiceCounter = eb.wReqCounterRid ,
                bv.wPaymentMethod ,
			    wReasonCd = ISNULL(gt.wReasonCd,''), 
			    wIsReceived = ISNULL(gt.wIsReceived, 'N'),
                wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END,
                wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END
            FROM dbo.eBookingVisa bv
            INNER JOIN dbo.eBooking eb ON eb.RowID = bv.wBookingRid
            LEFT JOIN dbo.mTravelAgency mta ON mta.RowID = bv.wTravelAgencyRid
            LEFT JOIN dbo.eGift gt ON gt.wRefBookingRid = bv.wBookingRid
            LEFT JOIN tPassnger p ON p.wBookingRid = bv.wBookingRid
            LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = bv.wUpdBy
            LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = bv.wCrtBy
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