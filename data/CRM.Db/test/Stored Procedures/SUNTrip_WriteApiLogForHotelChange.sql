CREATE PROC [test].[SUNTrip_WriteApiLogForHotelChange]
    @pXML        XML,
    @pMainCompNo INT
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @vHotelChange TABLE (RowID BIGINT, wOldHotelChangeStatus VARCHAR(5));

        IF @pXML IS NOT NULL
        BEGIN
            INSERT INTO @vHotelChange(RowID, wOldHotelChangeStatus)
            SELECT DISTINCT tmp.RowID, tmp.wOldHotelChangeStatus FROM (
                SELECT RowID                 = T.tmp.value('@RowID',    'BIGINT'),
                       wOldHotelChangeStatus = T.tmp.value('@wOldHotelChangeStatus', 'VARCHAR(5)')
                FROM @pXML.nodes('DataSet/Record') T(tmp)
            ) tmp WHERE tmp.RowID > 0;
        END

        DECLARE @vSunTrip_SetRoomBookingNewRequest_API_URL          NVARCHAR(1000),
                @vSunTrip_SetRoomBookingRequestFinalStatus_API_URL  NVARCHAR(1000);

        SET @vSunTrip_SetRoomBookingNewRequest_API_URL = (SELECT wValue FROM RollsMary.dbo.mSysTable WHERE wItemCode = 'NEWHOTELCHANGE_SUNTRIP_URL');
        SET @vSunTrip_SetRoomBookingRequestFinalStatus_API_URL = (SELECT wValue FROM RollsMary.dbo.mSysTable WHERE wItemCode = 'SETHOTELCHANGE_SUNTRIP_URL');

        -- 更改入住日期狀態
        DECLARE @vHotalChangeStatus TABLE(wCode NVARCHAR(50) PRIMARY KEY, wCName NVARCHAR(100), wEName NVARCHAR(100));
        INSERT INTO @vHotalChangeStatus(wCode, wCName, wEName)
        SELECT cn.wCode, wCName = cn.wTitle, wEName = en.wTitle 
        FROM dbo.mLookUp cn
        INNER JOIN dbo.mLookUp en ON en.wType = cn.wType AND en.wCode = cn.wCode
        WHERE cn.wStatus = 'A'
            AND en.wStatus = 'A'
            AND cn.wLangCd = 'zh-TW' 
            AND en.wLangCd = 'en-GB' 
            AND cn.wType = 'HOTEL_CHANGE_STATUS';

        -- 更改入住記錄類型
        DECLARE @vHotelBookingAction TABLE(wCode NVARCHAR(50) PRIMARY KEY, wCName NVARCHAR(100), wEName NVARCHAR(100));
        INSERT INTO @vHotelBookingAction(wCode, wCName, wEName)
        SELECT cn.wCode, wCName = cn.wTitle, wEName = en.wTitle 
        FROM dbo.mLookUp cn
        INNER JOIN dbo.mLookUp en ON en.wType = cn.wType AND en.wCode = cn.wCode
        WHERE cn.wStatus = 'A'
            AND en.wStatus = 'A'
            AND cn.wLangCd = 'zh-TW' 
            AND en.wLangCd = 'en-GB' 
            AND cn.wType = 'HOTEL_BOOKING_ACTION';

        DECLARE @vResult TABLE (
            RowNum                  INT,
            wBookingHotelRid        BIGINT,
            wBookingRoomRid         BIGINT,
            wHotelChangeRid         BIGINT,
            wHotelChangeNo          BIGINT,
            wSunTripNo              VARCHAR(30),
            wAction                 VARCHAR(5),
            wCurrCode               VARCHAR(5),
            wAmountChange           NUMERIC(18, 4),
            wCheckInDateChange      DATE,
            wCheckOutDateChange     DATE,
            wHotelChangeStatus      VARCHAR(50),
            wHotelChangeStatusCName NVARCHAR(100),
            wHotelChangeStatusEName NVARCHAR(100),
            wRemark                 NVARCHAR(MAX),
            wAPIName                NVARCHAR(1000),
            wAPIURL                 NVARCHAR(1000)
        );

        INSERT INTO @vResult
        SELECT RowNum = ROW_NUMBER() OVER (ORDER BY A.wHotelChangeRid),
               A.*,
               B.*,
               C.*
        FROM (
            SELECT wBookingHotelRid = bh.RowID,
                   wBookingRoomRid = br.RowID,
                   wHotelChangeRid = hc.RowID,
                   hc.wHotelChangeNo,
                   bh.wSunTripNo,
                   hc.wAction,
                   hc.wCurrCode,
                   hc.wAmountChange,
                   wCheckInDateChange =  CASE hc.wAction WHEN 'C'   THEN hc.wNewStartDate
                                                         WHEN 'RF'  THEN hc.wOriStartDate
                                                         WHEN 'EX'  THEN hc.wOriEndDate
                                                         WHEN 'ECI' THEN hc.wNewStartDate
                                                         WHEN 'LC'  THEN hc.wOriStartDate
                                                         WHEN 'ECO' THEN hc.wNewEndDate
                                                         ELSE hc.wNewStartDate
                                         END ,		--入住日期變動
                   wCheckOutDateChange = CASE hc.wAction WHEN 'C'   THEN hc.wNewEndDate
                                                         WHEN 'RF'  THEN hc.wOriEndDate
                                                         WHEN 'EX'  THEN hc.wNewEndDate
                                                         WHEN 'ECI' THEN hc.wOriStartDate
                                                         WHEN 'LC'  THEN hc.wNewStartDate
                                                         WHEN 'ECO' THEN hc.wOriEndDate
                                                         ELSE hc.wNewEndDate
                                         END ,		--退房日期變動,
                   wHotelChangeStatus = hcs.wCode,
                   wHotelChangeStatusCName = hcs.wCName,
                   wHotelChangeStatusEName = hcs.wEName
            FROM dbo.eHotelChange hc
            INNER JOIN dbo.eBookingRoom br ON br.RowID = hc.wRoomBookingRid
            INNER JOIN dbo.eBookingHotel bh ON bh.RowID = br.wHotelBookingRid
            INNER JOIN @vHotalChangeStatus hcs ON hcs.wCode = hc.wHotelChangeStatus
            INNER JOIN @vHotelChange vhc ON vhc.RowID = hc.RowID
            WHERE bh.wSource = 'SunTrip'
                AND hc.wAction <> 'C'
                AND hc.wHotelChangeStatus <> ISNULL(vhc.wOldHotelChangeStatus, '')
        ) A
        OUTER APPLY (
            SELECT wRemark = CONCAT('[', hba.wCName, ']', CHAR(10),
                             N'預訂編號：', eb.wRefNo, CHAR(10),
                             N'酒店名稱：', h.wName, CHAR(10), 
                             N'間數：', N'1間', CAST(DATEDIFF(DAY, A.wCheckInDateChange, A.wCheckOutDateChange) AS VARCHAR), N'晚', CHAR(10),
                             N'入住日期：', FORMAT(A.wCheckInDateChange, 'yyyy-MM-dd'), ' ', N'退房日期：', FORMAT(A.wCheckOutDateChange, 'yyyy-MM-dd'))
            FROM dbo.eBookingRoom br
            INNER JOIN dbo.eBooking eb ON eb.RowID = br.wBookingRid
            INNER JOIN dbo.mHotel h ON h.RowID = br.wHotelRid
            INNER JOIN @vHotelBookingAction hba ON hba.wCode = A.wAction
            WHERE br.RowID = A.wBookingRoomRid
        ) B
        OUTER APPLY (
            SELECT  wAPIName = IIF(A.wHotelChangeStatus = 'P', 'CRM_Api_SunTrip_SetRoomBookingNewRequest', 'CRM_Api_SunTrip_SetRoomBookingRequestFinalStatus'),
                    wAPIURL = IIF(A.wHotelChangeStatus = 'P', @vSunTrip_SetRoomBookingNewRequest_API_URL, @vSunTrip_SetRoomBookingRequestFinalStatus_API_URL)
        ) C;

        -- Write Api Log
        DECLARE @sRuningIndex   INT,
                @sRecCount      INT;

        DECLARE @sAPILogRtnCode INT,
                @sAPILogErrMsg  NVARCHAR(2000);

        DECLARE @sApiName       NVARCHAR(100),
                @sURL           NVARCHAR(1000),
                @sPostData      NVARCHAR(MAX);

        SET @sRuningIndex = 1;
        SET @sRecCount = (SELECT COUNT(1) FROM @vResult);

        WHILE @sRuningIndex <= @sRecCount
        BEGIN
            SELECT @sApiName  = wAPIName,
                   @sURL      = wAPIURL,
                   @sPostData = IIF(wHotelChangeStatus = 'P', 
                                    CONCAT('{', 
                                                '"requestRid":', CONVERT(VARCHAR, wHotelChangeNo), 
                                                '"sunTripNo":', '"', wSunTripNo, '"',
                                                '"remark":', '"', wRemark, '"',
                                                '"currency":', '"', wCurrCode, '"',
                                                '"amount":', CONVERT(VARCHAR, wAmountChange),
                                                '"status":', '"', wHotelChangeStatus, '"',
                                                '"statusName":', '"', wHotelChangeStatusCName, '"',
                                           '}'
                                    ), 
                                    CONCAT('{',
                                                '"requestRid":', CONVERT(VARCHAR, wHotelChangeNo), 
                                                '"finalStatus":', '"', wHotelChangeStatus, '"',
                                                '"finalStatusName":', '"', wHotelChangeStatusCName, '"',
                                           '}'
                                    )
                                )
            FROM @vResult WHERE RowNum = @sRuningIndex;
            
            EXEC RollsMary.spa.WriteApiLog @pCompNo     = @pMainCompNo,
                                           @pApiName    = @sApiName,
                                           @pQueryStr   = @sURL,
                                           @pPostData   = @sPostData,
                                           @pTranType   = 'O',
                                           @pSrc        = 'MARY',
                                           @pResponse   = N'',
                                           @pFailCnt    = 0,
                                           @pReferRID   = 0,
                                           @pStatus     = 'O',
                                           @pActionDt   = NULL,
                                           @pType       = 'SYNC',
                                           @pRtnCode    = @sAPILogRtnCode OUTPUT,
                                           @pErrMsg     = @sAPILogErrMsg OUTPUT;
            
            SET @sRuningIndex = @sRuningIndex + 1;
        END
    END