
CREATE PROCEDURE [spq].[GetRptAdditionalExpenses]
(
	@pAgentCodeIn VARCHAR(14),
	@pDebitCounter NVARCHAR(MAX),
	@pRequestCounter NVARCHAR(MAX),
	@pExpenseType BIGINT,
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
	mExpType AS (
		SELECT
			RowID,
			wCode,
			wName
		FROM dbo.mExpenseType
	),
	mExpSubType AS (
		SELECT
			RowID,
			wCode,
			wName
		FROM dbo.mExpenseSubtype
	),
	eAddExp AS (
		SELECT * FROM dbo.eAdditionalExpense
	)
	SELECT
			ae.RowId AS RowId,
			eb.wRefNo AS BookingRefNo,						--訂單編號
			eExp.wDate AS DebitDate,						--扣數日期
			dsc.wCode AS DebitCounterCode,					--扣數柜台
			dsc.wName As DebitCounterName,
			rsc.wCode AS ReqCounterCode,					--要求櫃檯
			rsc.wName As ReqCounterName,
			daAgent.wAgentCode_Display AS DebitAgentCode,	--扣數户口
			daAgent.wAgentName AS DebitAgentName,
			dcAgent.wAgentCode_Display AS CustomAgentCode,	--使用户口
			dcAgent.wAgentName AS CustomAgentName,
			reqDept.wDeptCode AS ReqDeptCode,				--要求部门
			reqDept.wDeptName AS ReqDeptName,
			reqUsr.RowID AS ReqUsrRid,						--要求同事
			reqUsr.wUsrName AS ReqUsrName,
			folDept.wDeptCode AS FollowDeptCode,			--跟进部門
			folDept.wDeptName AS FollowDeptName,
			folUsr.RowID AS FollowUsrRid,					--跟进同事
			folUsr.wUsrName AS FollowUsrName,
			eb.wAsstBooker AS AssistantBooker,				--代訂人
			eb.wAssBookerTel AS AssistantBookerPhone,		--代訂人電話
			me.wEventCode AS EventCode,						--活动代碼
			me.wEventName AS EventName,
			et.wCode AS ExpCode,							--消费类型
			et.wName AS ExpName,
			est.wCode AS SubExpCode,						--消费副类型
			est.wName AS SubExpName,
			ae.wOrderNo AS OrderNo,							--消費單號
			mr.RowID AS RestaurantRid,						--餐廳名稱
			mr.wName AS RestaurantName,				
			eExp.wAmountActual_CRM AS TotalAmount,			--總值
			eExp.wAmount AS ExpAmount,						--消费额
			mPay.wPayCode AS PayCode,						--付款方式
			mPay.wPayName AS PayName,
			ae.wReceiptNo AS ReceiptNo,						--現金單號
			ae.wRemark AS Remark,							--備註
			b.wRefNo AS RelatedBookingRefNo,				--相關訂單編號
			ae.wBookingStatus AS BookingStatus,				--訂單狀態
			CASE WHEN eb.wBookingType = 'HELI' THEN	'H' + CAST(h.wTicketId AS VARCHAR) WHEN eb.wBookingType = 'AIRTICKET' THEN 'A' + CAST(a.RowID AS VARCHAR) WHEN eb.wBookingType = 'ADDITIONALEXPENSES' THEN CAST(ae.RowID AS VARCHAR) END AS wBookingNo
		FROM eAddExp AS ae
		INNER JOIN dbo.eBooking AS eb ON eb.RowID = ae.wBookingRefRid  --self
		LEFT JOIN [RollsMary].[dbo].[eExpTran] AS eExp ON eExp.wReferId = CAST(eb.RowID AS VARCHAR(40)) AND eExp.wExpGroup IN ('CRM', 'RCRM')  --对数表
		INNER JOIN mServiceCounter AS dsc ON dsc.RowID = eb.wDebitCounterRid --扣數櫃檯
		INNER JOIN mServiceCounter rsc ON rsc.RowID = eb.wReqCounterRid  --要求櫃檯
		LEFT JOIN mUsr AS usr ON usr.RowID=ae.wUpdBy 
		LEFT JOIN mUsr AS crusr ON crusr.RowID=ae.wCrtBy
		LEFT JOIN mExpType AS et  ON et.RowID = ae.wExpenseType --消费类型
		LEFT JOIN mExpenseSubtype AS est ON est.RowId = ae.wExpenseSubtype	--消费副类型
		LEFT JOIN mUsr AS reqUsr ON reqUsr.RowID = eb.wReqUserRid
		LEFT JOIN mUsr AS folUsr ON folUsr.RowID = eb.wStaffFollwedRid
		LEFT JOIN mPay AS mPay ON mPay.wPayCode = ae.wPaymentMethod
		LEFT JOIN mEvent AS me ON me.RowID = eb.wEventCodeRid
		LEFT JOIN dbo.eBookingHeli AS h ON h.wBookingRid = eb.RowID			--直升機
		LEFT JOIN dbo.eBookingAirTicket AS a ON a.wBookingRid = eb.RowID	--機票
		LEFT JOIN dbo.eBookingRestaurant AS rst ON rst.wBookingRid = ae.wBookingRid --餐廳	
		LEFT JOIN dbo.mRestaurant AS mr ON mr.RowID = rst.wRestaurantRid
		INNER JOIN mAgent AS daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn  --扣数户口
		LEFT JOIN mAgent AS dcAgent ON dcAgent.wAgentCodeIn = eb.wReqAgentCodeIn  --使用户口
		LEFT JOIN mDept AS reqDept ON eb.wReqDepartment = reqDept.wDeptCode --要求部門
		LEFT JOIN mDept AS folDept ON eb.wDeptFollwedCd = folDept.wDeptCode  --跟進部門
		LEFT JOIN dbo.eBooking b ON b.RowID = ae.wBookingRid	  --关联订单
		INNER JOIN @DebitCounter AS dc ON dc.wRowId = dsc.RowID
		INNER JOIN @RequestCounter AS rc ON rc.wRowId = rsc.RowID
		WHERE (@pExpenseType IS NULL OR @pExpenseType = 0 OR ae.wExpenseType = @pExpenseType) AND (eExp.wDate BETWEEN @pFDate AND @pTDate) --扣数日期要用eExpTran的日期
		ORDER BY eb.wRefNo DESC, eExp.wDate DESC
END