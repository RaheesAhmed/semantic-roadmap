CREATE PROCEDURE [spq].[GetRoomAllotmentDailyRecord]
(
    @pHotelRid BIGINT = NULL ,
    @pFromDate DATE = NULL ,
    @pToDate DATE = NULL ,
    @pRoomRid BIGINT = NULL ,
    @pAllotmentGroupRid BIGINT = NULL ,
    @pServiceCounterRid BIGINT = NULL ,
    @pStatus CHAR(1) = '' ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1 ,
    @pLangCd VARCHAR(10) = 'en-GB'
)
AS
    BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
        SET NOCOUNT ON;
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;   

        SET @pHotelRid = IIF(@pHotelRid <= 0, NULL, @pHotelRid);
        SET @pRoomRid = IIF(@pRoomRid <= 0, NULL, @pRoomRid);
        SET @pAllotmentGroupRid = IIF(@pAllotmentGroupRid <= 0, NULL, @pAllotmentGroupRid);
        SET @pServiceCounterRid = IIF(@pServiceCounterRid <= 0, NULL, @pServiceCounterRid);
        SET @pPageSize = IIF(@pPageSize <= 0, 999, @pPageSize);
        SET @pPageNum = IIF(@pPageNum <= 0, 1, @pPageNum);
        SET @pLangCd = ISNULL(@pLangCd, 'en-GB');
        SET @pStatus = NULLIF(@pStatus, ' ');

        WITH tResult AS (
            SELECT
                AHD.RowId ,
                AHD.wAllotmentGroupRid ,
                wHotelName  = MHT.wName,
                wHotelRoomName  = MHTR.wName,
                wAllotmentGroupName = ALT.wName,
                AHD.wDate ,
                AHD.wCurrCode ,
                wRoomPrice ,
                wBreakfastPrice ,
                wRoomCost ,
                AHD.wExtraBedPrice,
                wIsCustomized ,
                AHD.wStatus ,
                wAllotmentStatus = IIF(AHD.wStatus = 'A', 'P', 'C'),
                AHD.wCrtDt ,
                AHD.wCrtBy ,
                AHD.wUpdDt ,
                AHD.wUpdBy ,
                AHD.wAllotmentQty ,
                AHD.wBookedQty ,
                AHD.wExtraQty,
                AHD.wOnHoldQty, -- 停用數量
                wRoomsLeft = ( AHD.wAllotmentQty + AHD.wExtraQty ) - AHD.wOnHoldQty - AHD.wBookedQty, -- 剩餘房額 = 房間配額 + 額外房 - 停用 - 已訂
                wUpdByCName = IIF(@pLangCd = 'en-GB', USR.wName, USR.wCName),
                wCreatedByCName = IIF(@pLangCd = 'en-GB', CRUSR.wName, CRUSR.wCName)
            FROM dbo.eAllotmentHotelDaily AS AHD
            INNER JOIN dbo.mHotelRoom AS MHTR ON MHTR.RowID = AHD.wRoomRid
            INNER JOIN dbo.mHotel AS MHT ON MHT.RowID = MHTR.wHotelRid
            INNER JOIN dbo.mAllotmentGroup AS ALT ON ALT.RowID = AHD.wAllotmentGroupRid
            LEFT JOIN dbo.mAllotmentGroupDtl AS ALTDTL ON (@pServiceCounterRid IS NOT NULL AND ALTDTL.wAllotmentGroupRid = ALT.RowID) -- 如果@pServiceCounterRid IS NULL，不Join dbo.mAllotmentGroupDtl
            LEFT JOIN RollsMary.dbo.mUsr AS USR ON USR.RowID = AHD.wUpdBy
            LEFT JOIN RollsMary.dbo.mUsr AS CRUSR ON CRUSR.RowID = AHD.wCrtBy
            WHERE ( @pStatus IS NULL OR @pStatus = AHD.wStatus )
                AND ( @pRoomRid IS NULL OR @pRoomRid = AHD.wRoomRid  )
                AND ( @pHotelRid IS NULL OR @pHotelRid = MHTR.wHotelRid )
                AND ( @pAllotmentGroupRid IS NULL OR @pAllotmentGroupRid = AHD.wAllotmentGroupRid )
                AND ( @pServiceCounterRid IS NULL OR @pServiceCounterRid = ALTDTL.wCounterRid )
                AND ( @pFromDate IS NULL OR @pFromDate <= AHD.wDate )
                AND ( @pToDate IS NULL OR @pToDate >= AHD.wDate )
        ),
        tCount AS (
            SELECT wRecordCount = COUNT(1) FROM tResult
        )
        
        SELECT
            tResult.* ,
            wRecordCount
        FROM tResult , tCount
        ORDER BY wDate DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION(RECOMPILE);
    END;