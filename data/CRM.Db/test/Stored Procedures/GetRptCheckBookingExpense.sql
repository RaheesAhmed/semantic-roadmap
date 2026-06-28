CREATE PROCEDURE [test].[GetRptCheckBookingExpense]
      @pAgentCodeIn VARCHAR(14),
      @pDebitCounter NVARCHAR(MAX),
      @pBookingType NVARCHAR(MAX),
      @pFromDt DATETIME2(7),
      @pToDt DATETIME2(7),
      @pLangCd VARCHAR(10) = 'zh-TW',
      @pErrMsg NVARCHAR(200) = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF @@trancount = 0
        SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

    -- 空字符串转换为NULL
    -- 空字符串判断（@pAgentCodeIn IS NULL）影响性能
    -- 推荐用@pAgentCodeIn IS NULL
    SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
    SET @pDebitCounter = NULLIF(@pDebitCounter, '');
    SET @pBookingType = NULLIF(@pBookingType, '');
    SET @pLangCd = ISNULL(@pLangCd, 'zh-TW');
    SET @pFromDt = FORMAT(@pFromDt, 'yyyy-MM-dd 00:00:00');
    SET @pToDt = FORMAT(@pToDt, 'yyyy-MM-dd 23:59:59');

    DECLARE @sDateFormat VARCHAR(10) = 'yyyy-MM-dd';
    DECLARE @sDateTimeFormat VARCHAR(20) = 'yyyy-MM-dd HH:mm:00';
    DECLARE @sShortDateTimeFormat VARCHAR(20) = 'yyyy-MM-dd HH:mm';
    -- 缺省时最小日期
    DECLARE @sStartDateTime DATETIME2(7) = '1990-01-01';

    -- 扣數櫃台
    DECLARE @tmpFilterCounter AS TABLE (
        wCounterRid	BIGINT
    );
    IF @pDebitCounter IS NOT NULL
    BEGIN
        INSERT INTO 
            @tmpFilterCounter (wCounterRid)
        SELECT
            CAST(item AS BIGINT)
        FROM dbo.fnSplit(@pDebitCounter, ',')
        WHERE NULLIF(item, '') IS NOT NULL
    END;

    -- 預訂類型
    DECLARE @tmpBookingType AS TABLE (
        wBookingType VARCHAR(30)
    );
    IF @pBookingType IS NOT NULL
    BEGIN
        INSERT INTO
            @tmpBookingType (wBookingType)
        SELECT 
            item
        FROM dbo.fnSplit(@pBookingType, ',')
        WHERE NULLIF(item, '') IS NOT NULL
    END;

    -- 預訂狀態
    DECLARE @tmpBookingStatus AS TABLE (
        wBookingStatus VARCHAR(20),
        wMapBookingStatus VARCHAR(20)
    );
    INSERT INTO 
        @tmpBookingStatus(wBookingStatus, wMapBookingStatus)
    VALUES 
        ('P',	'P'), -- 按金沒有跟狀態無關，預訂
        ('CL',	'CL'),
        ('UQ',	'UQ'),
        ('C',	'C'),  -- 完成狀態預期會產生一條射數記錄
        ('RF',	'C'),  -- 退款預期會產生兩條射數記錄（消費、退款）
        ('RF',	'RF');

    -- use temp table when report done
    -- Insert booking data to temp table with booking details one by one
    CREATE TABLE #tmpResult (
        RowId                   BIGINT PRIMARY KEY IDENTITY(1, 1),
        wBookingType            NVARCHAR(30),               -- 消費類型
        wDebitDt                DATETIME2(7),	            -- 扣數日期
        wCancelDebitDt          DATETIME2(7),               -- 取消扣數日期
        wCancelDt               DATETIME2(7),               -- 取消日期
        wRefNo                  VARCHAR(30) DEFAULT '',     -- 訂單編號
        wRelatedBookingRefNo    VARCHAR(30) DEFAULT '',     -- 相關訂務
        wDebitCounterRid        BIGINT DEFAULT 0,           -- 扣數場館
        wReqCounterRid          BIGINT DEFAULT 0,           -- 要求場館
        wDebitAgentCodeIn       VARCHAR(14),                -- 扣數戶口 code
        wReqAgentCodeIn         VARCHAR(14),                -- 要求戶口 code
        wTranvalAgencyName      NVARCHAR(100),              -- 供應商名稱
        wOrderNo                NVARCHAR(100),              -- 單號
        wPaymentMethod          VARCHAR(30),                -- 付款方式
        wReceiptNo              NVARCHAR(100),              -- 現金單號
        wDepositCost            NUMERIC(18, 4),             -- 按金
        wTotalCost              NUMERIC(18, 4),             -- 總成本
        wTotalAmount            NUMERIC(18, 4),             -- 總值
        wDateString             NVARCHAR(MAX),              -- 日期
        wQuantity               INT,                        -- 數量
        wRouteString            NVARCHAR(MAX),              -- 航線
        wTicketType             NVARCHAR(100),              -- 票類型
        wHotel                  NVARCHAR(500),              -- 酒店
        wDetail                 NVARCHAR(MAX),              -- 明細
        wCustomer               NVARCHAR(MAX),              -- 客人
        wBookingStatus          VARCHAR(30),                -- 訂單狀態
        wRemark                 NVARCHAR(MAX),              -- 備註
        wCancelReasonCd         VARCHAR(30),                -- 取消原因 code
        wOtherReason            NVARCHAR(200),              -- 其它取消原因			
        wAsstBooker             NVARCHAR(100),              -- 代訂人
        wAsstBookerTel          VARCHAR(100),               -- 代訂人電話
        wAssBookerEmail         NVARCHAR(100),              -- 代訂人電郵
        wDeptFollowedCd         VARCHAR(30),                -- 跟進部門
        wStaffFollowedRid       BIGINT,                     -- 跟進同事
        wApprovalAgentCodeIn    VARCHAR(14),                -- 確認戶主/授權人
        wEventCodeRid           BIGINT,                     -- 活動代碼
        wReqDepartment          VARCHAR(30),                -- 要求部門
        wReqUserRid             BIGINT,                     -- 要求同事
        wTravelPkgRid           BIGINT,                     -- 旅遊套票
        wUseBlackCard           NCHAR(1),                   -- 黑卡?
        wSameDebitDtCnt         VARCHAR(10),                -- 最終要顯示  '1/wSameDebitDtCnt'
        wExpCategory            NVARCHAR(200),              -- 消費類型 （其他消費的消費類型取Booking的消費類型及消費副類型）
        wCrtDt                  DATETIME2(7),               -- 創建日期
        -- using for joining eExpTran
        wBookingRid             BIGINT DEFAULT -1,
        wBookingDtlRid          BIGINT DEFAULT -1,          -- Passenger or room
        wHotelChangeRid         BIGINT DEFAULT -1           -- For hotel
    );

    -- 船票
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @tmpBookingType WHERE wBookingType = 'FERRY')
    BEGIN
        -- 船票航线
        SELECT 
            mr.RowID,
            wRouteTitle = CONCAT(luFrom.wTitle, CASE WHEN mr.wIsTwoWay = 'Y' THEN '<->' ELSE '->' END, luTo.wTitle)
        INTO #tFerryRoute
        FROM dbo.mRoute AS mr
        INNER JOIN dbo.mLookUp AS luFrom ON luFrom.wCode = mr.wRouteFrom AND luFrom.wLangCd = @pLangCd AND mr.wVehicle = 'FERRY' AND luFrom.wType = 'FERRY_ROUTE_LOCATION'
        INNER JOIN dbo.mLookUp AS luTo ON luTo.wCode = mr.wRouteTo AND luTo.wLangCd = @pLangCd AND mr.wVehicle = 'FERRY' AND luTo.wType = 'FERRY_ROUTE_LOCATION'

        -- 客户
        SELECT
            rpd.wBookingRid,
            wCustomer = STUFF(
                (SELECT CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN p.wEName ELSE p.wCName END, CASE WHEN NULLIF(ptd.wEnglishPinyin, '') IS NULL THEN NULL ELSE ' (' + ptd.wEnglishPinyin + ')' END)
                From dbo.ePassengerDetails AS spd
                INNER JOIN dbo.mPerson AS p ON p.RowID = spd.wPersonRid AND spd.wBookingRid = rpd.wBookingRid AND spd.wStatus = 'A'
                LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON spd.RowID = ptdd.wPassengerDetailsRid
                LEFT JOIN dbo.mPersonTravelDoc AS ptd ON ptdd.wPersonTravelDocRid = ptd.RowID
                WHERE ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = spd.RowID)
                FOR XML PATH('')), 1, 1, N'')
        INTO #tFerryPassenger
        FROM dbo.eBookingFerry AS ferry
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'FERRY' AND ferry.wStatus = 'A' AND eb.RowID = ferry.wBookingRid
        INNER JOIN dbo.ePassengerDetails AS rpd ON rpd.wBookingRid > 0 AND rpd.wStatus = 'A' AND rpd.wBookingRid = ferry.wBookingRid
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((ferry.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt))) --只有完成、退款狀態才有射數
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        GROUP BY rpd.wBookingRid

        INSERT INTO #tmpResult (
            wBookingType,
            wDebitDt,
            wCancelDebitDt,
            wCancelDt,
            wRefNo,
            wRelatedBookingRefNo,
            wDebitCounterRid,
            wReqCounterRid,
            wDebitAgentCodeIn,
            wReqAgentCodeIn,
            wTranvalAgencyName,
            wOrderNo,
            wPaymentMethod,
            wReceiptNo,
            wDepositCost,
            wTotalCost,
            wTotalAmount,
            wDateString,
            wQuantity,
            wRouteString,
            wTicketType,
            wHotel,
            wDetail,
            wCustomer,
            wBookingStatus,
            wRemark,
            wCancelReasonCd,
            wOtherReason,
            wAsstBooker,
            wAsstBookerTel,
            wAssBookerEmail,
            wDeptFollowedCd,
            wStaffFollowedRid,
            wApprovalAgentCodeIn,
            wEventCodeRid,
            wReqDepartment,
            wReqUserRid,
            wTravelPkgRid,
            wUseBlackCard,
            wSameDebitDtCnt,
            wExpCategory,
            wCrtDt,
            wBookingRid,
            wBookingDtlRid,
            wHotelChangeRid
        )
        SELECT 
            wBookingType = eb.wBookingType,
            wDebitDt = eb.wDebitDt,
            wCancelDebitDt = eb.wCancelDebitDt,
            wCancelDt = eb.wCancelDt,
            wRefNo = eb.wRefNo,
            wRelatedBookingRefNo = NULL, 
            wDebitCounterRid = eb.wDebitCounterRid, 
            wReqCounterRid = eb.wReqCounterRid, 
            wDebitAgentCodeIn = eb.wDebitAgentCodeIn, 
            wReqAgentCodeIn = eb.wReqAgentCodeIn, 
            wTranvalAgencyName = ta.wName, 
            wOrderNo = ferry.wOrderNo, 
            wPaymentMethod = ferry.wPaymentMethod, 
            wReceiptNo = ferry.wReceiptNo, 
            wDepositCost = eb.wDepositAmt,
            wTotalCost = ferry.wCost, 
            wTotalAmount = 0,
            wDateString = CASE WHEN ferry.wDepartDt IS NULL THEN NULL ELSE FORMAT(ferry.wDepartDt, @sDateTimeFormat) END,
            wQuantity = ferry.wQuantity,
            wRouteString = rout.wRouteTitle,
            wTicketType = tType.wTitle,
            wHotel = NULL,
            wDetail = CONCAT(N'艙等: ', fc.wTitle, CHAR(10), N'申請豁免: ', CASE WHEN ferry.wWaived = 'Y' THEN N'是' ELSE N'否' END),
            wCustomer = pd.wCustomer,
            wBookingStatus = ferry.wBookingStatus,
            wRemark = ferry.wRemark,
            wCancelReasonCd = eb.wCancelReasonCd,
            wOtherReason = eb.wOtherReason,
            wAsstBooker = eb.wAsstBooker,
            wAsstBookerTel = eb.wAssBookerTel,
            wAssBookerEmail = eb.wAsstBookerEmail,
            wDeptFollowedCd = eb.wDeptFollwedCd,
            wStaffFollowedRid = eb.wStaffFollwedRid,
            wApprovalAgentCodeIn = eb.wApprovalAgentCodeIn,
            wEventCodeRid = eb.wEventCodeRid,
            wReqDepartment = eb.wReqDepartment,
            wReqUserRid = eb.wReqUserRid,
            wTravelPkgRid = eb.wTravePkgRid,
            wUseBlackCard = ferry.wUseBlackCard,
            wSameDebitDtCnt = '1',
            wExpCategory = NULL,
            wCrtDt = ferry.wCrtDt,
            wBookingRid = eb.RowID,
            wBookingDtlRid = -1,
            wHotelChangeRid = -1
        FROM dbo.eBookingFerry AS ferry
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'FERRY' AND ferry.wStatus = 'A' AND eb.RowID = ferry.wBookingRid
        LEFT JOIN dbo.mLookUp AS fc ON wLangCd = @pLangCd AND wType = 'FERRY_CLASS' AND ferry.wClassCd = fc.wCode
        LEFT JOIN dbo.mLookUp AS tType ON tType.wLangCd = @pLangCd AND tType.wType = 'FERRY_TICKET_TYPE' AND tType.wCode = ferry.wTicketType
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.wIsShip= 'Y' AND ferry.wTravelAgencyRid = ta.RowID
        LEFT JOIN #tFerryRoute AS rout ON rout.RowID = ferry.wRouteRid
        LEFT JOIN #tFerryPassenger AS pd ON pd.wBookingRid = eb.RowID
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((ferry.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt))) --只有完成、退款狀態才有射數
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))

        IF OBJECT_ID('tempdb..#tFerryRoute') IS NOT NULL
            DROP TABLE #tFerryRoute;

        IF OBJECT_ID('tempdb..#tFerryPassenger') IS NOT NULL
            DROP TABLE #tFerryPassenger;
    END;

    -- 直升機 --
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @tmpBookingType WHERE wBookingType = 'HELI')
    BEGIN
        -- 直升機航线
        SELECT 
            mr.RowID,
            wRouteTitle = CONCAT(luFrom.wTitle, CASE WHEN mr.wIsTwoWay = 'Y' THEN '<->' ELSE '->' END, luTo.wTitle)
        INTO #tHeliRoute
        FROM dbo.mRoute AS mr
        INNER JOIN dbo.mLookUp AS luFrom ON luFrom.wCode = mr.wRouteFrom AND luFrom.wLangCd = @pLangCd AND mr.wVehicle = 'HELI' AND luFrom.wType = 'HELICOPTER_ROUTE_LOCATION'
        INNER JOIN dbo.mLookUp AS luTo ON luTo.wCode = mr.wRouteTo AND luTo.wLangCd = @pLangCd AND mr.wVehicle = 'HELI' AND luTo.wType = 'HELICOPTER_ROUTE_LOCATION'

        -- 包机客户
        SELECT
            rpd.wBookingRid,
            wCustomer = STUFF(
                (SELECT CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN p.wEName ELSE p.wCName END, CASE WHEN NULLIF(ptd.wEnglishPinyin, '') IS NULL THEN NULL ELSE ' (' + ptd.wEnglishPinyin + ')' END)
                FROM dbo.ePassengerDetails AS spd
                INNER JOIN dbo.mPerson AS p ON p.RowID = spd.wPersonRid AND spd.wBookingRid = rpd.wBookingRid AND spd.wStatus = 'A'
                LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON spd.RowID = ptdd.wPassengerDetailsRid
                LEFT JOIN dbo.mPersonTravelDoc AS ptd ON ptdd.wPersonTravelDocRid = ptd.RowID
                WHERE ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = spd.RowID)
                FOR XML PATH('')), 1, 1, N'')
        INTO #tCFYHeliPassenger
        FROM dbo.eBookingHeli AS heli
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'HELI' AND heli.wStatus = 'A' AND heli.wIsCharteredFlight = 'Y' AND eb.RowID = heli.wBookingRid
        INNER JOIN dbo.ePassengerDetails AS rpd ON rpd.wBookingRid > 0 AND rpd.wStatus = 'A' AND rpd.wBookingRid = heli.wBookingRid
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((heli.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        GROUP BY rpd.wBookingRid
        
        -- 非包机客户（小單扣數日期保存在小單）
        SELECT
            rpd.RowID,
            rpd.wBookingRid,
            rpd.wCancelReasonCd,
            rpd.wOtherReason,
            rpd.wCancelDebitDt,
            rpd.wCancelDt,
            rpd.wRouteRid,
            rpd.wTakeOffDt,
            rpd.wRemark,
            wPassengerBookingStatus = rps.wMapBookingStatus,
            wCustomer = STUFF(
                (SELECT CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN p.wEName ELSE p.wCName END, CASE WHEN NULLIF(ptd.wEnglishPinyin, '') IS NULL THEN NULL ELSE ' (' + ptd.wEnglishPinyin + ')' END)
                FROM dbo.ePassengerDetails AS spd
                INNER JOIN @tmpBookingStatus AS sps ON spd.wBookingRid = rpd.wBookingRid AND spd.wStatus = 'A' AND sps.wBookingStatus = spd.wPassengerBookingStatus AND sps.wMapBookingStatus = rps.wMapBookingStatus
                INNER JOIN dbo.mPerson AS p ON spd.wPersonRid = p.RowID
                LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON spd.RowID = ptdd.wPassengerDetailsRid
                LEFT JOIN dbo.mPersonTravelDoc AS ptd ON ptdd.wPersonTravelDocRid = ptd.RowID
                WHERE ((rps.wMapBookingStatus = 'RF' AND spd.wCancelDt = rpd.wCancelDt AND spd.wCancelDebitDt BETWEEN @pFromDt AND @pToDt) OR (rps.wMapBookingStatus != 'RF'))
                    AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = spd.RowID)
                FOR XML PATH('')), 1, 1, N'')
        INTO #tCFNHeliPassenger
        FROM dbo.eBookingHeli AS heli
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'HELI' AND heli.wStatus = 'A' AND heli.wIsCharteredFlight != 'Y' AND eb.RowID = heli.wBookingRid
        INNER JOIN dbo.ePassengerDetails AS rpd ON rpd.wBookingRid > 0 AND rpd.wStatus = 'A' AND rpd.wBookingRid = heli.wBookingRid
        INNER JOIN @tmpBookingStatus AS rps ON rps.wBookingStatus = rpd.wPassengerBookingStatus
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((rps.wMapBookingStatus = 'C' AND eb.wDebitDt BETWEEN @pFromDt AND @pToDt)
                OR (rps.wMapBookingStatus = 'RF' AND rpd.wCancelDebitDt BETWEEN @pFromDt AND @pToDt)
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))

        INSERT INTO #tmpResult (
            wBookingType,
            wDebitDt,
            wCancelDebitDt,
            wCancelDt,
            wRefNo,
            wRelatedBookingRefNo,
            wDebitCounterRid,
            wReqCounterRid,
            wDebitAgentCodeIn,
            wReqAgentCodeIn,
            wTranvalAgencyName,
            wOrderNo,
            wPaymentMethod,
            wReceiptNo,
            wDepositCost,
            wTotalCost,
            wTotalAmount,
            wDateString,
            wQuantity,
            wRouteString,
            wTicketType,
            wHotel,
            wDetail,
            wCustomer,
            wBookingStatus,
            wRemark,
            wCancelReasonCd,
            wOtherReason,
            wAsstBooker,
            wAsstBookerTel,
            wAssBookerEmail,
            wDeptFollowedCd,
            wStaffFollowedRid,
            wApprovalAgentCodeIn,
            wEventCodeRid,
            wReqDepartment,
            wReqUserRid,
            wTravelPkgRid,
            wUseBlackCard,
            wSameDebitDtCnt,
            wExpCategory,
            wCrtDt,
            wBookingRid,
            wBookingDtlRid,
            wHotelChangeRid
        )
        SELECT
            wBookingType = eb.wBookingType,
            wDebitDt = eb.wDebitDt,
            wCancelDebitDt = CASE WHEN heli.wIsCharteredFlight = 'Y' THEN eb.wCancelDebitDt ELSE pd.wCancelDebitDt END,
            wCancelDt = CASE WHEN heli.wIsCharteredFlight = 'Y' THEN eb.wCancelDt ELSE pd.wCancelDt END,
            wRefNo = eb.wRefNo,
            wRelatedBookingRefNo = NULL,
            wDebitCounterRid = eb.wDebitCounterRid,
            wReqCounterRid = eb.wReqCounterRid,
            wDebitAgentCodeIn = eb.wDebitAgentCodeIn,
            wReqAgentCodeIn = eb.wReqAgentCodeIn,
            wTranvalAgencyName = ta.wTitle,
            wOrderNo = heli.wOrderNo,
            wPaymentMethod = heli.wPaymentMethod,
            wReceiptNo = heli.wReceiptNo,
            wDepositCost = eb.wDepositAmt,
            wTotalCost = CASE WHEN heli.wIsCharteredFlight = 'Y' THEN heli.wCost ELSE (heli.wCost / NULLIF(ISNULL(heli.wQuantity, 0) , 0)) END,
            wTotalAmount = 0,
            wDateString = FORMAT(CASE WHEN heli.wIsCharteredFlight != 'Y' AND pd.wPassengerBookingStatus = 'RF' AND pd.wCancelDt != ISNULL(eb.wCancelDt, @sStartDateTime) THEN pd.wTakeOffDt ELSE heli.wDepartDt END, @sDateTimeFormat),
            wQuantity = heli.wQuantity,
            wRouteString = CASE WHEN pd.wPassengerBookingStatus = 'RF' AND pd.wCancelDt != ISNULL(eb.wCancelDt, @sStartDateTime) AND pr.wRouteTitle IS NOT NULL THEN pr.wRouteTitle ELSE hr.wRouteTitle END,
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CONCAT(N'包機：', CASE heli.wIsCharteredFlight WHEN 'Y' THEN N'是' ELSE N'否' END),
            wCustomer = CASE WHEN heli.wIsCharteredFlight = 'Y' THEN p.wCustomer ELSE pd.wCustomer END,
            wBookingStatus = CASE WHEN heli.wIsCharteredFlight = 'Y' THEN ps.wMapBookingStatus ELSE pd.wPassengerBookingStatus End,
            wRemark = CASE WHEN heli.wIsCharteredFlight != 'Y' AND pd.wPassengerBookingStatus = 'RF' AND pd.wCancelDt != ISNULL(eb.wCancelDt, @sStartDateTime) THEN pd.wRemark ELSE heli.wRemark END,
            wCancelReasonCd = CASE WHEN heli.wIsCharteredFlight = 'Y' OR pd.wCancelDt = eb.wCancelDt THEN eb.wCancelReasonCd ELSE pd.wCancelReasonCd END,
            wOtherReason = CASE WHEN heli.wIsCharteredFlight = 'Y' OR pd.wCancelDt = eb.wCancelDt THEN eb.wOtherReason ELSE pd.wOtherReason END,
            wAsstBooker = eb.wAsstBooker,
            wAsstBookerTel = eb.wAssBookerTel,
            wAssBookerEmail = eb.wAsstBookerEmail,
            wDeptFollowedCd = eb.wDeptFollwedCd,
            wStaffFollowedRid = eb.wStaffFollwedRid,
            wApprovalAgentCodeIn = eb.wApprovalAgentCodeIn,
            wEventCodeRid = eb.wEventCodeRid,
            wReqDepartment = eb.wReqDepartment,
            wReqUserRid = eb.wReqUserRid,
            wTravelPkgRid = eb.wTravePkgRid,
            wUseBlackCard = heli.wUseBlackCardFlag,
            wSameDebitDtCnt = '1',
            wExpCategory = NULL,
            wCrtDt = heli.wCrtDt,
            wBookingRid = eb.RowID,
            wBookingDtlRid = CASE WHEN heli.wIsCharteredFlight = 'Y' THEN -1 ELSE pd.RowID END,
            wHotelChangeRid = -1
        FROM dbo.eBookingHeli AS heli
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'HELI' AND heli.wStatus = 'A' AND eb.RowID = heli.wBookingRid
        LEFT JOIN dbo.mLookUp AS ta ON ta.wLangCd = @pLangCd AND ta.wType = 'HELICOPTER_BOOKING_LOCATION' AND ta.wCode = heli.wBookingLocation
        LEFT JOIN #tCFYHeliPassenger AS p ON heli.wIsCharteredFlight = 'Y' AND p.wBookingRid = eb.RowID	-- 包機
        LEFT JOIN #tCFNHeliPassenger AS pd ON heli.wIsCharteredFlight != 'Y' AND pd.wBookingRid = heli.wBookingRid --非包機，才有可能小單消費
        LEFT JOIN #tHeliRoute AS hr ON hr.RowID = heli.wRouteRid	-- 大單航線
        LEFT JOIN #tHeliRoute AS pr ON pr.RowID = pd.wRouteRid	-- 小單航線
        LEFT JOIN @tmpBookingStatus AS ps ON heli.wIsCharteredFlight = 'Y' AND ps.wBookingStatus = heli.wBookingStatus -- 包機（非包机，小单已经Join BookingStatus）
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((heli.wBookingStatus IN ('C', 'RF') 
                    AND ((ps.wMapBookingStatus = 'C' OR pd.wPassengerBookingStatus = 'C') AND eb.wDebitDt BETWEEN @pFromDt AND @pToDt)
                        OR (ps.wMapBookingStatus = 'RF' AND eb.wCancelDebitDt BETWEEN @pFromDt AND @pToDt)
                        OR (pd.wPassengerBookingStatus = 'RF' AND pd.wCancelDebitDt BETWEEN @pFromDt AND @pToDt))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))

        IF OBJECT_ID('tempdb..#tHeliRoute') IS NOT NULL
            DROP TABLE #tHeliRoute;

        IF OBJECT_ID('tempdb..#tCFYHeliPassenger') IS NOT NULL
            DROP TABLE #tCFYHeliPassenger;	
        
        IF OBJECT_ID('tempdb..#tCFNHeliPassenger') IS NOT NULL
            DROP TABLE #tCFNHeliPassenger;
    END;

    -- 機票 --
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @tmpBookingType WHERE wBookingType = 'AIRTICKET')
    BEGIN
        -- 機票航線（87%）
        SELECT
            rard.wTypeRid,
            rard.wType,
            wRouteTitle = STUFF(
                (SELECT CONCAT(CHAR(10), da.wCName, '->', aa.wCName)
                FROM dbo.eAirTicketRouteDtl AS sard
                LEFT JOIN dbo.mAirport AS da ON da.RowID = sard.wDepartureAirportRid
                LEFT JOIN dbo.mAirport AS aa ON aa.RowID = sard.wArrivalAirportRid
                WHERE sard.wTypeRid = rard.wTypeRid AND sard.wType = rard.wType
                ORDER BY sard.wLine
                FOR XML PATH(''),TYPE).value('text()[1]','nvarchar(max)'), 1, 1, N''),
            wRouteTime = STUFF(
                (SELECT CONCAT(CHAR(10), FORMAT(sard.wTakeOffDt, @sShortDateTimeFormat), '->', FORMAT(sard.wArrivalDt, @sShortDateTimeFormat))
                FROM dbo.eAirTicketRouteDtl AS sard
                WHERE sard.wTypeRid = rard.wTypeRid AND sard.wType = rard.wType
                ORDER BY sard.wLine
                FOR XML PATH(''),TYPE).value('text()[1]','nvarchar(max)'), 1, 1, N''),
            wFlight = STUFF(
                (SELECT CONCAT(CHAR(10), CONCAT(N'第', 
                                        CAST(sard.wLine AS VARCHAR), 
                                        N'程航班：', 
                                        sard.wDepartFlightNo, 
                                        CASE WHEN NULLIF(sard.wDepartFlightNo, '') IS NULL OR NULLIF(sard.wDepartureTerminal, '') IS NULL THEN NULL ELSE ', ' END, 
                                        sard.wDepartureTerminal, 
                                        CASE WHEN (NULLIF(sard.wDepartFlightNo, '') IS NULL AND NULLIF(sard.wDepartureTerminal, '') IS NULL) OR NULLIF(lu.wTitle, '') IS NULL THEN NULL ELSE ', ' END,
                                        CASE WHEN NULLIF(lu.wTitle, '') IS NULL THEN NULL ELSE lu.wTitle + N'艙' END))
                FROM dbo.eAirTicketRouteDtl AS sard
                LEFT JOIN dbo.mLookUp AS lu ON lu.wLangCd = @pLangCd AND lu.wType = 'AIR_CLASS' AND sard.wClassCd = lu.wCode
                WHERE sard.wTypeRid = rard.wTypeRid AND sard.wType = rard.wType
                ORDER BY sard.wLine
                FOR XML PATH('')), 1, 1, N''),
            wAirlines = STUFF(
                (SELECT CONCAT(', ', lu.wTitle)
                FROM dbo.eAirTicketRouteDtl AS sard
                LEFT JOIN dbo.mLookUp AS lu ON lu.wLangCd = @pLangCd AND lu.wType = 'AIRLINES' AND sard.wAirline = lu.wCode
                WHERE sard.wTypeRid = rard.wTypeRid AND sard.wType = rard.wType
                GROUP BY lu.wTitle
                FOR XML PATH('')), 1, 2, N'')
        INTO #tAirRoute
        FROM dbo.eAirTicketRouteDtl AS rard
        -- 大单
        LEFT JOIN dbo.eBookingAirTicket AS air ON air.wStatus = 'A' AND air.RowID = rard.wTypeRid AND rard.wType = 'AIRTICKET'
        LEFT JOIN dbo.eBooking AS eb ON eb.wBookingType = 'AIRTICKET' AND eb.RowID = air.wBookingRid
        -- 小单
        LEFT JOIN dbo.ePassengerDetails AS pd ON ISNULL(pd.wBookingRid, 0) > 0 AND pd.wStatus = 'A' AND pd.RowID = rard.wTypeRid AND rard.wType = 'PASSENGER'
        LEFT JOIN dbo.eBooking AS b ON b.wBookingType = 'AIRTICKET' AND b.RowID = pd.wBookingRid
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (rard.wType = 'AIRTICKET' OR rard.wType = 'PASSENGER') AND rard.wStatus = 'A' AND wTypeRid > 0
            AND (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND (eb.wDebitDt BETWEEN @pFromDt AND @pToDt
                OR ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt
                OR ISNULL(pd.wCancelDebitDt, ISNULL(b.wDebitDt, @sStartDateTime)) BETWEEN @pFromDt AND @pToDt
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        GROUP BY rard.wTypeRid, rard.wType --（大、小單航線，wTypeRid可能會跟小單一致（如果有），要用Rid, Type分组)

        -- 客戶（小單扣數日期保存在小單）
        SELECT
            rpd.RowID,
            rpd.wBookingRid,
            rpd.wCancelReasonCd,
            rpd.wOtherReason,
            rpd.wCost,
            rpd.wCancelDebitDt,
            rpd.wCancelDt,
            rpd.wRemark,
            wPassengerBookingStatus = rps.wMapBookingStatus,
            wCustomer = STUFF(
                (SELECT CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN p.wEName ELSE p.wCName END, CASE WHEN NULLIF(ptd.wEnglishPinyin, '') IS NULL THEN NULL ELSE ' (' + ptd.wEnglishPinyin + ')' END)
                FROM dbo.ePassengerDetails AS spd
                INNER JOIN @tmpBookingStatus AS sps ON spd.wBookingRid = rpd.wBookingRid AND spd.wStatus = 'A' AND sps.wBookingStatus = spd.wPassengerBookingStatus AND sps.wMapBookingStatus = rps.wMapBookingStatus
                INNER JOIN dbo.mPerson AS p ON spd.wPersonRid = p.RowID
                LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON spd.RowID = ptdd.wPassengerDetailsRid
                LEFT JOIN dbo.mPersonTravelDoc AS ptd ON ptdd.wPersonTravelDocRid = ptd.RowID
                WHERE ((rps.wMapBookingStatus = 'RF' AND spd.wCancelDt = rpd.wCancelDt AND spd.wCancelDebitDt BETWEEN @pFromDt AND @pToDt) OR (rps.wMapBookingStatus != 'RF'))
                    AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = spd.RowID)
                FOR XML PATH('')), 1, 1, N''),
            wTicketNo = STUFF(
                (SELECT CASE WHEN NULLIF(spd.wClientTicketNo, '') IS NULL THEN NULL ELSE CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN p.wEName ELSE p.wCName END, '(', spd.wClientTicketNo , ') ') END
                FROM dbo.ePassengerDetails AS spd
                INNER JOIN @tmpBookingStatus AS sps ON spd.wBookingRid = rpd.wBookingRid AND spd.wStatus = 'A' AND sps.wBookingStatus = spd.wPassengerBookingStatus AND sps.wMapBookingStatus = rps.wMapBookingStatus
                INNER JOIN dbo.mPerson AS p ON p.RowID = spd.wPersonRid
                WHERE (rps.wMapBookingStatus = 'RF' AND spd.wCancelDt = rpd.wCancelDt AND spd.wCancelDebitDt BETWEEN @pFromDt AND @pToDt) OR (rps.wMapBookingStatus != 'RF')
                FOR XML PATH('')), 1, 1, N'')
        INTO #tAirPassenger
        FROM dbo.eBookingAirTicket AS air
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'AIRTICKET' AND air.wStatus = 'A' AND eb.RowID = air.wBookingRid
        INNER JOIN dbo.ePassengerDetails AS rpd ON rpd.wBookingRid > 0 AND rpd.wStatus = 'A' AND rpd.wBookingRid = air.wBookingRid
        INNER JOIN @tmpBookingStatus AS rps ON rps.wBookingStatus = rpd.wPassengerBookingStatus
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((rps.wMapBookingStatus = 'C' AND eb.wDebitDt BETWEEN @pFromDt AND @pToDt)
                OR (rps.wMapBookingStatus = 'RF' AND rpd.wCancelDebitDt BETWEEN @pFromDt AND @pToDt)
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))

        INSERT INTO #tmpResult (
            wBookingType,
            wDebitDt,
            wCancelDebitDt,
            wCancelDt,
            wRefNo,
            wRelatedBookingRefNo,
            wDebitCounterRid,
            wReqCounterRid,
            wDebitAgentCodeIn,
            wReqAgentCodeIn,
            wTranvalAgencyName,
            wOrderNo,
            wPaymentMethod,
            wReceiptNo,
            wDepositCost,
            wTotalCost,
            wTotalAmount,
            wDateString,
            wQuantity,
            wRouteString,
            wTicketType,
            wHotel,
            wDetail,
            wCustomer,
            wBookingStatus,
            wRemark,
            wCancelReasonCd,
            wOtherReason,
            wAsstBooker,
            wAsstBookerTel,
            wAssBookerEmail,
            wDeptFollowedCd,
            wStaffFollowedRid,
            wApprovalAgentCodeIn,
            wEventCodeRid,
            wReqDepartment,
            wReqUserRid,
            wTravelPkgRid,
            wUseBlackCard,
            wSameDebitDtCnt,
            wExpCategory,
            wCrtDt,
            wBookingRid,
            wBookingDtlRid,
            wHotelChangeRid
        )
        SELECT
            wBookingType = eb.wBookingType,
            wDebitDt = eb.wDebitDt,
            wCancelDebitDt = pd.wCancelDebitDt,
            wCancelDt = pd.wCancelDt,
            wRefNo = eb.wRefNo,
            wRelatedBookingRefNo = NULL,
            wDebitCounterRid = eb.wDebitCounterRid,
            wReqCounterRid = eb.wReqCounterRid,
            wDebitAgentCodeIn = eb.wDebitAgentCodeIn,
            wReqAgentCodeIn = eb.wReqAgentCodeIn,
            wTranvalAgencyName = ta.wName,
            wOrderNo = air.wOrderNo,
            wPaymentMethod = air.wPaymentMethod,
            wReceiptNo = air.wReceiptNo,
            wDepositCost = eb.wDepositAmt,
            wTotalCost = pd.wCost,
            wTotalAmount = 0,
            wDateString = CASE WHEN pd.wPassengerBookingStatus = 'RF' AND pd.wCancelDt != ISNULL(eb.wCancelDt, @sStartDateTime) AND pr.wRouteTime IS NOT NULL THEN pr.wRouteTime ELSE ar.wRouteTime END,
            wQuantity = air.wQuantity,
            wRouteString = CASE WHEN pd.wPassengerBookingStatus = 'RF' AND pd.wCancelDt != ISNULL(eb.wCancelDt, @sStartDateTime) AND pr.wRouteTitle IS NOT NULL THEN pr.wRouteTitle ELSE ar.wRouteTitle END,
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CONCAT(N'預訂類型：', tType.wTitle, char(10), 
                            N'航空公司：', CASE WHEN pd.wPassengerBookingStatus = 'RF' AND pd.wCancelDt != ISNULL(eb.wCancelDt, @sStartDateTime) AND pr.wAirlines IS NOT NULL THEN pr.wAirlines ELSE  ar.wAirlines END, char(10), 
                            N'到期日：', CASE WHEN air.wExpiryDt IS NOT NULL THEN FORMAT(air.wExpiryDt, 'yyyy-MM-dd') ELSE NULL END, char(10),
                            CASE WHEN pd.wPassengerBookingStatus = 'RF' AND pd.wCancelDt != ISNULL(eb.wCancelDt, @sStartDateTime) AND pr.wFlight IS NOT NULL THEN pr.wFlight ELSE ar.wFlight END, char(10),
                            N'票號：', pd.wTicketNo
                      ),
            wCustomer = pd.wCustomer,
            wBookingStatus = CASE WHEN NULLIF(pd.wPassengerBookingStatus, '') IS NULL THEN air.wBookingStatus ELSE pd.wPassengerBookingStatus END,
            wRemark = CASE WHEN pd.wPassengerBookingStatus = 'RF' AND pd.wCancelDt != ISNULL(eb.wCancelDt, @sStartDateTime) THEN pd.wRemark ELSE air.wRemark END,
            wCancelReasonCd = CASE WHEN pd.wCancelDt = eb.wCancelDt THEN eb.wCancelReasonCd ELSE pd.wCancelReasonCd END,
            wOtherReason = CASE WHEN pd.wCancelDt = eb.wCancelDt THEN eb.wOtherReason ELSE pd.wOtherReason END,
            wAsstBooker = eb.wAsstBooker,
            wAsstBookerTel = eb.wAssBookerTel,
            wAssBookerEmail = eb.wAsstBookerEmail,
            wDeptFollowedCd = eb.wDeptFollwedCd,
            wStaffFollowedRid = eb.wStaffFollwedRid,
            wApprovalAgentCodeIn = eb.wApprovalAgentCodeIn,
            wEventCodeRid = eb.wEventCodeRid,
            wReqDepartment = eb.wReqDepartment,
            wReqUserRid = eb.wReqUserRid,
            wTravelPkgRid = eb.wTravePkgRid,
            wUseBlackCard = NULL,
            wSameDebitDtCnt = '1',
            wExpCategory = NULL,
            wCrtDt = air.wCrtDt,
            wBookingRid = eb.RowID,
            wBookingDtlRid = pd.RowID,
            wHotelChangeRid = -1
        FROM dbo.eBookingAirTicket AS air
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'AIRTICKET' AND air.wStatus = 'A' AND eb.RowID = air.wBookingRid
        LEFT JOIN dbo.mTravelAgency AS ta ON wIsAirTic = 'Y' AND air.wTravelAgencyRid = ta.RowID
        LEFT JOIN dbo.mLookUp AS tType ON tType.wLangCd = @pLangCd AND tType.wType = 'AIR_TICKET_TYPE' AND tType.wCode = air.wFlightType
        LEFT JOIN #tAirPassenger AS pd ON pd.wBookingRid = air.wBookingRid
        LEFT JOIN #tAirRoute AS ar ON ar.wType = 'AIRTICKET' AND ar.wTypeRid = air.RowID  	-- 大單航線
        LEFT JOIN #tAirRoute As pr ON pr.wType = 'PASSENGER' AND pr.wTypeRid = pd.RowID 	-- 小單航線
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((pd.wPassengerBookingStatus = 'C' AND eb.wDebitDt BETWEEN @pFromDt AND @pToDt)
                OR (pd.wPassengerBookingStatus = 'RF' AND ISNULL(pd.wCancelDebitDt, eb.wCancelDebitDt) BETWEEN @pFromDt AND @pToDt)
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))

        IF OBJECT_ID('tempdb..#tAirRoute') IS NOT NULL
            DROP TABLE #tAirRoute;

        IF OBJECT_ID('tempdb..#tAirPassenger') IS NOT NULL
            DROP TABLE #tAirPassenger;	
    END;

    -- 房間 --
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @tmpBookingType WHERE wBookingType = 'CHANGEHOTEL')
    BEGIN
        -- Order數（同一個大單號，同一個動作，扣數日期同一天為一個ORDER）(24%)
        SELECT
            wHotelBookingRid = bh.RowID,
            hc.wAction,
            hc.wDebitDt,
            wCount = COUNT(*)
        INTO #tRoomOrderAction
        FROM (SELECT wRoomBookingRid, wAction, wDebitDt = FORMAT(wDebitDt, @sDateFormat) FROM dbo.eHotelChange WHERE wDebitDt BETWEEN @pFromDt AND @pToDt)AS hc
        INNER JOIN dbo.eBookingRoom AS br ON br.RowID = hc.wRoomBookingRid
        INNER JOIN dbo.eBookingHotel AS bh ON bh.RowID = br.wHotelBookingRid
        GROUP BY bh.RowID, hc.wAction, hc.wDebitDt

        -- 房間客戶(13%)
        SELECT
            rpd.wRoomBookingRid,
            wCustomer = STUFF(
                (SELECT CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN p.wEName ELSE p.wCName END, CASE WHEN NULLIF(ptd.wEnglishPinyin, '') IS NULL THEN NULL ELSE ' (' + ptd.wEnglishPinyin + ')' END)
                From dbo.ePassengerDetails AS spd
                INNER JOIN dbo.mPerson AS p ON p.RowID = spd.wPersonRid
                LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON spd.RowID = ptdd.wPassengerDetailsRid
                LEFT JOIN dbo.mPersonTravelDoc ptd ON ptdd.wPersonTravelDocRid = ptd.RowID
                WHERE spd.wRoomBookingRid = rpd.wRoomBookingRid AND spd.wStatus = 'A' AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = spd.RowID)
                FOR XML PATH('')), 1, 1, N'')
        INTO #tRoomPassenger
        FROM dbo.eBookingRoom AS br
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'ROOM' AND br.wStatus = 'A' AND eb.RowID = br.wBookingRid
        INNER JOIN dbo.ePassengerDetails AS rpd ON ISNULL(rpd.wRoomBookingRid, 0) > 0 AND rpd.wStatus = 'A' AND rpd.wRoomBookingRid = br.RowID
        LEFT JOIN dbo.eHotelChange AS hc ON hc.wRoomBookingRid = br.RowID
        LEFT JOIN dbo.eBooking AS b ON b.RowID = hc.wBookingRid
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND (((br.wBookingStatus IN ('C', 'CI', 'CO', 'RF') AND ((b.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt))))
                 OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        GROUP BY rpd.wRoomBookingRid

        -- (63%)
        INSERT INTO #tmpResult (
            wBookingType,
            wDebitDt,
            wCancelDebitDt,
            wCancelDt,
            wRefNo,
            wRelatedBookingRefNo,
            wDebitCounterRid,
            wReqCounterRid,
            wDebitAgentCodeIn,
            wReqAgentCodeIn,
            wTranvalAgencyName,
            wOrderNo,
            wPaymentMethod,
            wReceiptNo,
            wDepositCost,
            wTotalCost,
            wTotalAmount,
            wDateString,
            wQuantity,
            wRouteString,
            wTicketType,
            wHotel,
            wDetail,
            wCustomer,
            wBookingStatus,
            wRemark,
            wCancelReasonCd,
            wOtherReason,
            wAsstBooker,
            wAsstBookerTel,
            wAssBookerEmail,
            wDeptFollowedCd,
            wStaffFollowedRid,
            wApprovalAgentCodeIn,
            wEventCodeRid,
            wReqDepartment,
            wReqUserRid,
            wTravelPkgRid,
            wUseBlackCard,
            wSameDebitDtCnt,
            wExpCategory,
            wCrtDt,
            wBookingRid,
            wBookingDtlRid,
            wHotelChangeRid
        )
        SELECT
            wBookingType = eb.wBookingType,
            wDebitDt = b.wDebitDt,
            wCancelDebitDt = b.wCancelDebitDt,
            wCancelDt = eb.wCancelDt,
            wRefNo = eb.wRefNo,
            wRelatedBookingRefNo = NULL,
            wDebitCounterRid = eb.wDebitCounterRid,
            wReqCounterRid = eb.wReqCounterRid,
            wDebitAgentCodeIn = eb.wDebitAgentCodeIn,
            wReqAgentCodeIn = eb.wReqAgentCodeIn,
            wTranvalAgencyName = ta.wName,
            wOrderNo = hc.wOrderNo,
            wPaymentMethod = hc.wPaymentMethod,
            wReceiptNo = hc.wCashReceiptNo,
            wDepositCost = eb.wDepositAmt,
            wTotalCost = hc.wCostChange,
            wTotalAmount = 0,
            wDateString = CONCAT(N'變動入住日期：', ( 
                                                    CASE hc.wAction
                                                    WHEN 'C'	THEN FORMAT(hc.wNewStartDate, @sDateFormat)
                                                    WHEN 'RF'	THEN FORMAT(hc.wOriStartDate, @sDateFormat)
                                                    WHEN 'EX'	THEN FORMAT(hc.wOriEndDate,	  @sDateFormat)
                                                    WHEN 'ECI'	THEN FORMAT(hc.wNewStartDate, @sDateFormat)
                                                    WHEN 'LC'	THEN FORMAT(hc.wOriStartDate, @sDateFormat)
                                                    WHEN 'ECO'	THEN FORMAT(hc.wNewEndDate,	  @sDateFormat)
                                                    ELSE NULL END), 
                                                    CHAR(10), 
                                N'變動退房日期：', (
                                                    CASE hc.wAction
                                                    WHEN 'C'	THEN FORMAT(hc.wNewEndDate,   @sDateFormat)
                                                    WHEN 'RF'	THEN FORMAT(hc.wOriEndDate,   @sDateFormat)
                                                    WHEN 'EX'	THEN FORMAT(hc.wNewEndDate,   @sDateFormat)
                                                    WHEN 'ECI'	THEN FORMAT(hc.wOriStartDate, @sDateFormat)
                                                    WHEN 'LC'	THEN FORMAT(hc.wNewStartDate, @sDateFormat)
                                                    WHEN 'ECO'	THEN FORMAT(hc.wOriEndDate,   @sDateFormat)
                                                    ELSE NULL END)
            ),
            wQuantity = (
                        CASE hc.wAction
                        WHEN 'C' THEN DATEDIFF(DAY, hc.wNewStartDate, hc.wNewEndDate)		-- 完成
                        WHEN 'RF' THEN -1 * DATEDIFF(DAY, hc.wOriStartDate, hc.wOriEndDate) -- 退款
                        WHEN 'ECI' THEN DATEDIFF(DAY, hc.wNewStartDate, hc.wOriStartDate)	-- 提早入住
                        WHEN 'LC' THEN DATEDIFF(DAY, hc.wNewStartDate, hc.wOriStartDate)	-- 延遲入住
                        WHEN 'ECO' THEN DATEDIFF(DAY, hc.wOriEndDate, hc.wNewEndDate)		-- 早退
                        WHEN 'EX' THEN DATEDIFF(DAY, hc.wOriEndDate, hc.wNewEndDate)		-- 續房
                        ELSE NULL END
            ),
            wRouteString = NULL,
            wTicketType = NULL,
            wHotel = CASE WHEN @pLangCd = 'en-GB' THEN h.wEname ELSE h.wName END,
            wDetail = CONCAT(N'動作：', actionType.wTitle, char(10),  
                            N'房型：', CASE WHEN @pLangCd = 'en-gb' THEN hr.wEname ELSE hr.wName END, CHAR(10), 
                            N'配額類型：', mhr.wName, char(10),
                            N'床類：', bed.wTitle, char(10),
                            N'房號：', br.wRoomNo, char(10),
                            N'是否含早餐：', CASE WHEN br.wIncludeBreakfast = 'Y' THEN N'是' ELSE N'否' END, char(10),
                            N'確認號：', br.wConfirmationNo),
            wCustomer = pd.wCustomer,
            wBookingStatus = br.wBookingStatus,
            wRemark = br.wRemark,
            wCancelReasonCd = eb.wCancelReasonCd,
            wOtherReason = eb.wOtherReason,
            wAsstBooker = b.wAsstBooker,
            wAsstBookerTel = b.wAssBookerTel,
            wAssBookerEmail = b.wAsstBookerEmail,
            wDeptFollowedCd = b.wDeptFollwedCd,
            wStaffFollowedRid = b.wStaffFollwedRid,
            wApprovalAgentCodeIn = b.wApprovalAgentCodeIn,
            wEventCodeRid = br.wEventCodeRid,
            wReqDepartment = b.wReqDepartment,
            wReqUserRid = b.wReqUserRid,
            wTravelPkgRid = br.wTravelPkgRid,
            wUseBlackCard = hc.wUseMemeberCard,
            wSameDebitDtCnt = CASE WHEN hca.wCount > 1 THEN CONCAT('1', '/', CAST(hca.wCount AS VARCHAR)) ELSE '1' END,
            wExpCategory = NULL,
            wCrtDt = br.wCrtDt,
            wBookingRid = bh.wBookingRid, -- 酒店的wBookingRid而不是房间的wBookingRid
            wBookingDtlRid = br.RowID,
            wHotelChangeRid = hc.RowID
        FROM dbo.eBookingRoom AS br
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'ROOM' AND br.wStatus = 'A' AND eb.RowID = br.wBookingRid
        INNER JOIN dbo.eBookingHotel AS bh ON bh.RowID = br.wHotelBookingRid
        LEFT JOIN dbo.mHotelRoom AS hr ON hr.RowID = br.wHotelRoomRid
        LEFT JOIN dbo.mHotel AS h ON h.RowID = br.wHotelRid
        LEFT JOIN dbo.mAllotmentGroup AS mhr ON mhr.RowID = br.wAllotmentGroupRid
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.wIsHotel = 'Y' AND ta.RowID = br.wTravelAgencyRid --外館酒店供應商
        LEFT JOIN dbo.eHotelChange AS hc ON hc.wRoomBookingRid = br.RowID
        LEFT JOIN dbo.eBooking AS b ON b.RowID = hc.wBookingRid
        LEFT JOIN dbo.mLookUp AS actionType ON actionType.wLangCd = @pLangCd AND actionType.wType = 'HOTEL_BOOKING_ACTION' AND actionType.wCode = hc.wAction
        LEFT JOIN dbo.mLookUp AS bed ON bed.wLangCd = @pLangCd AND bed.wType = 'BED_TYPE' AND bed.wCode = br.wBedType
        LEFT JOIN #tRoomPassenger AS pd ON pd.wRoomBookingRid = br.RowID
        LEFT JOIN #tRoomOrderAction AS hca ON hca.wHotelBookingRid = bh.RowID AND hca.wAction = hc.wAction AND hca.wDebitDt = FORMAT(hc.wDebitDt, @sDateFormat)
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND (((br.wBookingStatus IN ('C', 'CI', 'CO', 'RF') AND ((b.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt))))
                 OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))

        IF OBJECT_ID('tempdb..#tRoomOrderAction') IS NOT NULL
            DROP TABLE #tRoomOrderAction;

        IF OBJECT_ID('tempdb..#tRoomPassenger') IS NOT NULL
            DROP TABLE #tRoomPassenger;
    END;

    -- 警察開路
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @tmpBookingType WHERE wBookingType = 'LEADING_SERVICE')
    BEGIN
        INSERT INTO #tmpResult (
            wBookingType,
            wDebitDt,
            wCancelDebitDt,
            wCancelDt,
            wRefNo,
            wRelatedBookingRefNo,
            wDebitCounterRid,
            wReqCounterRid,
            wDebitAgentCodeIn,
            wReqAgentCodeIn,
            wTranvalAgencyName,
            wOrderNo,
            wPaymentMethod,
            wReceiptNo,
            wDepositCost,
            wTotalCost,
            wTotalAmount,
            wDateString,
            wQuantity,
            wRouteString,
            wTicketType,
            wHotel,
            wDetail,
            wCustomer,
            wBookingStatus,
            wRemark,
            wCancelReasonCd,
            wOtherReason,
            wAsstBooker,
            wAsstBookerTel,
            wAssBookerEmail,
            wDeptFollowedCd,
            wStaffFollowedRid,
            wApprovalAgentCodeIn,
            wEventCodeRid,
            wReqDepartment,
            wReqUserRid,
            wTravelPkgRid,
            wUseBlackCard,
            wSameDebitDtCnt,
            wExpCategory,
            wCrtDt,
            wBookingRid,
            wBookingDtlRid,
            wHotelChangeRid
        )
        SELECT
            wBookingType = eb.wBookingType,
            wDebitDt = eb.wDebitDt,
            wCancelDebitDt = eb.wCancelDebitDt,
            wCancelDt = eb.wCancelDt,
            wRefNo = eb.wRefNo,
            wRelatedBookingRefNo = NULL,
            wDebitCounterRid = eb.wDebitCounterRid,
            wReqCounterRid = eb.wReqCounterRid,
            wDebitAgentCodeIn = eb.wDebitAgentCodeIn,
            wReqAgentCodeIn = eb.wReqAgentCodeIn,
            wTranvalAgencyName = ta.wName,
            wOrderNo = lead.wOrderNo,
            wPaymentMethod = lead.wPaymentMethod,
            wReceiptNo = lead.wReceiptNo,
            wDepositCost = eb.wDepositAmt,
            wTotalCost = lead.wTotalCost,
            wTotalAmount = 0,
            wDateString = FORMAT(lead.wStartDt, 'yyyy-MM-dd HH:mm'),
            wQuantity = 1,
            wRouteString = NULL,
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CONCAT(N'地區：', region.wTitle, CHAR(10), N'警察數量：', lead.wNoofPolice),
            wCustomer = NULL,
            wBookingStatus = lead.wBookingStatus,
            wRemark = lead.wRemark,
            wCancelReasonCd = eb.wCancelReasonCd,
            wOtherReason = eb.wOtherReason,
            wAsstBooker = eb.wAsstBooker,
            wAsstBookerTel = eb.wAssBookerTel,
            wAssBookerEmail = eb.wAsstBookerEmail,
            wDeptFollowedCd = eb.wDeptFollwedCd,
            wStaffFollowedRid = eb.wStaffFollwedRid,
            wApprovalAgentCodeIn = eb.wApprovalAgentCodeIn,
            wEventCodeRid = eb.wEventCodeRid,
            wReqDepartment = eb.wReqDepartment,
            wReqUserRid = eb.wReqUserRid,
            wTravelPkgRid = eb.wTravePkgRid,
            wUseBlackCard = lead.wUseBlackCard,
            wSameDebitDtCnt = '1',
            wExpCategory = NULL,
            wCrtDt = lead.wCrtDt,
            wBookingRid = eb.RowID,
            wBookingDtlRid = -1,
            wHotelChangeRid = -1
        FROM dbo.eBookingLeading As lead
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'LEADING_SERVICE' AND lead.wStatus = 'A' AND eb.RowID = lead.wBookingRid
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.RowID = lead.wTravelAgencyRid
        LEFT JOIN dbo.mLookUp AS region ON region.wLangCd = @pLangCd AND region.wType = 'REGION' AND region.wCode = lead.wRegion
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((lead.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt)))	--只有完成、退款狀態才有射數
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
    END;

    -- 簽證 --
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @tmpBookingType WHERE wBookingType = 'Visa')
    BEGIN
        -- 客戶、消費額
        SELECT
            rpd.wBookingRid,
            wTotalAmount = SUM(rpd.wAmount),
            wTotalCost = SUM(rpd.wCost),
            wCustomer = STUFF(
                (SELECT CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN p.wEName ELSE p.wCName END, CASE WHEN NULLIF(ptd.wEnglishPinyin, '') IS NULL THEN NULL ELSE ' (' + ptd.wEnglishPinyin + ')' END)
                From dbo.ePassengerDetails AS spd
                INNER JOIN dbo.mPerson AS p ON p.RowID = spd.wPersonRid
                LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON spd.RowID = ptdd.wPassengerDetailsRid
                LEFT JOIN dbo.mPersonTravelDoc AS ptd ON ptdd.wPersonTravelDocRid = ptd.RowID
                WHERE spd.wBookingRid = rpd.wBookingRid AND spd.wStatus = 'A' AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = spd.RowID)
                FOR XML PATH('')), 1, 1, N'')
        INTO #tVisaPassenger
        FROM dbo.eBookingVisa AS visa
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'Visa' AND visa.wStatus = 'A' AND eb.RowID = visa.wBookingRid
        INNER JOIN dbo.ePassengerDetails AS rpd ON rpd.wBookingRid > 0 AND rpd.wStatus = 'A' AND rpd.wBookingRid = visa.wBookingRid
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((visa.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        GROUP BY rpd.wBookingRid

        INSERT INTO #tmpResult (
            wBookingType,
            wDebitDt,
            wCancelDebitDt,
            wCancelDt,
            wRefNo,
            wRelatedBookingRefNo,
            wDebitCounterRid,
            wReqCounterRid,
            wDebitAgentCodeIn,
            wReqAgentCodeIn,
            wTranvalAgencyName,
            wOrderNo,
            wPaymentMethod,
            wReceiptNo,
            wDepositCost,
            wTotalCost,
            wTotalAmount,
            wDateString,
            wQuantity,
            wRouteString,
            wTicketType,
            wHotel,
            wDetail,
            wCustomer,
            wBookingStatus,
            wRemark,
            wCancelReasonCd,
            wOtherReason,
            wAsstBooker,
            wAsstBookerTel,
            wAssBookerEmail,
            wDeptFollowedCd,
            wStaffFollowedRid,
            wApprovalAgentCodeIn,
            wEventCodeRid,
            wReqDepartment,
            wReqUserRid,
            wTravelPkgRid,
            wUseBlackCard,
            wSameDebitDtCnt,
            wExpCategory,
            wCrtDt,
            wBookingRid,
            wBookingDtlRid,
            wHotelChangeRid
        )
        SELECT
            wBookingType = eb.wBookingType,
            wDebitDt = eb.wDebitDt,
            wCancelDebitDt = eb.wCancelDebitDt,
            wCancelDt = eb.wCancelDt,
            wRefNo = eb.wRefNo,
            wRelatedBookingRefNo = NULL,
            wDebitCounterRid = eb.wDebitCounterRid,
            wReqCounterRid = eb.wReqCounterRid,
            wDebitAgentCodeIn = eb.wDebitAgentCodeIn,
            wReqAgentCodeIn = eb.wReqAgentCodeIn,
            wTranvalAgencyName = ta.wName,
            wOrderNo = visa.wOrderNo,
            wPaymentMethod = visa.wPaymentMethod,
            wReceiptNo = visa.wReceiptNo,
            wDepositCost = eb.wDepositAmt,
            wTotalCost = pd.wTotalCost,
            wTotalAmount = 0,
            wDateString = FORMAT(visa.wApplyDt, 'yyyy-MM-dd'),
            wQuantity = visa.wQuantity,
            wRouteString = NULL,
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CASE WHEN NULLIF(place.wTitle, '') IS NULL THEN NUll ELSE CONCAT(N'簽發地：', place.wTitle) END,
            wCustomer = pd.wCustomer,
            wBookingStatus = visa.wBookingStatus,
            wRemark = visa.wRemark,
            wCancelReasonCd = eb.wCancelReasonCd,
            wOtherReason = eb.wOtherReason,
            wAsstBooker = eb.wAsstBooker,
            wAsstBookerTel = eb.wAssBookerTel,
            wAssBookerEmail = eb.wAsstBookerEmail,
            wDeptFollowedCd = eb.wDeptFollwedCd,
            wStaffFollowedRid = eb.wStaffFollwedRid,
            wApprovalAgentCodeIn = eb.wApprovalAgentCodeIn,
            wEventCodeRid = eb.wEventCodeRid,
            wReqDepartment = eb.wReqDepartment,
            wReqUserRid = eb.wReqUserRid,
            wTravelPkgRid = eb.wTravePkgRid,
            wUseBlackCard = visa.wUseBlackCard,
            wSameDebitDtCnt = '1',
            wExpCategory = NULL,
            wCrtDt = visa.wCrtDt,
            wBookingRid = eb.RowID,
            wBookingDtlRid = -1,
            wHotelChangeRid = -1
        FROM dbo.eBookingVisa AS visa
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'Visa' AND visa.wStatus = 'A' AND eb.RowID = visa.wBookingRid
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.RowID = visa.wTravelAgencyRid
        LEFT JOIN dbo.mLookUp AS place ON place.wLangCd = @pLangCd AND place.wType = 'ID_ISSUE_PLACE' AND place.wCode = visa.wPlaceOfIssue
        LEFT JOIN #tVisaPassenger AS pd ON pd.wBookingRid = eb.RowID
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((visa.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))

        IF OBJECT_ID('tempdb..#tVisaPassenger') IS NOT NULL
            DROP TABLE #tVisaPassenger;
    END;

    -- 流動登機 --
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @tmpBookingType WHERE wBookingType = 'CHK_IN_SVC')
    BEGIN
        -- 客戶
        SELECT
            rpd.wBookingRid,
            wCustomer = STUFF(
                (SELECT CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN p.wEName ELSE p.wCName END, CASE WHEN NULLIF(ptd.wEnglishPinyin, '') IS NULL THEN NULL ELSE ' (' + ptd.wEnglishPinyin + ')' END)
                From dbo.ePassengerDetails AS spd
                INNER JOIN dbo.mPerson AS p ON p.RowID = spd.wPersonRid
                LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON spd.RowID = ptdd.wPassengerDetailsRid
                LEFT JOIN dbo.mPersonTravelDoc AS ptd ON ptdd.wPersonTravelDocRid = ptd.RowID
                WHERE spd.wBookingRid = rpd.wBookingRid AND spd.wStatus = 'A' AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = spd.RowID)
                FOR XML PATH('')), 1, 1, N'')
        INTO #tCIPassenger
        FROM dbo.eBookingCheckInService AS ci
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'CHK_IN_SVC' AND ci.wStatus = 'A' AND eb.RowID = ci.wBookingRid
        INNER JOIN dbo.ePassengerDetails AS rpd ON rpd.wBookingRid > 0 AND rpd.wStatus = 'A' AND rpd.wBookingRid = ci.wBookingRid
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((ci.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt))) --只有完成、退款狀態才有射數
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        GROUP BY rpd.wBookingRid

        INSERT INTO #tmpResult (
            wBookingType,
            wDebitDt,
            wCancelDebitDt,
            wCancelDt,
            wRefNo,
            wRelatedBookingRefNo,
            wDebitCounterRid,
            wReqCounterRid,
            wDebitAgentCodeIn,
            wReqAgentCodeIn,
            wTranvalAgencyName,
            wOrderNo,
            wPaymentMethod,
            wReceiptNo,
            wDepositCost,
            wTotalCost,
            wTotalAmount,
            wDateString,
            wQuantity,
            wRouteString,
            wTicketType,
            wHotel,
            wDetail,
            wCustomer,
            wBookingStatus,
            wRemark,
            wCancelReasonCd,
            wOtherReason,
            wAsstBooker,
            wAsstBookerTel,
            wAssBookerEmail,
            wDeptFollowedCd,
            wStaffFollowedRid,
            wApprovalAgentCodeIn,
            wEventCodeRid,
            wReqDepartment,
            wReqUserRid,
            wTravelPkgRid,
            wUseBlackCard,
            wSameDebitDtCnt,
            wExpCategory,
            wCrtDt,
            wBookingRid,
            wBookingDtlRid,
            wHotelChangeRid
        )
        SELECT
            wBookingType = eb.wBookingType,
            wDebitDt = eb.wDebitDt,
            wCancelDebitDt = eb.wCancelDebitDt,
            wCancelDt = eb.wCancelDt,
            wRefNo = eb.wRefNo,
            wRelatedBookingRefNo = NULL,
            wDebitCounterRid = eb.wDebitCounterRid,
            wReqCounterRid = eb.wReqCounterRid,
            wDebitAgentCodeIn = eb.wDebitAgentCodeIn,
            wReqAgentCodeIn = eb.wReqAgentCodeIn,
            wTranvalAgencyName = ta.wName,
            wOrderNo = ci.wOrderNo,
            wPaymentMethod = ci.wPaymentMethod,
            wReceiptNo = ci.wReceiptNo,
            wDepositCost = eb.wDepositAmt,
            wTotalCost = ci.wCost,
            wTotalAmount = 0,
            wDateString = FORMAT(ci.wArrivalTimeToG15nG16, @sDateTimeFormat),
            wQuantity = ci.wQuantity,
            wRouteString = CONCAT(da.wCName, CASE WHEN NULLIF(aa.wCName, '') IS NULL THEN NULL ELSE '->' END, aa.wCName),
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CONCAT(N'行李件數：', CAST(CONVERT(BIGINT, ci.wNoOfBaggage) AS VARCHAR), CHAR(10), 
                            N'貴賓包廂：', CASE WHEN ci.wVIPRoom = 'Y' THEN N'是' ELSE N'否' END, CHAR(10),
                            N'貴賓包廂數量：', 1, CHAR(10),
                            N'坐位要求：', ci.wSeatRequest),
            wCustomer = pd.wCustomer,
            wBookingStatus = ci.wBookingStatus,
            wRemark = ci.wRemark,
            wCancelReasonCd = eb.wCancelReasonCd,
            wOtherReason = eb.wOtherReason,
            wAsstBooker = eb.wAsstBooker,
            wAsstBookerTel = eb.wAssBookerTel,
            wAssBookerEmail = eb.wAsstBookerEmail,
            wDeptFollowedCd = eb.wDeptFollwedCd,
            wStaffFollowedRid = eb.wStaffFollwedRid,
            wApprovalAgentCodeIn = eb.wApprovalAgentCodeIn,
            wEventCodeRid = eb.wEventCodeRid,
            wReqDepartment = eb.wReqDepartment,
            wReqUserRid = eb.wReqUserRid,
            wTravelPkgRid = eb.wTravePkgRid,
            wUseBlackCard = NULL,
            wSameDebitDtCnt = '1',
            wExpCategory = NULL,
            wCrtDt = ci.wCrtDt,
            wBookingRid = eb.RowID,
            wBookingDtlRid = -1,
            wHotelChangeRid = -1
        FROM dbo.eBookingCheckInService AS ci
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'CHK_IN_SVC' AND ci.wStatus = 'A' AND eb.RowID = ci.wBookingRid
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.RowID = ci.wSupplier
        LEFT JOIN dbo.mAirport AS da ON da.RowID =ci.wDepartAirport
        LEFT JOIN dbo.mAirport AS aa ON aa.RowID = ci.wDestination
        LEFT JOIN #tCIPassenger AS pd ON pd.wBookingRid = eb.RowID
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((ci.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt))) --只有完成、退款狀態才有射數
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))

        IF OBJECT_ID('tempdb..#tCIPassenger') IS NOT NULL
            DROP TABLE #tCIPassenger;
    END;

    -- 機場服務 --
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @tmpBookingType WHERE wBookingType = 'PickUp_SERVICE')
    BEGIN
        -- 客戶
        SELECT
            rpd.wBookingRid,
            wCustomer = STUFF(
                (SELECT CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN p.wEName ELSE p.wCName END, CASE WHEN NULLIF(ptd.wEnglishPinyin, '') IS NULL THEN NULL ELSE ' (' + ptd.wEnglishPinyin + ')' END)
                From dbo.ePassengerDetails AS spd
                INNER JOIN dbo.mPerson AS p ON p.RowID = spd.wPersonRid
                LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON spd.RowID = ptdd.wPassengerDetailsRid
                LEFT JOIN dbo.mPersonTravelDoc AS ptd ON ptdd.wPersonTravelDocRid = ptd.RowID
                WHERE spd.wBookingRid = rpd.wBookingRid AND spd.wStatus = 'A' AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = spd.RowID)
                FOR XML PATH('')), 1, 1, N'')
        INTO #tPickupPassenger
        FROM dbo.eBookingPickUpService AS pickup
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'PickUp_SERVICE' AND pickup.wStatus = 'A' AND eb.RowID = pickup.wBookingRid
        INNER JOIN dbo.ePassengerDetails AS rpd ON rpd.wBookingRid > 0 AND rpd.wStatus = 'A' AND rpd.wBookingRid = pickup.wBookingRid
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((pickup.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        GROUP BY rpd.wBookingRid

        INSERT INTO #tmpResult (
            wBookingType,
            wDebitDt,
            wCancelDebitDt,
            wCancelDt,
            wRefNo,
            wRelatedBookingRefNo,
            wDebitCounterRid,
            wReqCounterRid,
            wDebitAgentCodeIn,
            wReqAgentCodeIn,
            wTranvalAgencyName,
            wOrderNo,
            wPaymentMethod,
            wReceiptNo,
            wDepositCost,
            wTotalCost,
            wTotalAmount,
            wDateString,
            wQuantity,
            wRouteString,
            wTicketType,
            wHotel,
            wDetail,
            wCustomer,
            wBookingStatus,
            wRemark,
            wCancelReasonCd,
            wOtherReason,
            wAsstBooker,
            wAsstBookerTel,
            wAssBookerEmail,
            wDeptFollowedCd,
            wStaffFollowedRid,
            wApprovalAgentCodeIn,
            wEventCodeRid,
            wReqDepartment,
            wReqUserRid,
            wTravelPkgRid,
            wUseBlackCard,
            wSameDebitDtCnt,
            wExpCategory,
            wCrtDt,
            wBookingRid,
            wBookingDtlRid,
            wHotelChangeRid
        )
        SELECT
            wBookingType = eb.wBookingType,
            wDebitDt = eb.wDebitDt,
            wCancelDebitDt = eb.wCancelDebitDt,
            wCancelDt = eb.wCancelDt,
            wRefNo = eb.wRefNo,
            wRelatedBookingRefNo = NULL,
            wDebitCounterRid = eb.wDebitCounterRid,
            wReqCounterRid = eb.wReqCounterRid,
            wDebitAgentCodeIn = eb.wDebitAgentCodeIn,
            wReqAgentCodeIn = eb.wReqAgentCodeIn,
            wTranvalAgencyName = ta.wName,
            wOrderNo = pickup.wOrderNo,
            wPaymentMethod = pickup.wPaymentMethod,
            wReceiptNo = pickup.wReceiptNo,
            wDepositCost = eb.wDepositAmt,
            wTotalCost = pickup.wTotalCost,
            wTotalAmount = 0,
            wDateString = FORMAT(pickup.wApplyDt, @sDateTimeFormat),
            wQuantity = 1,
            wRouteString = CONCAT(da.wCName, CASE WHEN NULLIF(aa.wCName, '') IS NULL THEN NULL ELSE '->' END, aa.wCName),
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CONCAT(N'服務類型：', CASE pickup.wServiceType WHEN 'PU' THEN N'接機' WHEN 'DO' Then N'送機' WHEN 'EC' THEN N'快速通關' ELSE NULL END, CHAR(10),
                             N'顯示名稱：', pickup.wDisplayName),
            wCustomer = pd.wCustomer,
            wBookingStatus = pickup.wBookingStatus,
            wRemark = pickup.wRemark,
            wCancelReasonCd = eb.wCancelReasonCd,
            wOtherReason = eb.wOtherReason,
            wAsstBooker = eb.wAsstBooker,
            wAsstBookerTel = eb.wAssBookerTel,
            wAssBookerEmail = eb.wAsstBookerEmail,
            wDeptFollowedCd = eb.wDeptFollwedCd,
            wStaffFollowedRid = eb.wStaffFollwedRid,
            wApprovalAgentCodeIn = eb.wApprovalAgentCodeIn,
            wEventCodeRid = eb.wEventCodeRid,
            wReqDepartment = eb.wReqDepartment,
            wReqUserRid = eb.wReqUserRid,
            wTravelPkgRid = eb.wTravePkgRid,
            wUseBlackCard = pickup.wUseBlackCard,
            wSameDebitDtCnt = '1',
            wExpCategory = NULL,
            wCrtDt = pickup.wCrtDt,
            wBookingRid = eb.RowID,
            wBookingDtlRid = -1,
            wHotelChangeRid = -1
        FROM dbo.eBookingPickUpService AS pickup
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'PickUp_SERVICE' AND pickup.wStatus = 'A' AND eb.RowID = pickup.wBookingRid
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.RowID = pickup.wTravelAgencyRid
        LEFT JOIN #tPickupPassenger AS pd ON pd.wBookingRid = eb.RowID
        LEFT JOIN dbo.mAirport AS da ON da.RowID =pickup.wDepartAirport
        LEFT JOIN dbo.mAirport AS aa ON aa.RowID = pickup.wDestination
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((pickup.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))

        IF OBJECT_ID('tempdb..#tPickupPassenger') IS NOT NULL
            DROP TABLE #tPickupPassenger;	
    END;

    -- 其他消費
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @tmpBookingType WHERE wBookingType = 'ADDITIONALEXPENSES')
    BEGIN
        -- 消费类型
        SELECT wCode, wTitle INTO #tExpCategory FROM dbo.mLookUp WHERE wLangCd = @pLangCd AND wType = 'EXPENSE_CATEGORY'

        INSERT INTO #tmpResult (
            wBookingType,
            wDebitDt,
            wCancelDebitDt,
            wCancelDt,
            wRefNo,
            wRelatedBookingRefNo,
            wDebitCounterRid,
            wReqCounterRid,
            wDebitAgentCodeIn,
            wReqAgentCodeIn,
            wTranvalAgencyName,
            wOrderNo,
            wPaymentMethod,
            wReceiptNo,
            wDepositCost,
            wTotalCost,
            wTotalAmount,
            wDateString,
            wQuantity,
            wRouteString,
            wTicketType,
            wHotel,
            wDetail,
            wCustomer,
            wBookingStatus,
            wRemark,
            wCancelReasonCd,
            wOtherReason,
            wAsstBooker,
            wAsstBookerTel,
            wAssBookerEmail,
            wDeptFollowedCd,
            wStaffFollowedRid,
            wApprovalAgentCodeIn,
            wEventCodeRid,
            wReqDepartment,
            wReqUserRid,
            wTravelPkgRid,
            wUseBlackCard,
            wSameDebitDtCnt,
            wExpCategory,
            wCrtDt,
            wBookingRid,
            wBookingDtlRid,
            wHotelChangeRid
        )
        SELECT
            wBookingType = eb.wBookingType,
            wDebitDt = eb.wDebitDt,
            wCancelDebitDt = eb.wCancelDebitDt,
            wCancelDt = eb.wCancelDt,
            wRefNo = eb.wRefNo,
            wRelatedBookingRefNo = b.wRefNo,
            wDebitCounterRid = eb.wDebitCounterRid,
            wReqCounterRid = eb.wReqCounterRid,
            wDebitAgentCodeIn = eb.wDebitAgentCodeIn,
            wReqAgentCodeIn = eb.wReqAgentCodeIn,
            wTranvalAgencyName = ta.wName,
            wOrderNo = ae.wOrderNo,
            wPaymentMethod = ae.wPaymentMethod,
            wReceiptNo = ae.wReceiptNo,
            wDepositCost = eb.wDepositAmt,
            wTotalCost = ae.wCost,
            wTotalAmount = ae.wTotalAmt, -- 其他消费可以是负值，射数正负使用，其他预订都为0
            wDateString = NULL,
            wQuantity = 1,
            wRouteString = NULL,
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CONCAT(CASE WHEN NULLIF(et.wName, '') IS NULL THEN NULL ELSE CONCAT(N'消費類型：', et.wName, CHAR(10)) END, 
                        CASE WHEN NULLIF(est.wName, '') IS NULL THEN NULL ELSE CONCAT(N'消費副類型：', est.wName, CHAR(10)) END,
                        CASE WHEN NULLIF(mr.wName, '') IS NULL THEN NULL ELSE CONCAT(N'餐廳：', mr.wName) END),
            wCustomer = NULL,
            wBookingStatus = ae.wBookingStatus,
            wRemark = ae.wRemark,
            wCancelReasonCd = eb.wCancelReasonCd,
            wOtherReason = eb.wOtherReason,
            wAsstBooker = eb.wAsstBooker,
            wAsstBookerTel = eb.wAssBookerTel,
            wAssBookerEmail = eb.wAsstBookerEmail,
            wDeptFollowedCd = eb.wDeptFollwedCd,
            wStaffFollowedRid = eb.wStaffFollwedRid,
            wApprovalAgentCodeIn = eb.wApprovalAgentCodeIn,
            wEventCodeRid = eb.wEventCodeRid,
            wReqDepartment = eb.wReqDepartment,
            wReqUserRid = eb.wReqUserRid,
            wTravelPkgRid = eb.wTravePkgRid,
            wUseBlackCard = ae.wIsUseBlackCard,
            wSameDebitDtCnt = '1',
            wExpCategory = ISNULL(esc.wTitle, ec.wTitle), -- 其他消费【消费类型】特殊处理，取Booking的消費類型及消費副類型
            wCrtDt = ae.wCrtDt,
            wBookingRid = eb.RowID,
            wBookingDtlRid = -1,
            wHotelChangeRid = -1
        FROM dbo.eAdditionalExpense AS ae
        INNER JOIN dbo.eBooking  AS eb ON eb.wBookingType = 'ADDITIONALEXPENSES' AND ae.wStatus = 'A' AND eb.RowID = ae.wBookingRefRid  --自己本身
        LEFT JOIN dbo.eBooking AS b ON ae.wBookingRefRid != ae.wBookingRid AND b.RowID = ae.wBookingRid	--相關訂務
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.RowID = ae.wTravelAgencyRid
        LEFT JOIN dbo.mRestaurant AS mr ON mr.RowID = ae.wRestaurantRid
        LEFT JOIN dbo.mExpenseType AS et ON et.RowID = ae.wExpenseType
        LEFT JOIN dbo.mExpenseSubtype AS est ON est.RowID = ae.wExpenseSubtype AND est.wExpenseTypeId = et.RowID
        LEFT JOIN #tExpCategory AS ec ON ec.wCode = et.wExpCat
        LEFT JOIN #tExpCategory AS esc ON esc.wCode = est.wExpCat
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((ae.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))

        IF OBJECT_ID('tempdb..#tExpCategory') IS NOT NULL
            DROP TABLE #tExpCategory;
    END;

    -- 門票
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @tmpBookingType WHERE wBookingType = 'SHOWTICKET')
    BEGIN
        -- 預訂門票
        SELECT
            rst.wBookingShowRid,
            wTicket = STUFF(
                (SELECT CONCAT(N', ', price.wTicketType, '-', CAST(sst.wQuantity AS VARCHAR), N'張')
                From dbo.eBookingShowTicket AS sst
                INNER JOIN dbo.mShowTicketPrice AS price ON sst.wQuantity > 0 AND sst.wBookingShowRid = rst.wBookingShowRid AND price.RowID = sst.wShowTicketPriceRid
                FOR XML PATH('')), 1, 2, N'')
        INTO #tShowTicket
        FROM dbo.eBookingShow AS show
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'SHOWTICKET' AND show.wStatus = 'A' AND eb.RowID = show.wBookingRid
        INNER JOIN dbo.eBookingShowTicket AS rst ON rst.wBookingShowRid = show.RowID
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((show.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        GROUP BY rst.wBookingShowRid

        INSERT INTO #tmpResult (
            wBookingType,
            wDebitDt,
            wCancelDebitDt,
            wCancelDt,
            wRefNo,
            wRelatedBookingRefNo,
            wDebitCounterRid,
            wReqCounterRid,
            wDebitAgentCodeIn,
            wReqAgentCodeIn,
            wTranvalAgencyName,
            wOrderNo,
            wPaymentMethod,
            wReceiptNo,
            wDepositCost,
            wTotalCost,
            wTotalAmount,
            wDateString,
            wQuantity,
            wRouteString,
            wTicketType,
            wHotel,
            wDetail,
            wCustomer,
            wBookingStatus,
            wRemark,
            wCancelReasonCd,
            wOtherReason,
            wAsstBooker,
            wAsstBookerTel,
            wAssBookerEmail,
            wDeptFollowedCd,
            wStaffFollowedRid,
            wApprovalAgentCodeIn,
            wEventCodeRid,
            wReqDepartment,
            wReqUserRid,
            wTravelPkgRid,
            wUseBlackCard,
            wSameDebitDtCnt,
            wExpCategory,
            wCrtDt,
            wBookingRid,
            wBookingDtlRid,
            wHotelChangeRid
        )
        SELECT
            wBookingType = eb.wBookingType,
            wDebitDt = eb.wDebitDt,
            wCancelDebitDt = eb.wCancelDebitDt,
            wCancelDt = eb.wCancelDt,
            wRefNo = eb.wRefNo,
            wRelatedBookingRefNo = NULL,
            wDebitCounterRid = eb.wDebitCounterRid,
            wReqCounterRid = eb.wReqCounterRid,
            wDebitAgentCodeIn = eb.wDebitAgentCodeIn,
            wReqAgentCodeIn = eb.wReqAgentCodeIn,
            wTranvalAgencyName = ta.wName,
            wOrderNo = show.wOrderNo,
            wPaymentMethod = show.wPaymentMethod,
            wReceiptNo = show.wReceiptNo,
            wDepositCost = eb.wDepositAmt,
            wTotalCost = show.wTotalCost,
            wTotalAmount = 0,
            wDateString = FORMAT(show.wShowDt, @sDateTimeFormat),
            wQuantity = show.wTotalQuantity,
            wRouteString = NULL,
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CONCAT(CASE WHEN NULLIF(ms.wName, '') IS NULL THEN NULL ELSE N'表演：' + ms.wName + CHAR(10) END,
                             CASE WHEN NULLIF(st.wTicket, '') IS NULL THEN NULL ELSE N' 區域：' + st.wTicket END ),
            wCustomer = NULL,
            wBookingStatus = show.wBookingStatus,
            wRemark = show.wRemark,
            wCancelReasonCd = eb.wCancelReasonCd,
            wOtherReason = eb.wOtherReason,
            wAsstBooker = eb.wAsstBooker,
            wAsstBookerTel = eb.wAssBookerTel,
            wAssBookerEmail = eb.wAsstBookerEmail,
            wDeptFollowedCd = eb.wDeptFollwedCd,
            wStaffFollowedRid = eb.wStaffFollwedRid,
            wApprovalAgentCodeIn = eb.wApprovalAgentCodeIn,
            wEventCodeRid = eb.wEventCodeRid,
            wReqDepartment = eb.wReqDepartment,
            wReqUserRid = eb.wReqUserRid,
            wTravelPkgRid = eb.wTravePkgRid,
            wUseBlackCard = show.wUseBlackCard,
            wSameDebitDtCnt = '1',
            wExpCategory = NULL,
            wCrtDt = show.wCrtDt,
            wBookingRid = eb.RowID,
            wBookingDtlRid = -1,
            wHotelChangeRid = -1
        FROM dbo.eBookingShow AS show
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'SHOWTICKET' AND show.wStatus = 'A' AND eb.RowID = show.wBookingRid
        LEFT JOIN dbo.mShow AS ms ON ms.RowID = show.wShowRid
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.wIsShowTic = 'Y' AND ta.RowID = show.wTravelAgencyRid
        LEFT JOIN #tShowTicket AS st ON st.wBookingShowRid = show.RowID
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((show.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))

        IF OBJECT_ID('tempdb..#tShowTicket') IS NOT NULL
            DROP TABLE #tShowTicket;
    END;
    
    -- 旅遊套票 --
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @tmpBookingType WHERE wBookingType = 'TRAVEL_PACKAGE')
    BEGIN
        -- 城市
        SELECT wCode, wTitle INTO #tPkgCity FROM dbo.mLookUp WHERE wLangCd = @pLangCd AND wType = 'CITY'

        -- 客戶
        SELECT
            rpd.wBookingRid,
            wCustomer = STUFF(
                (SELECT CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN p.wEName ELSE p.wCName END, CASE WHEN NULLIF(ptd.wEnglishPinyin, '') IS NULL THEN NULL ELSE ' (' + ptd.wEnglishPinyin + ')' END)
                From dbo.ePassengerDetails AS spd
                INNER JOIN dbo.mPerson AS p ON p.RowID = spd.wPersonRid
                LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON spd.RowID = ptdd.wPassengerDetailsRid
                LEFT JOIN dbo.mPersonTravelDoc ptd ON ptdd.wPersonTravelDocRid = ptd.RowID
                WHERE spd.wBookingRid = rpd.wBookingRid AND spd.wStatus = 'A' AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = spd.RowID)
                FOR XML PATH('')), 1, 1, N'')
        INTO #tPkgPassenger
        FROM dbo.eBookingTravelPackage AS pkg
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = pkg.wBookingRid
        INNER JOIN dbo.ePassengerDetails AS rpd ON rpd.wBookingRid > 0 AND rpd.wStatus = 'A' AND rpd.wBookingRid = pkg.wBookingRid
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((pkg.wBookingStatus IN ('C', 'CI', 'CO', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        GROUP BY rpd.wBookingRid

        -- 旅遊套票預訂類型
        SELECT 
            b.wTravePkgRid,
            wBookingTitle = STUFF(
            (SELECT
                CONCAT(N', ',dbo.fnGetBookingTypeName(wBookingType)) 
            FROM dbo.eBooking
            WHERE wTravePkgRid = b.wTravePkgRid
            FOR XML PATH('')), 1, 2, N'')
        INTO #tPkgBookingType
        FROM dbo.eBookingTravelPackage AS pkg
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = pkg.wBookingRid
        INNER JOIN dbo.eBooking AS b ON b.wTravePkgRid = pkg.RowID
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((pkg.wBookingStatus IN ('C', 'CI', 'CO', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        GROUP BY b.wTravePkgRid
        
        INSERT INTO #tmpResult (
            wBookingType,
            wDebitDt,
            wCancelDebitDt,
            wCancelDt,
            wRefNo,
            wRelatedBookingRefNo,
            wDebitCounterRid,
            wReqCounterRid,
            wDebitAgentCodeIn,
            wReqAgentCodeIn,
            wTranvalAgencyName,
            wOrderNo,
            wPaymentMethod,
            wReceiptNo,
            wDepositCost,
            wTotalCost,
            wTotalAmount,
            wDateString,
            wQuantity,
            wRouteString,
            wTicketType,
            wHotel,
            wDetail,
            wCustomer,
            wBookingStatus,
            wRemark,
            wCancelReasonCd,
            wOtherReason,
            wAsstBooker,
            wAsstBookerTel,
            wAssBookerEmail,
            wDeptFollowedCd,
            wStaffFollowedRid,
            wApprovalAgentCodeIn,
            wEventCodeRid,
            wReqDepartment,
            wReqUserRid,
            wTravelPkgRid,
            wUseBlackCard,
            wSameDebitDtCnt,
            wExpCategory,
            wCrtDt,
            wBookingRid,
            wBookingDtlRid,
            wHotelChangeRid
        )
        SELECT
            wBookingType = eb.wBookingType,
            wDebitDt = eb.wDebitDt,
            wCancelDebitDt = eb.wCancelDebitDt,
            wCancelDt = eb.wCancelDt,
            wRefNo = eb.wRefNo,
            wRelatedBookingRefNo = NULL,
            wDebitCounterRid = eb.wDebitCounterRid,
            wReqCounterRid = eb.wReqCounterRid,
            wDebitAgentCodeIn = eb.wDebitAgentCodeIn,
            wReqAgentCodeIn = eb.wReqAgentCodeIn,
            wTranvalAgencyName = ta.wName,
            wOrderNo = pkg.wOrderNo,
            wPaymentMethod = pkg.wPaymentMethod,
            wReceiptNo = pkg.wReceiptNo,
            wDepositCost = eb.wDepositAmt,
            wTotalCost = pkg.wTotalCost,
            wTotalAmount = 0,
            wDateString = CONCAT(N'出發日期：', FORMAT(pkg.wStartDt, @sDateFormat), ', ', N'結束日期：', FORMAT(pkg.wEndDt, @sDateFormat)),
            wQuantity = 1,
            wRouteString = NULL,
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CONCAT(CASE WHEN NULLIF(dept.wTitle, '') IS NULL THEN NULL ELSE N'出發城市：' + dept.wTitle + CHAR(10) END, 
                            CASE WHEN NULLIF(dest.wTitle, '') IS NULL THEN NULL ELSE N'目的地：' + dest.wTitle + CHAR(10) END,  
                            CASE WHEN NULLIF(bType.wBookingTitle, '') IS NULL THEN NULL ELSE N'預訂項目：' + bType.wBookingTitle END),
            wCustomer = pd.wCustomer,
            wBookingStatus = pkg.wBookingStatus,
            wRemark = pkg.wRemark,
            wCancelReasonCd = eb.wCancelReasonCd,
            wOtherReason = eb.wOtherReason,
            wAsstBooker = eb.wAsstBooker,
            wAsstBookerTel = eb.wAssBookerTel,
            wAssBookerEmail = eb.wAsstBookerEmail,
            wDeptFollowedCd = eb.wDeptFollwedCd,
            wStaffFollowedRid = eb.wStaffFollwedRid,
            wApprovalAgentCodeIn = eb.wApprovalAgentCodeIn,
            wEventCodeRid = eb.wEventCodeRid,
            wReqDepartment = eb.wReqDepartment,
            wReqUserRid = eb.wReqUserRid,
            wTravelPkgRid = eb.wTravePkgRid,
            wUseBlackCard = NULL,
            wSameDebitDtCnt = '1',
            wExpCategory = NULL,
            wCrtDt = pkg.wCrtDt,
            wBookingRid = eb.RowID,
            wBookingDtlRid = -1,
            wHotelChangeRid = -1
        FROM dbo.eBookingTravelPackage AS pkg
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'TRAVEL_PACKAGE' AND pkg.wStatus = 'A' AND eb.RowID = pkg.wBookingRid
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.wIsTravelPac = 'Y' AND ta.RowID = pkg.wTravelAgencyRid
        LEFT JOIN #tPkgPassenger AS pd ON pd.wBookingRid = eb.RowID
        LEFT JOIN #tPkgCity AS dept ON dept.wCode = pkg.wDeptCd
        LEFT JOIN #tPkgCity AS dest ON dest.wCode = pkg.wDestCd
        LEFT JOIN #tPkgBookingType AS bType ON pkg.RowID = bType.wTravePkgRid
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((pkg.wBookingStatus IN ('C', 'CI', 'CO', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))

        IF OBJECT_ID('tempdb..#tPkgCity') IS NOT NULL
            DROP TABLE #tPkgCity;

        IF OBJECT_ID('tempdb..#tPkgPassenger') IS NOT NULL
            DROP TABLE #tPkgPassenger;

        IF OBJECT_ID('tempdb..#tPkgBookingType') IS NOT NULL
            DROP TABLE #tPkgBookingType;
    END;

    -- 私人飛機 --
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @tmpBookingType WHERE wBookingType = 'PP')
    BEGIN
        -- 客戶
        SELECT
            rpd.wBookingRid,
            wCustomer = STUFF(
                (SELECT CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN p.wEName ELSE p.wCName END, CASE WHEN NULLIF(ptd.wEnglishPinyin, '') IS NULL THEN NULL ELSE ' (' + ptd.wEnglishPinyin + ')' END)
                From dbo.ePassengerDetails AS spd
                INNER JOIN dbo.mPerson AS p ON p.RowID = spd.wPersonRid
                LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON spd.RowID = ptdd.wPassengerDetailsRid
                LEFT JOIN dbo.mPersonTravelDoc ptd ON ptdd.wPersonTravelDocRid = ptd.RowID
                WHERE spd.wBookingRid = rpd.wBookingRid AND spd.wStatus = 'A' AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = spd.RowID)
                FOR XML PATH('')), 1, 1, N'')
        INTO #tPPPassenger
        FROM dbo.eBookingPrivatePlane AS pp
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'PP' AND pp.wStatus = 'A' AND eb.RowID = pp.wBookingRid
        INNER JOIN dbo.ePassengerDetails AS rpd ON rpd.wBookingRid > 0 AND rpd.wStatus = 'A' AND rpd.wBookingRid = pp.wBookingRid
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((pp.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        GROUP BY rpd.wBookingRid

        -- 私人飛機航線
        SELECT 
            rpprd.wBookingPrivatePlaneRid,
            wRouteTitle = STUFF(
                (SELECT CONCAT(CHAR(10), (CASE WHEN @pLangCd = 'en-GB' THEN da.wEName ELSE da.wCName END), '>', (CASE WHEN @pLangCd = 'en-GB' THEN aa.wEName ELSE aa.wCName END))
                FROM dbo.ePrivatePlaneRouteDtl AS spprd
                LEFT JOIN dbo.mAirport AS da ON da.RowID = spprd.wDepartureAirportRid
                LEFT JOIN dbo.mAirport AS aa ON aa.RowID = spprd.wArrivalAirportRid
                WHERE spprd.wBookingPrivatePlaneRid = rpprd.wBookingPrivatePlaneRid
                FOR XML PATH(''),TYPE).value('text()[1]','nvarchar(max)'), 1, 1, N''),
            wRouteTime = STUFF(
                (SELECT CONCAT(CHAR(10), FORMAT(spprd.wTakeOffDt, @sDateTimeFormat), '>', FORMAT(spprd.wArrivalDt, @sDateTimeFormat))
                FROM dbo.ePrivatePlaneRouteDtl AS spprd
                WHERE spprd.wBookingPrivatePlaneRid = rpprd.wBookingPrivatePlaneRid
                FOR XML PATH(''),TYPE).value('text()[1]','nvarchar(max)'), 1, 1, N'')
        INTO #tPPRoute
        FROM dbo.eBookingPrivatePlane AS pp
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'PP' AND pp.wStatus = 'A' AND eb.RowID = pp.wBookingRid
        INNER JOIN dbo.ePrivatePlaneRouteDtl AS rpprd ON rpprd.wBookingPrivatePlaneRid = pp.RowID
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((pp.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        GROUP BY rpprd.wBookingPrivatePlaneRid

        INSERT INTO #tmpResult (
            wBookingType,
            wDebitDt,
            wCancelDebitDt,
            wCancelDt,
            wRefNo,
            wRelatedBookingRefNo,
            wDebitCounterRid,
            wReqCounterRid,
            wDebitAgentCodeIn,
            wReqAgentCodeIn,
            wTranvalAgencyName,
            wOrderNo,
            wPaymentMethod,
            wReceiptNo,
            wDepositCost,
            wTotalCost,
            wTotalAmount,
            wDateString,
            wQuantity,
            wRouteString,
            wTicketType,
            wHotel,
            wDetail,
            wCustomer,
            wBookingStatus,
            wRemark,
            wCancelReasonCd,
            wOtherReason,
            wAsstBooker,
            wAsstBookerTel,
            wAssBookerEmail,
            wDeptFollowedCd,
            wStaffFollowedRid,
            wApprovalAgentCodeIn,
            wEventCodeRid,
            wReqDepartment,
            wReqUserRid,
            wTravelPkgRid,
            wUseBlackCard,
            wSameDebitDtCnt,
            wExpCategory,
            wCrtDt,
            wBookingRid,
            wBookingDtlRid,
            wHotelChangeRid
        )
        SELECT
            wBookingType = eb.wBookingType,
            wDebitDt = eb.wDebitDt,
            wCancelDebitDt = eb.wCancelDebitDt,
            wCancelDt = eb.wCancelDt,
            wRefNo = eb.wRefNo,
            wRelatedBookingRefNo = NULL,
            wDebitCounterRid = eb.wDebitCounterRid,
            wReqCounterRid = eb.wReqCounterRid,
            wDebitAgentCodeIn = eb.wDebitAgentCodeIn,
            wReqAgentCodeIn = eb.wReqAgentCodeIn,
            wTranvalAgencyName = CASE pp.wSupplier WHEN 'HO' THEN hta.wName ELSE mta.wName END,
            wOrderNo = pp.wOrderNo,
            wPaymentMethod = pp.wPaymentMethod,
            wReceiptNo = pp.wReceiptNo,
            wDepositCost = eb.wDepositAmt,
            wTotalCost = pp.wTotalCost,
            wTotalAmount = 0,
            wDateString = rout.wRouteTime,
            wQuantity = pp.wConfirmPassengerNo,
            wRouteString = rout.wRouteTitle,
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CONCAT(N'預訂類型：', ticketType.wTitle, CHAR(10),
                            N'飛機型號：', pp.wPlaneModel, CHAR(10),
                            N'吸煙：', CASE WHEN pp.wIsSmoking = 'Y' THEN N'是' ELSE N'否' END, CHAR(10),
                            N'語言：', pp.wServiceLang, CHAR(10),
                            N'WIFI：', CASE WHEN pp.wHasWifi = 'Y' THEN N'是' ELSE N'否' END, CHAR(10),
                            N'客服人數：', CAST(pp.wNoOfServiceStaff AS VARCHAR)),
            wCustomer = pd.wCustomer,
            wBookingStatus = pp.wBookingStatus,
            wRemark = pp.wRemark,
            wCancelReasonCd = eb.wCancelReasonCd,
            wOtherReason = eb.wOtherReason,
            wAsstBooker = eb.wAsstBooker,
            wAsstBookerTel = eb.wAssBookerTel,
            wAssBookerEmail = eb.wAsstBookerEmail,
            wDeptFollowedCd = eb.wDeptFollwedCd,
            wStaffFollowedRid = eb.wStaffFollwedRid,
            wApprovalAgentCodeIn = eb.wApprovalAgentCodeIn,
            wEventCodeRid = eb.wEventCodeRid,
            wReqDepartment = eb.wReqDepartment,
            wReqUserRid = eb.wReqUserRid,
            wTravelPkgRid = eb.wTravePkgRid,
            wUseBlackCard = pp.wIsUseBlackCard,
            wSameDebitDtCnt = '1',
            wExpCategory = NULL,
            wCrtDt = pp.wCrtDt,
            wBookingRid = eb.RowID,
            wBookingDtlRid = -1,
            wHotelChangeRid = -1
        FROM dbo.eBookingPrivatePlane AS pp
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'PP' AND pp.wStatus = 'A' AND eb.RowID = pp.wBookingRid
        LEFT JOIN dbo.mTravelAgency AS mta ON pp.wSupplier != 'HO' AND wIsPrivatePlane = 'Y' AND mta.RowId = pp.wTravelAgencyRid -- 旅行社代理
        LEFT JOIN dbo.mHotel AS hta ON pp.wSupplier = 'HO' AND hta.RowId = pp.wHotelRid -- 酒店代理
        LEFT JOIN #tPPPassenger AS pd ON pd.wBookingRid = eb.RowID
        LEFT JOIN #tPPRoute AS rout ON rout.wBookingPrivatePlaneRid = pp.RowID
        LEFT JOIN dbo.mLookUp AS ticketType ON ticketType.wLangCd = @pLangCd AND ticketType.wType = 'AIR_TICKET_TYPE' AND ticketType.wCode = pp.wBookingType
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((pp.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        
        IF OBJECT_ID('tempdb..#tPPPassenger') IS NOT NULL
            DROP TABLE #tPPPassenger;

        IF OBJECT_ID('tempdb..#tPPRoute') IS NOT NULL
            DROP TABLE #tPPRoute;
    END;

    -- 導遊服務 --
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @tmpBookingType WHERE wBookingType = 'TOUR')
    BEGIN
        -- 客戶
        SELECT
            rpd.wBookingRid,
            wCustomer = STUFF(
                (SELECT CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN p.wEName ELSE p.wCName END, CASE WHEN NULLIF(ptd.wEnglishPinyin, '') IS NULL THEN NULL ELSE ' (' + ptd.wEnglishPinyin + ')' END)
                From dbo.ePassengerDetails AS spd
                INNER JOIN dbo.mPerson AS p ON p.RowID = spd.wPersonRid
                LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON spd.RowID = ptdd.wPassengerDetailsRid
                LEFT JOIN dbo.mPersonTravelDoc ptd ON ptdd.wPersonTravelDocRid = ptd.RowID
                WHERE spd.wBookingRid = rpd.wBookingRid AND spd.wStatus = 'A' AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = spd.RowID)
                FOR XML PATH('')), 1, 1, N'')
        INTO #tTourPassenger
        FROM dbo.eBookingTourGuide AS tour
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'TOUR' AND tour.wStatus = 'A' AND eb.RowID = tour.wBookingRid
        INNER JOIN dbo.ePassengerDetails AS rpd ON rpd.wBookingRid > 0 AND rpd.wStatus = 'A' AND rpd.wBookingRid = tour.wBookingRid
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((tour.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        GROUP BY rpd.wBookingRid

        INSERT INTO #tmpResult (
            wBookingType,
            wDebitDt,
            wCancelDebitDt,
            wCancelDt,
            wRefNo,
            wRelatedBookingRefNo,
            wDebitCounterRid,
            wReqCounterRid,
            wDebitAgentCodeIn,
            wReqAgentCodeIn,
            wTranvalAgencyName,
            wOrderNo,
            wPaymentMethod,
            wReceiptNo,
            wDepositCost,
            wTotalCost,
            wTotalAmount,
            wDateString,
            wQuantity,
            wRouteString,
            wTicketType,
            wHotel,
            wDetail,
            wCustomer,
            wBookingStatus,
            wRemark,
            wCancelReasonCd,
            wOtherReason,
            wAsstBooker,
            wAsstBookerTel,
            wAssBookerEmail,
            wDeptFollowedCd,
            wStaffFollowedRid,
            wApprovalAgentCodeIn,
            wEventCodeRid,
            wReqDepartment,
            wReqUserRid,
            wTravelPkgRid,
            wUseBlackCard,
            wSameDebitDtCnt,
            wExpCategory,
            wCrtDt,
            wBookingRid,
            wBookingDtlRid,
            wHotelChangeRid
        )
        SELECT
            wBookingType = eb.wBookingType,
            wDebitDt = eb.wDebitDt,
            wCancelDebitDt = eb.wCancelDebitDt,
            wCancelDt = eb.wCancelDt,
            wRefNo = eb.wRefNo,
            wRelatedBookingRefNo = NULL,
            wDebitCounterRid = eb.wDebitCounterRid,
            wReqCounterRid = eb.wReqCounterRid,
            wDebitAgentCodeIn = eb.wDebitAgentCodeIn,
            wReqAgentCodeIn = eb.wReqAgentCodeIn,
            wTranvalAgencyName = ta.wName,
            wOrderNo = tour.wOrderNo,
            wPaymentMethod = tour.wPaymentMethod,
            wReceiptNo = tour.wReceiptNo,
            wDepositCost = eb.wDepositAmt,
            wTotalCost = tour.wCost,
            wTotalAmount = 0,
            wDateString = FORMAT(tour.wStartDt, @sDateTimeFormat), --日期為開始日期
            wQuantity = 1, --數量永遠為1
            wRouteString = NULL,
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CONCAT(N'地區：', region.wTitle, CHAR(10),
                            N'語言：', lang.wTitle, CHAR(10),
                            N'時數：', tour.wPeriod),
            wCustomer = pd.wCustomer,
            wBookingStatus = tour.wBookingStatus,
            wRemark = tour.wRemark,
            wCancelReasonCd = eb.wCancelReasonCd,
            wOtherReason = eb.wOtherReason,
            wAsstBooker = eb.wAsstBooker,
            wAsstBookerTel = eb.wAssBookerTel,
            wAssBookerEmail = eb.wAsstBookerEmail,
            wDeptFollowedCd = eb.wDeptFollwedCd,
            wStaffFollowedRid = eb.wStaffFollwedRid,
            wApprovalAgentCodeIn = eb.wApprovalAgentCodeIn,
            wEventCodeRid = eb.wEventCodeRid,
            wReqDepartment = eb.wReqDepartment,
            wReqUserRid = eb.wReqUserRid,
            wTravelPkgRid = eb.wTravePkgRid,
            wUseBlackCard = tour.wIsUseBlackCard,
            wSameDebitDtCnt = '1',
            wExpCategory = NULL,
            wCrtDt = tour.wCrtDt,
            wBookingRid = eb.RowID,
            wBookingDtlRid = -1,
            wHotelChangeRid = -1
        FROM dbo.eBookingTourGuide AS tour
        INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'TOUR' AND tour.wStatus = 'A' AND eb.RowID = tour.wBookingRid
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.wIsTourGuide = 'Y' AND ta.RowID = tour.wTravelAgencyRid
        LEFT JOIN dbo.mLookUp AS region ON region.wLangCd = @pLangCd AND region.wType = 'REGION' AND region.wCode = tour.wRegion
        LEFT JOIN dbo.mLookUp AS lang ON lang.wLangCd = @pLangCd AND lang.wType = 'SPEAK_LANG' AND lang.wCode = tour.wLang
        LEFT JOIN #tTourPassenger AS pd ON pd.wBookingRid = eb.RowID
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((tour.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))

        IF OBJECT_ID('tempdb..#tTourPassenger') IS NOT NULL
            DROP TABLE #tTourPassenger;
    END;

    -- 射數
    SELECT
        RowID,
        wBookingRid = CAST(ISNULL(NULLIF(wReferId, ''), '-1') AS BIGINT),
        wRefRid,
        wShopName,
        wAmount,
        wAmountActual_CRM,
        wCurDateTime,
        wIsDeposit,
        wDate
    INTO #tExpTran
    FROM RollsMary.dbo.eExpTran WHERE wExpGroup = 'RCRM' AND wDate BETWEEN @pFromDt AND @pToDt;

    -- 射數為0, 射數為0時Join不到記錄，此處取第一條為0的記錄
    SELECT
        RowId = MIN(RowID),
        wBookingRid,
        wRefRid,
        wShopName,
        wAmount = 0,
        wAmountActual_CRM = 0
    INTO #tZeroExpTran
    FROM #tExpTran
    WHERE wIsDeposit != 'Y' AND wAmountActual_CRM = 0 AND wBookingRid > 0
    GROUP BY wBookingRid, wRefRid, wShopName;

    -- 部門
    SELECT DISTINCT 
        wDeptCode = wCode,
        wDeptName = CASE WHEN @pLangCd = 'en-GB' THEN wEName ELSE wCName END
    INTO #tDepartment
    FROM RollsMary.dbo.mDepartment
    WHERE wIsRealDept = 'Y' AND NULLIF(wUserLineGrp, '') IS NULL AND wActive = 'A'

    -- 旅遊套票
    SELECT 
        p.RowID,
        p.wBookingRid,
        b.wRefNo
    INTO #tTravelPkg
    FROM dbo.eBookingTravelPackage p
    INNER JOIN dbo.eBooking b ON b.RowID = p.wBookingRid;

    -- 消費券
    SELECT
        rv.wBookingRid,
        wVoucher = STUFF(
            (SELECT N', ' + CAST(m.wVoucherRefNo AS NVARCHAR)
            From dbo.eVoucher AS sv
            INNER JOIN dbo.mVoucher AS m ON m.RowID = sv.wVoucherRid AND sv.wBookingRid = rv.wBookingRid
            FOR XML PATH('')), 1, 2, N'')
    INTO #tVoucher
    FROM dbo.eVoucher AS rv
    GROUP BY rv.wBookingRid;

    SELECT
        RowId = tmp.RowId,
        wBookingRid = tmp.wBookingRid,
        wBookingTypeCode = tmp.wBookingType,
        wMapBookingStatus = ISNULL(bs.wMapBookingStatus, tmp.wBookingStatus),
        wExpTranRid = et.RowID,
        wCurDateTime = et.wCurDateTime,
        wBookingType = (
            CASE WHEN @pLangCd = 'en-GB' THEN UPPER(tmp.wBookingType)
            ELSE dbo.fnGetBookingTypeName(tmp.wBookingType) END
        ),				-- 消費類型
        tmp.wRefNo,		-- 訂單編號
        tmp.wRelatedBookingRefNo,		-- 相關訂務
        wDebitCounterName = dsc.wName,	-- 扣數場館
        wReqCounterName = rsc.wName,	-- 要求場館
        wDebitAgentCode = aDebit.wAgentCode_Display,
        wDebitAgentName = CASE WHEN @pLangCd = 'en-GB' THEN aDebit.wEName ELSE aDebit.wCName END,	-- 扣數戶口
        wReqAgentCode = aReq.wAgentCode_Display,
        wReqAgentName = CASE WHEN @pLangCd = 'en-GB' THEN aReq.wEName ELSE aReq.wCName END,			-- 要求戶口
        tmp.wTranvalAgencyName,		-- 供應商名稱
        tmp.wOrderNo,				-- 單號
        wPayMethod = (
            CASE tmp.wBookingType
            WHEN 'CHANGEHOTEL' THEN hotelPay.wTitle
            WHEN 'HOTEL' THEN hotelPay.wTitle
            WHEN 'ROOM' THEN hotelPay.wTitle
            Else pay.wTitle END
        ),				-- 付款方式
        tmp.wReceiptNo,	-- 現金單號
        wIsDeposit = ISNULL(et.wIsDeposit, 'N'),
        wTotalCost = CASE WHEN et.wIsDeposit = 'Y' THEN tmp.wDepositCost ELSE (CASE WHEN (et.wAmount < 0 OR et.wAmountActual_CRM < 0 OR bs.wMapBookingStatus = 'RF') AND tmp.wTotalCost > 0 THEN -1 * tmp.wTotalCost ELSE tmp.wTotalCost END) END,	-- 總成本
        tmp.wDateString,		-- 日期
        tmp.wQuantity,			-- 數量
        tmp.wRouteString,		-- 航線
        tmp.wTicketType,		-- 票類型
        tmp.wHotel,				-- 酒店
        wDetail = CASE WHEN NULLIF(ev.wVoucher, '') IS NULL THEN tmp.wDetail ELSE CONCAT(tmp.wDetail, CHAR(10), N'消費券：', ev.wVoucher) END,	-- 明細
        tmp.wCustomer,			-- 客人
        wBookingStatus = (
            CASE tmp.wBookingStatus
            WHEN 'P'	THEN N'處理中'
            WHEN 'CL'	THEN N'取消'
            WHEN 'C'	THEN N'完成'
            WHEN 'RF'	THEN N'已退款'
            WHEN 'UQ'	THEN N'不達標'
            WHEN 'CO'	THEN N'退房'
            WHEN 'CI'	THEN N'已入住'
            ELSE NULL END
        ),						-- 訂單狀態
        tmp.wRemark,			-- 備註
        wCancelReason = CASE tmp.wBookingStatus WHEN 'C' THEN NULL ELSE (CASE WHEN tmp.wCancelReasonCd = '05' THEN tmp.wOtherReason ELSE cancel.wTitle END) END,	-- 取消原因 code
        tmp.wAsstBooker,		-- 代訂人
        tmp.wAsstBookerTel,		-- 代訂人電話
        tmp.wAssBookerEmail,	-- 代訂人電郵
        wDeptFollowedName = dFollow.wDeptName,				-- 跟進部門
        wStaffFollowedName = CASE WHEN @pLangCd = 'en-GB' THEN uFollow.wName ELSE uFollow.wCName END, -- 跟進同事
        wApprovalAgentCode = aApproval.wAgentCode_Display,				-- 確認戶主/授權人
        wApprovalAgentName = CASE WHEN @pLangCd = 'en-GB' THEN aApproval.wEName ELSE aApproval.wCName END,
        wEventCode = CASE WHEN @pLangCd = 'en-GB' THEN code.wEName ELSE code.wCName END,	-- 活動代碼
        wDeptReqName = dReq.wDeptName,				-- 要求部門
        wStaffReqName = CASE WHEN @pLangCd = 'en-GB' THEN uReq.wName ELSE uReq.wCName END,	-- 要求同事
        wTravelPkgRefNo = pkg.wRefNo,				-- 旅遊套票
        wUseBlackCard = (
            CASE tmp.wUseBlackCard
            WHEN 'T' THEN 'Y'
            WHEN 'F' THEN 'N'
            ELSE ISNULL(tmp.wUseBlackCard, 'N')
            END
        ),					-- 黑卡?
        wSameDebitDtCnt = CASE WHEN et.wIsDeposit = 'Y' THEN '1' ELSE tmp.wSameDebitDtCnt END,-- 最終要顯示  '1/wHotelSameDebitDtCnt'
        wDebitDt = ISNULL(et.wDate, CASE WHEN ISNULL(bs.wMapBookingStatus, tmp.wBookingStatus) = 'RF' THEN tmp.wCancelDebitDt ELSE tmp.wDebitDt END),
        wCancelDt = CASE WHEN (tmp.wBookingType IN ('AIRTICKET', 'HELI') AND tmp.wBookingStatus = 'RF') OR bs.wMapBookingStatus = 'RF' THEN tmp.wCancelDt ELSE NULL END,	-- 取消日期
        -- 射數為0，取射數第一條記錄的值
        -- 當射數為0時，Join不到射數值，取第一條射數為0的記錄
        --（目前，如果【完成】、【退款】其中一條射數失敗，最後兩條都會有值【0】，都是【0】影響不大，後面在射數表wBookingStatus賦值后能解決此問題）
        wAmount = ISNULL(et.wAmount, zet.wAmount),
        wAmountActual_CRM = ISNULL(et.wAmountActual_CRM, zet.wAmountActual_CRM ),
        wExpCategory = (
            CASE WHEN @pLangCd = 'en-GB' THEN UPPER(tmp.wBookingType)
            ELSE ( 
                CASE tmp.wBookingType
                WHEN 'ADDITIONALEXPENSES'	THEN tmp.wExpCategory
                WHEN 'HOTEL'				THEN N'住'
                WHEN 'ROOM'					THEN N'住'
                WHEN 'CHANGEHOTEL'			THEN N'住'
                WHEN 'AIRTICKET'			THEN N'行'
                WHEN 'CHK_IN_SVC'			THEN N'行'
                WHEN 'FERRY'				THEN N'行'
                WHEN 'HELI'					THEN N'行'
                WHEN 'LEADING_SERVICE'		THEN N'行'
                WHEN 'PickUp_SERVICE'		THEN N'行'
                WHEN 'PP'					THEN N'行'
                WHEN 'SHOWTICKET'			THEN N'樂'
                WHEN 'TOUR'					THEN N'樂'
                WHEN 'TRAVEL_PACKAGE'		THEN N'樂'
                WHEN 'Visa'					THEN N'樂'
                ELSE UPPER(tmp.wBookingType) END
            ) END
        ),
        tmp.wCrtDt
    INTO #tResult
    FROM #tmpResult tmp
    INNER JOIN RollsMary.dbo.mAgent AS aDebit ON tmp.wDebitAgentCodeIn = aDebit.wAgentCodeIn
    INNER JOIN RollsMary.dbo.mAgent AS aReq ON tmp.wReqAgentCodeIn = aReq.wAgentCodeIn
    LEFT JOIN RollsMary.dbo.mAgent AS aApproval ON aApproval.wAgentCodeIn = tmp.wApprovalAgentCodeIn
    LEFT JOIN dbo.mServiceCounter AS dsc ON tmp.wDebitCounterRid = dsc.RowID
    LEFT JOIN dbo.mServiceCounter AS rsc ON tmp.wReqCounterRid = rsc.RowID
    LEFT JOIN RollsMary.dbo.mUsr uFollow ON tmp.wStaffFollowedRid = uFollow.RowID
    LEFT JOIN RollsMary.dbo.mUsr uReq ON tmp.wReqUserRid = uReq.RowID
    LEFT JOIN dbo.mEventCode AS code ON code.RowID = tmp.wEventCodeRid
    LEFT JOIN #tTravelPkg as pkg ON pkg.RowID = tmp.wTravelPkgRid
    LEFT JOIN #tDepartment AS dFollow ON dFollow.wDeptCode = tmp.wDeptFollowedCd
    LEFT JOIN #tDepartment AS dReq ON dReq.wDeptCode = tmp.wReqDepartment
    LEFT JOIN dbo.mLookUp AS pay ON pay.wLangCd = @pLangCd AND pay.wType = 'PAYMENT_TYPE' AND pay.wCode = tmp.wPaymentMethod
    LEFT JOIN dbo.mLookUp AS hotelPay ON hotelPay.wLangCd = @pLangCd AND hotelPay.wType = 'PAYMENT_TYPE_HOTEL' AND hotelPay.wCode = tmp.wPaymentMethod
    LEFT JOIN dbo.mLookUp AS cancel ON cancel.wLangCd = @pLangCd AND cancel.wType = 'CANCEL_REASON' AND cancel.wCode = tmp.wCancelReasonCd
    LEFT JOIN #tVoucher AS ev ON ev.wBookingRid = tmp.wBookingRid
    LEFT JOIN @tmpBookingStatus AS bs ON tmp.wBookingType NOT IN ('HOTEL', 'ROOM', 'CHANGEHOTEL', 'AIRTICKET', 'HELI') AND bs.wBookingStatus = tmp.wBookingStatus -- 房間預計不進行狀態判斷統計，因為每次都會在eBooking中生成一條新的記錄
    LEFT JOIN #tExpTran AS et ON -- 房间按金 et.wReferId = Hotel.wBookingRid， et.wRefRid = Room.RowId，其他预订: et.wReferId = xx.wBookingRid
            (et.wIsDeposit = 'Y' AND et.wBookingRid = tmp.wBookingRid AND (tmp.wBookingType NOT IN ('HOTEL', 'ROOM', 'CHANGEHOTEL') OR tmp.wBookingDtlRid = et.wRefRid) AND ISNULL(bs.wMapBookingStatus, '') != 'RF') --按金， 退款狀態屬於重複數據（RF --> C、RF），只需要選擇C狀態)
                OR
                (
                    et.wIsDeposit != 'Y'
                    AND et.wBookingRid = tmp.wBookingRid
                    AND (tmp.wBookingDtlRid = -1 OR tmp.wBookingDtlRid = et.wRefRid OR tmp.wBookingType IN ('HOTEL', 'ROOM', 'CHANGEHOTEL'))
                    AND (tmp.wHotelChangeRid = -1 OR CAST(tmp.wHotelChangeRid AS VARCHAR) = et.wShopName)
                    AND ((bs.wMapBookingStatus IS NULL AND tmp.wBookingType IN ('HOTEL', 'ROOM', 'CHANGEHOTEL'))
                        OR (ISNULL(bs.wMapBookingStatus, tmp.wBookingStatus) = 'C' AND ((ISNULL(tmp.wTotalAmount, 0) >= 0 AND et.wAmountActual_CRM > 0) OR (ISNULL(tmp.wTotalAmount, 0) < 0 AND et.wAmountActual_CRM < 0)))	-- 如果Booking中的總值小於0時，【完成】期望射數值小於0，其他情況期望射數值大於0
                            OR (ISNULL(bs.wMapBookingStatus, tmp.wBookingStatus) = 'RF' AND ((ISNULL(tmp.wTotalAmount, 0) >= 0 AND et.wAmountActual_CRM < 0) OR (ISNULL(tmp.wTotalAmount, 0) < 0 AND et.wAmountActual_CRM > 0))))	-- 如果Booking中的總值小於0時，【完成】期望射數值大於0，其他情況期望射數值小於0
                )
    LEFT JOIN #tZeroExpTran AS zet ON zet.wBookingRid = tmp.wBookingRid AND (tmp.wBookingDtlRid = -1 OR tmp.wBookingDtlRid = zet.wRefRid) AND (tmp.wHotelChangeRid = -1 OR CAST(tmp.wHotelChangeRid AS VARCHAR) = zet.wShopName)
    --正確射數，取射數表射數日期
    --只有eBooking.wBookingStatus = 'RF'，wCancelDebitDt不為空
    --如果射數表射數日期、取消扣數日期都為空，取eBooking.wDebitDt
    WHERE ISNULL(et.wDate, CASE WHEN ISNULL(bs.wMapBookingStatus, tmp.wBookingStatus) = 'RF' THEN tmp.wCancelDebitDt ELSE tmp.wDebitDt END) BETWEEN @pFromDt AND @pToDt

    --SELECT * FROM #tmpResult;
    --SELECT * FROM #tExpTran
    --SELECT * FROM #tZeroExpTran
    --SELECT * FROM #tResult;

    --機票、直升機小單合併為一張大單
    SELECT
        RowId = MIN(RowId),
        wMapBookingStatus,
        wTotalCost = SUM(wTotalCost),
        wAmount = SUM(wAmount),
        wAmountActual_CRM = SUM(wAmountActual_CRM)
    INTO #tAirTicketGroup
    FROM #tResult
    WHERE wIsDeposit != 'Y' AND ( wBookingTypeCode = 'AIRTICKET' OR wBookingTypeCode = 'HELI')
    GROUP BY wBookingRid, wMapBookingStatus, wCancelDt

    -- 按金
    SELECT
        RowId = MIN(RowId),
        wExpTranRid
        INTO #tDepositGroup
    FROM #tResult 
    WHERE wIsDeposit = 'Y'
    GROUP BY wExpTranRid

    SELECT
        tmp.wBookingType,				-- 消費類型
        tmp.wRefNo,						-- 訂單編號
        tmp.wRelatedBookingRefNo,		-- 相關訂務
        tmp.wDebitCounterName,			-- 扣數場館
        tmp.wReqCounterName,			-- 要求場館
        tmp.wDebitAgentCode,
        tmp.wDebitAgentName,			-- 扣數戶口
        tmp.wReqAgentCode,
        tmp.wReqAgentName,				-- 要求戶口
        tmp.wTranvalAgencyName,			-- 供應商名稱
        tmp.wOrderNo,					-- 單號
        tmp.wPayMethod,					-- 付款方式
        tmp.wReceiptNo,					-- 現金單號
        tmp.wDateString,				-- 日期
        tmp.wQuantity,					-- 數量
        tmp.wRouteString,				-- 航線
        tmp.wTicketType,				-- 票類型
        tmp.wHotel,						-- 酒店
        tmp.wDetail,					-- 明細
        tmp.wCustomer,					-- 客人
        tmp.wBookingStatus,				-- 訂單狀態
        tmp.wRemark,					-- 備註
        tmp.wCancelReason,				-- 取消原因 code
        tmp.wAsstBooker,				-- 代訂人
        tmp.wAsstBookerTel,				-- 代訂人電話
        tmp.wAssBookerEmail,			-- 代訂人電郵
        tmp.wDeptFollowedName,			-- 跟進部門
        tmp.wStaffFollowedName,			-- 跟進同事
        tmp.wApprovalAgentCode,			-- 確認戶主/授權人
        tmp.wApprovalAgentName,
        tmp.wEventCode,					-- 活動代碼
        tmp.wDeptReqName,				-- 要求部門
        tmp.wStaffReqName,				-- 要求同事
        tmp.wTravelPkgRefNo,			-- 旅遊套票
        tmp.wUseBlackCard,				-- 黑卡?
        tmp.wSameDebitDtCnt,			-- 最終要顯示  '1/wHotelSameDebitDtCnt'
        tmp.wDebitDt,
        tmp.wExpCategory,				-- 消費類型
        tmp.wIsDeposit,					-- 按金
        tmp.wCrtDt,						-- 創建日期
        wTotalCost = CASE WHEN tmp.wIsDeposit = 'Y' THEN tmp.wTotalCost ELSE ISNULL(grlt.wTotalCost, tmp.wTotalCost) END,	-- 總成本
        wAmount = CASE WHEN tmp.wIsDeposit = 'Y' THEN tmp.wAmount ELSE ISNULL(grlt.wAmount, tmp.wAmount) END,				-- 消費額
        wAmountActual_CRM = CASE WHEN tmp.wIsDeposit = 'Y' THEN tmp.wAmountActual_CRM ELSE ISNULL(grlt.wAmountActual_CRM, tmp.wAmountActual_CRM) END	-- 總值
    FROM #tResult AS tmp
    LEFT JOIN #tAirTicketGroup AS grlt ON grlt.RowId = tmp.RowId AND grlt.wMapBookingStatus = tmp.wMapBookingStatus
    LEFT JOIN #tDepositGroup AS drlt ON drlt.RowId = tmp.RowId AND drlt.wExpTranRid = tmp.wExpTranRid
    WHERE (
            tmp.wIsDeposit = 'Y' AND drlt.RowId IS NOT NULL) -- 按金
            OR (tmp.wIsDeposit != 'Y' AND ((tmp.wBookingTypeCode IN ('AIRTICKET', 'HELI') AND grlt.RowId IS NOT NULL) OR (tmp.wBookingTypeCode NOT IN ('AIRTICKET', 'HELI') AND grlt.RowId IS NULL))
          )
    ORDER BY tmp.wBookingTypeCode, 
             tmp.wRefNo, 
             tmp.wDebitDt, 
             tmp.wCurDateTime
    

    --刪除臨時表
    IF OBJECT_ID('tempdb..#tResult') IS NOT NULL BEGIN
        DROP TABLE #tResult;
    END

    IF OBJECT_ID('tempdb..#tAirTicketGroup') IS NOT NULL BEGIN
        DROP TABLE #tAirTicketGroup;
    END

    IF OBJECT_ID('tempdb..#tDepositGroup') IS NOT NULL BEGIN
        DROP TABLE #tDepositGroup;
    END

    IF OBJECT_ID('tempdb..#tmpResult') IS NOT NULL BEGIN
        DROP TABLE #tmpResult;
    END

    IF OBJECT_ID('tempdb..#tExpTran') IS NOT NULL BEGIN
        DROP TABLE #tExpTran;
    END

    IF OBJECT_ID('tempdb..#tZeroExpTran') IS NOT NULL BEGIN
        DROP TABLE #tZeroExpTran;
    END

    IF OBJECT_ID('tempdb..#tDepartment') IS NOT NULL BEGIN
        DROP TABLE #tDepartment;
    END

    IF OBJECT_ID('tempdb..#tTravelPkg') IS NOT NULL BEGIN
        DROP TABLE #tTravelPkg;
    END

    IF OBJECT_ID('tempdb..#tVoucher') IS NOT NULL BEGIN
        DROP TABLE #tVoucher;
    END
END