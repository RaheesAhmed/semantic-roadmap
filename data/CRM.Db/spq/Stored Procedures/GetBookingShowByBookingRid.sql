
CREATE PROCEDURE [spq].[GetBookingShowByBookingRid]
(
    @pBookingRid BIGINT,
    @pLangCd VARCHAR(10)
)
AS
    BEGIN  
        SET NOCOUNT ON;  

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 
        
        SET @pBookingRid = ISNULL(@pBookingRid, 0);
		SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-GB'));
		
        
        SELECT
            bs.RowID ,
            bs.wBookingRid ,
            eb.wRefNo ,
            bs.wShowRid ,
            bs.wOrderNo ,
            eb.wDebitDt ,
            bs.wTravelAgencyRid ,
            wSupplier = mta.wName,
            bs.wShowDt ,
            wShowDateTime = FORMAT(bs.wShowDt, 'yyyy-MM-dd HH:mm:ss'), -- DateTime類型會有時區問題，此處轉成字符串，Client再轉成DateTime
            bs.wCurrCode ,
            bs.wTotalQuantity ,
            bs.wTotalAmt ,
            bs.wExpenseAmt ,
            bs.wTotalCost ,
            bs.wPaymentMethod ,
            bs.wReceiptNo ,
            wUseBlackCard = ISNULL(bs.wUseBlackCard, 'N'),
            bs.wRemark ,
            bs.wStatus ,
            bs.wBookingStatus ,
            bs.wUnqualifiedRid ,
            bs.wCrtBy ,
            bs.wCrtDt ,
            bs.wUpdBy ,
            bs.wUpdDt ,
            wHaveTicket = ISNULL(bs.wHaveTicket, 'N') ,
            bs.wOtherName ,
            wScalpedTicket = ISNULL(bs.wScalpedTicket, 'N'),
            bs.wGetTicketTime ,
            wGetTicketDateTime = FORMAT(bs.wGetTicketTime, 'yyyy-MM-dd HH:mm:ss'), -- DateTime類型會有時區問題，此處轉成字符串，Client再轉成DateTime
            wShowName = ms.wName  ,
            wIsShowFullDay = ISNULL(ms.wIsFullDay, 'N') ,
            eb.wReqDepartment ,
            eb.wReqAgentCodeIn ,
            wRequestedServiceCounterid = eb.wReqCounterRid ,
            eb.wDebitAgentCodeIn ,
            eb.wTravePkgRid ,
            wRequestedServiceCounter = MSC.wName ,
            daAgent.wAgentCode_Display ,
            wDebitClientName = N'' ,
            wDebitServiceCounterName = SC.wName ,
            wUpdByCName = IIF(@pLangCd = 'en-gb', usr.wName, usr.wCName ),
            wCreatedByCName = IIF(@pLangCd = 'en-gb', crusr.wName, crusr.wCName) 
        FROM dbo.eBookingShow bs
        INNER JOIN dbo.eBooking eb ON eb.RowID = bs.wBookingRid
        INNER JOIN RollsMary.dbo.mAgent daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
        INNER JOIN dbo.mServiceCounter SC ON SC.RowID = eb.wDebitCounterRid
        LEFT JOIN dbo.mServiceCounter MSC ON MSC.RowID = eb.wReqCounterRid
        LEFT JOIN dbo.mShow ms ON ms.RowID = bs.wShowRid
        LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = bs.wUpdBy
        LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = bs.wCrtBy
        LEFT JOIN dbo.mTravelAgency AS mta ON mta.RowID = bs.wTravelAgencyRid --供應商
        WHERE bs.wBookingRid = @pBookingRid
		
    END;