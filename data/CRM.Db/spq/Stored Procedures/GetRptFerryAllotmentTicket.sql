CREATE PROCEDURE [spq].[GetRptFerryAllotmentTicket]
	@pAgentCodeIn		VARCHAR(14),
	@pTicketType		NVARCHAR(1000), 
	@pTicketNo			VARCHAR(50),
	@pTicketClass		VARCHAR(1000),
	@pTicketStatus		VARCHAR(1000),
	@pFromDt			DATETIME2(7),
	@pToDt				DATETIME2(7),
	@pLangCd			VARCHAR(20) = 'zh-TW',
	@pErrorMsg			VARCHAR(200) = '' OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	IF @@trancount = 0
		SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

	SET @pAgentCodeIn	= ISNULL(@pAgentCodeIn, '');
	SET @pTicketType	= ISNULL(@pTicketType, '');
	SET @pTicketNo		= ISNULL(@pTicketNo, '');
	SET @pTicketClass = ISNULL(@pTicketClass, '');
	SET @pTicketStatus	= ISNULL(@pTicketStatus, '');
	SET @pLangCd		= ISNULL(@pLangCd, 'zh-TW');
	--開始、截止日期要麼都是空，要麼都不為空（空時用默認值）
	SET @pFromDt		= CASE WHEN @pFromDt IS NULL AND @pToDt IS NULL THEN NULL			-- 開始日期、與截止日期都為空
						  WHEN @pFromDt IS NULL AND @pToDt IS NOT NULL THEN '1990-01-01'	-- 開始日期為空，截止日期不為空，使用默認值：'1990-01-01'
						  ELSE FORMAT(@pFromDt, 'yyyy-MM-dd 00:00:00') END;					-- 開始日期不為空，只取日期，不要時間
	SET @pToDt			= CASE WHEN @pFromDt IS NULL AND @pToDt IS NULL THEN NULL			-- 開始日期、與截止日期都為空
						  WHEN @pFromDt IS NOT NULL AND @pToDt IS NULL THEN FORMAT(GETDATE(), 'yyyy-MM-dd 23:59:59') -- 開始日期不為空，截止日期為空，使用默認值：當前系統時間
						  ELSE FORMAT(@pToDt, 'yyyy-MM-dd 23:59:59') END;					-- 截止時間不為空， 只取日期，不要時間
	
	-- 船票類型
	DECLARE @tmpFilterTicketType TABLE ( wCode VARCHAR(30) );
	IF @pTicketType != '' BEGIN
		INSERT INTO @tmpFilterTicketType(wCode) SELECT item FROM dbo.fnSplit(@pTicketType, ',');
	END;

	-- 艙等
	DECLARE @tmpFilterTicketClass TABLE ( wCode VARCHAR(30) );
	IF @pTicketClass != '' BEGIN
		INSERT INTO @tmpFilterTicketClass(wCode) SELECT item FROM dbo.fnSplit(@pTicketClass, ',');
	END;

	-- 狀態
	DECLARE @tmpFilterTicketStatus TABLE ( wCode VARCHAR(30) );
	IF @pTicketStatus != '' BEGIN
		INSERT INTO @tmpFilterTicketStatus(wCode) SELECT item FROM dbo.fnSplit(@pTicketStatus, ',');
	END;

	SELECT 
		wBookingRefNo = eb.wRefNo,		-- 預訂編號
		wDebitDt = eb.wDebitDt,			-- 扣數日期
		wDebitCounterName = dsc.wName,	-- 扣數櫃檯
		wDebitAgentCode = aDebit.wAgentCode_Display, --扣數戶口
		wDebitAgentName = CASE WHEN @pLangCd = 'en-GB' THEN aDebit.wEName ELSE aDebit.wCName END, -- 扣數戶口
		wTicketType = ftType.wTitle,	-- 船票種類
		eat.wTicketNo,					-- 船票編號
		wTicketClass = clsType.wTitle,	-- 艙等
		wTicketStatus = ftsType.wTitle	-- 船票狀態
	FROM dbo.eAllotmentTicket AS eat
    LEFT JOIN dbo.eBooking AS eb ON eb.RowID = eat.wBookingRid
	LEFT JOIN RollsMary.dbo.mAgent AS aDebit ON aDebit.wAgentCodeIn = eb.wDebitAgentCodeIn
	LEFT JOIN dbo.mServiceCounter AS dsc ON dsc.RowID = eb.wDebitCounterRid
	LEFT JOIN (SELECT * FROM dbo.mLookUp WHERE wType = 'FERRY_TICKET_TYPE' AND wLangCd = @pLangCd) AS ftType ON ftType.wCode = eat.wTicketType
	LEFT JOIN (SELECT * FROM dbo.mLookUp WHERE wType = 'FERRY_CLASS' AND wLangCd = @pLangCd) AS clsType ON clsType.wCode = eat.wClassCd
	LEFT JOIN (SELECT * FROM dbo.mLookUp WHERE wType = 'FERRY_TICKET_STATUS' AND wLangCd = @pLangCd) AS ftsType ON ftsType.wCode = eat.wAllotmentStatus
	LEFT JOIN @tmpFilterTicketType AS typefil ON typefil.wCode = eat.wTicketType
	LEFT JOIN @tmpFilterTicketClass AS classfil ON classfil.wCode = eat.wClassCd
	LEFT JOIN @tmpFilterTicketStatus As statusfil ON statusfil.wCode = eat.wAllotmentStatus
	WHERE (@pTicketNo != '' AND @pTicketNo = eat.wTicketNo)	-- 如果提供具體編號，不判斷其他篩選條件
		OR(
		@pTicketNo = '' --AND eat.wStatus = 'A' 
		AND (@pAgentCodeIn = '' OR @pAgentCodeIn = eb.wDebitAgentCodeIn)
		AND (@pTicketType = '' OR typefil.wCode IS NOT NULL)
		AND (@pTicketClass = '' OR classfil.wCode IS NOT NULL)
		AND (@pTicketStatus = '' OR statusfil.wCode IS NOT NULL)
		AND ((@pFromDt IS NULL AND @pToDt IS NULL) OR (eb.wDebitDt BETWEEN @pFromDt AND @pToDt)) -- 時間Filter都為空，返回所有數據
		)
	ORDER BY eb.wDebitDt DESC, eat.wTicketNo
	OPTION(RECOMPILE);
END;