CREATE PROCEDURE [spq].[GetBookingVisaByBookingRid]
    @pBookingRid BIGINT,
    @pLangCd VARCHAR(10)
AS
    BEGIN 
        SET NOCOUNT ON;
              
        SET @pBookingRid = ISNULL(@pBookingRid, 0);
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'zh-TW'));                 
        
        WITH tPassnger AS (
            SELECT wBookingRid ,
                   wTotalAmount = SUM(wAmount),
                   wTotalCost = SUM(wCost)
            FROM dbo.ePassengerDetails
            WHERE wStatus = 'A' AND wPassengerBookingStatus IN ( 'P', 'C', 'RF' )
            GROUP BY wBookingRid
        )

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
        WHERE @pBookingRid = bv.wBookingRid
    END;