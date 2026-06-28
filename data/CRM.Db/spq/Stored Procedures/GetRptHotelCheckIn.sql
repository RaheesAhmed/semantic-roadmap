CREATE PROCEDURE [spq].[GetRptHotelCheckIn]
	@pAgentCodeIn				VARCHAR(14),
	@pDebitCounter				VARCHAR(MAX),
	@pDebitCounterRegion		VARCHAR(1000),
	--@pHotel						VARCHAR(1000),
	@pHotelName					NVARCHAR(100),
	@pAgencyRoom				VARCHAR(1),
	@pCheckInStatus					VARCHAR(1),
	@pFromDt					DATETIME2(7),
	@pToDt						DATETIME2(7),
	@pLangCd					VARCHAR(10),
	@pErrorMsg					VARCHAR(200) = '' OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	IF @@trancount = 0
		SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

	SET @pAgentCodeIn			= ISNULL(@pAgentCodeIn, '');
	SET @pDebitCounter			= ISNULL(@pDebitCounter, '');
	SET @pDebitCounterRegion	= ISNULL(@pDebitCounterRegion, '');
	--SET @pHotel					= ISNULL(@pHotel, '');
	SET @pHotelName				= ISNULL(@pHotelName, '');
	SET @pAgencyRoom			= ISNULL(@pAgencyRoom, '');
	SET @pCheckInStatus				= ISNULL(@pCheckInStatus, '');
	SET @pLangCd				= ISNULL(@pLangCd, 'zh-TW');
	SET @pFromDt				= CASE WHEN @pFromDt IS NULL AND @pToDt IS NULL THEN NULL			-- 開始日期、與截止日期都為空
									WHEN @pFromDt IS NULL AND @pToDt IS NOT NULL THEN '1990-01-01'	-- 開始日期為空，截止日期不為空，使用默認值：'1990-01-01'
									ELSE FORMAT(@pFromDt, 'yyyy-MM-dd 00:00:00') END;				-- 開始日期不為空，只取日期，不要時間
	SET @pToDt					= CASE WHEN @pFromDt IS NULL AND @pToDt IS NULL THEN NULL			-- 開始日期、與截止日期都為空
									WHEN @pFromDt IS NOT NULL AND @pToDt IS NULL THEN FORMAT(GETDATE(), 'yyyy-MM-dd 23:59:59') -- 開始日期不為空，截止日期為空，使用默認值：當前系統時間
									ELSE FORMAT(@pToDt, 'yyyy-MM-dd 23:59:59') END;					-- 截止時間不為空， 只取日期，不要時間

	-- 扣數櫃台
	DECLARE @tmpFilterDebitCounter AS TABLE ( wCounterRid BIGINT );
	IF @pDebitCounter != '' BEGIN
		INSERT INTO @tmpFilterDebitCounter(wCounterRid) SELECT CAST(item AS BIGINT) FROM dbo.fnSplit(@pDebitCounter, ',');
	END;

	-- 扣數場館地區
	DECLARE @tmpFilterDebitCounterRegion AS TABLE ( wRegionCd VARCHAR(30) );
	IF @pDebitCounterRegion != '' BEGIN
		INSERT INTO @tmpFilterDebitCounterRegion(wRegionCd) SELECT item FROM dbo.fnSplit(@pDebitCounterRegion, ',');
	END;

	-- 酒店
	--DECLARE @tmpFilterHotel AS TABLE ( wHotelRid BIGINT );
	--IF @pHotel != '' BEGIN
	--	INSERT INTO @tmpFilterHotel(wHotelRid) SELECT CAST(item AS BIGINT) FROM dbo.fnSplit(@pHotel, ',');
	--END;

	-- 房間預訂狀態 = 處理中，每日入住記錄狀態 = 處理中
	-- 房間預訂狀態 = 完成，  每日入住記錄狀態 = 完成
	-- 房間預訂狀態 = 已入住，每日入住記錄狀態 = 完成
	-- 房間預訂狀態 = 已退房，每日入住記錄狀態 = 完成
	-- 房間預訂狀態 = 取消、不達標、已退款，沒有每日入住記錄
	-- 房間預訂最後一次【更改入住日期】的入住記錄
	-- 篩選房間預訂【每日入住記錄】重複記錄，只取最後一次修改記錄（wStatus = 'T'，每一天都有重複記錄）
	--WITH tHotelDailyCheckIn AS (
        --SELECT hci.*
        --FROM dbo.eHotelCheckIn AS hci
        --INNER JOIN (
        --    SELECT RowNum = ROW_NUMBER() OVER ( PARTITION BY wRoomBookingRid, wBookingDate ORDER BY wCrtDt DESC),
        --           RowID
        --    FROM dbo.eHotelCheckIn
        --) AS gci ON gci.RowID = hci.RowID 
        --WHERE gci.RowNum = 1
	--),
	-- 房間預訂【每日入住記錄】第一次扣數記錄
	-- 只有完成（C），提前入住（ECI）、續房（EX）有扣數記錄
	WITH tHotelCheckInDebit AS (
		SELECT 
			hci.wRoomBookingRid,
			hci.wBookingDate,
			eb.wDebitDt,
			dsc.wRegion,	-- 扣數地區
			eb.wDebitCounterRid,																		
			wDebitCounterName = dsc.wName,	-- 扣數櫃檯,
			eb.wDebitAgentCodeIn,
			wDebitAgentCode = dAgent.wAgentCode_Display,	-- 扣數戶口
			wDebitAgentName = CASE WHEN @pLangCd = 'en-GB' THEN dAgent.wEName ELSE dAgent.wCName END,	-- 扣數戶口名稱
			eb.wReqAgentCodeIn,
			wReqAgentCode = rAgent.wAgentCode_Display,	-- 扣數戶口
			wReqAgentName =  CASE WHEN @pLangCd = 'en-GB' THEN rAgent.wEName ELSE rAgent.wCName END,	-- 扣數戶口名稱
			hc.wPaymentMethod	-- 付款方式
		--FROM dbo.eHotelCheckIn AS hci
		--INNER JOIN(
		--	SELECT RowId = MIN(RowID)
		--	FROM dbo.eHotelCheckIn 
		--	WHERE wHotelChangeRid > 0
		--	GROUP BY wRoomBookingRid, wBookingDate
		--) AS gci ON gci.RowId = hci.RowID
		FROM (
			SELECT wHotelChangeRid = MAX(c.RowID), ci.wRoomBookingRid, ci.wBookingDate
			FROM dbo.eHotelCheckIn ci
			INNER JOIN dbo.eHotelChange c ON c.RowID = ci.wHotelChangeRid
			WHERE c.wAction IN ('C', 'ECI', 'EX') 
				AND ci.wHotelChangeRid > 0  
				AND ci.wBookingDate BETWEEN (CASE c.wAction 
												WHEN 'C' THEN c.wNewStartDate
												WHEN 'ECI' THEN c.wNewStartDate
												WHEN 'EX' THEN c.wOriEndDate
												END)
									AND
											(CASE c.wAction
											WHEN 'C' THEN c.wNewEndDate
											WHEN 'ECI' THEN c.wOriStartDate
											WHEN 'EX' THEN c.wNewEndDate
											END)
			GROUP BY ci.wRoomBookingRid, ci.wBookingDate
		) AS hci
		INNER JOIN dbo.eHotelChange AS hc ON hc.RowID = hci.wHotelChangeRid
		INNER JOIN dbo.eBooking AS eb ON eb.RowID = hc.wBookingRid
		LEFT JOIN RollsMary.dbo.mAgent AS dAgent ON dAgent.wAgentCodeIn = eb.wDebitAgentCodeIn	-- 扣數戶口
		LEFT JOIN RollsMary.dbo.mAgent AS rAgent ON rAgent.wAgentCodeIn = eb.wReqAgentCodeIn	-- 要求戶口
		LEFT JOIN dbo.mServiceCounter AS dsc ON dsc.RowID = eb.wDebitCounterRid		-- 扣數櫃檯
	)

	SELECT
		wBookingRefNo		= eb.wRefNo,		-- 房間預訂編號
		wRegionName			= (SELECT TOP(1) wTitle FROM mLookUp WHERE wType = 'REGION' AND wLangCd = @pLangCd AND wCode = (CASE WHEN debit.wRegion IS NOT NULL THEN debit.wRegion ELSE dsc.wRegion END)),	-- 扣數地區
		wDebitDt			= CASE WHEN debit.wDebitDt IS NOT NULL THEN debit.wDebitDt ELSE eb.wDebitDt END,	-- 扣數日期，查不到eHotelChange扣數日期，用eBooking扣數日期（舊數據）
		wDebitCounterName	= CASE WHEN debit.wDebitCounterName IS NOT NULL THEN debit.wDebitCounterName ELSE dsc.wName END,	-- 扣數櫃檯
		wBookingDt			= hci.wBookingDate,		-- 預訂日期
		wDebitAgentCode		= CASE WHEN debit.wDebitAgentCode IS NOT NULL THEN debit.wDebitAgentCode ELSE dAgent.wAgentCode_Display END,	-- 扣數戶口
		wDebitAgentName		= CASE WHEN debit.wDebitAgentName IS NOT NULL THEN debit.wDebitAgentName ELSE (CASE WHEN @pLangCd = 'en-GB' THEN dAgent.wEName ELSE dAgent.wCName END) END,	-- 扣數戶口名稱
		wReqAgentCode		= CASE WHEN debit.wReqAgentCode IS NOT NULL THEN debit.wReqAgentCode ELSE rAgent.wAgentCode_Display END, -- 扣數戶口
		wReqAgentName		= CASE WHEN debit.wReqAgentName IS NOT NULL THEN debit.wReqAgentName ELSE (CASE WHEN @pLangCd = 'en-GB' THEN rAgent.wEName ELSE rAgent.wCName END) END,		--扣數戶口名稱
		wPaymentMethod		= (SELECT TOP(1) wTitle FROM mLookUp WHERE wType = 'PAYMENT_TYPE_HOTEL' AND wLangCd = @pLangCd AND wCode = (CASE WHEN debit.wPaymentMethod IS NOT NULL THEN debit.wPaymentMethod ELSE br.wPaymentMethod END)), -- 付款方式
		wAgencyRoom			= CASE WHEN hci.wAgencyRoom = 'Y' THEN N'是' ELSE N'否' END, -- 是否外館房
		wHotelRegionName	= (SELECT TOP(1) wTitle FROM mLookUp WHERE wType = 'REGION' AND wLangCd = @pLangCd AND wCode = h.wRegion),	-- 酒店預訂地區
		wHotelName			= h.wName, -- 酒店名稱
		wHotelRoomName		= (SELECT TOP(1) wName FROM dbo.mHotelRoom WHERE RowID =  hci.wRoomRid),	-- 房間類型
		wAllotmentName		= (SELECT TOP(1) wName FROM dbo.mAllotmentGroup WHERE RowID = hci.wAllotmentGroupRid),		-- 配額名稱
		wExtentRoom			= CASE WHEN hci.wExtent = 'Y' THEN N'是' ELSE N'否' END,		-- 是否續房
		wCurrencyName		= (SELECT TOP(1) wTitle FROM dbo.mLookUp WHERE wType = 'CURRENCY' AND wLangCd = @pLangCd AND wCode = hci.wCurrCode),	-- 貨幣
		wDayPrice			= hci.wPrice,		-- 房間價格
		wDayCost			= hci.wCost,		-- 房間成本
		wStartDt			= br.wStartDate,	-- 入住日期
		wEndDt				= br.wEndtDate,		-- 退房日期
		wRoomNo				= hci.wRoomNo,		-- 房號
		wTotalAmount		= br.wTotalAmount,	-- 總值
		wTotalCost			= br.wTotalCost,	-- 總成本
		wStatus				= CASE br.wBookingStatus WHEN 'P' THEN N'處理中' ELSE N'完成' END,	-- 狀態
		wEventCode			= (SELECT TOP(1) wEventCode FROM dbo.mEventCode WHERE RowID = eb.wEventCodeRid) -- 活動代碼
	FROM dbo.eHotelCheckIn AS hci
	INNER JOIN dbo.eBookingRoom AS br ON br.RowID = hci.wRoomBookingRid
	INNER JOIN dbo.eBooking AS eb ON eb.RowID = br.wBookingRid
	LEFT JOIN tHotelCheckInDebit AS debit ON debit.wRoomBookingRid = hci.wRoomBookingRid AND debit.wBookingDate = hci.wBookingDate
	LEFT JOIN RollsMary.dbo.mAgent AS dAgent ON dAgent.wAgentCodeIn = eb.wDebitAgentCodeIn	-- 扣數戶口
	LEFT JOIN RollsMary.dbo.mAgent AS rAgent ON rAgent.wAgentCodeIn = eb.wReqAgentCodeIn	-- 要求戶口
	LEFT JOIN dbo.mServiceCounter AS dsc ON dsc.RowID = eb.wDebitCounterRid					-- 扣數櫃檯
	LEFT JOIN dbo.mHotel AS h ON h.RowID = hci.wHotelRid
	LEFT JOIN @tmpFilterDebitCounter AS dcfil ON dcfil.wCounterRid = ISNULL(debit.wDebitCounterRid, eb.wDebitCounterRid)
	LEFT JOIN @tmpFilterDebitCounterRegion AS regfil ON regfil.wRegionCd = ISNULL(debit.wRegion, dsc.wRegion)
	--LEFT JOIN @tmpFilterHotel AS hfil ON hfil.wHotelRid = hci.wHotelRid
	WHERE hci.wStatus = 'A' AND br.wBookingStatus IN ('P', 'C', 'CI', 'CO')
        AND (hci.wBookingDate BETWEEN br.wStartDate AND DATEADD(SECOND, -1, CAST(br.wEndtDate AS DATETIME2(7)))) -- 房間預訂日期，包含開始日期，不包含結束日期，應該用前一天日期（wEndDate - 1秒）
		AND (@pAgentCodeIn = '' OR @pAgentCodeIn = ISNULL(debit.wDebitAgentCodeIn, eb.wDebitAgentCodeIn))
		AND (@pDebitCounter = '' OR dcfil.wCounterRid IS NOT NULL)
		AND (@pDebitCounterRegion = '' OR regfil.wRegionCd IS NOT NULL)
		--AND (@pHotel = '' OR hfil.wHotelRid IS NOT NULL)
		AND (@pHotelName = '' OR h.wName LIKE CONCAT('%', @pHotelName, '%'))
		AND (@pAgencyRoom = '' OR @pAgencyRoom = hci.wAgencyRoom)
		AND (@pCheckInStatus = '' OR @pCheckInStatus = CASE WHEN br.wBookingStatus = 'P' THEN 'P' ELSE 'C' END)
		AND ((@pFromDt IS NULL AND @pToDt IS NULL) OR (hci.wBookingDate BETWEEN @pFromDt AND @pToDt)) 
	ORDER BY wBookingRefNo, wBookingDt
	OPTION(RECOMPILE);
END;