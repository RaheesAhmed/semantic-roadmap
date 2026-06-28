CREATE PROCEDURE [spa].[SetHotelRoom]
    @pXML XML ,
    @pActionType CHAR(1) , -- I/U/D
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pReturnResultSet CHAR(1) = 'N',
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;
		
        -- SELECT * FROM dbo.mHotelRoom;

        DECLARE @sThisTableName     VARCHAR(50) = 'mHotelRoom' , -- For RowID
                @sBeginTranCount    INT = 0 ,
                @sRecCount          INT = 0 ,
                @sRuningIndex       INT = 1 ,
                @sRowID             BIGINT = 0,
                @sNow               DATETIME2(7) = dbo.fnUTC8Now();
	        
        DECLARE @vOldXML XML,
                @vNewXML XML;

        DECLARE @sDataSet_SetHotelRoom TABLE (
            wRowNum             INT PRIMARY KEY IDENTITY(1, 1),
            RowID               BIGINT,
            wHotelRid           BIGINT,
            wCode               VARCHAR(30),
            wName               NVARCHAR(200),
            wEname              NVARCHAR(100),
            wJname              NVARCHAR(100),
            wThname             NVARCHAR(100),
            wKname              NVARCHAR(100),
            wRemarks            NVARCHAR(500),
            wSeqNo              INT,
            wMaxPeopleQty       INT, -- 入住人數上限
            wCanExtBedType      CHAR(1), -- 可否加床位
            wBreakfastType      VARCHAR(30), -- 早餐方式
            wBedType            VARCHAR(30), -- 床類
            wCRoomIntroduction  NVARCHAR(1000), -- 房間簡述(中)
            wERoomIntroduction  NVARCHAR(1000), -- 房間簡述(英)
            wCRoomDescription   NVARCHAR(1000), -- 房間描述(中)
            wERoomDescription   NVARCHAR(1000), -- 房間描述(英)
            wCRoomCondition     NVARCHAR(1000),-- 房間使用條款(中)
            wERoomCondition     NVARCHAR(1000), -- 房間使用條款(英)
            wIsSunTrip          CHAR(1), -- SunTrip使用
            wRoomQtyOfPerID     INT, -- 每個證件可訂房數
            wRoomArea           NUMERIC(18, 4), -- 房間面積
            wAllOpenDeposit     NUMERIC(18, 4), -- All Open押金
            wAllLockDeposit     NUMERIC(18, 4), -- All Lock押金
            wIsMinibarFree      CHAR(1), -- 免費Mini Bar
            wIsMinibarLock      CHAR(1), -- 上鎖Mini Bar
            wIsSmoking          CHAR(1), -- 吸菸房
            wIsNoSmoking        CHAR(1), -- 非吸菸房
            wStatus             CHAR(1),
            wCrtDt              DATETIME2(7),
            wCrtBy              BIGINT,
            wUpdDt              DATETIME2(7),
            wUpdBy              BIGINT
        );

        INSERT INTO @sDataSet_SetHotelRoom
        SELECT  RowID               = T.tmp.value('@RowID',              'BIGINT'),
                wHotelRid           = T.tmp.value('@wHotelRid',          'BIGINT'),
                wCode               = T.tmp.value('@wCode',              'VARCHAR(30)'),
                wName               = T.tmp.value('@wName',              'NVARCHAR(200)'),
                wEname              = T.tmp.value('@wEname',             'NVARCHAR(100)'),
                wJname              = T.tmp.value('@wJname',             'NVARCHAR(100)'),
                wThname             = T.tmp.value('@wThname',            'NVARCHAR(100)'),
                wKname              = T.tmp.value('@wKname',             'NVARCHAR(100)'),
                wRemarks            = T.tmp.value('@wRemarks',           'NVARCHAR(500)'),
                wSeqNo              = T.tmp.value('@wSeqNo',             'INT'),
                wMaxPeopleQty       = T.tmp.value('@wMaxPeopleQty',      'INT'), -- 入住人數上限
                wCanExtBedType      = T.tmp.value('@wCanExtBedType',     'CHAR(1)'), -- 可否加床位
                wBreakfastType      = T.tmp.value('@wBreakfastType',     'VARCHAR(30)'), -- 早餐方式
                wBedType            = T.tmp.value('@wBedType' ,          'VARCHAR(30)'), -- 床類
                wCRoomIntroduction  = T.tmp.value('@wCRoomIntroduction', 'NVARCHAR(1000)'), -- 房間簡述(中)
                wERoomIntroduction  = T.tmp.value('@wERoomIntroduction', 'NVARCHAR(1000)'), -- 房間簡述(英)
                wCRoomDescription   = T.tmp.value('@wCRoomDescription',  'NVARCHAR(1000)'), -- 房間描述(中)
                wERoomDescription   = T.tmp.value('@wERoomDescription',  'NVARCHAR(1000)'), -- 房間描述(英)
                wCRoomCondition     = T.tmp.value('@wCRoomCondition',    'NVARCHAR(1000)'),-- 房間使用條款(中)
                wERoomCondition     = T.tmp.value('@wERoomCondition',    'NVARCHAR(1000)'), -- 房間使用條款(英)
                wIsSunTrip          = T.tmp.value('@wIsSunTrip',         'CHAR(1)'), -- SunTrip使用
                wRoomQtyOfPerID     = T.tmp.value('@wRoomQtyOfPerID',    'INT'), -- 每個證件可訂房數
                wRoomArea           = T.tmp.value('@wRoomArea',          'NUMERIC(18, 4)'), -- 房間面積
                wAllOpenDeposit     = T.tmp.value('@wAllOpenDeposit',    'NUMERIC(18, 4)'), -- All Open押金
                wAllLockDeposit     = T.tmp.value('@wAllLockDeposit',    'NUMERIC(18, 4)'), -- All Lock押金
                wIsMinibarFree      = T.tmp.value('@wIsMinibarFree',     'CHAR(1)'), -- 免費Mini Bar
                wIsMinibarLock      = T.tmp.value('@wIsMinibarLock',     'CHAR(1)'), -- 上鎖Mini Bar
                wIsSmoking          = T.tmp.value('@wIsSmoking',         'CHAR(1)'), -- 吸菸房
                wIsNoSmoking        = T.tmp.value('@wIsNoSmoking',       'CHAR(1)'), -- 非吸菸房
                wStatus             = T.tmp.value('@wStatus',            'CHAR(1)'),
                wCrtDt              = T.tmp.value('@wCrtDt',             'DATETIME2(7)'),
                wCrtBy              = T.tmp.value('@wCrtBy',             'BIGINT'),
                wUpdDt              = T.tmp.value('@wUpdDt',             'DATETIME2(7)'),
                wUpdBy              = T.tmp.value('@wUpdBy',             'BIGINT')
        FROM @pXML.nodes('DataSet/Record') T(tmp);
	    
        SET @vOldXML = (
            SELECT hr.*
            FROM dbo.mHotelRoom hr WITH(NOLOCK)
            INNER JOIN @sDataSet_SetHotelRoom tmp ON tmp.RowID = hr.RowID
            FOR XML RAW('Record'), ROOT('DataSet')
        );

        SET @pErrCode = 0;
        SET @pErrMsg = '';
        SET @sBeginTranCount = @@trancount;

        BEGIN TRY
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;
	        
            IF @pActionType = 'I'
            BEGIN
                SET @sRuningIndex = 1;
                SET @sRecCount = (SELECT COUNT(1) FROM @sDataSet_SetHotelRoom);

                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
                        
                    UPDATE @sDataSet_SetHotelRoom SET RowID = @sRowID WHERE wRowNum = @sRuningIndex;
                        
                    SET @sRuningIndex = @sRuningIndex + 1;
                END;

                INSERT INTO dbo.mHotelRoom (
                    RowID,
                    wHotelRid,
                    wCode,
                    wName,
                    wEname,
                    wJname,
                    wThname,
                    wKname,
                    wRemarks,
                    wSeqNo,
                    wMaxPeopleQty,
                    wCanExtBedType,
                    wBreakfastType,
                    wBedType,
                    wCRoomIntroduction,
                    wERoomIntroduction,
                    wCRoomDescription,
                    wERoomDescription,
                    wCRoomCondition,
                    wERoomCondition,
                    wIsSunTrip,
                    wRoomQtyOfPerID,
                    wRoomArea,
                    wAllOpenDeposit,
                    wAllLockDeposit,
                    wIsMinibarFree,
                    wIsMinibarLock,
                    wIsSmoking,
                    wIsNoSmoking,
                    wStatus,
                    wCrtDt,
                    wCrtBy,
                    wUpdDt,
                    wUpdBy
				)
                SELECT  RowID,
                        wHotelRid,
                        wCode,
                        wName,
                        wEname,
                        wJname,
                        wThname,
                        wKname,
                        wRemarks,
                        wSeqNo,
                        wMaxPeopleQty,
                        wCanExtBedType,
                        wBreakfastType,
                        wBedType,
                        wCRoomIntroduction,
                        wERoomIntroduction,
                        wCRoomDescription,
                        wERoomDescription,
                        wCRoomCondition,
                        wERoomCondition,
                        wIsSunTrip,
                        wRoomQtyOfPerID,
                        wRoomArea,
                        wAllOpenDeposit,
                        wAllLockDeposit,
                        wIsMinibarFree,
                        wIsMinibarLock,
                        wIsSmoking,
                        wIsNoSmoking,
                        wStatus,
                        wCrtDt = @sNow,
                        wCrtBy = wUpdBy,
                        wUpdDt = @sNow,
                        wUpdBy = wUpdBy
                FROM @sDataSet_SetHotelRoom;
            END;
            
            IF @pActionType = 'U'
            BEGIN
                IF EXISTS (SELECT 1 FROM @sDataSet_SetHotelRoom tmp INNER JOIN CRM.dbo.eBookingRoom br WITH(NOLOCK) ON br.wHotelRoomRid = tmp.RowID WHERE tmp.wStatus='T')
                BEGIN
                    SET @pErrMsg = N'该房間類型已被使用,不能删除或终止';	
                END;
                ELSE
                BEGIN
                    UPDATE hr
                    SET wHotelRid           = tmp.wHotelRid ,
                        wCode               = tmp.wCode ,
                        wName               = tmp.wName ,	
                        wEname              = tmp.wEname ,
                        wJname              = tmp.wJname ,
                        wThname             = tmp.wThname ,
                        wKname              = tmp.wKname ,
                        wRemarks            = tmp.wRemarks ,
                        wSeqNo              = tmp.wSeqNo ,
                        wMaxPeopleQty       = tmp.wMaxPeopleQty,
                        wCanExtBedType      = tmp.wCanExtBedType,
                        wBreakfastType      = tmp.wBreakfastType,
                        wBedType            = tmp.wBedType,
                        wCRoomIntroduction  = tmp.wCRoomIntroduction,
                        wERoomIntroduction  = tmp.wERoomIntroduction,
                        wCRoomDescription   = tmp.wCRoomDescription,
                        wERoomDescription   = tmp.wERoomDescription,
                        wCRoomCondition     = tmp.wCRoomCondition,
                        wERoomCondition     = tmp.wERoomCondition,
                        wIsSunTrip          = tmp.wIsSunTrip,
                        wRoomQtyOfPerID     = tmp.wRoomQtyOfPerID,
                        wRoomArea           = tmp.wRoomArea,
                        wAllOpenDeposit     = tmp.wAllOpenDeposit,
                        wAllLockDeposit     = tmp.wAllLockDeposit,
                        wIsMinibarFree      = tmp.wIsMinibarFree,
                        wIsMinibarLock      = tmp.wIsMinibarLock,
                        wIsSmoking          = tmp.wIsSmoking,
                        wIsNoSmoking        = tmp.wIsNoSmoking,
                        wStatus             = tmp.wStatus,
                        wUpdDt              = @sNow,
                        wUpdBy              = tmp.wUpdBy
                    FROM dbo.mHotelRoom hr
                    INNER JOIN @sDataSet_SetHotelRoom tmp ON tmp.RowID = hr.RowID;
                END;
            END;
                
            IF @pActionType = 'D'
            BEGIN
                IF EXISTS (SELECT 1 FROM @sDataSet_SetHotelRoom tmp INNER JOIN CRM.dbo.eBookingRoom br WITH(NOLOCK) ON br.wHotelRoomRid = tmp.RowID )
                BEGIN
                    SET @pErrMsg = N'该房間類型已被使用,不能删除或终止';	
                END;
                ELSE
                BEGIN
                    UPDATE hr
                    SET wStatus = 'T',
                        wUpdBy = tmp.wUpdBy ,
                        wUpdDt = @sNow                           
                    FROM dbo.mHotelRoom hr
                    INNER JOIN @sDataSet_SetHotelRoom tmp ON tmp.RowID = hr.RowID;
                END;		
            END;

            -- 如果數據有修改，Sync到SUNTrip
            ------------------------------------------------------------------------------------------------------
            SET @vNewXML = (SELECT *, RecordState = @pActionType FROM @sDataSet_SetHotelRoom FOR XML RAW('Record'), ROOT('DataSet'));
            
            EXEC spa.SUNTrip_SetHotelRoomChange @pOldXML = @vOldXML,
                                                @pNewXML = @vNewXML;
            ------------------------------------------------------------------------------------------------------

            IF @sBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                COMMIT;
            END;

            IF @pReturnResultSet = 'Y'
                SELECT  RowID FROM @sDataSet_SetHotelRoom;
        END TRY
        BEGIN CATCH
            DECLARE @sErrorNum INT ,
                    @sCatchErrorMessage NVARCHAR(4000) ,
                    @xstate INT ,
                    @sProcedureName VARCHAR(100) ,
                    @sRtnCodeLog INT ,
                    @sErrMessageLog NVARCHAR(4000);
	        
            SELECT  @sErrorNum = ERROR_NUMBER() ,
                    @sCatchErrorMessage = ERROR_MESSAGE() ,
                    @xstate = XACT_STATE() ,
                    @sProcedureName = OBJECT_NAME(@@PROCID);
			
            IF ISNULL(@pErrCode, 0) = 0
            BEGIN
                SET @pErrCode = 999;
            END;

            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ', @sCatchErrorMessage);
			
            -- transaction created within this sp
            IF @sBeginTranCount = 0 AND ( @xstate = 1 OR @xstate = -1 )
            BEGIN
                ROLLBACK;
            END;
	        
	        -- Write Log
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH;
    END;