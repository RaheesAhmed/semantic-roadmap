
CREATE PROCEDURE [spq].[GetRptBookingPickup]    
(    
	@pAgentCodeIn VARCHAR(14),
	@pDebitCounter NVARCHAR(MAX),
	@pRequestCounter NVARCHAR(MAX),
	@pFDate DATETIME2(7),
	@pTDate DATETIME2(7),
	@pLangCd VARCHAR(10) = 'en-gb',
	@pErrMsg NVARCHAR(200) = '' OUTPUT
)
AS    
BEGIN    
	DECLARE @DebitCounter TABLE(
		wRowId BIGINT
	);

	DECLARE @RequestCounter TABLE(
		wRowId BIGINT
	);

	SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));
	SET @pAgentCodeIn = REPLACE(ISNULL(@pAgentCodeIn, ''), ' ', '');
	SET @pDebitCounter = REPLACE(ISNULL(@pDebitCounter, ''), ' ', '');
	SET @pRequestCounter = REPLACE(ISNULL(@pRequestCounter, ''), ' ', '');

	IF(@pDebitCounter != '')
		INSERT INTO @DebitCounter SELECT item  from RollsMary.dbo.fnSplit(@pDebitCounter, ',');
	IF(@pRequestCounter != '')
		INSERT INTO @RequestCounter SELECT item from RollsMary.dbo.fnSplit(@pRequestCounter, ',');

	IF @@trancount = 0
		SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	SET NOCOUNT ON;

	WITH
	mAgent AS (
		SELECT 
			wAgentCode AS wAgentCode,
			wAgentCode_Display As wAgentCode_Display,
			wAgentCodeIn AS wAgentCodeIn,
			CASE WHEN @pLangCd = 'en-gb' THEN wEName ELSE wCName END AS wAgentName
		FROM [RollsMary].[dbo].[mAgent]
		WHERE @pAgentCodeIn = '' OR wAgentCodeIn = @pAgentCodeIn
	),
	mDept AS (
		SELECT 
			wCode AS wDeptCode,
			wTitle AS wDeptName
		FROM dbo.mLookUp 
		WHERE wType = 'DEPARTMENT' AND wLangCd = @pLangCd
	),
	mPay AS (
		SELECT
			wCode AS wPayCode,
			wTitle AS wPayName
		FROM dbo.mLookUp
		WHERE wType = 'PAYMENT_TYPE' AND wLangCd = @pLangCd
	),
	mEvent AS (
		SELECT 
			RowID, 
			wEventCode,
			CASE WHEN @pLangCd = 'en-gb' THEN wEName ELSE wCName END AS wEventName
		FROM dbo.mEventCode
	),
	mUsr AS (
		SELECT
			RowID,
			wUsrId,
			CASE WHEN @pLangCd = 'en-gb' THEN wName ELSE wCName END AS wUsrName
		FROM [RollsMary].[dbo].[mUsr]
	),
	mServiceCounter AS (
		SELECT 
			RowID,
			wCode,
			wName
		FROM dbo.mServiceCounter
	),
	mSupplier AS (
		SELECT 
			RowID AS RowId,
			wCode As wCode,
			wName AS wName
		FROM mTravelAgency
		WHERE wIsPickup = 'Y'
	),
	mCity AS (
		SELECT
			wCode,
			wTitle AS wName
		FROM [dbo].[mLookUp]
		WHERE wType = 'CITY' AND wLangCd = (CASE @pLangCd WHEN 'en-gb' THEN 'en-gb' ELSE 'zh-tw' END) --语言各类，否则会有重复wCode的数据
	),
	mAirPort AS (
		SELECT
			RowID,
			CASE WHEN @pLangCd = 'en-gb' THEN (ma.wEName + ', ' + city.wName) ELSE (ma.wCName + ', ' + city.wName) END AS wAirPortName
		FROM [dbo].[mAirport] AS ma
		INNER JOIN mCity AS city ON city.wCode = ma.wCity
	),
	mTravelPackage AS (
		SELECT 
			ebtp.RowID AS RowId, 
			eb.wRefNo AS wRefNo
		FROM eBookingTravelPackage ebtp
		INNER JOIN eBooking eb ON eb.RowID = ebtp.wBookingRid
	    WHERE eb.wBookingType = 'TRAVEL_PACKAGE' AND ebtp.wBookingStatus IN('P','C')
	)   
	SELECT    
		ebps.RowID AS RowId, 
		eb.wRefNo AS BookingRefNo,					--訂單編號
		eExp.wDate AS DebitDate,					--扣數日期
		dsc.wCode AS DebitCounterCode,				--扣數櫃檯
		dsc.wName AS DebitCounterName,
		rsc.wCode AS ReqCounterCode,				--要求櫃檯
		rsc.wName AS ReqCounterName,
		daAgent.wAgentCode AS DebitAgentCode,		--扣數戶口
		daAgent.wAgentName AS DebitAgentName,
		dcAgent.wAgentCode AS CustomAgentCode,		--使用戶口
		dcAgent.wAgentName AS CustomAgentName,
		reqDept.wDeptCode AS ReqDeptCode,			--要求部門
		reqDept.wDeptName AS ReqDeptName,
		reqUsr.RowID AS ReqUsrRid,					--要求同事
		reqUsr.wUsrName AS ReqUsrName,
		folDept.wDeptCode AS FollowDeptCode,		--跟進部門
		folDept.wDeptName AS FollowDeptName,
		folUsr.RowID AS FollowUsrRid,				--跟進同事
		folUsr.wUsrName AS FollowUsrName,
		eb.wAsstBooker AS AssistantBooker,			--代訂人
		eb.wAssBookerTel AS AssistantBookerPhone,	--代訂人電話
		me.wEventCode AS EventCode,					--活動代碼
		me.wEventName AS EventName,
		ebps.wServiceType AS BookingType,			--預訂類型
		ms.wCode AS SupplierCode,					--供應商
		ms.wName AS SupplierName,
		ebps.wOrderNo AS OrderNo,					--單號/確認號
		ebps.wFlightNo AS FlightNo,					--航班編號
		DAP.wAirPortName AS DepartureCity,			--出發地點
		AAP.wAirPortName AS ArivalCity,				--目的地點
		ebps.wDepartDt AS DepartureDateTime,		--航班時間
		ebps.wArrivalDt AS ArrivalDateTime,
		ebps.wQuantity AS PassengerQuantity,		--人数
		eExp.wAmountActual_CRM AS TotalAmount,		--總值
		eExp.wAmount AS ExpAmount,					--消费额
		mPay.wPayCode AS PayCode,					--付款方式
		mPay.wPayName AS PayName,
		ebps.wReceiptNo AS ReceiptNo,				--現金單號
		ebps.wRemark AS Remark,						--備註
		mtp.wRefNo AS TravePkgRefNo,				--相關套票編號
		ebps.wBookingStatus AS BookingStatus		--訂單狀態
	FROM  dbo.eBookingPickUpService ebps
	INNER JOIN dbo.eBooking AS eb ON eb.RowID = ebps.wBookingRid
	LEFT JOIN [RollsMary].[dbo].[eExpTran] AS eExp ON eExp.wReferId = CAST(eb.RowID AS VARCHAR(40)) AND eExp.wExpGroup IN ('CRM', 'RCRM')     --对数表
	INNER JOIN mServiceCounter AS dsc ON dsc.RowID = eb.wDebitCounterRid --扣數櫃檯
	INNER JOIN mServiceCounter rsc ON rsc.RowID = eb.wReqCounterRid  --要求櫃檯
	LEFT JOIN mUsr AS usr ON usr.RowID = ebps.wUpdBy
	LEFT JOIN mUsr AS crusr ON crusr.RowID = ebps.wCrtBy
	LEFT JOIN mUsr AS reqUsr ON reqUsr.RowID = eb.wReqUserRid
	LEFT JOIN mUsr AS folUsr ON folUsr.RowID = eb.wStaffFollwedRid
	LEFT JOIN mPay AS mPay ON mPay.wPayCode = ebps.wPaymentMethod
	LEFT JOIN mEvent AS me ON me.RowId = eb.wEventCodeRid
	LEFT JOIN mTravelPackage AS mtp ON mtp.RowId = eb.wTravePkgRid
	LEFT JOIN mSupplier ms ON ms.RowId = ebps.wTravelAgencyRid
	INNER JOIN mAgent AS daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn  --扣数户口
	LEFT JOIN mAgent AS dcAgent ON dcAgent.wAgentCodeIn = eb.wReqAgentCodeIn  --使用户口
	LEFT JOIN mDept AS reqDept ON eb.wReqDepartment = reqDept.wDeptCode --要求部門
	LEFT JOIN mDept AS folDept ON eb.wDeptFollwedCd = folDept.wDeptCode  --跟進部門
	LEFT JOIN mAirport AS DAP ON ebps.wDepartAirport = DAP.RowID
	LEFT JOIN mAirport AS AAP ON ebps.wDestination = AAP.RowID
	INNER JOIN @DebitCounter AS dc ON dc.wRowId = dsc.RowID
	INNER JOIN @RequestCounter AS rc ON rc.wRowId = rsc.RowID 
	WHERE eExp.wDate BETWEEN @pFDate AND @pTDate  --扣数日期要用eExpTran的日期
	ORDER BY eb.wRefNo DESC, eExp.wDate DESC
END;