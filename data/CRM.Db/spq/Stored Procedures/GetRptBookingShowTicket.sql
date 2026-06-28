
CREATE PROCEDURE [spq].[GetRptBookingShowTicket]  
(
	@pAgentCodeIn VARCHAR(14),
	@pDebitCounter NVARCHAR(MAX),
	@pRequestCounter NVARCHAR(MAX),
	@pFDate DATETIME2(7),
	@pTDate DATETIME2(7),
	@pTicketType VARCHAR(10),
	@pSupplierRid BIGINT,
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
	mSupplier AS (
		SELECT
			RowID AS RowId,
			wCode As wCode,
			wName AS wName
		FROM mTravelAgency
		WHERE wIsShowTic = 'Y' AND (@pSupplierRid IS NULL OR @pSupplierRid = 0 OR RowID = @pSupplierRid)
	),
	mTravelPackage AS (
		SELECT 
			ebtp.RowID AS RowId, 
			eb.wRefNo AS wRefNo
		FROM eBookingTravelPackage ebtp
		INNER JOIN eBooking eb ON eb.RowID = ebtp.wBookingRid
	    WHERE eb.wBookingType = 'TRAVEL_PACKAGE' AND ebtp.wBookingStatus IN('P','C')
	),
	mTicketType AS (
		SELECT
			wCode AS wTicketTypeCode,
			wTitle AS wTicketTypeName
		FROM dbo.mLookUp
		WHERE wType = 'SHOW_CATEGORY' AND wLangCd = @pLangCd
	)

	SELECT
		ebs.RowID AS RowId, 
		eb.wRefNo AS BookingRefNo,					--訂單碼號
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
		ms.wCode AS SupplierCode,					--供應商
		ms.wName AS SupplierName,
		ebs.wOrderNo AS OrderNo,					--單號/確認號
		mShow.RowID AS ShowRid,						--表演
		mShow.wName AS ShowName,					--表演名稱
		ebs.wOtherName AS AdditionShowName,			--附加節目名稱
		ebs.wShowDt AS ShowDateTime,				--观看表演时间
		mShow.wStartDate AS ShowStartDateTime,		--表演開始時間
		mShow.wEndDate AS ShowEndDateTime,			--表演結束時間
		ebs.wTotalQuantity AS TicketQuantity,		--票數
		eExp.wAmountActual_CRM AS TotalAmount,		--總值
		eExp.wAmount AS ExpAmount,					--消费额
		mPay.wPayCode AS PayCode,					--付款方式
		mPay.wPayName AS PayName,
		ebs.wReceiptNo AS ReceiptNo,				--現金單號
		ebs.wRemark AS Remark,						--備註
		mtp.wRefNo AS TravePkgRefNo,				--相關套票編號
		ebs.wBookingStatus As BookingStatus			--訂單狀態		
	FROM dbo.eBookingShow ebs 
	INNER JOIN eBooking AS eb ON eb.RowID = ebs.wBookingRid
	--CRM相关扣数
	LEFT JOIN [RollsMary].[dbo].[eExpTran] AS eExp ON eExp.wReferId = CAST(eb.RowID AS VARCHAR(40)) AND eExp.wExpGroup IN ('CRM', 'RCRM')     --对数表
	INNER JOIN mServiceCounter AS dsc ON dsc.RowID = eb.wDebitCounterRid --扣數櫃檯
	INNER JOIN mServiceCounter rsc ON rsc.RowID = eb.wReqCounterRid  --要求櫃檯
	LEFT JOIN mUsr AS usr ON usr.RowID = ebs.wUpdBy
	LEFT JOIN mUsr AS crusr ON crusr.RowID = ebs.wCrtBy
	LEFT JOIN dbo.mShow AS mShow ON mShow.RowID = ebs.wShowRid
	LEFT JOIN mUsr AS reqUsr ON reqUsr.RowID = eb.wReqUserRid
	LEFT JOIN mUsr AS folUsr ON folUsr.RowID = eb.wStaffFollwedRid
	LEFT JOIN mPay AS mPay ON mPay.wPayCode = ebs.wPaymentMethod
	LEFT JOIN mEvent AS me ON me.RowID = eb.wEventCodeRid
	LEFT JOIN mTravelPackage mtp ON mtp.RowID = eb.wTravePkgRid
	LEFT JOIN dbo.eTicketCollection AS etc ON etc.wBookingRid = eb.RowID
	INNER JOIN mAgent AS daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn  --扣数户口
	LEFT JOIN mAgent AS dcAgent ON dcAgent.wAgentCodeIn = eb.wReqAgentCodeIn  --使用户口
	LEFT JOIN mDept AS reqDept ON eb.wReqDepartment = reqDept.wDeptCode --要求部門
	LEFT JOIN mDept AS folDept ON eb.wDeptFollwedCd = folDept.wDeptCode  --跟進部門
	LEFT JOIN mSupplier ms ON ms.RowID = ebs.wTravelAgencyRid
	LEFT JOIN mTicketType AS mtt ON mtt.wTicketTypeCode = mShow.wShowCatCode
	INNER JOIN @DebitCounter AS dc ON dc.wRowId = dsc.RowID
	INNER JOIN @RequestCounter AS rc ON rc.wRowId = rsc.RowID 
	WHERE (@pSupplierRid IS NULL OR  @pSupplierRid = 0 OR @pSupplierRid = ms.RowId) AND (@pTicketType = '' OR mtt.wTicketTypeCode = @pTicketType)  AND (eExp.wDate BETWEEN @pFDate AND @pTDate)  --扣数日期要用eExpTran的日期 @pTDate)
	ORDER BY eb.wRefNo DESC, eExp.wDate DESC
 END