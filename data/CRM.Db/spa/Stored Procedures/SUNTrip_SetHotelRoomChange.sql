CREATE PROC [spa].[SUNTrip_SetHotelRoomChange]
    @pOldXML    XML,
    @pNewXML    XML
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sShouldUpdate CHAR(1) = 'N';

        SELECT  RowID               = T.tmp.value('@RowID',              'BIGINT'),
                wHotelRID           = T.tmp.value('@wHotelRid',          'BIGINT'),
                wCode               = T.tmp.value('@wCode',              'VARCHAR(30)'),
                wName               = T.tmp.value('@wName',              'NVARCHAR(200)'),
                wEname              = T.tmp.value('@wEname',             'NVARCHAR(100)'),
                wJname              = T.tmp.value('@wJname',             'NVARCHAR(100)'),
                wThname             = T.tmp.value('@wThname',            'NVARCHAR(100)'),
                wKname              = T.tmp.value('@wKname',             'NVARCHAR(100)'),
                wRemarks            = T.tmp.value('@wRemarks',           'NVARCHAR(500)'),
                wSeqNo              = T.tmp.value('@wSeqNo',             'INT'),
                wMaxPeopleQty       = T.tmp.value('@wMaxPeopleQty',      'INT'),            -- 入住人數上限
                wCanExtBedType      = T.tmp.value('@wCanExtBedType',     'CHAR(1)'),        -- 可否加床位
                wBreakfastType      = T.tmp.value('@wBreakfastType',     'VARCHAR(30)'),    -- 早餐方式
                wBedType            = T.tmp.value('@wBedType' ,          'VARCHAR(30)'),    -- 床類
                wCRoomIntroduction  = T.tmp.value('@wCRoomIntroduction', 'NVARCHAR(1000)'), -- 房間簡述(中)
                wERoomIntroduction  = T.tmp.value('@wERoomIntroduction', 'NVARCHAR(1000)'), -- 房間簡述(英)
                wCRoomDescription   = T.tmp.value('@wCRoomDescription',  'NVARCHAR(1000)'), -- 房間描述(中)
                wERoomDescription   = T.tmp.value('@wERoomDescription',  'NVARCHAR(1000)'), -- 房間描述(英)
                wCRoomCondition     = T.tmp.value('@wCRoomCondition',    'NVARCHAR(1000)'), -- 房間使用條款(中)
                wERoomCondition     = T.tmp.value('@wERoomCondition',    'NVARCHAR(1000)'), -- 房間使用條款(英)
                wRoomQtyOfPerID     = T.tmp.value('@wRoomQtyOfPerID',    'INT'),            -- 每個證件可訂房數
                wRoomArea           = T.tmp.value('@wRoomArea',          'NUMERIC(18, 4)'), -- 房間面積
                wAllOpenDeposit     = T.tmp.value('@wAllOpenDeposit',    'NUMERIC(18, 4)'), -- All Open押金
                wAllLockDeposit     = T.tmp.value('@wAllLockDeposit',    'NUMERIC(18, 4)'), -- All Lock押金
                wIsMinibarFree      = T.tmp.value('@wIsMinibarFree',     'CHAR(1)'),        -- 免費Mini Bar
                wIsMinibarLock      = T.tmp.value('@wIsMinibarLock',     'CHAR(1)'),        -- 上鎖Mini Bar
                wIsSmoking          = T.tmp.value('@wIsSmoking',         'CHAR(1)'),        -- 吸菸房
                wIsNoSmoking        = T.tmp.value('@wIsNoSmoking',       'CHAR(1)')         -- 非吸菸房
        INTO #vOldHotelRoom_DataSet
        FROM @pOldXML.nodes('DataSet/Record') T(tmp);

        SELECT  RowID               = T.tmp.value('@RowID',              'BIGINT'),
                wHotelRID           = T.tmp.value('@wHotelRid',          'BIGINT'),
                wCode               = T.tmp.value('@wCode',              'VARCHAR(30)'),
                wName               = T.tmp.value('@wName',              'NVARCHAR(200)'),
                wEname              = T.tmp.value('@wEname',             'NVARCHAR(100)'),
                wJname              = T.tmp.value('@wJname',             'NVARCHAR(100)'),
                wThname             = T.tmp.value('@wThname',            'NVARCHAR(100)'),
                wKname              = T.tmp.value('@wKname',             'NVARCHAR(100)'),
                wRemarks            = T.tmp.value('@wRemarks',           'NVARCHAR(500)'),
                wSeqNo              = T.tmp.value('@wSeqNo',             'INT'),
                wMaxPeopleQty       = T.tmp.value('@wMaxPeopleQty',      'INT'),            -- 入住人數上限
                wCanExtBedType      = T.tmp.value('@wCanExtBedType',     'CHAR(1)'),        -- 可否加床位
                wBreakfastType      = T.tmp.value('@wBreakfastType',     'VARCHAR(30)'),    -- 早餐方式
                wBedType            = T.tmp.value('@wBedType' ,          'VARCHAR(30)'),    -- 床類
                wCRoomIntroduction  = T.tmp.value('@wCRoomIntroduction', 'NVARCHAR(1000)'), -- 房間簡述(中)
                wERoomIntroduction  = T.tmp.value('@wERoomIntroduction', 'NVARCHAR(1000)'), -- 房間簡述(英)
                wCRoomDescription   = T.tmp.value('@wCRoomDescription',  'NVARCHAR(1000)'), -- 房間描述(中)
                wERoomDescription   = T.tmp.value('@wERoomDescription',  'NVARCHAR(1000)'), -- 房間描述(英)
                wCRoomCondition     = T.tmp.value('@wCRoomCondition',    'NVARCHAR(1000)'), -- 房間使用條款(中)
                wERoomCondition     = T.tmp.value('@wERoomCondition',    'NVARCHAR(1000)'), -- 房間使用條款(英)
                wRoomQtyOfPerID     = T.tmp.value('@wRoomQtyOfPerID',    'INT'),            -- 每個證件可訂房數
                wRoomArea           = T.tmp.value('@wRoomArea',          'NUMERIC(18, 4)'), -- 房間面積
                wAllOpenDeposit     = T.tmp.value('@wAllOpenDeposit',    'NUMERIC(18, 4)'), -- All Open押金
                wAllLockDeposit     = T.tmp.value('@wAllLockDeposit',    'NUMERIC(18, 4)'), -- All Lock押金
                wIsMinibarFree      = T.tmp.value('@wIsMinibarFree',     'CHAR(1)'),        -- 免費Mini Bar
                wIsMinibarLock      = T.tmp.value('@wIsMinibarLock',     'CHAR(1)'),        -- 上鎖Mini Bar
                wIsSmoking          = T.tmp.value('@wIsSmoking',         'CHAR(1)'),        -- 吸菸房
                wIsNoSmoking        = T.tmp.value('@wIsNoSmoking',       'CHAR(1)'),        -- 非吸菸房
                RecordState         = T.tmp.value('@RecordState',       'CHAR(1)')
        INTO #vNewHotelRoom_DataSet
        FROM @pNewXML.nodes('DataSet/Record') T(tmp);

        SELECT @sShouldUpdate = 'Y'
        FROM #vNewHotelRoom_DataSet new
        LEFT JOIN #vOldHotelRoom_DataSet old ON old.RowID = new.RowID
        WHERE new.RecordState = 'I'
            OR (new.RecordState = 'U' AND (
                   old.RowID IS NULL
                OR old.wHotelRID <> new.wHotelRID
                OR old.wCode <> new.wCode
                OR old.wName <> new.wName
                OR old.wEname <> new.wEname
                OR old.wJname <> new.wJname
                OR old.wThname <> new.wThname
                OR old.wKname <> new.wKname
                OR old.wRemarks <> new.wRemarks
                OR old.wSeqNo <> new.wSeqNo
                OR old.wMaxPeopleQty <> new.wMaxPeopleQty
                OR old.wCanExtBedType <> new.wCanExtBedType
                OR old.wBreakfastType <> new.wBreakfastType
                OR old.wBedType <> new.wBedType
                OR old.wCRoomIntroduction <> new.wCRoomIntroduction
                OR old.wERoomIntroduction <> new.wERoomIntroduction
                OR old.wCRoomDescription <> new.wCRoomDescription
                OR old.wERoomDescription <> new.wERoomDescription
                OR old.wCRoomCondition <> new.wCRoomCondition
                OR old.wERoomCondition <> new.wERoomCondition
                OR old.wRoomQtyOfPerID <> new.wRoomQtyOfPerID
                OR old.wRoomArea <> new.wRoomArea
                OR old.wAllOpenDeposit <> new.wAllOpenDeposit
                OR old.wAllLockDeposit <> new.wAllLockDeposit
                OR old.wIsMinibarFree <> new.wIsMinibarFree
                OR old.wIsMinibarLock <> new.wIsMinibarLock
                OR old.wIsSmoking <> new.wIsSmoking
                OR old.wIsNoSmoking <> new.wIsNoSmoking
                )
            );

        IF @sShouldUpdate = 'Y'
        BEGIN
            DECLARE @vXML XML;

            -- 床類
            SELECT  tw.wCode,
                    wCName = tw.wTitle,
                    wEName = en.wTitle
            INTO #vBedType
            FROM CRM.dbo.mLookUp tw WITH(NOLOCK) 
            INNER JOIN CRM.dbo.mLookUp en WITH(NOLOCK) ON en.wCode = tw.wCode AND en.wType = tw.wType AND en.wLangCd = 'en-GB'
            WHERE tw.wType = 'BOOKING_BED_TYPE'
                AND tw.wLangCd = 'zh-TW';

            SET @vXML = (
                SELECT  tmp.RowID,
                        tmp.wHotelRID,
                        tmp.wCode,
                        wCName = tmp.wName,
                        tmp.wEname,
                        wJName = tmp.wJname,
                        wTName = tmp.wThname,
                        wKName = tmp.wKname,
                        tmp.wRoomQtyOfPerID,
                        tmp.wMaxPeopleQty,
                        wBedType_Code = ISNULL(bt.wCode, ''),
                        wBedType_CName = ISNULL(bt.wCName, ''),
                        wBedType_EName = ISNULL(bt.wEName, ''),
                        tmp.wBreakfastType,
                        tmp.wCanExtBedType,
                        tmp.wRoomArea,
                        tmp.wAllOpenDeposit,
                        tmp.wAllLockDeposit,
                        tmp.wIsMinibarFree,
                        tmp.wIsMinibarLock,
                        tmp.wIsSmoking,
                        tmp.wIsNoSmoking,
                        tmp.wCRoomIntroduction,
                        tmp.wERoomIntroduction,
                        tmp.wCRoomDescription,
                        tmp.wERoomDescription,
                        tmp.wCRoomCondition,
                        tmp.wERoomCondition
                FROM #vNewHotelRoom_DataSet tmp
                LEFT JOIN #vBedType bt ON bt.wCode = tmp.wBedType
                WHERE tmp.RecordState IN ('I', 'U')
                FOR XML RAW('Record'), ROOT('DataSet')
            );

            IF @vXML IS NOT NULL
                EXEC spa.SUNTrip_WriteApiLogForHotelRoomPrice  @pType = 'Room', @pXML = @vXML;
        END

        IF OBJECT_ID('tempdb..#vBedType') IS NOT NULL
            DROP TABLE #vBedType;

        IF OBJECT_ID('tempdb..#vOldHotelRoom_DataSet') IS NOT NULL
            DROP TABLE #vOldHotelRoom_DataSet;

        IF OBJECT_ID('tempdb..#vNewHotelRoom_DataSet') IS NOT NULL
            DROP TABLE #vNewHotelRoom_DataSet;
    END