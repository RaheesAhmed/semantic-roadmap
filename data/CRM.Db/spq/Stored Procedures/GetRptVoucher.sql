CREATE PROCEDURE [spq].[GetRptVoucher]
	@pAgentCodeIn	VARCHAR(14),
	@pDebitCounter	VARCHAR(MAX),
	@pVoucherType	VARCHAR(1000),
	@pVoucherStatus VARCHAR(1000),
	@pVoucherNo		VARCHAR(50),
	@pFromDt		DATETIME2(7),
	@pToDt			DATETIME2(7),
	@pLangCd		VARCHAR(20) = 'zh-TW',
	@pErrorMsg		VARCHAR(200) = '' OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	IF @@trancount = 0
		SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

	SET @pAgentCodeIn	= ISNULL(@pAgentCodeIn, '');
	SET @pDebitCounter	= ISNULL(@pDebitCounter, '');
	SET @pVoucherType	= ISNULL(@pVoucherType, '');
	SET @pVoucherNo		= ISNULL(@pVoucherNo, '');
	SET @pVoucherStatus = ISNULL(@pVoucherStatus, '');
	SET @pLangCd		= ISNULL(@pLangCd, 'zh-TW');
	-- 開始、截止日期要麼都是空，要麼都不為空（空時用默認值）
	SET @pFromDt		= CASE WHEN @pFromDt IS NULL AND @pToDt IS NULL THEN NULL			-- 開始日期、與截止日期都為空
						  WHEN @pFromDt IS NULL AND @pToDt IS NOT NULL THEN '1990-01-01'	-- 開始日期為空，截止日期不為空，使用默認值：'1990-01-01'
						  ELSE FORMAT(@pFromDt, 'yyyy-MM-dd 00:00:00') END;					-- 開始日期不為空，只取日期，不要時間
	SET @pToDt			= CASE WHEN @pFromDt IS NULL AND @pToDt IS NULL THEN NULL			-- 開始日期、與截止日期都為空
						  WHEN @pFromDt IS NOT NULL AND @pToDt IS NULL THEN FORMAT(GETDATE(), 'yyyy-MM-dd 23:59:59') -- 開始日期不為空，截止日期為空，使用默認值：當前系統時間
						  ELSE FORMAT(@pToDt, 'yyyy-MM-dd 23:59:59') END;					-- 截止時間不為空， 只取日期，不要時間

	-- 扣數櫃台
	DECLARE @tmpFilterDebitCounter AS TABLE ( wCounterRid BIGINT );
	IF @pDebitCounter != '' BEGIN
		INSERT INTO @tmpFilterDebitCounter(wCounterRid) SELECT CAST(item AS BIGINT) FROM dbo.fnSplit(@pDebitCounter, ',');
	END;

	-- 消費券種類
	DECLARE @tmpFilterVoucherType TABLE ( wCode VARCHAR(30) );
	IF @pVoucherType != '' BEGIN
		INSERT INTO @tmpFilterVoucherType(wCode) SELECT item FROM dbo.fnSplit(@pVoucherType, ',');
	END;

	-- 狀態
	DECLARE @tmpFilterVoucherStatus TABLE (wCode VARCHAR(30));
	IF @pVoucherStatus != '' BEGIN
		INSERT INTO @tmpFilterVoucherStatus(wCode) SELECT item FROM dbo.fnSplit(@pVoucherStatus, ',');
	END;

	SELECT
		wBookingRefNo = eb.wRefNo,						-- 預訂編號
		wDebitDt = eb.wDebitDt,							-- 扣數日期
		wDebitCounterName = dsc.wName,					-- 扣數場館
		wDebitAgentCode = aDebit.wAgentCode_Display,	-- 扣數戶口
		wDebitAgentName = CASE WHEN @pLangCd = 'en-GB' THEN aDebit.wEName ELSE aDebit.wCName END, -- 扣數戶口
		wAddExpRefNo = ae.wOrderNo,			-- 其它消費單號
		wAddExpTotalAmt = ae.wTotalAmt,		-- 總值
		wVoucherType = vtype.wTitle,		-- 消費券種類
		mv.wVoucherRefNo,					-- 消費券編號
		mv.wVoucherValue,					-- 消費券票價
		wVoucherStatus = sType.wTitle		-- 消費券狀態
	FROM dbo.mVoucher AS mv
	LEFT JOIN dbo.eVoucher AS ev ON ev.wVoucherRid = mv.RowID
	LEFT JOIN dbo.eBooking AS eb ON eb.RowID = ev.wBookingRid
	LEFT JOIN RollsMary.dbo.mAgent aDebit ON aDebit.wAgentCodeIn = eb.wDebitAgentCodeIn
	LEFT JOIN dbo.mServiceCounter AS dsc ON dsc.RowID = eb.wDebitCounterRid
	LEFT JOIN dbo.eAdditionalExpense AS ae ON ( eb.wBookingType = 'ADDITIONALEXPENSES' AND ae.wBookingRefRid = eb.RowID) -- 只顯示其他消費的單號、總值
	LEFT JOIN (SELECT * FROM dbo.mLookUp WHERE wType = 'VOUCHER_TYPE' AND wLangCd = @pLangCd) AS vtype ON vtype.wCode = mv.wVoucherType
	LEFT JOIN (SELECT * FROM dbo.mLookUp WHERE wType = 'VOUCHER_STATUS' AND wLangCd =@pLangCd) AS sType ON sType.wCode = mv.wVoucherStatus
	LEFT JOIN @tmpFilterDebitCounter AS dcfil ON dcfil.wCounterRid = eb.wDebitCounterRid
	LEFT JOIN @tmpFilterVoucherType AS vtfil ON vtfil.wCode = mv.wVoucherType
	LEFT JOIN @tmpFilterVoucherStatus AS vsfil ON vsfil.wCode = mv.wVoucherStatus
	WHERE (@pVoucherNo != '' AND @pVoucherNo = CAST(mv.wVoucherRefNo AS VARCHAR))	-- 如果提供具體編號，不判斷其他篩選條件
		OR (
		@pVoucherNo = '' AND mv.wStatus = 'A'
		AND (@pAgentCodeIn = '' OR @pAgentCodeIn = eb.wDebitAgentCodeIn )
		AND (@pDebitCounter = '' OR dcfil.wCounterRid IS NOT NULL)
		AND (@pVoucherType = '' OR vtfil.wCode IS NOT NULL)
		AND (@pVoucherStatus = '' OR vsfil.wCode IS NOT NULL)
		AND ((@pFromDt IS NULL AND @pToDt IS NULL) OR (eb.wDebitDt BETWEEN @pFromDt AND @pToDt))  -- 時間Filter都為空，返回所有數據，
		)
	ORDER BY eb.wDebitDt DESC, mv.wVoucherRefNo
	OPTION(RECOMPILE);
END;