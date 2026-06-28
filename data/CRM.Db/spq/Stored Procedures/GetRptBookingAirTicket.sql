
CREATE PROCEDURE [spq].[GetRptBookingAirTicket]
(
    @pAgentCodeIn VARCHAR(14) ,
    @pDebitCounter NVARCHAR(MAX) ,
    @pFromDt DATETIME2(7) ,
    @pToDt DATETIME2(7) ,
    @pLangCd VARCHAR(10) = 'en-gb',
    @pErrMsg NVARCHAR(200) = '' OUTPUT
)
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
    SET @pFromDt = FORMAT( @pFromDt, 'yyyy-MM-dd 00:00:00');
    SET  @pToDt = FORMAT( @pToDt, 'yyyy-MM-dd 23:59:59');

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
        RowId					BIGINT PRIMARY KEY IDENTITY(1, 1),
        wBookingType			NVARCHAR(30),				-- 消費類型
        wDebitDt				DATETIME2(7),				-- 扣數日期
        wCancelDebitDt			DATETIME2(7),				-- 取消扣數日期
        wCancelDt				DATETIME2(7),				-- 取消日期
        wRefNo					VARCHAR(30) DEFAULT '',		-- 訂單編號
        wRelatedBookingRefNo	VARCHAR(30) DEFAULT '',		-- 相關訂務
        wDebitCounterRid		BIGINT DEFAULT 0,			-- 扣數場館
        wReqCounterRid			BIGINT DEFAULT 0,			-- 要求場館
        wDebitAgentCodeIn		VARCHAR(14),				-- 扣數戶口 code
        wReqAgentCodeIn			VARCHAR(14),				-- 要求戶口 code
        wTranvalAgencyName		NVARCHAR(100),				-- 供應商名稱
        wOrderNo				NVARCHAR(100),				-- 單號
        wPaymentMethod			VARCHAR(30),				-- 付款方式
        wReceiptNo				NVARCHAR(100),				-- 現金單號
        wDepositCost			NUMERIC(18, 4),				-- 按金
        wTotalCost				NUMERIC(18, 4),				-- 總成本
        wTotalAmount			NUMERIC(18, 4),				-- 總值
        wDateString				NVARCHAR(MAX),				-- 日期
        wPassengerDateString	NVARCHAR(MAX),				-- 小单日期
        wQuantity				INT,						-- 數量
        wRouteString			NVARCHAR(MAX),				-- 航線
        wPassengerRouteString	NVARCHAR(MAX),				-- 小单航線
        wTicketType				NVARCHAR(100),				-- 票類型
        wHotel					NVARCHAR(500),				-- 酒店
        wDetail					NVARCHAR(MAX),				-- 明細
        wPassengerDetail		NVARCHAR(MAX),				-- 小单明細
        wCustomer				NVARCHAR(MAX),				-- 客人
        wBookingStatus			VARCHAR(30),				-- 訂單狀態
        wRemark					NVARCHAR(MAX),				-- 備註
        wCancelReasonCd			VARCHAR(30),				-- 取消原因 code
        wOtherReason			NVARCHAR(200),				-- 其它取消原因			
        wAsstBooker				NVARCHAR(100),				-- 代訂人
        wAsstBookerTel			VARCHAR(100),				-- 代訂人電話
        wAssBookerEmail			NVARCHAR(100),				-- 代訂人電郵
        wDeptFollowedCd			VARCHAR(30),				-- 跟進部門
        wStaffFollowedRid		BIGINT,						-- 跟進同事
        wApprovalAgentCodeIn	VARCHAR(14),				-- 確認戶主/授權人
        wEventCodeRid			BIGINT,						-- 活動代碼
        wReqDepartment			VARCHAR(30),				-- 要求部門
        wReqUserRid				BIGINT,						-- 要求同事
        wTravelPkgRid			BIGINT,						-- 旅遊套票
        wUseBlackCard			NCHAR(1),					-- 黑卡?
        wSameDebitDtCnt			VARCHAR(10),				-- 最終要顯示  '1/wSameDebitDtCnt'
        wExpCategory			NVARCHAR(200),				-- 消費類型 （其他消費的消費類型取Booking的消費類型及消費副類型）
        -- using for joining eExpTran
        wBookingRid				BIGINT DEFAULT -1,
        wBookingDtlRid			BIGINT DEFAULT -1,			-- Passenger or room
        wHotelChangeRid			BIGINT DEFAULT -1,			-- For hotel
        wCrtDt                  DATETIME2(7),               -- 創建日期
        wAllCustomer			NVARCHAR(MAX),				--有按金的時候,需要將所有客戶取出匯成一條記錄
        wCustomerNo				VARCHAR(30) DEFAULT ''		--客戶編號
    );

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
            wPassengerCustomer = CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN pp.wEName ELSE pp.wCName END, CASE WHEN NULLIF(pttd.wEnglishPinyin, '') IS NULL THEN NULL ELSE ' (' + pttd.wEnglishPinyin + ')' END),
            wBookingCustomer = STUFF(
                (SELECT CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN p.wEName ELSE p.wCName END, CASE WHEN NULLIF(ptd.wEnglishPinyin, '') IS NULL THEN NULL ELSE ' (' + ptd.wEnglishPinyin + ')' END)
                FROM dbo.ePassengerDetails AS spd
                INNER JOIN dbo.mPerson AS p ON spd.wPersonRid = p.RowID
                LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON spd.RowID = ptdd.wPassengerDetailsRid
                LEFT JOIN dbo.mPersonTravelDoc AS ptd ON ptdd.wPersonTravelDocRid = ptd.RowID
                WHERE spd.wBookingRid = rpd.wBookingRid AND spd.wStatus = 'A' AND ptdd.RowID = (SELECT MIN(RowID) FROM dbo.ePassengerTravelDocDetail WHERE wPassengerDetailsRid = spd.RowID)
                FOR XML PATH('')), 1, 1, N''),
            wPassengerTicketNo = CASE WHEN NULLIF(rpd.wClientTicketNo, '') IS NULL THEN NULL ELSE CONCAT(CHAR(10), CASE WHEN @pLangCd = 'en-GB' THEN pp.wEName ELSE pp.wCName END, '(', rpd.wClientTicketNo , ') ') END,
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
        LEFT JOIN @tmpFilterCounter AS fil ON eb.wDebitCounterRid = fil.wCounterRid
        LEFT JOIN dbo.ePassengerTravelDocDetail AS ptdd ON rpd.RowID = ptdd.wPassengerDetailsRid
        INNER JOIN dbo.mPerson AS pp ON rpd.wPersonRid = pp.RowID
        LEFT JOIN dbo.mPersonTravelDoc AS pttd ON ptdd.wPersonTravelDocRid = pttd.RowID
        WHERE (@pAgentCodeIn IS NULL OR eb.wDebitAgentCodeIn = @pAgentCodeIn)
            AND (@pDebitCounter IS NULL OR fil.wCounterRid IS NOT NULL)
            AND ((rps.wMapBookingStatus = 'C' AND eb.wDebitDt BETWEEN @pFromDt AND @pToDt)
                OR (rps.wMapBookingStatus = 'RF' AND rpd.wCancelDebitDt BETWEEN @pFromDt AND @pToDt)
                OR (eb.wHasDeposit = 'Y' AND eb.wUpdDt > @pFromDt AND eb.wCrtDt < @pToDt))

        INSERT INTO #tmpResult (
            wBookingType,
            wDebitDt,
            wCancelDebitDt,
            wCancelDt,
            wRefNo,
            wRelatedBookingRefNo,
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
            wDateString,
            wPassengerDateString,
            wQuantity,
            wRouteString,
            wPassengerRouteString,
            wTicketType,
            wHotel,
            wDetail,
            wPassengerDetail,
            wCustomer,
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
            wExpCategory,
            wCrtDt,
            wBookingRid,
            wBookingDtlRid,
            wHotelChangeRid,
            wCustomerNo,
            wAllCustomer
        )
        SELECT
            wBookingType = eb.wBookingType,
            wDebitDt = eb.wDebitDt,
            wCancelDebitDt = pd.wCancelDebitDt,
            wCancelDt = pd.wCancelDt,
            wRefNo = eb.wRefNo,
            wRelatedBookingRefNo = NULL,
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
            wDateString = ar.wRouteTime, -- CASE WHEN pd.wPassengerBookingStatus = 'RF' AND pd.wCancelDt != ISNULL(eb.wCancelDt, @sStartDateTime) AND pr.wRouteTime IS NOT NULL THEN pr.wRouteTime ELSE ar.wRouteTime END,
            wPassengerDateString = pr.wRouteTime,
            wQuantity = air.wQuantity,
            wRouteString = ar.wRouteTitle, --CASE WHEN pd.wPassengerBookingStatus = 'RF' AND pd.wCancelDt != ISNULL(eb.wCancelDt, @sStartDateTime) AND pr.wRouteTitle IS NOT NULL THEN pr.wRouteTitle ELSE ar.wRouteTitle END,
            wPassengerRouteString = pr.wRouteTitle,
            wTicketType = NULL,
            wHotel = NULL,
            wDetail = CONCAT(N'預訂類型：', tType.wTitle, char(10), 
                            N'航空公司：',ar.wAirlines ,char(10), 
                            N'到期日：', CASE WHEN air.wExpiryDt IS NOT NULL THEN FORMAT(air.wExpiryDt, 'yyyy-MM-dd') ELSE NULL END, char(10),
                            ar.wFlight , char(10),
                            N'票號：', pd.wBookingTicketNo
                      ),
            wPassengerDetail = CONCAT(N'預訂類型：', tType.wTitle, char(10), 
                            N'航空公司：', pr.wAirlines , char(10), 
                            N'到期日：', CASE WHEN air.wExpiryDt IS NOT NULL THEN FORMAT(air.wExpiryDt, 'yyyy-MM-dd') ELSE NULL END, char(10),
                            pr.wFlight, char(10),
                            N'票號：', pd.wPassengerTicketNo
                      ),			  						  		
            wCustomer = pd.wPassengerCustomer,
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
            wExpCategory = NULL,
            wCrtDt = air.wCrtDt,
            wBookingRid = eb.RowID,
            wBookingDtlRid = pd.RowID,
            wHotelChangeRid = -1,
            wCustomerNo=eb.wRefNo + '-' + RIGHT('000' + CAST(( pd.wSeqNo ) AS VARCHAR(3)), 3),
            wAllCustomer=pd.wBookingCustomer
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
            p.RowID,
            p.wBookingRid,
            b.wRefNo
        INTO #tTravelPkg
        FROM dbo.eBookingTravelPackage p
        INNER JOIN dbo.eBooking b ON b.RowID = p.wBookingRid;

        -- 消費券
        SELECT
            rv.wBookingRid,
            wVoucher = STUFF(
                (SELECT N', ' + CAST(m.wVoucherRefNo AS NVARCHAR)
                From dbo.eVoucher AS sv
                INNER JOIN dbo.mVoucher AS m ON m.RowID = sv.wVoucherRid AND sv.wBookingRid = rv.wBookingRid
                FOR XML PATH('')), 1, 2, N'')
        INTO #tVoucher
        FROM dbo.eVoucher AS rv
        GROUP BY rv.wBookingRid;

        SELECT
            RowId = tmp.RowId,
            wBookingRid = tmp.wBookingRid,
            wBookingTypeCode = tmp.wBookingType,
            wMapBookingStatus = ISNULL(bs.wMapBookingStatus, tmp.wBookingStatus),
            wExpTranRid = et.RowID,
            wCurDateTime = et.wCurDateTime,
            wBookingType = (
                CASE WHEN @pLangCd = 'en-GB' THEN UPPER(tmp.wBookingType)
                ELSE dbo.fnGetBookingTypeName(tmp.wBookingType) END
            ),				-- 消費類型
            wRefNo=CASE WHEN ISNULL(et.wIsDeposit, 'N')!='Y'THEN tmp.wCustomerNo ELSE tmp.wRefNo END,	-- 訂單編號
            tmp.wRelatedBookingRefNo,		-- 相關訂務
            wDebitCounterName = dsc.wName,	-- 扣數場館
            wReqCounterName = rsc.wName,	-- 要求場館
            wDebitAgentCode = aDebit.wAgentCode_Display,
            wDebitAgentName = CASE WHEN @pLangCd = 'en-GB' THEN aDebit.wEName ELSE aDebit.wCName END,	-- 扣數戶口
            wReqAgentCode = aReq.wAgentCode_Display,
            wReqAgentName = CASE WHEN @pLangCd = 'en-GB' THEN aReq.wEName ELSE aReq.wCName END,			-- 要求戶口
            tmp.wTranvalAgencyName,		-- 供應商名稱
            tmp.wOrderNo,				-- 單號
            wPayMethod = (
                CASE tmp.wBookingType
                WHEN 'CHANGEHOTEL' THEN hotelPay.wTitle
                WHEN 'HOTEL' THEN hotelPay.wTitle
                WHEN 'ROOM' THEN hotelPay.wTitle
                Else pay.wTitle END
            ),				-- 付款方式
            tmp.wReceiptNo,	-- 現金單號
            wIsDeposit = ISNULL(et.wIsDeposit, 'N'),
            wTotalCost = CASE WHEN et.wIsDeposit = 'Y' THEN tmp.wDepositCost ELSE (CASE WHEN (et.wAmount < 0 OR et.wAmountActual_CRM < 0 OR bs.wMapBookingStatus = 'RF') AND tmp.wTotalCost > 0 THEN -1 * tmp.wTotalCost ELSE tmp.wTotalCost END) END,	-- 總成本
            wDateString=CASE WHEN ISNULL(et.wIsDeposit, 'N')!='Y'THEN tmp.wPassengerDateString ELSE tmp.wDateString END,		-- 日期
            tmp.wQuantity,			-- 數量
            wRouteString=CASE WHEN ISNULL(et.wIsDeposit, 'N')!='Y'THEN tmp.wPassengerRouteString ELSE tmp.wRouteString END,		-- 航線
            tmp.wTicketType,		-- 票類型
            tmp.wHotel,				-- 酒店
            wDetail =CASE WHEN NULLIF(ev.wVoucher, '') IS NULL THEN (CASE WHEN ISNULL(et.wIsDeposit, 'N')!='Y'THEN tmp.wPassengerDetail ELSE tmp.wDetail END ) ELSE  CONCAT(tmp.wDetail, CHAR(10), N'消費券：', ev.wVoucher) END,-- 明細
            wCustomer = CASE WHEN ISNULL(et.wIsDeposit, 'N')!='Y'THEN tmp.wCustomer ELSE tmp.wAllCustomer END,		-- 客人
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
            wDebitDt = ISNULL(et.wDate, CASE WHEN ISNULL(bs.wMapBookingStatus, tmp.wBookingStatus) = 'RF' THEN tmp.wCancelDebitDt ELSE tmp.wDebitDt END),
            wCancelDt = CASE WHEN (tmp.wBookingType IN ('AIRTICKET', 'HELI') AND tmp.wBookingStatus = 'RF') OR bs.wMapBookingStatus = 'RF' THEN tmp.wCancelDt ELSE NULL END,	-- 取消日期
            -- 射數為0，取射數第一條記錄的值
            -- 當射數為0時，Join不到射數值，取第一條射數為0的記錄
            --（目前，如果【完成】、【退款】其中一條射數失敗，最後兩條都會有值【0】，都是【0】影響不大，後面在射數表wBookingStatus賦值后能解決此問題）
            wAmount = ISNULL(et.wAmount, zet.wAmount),
            wAmountActual_CRM = ISNULL(et.wAmountActual_CRM, zet.wAmountActual_CRM ),
            wExpCategory = (
                CASE WHEN @pLangCd = 'en-GB' THEN UPPER(tmp.wBookingType)
                ELSE ( 
                    CASE tmp.wBookingType
                    WHEN 'ADDITIONALEXPENSES'	THEN tmp.wExpCategory
                    WHEN 'HOTEL'				THEN N'住'
                    WHEN 'ROOM'					THEN N'住'
                    WHEN 'CHANGEHOTEL'			THEN N'住'
                    WHEN 'AIRTICKET'			THEN N'行'
                    WHEN 'CHK_IN_SVC'			THEN N'行'
                    WHEN 'FERRY'				THEN N'行'
                    WHEN 'HELI'					THEN N'行'
                    WHEN 'LEADING_SERVICE'		THEN N'行'
                    WHEN 'PickUp_SERVICE'		THEN N'行'
                    WHEN 'PP'					THEN N'行'
                    WHEN 'SHOWTICKET'			THEN N'樂'
                    WHEN 'TOUR'					THEN N'樂'
                    WHEN 'TRAVEL_PACKAGE'		THEN N'樂'
                    WHEN 'Visa'					THEN N'樂'
                    ELSE UPPER(tmp.wBookingType) END
                ) END
            ),                  
            tmp.wCrtDt
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
        LEFT JOIN dbo.mLookUp AS hotelPay ON hotelPay.wLangCd = @pLangCd AND hotelPay.wType = 'PAYMENT_TYPE_HOTEL' AND hotelPay.wCode = tmp.wPaymentMethod
        LEFT JOIN dbo.mLookUp AS cancel ON cancel.wLangCd = @pLangCd AND cancel.wType = 'CANCEL_REASON' AND cancel.wCode = tmp.wCancelReasonCd
        LEFT JOIN #tVoucher AS ev ON ev.wBookingRid = tmp.wBookingRid
        LEFT JOIN @tmpBookingStatus AS bs ON tmp.wBookingType!= 'AIRTICKET' AND bs.wBookingStatus = tmp.wBookingStatus -- 房間預計不進行狀態判斷統計，因為每次都會在eBooking中生成一條新的記錄
        LEFT JOIN #tExpTran AS et ON -- 房间按金 et.wReferId = Hotel.wBookingRid， et.wRefRid = Room.RowId，其他预订: et.wReferId = xx.wBookingRid
                (et.wIsDeposit = 'Y' AND et.wBookingRid = tmp.wBookingRid  
                    AND((tmp.wBookingStatus != 'C' AND tmp.wBookingStatus != 'RF') OR (tmp.wBookingStatus = 'C'					
                    AND tmp.wBookingDtlRid =(SELECT MIN(wBookingDtlRid) FROM #tmpResult ttmp WHERE ttmp.wBookingRid=tmp.wBookingRid)))
                ) --按金， 退款狀態屬於重複數據（RF --> C、RF），只需要選擇C狀態)
                    OR
                    (				
                        et.wIsDeposit != 'Y'
                        AND et.wBookingRid = tmp.wBookingRid
                        AND (tmp.wBookingDtlRid = -1 OR tmp.wBookingDtlRid = et.wRefRid)
                        AND (tmp.wHotelChangeRid = -1 OR CAST(tmp.wHotelChangeRid AS VARCHAR) = et.wShopName)
                        AND ((ISNULL(bs.wMapBookingStatus, tmp.wBookingStatus) = 'C' AND ((ISNULL(tmp.wTotalAmount, 0) >= 0 AND et.wAmountActual_CRM > 0) OR (ISNULL(tmp.wTotalAmount, 0) < 0 AND et.wAmountActual_CRM < 0)))	-- 如果Booking中的總值小於0時，【完成】期望射數值小於0，其他情況期望射數值大於0
                                OR (ISNULL(bs.wMapBookingStatus, tmp.wBookingStatus) = 'RF' AND ((ISNULL(tmp.wTotalAmount, 0) >= 0 AND et.wAmountActual_CRM < 0) OR (ISNULL(tmp.wTotalAmount, 0) < 0 AND et.wAmountActual_CRM > 0))))	-- 如果Booking中的總值小於0時，【完成】期望射數值大於0，其他情況期望射數值小於0
                    )
        LEFT JOIN #tZeroExpTran AS zet ON zet.wBookingRid = tmp.wBookingRid AND (tmp.wBookingDtlRid = -1 OR tmp.wBookingDtlRid = zet.wRefRid) AND (tmp.wHotelChangeRid = -1 OR CAST(tmp.wHotelChangeRid AS VARCHAR) = zet.wShopName)	
        --正確射數，取射數表射數日期
        --只有eBooking.wBookingStatus = 'RF'，wCancelDebitDt不為空
        --如果射數表射數日期、取消扣數日期都為空，取eBooking.wDebitDt
        WHERE ISNULL(et.wDate, CASE WHEN ISNULL(bs.wMapBookingStatus, tmp.wBookingStatus) = 'RF' THEN tmp.wCancelDebitDt ELSE tmp.wDebitDt END) BETWEEN @pFromDt AND @pToDt

        SELECT
            tmp.wBookingType,				-- 消費類型
            tmp.wRefNo,						-- 訂單編號
            tmp.wRelatedBookingRefNo,		-- 相關訂務
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
            wTotalCost ,-- 總成本
            wAmount,-- 消費額
            wAmountActual_CRM -- 總值
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