CREATE PROCEDURE [spq].[GetBookingPickUpByTravelPkgRid]
    @pTravelPkgRid BIGINT = 0 ,
    @pLangCd VARCHAR(10) = 'en-GB'
AS
    BEGIN    
        SET NOCOUNT ON;

        SET @pTravelPkgRid = ISNULL(@pTravelPkgRid, 0);
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-GB'));
   
        SELECT
            bp.RowID ,
            bp.wBookingRid ,
            eb.wRefNo ,
            eb.wTravePkgRid ,
            bp.wTravelAgencyRid ,
            wAgencyName = mta.wName ,
            bp.wOrderNo ,
            bp.wRelatedOrderNo ,
            bp.wDisplayName ,
            bp.wServiceType ,
            bp.wApplyDt ,
            bp.wDriverName ,
            bp.wDriverPhone ,
            bp.wCarNo ,
            bp.wCurrCode ,
            bp.wPaymentMethod ,
            bp.wExpenseAmt ,
            bp.wTotalAmt ,
            bp.wTotalCost ,
            bp.wUnitPrice ,
            bp.wAdditionalExp ,
            bp.wQuantity ,
            bp.wRemark ,
            bp.wUseBlackCard ,
            bp.wStatus ,
            bp.wBookingStatus ,
            bp.wReceiptNo ,
            bp.wDepartAirport ,
            bp.wDepartDt ,
            bp.wDestination ,
            bp.wFlightNo ,
            bp.wArrivalDt ,
            bp.wCrtBy ,
            bp.wCrtDt ,
            bp.wUpdBy ,
            bp.wUpdDt ,
            bp.wSeqNo ,
            bp.wUnqualifiedRid ,
            wServiceTypeTitle = '' ,
            wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END,
            wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END
        FROM dbo.eBookingPickUpService bp
        INNER JOIN dbo.eBooking eb ON eb.RowID = bp.wBookingRid                                              
        LEFT JOIN dbo.mTravelAgency mta ON mta.RowID = bp.wTravelAgencyRid
        LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = bp.wUpdBy
        LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = bp.wCrtBy
        WHERE @pTravelPkgRid = eb.wTravePkgRid
    END;