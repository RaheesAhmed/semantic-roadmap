
CREATE PROCEDURE [spq].[GetRptBookingFerry]
(
	@pAgentCodeIn VARCHAR(14),
	@pDebitCounter NVARCHAR(MAX),
	@pRequestCounter NVARCHAR(MAX),
	@pFDate DATETIME2(7),
	@pTDate DATETIME2(7),
	@pTicketType VARCHAR(30),
	@pRouteRid BIGINT,
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
	SET @pTicketType = REPLACE(ISNULL(@pTicketType, ''), ' ', '');
	
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
	mTravelPackage AS (
		SELECT eb.wRefNo,ebtp.RowID 
		FROM eBookingTravelPackage ebtp
		INNER JOIN eBooking eb ON eb.RowID = ebtp.wBookingRid
		WHERE ebtp.wBookingStatus IN('P','C')
	),
	mTicketType AS (
		SELECT
			wCode,
			wTitle
		FROM dbo.mLookUp
		WHERE wType = 'FERRY_TICKET_TYPE' AND wLangCd = @pLangCd
	),
	mFerryPoint AS (
		SELECT * 
		FROM dbo.mTicketCollectionPoint
		WHERE wIsFerryTic = 'Y'
	),
	mRoute AS (
		SELECT  
			mr.RowID,
			mr.wRouteFrom AS wRouteFromCode,
			lpFrom.wTitle AS wRouteFrom,
			mr.wRouteTo AS wRouteToCode,
			lpTo.wTitle AS wRouteTo,
			wIsTwoWay,
			CASE WHEN wIsTwoWay='Y' THEN lpFrom.wTitle + '<->' + lpTo.wTitle ELSE lpFrom.wTitle + '->' + lpTo.wTitle END AS wRouteTitle
		FROM [CRM].[dbo].mRoute mr
		INNER JOIN mLookUp lpFrom on lpFrom.wCode = mr.wRouteFrom AND lpFrom.wLangCd= @pLangCd AND ((mr.wVehicle = 'FERRY' AND lpFrom.wType = 'FERRY_ROUTE_LOCATION'))
		INNER JOIN mLookUp lpTo on lpTo.wCode = mr.wRouteTo AND lpTo.wLangCd= @pLangCd AND ((mr.wVehicle = 'FERRY' AND lpTo.wType = 'FERRY_ROUTE_LOCATION'))
	),
	eBookingFerry AS (
		SELECT *
		FROM dbo.eBookingFerry
		WHERE (@pTicketType = '' OR wTicketType = @pTicketType) AND (@pRouteRid IS NULL OR @pRouteRid = wRouteRid)
	)

	SELECT
		ebf.RowID AS RowId,
		eb.wRefNo AS BookingRefNo,					--訂單編號
		eExp.wDate AS DebitDate,					--扣數日期
		dsc.wCode AS DebitCounterCode,				--扣数櫃檯
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
		mtt.wCode AS TicketTypeCode,				--船票類型
		mtt.wTitle As TicketTypeName,				--船票名稱
		ebf.wOrderNo AS OrderNo,					--單號/確認號			
		r.wRouteTitle AS RouteFromTo,				--航線
		ebf.wDepartDt AS FerryDateTime,				--航班時間
		ebf.wClassCd AS TravalClass,				--舱等
		ebf.wUnitAmt AS TicketPrice,				--票價
		ebf.wQuantity AS TicketQuantity,			--票数
		eExp.wAmountActual_CRM AS TotalAmount,		--總值
		eExp.wAmount AS ExpAmount,					--消费额
		mPay.wPayCode AS PayCode,					--付款方式
		mPay.wPayName AS PayName,
		ebf.wReceiptNo AS ReceiptNo,				--現金單號
		etc.wIsCollected AS IsCollected,			--是否取票
		mfp.wCode AS TicketCollPointCode,			--取票地點
		mfp.wName AS TicketCollPointName,
		ebf.wRemark AS Remark,						--備註
		mtp.wRefNo AS TravePkgRefNo,				--相關套票編號
		ebf.wBookingStatus AS BookingStatus			--訂單狀態
	FROM eBookingFerry AS ebf
	INNER JOIN dbo.eBooking AS eb ON eb.RowID = ebf.wBookingRid
	LEFT JOIN [RollsMary].[dbo].[eExpTran] AS eExp ON eExp.wReferId = CAST(eb.RowID AS VARCHAR(40)) AND eExp.wExpGroup IN ('CRM', 'RCRM')    --对数表
	INNER JOIN mServiceCounter AS dsc ON dsc.RowID = eb.wDebitCounterRid --扣數櫃檯
	INNER JOIN mServiceCounter rsc ON rsc.RowID = eb.wReqCounterRid  --要求櫃檯
	INNER JOIN mUsr AS usr ON usr.RowID = ebf.wUpdBy
	INNER JOIN mUsr AS crusr ON crusr.RowID = ebf.wCrtBy
	LEFT JOIN mUsr AS reqUsr ON reqUsr.RowID = eb.wReqUserRid
	LEFT JOIN mUsr AS folUsr ON folUsr.RowID = eb.wStaffFollwedRid
	LEFT JOIN mPay AS mPay ON mPay.wPayCode = ebf.wPaymentMethod
	LEFT JOIN mEvent AS me ON me.RowID = eb.wEventCodeRid
	LEFT JOIN mTravelPackage AS mtp ON mtp.RowID = eb.wTravePkgRid
	LEFt JOIN dbo.eTicketCollection AS etc ON etc.wBookingRid = eb.RowID
	LEFT JOIN mFerryPoint AS mfp ON mfp.wCode = etc.wTicCollPoint
	LEFT JOIN mAgent AS daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
	LEFT JOIN mAgent AS dcAgent ON dcAgent.wAgentCodeIn = eb.wReqAgentCodeIn
	LEFT JOIN mDept AS reqDept ON eb.wReqDepartment = reqDept.wDeptCode --要求部門
	LEFT JOIN mDept AS folDept ON eb.wDeptFollwedCd = folDept.wDeptCode  --跟進部門
	INNER JOIN mRoute r ON r.RowID = ebf.wRouteRid
	INNER JOIN mTicketType AS mtt ON mtt.wCode = ebf.wTicketType
	INNER JOIN @DebitCounter AS dc ON dc.wRowId = dsc.RowID
	INNER JOIN @RequestCounter AS rc ON rc.wRowId = rsc.RowID
	WHERE eExp.wDate BETWEEN @pFDate AND @pTDate  --扣数日期要用eExpTran的日期
	ORDER BY eb.wRefNo DESC, eExp.wDate DESC
END;