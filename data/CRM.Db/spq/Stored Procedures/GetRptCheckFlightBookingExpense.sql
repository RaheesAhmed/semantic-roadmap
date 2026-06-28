
CREATE PROCEDURE [spq].[GetRptCheckFlightBookingExpense]
      @pAgentCodeIn VARCHAR(14),
      @pDebitCounter NVARCHAR(MAX),
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
		wPassengerRefNo         VARCHAR(30) DEFAULT '',     -- 小單編號
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
		wPassengerDateString    NVARCHAR(500),              -- 小單日期
		wBookingDateString	    NVARCHAR(500),              -- 大單单日期
		wQuantity               INT,                        -- 數量
		wPassengerRouteString	NVARCHAR(2000),             -- 大单航線
		wBookingRouteString     NVARCHAR(2000),             -- 小單航線
		wTicketType             NVARCHAR(100),              -- 票類型
		wHotel                  NVARCHAR(500),              -- 酒店
		wPassengerDetail        NVARCHAR(4000),             -- 小單明細
		wBookingDetail          NVARCHAR(4000),             -- 大單明細
		wCustomer               NVARCHAR(200),              -- 客人
		wBookingCustomer        NVARCHAR(2000),             -- 訂單所有客戶（按金,需要匯成所有客戶）
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
		wUseBlackCard           NCHAR(1),                   -- 黑卡?
		wSameDebitDtCnt         VARCHAR(10),                -- 最終要顯示  '1/wSameDebitDtCnt'
		wCrtDt                  DATETIME2(7),               -- 創建日期
		-- using for joining eExpTran
		wBookingRid             BIGINT DEFAULT -1,
		wBookingDtlRid          BIGINT DEFAULT -1,          -- Passenger
	);

	-- 直升機
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
			rpd.wSeqNo,
			wPassengerBookingStatus = rps.wMapBookingStatus,
			wCustomer = CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN rp.wEName ELSE rp.wCName END, CASE WHEN NULLIF(rptd.wEnglishPinyin, '') IS NULL THEN NULL ELSE ' (' + rptd.wEnglishPinyin + ')' END),
			wBookingCustomer = CASE WHEN eb.wHasDeposit != 'Y' THEN NULL ELSE(STUFF(
				(SELECT CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN sp.wEName ELSE sp.wCName END, CASE WHEN NULLIF(sptd.wEnglishPinyin, '') IS NULL THEN NULL ELSE ' (' + sptd.wEnglishPinyin + ')' END)
				FROM dbo.ePassengerDetails AS spd
				INNER JOIN dbo.mPerson AS sp ON sp.RowID = spd.wPersonRid AND spd.wBookingRid = rpd.wBookingRid AND spd.wStatus = 'A'
				LEFT JOIN dbo.ePassengerTravelDocDetail AS sptdd ON spd.RowID = sptdd.wPassengerDetailsRid
				LEFT JOIN dbo.mPersonTravelDoc AS sptd ON sptdd.wPersonTravelDocRid = sptd.RowID
				WHERE sptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = spd.RowID)
				FOR XML PATH('')), 1, 1, N'')) END
		INTO #tCFNHeliPassenger
		FROM dbo.eBookingHeli AS heli
		INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'HELI' AND heli.wStatus = 'A' AND heli.wIsCharteredFlight != 'Y' AND eb.RowID = heli.wBookingRid
		INNER JOIN dbo.ePassengerDetails AS rpd ON rpd.wBookingRid > 0 AND rpd.wStatus = 'A' AND rpd.wBookingRid = heli.wBookingRid
		INNER JOIN @tmpBookingStatus AS rps ON rps.wBookingStatus = rpd.wPassengerBookingStatus
		INNER JOIN dbo.mPerson AS rp ON rpd.wPersonRid = rp.RowID
		LEFT JOIN dbo.ePassengerTravelDocDetail AS rptdd ON rpd.RowID = rptdd.wPassengerDetailsRid
		LEFT JOIN dbo.mPersonTravelDoc AS rptd ON rptdd.wPersonTravelDocRid = rptd.RowID
		LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
		WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
			AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
			AND ((rps.wMapBookingStatus = 'C' AND eb.wDebitDt BETWEEN @pFromDt AND @pToDt)
				OR (rps.wMapBookingStatus = 'RF' AND rpd.wCancelDebitDt BETWEEN @pFromDt AND @pToDt)
				OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
			AND rptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = rpd.RowID) -- 取第一個有有效證件，否則有重複數據

		INSERT INTO #tmpResult (
			wBookingType,
			wDebitDt,
			wCancelDebitDt,
			wCancelDt,
			wRefNo,
			wPassengerRefNo,
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
			wPassengerDateString,
			wBookingDateString,
			wQuantity,
			wPassengerRouteString,
			wBookingRouteString,
			wTicketType,
			wHotel,
			wPassengerDetail,
			wBookingDetail,
			wCustomer,
			wBookingCustomer,
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
			wCrtDt,
			wBookingRid,
			wBookingDtlRid
		)
		SELECT
			wBookingType = eb.wBookingType,
			wDebitDt = eb.wDebitDt,
			wCancelDebitDt = CASE WHEN heli.wIsCharteredFlight = 'Y' THEN eb.wCancelDebitDt ELSE pd.wCancelDebitDt END,
			wCancelDt = CASE WHEN heli.wIsCharteredFlight = 'Y' THEN eb.wCancelDt ELSE pd.wCancelDt END,
			wRefNo = eb.wRefNo,
			wPassengerRefNo= CONCAT(eb.wRefNo, CASE WHEN pd.wSeqNo IS NULL THEN NULL ELSE '-' END, RIGHT('000' + CAST(pd.wSeqNo AS VARCHAR), 3)),
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
			wPassengerDateString = FORMAT(pd.wTakeOffDt, @sDateTimeFormat), -- 小單出發時間
			wBookingDateString = FORMAT(heli.wDepartDt, @sDateTimeFormat),  -- 大單出發時間
			wQuantity = heli.wQuantity,
			wPassengerRouteString = pr.wRouteTitle, -- 小單航線
			wBookingRouteString = hr.wRouteTitle,   -- 大單航線
			wTicketType = NULL,
			wHotel = NULL,
			wPassengerDetail = CONCAT(N'包機：', CASE heli.wIsCharteredFlight WHEN 'Y' THEN N'是' ELSE N'否' END),
			wBookingDetail = CONCAT(N'包機：', CASE heli.wIsCharteredFlight WHEN 'Y' THEN N'是' ELSE N'否' END),
			wCustomer = CASE WHEN heli.wIsCharteredFlight = 'Y' THEN p.wCustomer ELSE pd.wCustomer END,
			wBookingCustomer = CASE WHEN heli.wIsCharteredFlight = 'Y' THEN p.wCustomer ELSE pd.wBookingCustomer END,
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
			wCrtDt = heli.wCrtDt,
			wBookingRid = eb.RowID,
			wBookingDtlRid = CASE WHEN heli.wIsCharteredFlight = 'Y' THEN -1 ELSE pd.RowID END
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

	-- 機票
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
				WHERE sard.wTypeRid = rard.wTypeRid AND sard.wType = rard.wType AND sard.wStatus = 'A'
				ORDER BY sard.wLine
				FOR XML PATH(''),TYPE).value('text()[1]','nvarchar(max)'), 1, 1, N''),
			wRouteTime = STUFF(
				(SELECT CONCAT(CHAR(10), FORMAT(sard.wTakeOffDt, @sShortDateTimeFormat), '->', FORMAT(sard.wArrivalDt, @sShortDateTimeFormat))
				FROM dbo.eAirTicketRouteDtl AS sard
				WHERE sard.wTypeRid = rard.wTypeRid AND sard.wType = rard.wType AND sard.wStatus = 'A'
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
				WHERE sard.wTypeRid = rard.wTypeRid AND sard.wType = rard.wType AND sard.wStatus = 'A'
				ORDER BY sard.wLine
				FOR XML PATH('')), 1, 1, N''),
			wAirlines = STUFF(
				(SELECT CONCAT(', ', lu.wTitle)
				FROM dbo.eAirTicketRouteDtl AS sard
				LEFT JOIN dbo.mLookUp AS lu ON lu.wLangCd = @pLangCd AND lu.wType = 'AIRLINES' AND sard.wAirline = lu.wCode
				WHERE sard.wTypeRid = rard.wTypeRid AND sard.wType = rard.wType AND sard.wStatus = 'A'
				GROUP BY lu.wTitle
				FOR XML PATH('')), 1, 2, N'')	
		INTO #tAirRoute
		FROM dbo.eAirTicketRouteDtl AS rard
		  -- 大单
		  LEFT JOIN dbo.eBookingAirTicket AS air ON air.wStatus = 'A' AND air.RowID = rard.wTypeRid AND rard.wType = 'AIRTICKET'
		  LEFT JOIN dbo.eBooking AS eb ON eb.wBookingType = 'AIRTICKET' AND eb.RowID = air.wBookingRid
		  LEFT JOIN @tmpFilterCounter AS afil ON afil.wCounterRid = eb.wDebitCounterRid
		  -- 小单
		  LEFT JOIN dbo.ePassengerDetails AS pd ON ISNULL(pd.wBookingRid, 0) > 0 AND pd.wStatus = 'A' AND pd.RowID = rard.wTypeRid AND rard.wType = 'PASSENGER'
		  LEFT JOIN dbo.eBooking AS pb ON pb.wBookingType = 'AIRTICKET' AND pb.RowID = pd.wBookingRid
		  LEFT JOIN @tmpFilterCounter AS pfil ON pfil.wCounterRid = pb.wDebitCounterRid
		  WHERE (rard.wType = 'AIRTICKET' OR rard.wType = 'PASSENGER') AND rard.wStatus = 'A' AND wTypeRid > 0
			  AND (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn OR pb.wDebitAgentCodeIn = @pAgentCodeIn) -- 大、小單扣數戶口
			  AND (@pDebitCounter IS NULL OR afil.wCounterRid IS NOT NULL OR pfil.wCounterRid IS NOT NULL) -- 大、小單扣數櫃檯
			  AND (eb.wDebitDt BETWEEN @pFromDt AND @pToDt -- 大單扣數日期
				OR pb.wDebitDt BETWEEN @pFromDt AND @pToDt -- 小單扣數日期
				OR ISNULL(eb.wCancelDebitDt, @sStartDateTime) BETWEEN @pFromDt AND @pToDt -- 大單取消扣數日期
				OR ISNULL(pd.wCancelDebitDt, ISNULL(pb.wCancelDebitDt, @sStartDateTime)) BETWEEN @pFromDt AND @pToDt -- 小單取消扣數日期
				OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt) -- 按金
				OR (pb.wHasDeposit = 'Y' AND pb.wUpdDt > @pFromDt AND pb.wCrtDt < @pToDt))
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
			rpd.wSeqNo,
			wPassengerBookingStatus = rps.wMapBookingStatus,
			wCustomer = CONCAT(CASE WHEN @pLangCd = 'en-GB' THEN rp.wEName ELSE rp.wCName END, CASE WHEN NULLIF(rptd.wEnglishPinyin, '') IS NULL THEN NULL ELSE ' (' + rptd.wEnglishPinyin + ')' END),
			wBookingCustomer = STUFF(
				(SELECT CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN sp.wEName ELSE sp.wCName END, CASE WHEN NULLIF(sptd.wEnglishPinyin, '') IS NULL THEN NULL ELSE ' (' + sptd.wEnglishPinyin + ')' END)
				FROM dbo.ePassengerDetails AS spd
				INNER JOIN dbo.mPerson AS sp ON spd.wPersonRid = sp.RowID AND spd.wBookingRid = rpd.wBookingRid AND spd.wStatus = 'A'
				LEFT JOIN dbo.ePassengerTravelDocDetail AS sptdd ON spd.RowID = sptdd.wPassengerDetailsRid
				LEFT JOIN dbo.mPersonTravelDoc AS sptd ON sptdd.wPersonTravelDocRid = sptd.RowID
				WHERE sptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = spd.RowID)
				FOR XML PATH('')), 1, 1, N''),
			wClientTicketNo = CASE WHEN NULLIF(rpd.wClientTicketNo, '') IS NULL THEN NULL ELSE CONCAT(CASE WHEN @pLangCd = 'en-GB' THEN rp.wEName ELSE rp.wCName END, '(', rpd.wClientTicketNo , ') ') END,
			wBookingTicketNo = STUFF(
				(SELECT CASE WHEN NULLIF(spd.wClientTicketNo, '') IS NULL THEN NULL ELSE CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN p.wEName ELSE p.wCName END, '(', spd.wClientTicketNo , ') ') END
				FROM dbo.ePassengerDetails AS spd
				INNER JOIN dbo.mPerson AS p ON p.RowID = spd.wPersonRid
				WHERE spd.wBookingRid = rpd.wBookingRid AND spd.wStatus = 'A'
				FOR XML PATH('')), 1, 1, N'')
		INTO #tAirPassenger
		FROM dbo.eBookingAirTicket AS air
		INNER JOIN dbo.eBooking AS eb ON eb.wBookingType = 'AIRTICKET' AND air.wStatus = 'A' AND eb.RowID = air.wBookingRid
		INNER JOIN dbo.ePassengerDetails AS rpd ON rpd.wBookingRid > 0 AND rpd.wStatus = 'A' AND rpd.wBookingRid = air.wBookingRid
		INNER JOIN @tmpBookingStatus AS rps ON rps.wBookingStatus = rpd.wPassengerBookingStatus
		INNER JOIN dbo.mPerson AS rp ON rpd.wPersonRid = rp.RowID
		LEFT JOIN dbo.ePassengerTravelDocDetail AS rptdd ON rpd.RowID = rptdd.wPassengerDetailsRid
		LEFT JOIN dbo.mPersonTravelDoc AS rptd ON rptdd.wPersonTravelDocRid = rptd.RowID
		LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
		WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
			AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
			AND ((rps.wMapBookingStatus = 'C' AND eb.wDebitDt BETWEEN @pFromDt AND @pToDt)
				OR (rps.wMapBookingStatus = 'RF' AND rpd.wCancelDebitDt BETWEEN @pFromDt AND @pToDt)
				OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))
			AND rptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = rpd.RowID) -- 取第一個有有效證件，否則有重複數據

		INSERT INTO #tmpResult (
			wBookingType,
			wDebitDt,
			wCancelDebitDt,
			wCancelDt,
			wRefNo,
			wPassengerRefNo,
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
			wPassengerDateString,
			wBookingDateString,
			wQuantity,
			wPassengerRouteString,
			wBookingRouteString,
			wTicketType,
			wHotel,
			wPassengerDetail,
			wBookingDetail,
			wCustomer,
			wBookingCustomer,
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
			wCrtDt,
			wBookingRid,
			wBookingDtlRid
		)
		SELECT
			wBookingType = eb.wBookingType,
			wDebitDt = eb.wDebitDt,
			wCancelDebitDt = pd.wCancelDebitDt,
			wCancelDt = pd.wCancelDt,
			wRefNo = eb.wRefNo,
			wPassengerRefNo= CONCAT(eb.wRefNo, CASE WHEN pd.wSeqNo IS NULL THEN NULL ELSE '-' END, RIGHT('000' + CAST(pd.wSeqNo AS VARCHAR), 3)),
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
			wPassengerDateString = pr.wRouteTime,
			wBookingDateString = ar.wRouteTime,
			wQuantity = air.wQuantity,
			wPassengerRouteString = pr.wRouteTitle,
			wBookingRouteString = ar.wRouteTitle,
			wTicketType = NULL,
			wHotel = NULL,
			wPassengerDetail = CONCAT(N'預訂類型：', tType.wTitle, char(10), 
							N'航空公司：', pr.wAirlines , char(10), 
							N'到期日：', CASE WHEN air.wExpiryDt IS NOT NULL THEN FORMAT(air.wExpiryDt, @sDateFormat) ELSE NULL END, char(10),
							pr.wFlight, char(10),
							N'票號：', pd.wClientTicketNo),
			wBookingDetail = CONCAT(N'預訂類型：', tType.wTitle, char(10), 
							N'航空公司：',ar.wAirlines ,char(10), 
							N'到期日：', CASE WHEN air.wExpiryDt IS NOT NULL THEN FORMAT(air.wExpiryDt, @sDateFormat) ELSE NULL END, char(10),
							ar.wFlight , char(10),
							N'票號：', pd.wBookingTicketNo),
			wCustomer = pd.wCustomer,
			wBookingCustomer= pd.wBookingCustomer,
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
			wCrtDt = air.wCrtDt,
			wBookingRid = eb.RowID,
			wBookingDtlRid = pd.RowID
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
		pkg.RowID,
		pkg.wBookingRid,
		b.wRefNo
	INTO #tTravelPkg
	FROM dbo.eBookingTravelPackage AS pkg
	INNER JOIN dbo.eBooking b ON b.RowID = pkg.wBookingRid
	WHERE EXISTS (SELECT 1 FROM #tmpResult WHERE wTravelPkgRid = pkg.RowID);
	
	-- 消費券
	SELECT
		ev.wBookingRid,
		wVoucher = STUFF(
			(SELECT N', ' + CAST(m.wVoucherRefNo AS NVARCHAR)
			From dbo.eVoucher AS sv
			INNER JOIN dbo.mVoucher AS m ON m.RowID = sv.wVoucherRid AND sv.wBookingRid = ev.wBookingRid
			FOR XML PATH('')), 1, 2, N'')
	INTO #tVoucher
	FROM dbo.eVoucher AS ev
	WHERE EXISTS (SELECT 1 FROM #tmpResult WHERE wBookingRid = ev.wBookingRid)
	GROUP BY ev.wBookingRid;

	SELECT
		RowId = tmp.RowId,
		wBookingRid = tmp.wBookingRid,
		wBookingTypeCode = tmp.wBookingType,
		wMapBookingStatus = tmp.wBookingStatus,
		wExpTranRid = et.RowID,
		wCurDateTime = et.wCurDateTime,
		wBookingType = (
				CASE WHEN @pLangCd = 'en-GB' THEN UPPER(tmp.wBookingType)
				ELSE ( 
					CASE tmp.wBookingType
					WHEN 'AIRTICKET'			THEN N'機票'
					WHEN 'HELI'					THEN N'直升機'
					ELSE UPPER(tmp.wBookingType) END
				) END
			),				-- 消費類型
		wRefNo = CASE WHEN et.wIsDeposit ='Y' THEN tmp.wRefNo ELSE tmp.wPassengerRefNo END,	-- 訂單編號
		wDebitCounterName = dsc.wName,	-- 扣數場館
		wReqCounterName = rsc.wName,	-- 要求場館
		wDebitAgentCode = aDebit.wAgentCode_Display,
		wDebitAgentName = CASE WHEN @pLangCd = 'en-GB' THEN aDebit.wEName ELSE aDebit.wCName END,	-- 扣數戶口
		wReqAgentCode = aReq.wAgentCode_Display,
		wReqAgentName = CASE WHEN @pLangCd = 'en-GB' THEN aReq.wEName ELSE aReq.wCName END,			-- 要求戶口
		tmp.wTranvalAgencyName,		-- 供應商名稱
		tmp.wOrderNo,				-- 單號
		wPayMethod = pay.wTitle,	-- 付款方式
		tmp.wReceiptNo,				-- 現金單號
		wIsDeposit = et.wIsDeposit,
		wTotalCost = CASE WHEN et.wIsDeposit = 'Y' THEN 0 ELSE (CASE WHEN (et.wAmount < 0 OR et.wAmountActual_CRM < 0) AND tmp.wTotalCost > 0 THEN -1 * tmp.wTotalCost ELSE tmp.wTotalCost END) END,	-- 總成本
		wDateString = CASE WHEN et.wIsDeposit = 'Y' THEN tmp.wBookingDateString ELSE tmp.wPassengerDateString END,		-- 日期
		wQuantity = CASE WHEN et.wIsDeposit = 'Y' THEN tmp.wQuantity ELSE 1 END,	-- 數量
		wRouteString = CASE WHEN et.wIsDeposit = 'Y' THEN tmp.wBookingRouteString ELSE tmp.wPassengerRouteString END,	-- 航線
		tmp.wTicketType,		-- 票類型
		tmp.wHotel,				-- 酒店
		wDetail = CONCAT(CASE WHEN et.wIsDeposit = 'Y' THEN tmp.wBookingDetail ELSE tmp.wPassengerDetail END, CASE WHEN NULLIF(ev.wVoucher, '') IS NULL THEN NULL ELSE CHAR(10) + N'消費券：' + ev.wVoucher END),-- 明細
		wCustomer = CASE WHEN et.wIsDeposit = 'Y' THEN tmp.wBookingCustomer ELSE tmp.wCustomer END,		-- 客人
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
		wDebitDt = ISNULL(et.wDate, CASE WHEN tmp.wBookingStatus = 'RF' THEN tmp.wCancelDebitDt ELSE tmp.wDebitDt END),
		tmp.wCancelDt,	-- 取消日期
		tmp.wCrtDt,
		wExpCategory = CASE WHEN @pLangCd = 'en-GB' THEN UPPER(tmp.wBookingType) ELSE N'行' END,
		-- 射數為0，取射數第一條記錄的值
		-- 當射數為0時，Join不到射數值，取第一條射數為0的記錄
		--（目前，如果【完成】、【退款】其中一條射數失敗，最後兩條都會有值【0】，都是【0】影響不大，後面在射數表wBookingStatus賦值后能解決此問題）
		wAmount = ISNULL(et.wAmount, zet.wAmount),
		wAmountActual_CRM = ISNULL(et.wAmountActual_CRM, zet.wAmountActual_CRM )
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
	LEFT JOIN dbo.mLookUp AS cancel ON cancel.wLangCd = @pLangCd AND cancel.wType = 'CANCEL_REASON' AND cancel.wCode = tmp.wCancelReasonCd
	LEFT JOIN #tVoucher AS ev ON ev.wBookingRid = tmp.wBookingRid
	LEFT JOIN #tExpTran AS et ON  -- 房间按金 et.wReferId = Hotel.wBookingRid， et.wRefRid = Room.RowId，其他预订: et.wReferId = xx.wBookingRid
			(et.wIsDeposit = 'Y' AND et.wBookingRid = tmp.wBookingRid AND tmp.wBookingStatus != 'RF' ) --按金， 退款狀態屬於重複數據（RF --> C、RF），只需要選擇C狀態)
			OR
			(et.wIsDeposit != 'Y'
			AND et.wBookingRid = tmp.wBookingRid
			AND (tmp.wBookingDtlRid = -1 OR tmp.wBookingDtlRid = et.wRefRid)
			AND ((tmp.wBookingStatus = 'C' AND ((ISNULL(tmp.wTotalAmount, 0) >= 0 AND et.wAmountActual_CRM > 0) OR (ISNULL(tmp.wTotalAmount, 0) < 0 AND et.wAmountActual_CRM < 0)))	-- 如果Booking中的總值小於0時，【完成】期望射數值小於0，其他情況期望射數值大於0
				OR (tmp.wBookingStatus = 'RF' AND ((ISNULL(tmp.wTotalAmount, 0) >= 0 AND et.wAmountActual_CRM < 0) OR (ISNULL(tmp.wTotalAmount, 0) < 0 AND et.wAmountActual_CRM > 0))))	-- 如果Booking中的總值小於0時，【完成】期望射數值大於0，其他情況期望射數值小於0
			)
	LEFT JOIN #tZeroExpTran AS zet ON zet.wBookingRid = tmp.wBookingRid AND (tmp.wBookingDtlRid = -1 OR tmp.wBookingDtlRid = zet.wRefRid)
	--正確射數，取射數表射數日期
	--只有eBooking.wBookingStatus = 'RF'，wCancelDebitDt不為空
	--如果射數表射數日期、取消扣數日期都為空，取eBooking.wDebitDt
	WHERE ISNULL(et.wDate, CASE WHEN tmp.wBookingStatus = 'RF' THEN tmp.wCancelDebitDt ELSE tmp.wDebitDt END) BETWEEN @pFromDt AND @pToDt
	AND ((et.wIsDeposit != 'Y') OR (et.wIsDeposit = 'Y' AND (tmp.wBookingDtlRid = (SELECT MIN(wBookingDtlRid) FROM #tmpResult WHERE wBookingRid = tmp.wBookingRid)))) 

	--SELECT * FROM #tmpResult;
	--SELECT * FROM #tExpTran
	--SELECT * FROM #tZeroExpTran
	--SELECT * FROM #tResult;

	SELECT
		tmp.wBookingType,				-- 消費類型
		tmp.wRefNo,						-- 訂單編號
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
		wTotalCost = tmp.wTotalCost,	-- 總成本
		wAmount =  tmp.wAmount,			-- 消費額
		wAmountActual_CRM = tmp.wAmountActual_CRM	-- 總值
	FROM #tResult AS tmp
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