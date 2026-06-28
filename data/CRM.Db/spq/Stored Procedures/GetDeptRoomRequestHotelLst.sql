CREATE PROCEDURE [spq].[GetDeptRoomRequestHotelLst]
(
    @pDeptCd VARCHAR(20),
    @pRegionCd VARCHAR(20),
    @pHotelType VARCHAR(10) = NULL,
    @pDate DATE,
    @pStatus CHAR(1),
    @pLangCd VARCHAR(10)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sWeekDay INT;

    SET @pDeptCd = NULLIF(@pDeptCd, '');
    SET @pRegionCd = NULLIF(@pRegionCd, '');
    SET @pDate = ISNULL(@pDate, CAST(GETDATE() AS DATE));
    SET @pHotelType = NULLIF(@pHotelType, ''); -- NULL: 全部酒店  HA：有設房額  NA：沒設房額  LH：本館  EH：外館
    SET @pStatus = NULLIF(@pStatus, '');
    SET @pLangCd = NULLIF(@pLangCd, '');
    SET @sWeekDay = DATEPART(DW, @pDate);
	
    CREATE TABLE #tAllotmentHotel(wHotelRid BIGINT PRIMARY KEY);

    -- 部門、日期有設置房額的酒店（值為0等於沒設置有房額）
    INSERT INTO #tAllotmentHotel(wHotelRid)
    SELECT ah.wHotelRid
    FROM dbo.eAllotmentHotel AS ah
    INNER JOIN dbo.eAllotmentHotelDtl AS ahd ON ahd.wAllotmentHotelRid = ah.RowID
    INNER JOIN dbo.mAllotmentGroup AS ag ON ag.RowID = ahd.wAllotmentGroupRid AND ag.wDept = @pDeptCd
    WHERE ah.wStatus = 'A'
        AND (ah.wStartDate <= @pDate AND (ah.wEndDate IS NULL OR @pDate <= ah.wEndDate))
    GROUP BY ah.wHotelRid
    HAVING (CASE @sWeekDay
                WHEN 1 THEN SUM(IIF(ag.RowID IS NULL, 0, ISNULL(ahd.wSunQty,0)))
                WHEN 2 THEN SUM(IIF(ag.RowID IS NULL, 0, ISNULL(ahd.wMonQty,0)))
                WHEN 3 THEN SUM(IIF(ag.RowID IS NULL, 0, ISNULL(ahd.wTueQty,0)))
                WHEN 4 THEN SUM(IIF(ag.RowID IS NULL, 0, ISNULL(ahd.wWedQty,0)))
                WHEN 5 THEN SUM(IIF(ag.RowID IS NULL, 0, ISNULL(ahd.wThuQty,0)))
                WHEN 6 THEN SUM(IIF(ag.RowID IS NULL, 0, ISNULL(ahd.wFriQty,0)))
                WHEN 7 THEN SUM(IIF(ag.RowID IS NULL, 0, ISNULL(ahd.wSatQty,0)))
                ELSE 0 END
            ) > 0;

    SELECT
        h.RowID ,
        h.wCode ,
        h.wName ,
        wDisplayName = CASE @pLangCd WHEN 'en-gb' THEN ISNULL(NULLIF(h.wEname, ''), h.wName)
                                     WHEN 'zh-TW' THEN h.wName
                                     WHEN 'ja-JP' THEN ISNULL(NULLIF(h.wJname, ''), h.wName)
                                     WHEN 'th-TH' THEN ISNULL(NULLIF(h.wThname, ''), h.wName)
                                     WHEN 'ko-KR' THEN ISNULL(NULLIF(h.wKname, ''), h.wName)
                                     ELSE h.wName END,
        h.wEname ,
        h.wJname ,
        h.wThname ,
        h.wKname ,
        wRegionCd = h.wRegion,
        wRegionName = lupr.wTitle,
        h.wCurrCode ,
        wCurrency = lupc.wTitle ,
        h.wIsBase , -- 1:本館  0: 外館
        h.wAddress ,
        h.wStatus ,
        wIsAgentHotel = IIF(ah.wHotelRid IS NULL, 0, 1) -- 0：無房額  1：有房額
    FROM dbo.mHotel AS h
    INNER JOIN mLookUp AS lupr ON lupr.wCode = h.wRegion AND lupr.wType = 'REGION' AND lupr.wLangCd = @pLangCd
    INNER JOIN mLookUp AS lupc ON lupc.wCode = h.wCurrCode AND lupc.wType = 'CURRENCY' AND lupc.wLangCd = @pLangCd
    LEFT JOIN #tAllotmentHotel AS ah ON ah.wHotelRid = h.RowID
    WHERE (@pStatus IS NULL OR @pStatus = h.wStatus)
        AND (@pRegionCd IS NULL OR @pRegionCd = h.wRegion)
        AND (@pHotelType IS NULL
            OR (@pHotelType = 'HA' AND ah.wHotelRid IS NOT NULL)
            OR (@pHotelType = 'NA' AND ah.wHotelRid IS NULL)
            OR (@pHotelType = 'LH' AND h.wIsBase = '1')
            OR (@pHotelType = 'EH' AND h.wIsBase <> '1')
        )
    OPTION(RECOMPILE);

    IF OBJECT_ID('tempdb..#tAllotmentHotel') IS NOT NULL
        DROP TABLE #tAllotmentHotel;
END;