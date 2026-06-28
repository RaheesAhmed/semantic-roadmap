CREATE PROCEDURE [spq].[GetAirTicketPassengerLst]
(
    @pFromDebitDt DATETIME2 ,
    @pToDebitDt DATETIME2 ,
    @pDebitDt DATETIME2 ,
    @pDebitAgentCodeIn VARCHAR(14) ,
    @pReqAgentCodeIn VARCHAR(14) ,
    @pRefNo VARCHAR(30) ,
    @pSeqNo INT ,
    @pFlightType VARCHAR(30) ,
    @pCName NVARCHAR(50) ,
    @pEName VARCHAR(500) ,
    @pEnglishPinyin NVARCHAR(100) ,
    @pIDType VARCHAR(30) ,
    @pIDNo VARCHAR(30) ,
    @pDepartureAirportRid BIGINT ,
    @pTakeOffDt DATETIME2 ,
    @pArrivalnDepartAirportRid BIGINT ,
    @pArrivalnTakeOffDt DATETIME2 ,
    @pArrivalAirportRid BIGINT ,
    @pArrivalDt DATETIME2 ,
    @pDepartFlightNo VARCHAR(20) ,
    @pClassCd NVARCHAR(50) ,
    @pIsCompAcc CHAR(1) ,
    @pBookingStatusXML XML ,
    @pSort VARCHAR(200) ,
    @pPageSize INT ,
    @pPageNum INT ,
    @pLangCd VARCHAR(10)
)
AS
    BEGIN 

        -- SET NOCOUNT ON added to prevent extra result sets from 
        SET NOCOUNT ON;

        DECLARE @vFromTakeOffDt AS DATETIME2 = '0001-01-01' ,
                @vToTakeOffDt AS DATETIME2 = '9999-12-31' ,
                @vFromArrivalnTakeOffDt AS DATETIME2 = '0001-01-01' ,
                @vToArrivalnTakeOffDt AS DATETIME2 = '9999-12-31' ,
                @vFromArrivalDt AS DATETIME2 = '0001-01-01' ,
                @vToArrivalDt AS DATETIME2 = '9999-12-31' ,
                @vBookingStatusCount INT;

        DECLARE @vData_BookingStatus AS TABLE
        (
            wBookingStatus VARCHAR(5)
        );

        IF CAST(@pBookingStatusXML AS NVARCHAR(MAX)) != N'<DataSet/>'
        BEGIN
            INSERT INTO @vData_BookingStatus ( wBookingStatus )
            SELECT wBookingStatus = tmp.value('@SelectionItem', 'VARCHAR(5)')
            FROM @pBookingStatusXML.nodes('/DataSet/Record') AS T ( tmp );
        END;

        SET @vBookingStatusCount = ( SELECT COUNT(1) FROM @vData_BookingStatus );
        SET @pFromDebitDt = ISNULL(@pFromDebitDt, '0001-01-01');
        SET @pToDebitDt = ISNULL(@pToDebitDt, '9999-12-31');  
        IF @pDebitDt IS NOT NULL
        BEGIN
            SET @pFromDebitDt = @pDebitDt;
            SET @pToDebitDt = DATEADD(dd, 1, @pDebitDt);
        END;
        SET @pDebitAgentCodeIn = NULLIF(@pDebitAgentCodeIn, '');
        SET @pReqAgentCodeIn = NULLIF(@pReqAgentCodeIn, '');		
        SET @pRefNo = NULLIF(@pRefNo, '');
        SET @pSeqNo = ISNULL(@pSeqNo, 0);
        SET @pFlightType = NULLIF(@pFlightType, '');
        SET @pEName = NULLIF(@pEName, '');
        SET @pCName = NULLIF(@pCName, '');
        SET @pEnglishPinyin = NULLIF(@pEnglishPinyin, '');
        SET @pIDType = NULLIF(@pIDType, '');
        SET @pIDNo = NULLIF(@pIDNo, '');
        SET @pDepartureAirportRid = ISNULL(@pDepartureAirportRid, 0);
        IF @pTakeOffDt IS NOT NULL
        BEGIN
            SET @vFromTakeOffDt = @pTakeOffDt;
            SET @vToTakeOffDt = DATEADD(ss,-1,DATEADD(dd, 1, @pTakeOffDt));
        END;
        SET @pArrivalnDepartAirportRid = ISNULL(@pArrivalnDepartAirportRid, 0);
        IF @pArrivalnTakeOffDt IS NOT NULL
        BEGIN
            SET @vFromArrivalnTakeOffDt = @pArrivalnTakeOffDt;
            SET @vToArrivalnTakeOffDt = DATEADD(ss,-1,DATEADD(dd, 1, @pArrivalnTakeOffDt));
        END;
        SET @pArrivalAirportRid = ISNULL(@pArrivalAirportRid, 0);
        IF @pArrivalDt IS NOT NULL
        BEGIN
            SET @vFromArrivalDt = @pArrivalDt;
            SET @vToArrivalDt = DATEADD(ss,-1,DATEADD(dd, 1, @pArrivalDt));
        END;
        SET @pDepartFlightNo = NULLIF(@pDepartFlightNo, '');
        SET @pClassCd = NULLIF(@pClassCd, '');
        SET @pIsCompAcc = NULLIF(@pIsCompAcc, '');
        SET @pSort = CASE WHEN NULLIF(@pSort, '') IS NULL THEN '||' ELSE @pSort END;
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);
        
        --IF @@trancount = 0
        --    SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 

        WITH cteDocDetails AS (
            SELECT
                ptdd.wPassengerDetailsRid ,
                ptd.wIDNo ,
                ptd.wIDType ,
                ptd.wEnglishPinyin
            FROM dbo.ePassengerTravelDocDetail AS ptdd
            LEFT JOIN dbo.mPersonTravelDoc AS ptd ON ptd.RowID = ptdd.wPersonTravelDocRid
        ),
        ctePassengerDoc AS (
            SELECT
                rdd.wPassengerDetailsRid,
                wIDNo = STUFF(( SELECT ',' + sdd.wIDNo FROM cteDocDetails AS sdd WHERE sdd.wPassengerDetailsRid = rdd.wPassengerDetailsRid  FOR XML PATH('')), 1, 1, N''),
                wIDType = STUFF(( SELECT ',' + sdd.wIDType FROM cteDocDetails AS sdd WHERE sdd.wPassengerDetailsRid = rdd.wPassengerDetailsRid  FOR XML PATH('')), 1, 1, N''),
                wEnglishPinyin = STUFF(( SELECT ',' + sdd.wEnglishPinyin FROM cteDocDetails AS sdd WHERE sdd.wPassengerDetailsRid = rdd.wPassengerDetailsRid  FOR XML PATH('')), 1, 1, N'')
            FROM cteDocDetails AS rdd
            GROUP BY rdd.wPassengerDetailsRid
        ),
        cteFirstRouteDtl AS (
            SELECT 
                fard.wArrivalAirportRid ,
                fard.wTypeRid,
                fard.wType ,
                fard.wClassCd ,
                fard.wAirline ,
                fard.wDepartureAirportRid ,
                fard.wTakeOffDt ,
                fard.wArrivalDt ,
                fard.wDepartFlightNo,
                wDepartAirport = CONCAT(fdptma.wCode, ', ', IIF(@pLangCd = 'en-gb', fdptma.wEName, fdptma.wCName), ', '),
                wDepartAirportCity = fdptma.wCity ,
                wArrivalAirport = CONCAT(farvma.wCode, ', ', IIF(@pLangCd = 'en-gb', farvma.wEName, farvma.wCName), ', '),
                wArrivalAirportCity = farvma.wCity 
            FROM dbo.eAirTicketRouteDtl AS fard
            LEFT JOIN dbo.mAirport fdptma ON fdptma.RowID = fard.wDepartureAirportRid
            LEFT JOIN dbo.mAirport farvma ON farvma.RowID = fard.wArrivalAirportRid
            WHERE fard.wLine = 1 AND fard.wStatus = 'A' AND fard.wType = 'PASSENGER'
        ),
        cteLastRouteDtl AS (
            SELECT
                lard.wArrivalAirportRid ,
                lard.wTypeRid,
                lard.wType ,
                lard.wDepartureAirportRid ,
                lard.wTakeOffDt ,
                lard.wArrivalDt ,
                lard.wDepartFlightNo ,
                wAirport = CONCAT(larvma.wCode, ', ', IIF(@pLangCd = 'en-gb', larvma.wEName, larvma.wCName), ', '),
                wCity = larvma.wCity
                FROM dbo.eAirTicketRouteDtl lard
                INNER JOIN (
                    SELECT
                        wTypeRid ,
                        wLine = MAX(wLine)
                    FROM dbo.eAirTicketRouteDtl
                    WHERE wStatus = 'A' AND wIsReturn != 'Y' AND wType = 'PASSENGER'
                    GROUP BY wTypeRid
                ) larl ON larl.wTypeRid = lard.wTypeRid AND larl.wLine = lard.wLine AND lard.wStatus = 'A' AND lard.wType = 'PASSENGER'
                LEFT JOIN dbo.mAirport larvma ON larvma.RowID = lard.wArrivalAirportRid
        ),
        cteReturnRouteDtl AS (
            SELECT 
                lard.wArrivalAirportRid ,
                lard.wTypeRid,
                lard.wType ,
                lard.wDepartureAirportRid ,
                lard.wTakeOffDt ,
                lard.wArrivalDt ,
                lard.wDepartFlightNo ,
                wAirport = CONCAT(ldptma.wCode, ', ', IIF(@pLangCd = 'en-gb', ldptma.wEName, ldptma.wCName), ', ' ),
                ldptma.wCity AS wCity
            FROM dbo.eAirTicketRouteDtl lard
            INNER JOIN (
                SELECT
                    wTypeRid ,
                    wLine = MIN(wLine)
                FROM dbo.eAirTicketRouteDtl
                WHERE wStatus = 'A' AND wIsReturn = 'Y' AND wLine != 1 AND wType = 'PASSENGER'
                GROUP BY wTypeRid
            ) larl ON larl.wTypeRid = lard.wTypeRid AND larl.wLine = lard.wLine AND lard.wStatus = 'A' AND lard.wType = 'PASSENGER'
            LEFT JOIN dbo.mAirport ldptma ON ldptma.RowID = lard.wDepartureAirportRid
        ),
        cteArrivalnDepartAirport AS (
            SELECT 
                wTypeRid
            FROM dbo.eAirTicketRouteDtl
            WHERE wType = 'PASSENGER' AND wStatus = 'A'
                AND (@pArrivalnDepartAirportRid = 0
                  OR @pArrivalnDepartAirportRid = wDepartureAirportRid
                  OR @pArrivalnDepartAirportRid = wArrivalAirportRid
                )
            GROUP BY wTypeRid
        ),
        tResult AS (
            SELECT
                psd.RowID,
                psd.wBookingRid ,
                eb.wRefNo ,
                eb.wDebitDt,
                daAgent.wAgentCode_Display ,
                eb.wReqAgentCodeIn ,
                wReqAgentCode_Display = rqAgent.wAgentCode_Display,
                ps.wCName,
                wEName = ISNULL(ps.wEName, ''),
                wIDNo = dd.wIDNo,
                wIDType = dd.wIDType,
                wEnglishPinyin = dd.wEnglishPinyin,
                ps.wGender ,
                psd.wClientTicketNo ,
                ebat.wFlightType,
                COALESCE(pfrd.wClassCd, '') AS wClassCd ,
                COALESCE(pfrd.wAirline, '') AS wAirline ,
                COALESCE(pfrd.wDepartFlightNo, '') AS wDepartFlightNo ,
                COALESCE(pfrd.wDepartAirport, '') AS wDepartureAirport ,
                COALESCE(pfrd.wDepartAirportCity, '') AS wDepartAirportCityCd ,
                COALESCE(pfrd.wArrivalAirport, '') AS wArrivalAirport ,
                COALESCE(pfrd.wArrivalAirportCity, '') AS wArrivalAirportCityCd ,
                COALESCE(pfrd.wTakeOffDt, '') AS wTakeOffDt ,
                COALESCE(pfrd.wArrivalDt, '') AS wArrivalDt ,
                COALESCE(pfrd.wDepartAirport, '') AS wFirstDepartureAirport ,
                COALESCE(pfrd.wDepartAirportCity, '') AS wFirstDepartAirportCityCd ,
                COALESCE(pfrd.wTakeOffDt, '') AS wFirstTakeOffDt ,
                COALESCE(pfrd.wDepartFlightNo, '') AS wFirstDepartFlightNo ,
                COALESCE(prrd.wAirport, plrd.wAirport, '') AS wLastAirport ,
                COALESCE(prrd.wCity, plrd.wCity, '') AS wLastCityCd ,
                COALESCE(prrd.wTakeOffDt, plrd.wTakeOffDt, '') AS wLastDt ,
                COALESCE(prrd.wDepartFlightNo, plrd.wDepartFlightNo, '') AS wLastFlightNo,
                psd.wChangeOrderCount ,
                psd.wIsWaiting ,
                psd.wAmount ,
                psd.wCost ,
                psd.wPassengerBookingStatus ,
                psd.wCrtDt , 
                wUpdByName = IIF(@pLangCd = 'en-gb', usr.wName, usr.wCName),
                psd.wSeqNo ,
                ebat.wBookingStatus ,
                ebat.wCurrCode ,
                ps.wAgentCodeIn ,
                psd.wType ,
                psd.wDestination ,
                psd.wOtherReason ,
                psd.wCancelReasonCd ,
                psd.wCancelDebitDt ,
                psd.wCancelDt ,
                psd.wStatus ,
                psd.wPersonRid ,
                psd.wUpdDt ,
                psd.wCrtBy ,
                psd.wRemark ,
                psd.wRequesterAcc ,
                wTakeOffDtInDetail = psd.wTakeOffDt,
                eb.wExpDt,
                wIsCompAcc = IIF(ai.wAgentCodeIn IS NOT NULL, 'Y', 'N'),
                wAgentCodeByName = IIF(@pLangCd = 'en-gb', daAgent.wEName, daAgent.wCName),
                wReqAgentCodeByName = IIF(@pLangCd = 'en-gb', rqAgent.wEName, rqAgent.wCName)
            FROM dbo.ePassengerDetails AS psd
            INNER JOIN dbo.eBooking AS eb ON eb.RowID = psd.wBookingRid
            INNER JOIN dbo.eBookingAirTicket AS ebat ON ebat.wBookingRid = eb.RowID
            INNER JOIN RollsMary.dbo.mAgent AS daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
            INNER JOIN RollsMary.dbo.mAgent AS rqAgent ON rqAgent.wAgentCodeIn = eb.wReqAgentCodeIn
            LEFT JOIN dbo.mPerson ps ON ps.RowID = psd.wPersonRid
            LEFT JOIN ctePassengerDoc dd ON dd.wPassengerDetailsRid = psd.RowID
            LEFT JOIN cteFirstRouteDtl pfrd ON pfrd.wTypeRid = psd.RowID
            LEFT JOIN cteLastRouteDtl plrd ON plrd.wTypeRid = psd.RowID
            LEFT JOIN cteReturnRouteDtl prrd ON prrd.wTypeRid = psd.RowID
            LEFT JOIN cteArrivalnDepartAirport prdf ON prdf.wTypeRid = psd.RowID
            LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = psd.wUpdBy
            LEFT JOIN @vData_BookingStatus vs ON vs.wBookingStatus = ebat.wBookingStatus
            LEFT JOIN RollsMary.dbo.mAgentIdentity ai ON ai.wType = 'COMPANY_ACCT' AND ai.wValue = 'Y' AND ai.wAgentCodeIn = eb.wReqAgentCodeIn
            WHERE ( eb.wDebitDt >= @pFromDebitDt AND eb.wDebitDt <= @pToDebitDt  )
                AND ( @pDebitAgentCodeIn IS NULL OR @pDebitAgentCodeIn = eb.wDebitAgentCodeIn )
                AND ( @pReqAgentCodeIn IS NULL OR @pReqAgentCodeIn = eb.wReqAgentCodeIn )
                AND ( @pSeqNo = 0 OR ( eb.wRefNo = @pRefNo AND psd.wSeqNo = @pSeqNo ))
                AND ( @pCName IS NULL OR @pCName = ps.wCName )
                AND ( @pFlightType IS NULL OR @pFlightType = ebat.wFlightType )
                AND ( @pEName IS NULL OR @pEName = ps.wEName )
                AND ( @pEnglishPinyin IS NULL OR @pEnglishPinyin = dd.wEnglishPinyin )
                AND ( @pIDType IS NULL OR @pIDType = dd.wIDType )
                AND ( @pIDNo IS NULL OR @pIDNo = dd.wIDNo )
                AND ( @pDepartureAirportRid = 0 OR @pDepartureAirportRid = pfrd.wDepartureAirportRid)
                AND ( @vFromTakeOffDt <= COALESCE(pfrd.wTakeOffDt, '') AND @vToTakeOffDt >= COALESCE(pfrd.wTakeOffDt, ''))
                AND ( @pArrivalAirportRid = 0 OR @pArrivalAirportRid = pfrd.wArrivalAirportRid)
                AND ( @vFromArrivalDt <= COALESCE(pfrd.wArrivalDt, '') AND @vToArrivalDt >=  COALESCE(pfrd.wArrivalDt, ''))
                AND ( @pDepartFlightNo IS NULL OR @pDepartFlightNo = pfrd.wDepartFlightNo)
                AND ( @pClassCd IS NULL OR @pClassCd = pfrd.wClassCd)
                AND ( @pArrivalnDepartAirportRid = 0 OR prdf.wTypeRid IS NOT NULL)
                AND ( @vFromArrivalnTakeOffDt <= COALESCE(prrd.wTakeOffDt, plrd.wTakeOffDt, '')
                  AND @vToArrivalnTakeOffDt >= COALESCE(prrd.wTakeOffDt, plrd.wTakeOffDt, '')
                )
                AND ( @pIsCompAcc IS NULL
                    OR ( @pIsCompAcc = 'Y' AND ai.wAgentCodeIn IS NOT NULL )
                    OR ( @pIsCompAcc = 'N' AND ai.wAgentCodeIn IS NULL )
                )
                AND ( @vBookingStatusCount <= 0 OR vs.wBookingStatus IS NOT NULL )
        ),
        tCount AS (
            SELECT wRecordCount = COUNT(1)
            FROM tResult
        )
            
        SELECT
            tResult.* , 
            wRecordCount
        FROM tResult , tCount
        ORDER BY CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wDebitDt END DESC ,
                 CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wRefNo END DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS  
        FETCH NEXT @pPageSize ROWS ONLY
	    OPTION(RECOMPILE);  
    END;