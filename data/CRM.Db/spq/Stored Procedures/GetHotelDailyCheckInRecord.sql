CREATE PROCEDURE [spq].[GetHotelDailyCheckInRecord]
(
    @pHotelRid BIGINT ,
    @pRoomRid BIGINT ,
    @pAllotmentGroupRid BIGINT ,
    @pRoomStartDate DATETIME2 ,
    @pRoomEndDate DATETIME2 ,
    @pDebitCounterRegionXML XML ,
    @pDebitCounterRidXML XML ,
    @pHotelRegion VARCHAR(20) ,
    @pAgencyRoom CHAR(1) ,
    @pStatus CHAR(1) ,
    @pSort VARCHAR(200) ,
    @pLangCd VARCHAR(10) ,
    @pPageSize INT ,
    @pPageNum INT
)
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        DECLARE @vDebitCounterRegionCount INT ,
                @vDebitCounterRidCount INT;

        DECLARE @vData_DebitCounterRegion AS TABLE ( SelectionItem VARCHAR(20) );
        DECLARE @vData_DebitCounterRid AS TABLE ( SelectionItem BIGINT );

        IF CAST(@pDebitCounterRegionXML AS NVARCHAR(MAX)) != N'<DataSet/>'
        BEGIN
            INSERT INTO @vData_DebitCounterRegion ( SelectionItem )
            SELECT tmp.value('@SelectionItem', 'VARCHAR(20)') AS SelectionItem
            FROM @pDebitCounterRegionXML.nodes('/DataSet/Record') AS T ( tmp );
        END;

        IF CAST(@pDebitCounterRidXML AS NVARCHAR(MAX)) != N'<DataSet/>'
        BEGIN
            INSERT INTO @vData_DebitCounterRid ( SelectionItem )
            SELECT tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
            FROM @pDebitCounterRidXML.nodes('/DataSet/Record') AS T ( tmp );
        END;

        SET @vDebitCounterRegionCount = ( SELECT COUNT(1) FROM @vData_DebitCounterRegion );
        SET @vDebitCounterRidCount = ( SELECT COUNT(1) FROM @vData_DebitCounterRid );
        SET @pHotelRid = ISNULL(@pHotelRid, 0);
        SET @pRoomRid = ISNULL(@pRoomRid, 0);
        SET @pAllotmentGroupRid = ISNULL(@pAllotmentGroupRid, 0);
        SET @pRoomStartDate = CAST(@pRoomStartDate AS DATE);
        SET @pRoomEndDate  = CAST(@pRoomEndDate AS DATE);
        SET @pHotelRegion = ISNULL(@pHotelRegion, '');
        SET @pAgencyRoom = ISNULL(@pAgencyRoom, ' ');
        SET @pStatus = ISNULL(@pStatus, ' ');
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||' ELSE @pSort END;
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-GB'));
        SET @pPageSize = ISNULL(@pPageSize, 999);
        SET @pPageNum = ISNULL(@pPageNum, 1);

        -- 篩選房間預訂【每日入住記錄】重複記錄，只取最後一次修改記錄（wStatus = 'T'，每一天都有重複記錄）
        WITH gHotelDailyCheckIn AS ( -- 按房間預訂、預訂日期，最後創建的記錄
            SELECT
                wRoomBookingRid,
                wBookingDate, 
                wCrtDt = MAX(wCrtDt)
            FROM dbo.eHotelCheckIn
            GROUP BY wRoomBookingRid, wBookingDate
        ),
        tHotelDailyCheckIn AS (
            SELECT
                hci.*
            FROM dbo.eHotelCheckIn AS hci
            INNER JOIN dbo.eBookingRoom AS br ON br.RowID = hci.wRoomBookingRid
            INNER JOIN gHotelDailyCheckIn AS ghci ON ghci.wRoomBookingRid = hci.wRoomBookingRid AND ghci.wBookingDate = hci.wBookingDate AND hci.wCrtDt = ghci.wCrtDt
            WHERE (hci.wBookingDate BETWEEN br.wStartDate AND br.wEndtDate)
                AND ((br.wBookingStatus IN ('CL', 'UQ', 'RF') AND hci.wStatus = 'T') 
                    OR ((br.wBookingStatus NOT IN ('CL', 'UQ', 'RF') AND hci.wStatus = 'A'))
                )
        ),
        tResult AS (
            SELECT
                IsAgencyRoom = CAST(( CASE WHEN ebr.wHotelRoomRid < 1 THEN 1 ELSE 0 END ) AS BIT),
                ehci.RowID ,
                ehci.wHotelRid ,
                mh.wName AS wHotelName ,
                ehci.wBookingDate ,
                ehci.wRoomBookingRid ,
                ehci.wRoomNo ,
                ehci.wExtraRoom ,
                ehci.wIncludeBreakfast ,
                ehci.wCrtBy ,
                alt.wName AS wAllotmentType ,
                hm.wName AS wRoomType ,
                ehci.wCost ,
                ehci.wPrice AS wRoomPrice ,
                ehci.wBreakfastPrice,
                ehci.wExtraBedPrice,
                ehci.wExtraBed,
                ehci.wCurrCode ,
                ehci.wDismiss ,
                ehci.wExtent ,
                ehci.wStatus ,
                ehci.wCrtDt ,
                wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END,
                ehci.wUpdDt ,
                eb.wRefNo AS wRoomBookingRefNo ,
                daAgent.wAgentCode_Display ,
                eb.wDebitAgentCodeIn,
                eb.wDebitCounterRid,
                wAgentCodeByName = CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName ELSE daAgent.wCName END,
                rqAgent.wAgentCode_Display AS wReqAgentCode_Display ,
                wReqAgentCodeByName = CASE WHEN @pLangCd = 'en-gb' THEN rqAgent.wEName ELSE rqAgent.wCName END,
                msc.wName AS wDebitServiceCounterName ,
                ehci.wAgencyRoom ,
                ebr.wStartDate AS wRoomStartDate ,
                ebr.wEndtDate AS wRoomEndDate ,
                ebr.wTotalAmount AS wTotalRoomPrice ,
                ebr.wTotalCost AS wTotalRoomCost,
                ebr.wUseMemberCard,
                ebr.wBookingStatus ,
                wAgentCodeIn = eb.wDebitAgentCodeIn
            FROM tHotelDailyCheckIn ehci
            LEFT JOIN dbo.mHotel mh ON mh.RowID = ehci.wHotelRid
            LEFT JOIN dbo.mAllotmentGroup alt ON alt.RowID = ehci.wAllotmentGroupRid
            LEFT JOIN dbo.mHotelRoom hm ON hm.RowID = ehci.wRoomRid
            LEFT JOIN dbo.eBookingRoom ebr ON ebr.RowID = ehci.wRoomBookingRid
            LEFT JOIN dbo.eBookingHotel ebh ON ebh.RowID = ebr.wHotelBookingRid AND ebh.wStatus = 'A'
            LEFT JOIN dbo.eBooking eb ON eb.RowID = ebr.wBookingRid
            LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ehci.wUpdBy
            INNER JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
            LEFT JOIN [RollsMary].[dbo].[mAgent] rqAgent ON rqAgent.wAgentCodeIn = eb.wReqAgentCodeIn
            LEFT JOIN dbo.mServiceCounter msc ON msc.RowID = eb.wDebitCounterRid
            LEFT JOIN @vData_DebitCounterRegion vr ON msc.wRegion = vr.SelectionItem
            LEFT JOIN @vData_DebitCounterRid v ON eb.wDebitCounterRid = v.SelectionItem
            WHERE ( @pHotelRid = 0 OR @pHotelRid = ehci.wHotelRid )
                AND ( @pRoomRid = 0 OR @pRoomRid = ehci.wRoomRid )
                AND ( @pAllotmentGroupRid = 0 OR @pAllotmentGroupRid = ehci.wAllotmentGroupRid )
                AND ( @pRoomStartDate IS NULL OR ehci.wBookingDate >= @pRoomStartDate )
                AND ( @pRoomEndDate IS NULL OR ehci.wBookingDate <= @pRoomEndDate )
                AND ( @vDebitCounterRegionCount = 0 OR vr.SelectionItem IS NOT NULL )
                AND ( @vDebitCounterRidCount = 0 OR v.SelectionItem IS NOT NULL )
                AND ( @pHotelRegion = '' OR @pHotelRegion = mh.wRegion )
                AND ( @pAgencyRoom = ' ' OR @pAgencyRoom = ehci.wAgencyRoom )
                AND ( @pStatus = ' ' OR @pStatus = ehci.wStatus )
                AND ( ehci.wBookingDate >= ebr.wStartDate AND ehci.wBookingDate < ebr.wEndtDate) -- 用DATEADD - 1，如果wEndDate = '0001-01-01'，導致溢出Exception，半開半閉區間[wStatrDate, wEndDate)
        ),
        tCount AS (
            SELECT COUNT(1) AS wRecordCount
            FROM tResult
        )
        
        SELECT
            tResult.* ,
            wRecordCount
        FROM tResult , tCount
        ORDER BY CASE WHEN CHARINDEX('|wCrtDt_DESC|', @pSort) = 1 THEN tResult.wCrtDt END DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );
    END;