
CREATE PROCEDURE [spq].[GetBookingPrivatePlaneLst]
(
    @pRefNo VARCHAR(30) ,
    @pFromDebitDt DATETIME2 ,
    @pToDebitDt DATETIME2 ,
    @pDebitCounterRidXML XML ,
    @pReqDeptCode VARCHAR(30) ,
    @pFollowUpDeptCode VARCHAR(30) ,
    @pDebitAgentCodeIn VARCHAR(14) ,
    @pReqAgentCodeIn VARCHAR(14) ,
    @pSupplier BIGINT ,
    @pDepartureAirportRid BIGINT ,
    @pTakeOffDt DATETIME2 ,
    @pArrivalAirportRid BIGINT ,
    @pArrivalDt DATETIME2 ,
    @pPaymentMethod VARCHAR(30) ,
    @pOrderNo VARCHAR(20) ,
    @pBookingStatusXML XML ,
    @pSort VARCHAR(200) ,
    @pLangCd VARCHAR(10) ,
    @pPageSize INT ,
    @pPageNum INT ,
    @pTravelPackageRid BIGINT
)
AS
    BEGIN
        SET NOCOUNT ON;
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        DECLARE @sTakeOffDt AS DATE,
                @sArrivalDt AS DATE ,
                @sDebitCounterCount AS INT ,
                @sBookingStatusCount AS INT;
                
        DECLARE @sData_DebitCounter AS TABLE ( wServiceCounterRid BIGINT );
        DECLARE @sData_BookingStatus AS TABLE ( wBookingStatus VARCHAR(5) );
        
        IF CAST(@pDebitCounterRidXML AS NVARCHAR(MAX)) != N'<DataSet/>'
        BEGIN
            INSERT INTO @sData_DebitCounter ( wServiceCounterRid )
            SELECT wServiceCounterRid = tmp.value('@SelectionItem', 'BIGINT')
            FROM @pDebitCounterRidXML.nodes('/DataSet/Record') AS T ( tmp );
        END;
        
        IF CAST(@pBookingStatusXML AS NVARCHAR(MAX)) != N'<DataSet/>'
        BEGIN
            INSERT INTO @sData_BookingStatus ( wBookingStatus )
            SELECT wBookingStatus = tmp.value('@SelectionItem', 'VARCHAR(5)')
            FROM @pBookingStatusXML.nodes('/DataSet/Record') AS T ( tmp );
        END;

        SET @sDebitCounterCount = ( SELECT COUNT(1) FROM @sData_DebitCounter );
        SET @sBookingStatusCount = ( SELECT COUNT(1) FROM @sData_BookingStatus );
        SET @pRefNo = NULLIF(@pRefNo, '');
        SET @pFromDebitDt = NULLIF(@pFromDebitDt, '');
        SET @pToDebitDt = NULLIF(@pToDebitDt, '');  
        SET @pReqDeptCode = NULLIF(@pReqDeptCode, '');
        SET @pFollowUpDeptCode = NULLIF(@pFollowUpDeptCode, '');
        SET @pDebitAgentCodeIn = NULLIF(@pDebitAgentCodeIn, '');
        SET @pReqAgentCodeIn = NULLIF(@pReqAgentCodeIn, '');
        SET @pSupplier = ISNULL(@pSupplier, 0);
        SET @pDepartureAirportRid = ISNULL(@pDepartureAirportRid, 0);
        SET @sTakeOffDt = CAST(@pTakeOffDt AS DATE);
        SET @pArrivalAirportRid = ISNULL(@pArrivalAirportRid, 0);
        SET @sArrivalDt = CAST(@pArrivalDt AS DATE);
        SET @pPaymentMethod = NULLIF(@pPaymentMethod, '');
        SET @pOrderNo = NULLIF(@pOrderNo, '');
        SET @pSort = ISNULL(NULLIF(@pSort, ''), '||');
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));
        SET @pPageSize = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 100);
        SET @pPageNum = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);	
        SET @pTravelPackageRid = ISNULL(@pTravelPackageRid, 0);

        WITH tUsr AS (
            SELECT RowID, wName = IIF(@pLangCd = 'en-gb', wName, wCName) FROM RollsMary.dbo.mUsr
        ),
        tAirPort AS (
            SELECT RowID, wCode, wName = IIF(@pLangCd = 'en-gb', wEName, wCName), wCity FROM dbo.mAirport
        ),
        tAgent AS (
            SELECT wAgentCodeIn, wAgentCode_Display, wName = IIF(@pLangCd = 'en-gb', wEName, wCName) FROM Rollsmary.dbo.mAgent
        ),
        tPPRoute AS (
            SELECT 
                wBookingPrivatePlaneRid, 
                wLine, 
                wCityCd, 
                wIsReturn, 
                wDepartureAirportRid, 
                wArrivalAirportRid, 
                wTakeOffDt, 
                wArrivalDt  
            FROM dbo.ePrivatePlaneRouteDtl WHERE wStatus = 'A'
        ),
        tDepartureRoute AS (
            SELECT 
                r.*,
                a.wCode,
                a.wName,
                a.wCity
            FROM tPPRoute AS r
            LEFT JOIN tAirport AS a ON a.RowID = r.wDepartureAirportRid
            WHERE r.wLine = 1
        ),
        tDestRoute AS (
            SELECT
                dest.*,
                a.wCode,
                a.wName,
                a.wCity
            FROM (SELECT wBookingPrivatePlaneRid , MAX(wLine) AS wLine FROM tPPRoute WHERE wIsReturn != 'Y' GROUP BY wBookingPrivatePlaneRid) AS gdest
            INNER JOIN tPPRoute AS dest ON dest.wBookingPrivatePlaneRid = gdest.wBookingPrivatePlaneRid AND dest.wLine = gdest.wLine
            LEFT JOIN tAirport AS a ON a.RowID = dest.wArrivalAirportRid
        ),
        tFistReturnRoute AS (
            SELECT
                r.wBookingPrivatePlaneRid,
                r.wTakeOffDt
            FROM (SELECT wBookingPrivatePlaneRid , MIN(wLine) AS wLine FROM tPPRoute WHERE wIsReturn = 'Y' GROUP BY wBookingPrivatePlaneRid) AS gr
            INNER JOIN tPPRoute AS r ON r.wBookingPrivatePlaneRid = gr.wBookingPrivatePlaneRid AND r.wLine = gr.wLine
        ),
        tResult AS (
            SELECT
                pp.RowID ,
                eb.wRefNo ,
                pp.wBookingNo ,
                pp.wBookingRid ,
                pp.wOrderNo ,
                eb.wDebitDt ,
                pp.wPaymentMethod ,
                pp.wReceiptNo ,
                wAgentCodeIn = eb.wDebitAgentCodeIn ,
                daAgent.wAgentCode_Display ,
                wDebitClient = eb.wDebitCustomerRid ,
                wDebitClientName = '' ,
                eb.wDebitCounterRid ,
                wDebitServiceCounterName = sc.wName ,
                wDepartCityCd = dpt.wCityCd ,
                wDepartureAirport = CONCAT(dpt.wCode, ', ', dpt.wName),
                wDepartAirportCityCd = dpt.wCity ,
                wArrivalAirport = CONCAT(dest.wCode, ', ', dest.wName),
                wArrivalAirportCityCd = dest.wCity ,
                dpt.wTakeOffDt ,
                dest.wArrivalDt ,
                wReturnDepartureAirport = '' ,
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
                wUpdByCName = usr.wName ,
                wCreatedByCName = crusr.wName,
                wRequestedServiceCounter = msc.wName ,
                eb.wReqDepartment ,
                wReqUserRidByCName = rqusr.wName,
                eb.wDeptFollwedCd ,
                wStaffFollwedRidByCName = sfusr.wName,
                wReqAgentCode_Display = rqAgent.wAgentCode_Display ,
                eb.wAsstBooker ,
                wSupplierByName = ( CASE pp.wSupplier WHEN 'HO' THEN ho.wName
                                                      WHEN 'TA' THEN ta.wName
                                                      ELSE NULL END ),
                eb.wDepositAmt ,
                wClient = bm.wValue,
                wAgentCodeByName = daAgent.wName,
                wReqAgentCodeByName = rqAgent.wName,
                wEventCodeByName = IIF( @pLangCd = 'en-gb', mec.wEName, mec.wCName)
            FROM dbo.eBookingPrivatePlane AS pp
            INNER JOIN dbo.eBooking AS eb ON eb.RowID = pp.wBookingRid
            LEFT JOIN dbo.mServiceCounter AS sc ON sc.RowID = eb.wDebitCounterRid
            LEFT JOIN dbo.mServiceCounter AS msc ON msc.RowID = eb.wReqCounterRid
            LEFT JOIN tAgent AS daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
            LEFT JOIN tAgent AS rqAgent ON rqAgent.wAgentCodeIn = eb.wReqAgentCodeIn
            LEFT JOIN tDepartureRoute AS dpt ON dpt.wBookingPrivatePlaneRid = pp.RowID
            LEFT JOIN tDestRoute AS dest ON dest.wBookingPrivatePlaneRid = pp.RowID
	        LEFT JOIN tFistReturnRoute RRTD ON RRTD.wBookingPrivatePlaneRid = pp.RowID
            LEFT JOIN tUsr usr ON usr.RowID = pp.wUpdBy
            LEFT JOIN tUsr crusr ON crusr.RowID = pp.wCrtBy
            LEFT JOIN tUsr rqusr ON rqusr.RowID = eb.wReqUserRid
            LEFT JOIN tUsr sfusr ON sfusr.RowID = eb.wStaffFollwedRid
            LEFT JOIN dbo.mTravelAgency ta ON ta.RowID = pp.wTravelAgencyRid
            LEFT JOIN dbo.mHotel ho ON ho.RowID = pp.wHotelRid
            LEFT JOIN dbo.mEventCode mec ON mec.RowID = eb.wEventCodeRid
            LEFT JOIN stg.eBookingMisc bm ON bm.wBookingRid = pp.wBookingRid AND bm.wLangCd = @pLangCd AND bm.wItemCd = 'CUST_NAME'
            LEFT JOIN @sData_DebitCounter v ON v.wServiceCounterRid = eb.wDebitCounterRid
            LEFT JOIN @sData_BookingStatus vs ON vs.wBookingStatus = pp.wBookingStatus
            WHERE ( @pRefNo IS NULL OR @pRefNo = eb.wRefNo )
                AND ( @pFromDebitDt IS NULL OR @pFromDebitDt <= eb.wDebitDt)
                AND ( @pToDebitDt IS NULL OR @pToDebitDt >= eb.wDebitDt )
                AND ( @sDebitCounterCount = 0 OR v.wServiceCounterRid IS NOT NULL )
                AND ( @pReqDeptCode IS NULL OR @pReqDeptCode = eb.wReqDepartment )
                AND ( @pFollowUpDeptCode IS NULL OR @pFollowUpDeptCode = eb.wDeptFollwedCd )
                AND ( @pDebitAgentCodeIn IS NULL OR @pDebitAgentCodeIn = eb.wDebitAgentCodeIn )
                AND ( @pReqAgentCodeIn IS NULL OR @pReqAgentCodeIn = eb.wReqAgentCodeIn )
                AND ( @pSupplier = 0 OR @pSupplier = pp.wHotelRid OR @pSupplier = pp.wTravelAgencyRid )
                AND ( @pDepartureAirportRid = 0 OR @pDepartureAirportRid = dpt.wDepartureAirportRid )
                AND ( @sTakeOffDt IS NULL OR @sTakeOffDt =  CAST(dpt.wTakeOffDt AS DATE) )
                AND ( @pArrivalAirportRid = 0 OR @pArrivalAirportRid = dest.wArrivalAirportRid )
                AND ( @sArrivalDt IS NULL OR @sArrivalDt = CAST(dest.wArrivalDt AS DATE) )
                AND ( @pPaymentMethod IS NULL OR @pPaymentMethod = pp.wPaymentMethod )
                AND ( @pOrderNo IS NULL OR @pOrderNo = pp.wOrderNo )
                AND ( @pTravelPackageRid = 0 OR @pTravelPackageRid = eb.wTravePkgRid )
                AND ( @sBookingStatusCount = 0 OR vs.wBookingStatus IS NOT NULL )
            ),
            tCount AS (
                SELECT wRecordCount = COUNT(1) FROM tResult
            ),
            tPageResult AS (
                SELECT
                    tResult.* ,
                    wRecordCount
                FROM tResult , tCount
                ORDER BY CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wDebitDt END DESC ,
                CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wRefNo END DESC
                OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
                FETCH NEXT @pPageSize ROWS ONLY
            ) 

            SELECT
                t.*
            FROM tPageResult AS t
            OPTION(RECOMPILE);
    END;