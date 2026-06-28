
CREATE PROCEDURE [spq].[GetRptBookingPrivatePlane]
(        
	@pAgentCodeIn VARCHAR(14),
	@pDebitCounter NVARCHAR(MAX),
	@pRequestCounter NVARCHAR(MAX),
	@pFDate DATETIME2(7),
	@pTDate DATETIME2(7),
	@pSupplierType VARCHAR(10),
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
	SET @pSupplierType = REPLACE(ISNULL(@pSupplierType, ''), ' ', '');
	
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
		WHERE wIsPrivatePlane = 'Y' AND (@pSupplierRid IS NULL OR @pSupplierRid = 0  OR RowID = @pSupplierRid)
		UNION
		SELECT
			RowID AS RowId,
			wCode AS wCode,
			wName AS wName
		FROM mHotel
		WHERE (@pSupplierRid IS NULL OR @pSupplierRid = 0  OR RowID = @pSupplierRid)
	),
	mTravelPackage AS (
		SELECT 
			ebtp.RowID AS RowId, 
			eb.wRefNo AS wRefNo
		FROM eBookingTravelPackage ebtp
		INNER JOIN eBooking eb ON eb.RowID = ebtp.wBookingRid
		WHERE eb.wBookingType = 'TRAVEL_PACKAGE' AND ebtp.wBookingStatus IN('P','C')
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
	)

	SELECT 
		ebpp.RowID AS RowId,
		eb.wRefNo AS BookingRefNo,					--訂單編號
		eExp.wDate AS DebitDate,					--扣數日期
		dsc.wCode AS DebitCounterCode,				--扣數櫃檯
		dsc.wName AS DebitCounterName,
		rsc.wCode AS ReqCounterCode,				--要求櫃檯
		rsc.wName AS ReqCounterName,
		daAgent.wAgentCode AS DebitAgentCode,		--扣数戶口
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
		ebpp.wBookingType AS BookingType,			--預訂類型
		ebpp.wOrderNo AS OrderNo,					--單號/確認號
		mDepart.wTakeOffDt AS DepartureDateTime,	--航班出發時間
		mDepart.wArrivalDt AS ArrivalDateTime,		--航班到達時間
		DAP.wAirPortName AS DepartureCity,					--出發地點
		AAP.wAirPortName AS ArrivalCity,					--目的地點
		mReturn.wTakeOffDt AS wReturnDepartureDateTime,
		ebpp.wConfirmPassengerNo AS PassengerQuantity,	--人數
		eExp.wAmountActual_CRM AS TotalAmount,			--總值
		eExp.wAmount AS ExpAmount,						--消费额
		mPay.wPayCode AS PayCode,						--付款方式   
		mPay.wPayName AS PayName,
		ebpp.wReceiptNo AS ReceiptNo,					--現金單號
		ebpp.wRemark AS Remark,							--備註
		mtp.wRefNo AS TravePkgRefNo,					--相關套票編號
		ebpp.wBookingStatus AS BookingStatus			--訂單狀態
	FROM [dbo].eBookingPrivatePlane ebpp            
	INNER JOIN dbo.eBooking AS eb ON eb.RowID = ebpp.wBookingRid
	LEFT JOIN [RollsMary].[dbo].[eExpTran] AS eExp ON eExp.wReferId = CAST(eb.RowID AS VARCHAR(40)) AND eExp.wExpGroup IN ('CRM', 'RCRM')
	INNER JOIN mServiceCounter AS dsc ON dsc.RowID = eb.wDebitCounterRid --扣數櫃檯
	INNER JOIN mServiceCounter rsc ON rsc.RowID = eb.wReqCounterRid  --要求櫃檯
	LEFT JOIN mUsr AS usr ON usr.RowID = ebpp.wUpdBy
	LEFT JOIN mUsr AS crusr ON crusr.RowID = ebpp.wCrtBy
	LEFT JOIN mUsr AS reqUsr ON reqUsr.RowID = eb.wReqUserRid
	LEFT JOIN mUsr AS folUsr ON folUsr.RowID = eb.wStaffFollwedRid
	LEFT JOIN mPay AS mPay ON mPay.wPayCode = ebpp.wPaymentMethod
	LEFT JOIN mEvent AS me ON me.RowID = eb.wEventCodeRid
	LEFT JOIN mTravelPackage AS mtp ON mtp.RowID = eb.wTravePkgRid
	INNER JOIN mAgent AS daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
	LEFT JOIN mAgent AS dcAgent ON dcAgent.wAgentCodeIn = eb.wReqAgentCodeIn 
	LEFT JOIN mDept AS reqDept ON eb.wReqDepartment = reqDept.wDeptCode --要求部門
	LEFT JOIN mDept AS folDept ON eb.wDeptFollwedCd = folDept.wDeptCode  --跟進部門
	INNER JOIN (SELECT * FROM dbo.ePrivatePlaneRouteDtl WHERE wLine=1) mDepart ON mDepart.wBookingPrivatePlaneRid=ebpp.RowID
	LEFT JOIN mAirport AS DAP ON DAP.RowID=mDepart.wDepartureAirportRid
	LEFT JOIN mAirport AS AAP ON AAP.RowID=mDepart.wArrivalAirportRid
	LEFT JOIN (SELECT *,ROW_NUMBER() OVER(PARTITION BY wBookingPrivatePlaneRid ORDER BY wLine DESC) AS ReturnFistRt 
		FROM dbo.ePrivatePlaneRouteDtl  WHERE wIsReturn='Y') mReturn ON mReturn.wBookingPrivatePlaneRid=ebpp.RowID AND mReturn.ReturnFistRt=1
	LEFT JOIN mSupplier ms ON ms.RowId = ebpp.wHotelRid OR ms.RowId = ebpp.wTravelAgencyRid
	INNER JOIN @DebitCounter AS dc ON dc.wRowId = dsc.RowID
	INNER JOIN @RequestCounter AS rc ON rc.wRowId = rsc.RowID
	WHERE ( @pSupplierType = '' 
			OR ( @pSupplierType ='TA' AND (@pSupplierRid IS NULL OR  @pSupplierRid = 0 OR @pSupplierRid = ebpp.wTravelAgencyRid) AND ebpp.wTravelAgencyRid IS NOT NULL AND ebpp.wTravelAgencyRid != 0) --旅行社
			OR ( @pSupplierType = 'HO' AND ( @pSupplierRid IS NULL OR  @pSupplierRid = 0 OR @pSupplierRid = ebpp.wHotelRid) AND ebpp.wHotelRid IS NOT NULL AND ebpp.wHotelRid != 0) --酒店
		  ) 
		  AND (eExp.wDate BETWEEN @pFDate AND @pTDate)  --扣数日期要用eExpTran的日期
	ORDER BY eb.wRefNo DESC, eExp.wDate DESC
END;