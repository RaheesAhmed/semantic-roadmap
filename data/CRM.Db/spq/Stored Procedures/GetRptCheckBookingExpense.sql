CREATE PROCEDURE [spq].[GetRptCheckBookingExpense]
    @pAgentCodeIn   VARCHAR(14),
    @pDebitCounter  NVARCHAR(4000),
    @pBookingType   NVARCHAR(4000),
    @pFromDt        DATETIME2(7),
    @pToDt          DATETIME2(7),
    @pLangCd        VARCHAR(10) = 'zh-TW'
AS
BEGIN
    SET NOCOUNT ON;
    IF @@trancount = 0
        SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
    
    ------------------------------------------------------------------------------------------
    -- dbml
    -- DECLARE @vResult TABLE(
    --    wBookingType            NVARCHAR(30),   -- 消費類型
    --    wRefNo                  VARCHAR(30),    -- 訂單編號
    --    wRelatedBookingRefNo    VARCHAR(30),    -- 相關訂務
    --    wDebitCounterName       NVARCHAR(50),   -- 扣數場館
    --    wReqCounterName         NVARCHAR(50),   -- 要求場館
    --    wDebitAgentCode         NVARCHAR(50),   -- 扣數戶口
    --    wDebitAgentName         NVARCHAR(50),   -- 扣數戶口
    --    wReqAgentCode           NVARCHAR(50),   -- 要求戶口
    --    wReqAgentName           NVARCHAR(50),   -- 要求戶口
    --    wTranvalAgencyName      NVARCHAR(100),  -- 供應商名稱
    --    wOrderNo                NVARCHAR(100),  -- 單號
    --    wPayMethod              NVARCHAR(100),  -- 付款方式
    --    wReceiptNo              NVARCHAR(100),  -- 現金單號
    --    wDateString             NVARCHAR(1000), -- 日期
    --    wQuantity               INT,            -- 數量
    --    wRouteString            NVARCHAR(4000), -- 航線
    --    wTicketType             NVARCHAR(100),  -- 票類型
    --    wHotel                  NVARCHAR(500),  -- 酒店
    --    wDetail                 NVARCHAR(4000), -- 明細
    --    wCustomer               NVARCHAR(1000), -- 客人
    --    wBookingStatus          NVARCHAR(10),   -- 訂單狀態
    --    wRemark                 NVARCHAR(4000), -- 備註
    --    wCancelReason           NVARCHAR(200),  -- 取消原因
    --    wAsstBooker             NVARCHAR(100),  -- 代訂人
    --    wAsstBookerTel          NVARCHAR(100),  -- 代訂人電話
    --    wAssBookerEmail         NVARCHAR(100),  -- 代訂人電郵
    --    wFollowedDeptName       NVARCHAR(100),  -- 跟進部門
    --    wFollowedStaffName      NVARCHAR(100),  -- 跟進同事
    --    wApprovalAgentCode      NVARCHAR(100),  -- 確認戶主/授權人
    --    wApprovalAgentName      NVARCHAR(100),  -- 確認戶主/授權人
    --    wEventCode              NVARCHAR(100),  -- 活動代碼
    --    wReqDeptName            NVARCHAR(100),  -- 要求部門
    --    wReqStaffID             VARCHAR(30),    -- 要求同事ID
    --    wReqStaffName           NVARCHAR(50),   -- 要求同事
    --    wTravelPkgRefNo         VARCHAR(30),    -- 旅遊套票
    --    wUseBlackCard           VARCHAR(1),     -- 黑卡
    --    wSameDebitDtCnt         NVARCHAR(10),   -- 最終要顯示  '1/wHotelSameDebitDtCnt'
    --    wDebitDt                DATETIME2(7),   -- 扣數日期/取消扣數日期
    --    wExpCategory            NVARCHAR(5),    -- 消費類型
    --    wIsDeposit              VARCHAR(1),     -- 按金
    --    wCrtDt                  DATETIME2(7),   -- 創建日期
    --    wTotalCost              NUMERIC(18,4),  -- 總成本（按金沒有成本）
    --    wAmount                 NUMERIC(18,4),  -- 消費額
    --    wAmountActual_CRM       NUMERIC(18,4)   -- 總值
    --)
    --SELECT * FROM @vResult;
    ------------------------------------------------------------------------------------------

    DECLARE @sStartDate             DATETIME2(7)    = '1990-01-01',             -- 缺省时最小日期
            @sDateFormat            CHAR(10)        = 'yyyy-MM-dd',
            @sShortDateTimeFormat   CHAR(20)        = 'yyyy-MM-dd HH:mm',
            @sLongDateTimeFormat    CHAR(20)        = 'yyyy-MM-dd HH:mm:00',
            @sDateTimeFormat        CHAR(20)        = 'yyyy-MM-dd HH:mm:ss',
            @sNow                   DATETIME2(7)    = GETDATE();

    -- 空字符串转换为NULL
    -- 空字符串判断（@pAgentCodeIn IS NULL）影响性能
    -- 推荐用@pAgentCodeIn IS NULL
    SET @pAgentCodeIn   = NULLIF(@pAgentCodeIn,   '');
    SET @pDebitCounter  = NULLIF(@pDebitCounter,  '');
    SET @pBookingType   = NULLIF(@pBookingType,   '');
    SET @pLangCd        = ISNULL(NULLIF(@pLangCd, ''),      'zh-TW');
    SET @pFromDt        = FORMAT(ISNULL(@pFromDt, @sNow),   'yyyy-MM-dd 00:00:00');
    SET @pToDt          = FORMAT(ISNULL(@pToDt,   @sNow),   'yyyy-MM-dd 23:59:59');

    -- 扣數櫃台
    DECLARE @vDebitCounter AS TABLE ( RowID BIGINT PRIMARY KEY );
    IF @pDebitCounter IS NOT NULL
    BEGIN
        INSERT INTO @vDebitCounter (RowID)
        SELECT DISTINCT CONVERT(BIGINT, item)
        FROM dbo.fnSplit(@pDebitCounter, ',')
        WHERE NULLIF(item, '') IS NOT NULL
            AND CONVERT(BIGINT, item) > 0;
    END;

    -- 預訂類型
    DECLARE @vBookingType AS TABLE ( wBookingType CHAR(30) PRIMARY KEY );
    IF @pBookingType IS NOT NULL
    BEGIN
        INSERT INTO @vBookingType (wBookingType)
        SELECT DISTINCT item
        FROM dbo.fnSplit(@pBookingType, ',')
        WHERE NULLIF(item, '') IS NOT NULL
    END;

    -- 預訂狀態
    DECLARE @vBookingStatus AS TABLE (
        wBookingStatus      CHAR(2),
        wMapBookingStatus   CHAR(2),
        PRIMARY KEY(wBookingStatus, wMapBookingStatus)
    );
    INSERT INTO @vBookingStatus(wBookingStatus, wMapBookingStatus)
    VALUES 
        ( 'P',	'P'  ),  -- 按金跟狀態無關，預訂
        ( 'CL',	'CL' ),
        ( 'UQ',	'UQ' ),
        ( 'C',	'C'  ),  -- 完成狀態預期會產生一條射數記錄
        ( 'RF',	'C'  ),  -- 退款預期會產生兩條射數記錄（消費、退款）
        ( 'RF',	'RF' );
       
    -- 把預訂先保存到臨時表
    CREATE TABLE #tmpResult (
        RowID                   BIGINT PRIMARY KEY IDENTITY(1, 1),
        wBookingType            NVARCHAR(30),               -- 消費類型
        wDebitDt                DATETIME2(7),	            -- 扣數日期
        wCancelDebitDt          DATETIME2(7),               -- 取消扣數日期
        wCancelDt               DATETIME2(7),               -- 取消日期
        wRefNo                  VARCHAR(30) DEFAULT '',     -- 訂單編號
        wRelatedBookingRefNo    VARCHAR(30) DEFAULT '',     -- 相關訂務
        wDebitCounterRid        BIGINT      DEFAULT 0,      -- 扣數場館
        wReqCounterRid          BIGINT      DEFAULT 0,      -- 要求場館
        wDebitAgentCodeIn       VARCHAR(14),                -- 扣數戶口
        wReqAgentCodeIn         VARCHAR(14),                -- 要求戶口
        wTranvalAgencyName      NVARCHAR(100),              -- 供應商名稱
        wOrderNo                NVARCHAR(100),              -- 單號
        wPaymentMethod          VARCHAR(30),                -- 付款方式
        wReceiptNo              NVARCHAR(100),              -- 現金單號
        wDepositCost            NUMERIC(18, 4),             -- 按金
        wTotalCost              NUMERIC(18, 4),             -- 總成本
        wTotalAmount            NUMERIC(18, 4),             -- 總值
        wDateString             NVARCHAR(4000),             -- 日期
        wQuantity               INT,                        -- 數量
        wRouteString            NVARCHAR(4000),             -- 航線
        wTicketType             NVARCHAR(100),              -- 票類型
        wHotel                  NVARCHAR(500),              -- 酒店
        wDetail                 NVARCHAR(4000),             -- 明細
        wCustomer               NVARCHAR(4000),             -- 客人
        wBookingStatus          VARCHAR(30),                -- 訂單狀態
        wRemark                 NVARCHAR(4000),             -- 備註
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
        wUseBlackCard           NCHAR(1),                   -- 黑卡
        wSameDebitDtCnt         VARCHAR(10),                -- 最終要顯示  '1/wSameDebitDtCnt'
        wExpCategory            NVARCHAR(200),              -- 消費類型 （其他消費的消費類型取Booking的消費類型及消費副類型）
        wCrtDt                  DATETIME2(7),               -- 創建日期
        -- using for joining eExpTran
        wBookingRid             BIGINT      DEFAULT -1,     -- eBooking.RowID
        wBookingDtlRid          BIGINT      DEFAULT -1,     -- Passenger or room
        wHotelChangeRid         BIGINT      DEFAULT -1      -- For hotel
    );

    PRINT CONCAT(N'開始', ' -- ', FORMAT(GETDATE(), @sDateTimeFormat));

    -- 船票
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @vBookingType WHERE wBookingType = 'FERRY')
    BEGIN
        -- 船票航线
        CREATE TABLE #vFerryRoute(
            RowID   BIGINT PRIMARY KEY,
            wTitle  NVARCHAR(200)
        );
        WITH tFerryRoute AS (
            SELECT
                wCode,
                wTitle
            FROM dbo.mLookUp
            WHERE wType = 'FERRY_ROUTE_LOCATION' AND wLangCd = @pLangCd
        )
        INSERT INTO #vFerryRoute( RowID, wTitle) 
        SELECT DISTINCT
            mr.RowID,
            wTitle = CONCAT(_from.wTitle, IIF(mr.wIsTwoWay = 'Y', '<->', '->'), _to.wTitle)
        FROM dbo.mRoute AS mr
        INNER JOIN tFerryRoute AS _from ON _from.wCode = mr.wRouteFrom
        INNER JOIN tFerryRoute AS _to   ON _to.wCode = mr.wRouteTo
        WHERE mr.wVehicle = 'FERRY';
        
        -- 艙等
        CREATE TABLE #vFerryClass(
            wCode   NVARCHAR(50),
            wTitle  NVARCHAR(100),
            PRIMARY KEY(wCode, wTitle)
        );
        INSERT INTO #vFerryClass(wCode, wTitle)
        SELECT DISTINCT
            wCode,
            wTitle
        FROM dbo.mLookUp
        WHERE wType = 'FERRY_CLASS' AND wLangCd = @pLangCd;
        
        -- 船票類型
        CREATE TABLE #vFerryTicketType (
            wCode   NVARCHAR(50),
            wTitle  NVARCHAR(100),
            PRIMARY KEY(wCode, wTitle)
        )
        INSERT INTO #vFerryTicketType(wCode, wTitle)
        SELECT DISTINCT
            wCode,
            wTitle
        FROM dbo.mLookUp
        WHERE wType = 'FERRY_TICKET_TYPE' AND wLangCd = @pLangCd;

        -- 船票URL類型
        CREATE TABLE #vFerryURLType(
            wCode   NVARCHAR(50),
            wTitle  NVARCHAR(100),
            PRIMARY KEY(wCode, wTitle)
        );
        INSERT INTO #vFerryURLType(wCode, wTitle)
        SELECT DISTINCT
            wCode,
            wTitle
        FROM dbo.mLookUp
        WHERE wType = 'FERRY_URL_TYPE' AND wLangCd = @pLangCd;

        -- 船票預訂
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
            wDateString = FORMAT(ferry.wDepartDt, @sLongDateTimeFormat),
            wQuantity = ferry.wQuantity,
            wRouteString = rout.wTitle,
            wTicketType = ftt.wTitle,
            wHotel = NULL,
            wDetail = CONCAT(IIF(fc.wTitle IS NULL, NULL, CONCAT(N'艙等: ', fc.wTitle, CHAR(10))), 
                             N'申請豁免: ', IIF(ferry.wWaived = 'Y', N'是', N'否'), CHAR(10),
                             IIF(furl.wTitle IS NULL, NULL, CONCAT(N'URL類型: ', furl.wTitle, CHAR(10), ferry.wURLAddress))),
            wCustomer = N'',
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
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = ferry.wBookingRid AND eb.wBookingType = 'FERRY' AND ferry.wStatus = 'A'
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.RowID = ferry.wTravelAgencyRid
        LEFT JOIN #vFerryRoute AS rout ON rout.RowID = ferry.wRouteRid
        LEFT JOIN #vFerryClass AS fc ON ferry.wClassCd = fc.wCode
        LEFT JOIN #vFerryTicketType AS ftt ON ftt.wCode = ferry.wTicketType
        LEFT JOIN #vFerryURLType AS furl ON furl.wCode = ferry.wURLType
        LEFT JOIN @vDebitCounter AS dc ON dc.RowID = eb.wDebitCounterRid
        WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = eb.wDebitAgentCodeIn)
            AND (@pDebitCounter IS NULL OR dc.RowID IS NOT NULL)
            AND ((ferry.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (eb.wCancelDebitDt BETWEEN @pFromDt AND @pToDt))) --只有完成、退款狀態才有射數
              OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt)
            )
		OPTION(RECOMPILE);

        -- 客户
        -- 客戶第一個旅行證件（多旅行證件會出現重複數據）
        UPDATE r
        SET wCustomer = STUFF(
            (SELECT CONCAT(CHAR(10), IIF(@pLangCd = 'en-GB', mp.wEName, mp.wCName), IIF(NULLIF(ptd.wEnglishPinyin, '') IS NULL, NULL, ' (' + ptd.wEnglishPinyin + ')'))
            From dbo.ePassengerDetails AS pd
            INNER JOIN dbo.mPerson AS mp ON mp.RowID = pd.wPersonRid
            LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON ptdd.wPassengerDetailsRid = pd.RowID
            LEFT JOIN dbo.mPersonTravelDoc AS ptd ON ptd.RowID = ptdd.wPersonTravelDocRid
            WHERE pd.wStatus = 'A'
                AND pd.wBookingRid = r.wBookingRid
                AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = pd.RowID)
            FOR XML PATH('')), 1, 1, N'')
        FROM #tmpResult r
        WHERE wBookingType = 'FERRY';

        IF OBJECT_ID('tempdb..#vFerryRoute') IS NOT NULL
            DROP TABLE #vFerryRoute;

        IF OBJECT_ID('tempdb..#vFerryClass') IS NOT NULL
            DROP TABLE #vFerryClass;

        IF OBJECT_ID('tempdb..#vFerryTicketType') IS NOT NULL
            DROP TABLE #vFerryTicketType;

        IF OBJECT_ID('tempdb..#vFerryURLType') IS NOT NULL
            DROP TABLE #vFerryURLType;

        PRINT CONCAT( N'船票', ' -- ' ,FORMAT(GETDATE(), @sDateTimeFormat));
    END;

    -- 直升機 --
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @vBookingType WHERE wBookingType = 'HELI')
    BEGIN
        -- 直升機航线
        CREATE TABLE #vHeliRoute(
            RowID   BIGINT PRIMARY KEY,
            wTitle  NVARCHAR(200)
        );
        WITH tHeliRoute AS (
            SELECT
                wCode,
                wTitle
            FROM dbo.mLookUp
            WHERE wType = 'HELICOPTER_ROUTE_LOCATION' AND wLangCd = @pLangCd
        )
        INSERT INTO #vHeliRoute(RowID, wTitle)
        SELECT DISTINCT
            mr.RowID,
            wTitle = CONCAT(_from.wTitle, IIF(mr.wIsTwoWay = 'Y', '<->', '->'), _to.wTitle)
        FROM dbo.mRoute AS mr
        INNER JOIN tHeliRoute AS _from ON _from.wCode = mr.wRouteFrom
        INNER JOIN tHeliRoute AS _to ON _to.wCode = mr.wRouteTo
        WHERE mr.wVehicle = 'HELI';

        -- 旅行社
        CREATE TABLE #vTravelAgency(
            wCode   NVARCHAR(50),
            wTitle  NVARCHAR(100),
            PRIMARY KEY(wCode, wTitle)
        );
        INSERT INTO #vTravelAgency(wCode, wTitle)
        SELECT DISTINCT
            wCode,
            wTitle
        FROM dbo.mLookUp 
        WHERE wType = 'HELICOPTER_BOOKING_LOCATION' AND wLangCd = @pLangCd;
        
        -- 非包机客户（小單扣數日期保存在小單）
        WITH tNCharteredFlightPassenger AS (
            SELECT
                pd.RowID,
                pd.wBookingRid,
                pd.wCancelReasonCd,
                pd.wOtherReason,
                pd.wCancelDebitDt,
                pd.wCancelDt,
                pd.wRouteRid,
                pd.wTakeOffDt,
                pd.wRemark,
                wPassengerBookingStatus = ps.wMapBookingStatus
            FROM dbo.eBookingHeli AS heli
            INNER JOIN dbo.ePassengerDetails AS pd ON pd.wBookingRid = heli.wBookingRid
            INNER JOIN @vBookingStatus AS ps ON ps.wBookingStatus = pd.wPassengerBookingStatus
            WHERE heli.wIsCharteredFlight <> 'Y' AND heli.wStatus = 'A' AND pd.wStatus = 'A'
        )

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
            wCancelDebitDt = IIF(heli.wIsCharteredFlight = 'Y', eb.wCancelDebitDt, pd.wCancelDebitDt),
            wCancelDt = IIF(heli.wIsCharteredFlight = 'Y', eb.wCancelDt, pd.wCancelDt),
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
            wTotalCost = IIF(heli.wIsCharteredFlight = 'Y', heli.wCost, (heli.wCost / NULLIF(ISNULL(heli.wQuantity, 0) , 0))),
            wTotalAmount = 0,
            wDateString = FORMAT(IIF(heli.wIsCharteredFlight != 'Y' AND pd.wPassengerBookingStatus = 'RF' AND pd.wCancelDt != ISNULL(eb.wCancelDt, @sStartDate), pd.wTakeOffDt, heli.wDepartDt), @sLongDateTimeFormat), -- 非包機、非退款，小單的出發時間可能不一樣，此處只能取大單的時間
            wQuantity = heli.wQuantity,
            wRouteString = IIF(pd.wPassengerBookingStatus = 'RF' AND pd.wCancelDt != ISNULL(eb.wCancelDt, @sStartDate) AND pr.wTitle IS NOT NULL, pr.wTitle, hr.wTitle),
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CONCAT(N'包機：', IIF(heli.wIsCharteredFlight = 'Y', N'是', N'否')),
            wCustomer = N'',
            wBookingStatus = IIF(heli.wIsCharteredFlight = 'Y', ps.wMapBookingStatus, pd.wPassengerBookingStatus),
            wRemark = IIF(heli.wIsCharteredFlight != 'Y' AND pd.wPassengerBookingStatus = 'RF' AND pd.wCancelDt != ISNULL(eb.wCancelDt, @sStartDate), pd.wRemark, heli.wRemark),
            wCancelReasonCd = IIF(heli.wIsCharteredFlight = 'Y' OR pd.wCancelDt = eb.wCancelDt, eb.wCancelReasonCd, pd.wCancelReasonCd),
            wOtherReason = IIF(heli.wIsCharteredFlight = 'Y' OR pd.wCancelDt = eb.wCancelDt, eb.wOtherReason, pd.wOtherReason),
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
            wBookingDtlRid = IIF(heli.wIsCharteredFlight = 'Y', -1, pd.RowID), -- 包機不拆分小單
            wHotelChangeRid = -1
        FROM dbo.eBookingHeli AS heli
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = heli.wBookingRid AND eb.wBookingType = 'HELI' AND heli.wStatus = 'A'
        LEFT JOIN tNCharteredFlightPassenger AS pd ON heli.wIsCharteredFlight != 'Y' AND pd.wBookingRid = heli.wBookingRid --非包機，Join小單消費，不Join大單
        LEFT JOIN #vTravelAgency AS ta ON ta.wCode = heli.wBookingLocation
        LEFT JOIN #vHeliRoute AS hr ON hr.RowID = heli.wRouteRid	-- 大單航線
        LEFT JOIN #vHeliRoute AS pr ON pr.RowID = pd.wRouteRid	    -- 小單航線
        LEFT JOIN @vBookingStatus AS ps ON heli.wIsCharteredFlight = 'Y' AND ps.wBookingStatus = heli.wBookingStatus -- 包機，Join大單消費，不Join小單（非包機Join小單）
        LEFT JOIN @vDebitCounter AS dc ON dc.RowID = eb.wDebitCounterRid
        WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = eb.wDebitAgentCodeIn)
            AND (@pDebitCounter IS NULL OR dc.RowID IS NOT NULL)
            AND ((heli.wBookingStatus IN ('C', 'RF') 
                    AND ((ps.wMapBookingStatus = 'C' OR pd.wPassengerBookingStatus = 'C') AND eb.wDebitDt BETWEEN @pFromDt AND @pToDt)
                        OR (ps.wMapBookingStatus = 'RF' AND eb.wCancelDebitDt BETWEEN @pFromDt AND @pToDt)
                        OR (pd.wPassengerBookingStatus = 'RF' AND pd.wCancelDebitDt BETWEEN @pFromDt AND @pToDt))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        OPTION(RECOMPILE);

        -- 包机客户（完成一條數據、退款一條數據，乘客Group埋一齊）
        -- 非包机客户（完成一條，大單退款一條，小單退款多條）
        UPDATE r
        SET wCustomer = IIF(wBookingDtlRid <= 0,
            -- 包機
            STUFF(( SELECT CONCAT(CHAR(10), IIF(@pLangCd = 'en-GB', mp.wEName, mp.wCName), IIF(NULLIF(ptd.wEnglishPinyin, '') IS NULL, NULL, ' (' + ptd.wEnglishPinyin + ')'))
                    From dbo.ePassengerDetails AS pd
                    INNER JOIN dbo.mPerson AS mp ON mp.RowID = pd.wPersonRid
                    LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON ptdd.wPassengerDetailsRid = pd.RowID
                    LEFT JOIN dbo.mPersonTravelDoc AS ptd ON ptd.RowID = ptdd.wPersonTravelDocRid
                    WHERE pd.wStatus = 'A'
                        AND pd.wBookingRid = r.wBookingRid
                        AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = pd.RowID)
                    FOR XML PATH('')), 1, 1, N''),
            -- 非包機
            STUFF(( SELECT CONCAT(CHAR(10), IIF(@pLangCd = 'en-GB', mp.wEName, mp.wCName), IIF(NULLIF(ptd.wEnglishPinyin, '') IS NULL, NULL, ' (' + ptd.wEnglishPinyin + ')'))
                    FROM dbo.ePassengerDetails AS pd
                    INNER JOIN @vBookingStatus AS ps ON ps.wBookingStatus = pd.wPassengerBookingStatus
                    INNER JOIN dbo.mPerson AS mp ON pd.wPersonRid = mp.RowID
                    LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON ptdd.wPassengerDetailsRid = pd.RowID
                    LEFT JOIN dbo.mPersonTravelDoc AS ptd ON ptd.RowID = ptdd.wPersonTravelDocRid
                    WHERE pd.wStatus = 'A'
                        AND pd.wBookingRid = r.wBookingRid
                        AND ps.wMapBookingStatus = r.wBookingStatus
                        AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = pd.RowID)
                        AND (r.wBookingStatus <> 'RF' OR (r.wBookingStatus = 'RF' AND pd.wCancelDt = r.wCancelDt AND pd.wCancelDebitDt BETWEEN @pFromDt AND @pToDt)) -- 非退款，所有乘客Group埋一齊，退款，按退款批次Group埋一齊（在大單一齊退款Group埋一齊，在小單退款獨立分開）
                    FOR XML PATH('')), 1, 1, N''))
        FROM #tmpResult r
        WHERE wBookingType = 'HELI';

        IF OBJECT_ID('tempdb..#vHeliRoute') IS NOT NULL
            DROP TABLE #vHeliRoute;

        IF OBJECT_ID('tempd..#vTravelAgency') IS NOT NULL
            DROP TABLE #vTravelAgency;

        PRINT CONCAT(N'直升機', ' -- ', FORMAT(GETDATE(), @sDateTimeFormat));
    END;

    -- 機票 --
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @vBookingType WHERE wBookingType = 'AIRTICKET')
    BEGIN
        -- 機票類型
        CREATE TABLE #vAirTicketType (
            wCode   NVARCHAR(50),
            wTitle  NVARCHAR(100),
            PRIMARY KEY(wCode, wTitle)
        );
        INSERT INTO #vAirTicketType(wCode, wTitle)
        SELECT DISTINCT
            wCode,
            wTitle
        FROM mLookUp 
        WHERE wType = 'AIR_TICKET_TYPE' AND wLangCd = @pLangCd;

        -- 艙等
        CREATE TABLE #vAirClass(
            wCode   NVARCHAR(50),
            wTitle  NVARCHAR(100),
            PRIMARY KEY(wCode, wTitle)
        );
        INSERT INTO #vAirClass(wCode, wTitle)
        SELECT DISTINCT
            wCode,
            wTitle
        FROM mLookUp 
        WHERE wType = 'AIR_CLASS' AND wLangCd = @pLangCd;

        -- 航線
        CREATE TABLE #vAirLine(
            wCode   NVARCHAR(50),
            wTitle  NVARCHAR(100),
            PRIMARY KEY(wCode, wTitle)
        );
        INSERT INTO #vAirLine(wCode, wTitle)
        SELECT DISTINCT
            wCode,
            wTitle
        FROM mLookUp 
        WHERE wType = 'AIRLINES' AND wLangCd = @pLangCd;

        -- 客戶（小單消費，扣數日期保存在小單，把大單拆成小單，到最後面再根據狀態條件Group埋一齊）
        WITH tAirPassenger AS (
            SELECT
                pd.RowID,
                pd.wBookingRid,
                pd.wCancelReasonCd,
                pd.wOtherReason,
                pd.wCost,
                pd.wCancelDebitDt,
                pd.wCancelDt,
                pd.wRemark,
                wPassengerBookingStatus = ps.wMapBookingStatus
            FROM dbo.eBookingAirTicket air
            INNER JOIN dbo.ePassengerDetails pd ON pd.wBookingRid = air.wBookingRid
            INNER JOIN @vBookingStatus ps ON ps.wBookingStatus = pd.wPassengerBookingStatus
            WHERE air.wStatus = 'A' AND pd.wStatus = 'A'
        )

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
            wDateString = N'',
            wQuantity = air.wQuantity,
            wRouteString = N'',
            wTicketType = air.wFlightType, -- 機票類型（單程、雙程、多程）
            wHotel = NULL,
            wDetail = CONCAT(N'到期日：', CONVERT(CHAR(10), air.wExpiryDt, 20)),
            wCustomer = N'',
            wBookingStatus = ISNULL(pd.wPassengerBookingStatus, air.wBookingStatus),
            wRemark = IIF(pd.wPassengerBookingStatus = 'RF' AND pd.wCancelDt != ISNULL(eb.wCancelDt, @sStartDate), pd.wRemark, air.wRemark),
            wCancelReasonCd = IIF(pd.wCancelDt = eb.wCancelDt, eb.wCancelReasonCd, pd.wCancelReasonCd),
            wOtherReason = IIF(pd.wCancelDt = eb.wCancelDt, eb.wOtherReason, pd.wOtherReason),
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
            wBookingRid = eb.RowID,     -- eBooking.RowID
            wBookingDtlRid = pd.RowID,  -- ePassengerDetail.RowID
            wHotelChangeRid = air.RowID -- eBookingAirTicket.RowID Join航線
        FROM dbo.eBookingAirTicket AS air
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = air.wBookingRid AND eb.wBookingType = 'AIRTICKET' AND air.wStatus = 'A'
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.RowID = air.wTravelAgencyRid
        LEFT JOIN tAirPassenger AS pd ON pd.wBookingRid = air.wBookingRid
        LEFT JOIN @vDebitCounter AS dc ON dc.RowID = eb.wDebitCounterRid 
        WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = eb.wDebitAgentCodeIn)
            AND (@pDebitCounter IS NULL OR dc.RowID IS NOT NULL)
            AND ((pd.wPassengerBookingStatus = 'C' AND eb.wDebitDt BETWEEN @pFromDt AND @pToDt)
              OR (pd.wPassengerBookingStatus = 'RF' AND ISNULL(pd.wCancelDebitDt, eb.wCancelDebitDt) BETWEEN @pFromDt AND @pToDt)
              OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        OPTION(RECOMPILE);
        
        -- 機票航線
        CREATE TABLE #vAirRoute(
            wTypeRid    BIGINT,
            wType       VARCHAR(30),
            wTitle      NVARCHAR(4000),
            wRouteTime  NVARCHAR(4000),
            wFlight     NVARCHAR(4000),
            wAirlines   NVARCHAR(4000),
            PRIMARY KEY(wTypeRid, wType)
        );
        -- 大單航線
        INSERT INTO #vAirRoute(wTypeRid, wType)
        SELECT DISTINCT 
            wTypeRid = r.wHotelChangeRid,
            wType = 'AIRTICKET'
        FROM #tmpResult r
        WHERE r.wHotelChangeRid > 0 AND r.wBookingType = 'AIRTICKET';
        -- 小單航線
        INSERT INTO #vAirRoute(wTypeRid, wType)
        SELECT DISTINCT 
            wTypeRid = r.wBookingDtlRid,
            wType = 'PASSENGER'
        FROM #tmpResult r
        WHERE r.wBookingDtlRid > 0 AND r.wBookingType = 'AIRTICKET';

        UPDATE ar
        SET wTitle = STUFF(
                (SELECT CONCAT(CHAR(10), da.wCName, '->', aa.wCName)
                FROM dbo.eAirTicketRouteDtl AS ard
                INNER JOIN dbo.mAirport AS da ON da.RowID = ard.wDepartureAirportRid
                INNER JOIN dbo.mAirport AS aa ON aa.RowID = ard.wArrivalAirportRid
                WHERE ard.wTypeRid = ar.wTypeRid AND ard.wType = ar.wType AND ard.wStatus = 'A'
                ORDER BY ard.wLine
                FOR XML PATH(''), TYPE).value('text()[1]', 'NVARCHAR(4000)'), 1, 1, N''),
            wRouteTime = STUFF(
                (SELECT CONCAT(CHAR(10), CONVERT(CHAR(16), ard.wTakeOffDt, 20), '->', CONVERT(CHAR(16), ard.wArrivalDt, 20))
                FROM dbo.eAirTicketRouteDtl AS ard
                WHERE ard.wTypeRid = ar.wTypeRid AND ard.wType = ar.wType AND ard.wStatus = 'A'
                ORDER BY ard.wLine
                FOR XML PATH(''), TYPE).value('text()[1]', 'NVARCHAR(4000)'), 1, 1, N''),
            wFlight = STUFF(
                (SELECT CONCAT(CHAR(10), CONCAT(N'第',  CAST(ard.wLine AS VARCHAR), N'程航班：', 
                                                ard.wDepartFlightNo, 
                                                IIF(NULLIF(ard.wDepartFlightNo, '') IS NULL OR NULLIF(ard.wDepartureTerminal, '') IS NULL, NULL, ', '), 
                                                ard.wDepartureTerminal, 
                                                IIF((NULLIF(ard.wDepartFlightNo, '') IS NULL AND NULLIF(ard.wDepartureTerminal, '') IS NULL) OR NULLIF(ac.wTitle, '') IS NULL, NULL, ', '),
                                                IIF(NULLIF(ac.wTitle, '') IS NULL, NULL, ac.wTitle + N'艙')))
                FROM dbo.eAirTicketRouteDtl AS ard
                LEFT JOIN #vAirClass AS ac ON ac.wCode = ard.wClassCd
                WHERE ard.wTypeRid = ar.wTypeRid AND ard.wType = ar.wType AND ard.wStatus = 'A'
                ORDER BY ard.wLine
                FOR XML PATH('')), 1, 1, N''),
            wAirlines = STUFF(
                (SELECT CONCAT(', ', al.wTitle)
                FROM dbo.eAirTicketRouteDtl AS ard
                INNER JOIN #vAirLine al ON al.wCode = ard.wAirline
                WHERE ard.wTypeRid = ar.wTypeRid AND ard.wType = ar.wType AND ard.wStatus = 'A'
                GROUP BY al.wTitle
                FOR XML PATH('')), 1, 2, N'')
        FROM #vAirRoute ar;

        -- 乘客
        SELECT
            r.RowID,
            wCustomer = STUFF(
                (SELECT CONCAT(CHAR(10), IIF(@pLangCd = 'en-GB', mp.wEName, mp.wCName), IIF(NULLIF(ptd.wEnglishPinyin, '') IS NULL, NULL, ' (' + ptd.wEnglishPinyin + ')'))
                FROM dbo.ePassengerDetails AS pd
                INNER JOIN @vBookingStatus AS ps ON ps.wBookingStatus = pd.wPassengerBookingStatus 
                INNER JOIN dbo.mPerson AS mp ON pd.wPersonRid = mp.RowID
                LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON ptdd.wPassengerDetailsRid = pd.RowID
                LEFT JOIN dbo.mPersonTravelDoc AS ptd ON ptd.RowID = ptdd.wPersonTravelDocRid
                WHERE pd.wStatus = 'A'
                    AND pd.wBookingRid = r.wBookingRid 
                    AND ps.wMapBookingStatus = r.wBookingStatus
                    AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = pd.RowID)
                    AND (r.wBookingStatus <> 'RF' OR (r.wBookingStatus = 'RF' AND pd.wCancelDt = r.wCancelDt AND pd.wCancelDebitDt BETWEEN @pFromDt AND @pToDt))
                FOR XML PATH('')), 1, 1, N''),
            wTicketNo = STUFF(
                (SELECT IIF(NULLIF(pd.wClientTicketNo, '') IS NULL, NULL, CONCAT(CHAR(10), IIF(@pLangCd = 'en-GB', mp.wEName, mp.wCName), '(', pd.wClientTicketNo , ') '))
                FROM dbo.ePassengerDetails AS pd
                INNER JOIN @vBookingStatus AS ps ON ps.wBookingStatus = pd.wPassengerBookingStatus 
                INNER JOIN dbo.mPerson AS mp ON pd.wPersonRid = mp.RowID
                WHERE pd.wStatus = 'A'
                    AND pd.wBookingRid = r.wBookingRid 
                    AND ps.wMapBookingStatus = r.wBookingStatus
                    AND (r.wBookingStatus <> 'RF' OR (r.wBookingStatus = 'RF' AND pd.wCancelDt = r.wCancelDt AND pd.wCancelDebitDt BETWEEN @pFromDt AND @pToDt))
                FOR XML PATH('')), 1, 1, N'')
            INTO #vPassenger
            FROM #tmpResult r
            WHERE r.wBookingType = 'AIRTICKET';

        -- update Result
        UPDATE r
        SET wDateString = IIF(r.wBookingStatus = 'RF' AND r.wCancelDt != ISNULL(eb.wCancelDt, @sStartDate) AND pr.wRouteTime IS NOT NULL, pr.wRouteTime, ar.wRouteTime),
            wRouteString = IIF( r.wBookingStatus = 'RF' AND r.wCancelDt != ISNULL(eb.wCancelDt, @sStartDate) AND pr.wTitle IS NOT NULL, pr.wTitle, ar.wTitle),
            wDetail = CONCAT(N'預訂類型：', att.wTitle, char(10), 
                             N'航空公司：', IIF(r.wBookingStatus = 'RF' AND r.wCancelDt != ISNULL(eb.wCancelDt, @sStartDate) AND pr.wAirlines IS NOT NULL,  pr.wAirlines, ar.wAirlines), char(10), 
                             r.wDetail, char(10),
                             IIF(r.wBookingStatus = 'RF' AND r.wCancelDt != ISNULL(eb.wCancelDt, @sStartDate) AND pr.wFlight IS NOT NULL, pr.wFlight, ar.wFlight), char(10),
                             N'票號：', pd.wTicketNo
                            ),
            wCustomer = pd.wCustomer,
            wTicketType = NULL,
            wHotelChangeRid = -1
        FROM #tmpResult r
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = r.wBookingRid
        LEFT JOIN #vAirRoute AS ar ON ar.wTypeRid = r.wHotelChangeRid AND ar.wType = 'AIRTICKET' -- 大单
        LEFT JOIN #vAirRoute AS pr ON  pr.wTypeRid = r.wBookingDtlRid AND pr.wType = 'PASSENGER' -- 小单
        LEFT JOIN #vPassenger AS pd ON pd.RowID = r.RowID
        LEFT JOIN #vAirTicketType AS att ON att.wCode = r.wTicketType
        WHERE r.wBookingType = 'AIRTICKET';
        
        IF OBJECT_ID('tempdb..#vAirTicketType') IS NOT NULL
            DROP TABLE #vAirTicketType;

        IF OBJECT_ID('tempdb..#vAirClass') IS NOT NULL
            DROP TABLE #vAirClass;

        IF OBJECT_ID('tempdb..#vAirLine') IS NOT NULL
            DROP TABLE #vAirLine;

        IF OBJECT_ID('tempdb..#vAirRoute') IS NOT NULL
            DROP TABLE #vAirRoute;
        
        IF OBJECT_ID('tempdb..#vPassenger') IS NOT NULL
            DROP TABLE #vPassenger;

        PRINT CONCAT(N'機票', ' -- ', FORMAT(GETDATE(), @sDateTimeFormat));
    END;
    
    -- 房間 --
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @vBookingType WHERE wBookingType = 'CHANGEHOTEL')
    BEGIN
        -- 更改入住日期類型
        CREATE TABLE #vHotelChangeActionType(
            wCode   NVARCHAR(50),
            wTitle  NVARCHAR(100),
            PRIMARY KEY(wCode, wTitle)
        );
        INSERT INTO #vHotelChangeActionType(wCode, wTitle)
        SELECT DISTINCT
            wCode,
            wTitle
        FROM dbo.mLookUp
        WHERE wType = 'HOTEL_BOOKING_ACTION' AND wLangCd = @pLangCd;

        -- 床類型
        CREATE TABLE #vBedType(
            wCode   NVARCHAR(50),
            wTitle  NVARCHAR(100),
            PRIMARY KEY(wCode, wTitle)
        );
        INSERT INTO #vBedType(wCode, wTitle)
        SELECT DISTINCT
            wCode,
            wTitle
        FROM dbo.mLookUp
        WHERE wType = 'BED_TYPE' AND wLangCd = @pLangCd;

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
            wDebitDt = hceb.wDebitDt,
            wCancelDebitDt =hceb.wCancelDebitDt,
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
            wDateString = CONCAT(N'變動入住日期：', (CASE hc.wAction
                                                    WHEN 'C'	THEN CONVERT(CHAR(10),  hc.wNewStartDate, 20)
                                                    WHEN 'RF'	THEN CONVERT(CHAR(10),  hc.wOriStartDate, 20)
                                                    WHEN 'EX'	THEN CONVERT(CHAR(10),  hc.wOriEndDate,	  20)
                                                    WHEN 'ECI'	THEN CONVERT(CHAR(10),  hc.wNewStartDate, 20)
                                                    WHEN 'LC'	THEN CONVERT(CHAR(10),  hc.wOriStartDate, 20)
                                                    WHEN 'ECO'	THEN CONVERT(CHAR(10),  hc.wNewEndDate,	  20)
                                                    ELSE NULL END), 
                                                    CHAR(10), 
                                N'變動退房日期：',  (CASE hc.wAction
                                                    WHEN 'C'	THEN CONVERT(CHAR(10),  hc.wNewEndDate,   20)
                                                    WHEN 'RF'	THEN CONVERT(CHAR(10),  hc.wOriEndDate,   20)
                                                    WHEN 'EX'	THEN CONVERT(CHAR(10),  hc.wNewEndDate,   20)
                                                    WHEN 'ECI'	THEN CONVERT(CHAR(10),  hc.wOriStartDate, 20)
                                                    WHEN 'LC'	THEN CONVERT(CHAR(10),  hc.wNewStartDate, 20)
                                                    WHEN 'ECO'	THEN CONVERT(CHAR(10),  hc.wOriEndDate,   20)
                                                    ELSE NULL END)
            ),
            wQuantity = (CASE hc.wAction
                         WHEN 'C'   THEN DATEDIFF(DAY, hc.wNewStartDate, hc.wNewEndDate)		-- 完成
                         WHEN 'RF'  THEN DATEDIFF(DAY, hc.wOriStartDate, hc.wOriEndDate) * -1   -- 退款
                         WHEN 'ECI' THEN DATEDIFF(DAY, hc.wNewStartDate, hc.wOriStartDate)	    -- 提早入住
                         WHEN 'LC'  THEN DATEDIFF(DAY, hc.wNewStartDate, hc.wOriStartDate)	    -- 延遲入住
                         WHEN 'ECO' THEN DATEDIFF(DAY, hc.wOriEndDate, hc.wNewEndDate)		    -- 早退
                         WHEN 'EX'  THEN DATEDIFF(DAY, hc.wOriEndDate, hc.wNewEndDate)		    -- 續房
                         ELSE NULL END
            ),
            wRouteString = NULL,
            wTicketType = NULL,
            wHotel = IIF(@pLangCd = 'en-GB', h.wEname, h.wName),
            wDetail = CONCAT(N'動作：',        hcat.wTitle, char(10),  
                             N'房型：',        IIF(@pLangCd = 'en-GB', hr.wEname, hr.wName), CHAR(10), 
                             N'配額類型：',    mhr.wName, char(10),
                             N'床類：',        bed.wTitle, char(10),
                             N'房號：',        br.wRoomNo, char(10),
                             N'是否含早餐：',   IIF(br.wIncludeBreakfast = 'Y', N'是', N'否'), char(10),
                             N'確認號：',       br.wConfirmationNo),
            wCustomer = N'',
            wBookingStatus = br.wBookingStatus,
            wRemark = br.wRemark,
            wCancelReasonCd = eb.wCancelReasonCd,
            wOtherReason = eb.wOtherReason,
            wAsstBooker = hceb.wAsstBooker,
            wAsstBookerTel = hceb.wAssBookerTel,
            wAssBookerEmail = hceb.wAsstBookerEmail,
            wDeptFollowedCd = hceb.wDeptFollwedCd,
            wStaffFollowedRid = hceb.wStaffFollwedRid,
            wApprovalAgentCodeIn = hceb.wApprovalAgentCodeIn,
            wEventCodeRid = eb.wEventCodeRid,
            wReqDepartment = hceb.wReqDepartment,
            wReqUserRid = hceb.wReqUserRid,
            wTravelPkgRid = eb.wTravePkgRid,
            wUseBlackCard = hc.wUseMemeberCard,
            wSameDebitDtCnt = hc.wAction, -- 更改入住日期類型
            wExpCategory = NULL,
            wCrtDt = br.wCrtDt,
            wBookingRid = bh.wBookingRid, -- 酒店的wBookingRid而不是房间的wBookingRid
            wBookingDtlRid = br.RowID,
            wHotelChangeRid = hc.RowID
        FROM dbo.eBookingRoom AS br
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = br.wBookingRid AND eb.wBookingType = 'ROOM' AND br.wStatus = 'A'
        INNER JOIN dbo.eBookingHotel AS bh ON bh.RowID = br.wHotelBookingRid
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.RowID = br.wTravelAgencyRid --外館酒店供應商
        LEFT JOIN dbo.mHotelRoom AS hr ON hr.RowID = br.wHotelRoomRid
        LEFT JOIN dbo.mHotel AS h ON h.RowID = br.wHotelRid
        LEFT JOIN dbo.mAllotmentGroup AS mhr ON mhr.RowID = br.wAllotmentGroupRid
        LEFT JOIN dbo.eHotelChange AS hc ON hc.wRoomBookingRid = br.RowID
        LEFT JOIN dbo.eBooking AS hceb ON hceb.RowID = hc.wBookingRid
        LEFT JOIN #vHotelChangeActionType AS hcat ON hcat.wCode = hc.wAction
        LEFT JOIN #vBedType AS bed ON bed.wCode = br.wBedType
        LEFT JOIN @vDebitCounter AS brdc ON brdc.RowID = eb.wDebitCounterRid -- 房間
        LEFT JOIN @vDebitCounter AS hcdc ON hcdc.RowID = hceb.wDebitCounterRid -- 更改入住日期
        WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = eb.wDebitAgentCodeIn OR @pAgentCodeIn = hceb.wDebitAgentCodeIn)
            AND (@pDebitCounter IS NULL OR brdc.RowID IS NOT NULL OR hcdc.RowID IS NOT NULL)
            AND (((br.wBookingStatus IN ('C', 'CI', 'CO', 'RF') AND ((hceb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDate) BETWEEN @pFromDt AND @pToDt))))
                 OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        OPTION(RECOMPILE);

        -- Order數（同一個大單號，同一個動作，扣數日期同一天為一個ORDER）(24%)
        CREATE TABLE #vRoomOrderAction(
            wHotelBookingRid BIGINT,
            wAction          VARCHAR(5),
            wDebitDt         DATE,
            wCount           INT,
            PRIMARY KEY(wHotelBookingRid, wAction, wDebitDt)
        );
        WITH tHotelChange AS (
            SELECT hc.wRoomBookingRid, hc.wAction, wDebitDt = CONVERT(CHAR(10), eb.wDebitDt, 20) 
              FROM dbo.eHotelChange hc 
              INNER JOIN dbo.eBooking eb ON eb.RowID = hc.wBookingRid
              WHERE eb.wDebitDt BETWEEN @pFromDt AND @pToDt
        )
        INSERT INTO #vRoomOrderAction(wHotelBookingRid, wAction, wDebitDt, wCount)
        SELECT
            br.wHotelBookingRid,
            hc.wAction,
            hc.wDebitDt,
            wCount = COUNT(1)
        FROM tHotelChange AS hc
        INNER JOIN dbo.eBookingRoom AS br ON br.RowID = hc.wRoomBookingRid
        GROUP BY br.wHotelBookingRid, hc.wAction, hc.wDebitDt;

        -- Update Order數
        UPDATE r
        SET wSameDebitDtCnt = IIF(hca.wCount > 1, CONCAT('1', '/', CAST(hca.wCount AS VARCHAR)), '1')
        FROM #tmpResult r
        INNER JOIN dbo.eBookingHotel AS bh ON bh.wBookingRid = r.wBookingRid
        LEFT JOIN #vRoomOrderAction AS hca ON hca.wHotelBookingRid = bh.RowID AND hca.wAction = r.wSameDebitDtCnt AND hca.wDebitDt = CAST(r.wDebitDt AS DATE)
        WHERE r.wBookingType = 'ROOM';

        -- 客户
        UPDATE r
        SET wCustomer = STUFF(
            (SELECT CONCAT(CHAR(10), IIF(@pLangCd = 'en-GB', mp.wEName, mp.wCName), IIF(NULLIF(ptd.wEnglishPinyin, '') IS NULL, NULL, ' (' + ptd.wEnglishPinyin + ')'))
            From dbo.ePassengerDetails AS pd
            INNER JOIN dbo.mPerson AS mp ON mp.RowID = pd.wPersonRid
            LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON ptdd.wPassengerDetailsRid = pd.RowID
            LEFT JOIN dbo.mPersonTravelDoc AS ptd ON ptd.RowID = ptdd.wPersonTravelDocRid
            WHERE pd.wStatus = 'A'
                AND pd.wRoomBookingRid = r.wBookingDtlRid -- 此處要用房間的RowID，wBookingRid為酒店
                AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = pd.RowID)
            FOR XML PATH('')), 1, 1, N'')
        FROM #tmpResult r
        WHERE wBookingType = 'ROOM';

        IF OBJECT_ID('tempdb..#vHotelChangeActionType') IS NOT NULL
            DROP TABLE #vHotelChangeActionType;

        IF OBJECT_ID('tempdb..#vBedType') IS NOT NULL
            DROP TABLE #vBedType;

        IF OBJECT_ID('tempdb..#vRoomOrderAction') IS NOT NULL
            DROP TABLE #vRoomOrderAction;

        PRINT CONCAT(N'房間', ' -- ', FORMAT(GETDATE(), @sDateTimeFormat));
    END;

    -- 警察開路
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @vBookingType WHERE wBookingType = 'LEADING_SERVICE')
    BEGIN
        -- 地區
        CREATE TABLE #vLeadingRegion(
            wCode   NVARCHAR(50),
            wTitle  NVARCHAR(100),
            PRIMARY KEY(wCode, wTitle)
        );
        INSERT INTO #vLeadingRegion(wCode, wTitle)
        SELECT DISTINCT
            wCode,
            wTitle
        FROM dbo.mLookUp 
        WHERE wType = 'REGION' AND wLangCd = @pLangCd;

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
            wDateString = CONVERT(CHAR(16), lead.wStartDt, 20),
            wQuantity = 1,
            wRouteString = NULL,
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CONCAT(IIF(region.wTitle IS NULL, NULL, CONCAT(N'地區：', region.wTitle, CHAR(10))), N'警察數量：', lead.wNoofPolice),
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
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = lead.wBookingRid AND eb.wBookingType = 'LEADING_SERVICE' AND lead.wStatus = 'A'
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.RowID = lead.wTravelAgencyRid
        LEFT JOIN #vLeadingRegion AS region ON region.wCode = lead.wRegion
        LEFT JOIN @vDebitCounter AS dc ON dc.RowID = eb.wDebitCounterRid
        WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = eb.wDebitAgentCodeIn)
            AND (@pDebitCounter IS NULL OR dc.RowID IS NOT NULL)
            AND ((lead.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDate) BETWEEN @pFromDt AND @pToDt)))	--只有完成、退款狀態才有射數
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        OPTION(RECOMPILE);

        IF OBJECT_ID('tempdb..#vLeadingRegion') IS NOT NULL
            DROP TABLE #vLeadingRegion;

        PRINT CONCAT(N'警察開路', ' -- ', FORMAT(GETDATE(), @sDateTimeFormat));
    END;

    -- 簽證
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @vBookingType WHERE wBookingType = 'Visa')
    BEGIN
        -- 簽發地
        CREATE TABLE #vIssuePlace(
            wCode   NVARCHAR(50),
            wTitle  NVARCHAR(100),
            PRIMARY KEY(wCode, wTitle)
        );
        INSERT INTO #vIssuePlace(wCode, wTitle)
        SELECT DISTINCT
            wCode,
            wTitle
        FROM dbo.mLookUp
        WHERE wType = 'ID_ISSUE_PLACE' AND wLangCd = @pLangCd;

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
            wTotalCost = 0,
            wTotalAmount = 0,
            wDateString = CONVERT(CHAR(10), visa.wApplyDt, 20),
            wQuantity = visa.wQuantity,
            wRouteString = NULL,
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = IIF(place.wTitle IS NULL, NUll, CONCAT(N'簽發地：', place.wTitle)),
            wCustomer = N'',
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
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = visa.wBookingRid AND eb.wBookingType = 'Visa' AND visa.wStatus = 'A'
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.RowID = visa.wTravelAgencyRid
        LEFT JOIN #vIssuePlace AS place ON place.wCode = visa.wPlaceOfIssue
        LEFT JOIN @vDebitCounter AS dc ON dc.RowID = eb.wDebitCounterRid
        WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = eb.wDebitAgentCodeIn)
            AND (@pDebitCounter IS NULL OR dc.RowID IS NOT NULL)
            AND ((visa.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDate) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        OPTION(RECOMPILE);

        -- 客戶、消費額
        WITH tPassenger AS ( 
            SELECT
                rpd.wBookingRid,
                wTotalAmount = SUM(rpd.wAmount),
                wTotalCost = SUM(rpd.wCost),
                wCustomer = STUFF(
                    (SELECT CONCAT(CHAR(10), IIF(@pLangCd = 'en-GB', mp.wEName, mp.wCName), IIF(NULLIF(ptd.wEnglishPinyin, '') IS NULL, NULL, ' (' + ptd.wEnglishPinyin + ')'))
                    From dbo.ePassengerDetails AS spd
                    INNER JOIN dbo.mPerson AS mp ON mp.RowID = spd.wPersonRid
                    LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON ptdd.wPassengerDetailsRid = spd.RowID
                    LEFT JOIN dbo.mPersonTravelDoc AS ptd ON ptd.RowID = ptdd.wPersonTravelDocRid
                    WHERE spd.wStatus = 'A'
                        AND spd.wBookingRid = rpd.wBookingRid 
                        AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = spd.RowID)
                    FOR XML PATH('')), 1, 1, N'')
            FROM dbo.ePassengerDetails AS rpd 
            WHERE rpd.wBookingRid > 0 AND rpd.wStatus = 'A'
            GROUP BY rpd.wBookingRid
        )

        UPDATE r
        SET r.wTotalCost = pd.wTotalCost,
            r.wCustomer = pd.wCustomer
        FROM #tmpResult r
        LEFT JOIN tPassenger pd ON pd.wBookingRid = r.wBookingRid
        WHERE r.wBookingType = 'Visa';

        IF OBJECT_ID('tempdb..#vIssuePlace') IS NOT NULL
            DROP TABLE #vIssuePlace;

        PRINT CONCAT(N'簽證', ' -- ', FORMAT(GETDATE(), @sDateTimeFormat));
    END;

    -- 流動登機 --
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @vBookingType WHERE wBookingType = 'CHK_IN_SVC')
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
            wOrderNo = ci.wOrderNo,
            wPaymentMethod = ci.wPaymentMethod,
            wReceiptNo = ci.wReceiptNo,
            wDepositCost = eb.wDepositAmt,
            wTotalCost = ci.wCost,
            wTotalAmount = 0,
            wDateString = FORMAT(ci.wArrivalTimeToG15nG16, @sLongDateTimeFormat),
            wQuantity = ci.wQuantity,
            wRouteString = CONCAT(da.wCName, IIF(NULLIF(aa.wCName, '') IS NULL, NULL, '->'), aa.wCName),
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CONCAT(N'行李件數：', CAST(CONVERT(BIGINT, ci.wNoOfBaggage) AS VARCHAR), CHAR(10), 
                             N'貴賓包廂：', IIF(ci.wVIPRoom = 'Y', N'是', N'否'), CHAR(10),
                             N'貴賓包廂數量：', 1, CHAR(10),
                             N'坐位要求：', ci.wSeatRequest),
            wCustomer = N'',
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
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = ci.wBookingRid AND eb.wBookingType = 'CHK_IN_SVC' AND ci.wStatus = 'A'
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.RowID = ci.wSupplier
        LEFT JOIN dbo.mAirport AS da ON da.RowID =ci.wDepartAirport
        LEFT JOIN dbo.mAirport AS aa ON aa.RowID = ci.wDestination
        LEFT JOIN @vDebitCounter AS dc ON dc.RowID = eb.wDebitCounterRid
        WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = eb.wDebitAgentCodeIn)
            AND (@pDebitCounter IS NULL OR dc.RowID IS NOT NULL)
            AND ((ci.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDate) BETWEEN @pFromDt AND @pToDt))) --只有完成、退款狀態才有射數
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        OPTION(RECOMPILE);

        -- 客戶
        UPDATE r
        SET wCustomer = STUFF(
            (SELECT CONCAT(CHAR(10), IIF(@pLangCd = 'en-GB', mp.wEName, mp.wCName), IIF(NULLIF(ptd.wEnglishPinyin, '') IS NULL, NULL, ' (' + ptd.wEnglishPinyin + ')'))
            From dbo.ePassengerDetails AS pd
            INNER JOIN dbo.mPerson AS mp ON mp.RowID = pd.wPersonRid
            LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON ptdd.wPassengerDetailsRid = pd.RowID
            LEFT JOIN dbo.mPersonTravelDoc AS ptd ON ptd.RowID = ptdd.wPersonTravelDocRid
            WHERE pd.wStatus = 'A'
                AND pd.wBookingRid = r.wBookingRid
                AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = pd.RowID)
            FOR XML PATH('')), 1, 1, N'')
        FROM #tmpResult r
        WHERE r.wBookingType = 'CHK_IN_SVC';

        PRINT CONCAT(N'流動登機', ' -- ', FORMAT(GETDATE(), @sDateTimeFormat));
    END;

    -- 機場服務 --
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @vBookingType WHERE wBookingType = 'PickUp_SERVICE')
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
            wOrderNo = pickup.wOrderNo,
            wPaymentMethod = pickup.wPaymentMethod,
            wReceiptNo = pickup.wReceiptNo,
            wDepositCost = eb.wDepositAmt,
            wTotalCost = pickup.wTotalCost,
            wTotalAmount = 0,
            wDateString = FORMAT(pickup.wApplyDt, @sLongDateTimeFormat),
            wQuantity = 1,
            wRouteString = CONCAT(da.wCName, IIF(NULLIF(aa.wCName, '') IS NULL, NULL, '->'), aa.wCName),
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CONCAT(N'服務類型：', CASE pickup.wServiceType 
                                           WHEN 'PU' THEN N'接機' 
                                           WHEN 'DO' THEN N'送機' 
                                           WHEN 'EC' THEN N'快速通關' 
                                           ELSE NULL END,
                             CHAR(10),
                             N'顯示名稱：', pickup.wDisplayName),
            wCustomer = N'',
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
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = pickup.wBookingRid AND eb.wBookingType = 'PickUp_SERVICE' AND pickup.wStatus = 'A'
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.RowID = pickup.wTravelAgencyRid
        LEFT JOIN dbo.mAirport AS da ON da.RowID =pickup.wDepartAirport
        LEFT JOIN dbo.mAirport AS aa ON aa.RowID = pickup.wDestination
        LEFT JOIN @vDebitCounter AS dc ON dc.RowID = eb.wDebitCounterRid
        WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = eb.wDebitAgentCodeIn)
            AND (@pDebitCounter IS NULL OR dc.RowID IS NOT NULL)
            AND ((pickup.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDate) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        OPTION(RECOMPILE);

        -- 客戶
        UPDATE r
        SET wCustomer = STUFF(
                (SELECT CONCAT(CHAR(10), IIF(@pLangCd = 'en-GB', mp.wEName, mp.wCName), IIF(NULLIF(ptd.wEnglishPinyin, '') IS NULL, NULL, ' (' + ptd.wEnglishPinyin + ')'))
                From dbo.ePassengerDetails AS pd
                INNER JOIN dbo.mPerson AS mp ON mp.RowID = pd.wPersonRid
                LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON ptdd.wPassengerDetailsRid = pd.RowID
                LEFT JOIN dbo.mPersonTravelDoc AS ptd ON ptd.RowID = ptdd.wPersonTravelDocRid
                WHERE pd.wStatus = 'A'
                    AND pd.wBookingRid = r.wBookingRid 
                    AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = pd.RowID)
                FOR XML PATH('')), 1, 1, N'')
        FROM #tmpResult r
        WHERE r.wBookingType = 'PickUp_SERVICE';

        PRINT CONCAT(N'機場服務', ' -- ', FORMAT(GETDATE(), @sDateTimeFormat));
    END;
    
    -- 其他消費
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @vBookingType WHERE wBookingType = 'ADDITIONALEXPENSES')
    BEGIN
        -- 消费类型
        CREATE TABLE #vExpCategory(
            wCode   NVARCHAR(50),
            wTitle  NVARCHAR(100),
            PRIMARY KEY(wCode, wTitle)
        );
        INSERT INTO #vExpCategory(wCode, wTitle)
        SELECT DISTINCT
            wCode, 
            wTitle 
        FROM dbo.mLookUp 
        WHERE wType = 'EXPENSE_CATEGORY' AND wLangCd = @pLangCd;

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
            wRelatedBookingRefNo = refeb.wRefNo, -- 相關預訂編號
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
            wDetail = N'',
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
            wExpCategory = N'',
            wCrtDt = ae.wCrtDt,
            wBookingRid = eb.RowID,
            wBookingDtlRid = ae.RowID,
            wHotelChangeRid = -1
        FROM dbo.eAdditionalExpense AS ae
        INNER JOIN dbo.eBooking  AS eb ON eb.RowID = ae.wBookingRefRid AND eb.wBookingType = 'ADDITIONALEXPENSES' AND ae.wStatus = 'A'  --自己本身
        LEFT JOIN dbo.eBooking AS refeb ON refeb.RowID = ae.wBookingRid AND ae.wBookingRefRid <> ae.wBookingRid	--相關訂務
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.RowID = ae.wTravelAgencyRid
        LEFT JOIN @vDebitCounter AS dc ON dc.RowID = eb.wDebitCounterRid
        WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = eb.wDebitAgentCodeIn)
            AND (@pDebitCounter IS NULL OR dc.RowID IS NOT NULL)
            AND ((ae.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDate) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        OPTION(RECOMPILE);

        UPDATE r
        SET wDetail = CONCAT(IIF(NULLIF(et.wName,  '') IS NULL,  NULL, CONCAT(N'消費類型：', et.wName, CHAR(10))), 
                             IIF(NULLIF(est.wName, '') IS NULL,  NULL, CONCAT(N'消費副類型：', est.wName, CHAR(10))),
                             IIF(NULLIF(mr.wName,  '') IS NULL,  NULL, CONCAT(N'餐廳：', mr.wName))
            ),
            wExpCategory = ISNULL(esc.wTitle, ec.wTitle), -- 其他消费【消费类型】特殊处理，取Booking的消費類型及消費副類型
            r.wBookingDtlRid = -1
        FROM #tmpResult r
        INNER JOIN dbo.eAdditionalExpense ae ON ae.RowID = r.wBookingDtlRid AND ae.wBookingRefRid = r.wBookingRid
        LEFT JOIN dbo.mRestaurant AS mr ON mr.RowID = ae.wRestaurantRid
        LEFT JOIN dbo.mExpenseType AS et ON et.RowID = ae.wExpenseType
        LEFT JOIN dbo.mExpenseSubtype AS est ON est.RowID = ae.wExpenseSubtype AND est.wExpenseTypeId = et.RowID
        LEFT JOIN #vExpCategory AS ec ON ec.wCode = et.wExpCat
        LEFT JOIN #vExpCategory AS esc ON esc.wCode = est.wExpCat
        WHERE r.wBookingType = 'ADDITIONALEXPENSES';

        IF OBJECT_ID('tempdb..#vExpCategory') IS NOT NULL
            DROP TABLE #vExpCategory;

        PRINT CONCAT(N'其他消費', ' -- ', FORMAT(GETDATE(), @sDateTimeFormat));
    END;
    
    -- 門票
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @vBookingType WHERE wBookingType = 'SHOWTICKET')
    BEGIN
    -- 消费类型
        CREATE TABLE #vShowCategory(
            wCode   NVARCHAR(50),
            wTitle  NVARCHAR(100),
            PRIMARY KEY(wCode, wTitle)
        );
        INSERT INTO #vShowCategory(wCode, wTitle)
        SELECT DISTINCT wCode, wTitle 
        FROM dbo.mLookUp 
        WHERE wType = 'SHOW_CATEGORY' AND wLangCd = @pLangCd;

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
            wDateString = FORMAT(show.wShowDt, @sLongDateTimeFormat),
            wQuantity = show.wTotalQuantity,
            wRouteString = NULL,
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = IIF(NULLIF(ms.wName, '') IS NULL, NULL, CONCAT(N'表演：', ms.wName)),
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
            wExpCategory = ms.wShowCatCode, -- 門票類型（臨時）
            wCrtDt = show.wCrtDt,
            wBookingRid = eb.RowID,
            wBookingDtlRid = show.RowID,
            wHotelChangeRid = -1
        FROM dbo.eBookingShow AS show
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = show.wBookingRid AND eb.wBookingType = 'SHOWTICKET' AND show.wStatus = 'A'
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.RowID = show.wTravelAgencyRid
        LEFT JOIN dbo.mShow AS ms ON ms.RowID = show.wShowRid
        LEFT JOIN @vDebitCounter AS dc ON dc.RowID = eb.wDebitCounterRid
        WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = eb.wDebitAgentCodeIn)
            AND (@pDebitCounter IS NULL OR dc.RowID IS NOT NULL)
            AND ((show.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDate) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        OPTION(RECOMPILE);

        -- 預訂門票
        WITH tShowTicket AS (
            SELECT
                rst.wBookingShowRid,
                wTicket = STUFF(
                    (SELECT CONCAT(N', ', price.wTicketType, '-', CAST(sst.wQuantity AS VARCHAR), N'張')
                    From dbo.eBookingShowTicket AS sst
                    INNER JOIN dbo.mShowTicketPrice AS price ON price.RowID = sst.wShowTicketPriceRid
                    WHERE sst.wQuantity > 0
                        AND sst.wBookingShowRid = rst.wBookingShowRid
                    FOR XML PATH('')), 1, 2, N'')
            FROM dbo.eBookingShowTicket AS rst
            GROUP BY rst.wBookingShowRid
        )

        UPDATE r
        SET r.wDetail = CONCAT(r.wDetail, IIF(NULLIF(st.wTicket, '') IS NULL, NULL, CONCAT(CHAR(10), N'區域：', st.wTicket)), IIF(NULLIF(sc.wTitle, '') IS NULL, NULL, CONCAT(CHAR(10), N'門票類型：', sc.wTitle))),
            r.wBookingDtlRid = -1,
            r.wExpCategory = NULL
        FROM #tmpResult r
        LEFT JOIN tShowTicket st ON st.wBookingShowRid = r.wBookingDtlRid
        LEFT JOIN #vShowCategory sc ON sc.wCode = r.wExpCategory
        WHERE r.wBookingType = 'SHOWTICKET';

        IF OBJECT_ID('tempdb..#vShowCategory') IS NOT NULL
            DROP TABLE #vShowCategory;

        PRINT CONCAT(N'門票', ' -- ', FORMAT(GETDATE(), @sDateTimeFormat));
    END;
    
    -- 旅遊套票 --
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @vBookingType WHERE wBookingType = 'TRAVEL_PACKAGE')
    BEGIN
        -- 城市
        CREATE TABLE #vPkgCity(
            wCode   NVARCHAR(50),
            wTitle  NVARCHAR(100),
            PRIMARY KEY(wCode, wTitle)
        );
        INSERT INTO #vPkgCity(wCode, wTitle)
        SELECT DISTINCT
            wCode, 
            wTitle 
        FROM dbo.mLookUp 
        WHERE wType = 'CITY' AND wLangCd = @pLangCd;

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
            wDateString = CONCAT(N'出發日期：', CONVERT(CHAR(10), pkg.wStartDt, 20), ', ', N'結束日期：', CONVERT(CHAR(10), pkg.wEndDt, 20)),
            wQuantity = 1,
            wRouteString = NULL,
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CONCAT(IIF(dept.wTitle IS NULL, NULL, CONCAT(N'出發城市：', dept.wTitle, CHAR(10))), 
                             IIF(dest.wTitle IS NULL, NULL, CONCAT(N'目的地：', dest.wTitle))
            ),
            wCustomer = N'',
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
            wBookingDtlRid = pkg.RowID,
            wHotelChangeRid = -1
        FROM dbo.eBookingTravelPackage AS pkg
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = pkg.wBookingRid AND eb.wBookingType = 'TRAVEL_PACKAGE' AND pkg.wStatus = 'A'
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.RowID = pkg.wTravelAgencyRid
        LEFT JOIN #vPkgCity AS dept ON dept.wCode = pkg.wDeptCd
        LEFT JOIN #vPkgCity AS dest ON dest.wCode = pkg.wDestCd
        LEFT JOIN @vDebitCounter AS dc ON dc.RowID = eb.wDebitCounterRid
        WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = eb.wDebitAgentCodeIn)
            AND (@pDebitCounter IS NULL OR dc.RowID IS NOT NULL)
            AND ((pkg.wBookingStatus IN ('C', 'CI', 'CO', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDate) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        OPTION(RECOMPILE);
		
        -- 客戶
        -- 旅遊套票預訂類型
        UPDATE r
        SET wCustomer = STUFF(
                (SELECT CONCAT(CHAR(10), IIF(@pLangCd = 'en-GB', mp.wEName, mp.wCName), IIF(NULLIF(ptd.wEnglishPinyin, '') IS NULL, NULL, ' (' + ptd.wEnglishPinyin + ')'))
                From dbo.ePassengerDetails AS pd
                INNER JOIN dbo.mPerson AS mp ON mp.RowID = pd.wPersonRid
                LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON ptdd.wPassengerDetailsRid = pd.RowID
                LEFT JOIN dbo.mPersonTravelDoc ptd ON ptd.RowID = ptdd.wPersonTravelDocRid
                WHERE pd.wStatus = 'A'
                    AND pd.wBookingRid = r.wBookingRid 
                    AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = pd.RowID)
                FOR XML PATH('')), 1, 1, N''),
            wDetail = CONCAT(r.wDetail, 
                             IIF((SELECT COUNT(1) FROM dbo.eBooking WHERE wTravePkgRid = r.wBookingDtlRid) = 0, 
                                 NULL,
                                 CONCAT(CHAR(10), N'預訂項目：', STUFF(
                                    (SELECT CONCAT(N', ',[dbo].[fnGetBookingTypeName](wBookingType)) 
                                    FROM dbo.eBooking
                                    WHERE wTravePkgRid = r.wBookingDtlRid
                                    FOR XML PATH('')), 1, 2, N'')
                                ))
            ),
            wBookingDtlRid = -1
        FROM #tmpResult r
        WHERE r.wBookingType = 'TRAVEL_PACKAGE'; 

        IF OBJECT_ID('tempdb..#vPkgCity') IS NOT NULL
            DROP TABLE #vPkgCity;

        PRINT CONCAT(N'旅遊套票', ' -- ', FORMAT(GETDATE(), @sDateTimeFormat));
    END;

    -- 私人飛機 --
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @vBookingType WHERE wBookingType = 'PP')
    BEGIN
        -- 機票類型
        CREATE TABLE #vPPTicketType(
            wCode   NVARCHAR(50),
            wTitle  NVARCHAR(100),
            PRIMARY KEY(wCode, wTitle)
        );
        INSERT INTO #vPPTicketType (wCode, wTitle)
        SELECT DISTINCT
            wCode,
            wTitle
        FROM dbo.mLookUp
        WHERE wType = 'AIR_TICKET_TYPE' AND wLangCd = @pLangCd;

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
            wTranvalAgencyName = IIF(pp.wSupplier = 'HO', hta.wName, mta.wName),
            wOrderNo = pp.wOrderNo,
            wPaymentMethod = pp.wPaymentMethod,
            wReceiptNo = pp.wReceiptNo,
            wDepositCost = eb.wDepositAmt,
            wTotalCost = pp.wTotalCost,
            wTotalAmount = 0,
            wDateString = N'',
            wQuantity = pp.wConfirmPassengerNo,
            wRouteString = N'',
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CONCAT(N'預訂類型: ',  ticketType.wTitle, CHAR(10),
                             N'飛機型號: ',  pp.wPlaneModel, CHAR(10),
                             N'吸煙: ',     IIF(pp.wIsSmoking = 'Y', N'是', N'否'), CHAR(10),
                             N'語言: ',     pp.wServiceLang, CHAR(10),
                             N'WIFI: ',     IIF(pp.wHasWifi = 'Y', N'是', N'否'), CHAR(10),
                             N'客服人數: ',  CAST(pp.wNoOfServiceStaff AS VARCHAR)),
            wCustomer = N'',
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
            wBookingDtlRid = pp.RowID,
            wHotelChangeRid = -1
        FROM dbo.eBookingPrivatePlane AS pp
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = pp.wBookingRid AND eb.wBookingType = 'PP' AND pp.wStatus = 'A'
        LEFT JOIN dbo.mTravelAgency AS mta ON mta.RowID = pp.wTravelAgencyRid AND pp.wSupplier != 'HO' -- 旅行社代理
        LEFT JOIN dbo.mHotel AS hta ON hta.RowID = pp.wHotelRid AND pp.wSupplier = 'HO' -- 酒店代理
        LEFT JOIN #vPPTicketType AS ticketType ON  ticketType.wCode = pp.wBookingType
        LEFT JOIN @vDebitCounter AS dc ON dc.RowID = eb.wDebitCounterRid
        WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = eb.wDebitAgentCodeIn)
            AND (@pDebitCounter IS NULL OR dc.RowID IS NOT NULL)
            AND ((pp.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDate) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        OPTION(RECOMPILE);

        -- 客戶
        -- 私人飛機航線
        UPDATE r
        SET wCustomer = STUFF(
                (SELECT CONCAT(CHAR(10), IIF(@pLangCd = 'en-GB', mp.wEName, mp.wCName), IIF(NULLIF(ptd.wEnglishPinyin, '') IS NULL, NULL, ' (' + ptd.wEnglishPinyin + ')'))
                From dbo.ePassengerDetails AS pd
                INNER JOIN dbo.mPerson AS mp ON mp.RowID = pd.wPersonRid
                LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON ptdd.wPassengerDetailsRid = pd.RowID
                LEFT JOIN dbo.mPersonTravelDoc ptd ON ptd.RowID = ptdd.wPersonTravelDocRid
                WHERE pd.wStatus = 'A'
                    AND pd.wBookingRid = r.wBookingRid 
                    AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = pd.RowID)
                FOR XML PATH('')), 1, 1, N''),
            wRouteString = STUFF(
                (SELECT CONCAT(CHAR(10), IIF(@pLangCd = 'en-GB', da.wEName, da.wCName), IIF(da.RowID IS NULL OR aa.RowID IS NULL, NULL, '>'), IIF(@pLangCd = 'en-GB', aa.wEName, aa.wCName))
                FROM dbo.ePrivatePlaneRouteDtl AS spprd
                LEFT JOIN dbo.mAirport AS da ON da.RowID = spprd.wDepartureAirportRid
                LEFT JOIN dbo.mAirport AS aa ON aa.RowID = spprd.wArrivalAirportRid
                WHERE spprd.wBookingPrivatePlaneRid = r.wBookingDtlRid
                FOR XML PATH(''),TYPE).value('text()[1]','NVARCHAR(4000)'), 1, 1, N''),
            wDateString = STUFF(
                (SELECT CONCAT(CHAR(10), FORMAT(spprd.wTakeOffDt, @sLongDateTimeFormat), '>', FORMAT(spprd.wArrivalDt, @sLongDateTimeFormat))
                FROM dbo.ePrivatePlaneRouteDtl AS spprd
                WHERE spprd.wBookingPrivatePlaneRid = r.wBookingDtlRid
                FOR XML PATH(''),TYPE).value('text()[1]','NVARCHAR(4000)'), 1, 1, N''),
            wBookingDtlRid = -1
        FROM #tmpResult r
        WHERE r.wBookingType = 'PP';

        IF OBJECT_ID('tempdb..#vPPTicketType') IS NOT NULL
            DROP TABLE #vPPTicketType;

        PRINT CONCAT(N'私人飛機', ' -- ', FORMAT(GETDATE(), @sDateTimeFormat));
    END;

    -- 導遊服務 --
    IF @pBookingType IS NULL OR EXISTS (SELECT 1 FROM @vBookingType WHERE wBookingType = 'TOUR')
    BEGIN
        -- 地區
        CREATE TABLE #vTourRegion(
            wCode   NVARCHAR(50),
            wTitle  NVARCHAR(100),
            PRIMARY KEY(wCode, wTitle)
        );
        INSERT INTO #vTourRegion (wCode, wTitle)
        SELECT DISTINCT
            wCode,
            wTitle
        FROm dbo.mLookUp 
        WHERE wType = 'REGION' AND wLangCd = @pLangCd;

        -- 語言
        CREATE TABLE #vTourLang (
            wCode   NVARCHAR(50),
            wTitle  NVARCHAR(100),
            PRIMARY KEY(wCode, wTitle)
        )
        INSERT INTO #vTourLang(wCode, wTitle)
        SELECT DISTINCT
            wCode,
            wTitle
        FROM dbo.mLookUp 
        WHERE wType = 'SPEAK_LANG' AND wLangCd = @pLangCd;

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
            wDateString = FORMAT(tour.wStartDt, @sLongDateTimeFormat), --日期為開始日期
            wQuantity = 1, --數量永遠為1
            wRouteString = NULL,
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CONCAT(IIF(region.wTitle IS NULL, NULL, CONCAT(N'地區：', region.wTitle, CHAR(10))),
                             IIF(lang.wTitle IS NULL, NULL, CONCAT(N'語言：', lang.wTitle, CHAR(10))),
                             N'時數：', tour.wPeriod),
            wCustomer = N'',
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
        INNER JOIN dbo.eBooking AS eb ON eb.RowID = tour.wBookingRid AND eb.wBookingType = 'TOUR' AND tour.wStatus = 'A'
        LEFT JOIN dbo.mTravelAgency AS ta ON ta.RowID = tour.wTravelAgencyRid
        LEFT JOIN #vTourRegion AS region ON region.wCode = tour.wRegion
        LEFT JOIN #vTourLang AS lang ON lang.wCode = tour.wLang
        LEFT JOIN @vDebitCounter AS dc ON dc.RowID = eb.wDebitCounterRid
        WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = eb.wDebitAgentCodeIn)
            AND (@pDebitCounter IS NULL OR dc.RowID IS NOT NULL)
            AND ((tour.wBookingStatus IN ('C', 'RF') AND ((eb.wDebitDt BETWEEN @pFromDt AND @pToDt) OR (ISNULL(eb.wCancelDebitDt, @sStartDate) BETWEEN @pFromDt AND @pToDt)))
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
        OPTION(RECOMPILE);

        -- 客戶
        UPDATE r
        SET wCustomer = STUFF(
                (SELECT CONCAT(CHAR(10), IIF(@pLangCd = 'en-GB', mp.wEName, mp.wCName), IIF(NULLIF(ptd.wEnglishPinyin, '') IS NULL, NULL, ' (' + ptd.wEnglishPinyin + ')'))
                From dbo.ePassengerDetails AS pd
                INNER JOIN dbo.mPerson AS mp ON mp.RowID = pd.wPersonRid
                LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON ptdd.wPassengerDetailsRid = pd.RowID 
                LEFT JOIN dbo.mPersonTravelDoc ptd ON ptd.RowID = ptdd.wPersonTravelDocRid
                WHERE pd.wStatus = 'A'
                    AND pd.wBookingRid = r.wBookingRid 
                    AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = pd.RowID)
                FOR XML PATH('')), 1, 1, N'')
        FROM #tmpResult r
        WHERE r.wBookingType = 'TOUR';

        IF OBJECT_ID('tempdb..#vTourRegion') IS NOT NULL
            DROP TABLE #vTourRegion;

        IF OBJECT_ID('tempdb..#vTourLang') IS NOT NULL
            DROP TABLE #vTourLang

        PRINT CONCAT(N'導遊', ' -- ', FORMAT(GETDATE(), @sDateTimeFormat));
    END;
    
    -- 射數
    -------------------------------------------------------------------------------------
    -- 付款方式
    CREATE TABLE #vPayType(
        wCode   NVARCHAR(50),
        wTitle  NVARCHAR(100),
        PRIMARY KEY(wCode, wTitle)
    );
    INSERT INTO #vPayType(wCode, wTitle)
    SELECT DISTINCT
        wCode,
        wTitle
    FROM dbo.mLookUp 
    WHERE wType = 'PAYMENT_TYPE' AND wLangCd = @pLangCd;

    -- 酒店付款方式
    CREATE TABLE #vHotelPayType(
        wCode   NVARCHAR(50),
        wTitle  NVARCHAR(100),
        PRIMARY KEY(wCode, wTitle)
    );
    INSERT INTO #vHotelPayType(wCode, wTitle)
    SELECT DISTINCT
        wCode,
        wTitle
    FROM dbo.mLookUp 
    WHERE wType = 'PAYMENT_TYPE_HOTEL' AND wLangCd = @pLangCd;

    -- 取消原因
    CREATE TABLE #vCancelReason(
        wCode   NVARCHAR(50),
        wTitle  NVARCHAR(100),
        PRIMARY KEY(wCode, wTitle)
    );
    INSERT INTO #vCancelReason(wCode, wTitle)
    SELECT DISTINCT
        wCode,
        wTitle
    FROM dbo.mLookUp 
    WHERE wType = 'CANCEL_REASON' AND wLangCd = @pLangCd;

    -- 部門
    CREATE TABLE #vDepartment (
        wDeptCode VARCHAR(30),
        wDeptName NVARCHAR(100),
        PRIMARY KEY (wDeptCode, wDeptName)
    );
    INSERT INTO #vDepartment(wDeptCode, wDeptName)
    SELECT DISTINCT 
        wDeptCode = wCode,
        wDeptName = IIF(@pLangCd = 'en-GB', wEName, wCName)
    FROM RollsMary.dbo.mDepartment
    WHERE wIsRealDept = 'Y' 
        AND wActive = 'A'
        AND NULLIF(wUserLineGrp, '') IS NULL ;

    -- 旅遊套票
    CREATE TABLE #vTravelPkg(
        RowID BIGINT,
        wRefNo VARCHAR(30),
        PRIMARY KEY(RowID, wRefNo)
    );
    INSERT INTO #vTravelPkg(RowID, wRefNo)
    SELECT DISTINCT 
            pkg.RowID,
            b.wRefNo
    FROM dbo.eBookingTravelPackage pkg
    INNER JOIN dbo.eBooking b ON b.RowID = pkg.wBookingRid
    INNER JOIN #tmpResult r ON r.wTravelPkgRid = pkg.RowID
    WHERE r.wTravelPkgRid > 0;

    -- 消費券（酒店預訂沒有消費券）
    CREATE TABLE #vVoucher(
        wBookingRid BIGINT PRIMARY KEY,
        wVoucher VARCHAR(4000)
    );
    INSERT INTO #vVoucher(wBookingRid, wVoucher)
    SELECT r.wBookingRid,
           wVoucher = STUFF(
                (SELECT CONCAT( N', ', CAST(mv.wVoucherRefNo AS NVARCHAR))
                From dbo.eVoucher AS ev
                INNER JOIN dbo.mVoucher AS mv ON mv.RowID = ev.wVoucherRid 
                WHERE ev.wBookingRid = r.wBookingRid
                FOR XML PATH('')), 1, 2, N'')
    FROM #tmpResult r
    GROUP BY r.wBookingRid;
    
    -- 射數
    SELECT
        RowID,
        wBookingRid = CONVERT(BIGINT, wReferId),
        wRefRid,
        wShopName,
        wAmount,
        wAmountActual_CRM,
        wIsDeposit,
        wDate
    INTO #vExpTran
    FROM RollsMary.dbo.eExpTran
    WHERE wExpGroup = 'RCRM'
        AND CONVERT(BIGINT, wReferId) > 0
        AND wDate BETWEEN @pFromDt AND @pToDt;

    -- 射數為0時Join不到記錄，此處取第一條為0的記錄
    SELECT
        RowID = MIN(RowID),
        wBookingRid,
        wRefRid,
        wShopName,
        wAmount = 0,
        wAmountActual_CRM = 0
    INTO #vZeroExpTran
    FROM #vExpTran
    WHERE wIsDeposit != 'Y' AND wAmountActual_CRM = 0 AND wBookingRid > 0
    GROUP BY wBookingRid, wRefRid, wShopName;
    
    SELECT
        RowID = r.RowID,
        wBookingRid = r.wBookingRid,
        wBookingTypeCode = r.wBookingType,
        wMapBookingStatus = ISNULL(bs.wMapBookingStatus, r.wBookingStatus),
        wExpTranRid = et.RowID,
        wBookingType = IIF(@pLangCd = 'en-GB', UPPER(r.wBookingType), dbo.fnGetBookingTypeName(r.wBookingType)), -- 消費類型
        r.wRefNo,		                -- 訂單編號
        r.wRelatedBookingRefNo,		    -- 相關訂務
        wDebitCounterName = dsc.wName,	-- 扣數場館
        wReqCounterName = rsc.wName,	-- 要求場館
        wDebitAgentCode = aDebit.wAgentCode_Display,
        wDebitAgentName = IIF(@pLangCd = 'en-GB', aDebit.wEName, aDebit.wCName),	-- 扣數戶口
        wReqAgentCode = aReq.wAgentCode_Display,
        wReqAgentName = IIF(@pLangCd = 'en-GB', aReq.wEName, aReq.wCName),			-- 要求戶口
        r.wTranvalAgencyName,		-- 供應商名稱
        r.wOrderNo,				-- 單號
        wPayMethod = IIF(r.wBookingType IN ('CHANGEHOTEL', 'HOTEL', 'ROOM'), hotelPay.wTitle, pay.wTitle), -- 付款方式
        r.wReceiptNo,	-- 現金單號
        wIsDeposit = ISNULL(et.wIsDeposit, 'N'),
        wTotalCost = IIF(et.wIsDeposit = 'Y', r.wDepositCost, IIF((et.wAmount < 0 OR et.wAmountActual_CRM < 0 OR bs.wMapBookingStatus = 'RF') AND r.wTotalCost > 0, -1 * r.wTotalCost, r.wTotalCost)),	-- 總成本
        r.wDateString,		-- 日期
        r.wQuantity,		-- 數量
        r.wRouteString,		-- 航線
        r.wTicketType,		-- 票類型
        r.wHotel,			-- 酒店
        wDetail = IIF(NULLIF(ev.wVoucher, '') IS NULL, r.wDetail, CONCAT(r.wDetail, CHAR(10), N'消費券：', ev.wVoucher)),	-- 明細
        r.wCustomer,		-- 客人
        wBookingStatus = (
            CASE r.wBookingStatus
            WHEN 'P'	THEN N'處理中'
            WHEN 'CL'	THEN N'取消'
            WHEN 'C'	THEN N'完成'
            WHEN 'RF'	THEN N'已退款'
            WHEN 'UQ'	THEN N'不達標'
            WHEN 'CO'	THEN N'退房'
            WHEN 'CI'	THEN N'已入住'
            ELSE NULL END
        ),					-- 訂單狀態
        r.wRemark,			-- 備註
        wCancelReason = IIF(r.wBookingStatus = 'C', NULL, IIF(r.wCancelReasonCd = '05', r.wOtherReason, cancel.wTitle)),	-- 取消原因
        r.wAsstBooker,		-- 代訂人
        r.wAsstBookerTel,	-- 代訂人電話
        r.wAssBookerEmail,	-- 代訂人電郵
        wFollowedDeptName = dFollow.wDeptName,				                            -- 跟進部門
        wFollowedStaffName = IIF(@pLangCd = 'en-GB', uFollow.wName, uFollow.wCName),    -- 跟進同事
        wApprovalAgentCode = aApproval.wAgentCode_Display,				                -- 確認戶主/授權人
        wApprovalAgentName = IIF(@pLangCd = 'en-GB', aApproval.wEName, aApproval.wCName),
        wEventCode = IIF(@pLangCd = 'en-GB', code.wEName, code.wCName),	        -- 活動代碼
        wReqDeptName = dReq.wDeptName,				                            -- 要求部門
        wReqStaffID = uReq.wUsrId,                                              -- 要求同事
        wReqStaffName = IIF(@pLangCd = 'en-GB' , uReq.wName, uReq.wCName),	    -- 要求同事
        wTravelPkgRefNo = pkg.wRefNo,				                            -- 旅遊套票
        wUseBlackCard = IIF(r.wUseBlackCard IN ('Y', 'T'), 'Y', 'N' ),        -- 黑卡?
        wSameDebitDtCnt = IIF(et.wIsDeposit = 'Y', '1', r.wSameDebitDtCnt),   -- 最終要顯示  '1/wHotelSameDebitDtCnt'
        wDebitDt = ISNULL(et.wDate, IIF(ISNULL(bs.wMapBookingStatus, r.wBookingStatus) = 'RF', r.wCancelDebitDt, r.wDebitDt)),
        wCancelDt = IIF((r.wBookingType IN ('AIRTICKET', 'HELI') AND r.wBookingStatus = 'RF') OR bs.wMapBookingStatus = 'RF', r.wCancelDt, NULL),	-- 取消日期
        -- 射數為0，取射數第一條記錄的值
        -- 當射數為0時，Join不到射數值，取第一條射數為0的記錄
        --（目前，如果【完成】、【退款】其中一條射數失敗，最後兩條都會有值【0】，都是【0】影響不大，後面在射數表wBookingStatus賦值后能解決此問題）
        wAmount = ISNULL(et.wAmount, zet.wAmount),
        wAmountActual_CRM = ISNULL(et.wAmountActual_CRM, zet.wAmountActual_CRM ),
        wExpCategory = (
            CASE WHEN @pLangCd = 'en-GB' THEN UPPER(r.wBookingType)
            ELSE ( 
                CASE r.wBookingType
                WHEN 'ADDITIONALEXPENSES'	THEN r.wExpCategory
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
                ELSE UPPER(r.wBookingType) END
            ) END
        ),
        r.wCrtDt
    INTO #vResult
    FROM #tmpResult r
    INNER JOIN RollsMary.dbo.mAgent AS aDebit ON r.wDebitAgentCodeIn = aDebit.wAgentCodeIn
    INNER JOIN RollsMary.dbo.mAgent AS aReq ON r.wReqAgentCodeIn = aReq.wAgentCodeIn
    LEFT JOIN RollsMary.dbo.mAgent AS aApproval ON aApproval.wAgentCodeIn = r.wApprovalAgentCodeIn
    LEFT JOIN dbo.mServiceCounter AS dsc ON r.wDebitCounterRid = dsc.RowID
    LEFT JOIN dbo.mServiceCounter AS rsc ON r.wReqCounterRid = rsc.RowID
    LEFT JOIN RollsMary.dbo.mUsr uFollow ON r.wStaffFollowedRid = uFollow.RowID
    LEFT JOIN RollsMary.dbo.mUsr uReq ON r.wReqUserRid = uReq.RowID
    LEFT JOIN dbo.mEventCode AS code ON code.RowID = r.wEventCodeRid
    LEFT JOIN #vTravelPkg as pkg ON pkg.RowID = r.wTravelPkgRid
    LEFT JOIN #vDepartment AS dFollow ON dFollow.wDeptCode = r.wDeptFollowedCd
    LEFT JOIN #vDepartment AS dReq ON dReq.wDeptCode = r.wReqDepartment
    LEFT JOIN #vPayType AS pay ON pay.wCode = r.wPaymentMethod
    LEFT JOIN #vHotelPayType AS hotelPay ON hotelPay.wCode = r.wPaymentMethod
    LEFT JOIN #vCancelReason AS cancel ON cancel.wCode = r.wCancelReasonCd
    LEFT JOIN #vVoucher AS ev ON ev.wBookingRid = r.wBookingRid
    LEFT JOIN @vBookingStatus AS bs ON r.wBookingType NOT IN ('HOTEL', 'ROOM', 'CHANGEHOTEL', 'AIRTICKET', 'HELI') AND bs.wBookingStatus = r.wBookingStatus -- 房間預計不進行狀態判斷統計，因為每次都會在eBooking中生成一條新的記錄
    LEFT JOIN #vExpTran AS et ON -- 房间按金 et.wReferId = Hotel.wBookingRid， et.wRefRid = Room.RowID，其他预订: et.wReferId = xx.wBookingRid
            (et.wIsDeposit = 'Y' AND et.wBookingRid = r.wBookingRid AND (r.wBookingType NOT IN ('HOTEL', 'ROOM', 'CHANGEHOTEL') OR r.wBookingDtlRid = et.wRefRid) AND ISNULL(bs.wMapBookingStatus, '') != 'RF') --按金， 退款狀態屬於重複數據（RF --> C、RF），只需要選擇C狀態)
                OR
                (
                    et.wIsDeposit != 'Y'
                    AND et.wBookingRid = r.wBookingRid
                    AND (r.wBookingDtlRid = -1 OR r.wBookingDtlRid = et.wRefRid OR r.wBookingType IN ('HOTEL', 'ROOM', 'CHANGEHOTEL'))
                    AND (r.wHotelChangeRid = -1 OR CAST(r.wHotelChangeRid AS VARCHAR) = et.wShopName)
                    AND ((bs.wMapBookingStatus IS NULL AND r.wBookingType IN ('HOTEL', 'ROOM', 'CHANGEHOTEL'))
                        OR (ISNULL(bs.wMapBookingStatus, r.wBookingStatus) = 'C' AND ((ISNULL(r.wTotalAmount, 0) >= 0 AND et.wAmountActual_CRM > 0) OR (ISNULL(r.wTotalAmount, 0) < 0 AND et.wAmountActual_CRM < 0)))	-- 如果Booking中的總值小於0時，【完成】期望射數值小於0，其他情況期望射數值大於0
                            OR (ISNULL(bs.wMapBookingStatus, r.wBookingStatus) = 'RF' AND ((ISNULL(r.wTotalAmount, 0) >= 0 AND et.wAmountActual_CRM < 0) OR (ISNULL(r.wTotalAmount, 0) < 0 AND et.wAmountActual_CRM > 0))))	-- 如果Booking中的總值小於0時，【完成】期望射數值大於0，其他情況期望射數值小於0
                )
    LEFT JOIN #vZeroExpTran AS zet ON zet.wBookingRid = r.wBookingRid AND (r.wBookingDtlRid = -1 OR r.wBookingDtlRid = zet.wRefRid) AND (r.wHotelChangeRid = -1 OR CAST(r.wHotelChangeRid AS VARCHAR) = zet.wShopName)
    --正確射數，取射數表射數日期
    --只有eBooking.wBookingStatus = 'RF'，wCancelDebitDt不為空
    --如果射數表射數日期、取消扣數日期都為空，取eBooking.wDebitDt
    WHERE ISNULL(et.wDate, CASE WHEN ISNULL(bs.wMapBookingStatus, r.wBookingStatus) = 'RF' THEN r.wCancelDebitDt ELSE r.wDebitDt END) BETWEEN @pFromDt AND @pToDt
    OPTION(RECOMPILE);

    --SELECT * FROM #tmpResult;
    --SELECT * FROM #vExpTran
    --SELECT * FROM #vZeroExpTran
    --SELECT * FROM #vResult;

    --機票、直升機小單合併為一張大單
    CREATE TABLE #vAirTicketGroup(
        RowID BIGINT PRIMARY KEY,
        wMapBookingStatus VARCHAR(30),
        wTotalCost NUMERIC(18,4),
        wAmount NUMERIC(18,4),
        wAmountActual_CRM NUMERIC(18,4)
    );
    INSERT INTO #vAirTicketGroup(RowID, wMapBookingStatus, wTotalCost, wAmount, wAmountActual_CRM)
    SELECT
        RowID = MIN(RowID),
        wMapBookingStatus,
        wTotalCost = SUM(wTotalCost),
        wAmount = SUM(wAmount),
        wAmountActual_CRM = SUM(wAmountActual_CRM)
    FROM #vResult
    WHERE wIsDeposit != 'Y' AND ( wBookingTypeCode = 'AIRTICKET' OR wBookingTypeCode = 'HELI')
    GROUP BY wBookingRid, wMapBookingStatus, wCancelDt;
    
    -- 按金
    CREATE TABLE #vDepositGroup(
        RowID BIGINT,
        wExpTranRid BIGINT,
        PRIMARY KEY(RowID, wExpTranRid)
    );
    INSERT INTO #vDepositGroup(RowID, wExpTranRid)
    SELECT
        RowID = MIN(RowID),
        wExpTranRid
    FROM #vResult 
    WHERE wIsDeposit = 'Y'
    GROUP BY wExpTranRid;
    
    PRINT CONCAT(N'開始輸出', ' -- ', FORMAT(GETDATE(), @sDateTimeFormat));

    SELECT
        r.wBookingType,             -- 消費類型
        r.wRefNo,                   -- 訂單編號
        r.wRelatedBookingRefNo,     -- 相關訂務
        r.wDebitCounterName,        -- 扣數場館
        r.wReqCounterName,          -- 要求場館
        r.wDebitAgentCode,
        r.wDebitAgentName,          -- 扣數戶口
        r.wReqAgentCode,
        r.wReqAgentName,            -- 要求戶口
        r.wTranvalAgencyName,       -- 供應商名稱
        r.wOrderNo,                 -- 單號
        r.wPayMethod,               -- 付款方式
        r.wReceiptNo,               -- 現金單號
        r.wDateString,              -- 日期
        r.wQuantity,                -- 數量
        r.wRouteString,             -- 航線
        r.wTicketType,              -- 票類型
        r.wHotel,                   -- 酒店
        r.wDetail,                  -- 明細
        r.wCustomer,                -- 客人
        r.wBookingStatus,           -- 訂單狀態
        r.wRemark,                  -- 備註
        r.wCancelReason,            -- 取消原因 code
        r.wAsstBooker,              -- 代訂人
        r.wAsstBookerTel,           -- 代訂人電話
        r.wAssBookerEmail,          -- 代訂人電郵
        r.wFollowedDeptName,        -- 跟進部門
        r.wFollowedStaffName,       -- 跟進同事
        r.wApprovalAgentCode,       -- 確認戶主/授權人
        r.wApprovalAgentName,
        r.wEventCode,               -- 活動代碼
        r.wReqDeptName,             -- 要求部門
        r.wReqStaffID,              -- 要求同事
        r.wReqStaffName,            -- 要求同事
        r.wTravelPkgRefNo,          -- 旅遊套票
        r.wUseBlackCard,            -- 黑卡?
        r.wSameDebitDtCnt,          -- 最終要顯示  '1/wHotelSameDebitDtCnt'
        r.wDebitDt,
        r.wExpCategory,             -- 消費類型
        r.wIsDeposit,               -- 按金
        r.wCrtDt,                   -- 創建日期
        wTotalCost        = IIF(r.wIsDeposit = 'Y', 0, ISNULL(ag.wTotalCost, r.wTotalCost)),      -- 總成本（按金沒有成本）
        wAmount           = IIF(r.wIsDeposit = 'Y', r.wAmount, ISNULL(ag.wAmount, r.wAmount)),    -- 消費額
        wAmountActual_CRM = IIF(r.wIsDeposit = 'Y', r.wAmountActual_CRM, ISNULL(ag.wAmountActual_CRM, r.wAmountActual_CRM))   -- 總值
    FROM #vResult AS r
    LEFT JOIN #vAirTicketGroup AS ag ON ag.RowID = r.RowID AND ag.wMapBookingStatus = r.wMapBookingStatus -- 機票
    LEFT JOIN #vDepositGroup AS dg ON dg.RowID = r.RowID AND dg.wExpTranRid = r.wExpTranRid -- 按金
    WHERE (r.wIsDeposit = 'Y' AND dg.RowID IS NOT NULL) -- 按金
       OR (r.wIsDeposit != 'Y' AND ((r.wBookingTypeCode IN ('AIRTICKET', 'HELI') AND ag.RowID IS NOT NULL) OR (r.wBookingTypeCode NOT IN ('AIRTICKET', 'HELI') AND ag.RowID IS NULL)))
    --ORDER BY r.wRefNo, 
    --         r.wDebitDt
    OPTION(RECOMPILE);
    
    --刪除臨時表
    IF OBJECT_ID('tempdb..#vPayType') IS NOT NULL
        DROP TABLE #vPayType;

    IF OBJECT_ID('tempdb..#vHotelPayType') IS NOT NULL
        DROP TABLE #vHotelPayType;

    IF OBJECT_ID('tempdb..#vCancelReason') IS NOT NULL
        DROP TABLE #vCancelReason;

    IF OBJECT_ID('tempdb..#vAirTicketGroup') IS NOT NULL
        DROP TABLE #vAirTicketGroup;

    IF OBJECT_ID('tempdb..#vDepositGroup') IS NOT NULL
        DROP TABLE #vDepositGroup;

    IF OBJECT_ID('tempdb..#vExpTran') IS NOT NULL
        DROP TABLE #vExpTran;

    IF OBJECT_ID('tempdb..#vZeroExpTran') IS NOT NULL
        DROP TABLE #vZeroExpTran;

    IF OBJECT_ID('tempdb..#vDepartment') IS NOT NULL
        DROP TABLE #vDepartment;

    IF OBJECT_ID('tempdb..#vTravelPkg') IS NOT NULL
        DROP TABLE #vTravelPkg;

    IF OBJECT_ID('tempdb..#vVoucher') IS NOT NULL
        DROP TABLE #vVoucher;

    IF OBJECT_ID('tempdb..#tmpResult') IS NOT NULL
        DROP TABLE #tmpResult;

    IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
        DROP TABLE #vResult;
    PRINT CONCAT(N'結束', ' -- ', FORMAT(GETDATE(), @sDateTimeFormat));
END