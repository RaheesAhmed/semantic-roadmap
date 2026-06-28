CREATE PROCEDURE [spq].[GetBookingAirTicketByTravelPkgRid]
(
    @pTravelPkgRid BIGINT ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1 ,
    @pLangCd VARCHAR(10) = 'zh-TW'
)
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pTravelPkgRid = ISNULL(IIF(@pTravelPkgRid <= 0, NULL, @pTravelPkgRid), 0);
        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');
        SET @pPageSize = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 999);
        SET @pPageNum = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);

        WITH tLookup AS (
            SELECT wCode, wTitle, wType FROM dbo.mLookUp WHERE wLangCd = @pLangCd
        ),
        tResult AS (
            SELECT
                bat.RowID ,
                bat.wBookingRid ,
                bat.wOrderNo ,
                wPerson = '',
                bat.wTravelAgencyRid ,
                bat.wFlightType ,
                wExpiryDate = bat.wExpiryDt ,
                bat.wQuantity ,
                bat.wExpAmt ,
                bat.wTotalAmt ,
                bat.wTotalCost ,
                bat.wIsRefund ,
                wChangeTicketCode = wChangeTicket ,
                wChangeTicket = lupatco.wTitle ,
                wPaymentMethodCode = bat.wPaymentMethod ,
                wPaymentMethod = luppt.wTitle ,
                bat.wReceiptNo ,
                bat.wCurrCode ,
                wCurrency = lupc.wTitle ,
                bat.wAdditionalExp ,
                bat.wRemark ,
                bat.wBookingStatus ,
                bat.wSeqNo ,
                RTD.wLine ,
                RTD.wAirline ,
                RTD.wClassCd ,
                RTD.wIsReturn ,
                RTD.wDepartFlightNo ,
                RTD.wDepartureAirportRid ,
                DepartureAirport = CASE WHEN @pLangCd = 'en-gb' THEN DAP.wEName ELSE DAP.wCName END + ', ' + DPLUP.wTitle,
                ArrivalAirport = CASE WHEN @pLangCd = 'en-gb' THEN AAP.wEName ELSE AAP.wCName END + ', ' + APLUP.wTitle ,
                RTD.wArrivalAirportRid ,
                RTD.wDepartureTerminal ,
                RTD.wArrivalTerminal ,
                RTD.wTakeOffDt AS wTakeOffDatetime ,
                RTD.wArrivalDt AS wArrivalDateTime ,
                eb.wDebitDt ,
                '' AS wCName ,
                sc.wName AS wDebitServiceCounterName ,
                eb.wDebitCounterRid wDebitServiceCounter ,
                eb.wDebitAgentCodeIn wDebitAccount ,
                CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName ELSE daAgent.wCName
                END AS wDebitAccountName ,
                eb.wDebitCustomerRid wDebitClient ,
                '' AS wDebitClientName ,
                eb.wTravePkgRid ,
                bat.wCrtDt ,
                bat.wCrtBy ,
                bat.wUpdDt ,
                bat.wUpdBy ,
                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END AS wUpdByCName ,
                CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END AS wCreatedByCName ,
                eb.wRefNo
            FROM dbo.eBookingAirTicket bat
            INNER JOIN dbo.eBooking AS eb ON eb.RowID = bat.wBookingRid
            INNER JOIN RollsMary.dbo.mAgent daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
            INNER JOIN tLookUp lupatco ON lupatco.wCode = bat.wChangeTicket AND lupatco.wType = 'AIR_TICKET_CHANGE_OPTION'
            INNER JOIN tLookup luppt ON luppt.wCode = bat.wPaymentMethod AND luppt.wType = 'PAYMENT_TYPE'
            INNER JOIN tLookup lupc ON lupc.wCode = bat.wCurrCode AND lupc.wType = 'CURRENCY'
            INNER JOIN dbo.mServiceCounter sc ON sc.RowID = eb.wDebitCounterRid
            LEFT JOIN dbo.eAirTicketRouteDtl AS RTD ON RTD.wType = 'AIRTICKET' AND RTD.wLine = 1 AND RTD.wStatus = 'A' AND RTD.wTypeRid = bat.RowID
            LEFT JOIN dbo.mAirport AAP ON AAP.RowID = RTD.wArrivalAirportRid
            LEFT JOIN tLookup APLUP ON APLUP.wCode = AAP.wCity AND APLUP.wType = 'CITY'
            LEFT JOIN dbo.mAirport DAP ON DAP.RowID = RTD.wDepartureAirportRid
            LEFT JOIN tLookup DPLUP ON DPLUP.wCode = DAP.wCity AND DPLUP.wType = 'CITY'
            LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = bat.wUpdBy
            LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = bat.wCrtBy
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