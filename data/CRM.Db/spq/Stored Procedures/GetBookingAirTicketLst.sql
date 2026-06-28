CREATE PROCEDURE [spq].[GetBookingAirTicketLst]
(
    @pRefNo VARCHAR(30) ,
    @pFromDebitDt DATETIME2 ,
    @pToDebitDt DATETIME2 ,
    @pDebitCounterRidXML XML ,
    @pReqDeptCode VARCHAR(30) ,
    @pFollowUpDeptCode VARCHAR(30) ,
    @pDebitAgentCodeIn VARCHAR(14) ,
    @pReqAgentCodeIn VARCHAR(14) ,
    @pTravelAgencyRid AS BIGINT ,
    @pOrderNo VARCHAR(20) ,
    @pFlightType VARCHAR(30) ,
    @pDepartureAirportRid BIGINT ,
    @pTakeOffDt DATETIME2 ,
    @pArrivalAirportRid BIGINT ,
    @pArrivalDt DATETIME2 ,
    @pTicketCollectionCdXML AS XML ,
    @pPaymentMethod VARCHAR(30) ,
    @pIsTicketCollected AS VARCHAR(10) ,
    @pBookingStatusXML XML ,
    @pSort VARCHAR(200) ,
    @pPageSize INT ,
    @pPageNum INT ,
    @pLangCd VARCHAR(10)
)
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sTakeOffDt AS DATE,
                @sArrivalDt AS DATE,
                @sDebitCounterRidCount AS INT = 0,
                @sTicketCollectionCount AS INT = 0,
                @sBookingStatusCount AS INT = 0;

        DECLARE @sData_DebitCounterRid AS TABLE (wCounterRid BIGINT PRIMARY KEY);
        DECLARE @sData_TicketCollectionPoint AS TABLE (wTicketCollectionPointRid BIGINT PRIMARY KEY);
        DECLARE @sData_BookingStatus AS TABLE (wBookingStatus VARCHAR(5) PRIMARY KEY);

        IF @pDebitCounterRidXML IS NOT NULL
        BEGIN
            INSERT INTO @sData_DebitCounterRid ( wCounterRid )
            SELECT tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
            FROM @pDebitCounterRidXML.nodes('/DataSet/Record') AS T ( tmp );

            SELECT @sDebitCounterRidCount = COUNT(1) FROM @sData_DebitCounterRid;
        END;

        IF @pTicketCollectionCdXML IS NOT NULL
        BEGIN
            INSERT INTO @sData_TicketCollectionPoint ( wTicketCollectionPointRid )
            SELECT tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
            FROM @pTicketCollectionCdXML.nodes('/DataSet/Record') AS T ( tmp );

            SELECT @sTicketCollectionCount = COUNT(1) FROM @sData_TicketCollectionPoint;
        END;

        IF @pBookingStatusXML IS NOT NULL
        BEGIN
            INSERT INTO @sData_BookingStatus ( wBookingStatus )
            SELECT tmp.value('@SelectionItem', 'VARCHAR(5)') AS SelectionItem
            FROM @pBookingStatusXML.nodes('/DataSet/Record') AS T ( tmp );

            SELECT @sBookingStatusCount = COUNT(1) FROM @sData_BookingStatus;
        END;
        
        SET @pRefNo = NULLIF(@pRefNo, '');  
        SET @pReqDeptCode = NULLIF(@pReqDeptCode, '');
        SET @pFollowUpDeptCode = NULLIF(@pFollowUpDeptCode, '');
        SET @pDebitAgentCodeIn = NULLIF(@pDebitAgentCodeIn, '');
        SET @pReqAgentCodeIn = NULLIF(@pReqAgentCodeIn, '');		
        SET @pTravelAgencyRid = IIF(@pTravelAgencyRid <= 0, NULL, @pTravelAgencyRid);
        SET @pOrderNo = NULLIF(@pOrderNo, '');
        SET @pFlightType = NULLIF(@pFlightType, '');
        SET @pDepartureAirportRid = IIF(@pDepartureAirportRid <= 0, NULL, @pDepartureAirportRid);
        SET @pArrivalAirportRid = IIF(@pArrivalAirportRid <= 0, NULL, @pArrivalAirportRid);
        SET @pPaymentMethod = NULLIF(@pPaymentMethod, '');
        SET @pIsTicketCollected = NULLIF(@pIsTicketCollected, '');
        SET @pFromDebitDt = CAST(@pFromDebitDt AS DATE);
        SET @pToDebitDt = CAST(@pToDebitDt AS DATE);
        SET @sTakeOffDt = CAST(@pTakeOffDt AS DATE);
        SET @sArrivalDt = CAST(@pArrivalDt AS DATE);
        SET @pSort = IIF(NULLIF(@pSort, '') IS NULL, '||', @pSort);
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));
        SET @pPageSize = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 100);
        SET @pPageNum = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);

        WITH tAirRouteDtl AS (
            SELECT 
                RowID, 
                wTypeRid, 
                wLine, 
                wFlightType, 
                wClassCd, 
                wAirline, 
                wIsReturn, 
                wDepartureAirportRid, 
                wArrivalAirportRid,
                wTakeOffDt,
                wArrivalDt,
                wDepartFlightNo
            FROM CRM.dbo.eAirTicketRouteDtl WHERE wType = 'AIRTICKET' AND wStatus = 'A'
        ),
        tNotReturnAirRouteDtl AS (
            SELECT * FROM tAirRouteDtl WHERE wIsReturn = 'N'
        ),
        tFirstReturnAirRouteDtl AS (
            SELECT
                wTypeRid,
                wLine = MIN(wLine)
            FROM tAirRouteDtl WHERE wIsReturn = 'Y' AND wLine != 1 GROUP BY wTypeRid
        ),
        tReturnAirRouteDtl AS (
            SELECT ard.*
            FROM tAirRouteDtl AS ard
            INNER JOIN tFirstReturnAirRouteDtl AS frard ON frard.wTypeRid = ard.wTypeRid AND frard.wLine = ard.wLine
            WHERE ard.wIsReturn = 'Y'
        ),
        tAirPort AS (
            SELECT RowID, wCode, wName = IIF(@pLangCd = 'en-gb', wEName, wCName), wCity FROM dbo.mAirport
        ),
        tUsr AS (
            SELECT RowID, wName = IIF(@pLangCd = 'en-gb', wName, wCName) FROM RollsMary.dbo.mUsr
        ),
        tServiceCunter AS (
            SELECT RowID, wName FROM dbo.mServiceCounter
        ),
        tAgent AS (
            SELECT wAgentCodeIn, wAgentCode_Display, wName = IIF(@pLangCd = 'en-gb', wEName, wCName) FROM Rollsmary.dbo.mAgent
        ),
        tResult AS ( 
            SELECT
                bat.RowID ,
                bat.wBookingRid ,
                eb.wRefNo ,
                eb.wDebitDt ,
                wDebitServiceCounter = eb.wDebitCounterRid,
                wDebitServiceCounterName = sc.wName,
                wRequestedServiceCounter = msc.wName,
                eb.wReqDepartment ,
                wReqUserRidByCName = rqusr.wName,
                eb.wDeptFollwedCd ,
                wStaffFollwedRidByCName = sfusr.wName,
                wAgentCodeIn = eb.wDebitAgentCodeIn,
                daAgent.wAgentCode_Display ,
                wReqAgentCode_Display = rqAgent.wAgentCode_Display,
                eb.wAsstBooker ,
                bat.wPaymentMethod ,
                wTravelAgencyRidByName = ta.wName,
                wOrderNo ,
                bat.wFlightType ,
                dptAP.wClassCd ,
                dptAP.wAirline ,
                wFirstDepartureAirport = CONCAT(dptMAP.wCode, ', ', dptMAP.wName),
                wFirstDepartAirportCityCd = dptMAP.wCity ,
                wFirstTakeOffDt = dptAP.wTakeOffDt ,
                wFirstDepartFlightNo = dptAP.wDepartFlightNo ,
                wSecondArrivalAirport = CONCAT(COALESCE(rtnMAP.wCode, secMAP.wCode, dptArrMAP.wCode), ', ', COALESCE(rtnMAP.wName, secMAP.wName, dptArrMAP.wName)),
                wSecondArrivalAirportCityCd = COALESCE(rtnMAP.wCity, secMAP.wCity, dptArrMAP.wCity) ,
                wSecondTakeOffDt = ISNULL(rtnAP.wTakeOffDt, secAP.wTakeOffDt) ,
                wSecondDepartFlightNo = ISNULL(rtnAP.wDepartFlightNo, secAP.wDepartFlightNo),
                eb.wDepositAmt ,
                wTicCollPointByName = mtc.wName ,
                wClient = bm.wValue,
                bat.wTotalAmt ,
                bat.wBookingStatus ,
                bat.wExpiryDt ,
                bat.wIsRefund ,
                bat.wUpdDt ,
                bat.wCrtDt,
                wUpdByCName = usr.wName,
                wAgentCodeByName = daAgent.wName,
                wReqAgentCodeByName = rqAgent.wName,
                wEventCodeByName = IIF(@pLangCd = 'en-gb', mec.wEName, mec.wCName)
            FROM dbo.eBookingAirTicket AS bat
            INNER JOIN dbo.eBooking eb ON eb.RowID = bat.wBookingRid
            LEFT JOIN tAgent daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
            LEFT JOIN tAgent rqAgent ON rqAgent.wAgentCodeIn = eb.wReqAgentCodeIn
            LEFT JOIN tServiceCunter sc ON sc.RowID = eb.wDebitCounterRid
            LEFT JOIN tServiceCunter msc ON msc.RowID = eb.wReqCounterRid
            LEFT JOIN tNotReturnAirRouteDtl AS dptAP ON dptAP.wLine = 1 AND dptAP.wTypeRid = bat.RowID
            LEFT JOIN tNotReturnAirRouteDtl AS secAP ON secAP.wLine = 2 AND secAP.wTypeRid = bat.RowID
            LEFT JOIN tReturnAirRouteDtl rtnAP ON rtnAP.wTypeRid = bat.RowID
            LEFT JOIN tAirPort dptMAP ON dptMAP.RowID = dptAP.wDepartureAirportRid
            LEFT JOIN tAirPort secMAP ON secMAP.RowID = secAP.wDepartureAirportRid
            LEFT JOIN tAirPort rtnMAP ON rtnMAP.RowID = rtnAP.wDepartureAirportRid
            LEFT JOIN tAirPort dptArrMAP ON dptArrMAP.RowID = dptAP.wArrivalAirportRid
            LEFT JOIN tUsr usr ON usr.RowID = bat.wUpdBy
            LEFT JOIN tUsr rqusr ON rqusr.RowID = eb.wReqUserRid
            LEFT JOIN tUsr sfusr ON sfusr.RowID = eb.wStaffFollwedRid
            LEFT JOIN dbo.mTravelAgency ta ON ta.RowID = bat.wTravelAgencyRid
            LEFT JOIN dbo.mEventCode mec ON mec.RowID = eb.wEventCodeRid
            LEFT JOIN stg.eBookingMisc bm ON bm.wBookingRid = bat.wBookingRid AND bm.wLangCd = @pLangCd AND bm.wItemCd = 'CUST_NAME'
            LEFT JOIN dbo.eTicketCollection tc ON tc.wBookingRid = bat.wBookingRid
            LEFT JOIN dbo.mTicketCollectionPoint mtc ON mtc.wCode = tc.wTicCollPoint
            LEFT JOIN @sData_TicketCollectionPoint dtcp ON dtcp.wTicketCollectionPointRid = mtc.RowID
            LEFT JOIN @sData_DebitCounterRid ddc ON ddc.wCounterRid = eb.wDebitCounterRid
            LEFT JOIN @sData_BookingStatus dbs ON dbs.wBookingStatus = bat.wBookingStatus
            WHERE ( @pRefNo IS NULL OR @pRefNo = eb.wRefNo )
                AND ( @pFromDebitDt IS NULL OR @pFromDebitDt <= eb.wDebitDt)
                AND ( @pToDebitDt IS NULL OR @pToDebitDt >= eb.wDebitDt )
                AND ( @sBookingStatusCount = 0 OR dbs.wBookingStatus IS NOT NULL )
                AND ( @sDebitCounterRidCount = 0 OR ddc.wCounterRid IS NOT NULL )
                AND ( @sTicketCollectionCount = 0 OR dtcp.wTicketCollectionPointRid IS NOT NULL )
                AND ( @pReqDeptCode IS NULL OR @pReqDeptCode = eb.wReqDepartment )
                AND ( @pFollowUpDeptCode IS NULL OR @pFollowUpDeptCode = eb.wDeptFollwedCd )
                AND ( @pDebitAgentCodeIn IS NULL OR @pDebitAgentCodeIn = eb.wDebitAgentCodeIn )
                AND ( @pReqAgentCodeIn IS NULL OR @pReqAgentCodeIn = eb.wReqAgentCodeIn )
                AND ( @pTravelAgencyRid IS NULL OR @pTravelAgencyRid = bat.wTravelAgencyRid )
                AND ( @pOrderNo IS NULL OR @pOrderNo = bat.wOrderNo )
                AND ( @pFlightType IS NULL OR @pFlightType = bat.wFlightType )
                AND ( @pPaymentMethod IS NULL OR @pPaymentMethod = bat.wPaymentMethod )
                AND ( @pIsTicketCollected IS NULL OR @pIsTicketCollected = tc.wIsCollected OR ( @pIsTicketCollected = 'false' AND tc.wIsCollected IS NULL))
                AND ( @pDepartureAirportRid IS NULL OR @pDepartureAirportRid = dptAP.wDepartureAirportRid )
                AND ( dptAP.wTakeOffDt IS NULL OR @sTakeOffDt IS NULL OR @sTakeOffDt = CAST(dptAP.wTakeOffDt AS DATE))
                AND ( dptAP.wArrivalDt IS NULL OR @sArrivalDt IS NULL OR @sArrivalDt = CAST(dptAP.wArrivalDt AS DATE) )
                AND ( secAP.wArrivalDt IS NULL OR @sArrivalDt IS NULL OR @sArrivalDt = CAST(secAP.wArrivalDt AS DATE) )
                AND ( rtnAP.wArrivalDt IS NULL OR @sArrivalDt IS NULL OR @sArrivalDt = CAST(rtnAP.wArrivalDt AS DATE))
                AND ( @pArrivalAirportRid IS NULL OR dptAP.wArrivalAirportRid IS NULL OR @pArrivalAirportRid = dptAP.wArrivalAirportRid )
                AND ( @pArrivalAirportRid IS NULL OR secAP.wArrivalAirportRid IS NULL OR @pArrivalAirportRid = secAP.wArrivalAirportRid )
                AND ( @pArrivalAirportRid IS NULL OR rtnAP.wArrivalAirportRid IS NULL OR @pArrivalAirportRid = rtnAP.wArrivalAirportRid)
        ),
         tCount AS (
            SELECT wRecordCount = COUNT(1) FROM tResult
        )

        --UAT： wRecordCount = 8479，pPageSize = 100, pPageNum = 80, Dutation ≈ 3.1103
        --UAT： wRecordCount = 8479，pPageSize = 100, pPageNum = 1, Dutation ≈ 1.0945
        --SELECT
        --    tResult.* ,
        --    wRecordCount
        --FROM tResult, tCount
        --ORDER BY wCrtDt DESC
        --OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        --FETCH NEXT @pPageSize ROWS ONLY
        --OPTION(RECOMPILE);

        --UAT： wRecordCount = 8479，pPageSize = 100, pPageNum = 80, Dutation ≈ 1.5925
        --UAT： wRecordCount = 8479，pPageSize = 100, pPageNum = 1, Dutation ≈ 1.5419
        SELECT
            tResult.*,
            wRecordCount
        FROM tResult, tCount
        WHERE RowID IN (
            SELECT TOP (@pPageSize) RowID FROM
            (
                SELECT TOP (@pPageSize * @pPageNum) wSortRid = ROW_NUMBER() OVER(ORDER BY wCrtDt DESC), RowID FROM tResult
            ) AS tmp WHERE wSortRid > @pPageSize * (@pPageNum - 1)
        )
        ORDER BY wCrtDt DESC
        OPTION(RECOMPILE);
    END;