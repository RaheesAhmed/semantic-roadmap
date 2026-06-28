CREATE PROCEDURE [spq].[GetBookingTourGuideByBookingRid]
    @pBookingRid BIGINT,
    @pLangCd VARCHAR(10)
AS
    BEGIN  
	    SET NOCOUNT ON;

        SET @pBookingRid = ISNULL(@pBookingRid, 0);
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-GB'));
        
        SELECT
            btg.RowID ,
            btg.wBookingRid ,
            eb.wRefNo ,
            btg.wRegion ,
            btg.wTravelAgencyRid ,
            wAgencyName = ta.wName ,
            btg.wOrderNo ,
            btg.wStartDt ,
            btg.wEndtDt ,
            btg.wPaymentMethod ,
            btg.wPeriod ,
            btg.wReceiptNo ,
            btg.wExpenseAmt ,
            btg.wTotalAmt ,
            btg.wCost ,
            btg.wAdditionalExp ,
            btg.wCurrCode ,
            btg.wRemark ,
            btg.wStatus ,
            btg.wLang ,
            btg.wBookingStatus ,
            btg.wCrtBy ,
            btg.wCrtDt ,
            btg.wUpdBy ,
            btg.wUpdDt ,
            btg.wSeqNo ,
            btg.wUnqualifiedRid ,
            btg.wIsUseBlackCard,
            wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END,
            wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END
        FROM dbo.eBookingTourGuide btg
        INNER JOIN dbo.eBooking eb ON eb.RowID = btg.wBookingRid                                              
        LEFT JOIN dbo.mTravelAgency ta ON ta.RowID = btg.wTravelAgencyRid
        LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = btg.wUpdBy
        LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = btg.wCrtBy
        WHERE @pBookingRid = btg.wBookingRid
    END;