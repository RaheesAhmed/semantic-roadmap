CREATE PROC [test].[SUNTrip_GetHotelChange]
    -- @pBookingHotelRid   BIGINT,
    @pHotelChangeRid    BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

        -- SET @pBookingHotelRid = IIF(@pBookingHotelRid <= 0, NULL, @pBookingHotelRid);
        SET @pHotelChangeRid = IIF(@pHotelChangeRid <= 0, NULL, @pHotelChangeRid);

        DECLARE @vSunTrip_SetRoomBookingNewRequest_API_URL          NVARCHAR(1000),
                @vSunTrip_SetRoomBookingRequestFinalStatus_API_URL  NVARCHAR(1000);

        SET @vSunTrip_SetRoomBookingNewRequest_API_URL = (SELECT wValue FROM dbo.mSysTable WHERE wCode = 'SunTrip_SetRoomBookingNewRequest_API_URL');
        SET @vSunTrip_SetRoomBookingRequestFinalStatus_API_URL = (SELECT wValue FROM dbo.mSysTable WHERE wCode = 'SunTrip_SetRoomBookingRequestFinalStatus_API_URL');

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

        SELECT wBookingHotelRid = bh.RowID,
               wBookingRoomRid = br.RowID,
               wHotelChangeRid = hc.RowID,
               hc.wAction,
               hc.wHotelChangeNo,
               bh.wSunTripNo,
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
               wHotelChangeStatusEName = hcs.wEName,
               wRemark = CAST(NULL AS NVARCHAR(MAX)),
               wAPIURL = IIF(hc.wHotelChangeStatus = 'P', @vSunTrip_SetRoomBookingNewRequest_API_URL, @vSunTrip_SetRoomBookingRequestFinalStatus_API_URL)
        INTO #vResult
        FROM dbo.eHotelChange hc
        INNER JOIN dbo.eBookingRoom br ON br.RowID = hc.wRoomBookingRid
        INNER JOIN dbo.eBookingHotel bh ON bh.RowID = br.wHotelBookingRid
        INNER JOIN @vHotalChangeStatus hcs ON hcs.wCode = hc.wHotelChangeStatus
        WHERE bh.wSource = 'SunTrip'
            AND hc.wAction <> 'C'
            --AND (@pBookingHotelRid > 0 OR @pHotelChangeRid > 0)
            --AND (@pBookingHotelRid IS NULL OR bh.RowID = @pBookingHotelRid)
            --AND (@pHotelChangeRid IS NULL OR hc.RowID = @pHotelChangeRid);
            AND hc.RowID = @pHotelChangeRid;

        UPDATE r
        SET wRemark = CONCAT('[', hba.wCName, ']', CHAR(10),
                             N'預訂編號：', eb.wRefNo, CHAR(10),
                             N'酒店名稱：', h.wName, CHAR(10), 
                             N'間數：', N'1間', CAST(DATEDIFF(DAY, r.wCheckInDateChange, r.wCheckOutDateChange) AS VARCHAR), N'晚', CHAR(10),
                             N'入住日期：', FORMAT(r.wCheckInDateChange, 'yyyy-MM-dd'), ' ', N'退房日期：', FORMAT(r.wCheckOutDateChange, 'yyyy-MM-dd'))
        FROM #vResult r
        INNER JOIN dbo.eBookingRoom br ON br.RowID = r.wBookingRoomRid
        INNER JOIN dbo.eBooking eb ON eb.RowID = br.wBookingRid
        INNER JOIN dbo.mHotel h ON h.RowID = br.wHotelRid
        INNER JOIN @vHotelBookingAction hba ON hba.wCode = r.wAction

        SELECT * FROM #vResult;

        IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
            DROP TABLE #vResult;
    END;