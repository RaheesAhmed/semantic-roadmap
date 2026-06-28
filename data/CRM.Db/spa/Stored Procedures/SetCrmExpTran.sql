CREATE PROCEDURE [spa].[SetCrmExpTran]
	(
	  @pXML XML ,
	  @pActionType CHAR(1) , -- I/U/D
	  @pMainCompNo INT ,
	  @pNonceToken VARCHAR(64) ,
	  @pErrCode INT = 0 OUTPUT ,
	  @pErrMsg NVARCHAR(200) = '' OUTPUT                
	)
AS
BEGIN             
	SET NOCOUNT ON;                                    

	DECLARE @sBeginTranCount INT = 0,
			@vXMLInsertExp NVARCHAR(MAX) = '' ,
			@vNow DATETIME2 = dbo.fnUTC8Now() ,
			@vRemark nvarchar(500) = '',			
			@vExpDesc nvarchar(200), --- wExpDesc 要填入payment method 名稱 (中文)
			@vVoucherNo nvarchar(400) = '', --- 單號..
			@vErrCode INT = 0 ,
			@vErrMsg NVARCHAR(MAX);                
					
	SET @sBeginTranCount = @@trancount;
	
	DECLARE  @tbl TABLE(
		RowID                 bigint              NULL,
		wCompNo               int                 NULL DEFAULT((0)),
		wCageCodeIn           varchar(14)         NULL DEFAULT(''),
		wTranNo               varchar(14)         NULL DEFAULT(''),
		wDate                 date                NULL,
		wCurDateTime          datetime2           NULL,
		wShift                char(1)             NULL DEFAULT(''),
		wAgentCodeIn          varchar(14)         NULL DEFAULT(''),
		wCardCodeIn           varchar(14)         NULL DEFAULT(''),
		wCustName             nvarchar(200)       NULL DEFAULT(''),
		wShopName             nvarchar(30)        NULL,
		wExpTypeCode          varchar(30)         NULL,
		wExpTargetCode        varchar(30)         NULL,
		wExpCode              varchar(30)         NULL DEFAULT(''),
		wExpSubCode1          varchar(30)         NULL DEFAULT(''),
		wCurCode              varchar(3)          NULL DEFAULT(''),
		wRoomNo               nvarchar(200)       NULL DEFAULT(''),
		wRoomCfmCode          nvarchar(20)        NULL DEFAULT(''),
		wRoomBookDt           datetime2           NULL,
		wRoomCheckInDt        datetime2           NULL,
		wRoomDeptDt           datetime2           NULL,
		wNight                int                 NULL DEFAULT((0)),
		wUnit                 int                 NULL DEFAULT((0)),
		wPrice                decimal(18,4)       NULL DEFAULT((0)),
		wRoomExpAmt           decimal(18,4)       NULL DEFAULT((0)),
		wAmount               decimal(18,4)       NULL DEFAULT((0)),
		wExpLocation          varchar(2)          NULL DEFAULT(''),
		wVoucherNo            nvarchar(400)       NULL DEFAULT(''),
		wVoucherDt            datetime2           NULL,
		wRemark               nvarchar(500)       NULL DEFAULT(''),
		wPeriodCodeIn         varchar(14)         NULL DEFAULT(''),
		wExpType              varchar(2)          NULL DEFAULT(''),
		wExpGroup             varchar(10)         NULL DEFAULT(''),
		wDeductType           varchar(2)          NULL DEFAULT(''),
		wPrtPage              int                 NULL DEFAULT((0)),
		wPrtRow               int                 NULL DEFAULT((0)),
		wTotSetAmt            decimal(18,4)       NULL DEFAULT((0)),
		wUpdBy                bigint              NULL,
		wUpdDt                datetime2           NULL,
		wRefRid               bigint              NULL,
		wReferId              varchar(40)         NULL,
		wExpSite              varchar(10)         NULL,
		wReferUpdBy           nvarchar(30)        NULL DEFAULT(''),
		wEliteCodeIn          varchar(14)         NULL,
		wSettleInstantTranNo  varchar(20)         NULL,
		wIsAdj                char(1)             NULL DEFAULT('N'),
		wForeignTranRefNo     varchar(20)         NULL,
		wFxRateHKD            decimal(12,6)       NULL,
		wFxRateRMB            decimal(12,6)       NULL,
		wExpDesc              nvarchar(200)       NULL,
		wExtUpdBy             nvarchar(50)        NULL,
		wInvoiceDateTime_CRM  datetime2           NULL,
		wAmountActual_CRM     decimal(18,4)       NULL,
		wCardNo_CRM           varchar(100)        NULL,
		wAuthorizer_CRM       nvarchar(200)       NULL,
		wRequestAgentCodeIn   varchar(14)         NULL,
		wExpCategory          nvarchar(20)        NULL DEFAULT(''),
		wGuid                 varchar(30)         NULL DEFAULT(''),
		wIsDeposit            char(1)             NULL DEFAULT('N'),
		wIsDepositDone        char(1)             NULL DEFAULT('N'),
		wProductCategory      nvarchar(40)        NULL DEFAULT(''),
		wProductDetail        nvarchar(200)       NULL DEFAULT(''),
		wBookingRid           bigint              NULL DEFAULT((-1)),
		wBookingActionRid     bigint              NULL DEFAULT((-1)),
		wIsDepositExposed     char(1)             NULL DEFAULT('N'),
		wBookingStatus        varchar(30)         NULL DEFAULT('')		
	);
	
	INSERT INTO @tbl (	
		RowID,
		wCompNo,
		wCageCodeIn,
		wTranNo,
		wDate,
		wCurDateTime,
		wShift,
		wAgentCodeIn,
		wCardCodeIn,
		wCustName,
		wShopName,
		wExpTypeCode,
		wExpTargetCode,
		wExpCode,
		wExpSubCode1,
		wCurCode,
		wRoomNo,
		wRoomCfmCode,
		wRoomBookDt,
		wRoomCheckInDt,
		wRoomDeptDt,
		wNight,
		wUnit,
		wPrice,
		wRoomExpAmt,
		wAmount,
		wExpLocation,
		wVoucherNo,
		wVoucherDt,
		wRemark,
		wPeriodCodeIn,
		wExpType,
		wExpGroup,
		wDeductType,
		wPrtPage,
		wPrtRow,
		wTotSetAmt,
		wUpdBy,
		wUpdDt,
		wRefRid,
		wReferId,
		wExpSite,
		wReferUpdBy,
		wEliteCodeIn,
		wSettleInstantTranNo,
		wIsAdj,
		wForeignTranRefNo,
		wFxRateHKD,
		wFxRateRMB,
		wExpDesc,
		wExtUpdBy,
		wInvoiceDateTime_CRM,
		wAmountActual_CRM,
		wCardNo_CRM,
		wAuthorizer_CRM,
		wRequestAgentCodeIn,
		wExpCategory,
		wGuid,
		wIsDeposit,
		wIsDepositDone,
		wProductCategory,
		wProductDetail,
		wBookingRid,
		wBookingActionRid,
		wIsDepositExposed,
		wBookingStatus
	)
	(SELECT  
		b.value('@RowID[1]', 'bigint') AS RowID,
		b.value('@wCompNo[1]', 'int') AS wCompNo,
		b.value('@wCageCodeIn[1]', 'varchar(14)') AS wCageCodeIn,
		b.value('@wTranNo[1]', 'varchar(14)') AS wTranNo,
		b.value('@wDate[1]', 'date') AS wDate,
		b.value('@wCurDateTime[1]', 'datetime2') AS wCurDateTime,
		b.value('@wShift[1]', 'char(1)') AS wShift,
		b.value('@wAgentCodeIn[1]', 'varchar(14)') AS wAgentCodeIn,
		b.value('@wCardCodeIn[1]', 'varchar(14)') AS wCardCodeIn,
		b.value('@wCustName[1]', 'nvarchar(200)') AS wCustName,
		b.value('@wShopName[1]', 'nvarchar(30)') AS wShopName,
		b.value('@wExpTypeCode[1]', 'varchar(30)') AS wExpTypeCode,
		b.value('@wExpTargetCode[1]', 'varchar(30)') AS wExpTargetCode,
		b.value('@wExpCode[1]', 'varchar(30)') AS wExpCode,
		b.value('@wExpSubCode1[1]', 'varchar(30)') AS wExpSubCode1,
		b.value('@wCurCode[1]', 'varchar(3)') AS wCurCode,
		b.value('@wRoomNo[1]', 'nvarchar(200)') AS wRoomNo,
		b.value('@wRoomCfmCode[1]', 'nvarchar(20)') AS wRoomCfmCode,
		b.value('@wRoomBookDt[1]', 'datetime2') AS wRoomBookDt,
		b.value('@wRoomCheckInDt[1]', 'datetime2') AS wRoomCheckInDt,
		b.value('@wRoomDeptDt[1]', 'datetime2') AS wRoomDeptDt,
		b.value('@wNight[1]', 'int') AS wNight,
		b.value('@wUnit[1]', 'int') AS wUnit,
		b.value('@wPrice[1]', 'decimal(18,4)') AS wPrice,
		b.value('@wRoomExpAmt[1]', 'decimal(18,4)') AS wRoomExpAmt,
		b.value('@wAmount[1]', 'decimal(18,4)') AS wAmount,
		b.value('@wExpLocation[1]', 'varchar(2)') AS wExpLocation,
		b.value('@wVoucherNo[1]', 'nvarchar(400)') AS wVoucherNo,
		b.value('@wVoucherDt[1]', 'datetime2') AS wVoucherDt,
		b.value('@wRemark[1]', 'nvarchar(500)') AS wRemark,
		b.value('@wPeriodCodeIn[1]', 'varchar(14)') AS wPeriodCodeIn,
		b.value('@wExpType[1]', 'varchar(2)') AS wExpType,
		b.value('@wExpGroup[1]', 'varchar(10)') AS wExpGroup,
		b.value('@wDeductType[1]', 'varchar(2)') AS wDeductType,
		b.value('@wPrtPage[1]', 'int') AS wPrtPage,
		b.value('@wPrtRow[1]', 'int') AS wPrtRow,
		b.value('@wTotSetAmt[1]', 'decimal(18,4)') AS wTotSetAmt,
		b.value('@wUpdBy[1]', 'bigint') AS wUpdBy,
		b.value('@wUpdDt[1]', 'datetime2') AS wUpdDt,
		b.value('@wRefRid[1]', 'bigint') AS wRefRid,
		b.value('@wReferId[1]', 'varchar(40)') AS wReferId,
		b.value('@wExpSite[1]', 'varchar(10)') AS wExpSite,
		b.value('@wReferUpdBy[1]', 'nvarchar(30)') AS wReferUpdBy,
		b.value('@wEliteCodeIn[1]', 'varchar(14)') AS wEliteCodeIn,
		b.value('@wSettleInstantTranNo[1]', 'varchar(20)') AS wSettleInstantTranNo,
		b.value('@wIsAdj[1]', 'char(1)') AS wIsAdj,
		b.value('@wForeignTranRefNo[1]', 'varchar(20)') AS wForeignTranRefNo,
		b.value('@wFxRateHKD[1]', 'decimal(12,6)') AS wFxRateHKD,
		b.value('@wFxRateRMB[1]', 'decimal(12,6)') AS wFxRateRMB,
		b.value('@wExpDesc[1]', 'nvarchar(200)') AS wExpDesc,
		b.value('@wExtUpdBy[1]', 'nvarchar(50)') AS wExtUpdBy,
		b.value('@wInvoiceDateTime_CRM[1]', 'datetime2') AS wInvoiceDateTime_CRM,
		b.value('@wAmountActual_CRM[1]', 'decimal(18,4)') AS wAmountActual_CRM,
		b.value('@wCardNo_CRM[1]', 'varchar(100)') AS wCardNo_CRM,
		b.value('@wAuthorizer_CRM[1]', 'nvarchar(200)') AS wAuthorizer_CRM,
		b.value('@wRequestAgentCodeIn[1]', 'varchar(14)') AS wRequestAgentCodeIn,
		b.value('@wExpCategory[1]', 'nvarchar(20)') AS wExpCategory,
		b.value('@wGuid[1]', 'varchar(30)') AS wGuid,
		b.value('@wIsDeposit[1]', 'char(1)') AS wIsDeposit,
		b.value('@wIsDepositDone[1]', 'char(1)') AS wIsDepositDone,
		b.value('@wProductCategory[1]', 'nvarchar(40)') AS wProductCategory,
		b.value('@wProductDetail[1]', 'nvarchar(200)') AS wProductDetail,
		b.value('@wBookingRid[1]', 'bigint') AS wBookingRid,
		b.value('@wBookingActionRid[1]', 'bigint') AS wBookingActionRid,
		b.value('@wIsDepositExposed[1]', 'char(1)') AS wIsDepositExposed,
		b.value('@wBookingStatus[1]', 'varchar(30)') AS wBookingStatus
		FROM @pXML.nodes('/DataSet/Record') a(b)); 
		
	DECLARE @sBookingType varchar(30), @sRefNo varchar(30), @sAsstBooker nvarchar(50), @sAsstBookerPhoneNo nvarchar(100), @sBookingRid bigint, @sCashReceiptNo nvarchar(50),
			@sBookingStatus varchar(30), @sPassenger nvarchar(1000), @sIsNeedConcat char(1) = 'Y', @sDepartureDatetime varchar(40), @sRoute nvarchar(500), @sArrivalDatetime varchar(50),
			@sFlightType varchar(30), @sAirPassengerId bigint, @sDepartureAirport nvarchar(40), @sArrivalAirport nvarchar(40), @sTakeOffDatetime varchar(50),
			@sBookingActionRid bigint, @sPaymentMethod varchar(30), @sRowID bigint;

	DECLARE @zExpType nvarchar(50), @zExpSubType nvarchar(50), @zSPA nvarchar(100), @zRestaurant nvarchar(100);
	DECLARE @zRegion nvarchar(50);
	DECLARE @zPlaceOfIssue nvarchar(50);
	DECLARE @zShowName nvarchar(50), @zBookingShowRid bigint, @zShowDatetime varchar(40), @zIsFullDay char(1), @zAllTicketStr nvarchar(1000);
	DECLARE @zServiceType nvarchar(50), @zApplyDatetime varchar(40);
	DECLARE @zClass nvarchar(50);
	DECLARE @zIsCharteredFlight char(1);
	DECLARE @zPrivatePlaneRowId bigint;
	DECLARE @zBookingXXRid bigint, @zRouteCount int, @zAirLine nvarchar(10), @zDepartFlightNo nvarchar(20);
	DECLARE @zHotelBookingAction varchar(5), @zHotelName nvarchar(100), @zRoomName nvarchar(200), @zCheckInDate date, @zCheckOutDate date,
					@zRoomBookingId bigint, @m_sAsstBooker nvarchar(50), @m_sAsstBookerPhoneNo nvarchar(50),@zOriCheckInDate date, @zOriCheckOutDate date;

	SELECT TOP 1 @sPaymentMethod = wExpDesc FROM @tbl;

	DECLARE curTbl CURSOR FORWARD_ONLY STATIC FOR
		SELECT t.RowID, b.wBookingType, b.wRefNo, b.wAsstBooker, b.wAssBookerTel, b.RowID, t.wBookingStatus, t.wRefRid, t.wBookingActionRid
			FROM dbo.eBooking AS b INNER JOIN @tbl AS t ON b.RowID = t.wBookingRid
		FOR READ ONLY;

	OPEN curTbl
	FETCH NEXT FROM curTbl INTO @sRowID, @sBookingType, @sRefNo, @sAsstBooker, @sAsstBookerPhoneNo, @sBookingRid, @sBookingStatus, @sAirPassengerId, @sBookingActionRid
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @sCashReceiptNo = '', @sPassenger = '', @sIsNeedConcat = 'Y', @sDepartureDatetime = '', @sRoute = '', @sArrivalDatetime = '',
			@sFlightType = '', @sDepartureAirport = '', @sArrivalAirport = '', @sTakeOffDatetime = '';

		SELECT @zExpType = '', @zExpSubType = '', @zSPA = '', @zRestaurant = '',
			@zRegion = '',
			@zPlaceOfIssue = '',
			@zShowName = '', @zBookingShowRid = NULL, @zShowDatetime = '', @zIsFullDay = '', @zAllTicketStr= '',
			@zServiceType = '', @zApplyDatetime = '',
			@zClass = '',
			@zIsCharteredFlight = '',
			@zPrivatePlaneRowId = NULL,
			@zBookingXXRid = NULL, @zRouteCount = NULL, @zAirLine = '', @zDepartFlightNo = '',
			@zHotelBookingAction = '', @zHotelName = '', @zRoomName = '', @zCheckInDate = NULL, @zCheckOutDate = NULL,
						@zRoomBookingId = NULL, @m_sAsstBooker = '', @m_sAsstBookerPhoneNo = '',@zOriCheckInDate = NULL, @zOriCheckOutDate = NULL;
		-- 其他消費
		IF @sBookingType = 'ADDITIONALEXPENSES'
		BEGIN			
			SELECT	@zExpType = ISNULL(et.wName, ''), @zExpSubType = ISNULL(es.wName, ''), @sCashReceiptNo = ISNULL(ae.wReceiptNo, ''),	@zRestaurant = ISNULL(r.wName, ''), @zSPA = ISNULL(s.wName, ''),
					@vVoucherNo = ae.wOrderNo
				FROM	dbo.eAdditionalExpense ae
						INNER JOIN dbo.mExpenseType et ON ae.wExpenseType = et.RowID
						LEFT JOIN dbo.mExpenseSubtype es ON ae.wExpenseSubtype = es.RowID
						LEFT JOIN dbo.mRestaurant r ON ae.wRestaurantRid = r.RowID
						LEFT JOIN dbo.mSpa s ON ae.wSpaRid = s.RowID
				WHERE	ae.wBookingRefRid = @sBookingRid;

			SET @vRemark = CONCAT(CASE WHEN @sBookingStatus = 'C' THEN N'<確認消費> ' ELSE N'<退款> ' END, @zExpType,
								  CASE WHEN @zExpSubType = '' THEN '' ELSE '-' END, @zExpSubType,
								  CASE WHEN @sAsstBooker = '' THEN '' ELSE N'，代訂人：' END, @sAsstBooker,
								  CASE WHEN @sAsstBookerPhoneNo = '' THEN '' ELSE N'，代訂人電話：' END, @sAsstBookerPhoneNo,
								  CASE WHEN @zRestaurant = '' THEN '' ELSE N'，餐廳名稱：' END, @zRestaurant,
								  CASE WHEN @zSPA = '' THEN '' ELSE N'，SPA名稱：' END, @zSPA, 
								  CASE WHEN @sCashReceiptNo = '' THEN '' ELSE N'，現金單號：' END, @sCashReceiptNo, 
								  ' (', @sRefNo, ')');
			SET @sIsNeedConcat = 'N';
		END
		-- 警察開路預訂
		ELSE IF @sBookingType = 'LEADING_SERVICE'
		BEGIN			
			SELECT	@zRegion = ISNULL(l.wTitle, ''), @vVoucherNo = b.wOrderNo
				FROM	dbo.eBookingLeading b
						INNER JOIN dbo.mLookUp l ON l.wType = 'REGION' AND l.wLangCd = 'zh-tw' AND l.wCode = b.wRegion
				WHERE	b.wBookingRid = @sBookingRid;

			SET @vRemark = CONCAT(CASE WHEN @sBookingStatus = 'C' THEN N'<確認消費> ' ELSE N'<退款> ' END, N'地區', @zRegion);
		END
		 -- 簽證預訂
		ELSE IF @sBookingType = 'Visa'
		BEGIN			
			SELECT	@zPlaceOfIssue = ISNULL(l.wTitle, ''), @vVoucherNo = v.wOrderNo
				FROM	dbo.eBookingVisa v
						LEFT JOIN dbo.mLookUp l ON l.wType = 'ID_ISSUE_PLACE' AND l.wLangCd = 'zh-tw' AND l.wCode = v.wPlaceOfIssue
				WHERE	v.wBookingRid = @sBookingRid;

			SET @sPassenger = STUFF(
					(SELECT CONCAT(N'，' , p.wCName)
							From dbo.ePassengerDetails pd
							INNER JOIN dbo.mPerson p ON pd.wPersonRid = p.RowID
							WHERE pd.wBookingRid = @sBookingRid
							FOR XML PATH(''),TYPE)
					.value('text()[1]','nvarchar(max)'),1,1,N'');
						
			SET @vRemark = CONCAT(CASE WHEN @sBookingStatus = 'C' THEN N'<確認消費> ' ELSE N'<退款> ' END, 
								  CASE WHEN @zPlaceOfIssue = '' THEN '' ELSE N'簽證國家：' END, @zPlaceOfIssue, 
								  N'，客人姓名：', @sPassenger);
		END
		-- 流動登機服務預訂
		ELSE IF @sBookingType = 'CHK_IN_SVC'
		BEGIN		
			SELECT	@sArrivalDatetime = CONVERT(varchar(40), bci.wArrivalTimeToG15nG16, 20), @vVoucherNo = bci.wOrderNo
				FROM	dbo.eBookingCheckInService bci
				WHERE	bci.wBookingRid = @sBookingRid;

			SET @sPassenger = STUFF(
					(SELECT CONCAT(N'，' , p.wCName)
							FROM dbo.ePassengerDetails pd
							INNER JOIN dbo.mPerson p ON pd.wPersonRid = p.RowID
							WHERE pd.wBookingRid = @sBookingRid
							FOR XML PATH(''),TYPE)
					.value('text()[1]','nvarchar(max)'),1,1,N'');
		
			SET @vRemark = CONCAT(CASE WHEN @sBookingStatus = 'C' THEN N'<確認消費> ' ELSE N'<退款> ' END, N'辦理日期：', @sArrivalDatetime, N'，客人姓名：', @sPassenger);
		END
		-- 門票預訂
		ELSE IF @sBookingType = 'SHOWTICKET'
		BEGIN			
			SELECT	@zShowName = s.wName, @zBookingShowRid = bs.RowID, @zShowDatetime = CONVERT(VARCHAR(40), bs.wShowDt, 20), @zIsFullDay = s.wIsFullDay,
					@vVoucherNo = bs.wOrderNo
				FROM	dbo.eBookingShow bs
						INNER JOIN dbo.mShow s ON bs.wShowRid = s.RowID
				WHERE	bs.wBookingRid = @sBookingRid;

			SET @zAllTicketStr = STUFF(
					(SELECT CONCAT(N'，' , stp.wTicketType, N'，數量：', bst.wQuantity)
							FROM dbo.eBookingShowTicket bst
							INNER JOIN dbo.mShowTicketPrice stp ON bst.wShowTicketPriceRid = stp.RowID
							WHERE bst.wBookingShowRid = @zBookingShowRid AND bst.wQuantity > 0
							FOR XML PATH(''),TYPE)
					.value('text()[1]','nvarchar(max)'),1,0,N'');
										
		
			SET @vRemark = CONCAT(CASE WHEN @sBookingStatus = 'C' THEN N'<確認消費> ' ELSE N'<退款> ' END, @zShowName, N'，',
								  CASE WHEN @zIsFullDay = 'Y' THEN SUBSTRING(@zShowDatetime, 1, 10)	ELSE @zShowDatetime	END,
								  @zAllTicketStr);
		END
		-- 機場貴賓服務預訂
		ELSE IF @sBookingType = 'PickUp_SERVICE'
		BEGIN			
			SELECT	@zServiceType = CASE ps.wServiceType
										WHEN 'EC' THEN N'快速通關'
										WHEN 'PU' THEN N'接機'
										WHEN 'DO' THEN N'送機'
										ELSE ''
									END, @zApplyDatetime =CONVERT(VARCHAR(40), ps.wApplyDt, 20) , @vVoucherNo = ps.wOrderNo
				FROM	dbo.eBookingPickUpService ps
				WHERE	ps.wBookingRid = @sBookingRid;

			SET @sPassenger = STUFF(
					(SELECT CONCAT(N'，' , p.wCName)
							FROM dbo.ePassengerDetails pd
							INNER JOIN dbo.mPerson p ON pd.wPersonRid = p.RowID
							WHERE pd.wBookingRid = @sBookingRid
							FOR XML PATH(''),TYPE)
					.value('text()[1]','nvarchar(max)'),1,1,N'');
				
		
			SET @vRemark = CONCAT(CASE WHEN @sBookingStatus = 'C' THEN N'<確認消費> ' ELSE N'<退款> ' END, @zServiceType, N'，', @zApplyDatetime, 
								  CASE WHEN ISNULL(@sPassenger, '') = '' THEN '' ELSE N'，客人姓名：' END, @sPassenger);
		END
		-- 船票預訂
		ELSE IF @sBookingType = 'FERRY'
		BEGIN			
			SELECT	@zClass = bfl.wTitle, @sDepartureDatetime = CONVERT(VARCHAR(40), bf.wDepartDt, 20), @vVoucherNo = bf.wOrderNo,
					@sRoute = CONCAT(rfl.wTitle, CASE WHEN r.wIsTwoWay = 'N' THEN '>'
													  ELSE '<>'
												 END, rtl.wTitle)
				FROM	dbo.eBookingFerry bf
						INNER JOIN dbo.mRoute r ON bf.wRouteRid = r.RowID
						INNER JOIN dbo.mLookUp rfl ON r.wRouteFrom = rfl.wCode AND rfl.wType = 'FERRY_ROUTE_LOCATION' AND rfl.wLangCd = 'zh-tw'
						INNER JOIN dbo.mLookUp rtl ON r.wRouteTo = rtl.wCode AND rtl.wType = 'FERRY_ROUTE_LOCATION' AND rtl.wLangCd = 'zh-tw'
						INNER JOIN dbo.mLookUp bfl ON bf.wClassCd = bfl.wCode AND bfl.wType = 'FERRY_CLASS' AND bfl.wLangCd = 'zh-tw'
				WHERE	bf.wBookingRid = @sBookingRid;


			SET @vRemark = CONCAT(CASE WHEN @sBookingStatus = 'C' THEN N'<確認消費> ' ELSE N'<退款> ' END, N'航線：', @sRoute, N'，艙等：', @zClass, N'，航班日期/時間：', @sDepartureDatetime);		
		END
		-- 直升機票預訂
		ELSE IF @sBookingType = 'HELI'
		BEGIN			
			SELECT	@zIsCharteredFlight = bh.wIsCharteredFlight, @vVoucherNo = bh.wOrderNo
				FROM	dbo.eBookingHeli bh
				WHERE	bh.wBookingRid = @sBookingRid;

			IF @zIsCharteredFlight = 'Y'
			BEGIN
				SELECT	@sRoute = CONCAT(rfl.wTitle, '>', rtl.wTitle), @sDepartureDatetime = CONVERT(VARCHAR(40), bh.wDepartDt, 20)
					FROM	dbo.eBookingHeli bh
							INNER JOIN dbo.mRoute r ON bh.wRouteRid = r.RowID
							INNER JOIN dbo.mLookUp rfl ON r.wRouteFrom = rfl.wCode AND rfl.wType = 'HELICOPTER_ROUTE_LOCATION' AND rfl.wLangCd = 'zh-tw'
							INNER JOIN dbo.mLookUp rtl ON r.wRouteTo = rtl.wCode AND rtl.wType = 'HELICOPTER_ROUTE_LOCATION' AND rtl.wLangCd = 'zh-tw'
					WHERE	bh.wBookingRid = @sBookingRid;

				SET @sPassenger = STUFF(
					(SELECT CONCAT(N'，' , p.wCName)
							FROM dbo.ePassengerDetails pd
							INNER JOIN dbo.mPerson p ON pd.wPersonRid = p.RowID
							WHERE pd.wBookingRid = @sBookingRid
							FOR XML PATH(''),TYPE)
					.value('text()[1]','nvarchar(max)'),1,1,N'');
			END
			ELSE
			BEGIN
				SELECT	@sRoute = CONCAT(rfl.wTitle, '>', rtl.wTitle), @sDepartureDatetime = CONVERT(VARCHAR(40), pd.wTakeOffDt, 20), @sPassenger = p.wCName
					FROM	dbo.ePassengerDetails pd
							INNER JOIN dbo.mRoute r ON pd.wRouteRid = r.RowID
							INNER JOIN dbo.mLookUp rfl ON r.wRouteFrom = rfl.wCode AND rfl.wType = 'HELICOPTER_ROUTE_LOCATION' AND rfl.wLangCd = 'zh-tw'
							INNER JOIN dbo.mLookUp rtl ON r.wRouteTo = rtl.wCode AND rtl.wType = 'HELICOPTER_ROUTE_LOCATION' AND rtl.wLangCd = 'zh-tw'
							INNER JOIN dbo.eBookingHeli bh ON pd.wBookingRid = bh.wBookingRid
							INNER JOIN dbo.mPerson p ON p.RowID = pd.wPersonRid
					WHERE	pd.RowID = @sAirPassengerId AND pd.wType = 'HELI';
			END;

			SET @vRemark = CONCAT(CASE WHEN @sBookingStatus = 'C' THEN N'<確認消費> ' ELSE N'<退款> ' END, @sRoute, N'，', @sDepartureDatetime, N'，客人姓名：', @sPassenger);
		END
		 -- 私人飛機預訂
		ELSE IF @sBookingType = 'PP'
		BEGIN			
			SELECT	@zPrivatePlaneRowId = p.RowID, @sFlightType = p.wBookingType, @vVoucherNo = p.wOrderNo
				FROM	dbo.eBookingPrivatePlane p
				WHERE	p.wBookingRid = @sBookingRid;

			SET @sPassenger = STUFF(
					(SELECT CONCAT(N'，' , p.wCName)
							FROM dbo.ePassengerDetails pd
							INNER JOIN dbo.mPerson p ON pd.wPersonRid = p.RowID
							WHERE pd.wBookingRid = @sBookingRid
							FOR XML PATH(''),TYPE)
					.value('text()[1]','nvarchar(max)'),1,1,N'');

			DECLARE curPD CURSOR FORWARD_ONLY STATIC
			FOR
			SELECT	da.wCName, aa.wCName, CONVERT(VARCHAR(40), pp.wTakeOffDt, 20)
			FROM	dbo.ePrivatePlaneRouteDtl pp
					INNER JOIN dbo.mAirport da ON pp.wDepartureAirportRid = da.RowID
					INNER JOIN dbo.mAirport aa ON pp.wArrivalAirportRid = aa.RowID
			WHERE	pp.wBookingPrivatePlaneRid = @zPrivatePlaneRowId
			ORDER BY pp.wLine FOR READ ONLY;

			SET @sRoute = '';

			OPEN curPD;
			FETCH NEXT FROM curPD INTO @sDepartureAirport, @sArrivalAirport, @sTakeOffDatetime
			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF @sRoute = ''
				BEGIN
					IF @sFlightType = 'ONEWAY'
					BEGIN
						SET @sRoute = CONCAT(@sDepartureAirport, N'>', @sArrivalAirport, N'，去程：',  @sTakeOffDatetime);
					END
					ELSE IF @sFlightType = 'ROUND'
					BEGIN
						SET @sRoute = CONCAT(@sDepartureAirport, N'<>', @sArrivalAirport, N'，去程：', @sTakeOffDatetime);
					END
					ELSE IF @sFlightType = 'MULTI'
					BEGIN
						SET @sRoute = CONCAT(@sDepartureAirport, N'>', @sArrivalAirport, N'，起飛：', @sTakeOffDatetime);
					END
				END
				ELSE
				BEGIN
					IF @sFlightType = 'ROUND'
					BEGIN
						SET @sRoute = CONCAT(@sRoute, N'，回程：', @sTakeOffDatetime);
					END
					ELSE IF @sFlightType = 'MULTI'
					BEGIN
						SET @sRoute = CONCAT(@sRoute, N'，', @sDepartureAirport, N'>', @sArrivalAirport, N'，起飛：', @sTakeOffDatetime);
					END
				END

				FETCH NEXT FROM curPD INTO @sDepartureAirport, @sArrivalAirport, @sTakeOffDatetime
			END;
			CLOSE curPD;
			DEALLOCATE curPD;
				
			SET @vRemark = CONCAT(CASE WHEN @sBookingStatus = 'C' THEN N'<確認消費> ' ELSE N'<退款> ' END, @sRoute, N'，客人姓名：', @sPassenger);
		END
		-- 機票預訂
		ELSE IF @sBookingType = 'AIRTICKET'
		BEGIN			
			SELECT	@sFlightType = bat.wFlightType, @sPassenger = ISNULL(p.wCName, ''), @zBookingXXRid = bat.RowID, @vVoucherNo = bat.wOrderNo
			FROM	dbo.ePassengerDetails pd
					INNER JOIN dbo.eBookingAirTicket bat ON pd.wBookingRid = bat.wBookingRid
					INNER JOIN dbo.mPerson p ON pd.wPersonRid = p.RowID
			WHERE	pd.RowID = @sAirPassengerId;

			SELECT	@zRouteCount = COUNT(1)
			FROM	dbo.eAirTicketRouteDtl a
			WHERE	a.wTypeRid = @sAirPassengerId AND a.wType = 'PASSENGER';

			IF @zRouteCount = 0
			BEGIN
				DECLARE curPD CURSOR FORWARD_ONLY STATIC
				FOR
				SELECT	a.wDepartFlightNo, al.wTitle, da.wCName, aa.wCName, CONVERT(VARCHAR(40), a.wTakeOffDt, 20)
				FROM	dbo.eAirTicketRouteDtl a
						INNER JOIN dbo.mLookUp al ON a.wAirline = al.wCode AND al.wType = 'AIRLINES' AND al.wLangCd = 'zh-tw'
						INNER JOIN dbo.mAirport da ON a.wDepartureAirportRid = da.RowID
						INNER JOIN dbo.mAirport aa ON a.wArrivalAirportRid = aa.RowID
				WHERE	a.wTypeRid = @zBookingXXRid AND a.wType = 'AIRTICKET' 
				ORDER BY a.wLine FOR READ ONLY;
			END;
			ELSE
			BEGIN
				DECLARE curPD CURSOR FORWARD_ONLY STATIC
				FOR
				SELECT	a.wDepartFlightNo, al.wTitle, da.wCName, aa.wCName, CONVERT(VARCHAR(40), a.wTakeOffDt, 20)
				FROM	dbo.eAirTicketRouteDtl a
						INNER JOIN dbo.mLookUp al ON a.wAirline = al.wCode AND al.wType = 'AIRLINES' AND al.wLangCd = 'zh-tw'
						INNER JOIN dbo.mAirport da ON a.wDepartureAirportRid = da.RowID
						INNER JOIN dbo.mAirport aa ON a.wArrivalAirportRid = aa.RowID
				WHERE	a.wTypeRid = @sAirPassengerId AND a.wType = 'PASSENGER' AND a.wStatus='A'
				ORDER BY a.wLine FOR READ ONLY;
			END;

			SET @sRoute = '';

			OPEN curPD;
			FETCH NEXT FROM curPD INTO @zDepartFlightNo, @zAirLine, @sDepartureAirport, @sArrivalAirport, @sTakeOffDatetime;
			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF @sRoute = ''
				BEGIN
					IF @sFlightType = 'ONEWAY'
					BEGIN
						SET @sRoute = CONCAT(@zAirLine, N'，', @sDepartureAirport, N'>', @sArrivalAirport, N'，去程：', @sTakeOffDatetime, N'，航班：', @zDepartFlightNo);
					END
					ELSE IF @sFlightType = 'ROUND'
					BEGIN
						SET @sRoute = CONCAT(@zAirLine, N'，', @sDepartureAirport, N'<>', @sArrivalAirport, N'，去程：', @sTakeOffDatetime, N'，航班：', @zDepartFlightNo);
					END
					ELSE IF @sFlightType = 'MULTI'
					BEGIN
						SET @sRoute = CONCAT(@zAirLine, N'，', @sDepartureAirport, N'>', @sArrivalAirport, N'，起飛：', @sTakeOffDatetime, N'，航班：', @zDepartFlightNo);
					END
				END
				ELSE
				BEGIN
					IF @sFlightType = 'ROUND'
					BEGIN
						SET @sRoute = CONCAT(@sRoute, N'，回程：', @sTakeOffDatetime, N'，航班：', @zDepartFlightNo);
					END
					ELSE IF @sFlightType = 'MULTI'
					BEGIN
						SET @sRoute = CONCAT(@sRoute, N'，', @sDepartureAirport, N'>', @sArrivalAirport, N'，起飛：', @sTakeOffDatetime, N'，航班：', @zDepartFlightNo);
					END
				END
				FETCH NEXT FROM curPD INTO @zDepartFlightNo, @zAirLine, @sDepartureAirport, @sArrivalAirport, @sTakeOffDatetime;
			END;
			CLOSE curPD;
			DEALLOCATE curPD;
				
			SET @vRemark = CONCAT(CASE WHEN @sBookingStatus = 'C' THEN N'<確認消費> ' ELSE N'<退款> ' END, @sRoute, N'，客人姓名：', @sPassenger);
		END
		-- 旅遊套票
		ELSE IF @sBookingType = 'TRAVEL_PACKAGE'
		BEGIN
			SET @vRemark = NULL;
			SET @sIsNeedConcat = 'N';
			SELECT @vVoucherNo = btp.wOrderNo FROM dbo.eBookingTravelPackage AS btp
				WHERE btp.wBookingRid = @sBookingRid;
		END
		-- 導遊預訂
		ELSE IF @sBookingType = 'TOUR'
		BEGIN
			SET @vRemark = NULL;
			SET @sIsNeedConcat = 'N';
			SELECT @vVoucherNo = btg.wOrderNo FROM dbo.eBookingTourGuide AS btg
				WHERE btg.wBookingRid = @sBookingRid;
		END
		-- 房間預訂
		ELSE IF ISNULL(@sBookingActionRid, -1) > 0
		BEGIN
			SELECT	@zHotelBookingAction = hc.wAction, @zHotelName = ISNULL(h.wName, ''), @zRoomName = ISNULL(hr.wName, ''),
					@zCheckInDate = hc.wNewStartDate, @zCheckOutDate = hc.wNewEndDate, @zRoomBookingId = hc.wRoomBookingRid, @sCashReceiptNo = hc.wCashReceiptNo, 
					@sRefNo = b.wRefNo, @sAsstBooker = b.wAsstBooker, @sAsstBookerPhoneNo = b.wAssBookerTel, @zOriCheckInDate = hc.wOriStartDate, @zOriCheckOutDate = hc.wOriEndDate,
					@vVoucherNo = hc.wOrderNo
			FROM	dbo.eHotelChange hc
					INNER JOIN dbo.eBookingRoom br ON hc.wRoomBookingRid = br.RowID
					INNER JOIN dbo.eBooking b ON br.wBookingRid = b.RowID
					LEFT JOIN dbo.mHotel h ON br.wHotelRid = h.RowID
					LEFT JOIN dbo.mHotelRoom hr ON br.wHotelRoomRid = hr.RowID
					
			WHERE	hc.RowID = @sBookingActionRid;

			SET @sPassenger = STUFF(
					(SELECT CONCAT(N'，' , p.wCName)
							FROM dbo.ePassengerDetails pd
							INNER JOIN dbo.mPerson p ON pd.wPersonRid = p.RowID
							WHERE pd.wRoomBookingRid = @zRoomBookingId
							FOR XML PATH(''),TYPE)
					.value('text()[1]','nvarchar(max)'),1,1,N'');
		
			/*by action processing the remark*/
			IF @zHotelBookingAction IN ('C', 'RF')
			BEGIN
				SET @vRemark = CONCAT(CASE @zHotelBookingAction 
										WHEN 'C' THEN N'<確認消費> ' 
										WHEN 'RF' THEN N'<退款> ' 
									  END, 
									  @zHotelName, N' ', @zRoomName, N'，入住日期：', 
									  CASE @zHotelBookingAction
										WHEN 'C' THEN @zCheckInDate
										WHEN 'RF' THEN @ZOriCheckInDate
									  END, N'，退房日期：', 
									  CASE @zHotelBookingAction
										WHEN 'C' THEN @zCheckOutDate
										WHEN 'RF' THEN @zOriCheckOutDate
									  END,
									  CASE WHEN ISNULL(@sPassenger, '') = '' THEN '' ELSE N'，登記人：' END, @sPassenger);

				IF @zHotelBookingAction = 'RF'
				BEGIN
					SET @sCashReceiptNo = '';
				END
			END;
			ELSE IF @zHotelBookingAction IN ('EX', 'ECI', 'LC', 'ECO')
			BEGIN
				SET @vRemark = CONCAT(CASE @zHotelBookingAction 
										WHEN 'EX' THEN N'<續房> ' 
										WHEN 'ECI' THEN N'<提前入住> ' 
										WHEN 'LC' THEN N'<延遲入住> ' 
										WHEN 'ECO' THEN N'<早退> ' 
									  END, @zHotelName, N' ', @zRoomName, N'，修改日子由 ', 
									  CASE @zHotelBookingAction
										WHEN 'EX' THEN @zOriCheckOutDate
										WHEN 'ECI' THEN @zCheckInDate
										WHEN 'LC' THEN @zOriCheckInDate
										WHEN 'ECO' THEN @zCheckOutDate
									  END, N' 至 ', 
									  CASE @zHotelBookingAction 
										WHEN 'EX' THEN @zCheckOutDate
										WHEN 'ECI' THEN @zOriCheckInDate
										WHEN 'LC' THEN @zCheckInDate
										WHEN 'ECO' THEN @zOriCheckOutDate
									  END, N'，變更後入住日期：', @zCheckInDate, N'，退房日期：', @zCheckOutDate,
									  CASE WHEN ISNULL(@sPassenger, '') = '' THEN '' ELSE N'，登記人：' END, @sPassenger);
			END
		END

		IF @sIsNeedConcat = 'Y'
		BEGIN
			SET @vRemark = CONCAT(ISNULL(@vRemark, ''),
								CASE WHEN ISNULL(@sAsstBooker, '') = '' THEN ''	ELSE N'，代訂人：' END, @sAsstBooker, 
								CASE WHEN ISNULL(@sAsstBookerPhoneNo, '') = '' THEN '' ELSE N'，代訂人電話：' END, @sAsstBookerPhoneNo, 
								CASE WHEN ISNULL(@sCashReceiptNo, '') = '' THEN '' ELSE N'，現金單號：' END, @sCashReceiptNo, 
								' (', @sRefNo, ')');
		END

		IF ISNULL(@sBookingActionRid, -1) > 0
		BEGIN
			SELECT @vExpDesc = wTitle FROM dbo.mLookUp WHERE wCode = @sPaymentMethod AND wType = 'PAYMENT_TYPE_HOTEL' AND wLangCd = 'zh-tw';
		END
		ELSE
		BEGIN
			SELECT @vExpDesc = wTitle FROM dbo.mLookUp WHERE wCode = @sPaymentMethod AND wType = 'PAYMENT_TYPE' AND wLangCd = 'zh-tw';
		END

		UPDATE @tbl SET 
			wCompNo = ISNULL(wCompNo, 0),
			wCageCodeIn = ISNULL(wCageCodeIn, ''),
			wTranNo = ISNULL(wTranNo, ''),
			--wDate = ISNULL(wDate, ),
			wCurDateTime = ISNULL(wCurDateTime, @vNow),
			wShift = ISNULL(wShift, ''),
			wAgentCodeIn = ISNULL(wAgentCodeIn, ''),
			wCardCodeIn = ISNULL(wCardCodeIn, ''),
			wCustName = ISNULL(wCustName, ''),
			wShopName = ISNULL(wShopName, ''),
			--wExpTypeCode = ISNULL(wExpTypeCode, ),
			--wExpTargetCode = ISNULL(wExpTargetCode, ),
			wExpCode = ISNULL(wExpCode, ''),
			wExpSubCode1 = ISNULL(wExpSubCode1, ''),
			--wCurCode = ISNULL(wCurCode, ''),
			wRoomNo = ISNULL(wRoomNo, ''),
			wRoomCfmCode = ISNULL(wRoomCfmCode, ''),
			--wRoomBookDt = ISNULL(wRoomBookDt, ),
			--wRoomCheckInDt = ISNULL(wRoomCheckInDt, ),
			--wRoomDeptDt = ISNULL(wRoomDeptDt, ),
			wNight = ISNULL(wNight, 0),
			wUnit = ISNULL(wUnit, 1),
			wPrice = ISNULL(wPrice, 0),
			wRoomExpAmt = ISNULL(wRoomExpAmt, 0),
			wAmount = ISNULL(wAmount, 0),
			wExpLocation = ISNULL(wExpLocation, ''),
			wVoucherNo = @vVoucherNo,
			--wVoucherDt = ISNULL(wVoucherDt, ),
			wRemark = ISNULL(@vRemark, ISNULL(wRemark, '')),
			wPeriodCodeIn = ISNULL(wPeriodCodeIn, ''),
			wExpType = ISNULL(wExpType, 'I'),
			wExpGroup = ISNULL(wExpGroup, 'RCRM'),
			wDeductType = ISNULL(wDeductType, 'DC'),
			wPrtPage = ISNULL(wPrtPage, 0),
			wPrtRow = ISNULL(wPrtRow, 0),
			wTotSetAmt = ISNULL(wTotSetAmt, 0),
			--wUpdBy = ISNULL(wUpdBy, ),
			wUpdDt =ISNULL(wUpdDt, @vNow),
			wRefRid = ISNULL(wRefRid, 0),
			wReferId = ISNULL(wReferId, 0),
			wExpSite = ISNULL(wExpSite, ''),
			wReferUpdBy = ISNULL(wReferUpdBy, ''),
			wEliteCodeIn = ISNULL(wEliteCodeIn, ''),
			wSettleInstantTranNo = ISNULL(wSettleInstantTranNo, ''),
			wIsAdj = ISNULL(wIsAdj, 'N'),
			wForeignTranRefNo = ISNULL(wForeignTranRefNo, ''),
			wFxRateHKD = ISNULL(wFxRateHKD, 1),
			wFxRateRMB = ISNULL(wFxRateRMB, 1),
			wExpDesc = ISNULL(@vExpDesc, ISNULL(wExpDesc, '')),
			wExtUpdBy = ISNULL(wExtUpdBy, ''),
			--wInvoiceDateTime_CRM = ISNULL(wInvoiceDateTime_CRM, ),
			--wAmountActual_CRM = ISNULL(wAmountActual_CRM, ),
			wCardNo_CRM = ISNULL(wCardNo_CRM, ''),
			wAuthorizer_CRM = ISNULL(wAuthorizer_CRM, ''),
			wRequestAgentCodeIn = ISNULL(wRequestAgentCodeIn, ''),
			wExpCategory = ISNULL(wExpCategory, ''),
			wGuid = ISNULL(wGuid, ''),
			wIsDeposit = ISNULL(wIsDeposit, 'N'),
			wIsDepositDone = ISNULL(wIsDepositDone, 'N'),
			wProductCategory = ISNULL(wProductCategory, ''),
			wProductDetail = ISNULL(wProductDetail, ''),
			wBookingRid = ISNULL(wBookingRid, -1),
			wBookingActionRid = ISNULL(wBookingActionRid, -1),
			wIsDepositExposed = ISNULL(wIsDepositExposed, 'N'),
			wBookingStatus = ISNULL(wBookingStatus, '')
		WHERE (@sRowID = 0 OR RowID = @sRowID) AND wBookingRid = @sBookingRid AND ISNULL(wRefRid, 0) = ISNULL(@sAirPassengerId, 0) 
			  AND ISNULL(wBookingActionRid, -1) = ISNULL(@sBookingActionRid, -1) AND wBookingStatus = ISNULL(@sBookingStatus, '');

		FETCH NEXT FROM curTbl INTO @sRowID, @sBookingType, @sRefNo, @sAsstBooker, @sAsstBookerPhoneNo, @sBookingRid, @sBookingStatus, @sAirPassengerId, @sBookingActionRid	
	END
	CLOSE curTbl
	DEALLOCATE curTbl
		
	BEGIN TRY
		-- Try to make the transaction scope as small as possible to reduce locking
		IF @sBeginTranCount = 0
		BEGIN
			BEGIN TRAN;
		END;                                                 

		---------------------------------------------------------------------------------------------
		-- Sync Expense to rollsmary
		---------------------------------------------------------------------------------------------
	   
		SET @vXMLInsertExp = ( SELECT * FROM @tbl FOR XML RAW('Record') , ROOT('DataSet'));
				
		IF @vXMLInsertExp != '' AND @sPaymentMethod <> 'OS'
		BEGIN
			DECLARE @vDummy TABLE ( RowID BIGINT );
            INSERT  INTO @vDummy( RowID )
				EXEC RollsMary.spa.SetExpTran @pXML = @vXMLInsertExp, -- xml
					@pActionType = @pActionType, -- char(1)
					@pMainCompNo = @pMainCompNo, -- int
					@pNonceToken = @pNonceToken, -- varchar(64)
					@pErrCode = @vErrCode OUTPUT, -- int
					@pErrMsg = @vErrMsg OUTPUT; -- nvarchar(200)

			IF @vErrCode != 0
			BEGIN
				SET @pErrMsg = @vErrMsg;
				THROW 50001, @pErrMsg, 1;
			END;

            IF @pActionType!='D' AND NOT EXISTS( SELECT 1 FROM RollsMary.dbo.eExpTran e INNER JOIN @vDummy et ON e.RowID=et.RowId)
            BEGIN
                SET @pErrMsg = N'沒有對應的射數記錄，保存失敗';
                THROW 50001, @pErrMsg, 1;
            END;
		END
		
		IF @sBeginTranCount = 0 AND @@TRANCOUNT > 0
		BEGIN
			COMMIT;
		END;       
	END TRY
	BEGIN CATCH
		DECLARE @vErrorNum INT ,
			@vCatchErrorMessage NVARCHAR(4000) ,
			@xstate INT ,
			@vProcedureName VARCHAR(100) ,
			@vRtnCodeLog INT ,
			@vErrMessageLog NVARCHAR(4000);
			
		SET @vErrorNum = ERROR_NUMBER();
		SET @vCatchErrorMessage = ERROR_MESSAGE();
		SET @xstate = XACT_STATE();
		SET @vProcedureName = OBJECT_NAME(@@PROCID);
			
		IF ISNULL(@pErrCode, 0) = 0
			BEGIN
				SET @pErrCode = 999;
			END;
		SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @vErrorNum, ') ', @vCatchErrorMessage);
			
		IF @sBeginTranCount = 0
			BEGIN
				IF @xstate != 0
					ROLLBACK;
				EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT, @vErrMessageLog OUTPUT;
			END;
		ELSE
			THROW;

	END CATCH;
END
