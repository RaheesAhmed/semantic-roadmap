CREATE PROCEDURE [spq].[GetBookingPrivatePlaneByTravelPkgRid]
    @pTravelPkgRid BIGINT,
    @pLangCd VARCHAR(10) = 'en-gb'
AS
    BEGIN        
        SET NOCOUNT ON; 

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));
        SET @pTravelPkgRid = ISNULL(@pTravelPkgRid, 0);

 
        SELECT
            pp.RowID ,
            eb.wRefNo ,
            pp.wBookingNo ,
            pp.wBookingRid ,
            pp.wOrderNo ,
            eb.wDebitDt ,
            pp.wPaymentMethod ,
            pp.wReceiptNo ,
            eb.wDebitAgentCodeIn,
            eb.wDebitCustomerRid,
            eb.wDebitCounterRid ,
            wDepartCityCd = RTD.wCityCd ,
            wDepartAirportCd = DAP.wCity ,
            wDepartAirport = DAP.wCode + ', ' + CASE WHEN @pLangCd = 'en-gb' THEN DAP.wEName ELSE DAP.wCName END + ', ' ,  -- departure airport
            wArrivalAirportCd = AAP.wCity ,
            wArrivalAirport = AAP.wCode + ', ' + CASE WHEN @pLangCd = 'en-gb' THEN AAP.wEName ELSE AAP.wCName END + ', ' ,  -- Arrival Airport 
            RTD.wTakeOffDt ,
            RTD.wArrivalDt ,
            wReturnDepartureDateTime = ISNULL(RRTD.wTakeOffDt, '0001-01-01'),
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
        LEFT JOIN dbo.ePrivatePlaneRouteDtl RTD ON RTD.wBookingPrivatePlaneRid = pp.RowID AND RTD.wLine = 1 AND RTD.wStatus = 'A'
        LEFT JOIN dbo.mAirport DAP ON DAP.RowID = RTD.wDepartureAirportRid
        LEFT JOIN dbo.mAirport AAP ON AAP.RowID = RTD.wArrivalAirportRid
        LEFT JOIN ( SELECT RowNum = ROW_NUMBER() OVER ( PARTITION BY wBookingPrivatePlaneRid ORDER BY wLine DESC ),
                           *
                    FROM dbo.ePrivatePlaneRouteDtl
                    WHERE wIsReturn = 'Y' AND wStatus = 'A'
        ) RRTD ON RRTD.wBookingPrivatePlaneRid = pp.RowID AND RRTD.RowNum = 1
        LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = pp.wUpdBy
        LEFT  JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = pp.wCrtBy
        WHERE @pTravelPkgRid = eb.wTravePkgRid;
    END;