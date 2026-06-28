CREATE PROC [spa].[SUNTrip_WriteApiLogForHotelRoomPrice]
    @pType  VARCHAR(10),
    @pXML   XML
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sURL        NVARCHAR(1000),
                @sApiName    NVARCHAR(100),
                @sMainCompNo INT = 10;

        DECLARE @sPostData NVARCHAR(MAX),
                @sAPILogCode INT,
                @sAPILogErrMsg NVARCHAR(200);

        DECLARE @sNow DATETIME2(7) = dbo.fnUTC8Now();

        SET @sApiName   = 'CRM_Api_SunTrip_SyncHotelRoomPrice';
        SET @sURL = (SELECT TOP(1) wValue FROM RollsMary.dbo.mSysTable WHERE wItemCode = 'HOTELROOMPRICE_SUNTRIP_URL_V1');

        -- Hotel
        IF @pType = 'Hotel'
        BEGIN
            SELECT  RowID                   = T.tmp.value('@RowID',                     'BIGINT'),
                    wCode                   = T.tmp.value('@wCode',                     'VARCHAR(30)'),
                    wName                   = T.tmp.value('@wName',                     'NVARCHAR(100)'),
                    wCName                  = T.tmp.value('@wCName',                    'NVARCHAR(100)'),
                    wEName                  = T.tmp.value('@wEName',                    'NVARCHAR(100)'),
                    wJName                  = T.tmp.value('@wJName',                    'NVARCHAR(100)'),
                    wTName                  = T.tmp.value('@wTName',                    'NVARCHAR(100)'),
                    wKName                  = T.tmp.value('@wKName',                    'NVARCHAR(100)'),
                    wRegion                 = T.tmp.value('@wRegion',                   'NVARCHAR(100)'),
                    wLocation               = T.tmp.value('@wLocation',                 'NVARCHAR(100)'),
                    wCurrCode               = T.tmp.value('@wCurrCode',                 'VARCHAR(30)'),
                    wAddress                = T.tmp.value('@wAddress',                  'NVARCHAR(100)'),
                    wSeqNo                  = T.tmp.value('@wSeqNo',                    'INT'),
                    wHasWIFI                = T.tmp.value('@wHasWIFI',                  'CHAR(1)'),
                    wNeedEntrancePaper      = T.tmp.value('@wNeedEntrancePaper',        'CHAR(1)'),
                    wEntrancePaperTips      = T.tmp.value('@wEntrancePaperTips',        'NVARCHAR(1000)'),
                    wRemark                 = T.tmp.value('@wRemark',                   'NVARCHAR(1000)'),
                    wSmsRemark              = T.tmp.value('@wSmsRemark',                'NVARCHAR(1000)'),
                    wGetKeyMethod           = T.tmp.value('@wGetKeyMethod',             'VARCHAR(1)'),
                    wRoomServiceDesc       = T.tmp.value('@wRoomServiceDesc',         'NVARCHAR(1000)'),
                    wHotelDesktopDesc      = T.tmp.value('@wHotelDesktopDesc',        'NVARCHAR(1000)'),
                    wNeedPassengerName      = T.tmp.value('@wNeedPassengerName',        'CHAR(1)'),
                    wNeedPassengerID        = T.tmp.value('@wNeedPassengerID',          'CHAR(1)'),
                    wNeedPassengerBirthday  = T.tmp.value('@wNeedPassengerBirthday',    'CHAR(1)'),
                    wNeedUploadID           = T.tmp.value('@wNeedUploadID',             'CHAR(1)')
            INTO #vHotel_DataSet
            FROM @pXML.nodes('DataSet/Record') T(tmp);

            SET @sPostData = CONCAT(
                '{',
                    '"token":""',
                    ',"timestamp":"', FORMAT(DATEADD(HOUR, DATEDIFF(HOUR, GETDATE(), GETUTCDATE()), @sNow), 'yyyy-MM-dd HH:mm:ss.fffffff'), '"', -- utc
                    ',"type":"hotel"',
                    ',"hotel":[', 
                        STUFF((SELECT CONCAT(',', 
                                    '{', 
                                        '"hotelRid":', CONVERT(VARCHAR, RowID),
                                        ',"hotelCode":"', wCode, '"',
                                        --',"hotelName":"', wName, '"',
                                        ',"location":"', wLocation, '"',
                                        ',"region":"', wRegion, '"',
                                        ',"currrency":"', wCurrCode, '"',
                                        ',"address":"', wAddress , '"',
                                        ',"sorting":', CONVERT(VARCHAR, ISNULL(wSeqNo, 0)),
                                        ',"wifi":"', IIF(wHasWIFI = 'Y', 'Y', 'N'), '"',
                                        ',"xbr":"', IIF(wNeedEntrancePaper = 'Y', 'Y', 'N'), '"',
                                        ',"xbrDesc":"', wEntrancePaperTips, '"',
                                        ',"remark":"', wRemark, '"',
                                        ',"smsRemark":"', wSmsRemark, '"',
                                        ',"cscounter":"', IIF(wGetKeyMethod = '1' OR wGetKeyMethod = '3', 'Y', 'N'), '"',
                                        ',"focounter":"', IIF(wGetKeyMethod = '2' OR wGetKeyMethod = '3', 'Y', 'N'), '"',
                                        ',"cscounterDesc":"', wRoomServiceDesc, '"',
                                        ',"focounterDesc":"', wHotelDesktopDesc, '"',
                                        ',"nameRequired":"', IIF(wNeedPassengerName = 'Y', 'Y', 'N'), '"',
                                        ',"idNoRequired":"', IIF(wNeedPassengerID = 'Y', 'Y', 'N'), '"',
                                        ',"bdateRequired":"', IIF(wNeedPassengerBirthday = 'Y', 'Y', 'N') , '"',
                                        ',"idRequired":"', IIF(wNeedUploadID = 'Y', 'Y', 'N'), '"',
                                        ',"hotelName_tw":"', wCName, '"',
                                        ',"hotelName_en":"', wEName, '"',
                                        ',"hotelName_jp":"', wJName, '"',
                                        ',"hotelName_th":"', wTName, '"',
                                        ',"hotelName_kr":"', wKName, '"',
                                    '}') 
                               FROM #vHotel_DataSet 
                               WHERE RowID > 0
                               FOR XML PATH('')
                            ), 1, 1, N''),
                    ']',
                    ',"room":null',
                    ',"roomPrice":null',
                '}'
            );
            
            IF OBJECT_ID('tempdb..#vHotel_DataSet') IS NOT NULL
                DROP TABLE #vHotel_DataSet;
        END

        -- Room
        IF @pType = 'Room'
        BEGIN
            SELECT  RowID               = T.tmp.value('@RowID',             'BIGINT'),
                    wHotelRID           = T.tmp.value('@wHotelRID',         'BIGINT'),
                    wCode               = T.tmp.value('@wCode',             'VARCHAR(30)'),
                    wCName              = T.tmp.value('@wCName',            'NVARCHAR(100)'),
                    wEName              = T.tmp.value('@wEName',            'NVARCHAR(100)'),
                    wJName              = T.tmp.value('@wJName',            'NVARCHAR(100)'),
                    wTName              = T.tmp.value('@wTName',            'NVARCHAR(100)'),
                    wKName              = T.tmp.value('@wKName',            'NVARCHAR(100)'),
                    wRoomQtyOfPerID     = T.tmp.value('@wRoomQtyOfPerID',   'INT'),
                    wMaxPeopleQty       = T.tmp.value('@wMaxPeopleQty',     'INT'),
                    wBedType_Code       = T.tmp.value('@wBedType_Code',     'VARCHAR(30)'),
                    wBedType_CName      = T.tmp.value('@wBedType_CName',    'NVARCHAR(50)'),
                    wBedType_EName      = T.tmp.value('@wBedType_EName',    'VARCHAR(50)'),
                    wBreakfastType      = T.tmp.value('@wBreakfastType',    'VARCHAR(30)'),
                    wCanExtBedType      = T.tmp.value('@wCanExtBedType',    'CHAR(1)'),
                    wRoomArea           = T.tmp.value('@wRoomArea',         'NUMERIC(18, 4)'),
                    wAllOpenDeposit     = T.tmp.value('@wAllOpenDeposit',   'NUMERIC(18, 4)'),
                    wAllLockDeposit     = T.tmp.value('@wAllLockDeposit',   'NUMERIC(18, 4)'),
                    wIsMinibarFree      = T.tmp.value('@wIsMinibarFree',    'CHAR(1)'),
                    wIsMinibarLock      = T.tmp.value('@wIsMinibarLock',    'CHAR(1)'),
                    wIsSmoking          = T.tmp.value('@wIsSmoking',        'CHAR(1)'),
                    wIsNoSmoking        = T.tmp.value('@wIsNoSmoking',      'CHAR(1)'),
                    wCRoomIntroduction  = T.tmp.value('@wCRoomIntroduction','NVARCHAR(1000)'),
                    wERoomIntroduction  = T.tmp.value('@wERoomIntroduction','VARCHAR(1000)'),
                    wCRoomDescription   = T.tmp.value('@wCRoomDescription', 'NVARCHAR(1000)'),
                    wERoomDescription   = T.tmp.value('@wERoomDescription', 'VARCHAR(1000)'),
                    wCRoomCondition     = T.tmp.value('@wCRoomCondition',   'NVARCHAR(1000)'),
                    wERoomCondition     = T.tmp.value('@wERoomCondition',   'NVARCHAR(1000)')
            INTO #vRoom_DataSet
            FROM @pXML.nodes('DataSet/Record') T(tmp);

            SET @sPostData = CONCAT(
                '{',
                    '"token":""',
                    ',"timestamp":"', FORMAT(DATEADD(HOUR, DATEDIFF(HOUR, GETDATE(), GETUTCDATE()), @sNow), 'yyyy-MM-dd HH:mm:ss.fffffff'), '"', -- utc
                    ',"type":"room"',
                    ',"hotel":null',
                    ',"room":[',
                        STUFF((SELECT CONCAT(',', 
                                    '{',
                                        '"roomRid":', CONVERT(VARCHAR, RowID),
                                        ',"hotelRid":', CONVERT(VARCHAR, wHotelRID),
                                        ',"roomCode":"', wCode,'"',
                                        ',"roomType_tw":"', wCName, '"',
                                        ',"roomType_en":"', wEName, '"',
                                        ',"roomType_jp":"', wJName, '"',
                                        ',"roomType_th":"', wTName, '"',
                                        ',"roomType_kr":"', wKName, '"',
                                        ',"noOfRoomPerId":', CONVERT(VARCHAR, ISNULL(wRoomQtyOfPerID, 0)),
                                        ',"personLimit":', CONVERT(VARCHAR, ISNULL(wMaxPeopleQty, 0)),
                                        ',"bedType":{',
                                            '"code":"', wBedType_Code , '"',
                                            ',"en":"', wBedType_EName, '"',
                                            ',"zh_tw":"', wBedType_EName, '"',
                                        '}',
                                        ',"breakfast":"', IIF(wBreakfastType = 'INCLUDE', 'Y', 'N'), '"',
                                        ',"bedAddOn":"', IIF(wCanExtBedType = 'Y', 'Y', 'N'), '"',
                                        
                                        ',"roomSize":', CONVERT(VARCHAR, ISNULL(wRoomArea, 0)),
                                        ',"allOpenDeposit":', CONVERT(VARCHAR, ISNULL(wAllOpenDeposit, 0)),
                                        ',"allLockDeposit":', CONVERT(VARCHAR, ISNULL(wAllLockDeposit, 0)),
                                        ',"isFreeMinibar":"', IIF(wIsMinibarFree = 'Y', 'Y', 'N'), '"',
                                        ',"isLockMinibar":"', IIF(wIsMinibarLock = 'Y', 'Y', 'N'), '"',
                                        ',"isSmoke":"', IIF(wIsSmoking = 'Y', 'Y', 'N'), '"',
                                        ',"isNotSmoke":"', IIF(wIsNoSmoking = 'Y', 'Y', 'N'), '"',
                                        ',"roomShortDescription":{',
                                            '"en":"', wERoomIntroduction, '"',
                                            ',"zh_tw":"', wCRoomIntroduction, '"',
                                        '}',
                                        ',"roomDescription":{',
                                            '"en":"', wERoomDescription, '"',
                                            ',"zh_tw":"', wCRoomDescription, '"',
                                        '}',
                                        ',"tnc":{',
                                            '"en":"', wERoomCondition, '"',
                                            ',"zh_tw":"', wCRoomCondition, '"',
                                        '}',
                                    '}') 
                               FROM #vRoom_DataSet
                               WHERE RowID > 0
                               FOR XML PATH('')
                             ), 1, 1, N''),
                    ']',
                    ',"roomPrice":null',
                '}'
            );

            IF OBJECT_ID('tempdb..#vRoom_DataSet') IS NOT NULL
                DROP TABLE #vRoom_DataSet;
        END

        -- Price
        IF @pType = 'Price'
        BEGIN
            SELECT  RowID           = T.tmp.value('@RowID',         'BIGINT'),
                    wRoomRid        = T.tmp.value('@wRoomRid',      'BIGINT'),
                    wType           = T.tmp.value('@wType',         'VARCHAR(10)'),
                    wStartDate      = T.tmp.value('@wStartDate',    'VARCHAR(10)'),
                    wEndDate        = T.tmp.value('@wEndDate',      'VARCHAR(10)'),
                    wCurrCode       = T.tmp.value('@wCurrCode',     'VARCHAR(10)'),
                    wMonRoomPrice   = T.tmp.value('@wMonRoomPrice', 'NUMERIC(18, 4)'),
                    wTueRoomPrice   = T.tmp.value('@wTueRoomPrice', 'NUMERIC(18, 4)'),
                    wWedRoomPrice   = T.tmp.value('@wWedRoomPrice', 'NUMERIC(18, 4)'),
                    wThuRoomPrice   = T.tmp.value('@wThuRoomPrice', 'NUMERIC(18, 4)'),
                    wFriRoomPrice   = T.tmp.value('@wFriRoomPrice', 'NUMERIC(18, 4)'),
                    wSatRoomPrice   = T.tmp.value('@wSatRoomPrice', 'NUMERIC(18, 4)'),
                    wSunRoomPrice   = T.tmp.value('@wSunRoomPrice', 'NUMERIC(18, 4)')
            INTO #vPrice_DataSet
            FROM @pXML.nodes('DataSet/Record') T(tmp);

            SET @sPostData = CONCAT(
                '{',
                    '"token":""',
                    ',"timestamp":"', FORMAT(DATEADD(HOUR, DATEDIFF(HOUR, GETDATE(), GETUTCDATE()), @sNow), 'yyyy-MM-dd HH:mm:ss.fffffff'), '"', -- utc
                    ',"type":"price"',
                    ',"hotel":null',
                    ',"room":null',
                    ',"roomPrice":[',
                        STUFF((SELECT CONCAT(',',
                                    '{', 
                                        '"roomPriceRid":', CONVERT(VARCHAR, RowID),
                                        ',"roomRid":', CONVERT(VARCHAR, wRoomRid),
                                        ',"type":"', wType, '"',
                                        ',"dateFrom":"', wStartDate, '"',
                                        ',"dateTo":"', wEndDate, '"',
                                        ',"currency":"', wCurrCode, '"',
                                        ',"monday":', CONVERT(VARCHAR, ISNULL(wMonRoomPrice, 0)),
                                        ',"tuesday":', CONVERT(VARCHAR, ISNULL(wTueRoomPrice, 0)),
                                        ',"wednesday":', CONVERT(VARCHAR, ISNULL(wWedRoomPrice, 0)),
                                        ',"thursday":', CONVERT(VARCHAR, ISNULL(wThuRoomPrice, 0)),
                                        ',"friday":', CONVERT(VARCHAR, ISNULL(wFriRoomPrice, 0)),
                                        ',"saturday":', CONVERT(VARCHAR, ISNULL(wSatRoomPrice, 0)),
                                        ',"sunday":', CONVERT(VARCHAR, ISNULL(wSunRoomPrice, 0)),
                                    '}')
                                FROM #vPrice_DataSet
                                WHERE wRoomRid > 0
                                FOR XML PATH('')
                             ), 1, 1, N''),
                    ']',
                '}'
            );

            IF OBJECT_ID('tempdb..#vPrice_DataSet') IS NOT NULL
                DROP TABLE #vPrice_DataSet;
        END

        IF ISNULL(@sPostData, '') <> '' AND ISNULL(@sURL, '') <> ''
        BEGIN
            BEGIN TRY
                EXEC RollsMary.spa.WriteApiLog  @pCompNo = @sMainCompNo, 
                                                @pApiName = @sApiName, 
                                                @pQueryStr = @sURL, 
                                                @pPostData = @sPostData, 
                                                @pTranType = 'O', 
                                                @pSrc = 'MARY', 
                                                @pResponse = N'', 
                                                @pFailCnt = 0, 
                                                @pReferRID = 0, 
                                                @pStatus = 'O', 
                                                @pActionDt = NULL, 
                                                @pType = 'SYNC', 
                                                @pRtnCode = @sAPILogCode OUTPUT, 
                                                @pErrMsg = @sAPILogErrMsg OUTPUT;
            END TRY
            BEGIN CATCH
                
            END CATCH
        END
    END