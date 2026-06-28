
CREATE PROCEDURE [spq].[GetBookingCheckInServiceByTravelPkgRid]
    @pTravelPkgRid BIGINT ,
    @pLangCd VARCHAR(10) = 'en-gb'
AS
    BEGIN  
        SET NOCOUNT ON;   

        SET @pLangCd = LOWER(ISNULL(NULLIF(@pLangCd, ''), 'en-gb'));     
        SET @pTravelPkgRid = ISNULL(@pTravelPkgRid, 0);
		     
        SELECT
            cs.RowID ,
            cs.wBookingRid ,
            cs.wBookDt ,
            cs.wExpAmt ,
            cs.wReceiptNo ,
            cs.wCurrCode ,
            cs.wExtraFee ,
            cs.wRemark ,
            cs.wTicketCollectionRid ,
            cs.wBookingDateRid ,
            cs.wServiceCounterRid ,
            cs.wOrderNo ,
            cs.wSupplier ,
            cs.wRelatedOrderNo ,
            cs.wArrivalTimeToG15nG16 ,
            cs.wNoOfBaggage ,
            cs.wPassengerName ,
            cs.wPassengerPhoneTel ,
            cs.wVIPRoom ,
            cs.wVIPRoomPrice ,
            cs.wUnitPrice ,
            cs.wQuantity ,
            cs.wCost ,
            cs.wTotalAmt,
            cs.wSeatRequest ,
            cs.wAdditionalFee ,
            cs.wCheckInRemarks ,
            cs.wFlightNo ,
            cs.wDepartAirport ,
            cs.wDestination ,
            cs.wDepartDt ,
            cs.wArrivalDt ,
            cs.wCrtDt ,
            cs.wCrtBy ,
            cs.wUpdDt ,
            cs.wUpdBy ,
            cs.wUnqualifiedRid ,
            cs.wBookingStatus ,
            cs.wPaymentMethod ,
            cs.wStatus,
            eb.wRefNo ,
            eb.wDebitDt ,
            eb.wCancelBy,
            eb.wCancelDt ,
            eb.wCancelReasonCd ,
            eb.wReqDepartment ,
            wServiceCounter = eb.wReqCounterRid ,
            wDebitServiceCounter = eb.wDebitCounterRid ,
            wDebitAccount = eb.wDebitAgentCodeIn ,
            wDebitServiceCounterName = sc.wName ,
            daAgent.wAgentCode_Display ,
            wDebitClientName = '' ,
            etc.wTicCollPoint ,
            wTicketCollection = mt.wName ,
            wIsCollected = IIF(etc.wIsCollected = 'True','Y', 'N'),
            wUpdByCName = IIF(@pLangCd = 'en-gb', usr.wName, usr.wCName),
            wCreatedByCName = IIF(@pLangCd = 'en-gb', crusr.wName, crusr.wCName)
        FROM dbo.eBookingCheckInService cs
        INNER JOIN dbo.eBooking eb ON eb.RowID = cs.wBookingRid
        INNER JOIN dbo.mServiceCounter sc ON sc.RowID = eb.wDebitCounterRid                
        INNER JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
        LEFT JOIN dbo.eTicketCollection etc ON etc.wBookingRid = cs.wBookingRid
        LEFT JOIN dbo.mTicketCollectionPoint mt ON mt.wCode = etc.wTicCollPoint
        LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = cs.wUpdBy
        LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = cs.wCrtBy
        WHERE  @pTravelPkgRid = eb.wTravePkgRid
    END;