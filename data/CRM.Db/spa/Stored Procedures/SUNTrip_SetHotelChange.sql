CREATE PROC [spa].[SUNTrip_SetHotelChange]
    @pOldXML    XML,
    @pNewXML    XML
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sShouldUpdate CHAR(1) = 'N'

        SELECT  RowID                   = T.tmp.value('@RowID',                 'BIGINT'),
                wCode                   = T.tmp.value('@wCode',                 'VARCHAR(20)'),
                wName                   = T.tmp.value('@wName',                 'NVARCHAR(100)'),
                wEname                  = T.tmp.value('@wEname',                'NVARCHAR(100)'),
                wJname                  = T.tmp.value('@wJname',                'NVARCHAR(100)'),
                wThname                 = T.tmp.value('@wThname',               'NVARCHAR(100)'),
                wKname                  = T.tmp.value('@wKname',                'NVARCHAR(100)'),				
                wRegion                 = T.tmp.value('@wRegion',               'VARCHAR(20)'),
                wDistrictCd             = T.tmp.value('@wDistrictCd',           'VARCHAR(30)'),
                wCurrCode               = T.tmp.value('@wCurrCode',             'VARCHAR(6)'),
                wAddress                = T.tmp.value('@wAddress',              'NVARCHAR(1000)'),
                wSeqNo                  = T.tmp.value('@wSeqNo',                'INT'),
                wHasWIFI                = T.tmp.value('@wHasWIFI',              'CHAR(1)'),
                wNeedEntrancePaper      = T.tmp.value('@wNeedEntrancePaper',    'CHAR(1)'),
                wEntrancePaperTips      = T.tmp.value('@wEntrancePaperTips',    'NVARCHAR(1000)'),
                wRemark                 = T.tmp.value('@wRemark',               'NVARCHAR(1000)'),
                wSmsRemark              = T.tmp.value('@wSmsRemark',            'NVARCHAR(1000)'),
                wGetKeyMethod           = T.tmp.value('@wGetKeyMethod',         'VARCHAR(5)'),
                wRoomServiceDesc       = T.tmp.value('@wRoomServiceDesc',     'NVARCHAR(1000)'),
                wHotelDesktopDesc      = T.tmp.value('@wHotelDesktopDesc',    'NVARCHAR(1000)'),
                wNeedPassengerName      = T.tmp.value('@wNeedPassengerName',    'CHAR(1)'),
                wNeedPassengerID        = T.tmp.value('@wNeedPassengerID',      'CHAR(1)'),
                wNeedPassengerBirthday  = T.tmp.value('@wNeedPassengerBirthday','CHAR(1)'),
                wNeedUploadID           = T.tmp.value('@wNeedUploadID',         'CHAR(1)')
        INTO #vOldHotel_DataSet
        FROM @pOldXML.nodes('DataSet/Record') T(tmp);

        SELECT  RowID                   = T.tmp.value('@RowID',                 'BIGINT'),
                wCode                   = T.tmp.value('@wCode',                 'VARCHAR(20)'),
                wName                   = T.tmp.value('@wName',                 'NVARCHAR(100)'),
                wEname                  = T.tmp.value('@wEname',                'NVARCHAR(100)'),
                wJname                  = T.tmp.value('@wJname',                'NVARCHAR(100)'),
                wThname                 = T.tmp.value('@wThname',               'NVARCHAR(100)'),
                wKname                  = T.tmp.value('@wKname',                'NVARCHAR(100)'),				
                wRegion                 = T.tmp.value('@wRegion',               'VARCHAR(20)'),
                wDistrictCd             = T.tmp.value('@wDistrictCd',           'VARCHAR(30)'),
                wCurrCode               = T.tmp.value('@wCurrCode',             'VARCHAR(6)'),
                wAddress                = T.tmp.value('@wAddress',              'NVARCHAR(1000)'),
                wSeqNo                  = T.tmp.value('@wSeqNo',                'INT'),
                wHasWIFI                = T.tmp.value('@wHasWIFI',              'CHAR(1)'),
                wNeedEntrancePaper      = T.tmp.value('@wNeedEntrancePaper',    'CHAR(1)'),
                wEntrancePaperTips      = T.tmp.value('@wEntrancePaperTips',    'NVARCHAR(1000)'),
                wRemark                 = T.tmp.value('@wRemark',               'NVARCHAR(1000)'),
                wSmsRemark              = T.tmp.value('@wSmsRemark',            'NVARCHAR(1000)'),
                wGetKeyMethod           = T.tmp.value('@wGetKeyMethod',         'VARCHAR(5)'),
                wRoomServiceDesc       = T.tmp.value('@wRoomServiceDesc',     'NVARCHAR(1000)'),
                wHotelDesktopDesc      = T.tmp.value('@wHotelDesktopDesc',    'NVARCHAR(1000)'),
                wNeedPassengerName      = T.tmp.value('@wNeedPassengerName',    'CHAR(1)'),
                wNeedPassengerID        = T.tmp.value('@wNeedPassengerID',      'CHAR(1)'),
                wNeedPassengerBirthday  = T.tmp.value('@wNeedPassengerBirthday','CHAR(1)'),
                wNeedUploadID           = T.tmp.value('@wNeedUploadID',         'CHAR(1)'),
                RecordState             = T.tmp.value('@RecordState',           'CHAR(1)')
        INTO #vNewHotel_DataSet
        FROM @pNewXML.nodes('DataSet/Record') T(tmp);
        
        SELECT @sShouldUpdate = 'Y'
        FROM #vNewHotel_DataSet new
        LEFT JOIN #vOldHotel_DataSet old ON old.RowID = new.RowID
        WHERE new.RecordState = 'I'
            OR (new.RecordState ='U' AND (
                   old.wCode <> new.wCode
                OR old.wName <> new.wName
                OR old.wEname <> new.wEname
                OR old.wJname <> new.wJname
                OR old.wThname <> new.wThname
                OR old.wKname <> new.wKname
                OR old.wRegion <> new.wRegion
                OR old.wDistrictCd <> new.wDistrictCd
                OR old.wCurrCode <> new.wCurrCode
                OR old.wAddress <> new.wAddress
                OR old.wSeqNo <> new.wSeqNo
                OR old.wHasWIFI <> new.wHasWIFI
                OR old.wNeedEntrancePaper <> new.wNeedEntrancePaper
                OR old.wEntrancePaperTips <> new.wEntrancePaperTips
                OR old.wRemark <> new.wRemark
                OR old.wSmsRemark <> new.wSmsRemark
                OR old.wGetKeyMethod <> new.wGetKeyMethod
                OR old.wRoomServiceDesc <> new.wRoomServiceDesc
                OR old.wHotelDesktopDesc <> new.wHotelDesktopDesc
                OR old.wNeedPassengerName <> new.wNeedPassengerName
                OR old.wNeedPassengerID <> new.wNeedPassengerID
                OR old.wNeedUploadID <> new.wNeedUploadID
                OR old.wNeedPassengerBirthday <> new.wNeedPassengerBirthday
                OR old.wNeedPassengerBirthday <> new.wNeedPassengerBirthday
                )
            );

        IF @sShouldUpdate = 'Y'
        BEGIN
            DECLARE @vXML XML;

            -- 地區
            SELECT  wCode, wTitle
            INTO #vRegion
            FROM CRM.dbo.mLookUp WITH(NOLOCK) 
            WHERE wType = 'REGION' AND wLangCd = 'zh-TW';

            -- 區域
            SELECT  wCode, wTitle
            INTO #vDistrict
            FROM CRM.dbo.mLookUp WITH(NOLOCK) 
            WHERE wType = 'DISTRICT' AND wLangCd = 'zh-TW';

            SET @vXML = (
                SELECT  RowID                   = tmp.RowID,
                        wCode                   = tmp.wCode,
                        wName                   = tmp.wName,
                        wCName                  = tmp.wName,
                        wEName                  = tmp.wEname,
                        wJName                  = tmp.wJname,
                        wTName                  = tmp.wThname,
                        wKName                  = tmp.wKname,
                        wRegion                 = CONCAT(ISNULL(reg.wCode, ''), IIF(ISNULL(reg.wCode, '') = '' OR ISNULL(reg.wTitle, '') = '', '', '-'), ISNULL(reg.wTitle, '')),
                        wLocation               = CONCAT(ISNULL(d.wCode, ''), IIF(ISNULL(d.wCode, '') = '' OR NULLIF(d.wTitle, '') = '', '', '-'), ISNULL(d.wTitle, '')),
                        wCurrCode               = tmp.wCurrCode,
                        wAddress                = tmp.wAddress,
                        wSeqNo                  = tmp.wSeqNo,
                        wHasWIFI                = tmp.wHasWIFI,
                        wNeedEntrancePaper      = tmp.wNeedEntrancePaper,
                        wEntrancePaperTips      = tmp.wEntrancePaperTips,
                        wRemark                 = tmp.wRemark,
                        wSmsRemark              = tmp.wSmsRemark,
                        wGetKeyMethod           = tmp.wGetKeyMethod,
                        wRoomServiceDesc        = tmp.wRoomServiceDesc,
                        wHotelDesktopDesc       = tmp.wHotelDesktopDesc,
                        wNeedPassengerName      = tmp.wNeedPassengerName,
                        wNeedPassengerID        = tmp.wNeedPassengerID,
                        wNeedPassengerBirthday  = tmp.wNeedPassengerBirthday,
                        wNeedUploadID           = tmp.wNeedUploadID 
                FROM #vNewHotel_DataSet tmp
                LEFT JOIN #vRegion reg ON reg.wCode = tmp.wRegion
                LEFT JOIN #vDistrict d ON d.wCode = tmp.wDistrictCd
                WHERE RecordState IN ('I', 'U')
                FOR XML RAW('Record'), ROOT('DataSet')
            );
            
            IF @vXML IS NOT NULL
                EXEC spa.SUNTrip_WriteApiLogForHotelRoomPrice  @pType = 'Hotel', @pXML = @vXML;
        END

        IF OBJECT_ID('tempdb..#vRegion') IS NOT NULL
            DROP TABLE #vRegion;

        IF OBJECT_ID('tempdb..#vDistrict') IS NOT NULL
            DROP TABLE #vDistrict;

        IF OBJECT_ID('tempdb..#vOldHotel_DataSet') IS NOT NULL
            DROP TABLE #vOldHotel_DataSet;

        IF OBJECT_ID('tempdb..#vNewHotel_DataSet') IS NOT NULL
            DROP TABLE #vNewHotel_DataSet;
    END