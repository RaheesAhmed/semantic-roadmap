CREATE PROC [spa].[SUNTrip_SetHotelRoomPriceChange]
    @pOldXML    XML,
    @pNewXML    XML
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sShouldUpdate CHAR(1) = 'N';

        SELECT  RowID               = T.tmp.value('@RowID',                 'BIGINT'),
                wHotelRoomRid       = T.tmp.value('@wHotelRoomRid',         'BIGINT'),
                wIsSpecialDate      = T.tmp.value('@wIsSpecialDate',        'CHAR(1)'),
                wStartDate          = T.tmp.value('@wStartDate',            'DATE'),
                wEndDate            = T.tmp.value('@wEndDate',              'DATE'),
                wCurrCode           = T.tmp.value('@wCurrCode',             'VARCHAR(6)'),
                wMonRoomPrice       = T.tmp.value('@wMonRoomPrice',         'NUMERIC(18,4)'),
                wTueRoomPrice       = T.tmp.value('@wTueRoomPrice',         'NUMERIC(18,4)'),
                wWedRoomPrice       = T.tmp.value('@wWedRoomPrice',         'NUMERIC(18,4)'),
                wThuRoomPrice       = T.tmp.value('@wThuRoomPrice',         'NUMERIC(18,4)'),
                wFriRoomPrice       = T.tmp.value('@wFriRoomPrice',         'NUMERIC(18,4)'),
                wSatRoomPrice       = T.tmp.value('@wSatRoomPrice',         'NUMERIC(18,4)'),
                wSunRoomPrice       = T.tmp.value('@wSunRoomPrice',         'NUMERIC(18,4)'),
                wMonRoomCost        = T.tmp.value('@wMonRoomCost',          'NUMERIC(18,4)'),
                wTueRoomCost        = T.tmp.value('@wTueRoomCost',          'NUMERIC(18,4)'),
                wWedRoomCost        = T.tmp.value('@wWedRoomCost',          'NUMERIC(18,4)'),
                wThuRoomCost        = T.tmp.value('@wThuRoomCost',          'NUMERIC(18,4)'),
                wFriRoomCost        = T.tmp.value('@wFriRoomCost',          'NUMERIC(18,4)'),
                wSatRoomCost        = T.tmp.value('@wSatRoomCost',          'NUMERIC(18,4)'),
                wSunRoomCost        = T.tmp.value('@wSunRoomCost',          'NUMERIC(18,4)'),
                wMonBreakfastPrice  = T.tmp.value('@wMonBreakfastPrice',    'NUMERIC(18,4)'),
                wTueBreakfastPrice  = T.tmp.value('@wTueBreakfastPrice',    'NUMERIC(18,4)'),
                wWedBreakfastPrice  = T.tmp.value('@wWedBreakfastPrice',    'NUMERIC(18,4)'),
                wThuBreakfastPrice  = T.tmp.value('@wThuBreakfastPrice',    'NUMERIC(18,4)'),
                wFriBreakfastPrice  = T.tmp.value('@wFriBreakfastPrice',    'NUMERIC(18,4)'),
                wSatBreakfastPrice  = T.tmp.value('@wSatBreakfastPrice',    'NUMERIC(18,4)'),
                wSunBreakfastPrice  = T.tmp.value('@wSunBreakfastPrice',    'NUMERIC(18,4)'),
                wMonExtraBedPrice   = T.tmp.value('@wMonExtraBedPrice',     'NUMERIC(18,4)'),
                wTueExtraBedPrice   = T.tmp.value('@wTueExtraBedPrice',     'NUMERIC(18,4)'),
                wWedExtraBedPrice   = T.tmp.value('@wWedExtraBedPrice',     'NUMERIC(18,4)'),
                wThuExtraBedPrice   = T.tmp.value('@wThuExtraBedPrice',     'NUMERIC(18,4)'),
                wFriExtraBedPrice   = T.tmp.value('@wFriExtraBedPrice',     'NUMERIC(18,4)'),
                wSatExtraBedPrice   = T.tmp.value('@wSatExtraBedPrice',     'NUMERIC(18,4)'),
                wSunExtraBedPrice   = T.tmp.value('@wSunExtraBedPrice',     'NUMERIC(18,4)')
        INTO #vOldHotelRoomPrice_DataSet
        FROM @pOldXML.nodes('DataSet/Record') T(tmp);

        SELECT  RowID               = T.tmp.value('@RowID',                 'BIGINT'),
                wHotelRoomRid       = T.tmp.value('@wHotelRoomRid',         'BIGINT'),
                wIsSpecialDate      = T.tmp.value('@wIsSpecialDate',        'CHAR(1)'),
                wStartDate          = T.tmp.value('@wStartDate',            'DATE'),
                wEndDate            = T.tmp.value('@wEndDate',              'DATE'),
                wCurrCode           = T.tmp.value('@wCurrCode',             'VARCHAR(6)'),
                wMonRoomPrice       = T.tmp.value('@wMonRoomPrice',         'NUMERIC(18,4)'),
                wTueRoomPrice       = T.tmp.value('@wTueRoomPrice',         'NUMERIC(18,4)'),
                wWedRoomPrice       = T.tmp.value('@wWedRoomPrice',         'NUMERIC(18,4)'),
                wThuRoomPrice       = T.tmp.value('@wThuRoomPrice',         'NUMERIC(18,4)'),
                wFriRoomPrice       = T.tmp.value('@wFriRoomPrice',         'NUMERIC(18,4)'),
                wSatRoomPrice       = T.tmp.value('@wSatRoomPrice',         'NUMERIC(18,4)'),
                wSunRoomPrice       = T.tmp.value('@wSunRoomPrice',         'NUMERIC(18,4)'),
                wMonRoomCost        = T.tmp.value('@wMonRoomCost',          'NUMERIC(18,4)'),
                wTueRoomCost        = T.tmp.value('@wTueRoomCost',          'NUMERIC(18,4)'),
                wWedRoomCost        = T.tmp.value('@wWedRoomCost',          'NUMERIC(18,4)'),
                wThuRoomCost        = T.tmp.value('@wThuRoomCost',          'NUMERIC(18,4)'),
                wFriRoomCost        = T.tmp.value('@wFriRoomCost',          'NUMERIC(18,4)'),
                wSatRoomCost        = T.tmp.value('@wSatRoomCost',          'NUMERIC(18,4)'),
                wSunRoomCost        = T.tmp.value('@wSunRoomCost',          'NUMERIC(18,4)'),
                wMonBreakfastPrice  = T.tmp.value('@wMonBreakfastPrice',    'NUMERIC(18,4)'),
                wTueBreakfastPrice  = T.tmp.value('@wTueBreakfastPrice',    'NUMERIC(18,4)'),
                wWedBreakfastPrice  = T.tmp.value('@wWedBreakfastPrice',    'NUMERIC(18,4)'),
                wThuBreakfastPrice  = T.tmp.value('@wThuBreakfastPrice',    'NUMERIC(18,4)'),
                wFriBreakfastPrice  = T.tmp.value('@wFriBreakfastPrice',    'NUMERIC(18,4)'),
                wSatBreakfastPrice  = T.tmp.value('@wSatBreakfastPrice',    'NUMERIC(18,4)'),
                wSunBreakfastPrice  = T.tmp.value('@wSunBreakfastPrice',    'NUMERIC(18,4)'),
                wMonExtraBedPrice   = T.tmp.value('@wMonExtraBedPrice',     'NUMERIC(18,4)'),
                wTueExtraBedPrice   = T.tmp.value('@wTueExtraBedPrice',     'NUMERIC(18,4)'),
                wWedExtraBedPrice   = T.tmp.value('@wWedExtraBedPrice',     'NUMERIC(18,4)'),
                wThuExtraBedPrice   = T.tmp.value('@wThuExtraBedPrice',     'NUMERIC(18,4)'),
                wFriExtraBedPrice   = T.tmp.value('@wFriExtraBedPrice',     'NUMERIC(18,4)'),
                wSatExtraBedPrice   = T.tmp.value('@wSatExtraBedPrice',     'NUMERIC(18,4)'),
                wSunExtraBedPrice   = T.tmp.value('@wSunExtraBedPrice',     'NUMERIC(18,4)'),
                RecordState         = T.tmp.value('@RecordState',           'CHAR(1)')
        INTO #vNewHotelRoomPrice_DataSet
        FROM @pNewXML.nodes('DataSet/Record') T(tmp);

        SELECT @sShouldUpdate = 'Y'
        FROM #vNewHotelRoomPrice_DataSet new
        LEFT JOIN #vOldHotelRoomPrice_DataSet old ON old.RowID = new.RowID
        WHERE new.RecordState IN ('I', 'U')
            AND (
                   old.RowID IS NULL
                OR old.wHotelRoomRid <> new.wHotelRoomRid
                OR old.wIsSpecialDate <> new.wIsSpecialDate
                OR old.wStartDate <> new.wStartDate
                OR old.wEndDate <> new.wEndDate
                OR old.wCurrCode <> new.wCurrCode
                OR old.wMonRoomPrice <> new.wMonRoomPrice
                OR old.wTueRoomPrice <> new.wTueRoomPrice
                OR old.wWedRoomPrice <> new.wWedRoomPrice
                OR old.wThuRoomPrice <> new.wThuRoomPrice
                OR old.wFriRoomPrice <> new.wFriRoomPrice
                OR old.wSatRoomPrice <> new.wSatRoomPrice
                OR old.wSunRoomPrice <> new.wSunRoomPrice
            );

        IF @sShouldUpdate = 'Y'
        BEGIN
            DECLARE @vXML XML;

            SET @vXML = (
                SELECT  tmp.RowID,
                        wRoomRid = tmp.wHotelRoomRid,
                        wType = IIF(tmp.wIsSpecialDate = 'Y', 'event', 'normal'),
                        wStartDate = FORMAT(tmp.wStartDate, 'yyyy-MM-dd'),
                        wEndDate = FORMAT(ISNULL(tmp.wEndDate, '9999-12-31'), 'yyyy-MM-dd'),
                        tmp.wCurrCode,
                        tmp.wMonRoomPrice,
                        tmp.wTueRoomPrice,
                        tmp.wWedRoomPrice,
                        tmp.wThuRoomPrice,
                        tmp.wFriRoomPrice,
                        tmp.wSatRoomPrice,
                        tmp.wSunRoomPrice-- ,
                        --tmp.wMonRoomCost,
                        --tmp.wTueRoomCost,
                        --tmp.wWedRoomCost,
                        --tmp.wThuRoomCost,
                        --tmp.wFriRoomCost,
                        --tmp.wSatRoomCost,
                        --tmp.wSunRoomCost,
                        --tmp.wMonBreakfastPrice,
                        --tmp.wTueBreakfastPrice,
                        --tmp.wWedBreakfastPrice,
                        --tmp.wThuBreakfastPrice,
                        --tmp.wFriBreakfastPrice,
                        --tmp.wSatBreakfastPrice,
                        --tmp.wSunBreakfastPrice,
                        --tmp.wMonExtraBedPrice,
                        --tmp.wTueExtraBedPrice,
                        --tmp.wWedExtraBedPrice,
                        --tmp.wThuExtraBedPrice,
                        --tmp.wFriExtraBedPrice,
                        --tmp.wSatExtraBedPrice,
                        --tmp.wSunExtraBedPrice
                FROM #vNewHotelRoomPrice_DataSet tmp
                WHERE tmp.RecordState IN ('I', 'U')
                FOR XML RAW('Record'), ROOT('DataSet')
            );

            IF @vXML IS NOT NULL
                EXEC spa.SUNTrip_WriteApiLogForHotelRoomPrice  @pType = 'Price', @pXML = @vXML;
        END

        IF OBJECT_ID('tempdb..#vOldHotelRoomPrice_DataSet') IS NOT NULL
            DROP TABLE #vOldHotelRoomPrice_DataSet;

        IF OBJECT_ID('tempdb..#vNewHotelRoomPrice_DataSet') IS NOT NULL
            DROP TABLE #vNewHotelRoomPrice_DataSet;
    END