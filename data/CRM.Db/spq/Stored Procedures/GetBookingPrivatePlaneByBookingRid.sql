CREATE PROCEDURE [spq].[GetBookingPrivatePlaneByBookingRid]
    @pBookingRid BIGINT = 0 ,
    @pLangCd VARCHAR(10) = 'en-gb'
AS
    BEGIN        
        SET NOCOUNT ON; 

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));
        SET @pBookingRid = ISNULL(@pBookingRid, 0);

        SELECT
                pp.RowID ,
                pp.wBookingRid ,
                eb.wRefNo ,
                pp.wBookingNo ,
                pp.wOrderNo ,
                eb.wDebitDt ,
                pp.wPaymentMethod ,
                pp.wReceiptNo ,
                eb.wDebitAgentCodeIn ,
                eb.wDebitCustomerRid ,
                eb.wDebitCounterRid ,
                pp.wPlaneModel ,
                pp.wBookingType ,
                pp.wSupplier ,
                pp.wHotelRid ,
                pp.wTravelAgencyRid ,
                pp.wSeatNo ,
                pp.wIsSmoking ,
                pp.wServiceLang ,
                pp.wHasWifi ,
                pp.wNoOfServiceStaff ,
                pp.wExpAmt ,
                pp.wTotalAmt ,
                pp.wCurrCode ,
                pp.wExtraFee ,
                pp.wConfirmPassengerNo ,
                pp.wChangeOrderCount ,
                pp.wBookingStatus ,
                pp.wUnqualifiedRid ,   
                pp.wRemark ,
                pp.wCrtDt ,
                pp.wCrtBy ,
                pp.wUpdDt ,
                pp.wUpdBy ,
                pp.wTotalCost ,
                pp.wIsUseBlackCard ,
                pp.wStatus ,
                pp.wCancelDt ,
                pp.wCancelReason ,
                wUpdByCName = IIF(@pLangCd = 'en-gb', usr.wName, usr.wCName) ,
                wCreatedByCName = IIF(@pLangCd = 'en-gb', crusr.wName, crusr.wCName)
        FROM dbo.eBookingPrivatePlane pp
        INNER JOIN dbo.eBooking eb ON eb.RowID = pp.wBookingRid
        LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = pp.wUpdBy
        LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = pp.wCrtBy
        WHERE @pBookingRid = pp.wBookingRid
    END;