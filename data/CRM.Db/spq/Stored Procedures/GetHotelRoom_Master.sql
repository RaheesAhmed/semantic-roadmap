
CREATE PROCEDURE spq.GetHotelRoom_Master
    @pHotelName NVARCHAR(100) ,
    @pRoomEName NVARCHAR(100) ,
    @pCode VARCHAR(30) ,
    @pName NVARCHAR(200) ,
    @pStatus CHAR(1) ,
    @pSort VARCHAR(200) ,
    @pLangCd VARCHAR(10) ,
    @pPageSize INT ,
    @pPageNum INT
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;						

        SET @pHotelName = NULLIF(@pHotelName, '');
        SET @pRoomEName = NULLIF(@pRoomEName, '');
        SET @pHotelName = IIF(@pHotelName IS NULL, NULL, '%' + @pHotelName +'%');
        SET @pRoomEName = IIF(@pRoomEName IS NULL, NULL, '%' + @pRoomEName + '%')
        SET @pCode = NULLIF(@pCode, '');
        SET @pName = NULLIF(@pName, '');
        SET @pStatus = NULLIF(@pStatus, ' ');
        SET @pSort = ISNULL(NULLIF(@pSort, ''), '||');
        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'en-gb');
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);

        WITH  tResult AS ( 
            SELECT 
                hr.RowID ,
                h.wName AS wHotelName ,
                h.wEname AS wHotelEname ,
                hr.wHotelRid ,
                hr.wCode AS wRoomCode ,
                hr.wName ,
                hr.wEname ,
                hr.wJname ,
                hr.wThname ,
                hr.wKname ,
                hr.wRemarks ,
                hr.wSeqNo ,
                hr.wMaxPeopleQty,
                hr.wCanExtBedType,
                hr.wBedType,
                hr.wBreakfastType,
                hr.wCRoomIntroduction,
                hr.wERoomIntroduction,
                hr.wCRoomDescription,
                hr.wERoomDescription,
                hr.wCRoomCondition,
                hr.wERoomCondition,
                hr.wIsSunTrip,
                hr.wRoomQtyOfPerID,
                hr.wRoomArea,
                hr.wAllOpenDeposit,
                hr.wAllLockDeposit,
                hr.wIsMinibarFree,
                hr.wIsMinibarLock,
                hr.wIsSmoking,
                hr.wIsNoSmoking,
                hr.wStatus ,
                hr.wCrtDt ,
                hr.wCrtBy ,
                hr.wUpdDt ,
                hr.wUpdBy ,
                wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END ,
                wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END ,
                wRoomName = CASE WHEN @pLangCd = 'en-GB' THEN ( CASE WHEN LEN(hr.wEname) > 0 THEN hr.wEname ELSE hr.wName END )
                                 WHEN @pLangCd = 'ja-JP' THEN ( CASE WHEN LEN(hr.wJname) > 0 THEN hr.wJname ELSE hr.wName END )
                                 WHEN @pLangCd = 'ko-KR' THEN ( CASE WHEN LEN(hr.wKname) > 0 THEN hr.wKname ELSE hr.wName END )
                                 WHEN @pLangCd = 'th-TH' THEN ( CASE WHEN LEN(hr.wThname) > 0 THEN hr.wThname ELSE hr.wName END )
                                 ELSE hr.wName 
                            END
            FROM dbo.mHotelRoom hr WITH(NOLOCK)
            INNER JOIN dbo.mHotel h WITH(NOLOCK) ON h.RowID = hr.wHotelRid
            LEFT JOIN RollsMary.dbo.mUsr usr WITH(NOLOCK) ON usr.RowID = hr.wUpdBy
            LEFT JOIN RollsMary.dbo.mUsr crusr WITH(NOLOCK) ON crusr.RowID = hr.wCrtBy
            WHERE ( @pHotelName IS NULL OR h.wName LIKE @pHotelName)
                AND ( @pRoomEName IS NULL OR hr.wEname LIKE @pRoomEName)
                AND ( @pCode IS NULL OR @pCode = hr.wCode )
                AND ( @pName IS NULL OR @pName = hr.wName OR @pName = hr.wJname OR @pName = hr.wKname OR @pName = hr.wThname)
                AND ( @pStatus IS NULL OR @pStatus = hr.wStatus )
        ),
        tCount AS (
            SELECT wRecordCount = COUNT(1) FROM tResult
        )

        SELECT  tResult.* ,
                wRecordCount
        FROM    tResult ,
                tCount
        ORDER BY CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wCrtDt END DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		FETCH NEXT @pPageSize ROWS ONLY;
    END;