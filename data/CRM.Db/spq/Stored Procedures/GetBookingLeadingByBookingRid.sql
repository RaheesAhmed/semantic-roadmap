
CREATE PROCEDURE [spq].[GetBookingLeadingByBookingRid]
    @pBookingRid BIGINT,
    @pLangCd VARCHAR(10)
AS
    BEGIN  
        SET NOCOUNT ON;

        SET @pBookingRid = ISNULL(@pBookingRid, 0);
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-GB'));

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
        WHERE @pBookingRid = bl.wBookingRid
    END;