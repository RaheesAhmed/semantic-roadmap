CREATE PROCEDURE [spq].[GetBookingFerryByTravelPkgRid]
(
    @pTravelPkgRid BIGINT ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1 ,
    @pLangCd VARCHAR(10) = 'en-GB'
)
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pTravelPkgRid = ISNULL(IIF(@pTravelPkgRid <= 0, NULL, @pTravelPkgRid), 0);
        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'en-GB');
        SET @pPageSize = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 999);
        SET @pPageNum = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);

        WITH tResult AS (
            SELECT
                bf.RowID ,
                bf.wBookingRid ,
                bf.wClassCd ,
                bf.wTicketType ,
                bf.wPaymentMethod ,
                bf.wRouteRid ,
                wRoute = IIF(r.RowID IS NULL, N'', CONCAT(r.wRouteFrom, IIF(r.wIsTwoWay = 'Y', '<->', '->'), r.wRouteTo)),
                bf.wDepartDt ,
                bf.wCurrCode ,
                bf.wExpAmt ,
                bf.wQuantity ,
                bf.wTotalAmt ,
                bf.wCost ,
                bf.wRemark ,
                bf.wCrtDt ,
                bf.wCrtBy ,
                bf.wUpdDt ,
                bf.wUpdBy ,
                bf.wOrderNo ,
                bf.wReceiptNo ,
                bf.wUnitAmt ,
                bf.wSeqNo ,
                bf.wUseBlackCard ,
                TicketId = 'F' + CAST(bf.wTicketId AS VARCHAR(20)) ,
                bf.wTicketId ,
                bf.wBookingStatus ,
                eb.wDebitDt ,
                eb.wRefNo ,
                wDebitServiceCounter = eb.wDebitCounterRid,
                wDebitServiceCounterName = sc.wName ,
                wDebitAccount = eb.wDebitAgentCodeIn ,
                wDebitAccountName = CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName ELSE daAgent.wCName END ,
                wDebitClient = eb.wDebitCustomerRid,
                wDebitClientName = '' ,
                eb.wTravePkgRid ,
                wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END ,
                wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END,
                bf.wURLType  ,
                bf.wURLAddress  
            FROM dbo.eBookingFerry AS bf
            INNER JOIN dbo.eBooking AS eb ON eb.RowID = bf.wBookingRid
            INNER JOIN dbo.mServiceCounter AS sc ON sc.RowID = eb.wDebitCounterRid
            LEFT JOIN dbo.mRoute AS r ON r.RowID = bf.wRouteRid
            LEFT JOIN RollsMary.dbo.mAgent AS daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn                                
            LEFT JOIN RollsMary.dbo.mUsr AS usr ON usr.RowID = bf.wUpdBy
            LEFT JOIN RollsMary.dbo.mUsr AS crusr ON crusr.RowID = bf.wCrtBy
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