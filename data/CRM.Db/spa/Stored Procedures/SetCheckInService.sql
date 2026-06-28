CREATE PROCEDURE [spa].[SetCheckInService]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D   
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pBookingRid BIGINT ,
      @pCheckInServiceRid BIGINT = 0 OUTPUT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT                
    )
AS
    BEGIN             
        SET NOCOUNT ON;                                    

        DECLARE @sThisTableName VARCHAR(50) = 'eBookingCheckinservice' , -- For RowID                                    
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @vNow DATETIME2 = dbo.fnUTC8Now() ,
            @sActionAffectedXML NVARCHAR(MAX) = '' ,
            @sXMLeGift NVARCHAR(MAX) = '' ,
            @sCageCodeIn VARCHAR(14) ,
            @vMthEndYearMth VARCHAR(6) ,
            @vDateUsingCRM DATETIME2 ,
            @sDocHandle INT ,
            @sBeginTranCount INT = 0;                

        DECLARE @sReturnRowID TABLE ( RowID BIGINT ); 
        
        SET @sBeginTranCount = @@trancount; 

        SET @sCageCodeIn = ( SELECT TOP 1
                                    c.wCageCodeIn
                             FROM   dbo.eBooking b
                                    INNER JOIN dbo.mServiceCounter sc ON sc.RowID = b.wDebitCounterRid
                                    INNER JOIN RollsMary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                                        AND c.wCageCode = '001'
                                                                        AND c.wStatus = 'A'
                             WHERE  b.RowID = @pBookingRid
                           );

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;    

        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetBookingCheckInService
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)                                    
        WITH (                        
                RowID BIGINT,                       
                wBookingRid BIGINT,                       
                wBookDt DATETIME2(7),                       
                wExpAmt NUMERIC(18,4),                      
                wTotalAmt NUMERIC(18,4) ,                               
                wPaymentMethod VARCHAR(30) ,                               
                wReceiptNo NVARCHAR(50),                          
                wCurrCode VARCHAR(6) ,                               
                wExtraFee  NUMERIC(18,4) ,                               
                wRemark NVARCHAR(500),                               
                wBookingStatus VARCHAR(2),                               
                wCrtBy BIGINT ,                               
                wCrtDt DATETIME2(7),                        
                wTicketCollectionRid BIGINT,                       
                wBookingDateRid BIGINT,                       
                wServiceCounterRid BIGINT,                       
                wOrderNo NVARCHAR(50),                       
                wUpdBy BIGINT, 
                wUpdDt DATETIME2 (7)
                ,wSupplier BIGINT
                ,wRelatedOrderNo NVARCHAR(50)
                ,wFlightNo	VARCHAR(30)	
                ,wDepartAirport	VARCHAR(50)	
                ,wDestination	VARCHAR(50)	
                ,wDepartDt	DATETIME2(7)	
                ,wArrivalDt	DATETIME2(7)	
                ,wArrivalTimeToG15nG16	DATETIME2 (7)
                ,wNoOfBaggage	NUMERIC(18,4)
                ,wPassengerName	NVARCHAR(50)
                ,wPassengerPhoneTel	NVARCHAR(50)
                ,wVIPRoom	CHAR(1)
                ,wVIPRoomPrice	NUMERIC(18,4)
                ,wUnitPrice	NUMERIC(18,4)
                ,wQuantity NUMERIC(18,4)
                ,wCost NUMERIC(18,4)
                ,wSeatRequest NVARCHAR(50)
                ,wAdditionalFee NUMERIC(18,4)
                ,wCheckInRemarks NVARCHAR(50)
                ,wUnqualifiedRid BIGINT
                ,wStatus CHAR(1)
                ,wOldBookingStatus VARCHAR(5)
            ); 

        UPDATE  #sDataSet_SetBookingCheckInService
        SET     wBookingRid = @pBookingRid
        WHERE   wBookingRid <= 0;
                --- Check In Service Required Field Validation Start
/*
                DECLARE @errorMsg varchar(max);	
                IF  @pActionType IN ('I', 'U') 
                BEGIN
                        SELECT  @errorMsg = CASE 
                                        WHEN RTRIM(ISNULL(tmp.wOrderNo,'')) = '' THEN 'Order No is Missing' 
                                        WHEN tmp.wSupplier <= 0  THEN 'Supplier is Missing'
                                        WHEN RTRIM(ISNULL(tmp.wCurrCode,'')) = '' THEN 'Currency is Missing'
                                        WHEN tmp.wArrivalTimeToG15nG16 = '18000101' THEN 'Arrival Time To G15 & G16 Date Time is Missing'
                                        WHEN RTRIM(ISNULL(tmp.wPaymentMethod,'')) = '' THEN 'Payment Method is missing'	
                                        WHEN RTRIM(ISNULL(tmp.wBookingStatus,'')) = '' THEN 'Status is missing'	
                                        WHEN tmp.wTotalAmt<0 THEN 'Total amount is missing'					 
                                        WHEN tmp.wCost<0 THEN 'Cost is missing'								  					 
                                END
                    FROM #sDataSet_SetBookingCheckInService tmp
                END
                IF @errorMsg <> ''
                    throw 50001, @errorMsg, 1;
            IF  @pActionType = 'U' 
                BEGIN
                    SELECT  @errorMsg =  CASE 
                                            WHEN cs.wCurrCode<>tmp.wCurrCode THEN 'Can not be updated Currency when booking status is ' +lup.wTitle 
                                            WHEN cs.wUnitPrice<>tmp.wUnitPrice  and cs.wBookingStatus IN ('C','CL','UQ','RF') THEN 'Can not be updated Unit Price when booking status is '+lup.wTitle  
                                            WHEN cs.wQuantity<>tmp.wQuantity and cs.wBookingStatus IN ('C','CL','UQ','RF') THEN 'Can not be updated Quantity when booking status is '+lup.wTitle  
                                            WHEN cs.wTotalAmt<>tmp.wTotalAmt and cs.wBookingStatus IN ('C','CL','UQ','RF') THEN 'Can not be updated Total Amount when booking status is '+lup.wTitle  
                                            WHEN cs.wExpAmt<>tmp.wExpAmt and cs.wBookingStatus IN ('C','CL','UQ','RF') THEN 'Can not be updated Expense Amount when booking status is '+lup.wTitle  
                                            WHEN cs.wAdditionalFee<>tmp.wAdditionalFee and cs.wBookingStatus IN ('CL','UQ') THEN 'Can not be updated Additional Fee when booking status is '+lup.wTitle  
                                            WHEN cs.wCost<>tmp.wCost and cs.wBookingStatus IN ('C','CL','UQ','RF') then 'Can not be updated Cost when booking status is ' +lup.wTitle  
                                            WHEN cs.wPaymentMethod<>tmp.wPaymentMethod and cs.wBookingStatus IN ('C','CL','UQ','RF')  THEN 'Can not be updated PaymentMethod when booking status is '+lup.wTitle  
                                            WHEN cs.wBookingStatus in ('RF','CL','UQ') AND  cs.wBookingStatus <> tmp.wBookingStatus THEN lup.wTitle + ' status can not be changed to status code ' + tmp.wBookingStatus
                                            WHEN cs.wBookingStatus in ('C') AND  tmp.wBookingStatus in ('P','CL','UQ') THEN lup.wTitle + ' status can not be changed to status code ' + tmp.wBookingStatus
                                            WHEN cs.wBookingStatus in ('P') AND  tmp.wBookingStatus in ('RF') THEN lup.wTitle + ' status can not be changed to status code ' + tmp.wBookingStatus								  
                                        END
                    FROM eBookingCheckInService cs 
                    INNER JOIN #sDataSet_SetBookingCheckInService tmp on cs.wBookingRid=tmp.wBookingRid 
                    INNER JOIN mLookUp lup On lup.wCode = cs.wBookingStatus AND lup.wType = 'BOARDING_SERVICE_BOOKING_STATUS' AND lup.wlangCd='en-GB'			
                END
            ELSE IF @pActionType = 'D' 
                BEGIN
                    SELECT  @errorMsg = 
                                        CASE 								  
                                            WHEN cs.wBookingStatus <> ('P') THEN 'Booking can not be deleted if it not "In-Progress"' 
                                        END
                    FROM eBookingCheckInService cs inner join
                        #sDataSet_SetBookingCheckInService tmp on cs.wBookingRid=tmp.wBookingRid			   
            END
      --better don't put everything within try, for example                                    

      --getting mSysTable value       

  --getting currency, period, mCompany ...                                    

       IF @errorMsg <> ''
         throw 50001, @errorMsg, 1;
*/

        BEGIN TRY
            -- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;                                                 

            --------------------------------------------------------------------------Checking-----------------------------------------------------------------------------
            DECLARE @sErrorMsg NVARCHAR(MAX);
            IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType NOT IN ('I', 'U', 'D')
                SET @sErrorMsg = N'非法操作！';
        
            IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType IN ('U', 'D')
            BEGIN
                DECLARE @sBookingType VARCHAR(30) = 'CHK_IN_SVC';
                DECLARE @sCurrentBookingStatus VARCHAR(5); -- DB当前状态
                DECLARE @sOldBookingStatus VARCHAR(5); -- 上一次Get數據時的狀態
                DECLARE @sNewBookingStatus VARCHAR(5); -- Save订单新状态
                DECLARE @sLangCd VARCHAR(10) = 'zh-TW';
                SELECT
                    @sCurrentBookingStatus = ebcs.wBookingStatus, 
                    @sOldBookingStatus = sbcs.wOldBookingStatus,
                    @sNewBookingStatus = sbcs.wBookingStatus
                FROM dbo.eBookingCheckInService AS ebcs 
                INNER JOIN #sDataSet_SetBookingCheckInService AS sbcs ON sbcs.RowID = ebcs.RowID AND sbcs.wBookingRid = ebcs.wBookingRid
                WHERE ebcs.wBookingRid = @pBookingRId;

                -- 獲取不到DB預訂當前狀態，訂單不存在（wBookingStatus IS NOT NULL）
                -- 如果已經有錯誤，不再Check
                IF NULLIF(@sErrorMsg, '') IS NULL AND @sCurrentBookingStatus IS NULL
                    SET @sErrorMsg = N'訂單不存在。';

                -- 如果已經有錯誤，不再Check
                IF NULLIF(@sErrorMsg, '') IS NULL
                    SET @sErrorMsg = dbo.fnGetBookingStatusErrorMsg(@pActionType, @sBookingType, @sCurrentBookingStatus, @sOldBookingStatus, @sNewBookingStatus, @sLangCd);
            
            END;

            IF NULLIF(@sErrorMsg, '') IS NOT NULL
                THROW 50001, @sErrorMsg, 1;
            ------------------------------------------------------------------------End Checking----------------------------------------------------------------------------

            ---------------------------------------------------------------------------------------------
            -- Sync Expense to rollsmary
            ---------------------------------------------------------------------------------------------
            SELECT  @vMthEndYearMth = MAX(wYearMth)
            FROM    RollsMary.dbo.eSettleTran (NOLOCK) WHERE wSettleLineGrp = '';
            SET @vDateUsingCRM = ( SELECT TOP 1
                                            wValue
                                   FROM     RollsMary.dbo.mSysTable
                                   WHERE    wItemCode = 'DATE_USING_CRM'
                                 );
            SET @vDateUsingCRM = ISNULL(@vDateUsingCRM, '2099-12-31');

            IF @pActionType IN ( 'I', 'U' )
                BEGIN
                    DECLARE @vXMLInsertExp NVARCHAR(MAX) = '' ,
                        @vXMLRefundExp NVARCHAR(MAX) = '' ,
                        @vErrCode INT = 0 ,
                        @vErrMsg NVARCHAR(MAX);

                    ALTER TABLE #sDataSet_SetBookingCheckInService ADD 
                    wPeriodCodeIn	VARCHAR(50) NOT NULL DEFAULT '',
                    wYearMth		VARCHAR(6),
                    wDate			DATE,
                    wShift			CHAR(1);

                    --- gen period start -navin 2018-01-19
                    DECLARE @zRecCount INT = 0,
                            @zRuningIndex INT = 1,
                            @zCompNo INT,
                            @zDate DATE;
                    SELECT wRowNum = ROW_NUMBER() OVER ( ORDER BY tmp.RowID ) ,
                           sc.wRollexCompNo AS wCompNo, (CASE tmp.wBookingStatus
                                            WHEN 'RF' THEN ISNULL(b.wCancelDebitDt, b.wDebitDt)
                                            ELSE b.wDebitDt
                                        END) AS wDate
                        INTO #s_Period
                        FROM #sDataSet_SetBookingCheckInService tmp 
                             INNER JOIN dbo.eBooking b ON tmp.wBookingRid = b.RowID
                             LEFT JOIN dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                             LEFT JOIN RollsMary.dbo.mSettlePeriod sp ON sp.wCompNo = sc.wRollexCompNo AND sp.wCageCodeIn = @sCageCodeIn
                                                                        AND CASE tmp.wBookingStatus
                                                                              WHEN 'RF' THEN ISNULL(b.wCancelDebitDt, b.wDebitDt)
                                                                              ELSE b.wDebitDt
                                                                            END BETWEEN sp.wStartDateTime
                                                                                AND     sp.wEndDateTime
                            WHERE sp.wPeriodCodeIn IS NULL;
                                                
                    SELECT @zRecCount = COUNT(1) FROM #s_Period

                    WHILE @zRuningIndex <= @zRecCount BEGIN
                         SELECT @zCompNo =  wCompNo, @zDate = CAST(wDate AS date) FROM #s_Period WHERE wRowNum = @zRuningIndex;
                         IF ISNULL(@zCompNo,0) > 0 AND @zDate IS NOT NULL
                            BEGIN
                                EXEC RollsMary.dbo.spqGetCompPeriod @zCompNo, @zCompNo, @zDate, 'Y', 'N';
                            END
                        SET @zCompNo = 0;
                        SET @zDate = NULL;
                        SET @zRuningIndex = @zRuningIndex + 1;
                    END	

                    -- end gen period

                    UPDATE  tmp
                    SET     wPeriodCodeIn = sp.wPeriodCodeIn,
                            wYearMth = sp.wYear + sp.wMonth,
                            wDate = ISNULL(cs.wDate, CAST(CASE WHEN tmp.wBookingStatus = 'RF' THEN ISNULL(b.wCancelDebitDt, b.wDebitDt)
                                                               ELSE b.wDebitDt
                                                          END AS DATE)) ,
                            wShift = ISNULL(cs.wShift, '1')
                    FROM    #sDataSet_SetBookingCheckInService tmp
                            LEFT JOIN dbo.eBookingCheckInService bh ON tmp.wBookingRid = bh.wBookingRid
                                                                       AND bh.wStatus = 'A'
                            INNER JOIN dbo.eBooking b ON tmp.wBookingRid = b.RowID
                            LEFT JOIN dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                            LEFT JOIN RollsMary.dbo.mSettlePeriod sp ON sp.wCompNo = sc.wRollexCompNo AND sp.wCageCodeIn = @sCageCodeIn
                                                                        AND CASE WHEN tmp.wBookingStatus = 'RF' THEN ISNULL(b.wCancelDebitDt, b.wDebitDt)
                                                                                 ELSE b.wDebitDt
                                                                            END BETWEEN sp.wStartDateTime
                                                                                AND     sp.wEndDateTime
                            LEFT JOIN RollsMary.dbo.eCompShift cs ON cs.wCompNo = sc.wRollexCompNo
                                                                     AND CASE WHEN tmp.wBookingStatus = 'RF' THEN ISNULL(b.wCancelDebitDt, b.wDebitDt)
                                                                              ELSE b.wDebitDt
                                                                         END BETWEEN cs.wStartDateTime
                                                                             AND     cs.wEndDateTime
                    WHERE   tmp.wBookingStatus = 'C'
                            AND ISNULL(bh.wBookingStatus, 'P') != 'C'
                            OR tmp.wBookingStatus = 'RF'
                            AND ISNULL(bh.wBookingStatus, 'P') != 'RF';
                
                -- Check is already Mth end or not	
                    IF EXISTS ( SELECT  1
                                FROM    #sDataSet_SetBookingCheckInService tmp
                                WHERE   wYearMth <= @vMthEndYearMth )
                        BEGIN
                            SET @pErrMsg = CONCAT(@vMthEndYearMth, ' already month end, cannot insert expense on or before that.');
                            THROW 50001, @pErrMsg, 1;
                        END;

                    IF @vNow >= @vDateUsingCRM
                -- Changed Status To CONFIRM, ADD expense tran
                        SET @vXMLInsertExp = ( SELECT   RowID = 0 ,
                                                        wCompNo = sc.wRollexCompNo ,
                                                        wCageCodeIn = c.wCageCodeIn ,
                                                        wTranNo = '' ,
                                                        wDate = tmp.wDate ,
                                                        wCurDateTime = @vNow ,
                                                        wShift = tmp.wShift ,
                                                        wAgentCodeIn = b.wDebitAgentCodeIn ,
                                                        wCardCodeIn = '' ,
                                                        wCustName = ISNULL(a.wCName, '') ,
                                                        wShopName = '' ,
                                                        wExpTypeCode = 'OTHER' ,
                                                        wExpTargetCode = '1000000017' ,
                                                        wExpCode = '1000058000' ,
                                                        wExpSubCode1 = '' ,
                                                        wCurCode = tmp.wCurrCode ,
                                                        wRoomNo = '' ,
                                                        wRoomCfmCode = '' ,
                                                        wRoomBookDt = NULL ,
                                                        wRoomCheckInDt = NULL ,
                                                        wRoomDeptDt = NULL ,
                                                        wNight = 0 ,
                                                        wUnit = 1 ,
                                                        wPrice = CASE tmp.wBookingStatus
                                                                   WHEN 'RF' THEN -1
                                                                   ELSE 1
                                                                 END * CASE WHEN ISNULL(tmp.wPaymentMethod, '') IN ( 'DA', 'GC', 'ST-CASH', 'ST-AP', 'ST-BT', 'ST-CC' ) THEN tmp.wExpAmt
                                                                            ELSE 0
                                                                       END ,
                                                        wRoomExpAmt = 0 ,
                                                        wAmount = CASE tmp.wBookingStatus
                                                                    WHEN 'RF' THEN -1
                                                                    ELSE 1
                                                                  END * CASE WHEN ISNULL(tmp.wPaymentMethod, '') IN ( 'DA', 'GC', 'ST-CASH', 'ST-AP', 'ST-BT', 'ST-CC' ) THEN tmp.wExpAmt
                                                                             ELSE 0
                                                                        END ,
                                                        wExpLocation = LEFT(sc.wDefaultHotelCode, 2) ,
                                                        wVoucherNo = '' ,
                                                        wVoucherDt = tmp.wDate ,
                                                        wRemark = CONCAT(N'登機預訂: ', b.wRefNo) ,
                                                        wPeriodCodeIn = tmp.wPeriodCodeIn ,
                                                        wExpType = 'I' ,
                                                        wExpGroup = 'RCRM' ,
                                                        wDeductType = 'DC' ,
                                                        wPrtPage = 0 ,
                                                        wPrtRow = 0 ,
                                                        wTotSetAmt = 0 ,
                                                        wUpdBy = tmp.wUpdBy ,
                                                        wUpdDt = @vNow ,
                                                        wRefRid = tmp.wBookingRid ,
                                                        wReferId = tmp.wBookingRid ,
                                                        wExpSite = '' ,
                                                        wReferUpdBy = '' ,
                                                        wEliteCodeIn = '' ,
                                                        wSettleInstantTranNo = '' ,
                                                        wIsAdj = 'N' ,
                                                        wForeignTranRefNo = '' ,
                                                        wFxRateHKD = 1 ,
                                                        wFxRateRMB = 1 ,
                                                        wExpDesc = tmp.wPaymentMethod ,
                                                        wExtUpdBy = ISNULL(u.wCName, '') ,
                                                        wInvoiceDateTime_CRM = b.wExpDt ,
                                                        wAmountActual_CRM = CASE tmp.wBookingStatus
                                                                              WHEN 'RF' THEN -1
                                                                              ELSE 1
                                                                            END * tmp.wTotalAmt ,
                                                        wCardNo_CRM = '' ,
                                                        wAuthorizer_CRM = aAuth.wCName ,
                                                        wExpCategory = 'TRAVEL' ,
                                                        wGuid = '' ,
                                                        wRequestAgentCodeIn = b.wReqAgentCodeIn ,
                                                        wIsDeposit = 'N' ,
                                                        wIsDepositDone = 'N' ,
                                                        wProductCategory = '' ,
                                                        wProductDetail = '',
                                                        wBookingRid = tmp.wBookingRid,
                                                        wBookingStatus = tmp.wBookingStatus
                                               FROM     #sDataSet_SetBookingCheckInService tmp
                                                        LEFT JOIN dbo.eBookingCheckInService bh ON tmp.wBookingRid = bh.wBookingRid
                                                                                                   AND bh.wStatus = 'A'
                                                        LEFT JOIN dbo.eBooking b ON tmp.wBookingRid = b.RowID
                                                        LEFT JOIN RollsMary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                                        LEFT JOIN RollsMary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                                        LEFT JOIN dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                                                        LEFT JOIN RollsMary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                                                           AND c.wCageCode = '001'
                                                                                           AND c.wStatus = 'A'
                                                        LEFT JOIN RollsMary.dbo.mUsr u ON tmp.wUpdBy = u.RowID
                                               WHERE    ( tmp.wBookingStatus = 'C'
                                                          AND ISNULL(bh.wBookingStatus, 'P') != 'C'
                                                        )
                                                        OR ( tmp.wBookingStatus = 'RF'
                                                             AND ISNULL(bh.wBookingStatus, 'P') != 'RF'
                                                           )
                                             FOR
                                               XML RAW('Record') ,
                                                   ROOT('DataSet')
                                             );
                
                    IF @vXMLInsertExp != ''
                        BEGIN
                            EXEC spa.SetCrmExpTran @pXML = @vXMLInsertExp, -- xml
                                @pActionType = 'I', -- char(1)
                                @pMainCompNo = @pMainCompNo, -- int
                                @pNonceToken = @pNonceToken, -- varchar(64)
                                @pErrCode = @vErrCode OUTPUT, -- int
                                @pErrMsg = @vErrMsg OUTPUT; -- nvarchar(200)	
                            IF @vErrCode != 0
                                BEGIN
                                    SET @pErrMsg = @vErrMsg;
                                    THROW 50001, @pErrMsg, 1;
                                END;
                        END;
                END;
            ---------------------------------------------------------------------------------------------
            -- End Sync Expense
            ---------------------------------------------------------------------------------------------

            ---------------------------------------------------------------------------------------------
            -- Add eGift record
            ---------------------------------------------------------------------------------------------
            IF EXISTS ( SELECT  1
                        FROM #sDataSet_SetBookingCheckInService tmp
                        INNER JOIN dbo.eBookingCheckInService bcis ON tmp.wBookingRid = bcis.wBookingRid
                        WHERE ((tmp.wBookingStatus = 'C' AND ISNULL(bcis.wBookingStatus, 'P') != 'C')
                               OR (tmp.wBookingStatus = 'RF' AND ISNULL(bcis.wBookingStatus, 'P') != 'RF')
                               OR (tmp.wBookingStatus = 'C' AND bcis.wBookingStatus = 'C')
                               OR (tmp.wBookingStatus = 'RF' AND bcis.wBookingStatus = 'RF'))
                          AND (tmp.wPaymentMethod = 'GC' OR tmp.wPaymentMethod = 'GC0'))
                BEGIN                    
                    SET @sXMLeGift = ( SELECT   g.RowID AS RowID ,
                                                tmp.wBookingRid AS wRefBookingRid ,
                                                'eBooking' AS wRefTableName ,
                                                tmp.wBookingRid AS wRefTableRid ,
                                                tmp.wBookingStatus AS wOriActionType ,
                                                b.wDebitCounterRid AS wDebitCounterRid ,
                                                b.wReqCounterRid AS wReqCounterRid ,
                                                sc.wRollexCompNo AS wCompNo ,
                                                @sCageCodeIn AS wCageCodeIn ,
                                                b.wReqDepartment AS wReqDeptCd ,
                                                b.wReqUserRid AS wReqStaffRid ,
                                                b.wReqAgentCodeIn AS wReqAgentCodeIn ,
                                                wDate = CASE WHEN g.RowID IS NULL THEN GETDATE() ELSE g.wDate END,
                                                a.wCName AS wRecipient ,
                                                -- 'HKD' AS wCurrCode , --2018-12-14： OP#24284，送禮特批中的金額貨幣現在默認為HKD，應該跟Booking中的貨幣
                                                tmp.wCurrCode AS wCurrCode ,
                                                wAmount = CASE WHEN g.RowID IS NULL THEN (CASE tmp.wBookingStatus WHEN 'RF' THEN -1 ELSE 1 END) * tmp.wTotalAmt ELSE g.wAmount END,
                                                '02' AS wType , --送禮
                                                '0217' AS wSubType , --流動登機服務
                                                wRemark = CASE WHEN (g.RowID IS NULL OR tmp.wRemark != bcis.wRemark) THEN tmp.wRemark ELSE g.wRemark END,
                                                b.wEventCodeRid AS wEventCodeRid ,
                                                wStatus = CASE WHEN g.RowID IS NULL THEN 'A' ELSE g.wStatus END,
                                                wCrtDt = CASE WHEN g.RowID IS NULL THEN @vNow ELSE g.wCrtDt END, -- set sp should not update this field when update
                                                wCrtBy = CASE WHEN g.RowID IS NULL THEN tmp.wUpdBy ELSE g.wCrtBy END, -- in set sp should not update this field when update
                                                @vNow AS wUpdDt ,
                                                tmp.wUpdBy ,
                                                CASE WHEN ((tmp.wBookingStatus = 'C' AND ISNULL(bcis.wBookingStatus, 'P') != 'C')
                                                          OR (tmp.wBookingStatus = 'RF' AND ISNULL(bcis.wBookingStatus, 'P') != 'RF'))
                                                          --AND ISNULL(g.wRefTableRid, 0) <= 0 
                                                THEN 'I'
                                                ELSE 'U'
                                                END AS RecordState ,
                                                b.wGiftReasonCd AS wReasonCd ,
                                                wIsReceived = CASE WHEN g.RowID IS NULL THEN 'Y' ELSE g.wIsReceived END ,-- 經由booking 產生的送禮記錄要預設為 "已接收"
                                                tmp.wCost
                                     FROM #sDataSet_SetBookingCheckInService tmp
                                     INNER JOIN dbo.eBookingCheckInService bcis ON tmp.wBookingRid = bcis.wBookingRid AND bcis.wStatus = 'A' AND (tmp.wPaymentMethod = 'GC' OR tmp.wPaymentMethod = 'GC0')
                                     INNER JOIN dbo.eBooking b ON b.RowID = tmp.wBookingRid
                                     INNER JOIN dbo.mServiceCounter sc ON sc.RowID = b.wReqCounterRid
                                     LEFT JOIN eGift g ON g.wRefTableRid = tmp.wBookingRid AND g.wStatus = 'A' AND ((tmp.wBookingStatus = 'C' AND bcis.wBookingStatus = 'C') OR (tmp.wBookingStatus = 'RF' AND bcis.wBookingStatus = 'RF')) -- 只有Update才能Join到舊數據
                                     INNER JOIN RollsMary.dbo.mAgent a ON a.wAgentCodeIn = b.wApprovalAgentCodeIn AND a.wStatus = 'A'
                                     FOR XML RAW('Record') , ROOT('DataSet'));

                    EXEC spa.SetGift @sXMLeGift, -- xml
                        @pMainCompNo, -- int
                        @pTestMode = 0, -- int
                        @pNonceToken = '', -- varchar(64)
                        @pReturnResultSet = 'N', -- char(1)
                        @pErrCode = 0, -- int
                        @pErrMsg = N''; -- nvarchar(200)     
                END;               
                ---------------------------------------------------------------------------------------------
                -- End Add eGift record
                ---------------------------------------------------------------------------------------------

            IF @pActionType = 'I'
                BEGIN

            -- Set RowID by Sequence             

                    UPDATE  #sDataSet_SetBookingCheckInService
                    SET     RowID = 0;

                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetBookingCheckInService;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;

                --set @pCheckinServiceRid = @sRowID                           

                            UPDATE  #sDataSet_SetBookingCheckInService
                            SET     RowID = @sRowID ,
                                    wBookingRid = @pBookingRid
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;

            -- MAIN Logic here, example here is inserting dataset to eIOUPenalty                                    

                    INSERT  INTO dbo.[eBookingCheckInService]
                            ( RowId ,
                              wBookingRid ,
                              wBookDt ,
                              wExpAmt ,
                              wTotalAmt ,
                              wPaymentMethod ,
                              wReceiptNo ,
                              wCurrCode ,
                              wExtraFee ,
                              wRemark ,
                              wBookingStatus ,
                              wCrtBy ,
                              wCrtDt ,
                              wTicketCollectionRid ,
                              wBookingDateRid ,
                              wServiceCounterRid ,
                              wOrderNo ,
                              wUpdBy ,
                              wUpdDt ,
                              wSupplier ,
                              wRelatedOrderNo ,
                              wFlightNo ,
                              wDepartAirport ,
                              wDestination ,
                              wDepartDt ,
                              wArrivalDt ,
                              wArrivalTimeToG15nG16 ,
                              wNoOfBaggage ,
                              wPassengerName ,
                              wPassengerPhoneTel ,
                              wVIPRoom ,
                              wVIPRoomPrice ,
                              wUnitPrice ,
                              wQuantity ,
                              wCost ,
                              wSeatRequest ,
                              wAdditionalFee ,
                              wCheckInRemarks ,
                              wUnqualifiedRid ,
                              wStatus
                            )
                            SELECT  s.RowID ,
                                    s.wBookingRid ,
                                    s.wBookDt ,
                                    s.wExpAmt ,
                                    s.wTotalAmt ,
                                    s.wPaymentMethod ,
                                    s.wReceiptNo ,
                                    s.wCurrCode ,
                                    s.wExtraFee ,
                                    s.wRemark ,
                                    s.wBookingStatus ,
                                    s.wCrtBy ,
                                    dbo.fnUTC8Now() ,
                                    0 ,
                                    0 ,
                                    0 ,
                                    s.wOrderNo ,
                                    s.wUpdBy ,
                                    dbo.fnUTC8Now() ,
                                    wSupplier ,
                                    s.wRelatedOrderNo ,
                                    s.wFlightNo ,
                                    s.wDepartAirport ,
                                    s.wDestination ,
                                    s.wDepartDt ,
                                    s.wArrivalDt ,
                                    s.wArrivalTimeToG15nG16 ,
                                    s.wNoOfBaggage ,
                                    s.wPassengerName ,
                                    s.wPassengerPhoneTel ,
                                    s.wVIPRoom ,
                                    s.wVIPRoomPrice ,
                                    s.wUnitPrice ,
                                    s.wQuantity ,
                                    s.wCost ,
                                    s.wSeatRequest ,
                                    s.wAdditionalFee ,
                                    s.wCheckInRemarks ,
                                    ISNULL(s.wUnqualifiedRid, 0) ,
                                    s.wStatus
                            FROM    #sDataSet_SetBookingCheckInService s;
                    SET @pCheckInServiceRid = ( SELECT  RowID
                                                FROM    #sDataSet_SetBookingCheckInService
                                              );
                END;
        ---------------------------------------------------------                              
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  cis
                        SET     -- cis.[wBookingRid] = tmp.wBookingRId,                                
                                @pCheckInServiceRid = tmp.RowID ,
                                cis.[wOrderNo] = tmp.wOrderNo ,
                                cis.[wBookDt] = tmp.wBookDt ,
                                cis.[wExpAmt] = tmp.wExpAmt ,
                                cis.[wTotalAmt] = tmp.wTotalAmt ,
                                cis.[wPaymentMethod] = tmp.wPaymentMethod ,
                                cis.[wReceiptNo] = tmp.wReceiptNo ,
                                cis.[wCurrCode] = tmp.wCurrCode ,
                                cis.[wExtraFee] = tmp.wExtraFee ,
                                cis.[wBookingStatus] = tmp.wBookingStatus ,
                                cis.[wRemark] = tmp.wRemark ,
                                cis.[wUpdBy] = tmp.wUpdBy ,
                                cis.[wUpdDt] = dbo.fnUTC8Now() ,
                                cis.[wTicketCollectionRid] = 0 ,
                                cis.[wBookingDateRid] = 0 ,
                                cis.[wServiceCounterRid] = 0 ,
                                cis.wSupplier = tmp.wSupplier ,
                                cis.wRelatedOrderNo = tmp.wRelatedOrderNo ,
                                cis.wFlightNo = tmp.wFlightNo ,
                                cis.wDepartAirport = tmp.wDepartAirport ,
                                cis.wDestination = tmp.wDestination ,
                                cis.wDepartDt = tmp.wDepartDt ,
                                cis.wArrivalDt = tmp.wArrivalDt ,
                                cis.wArrivalTimeToG15nG16 = tmp.wArrivalTimeToG15nG16 ,
                                cis.wNoOfBaggage = tmp.wNoOfBaggage ,
                                cis.wPassengerName = tmp.wPassengerName ,
                                cis.wPassengerPhoneTel = tmp.wPassengerPhoneTel ,
                                cis.wVIPRoom = tmp.wVIPRoom ,
                                cis.wVIPRoomPrice = tmp.wVIPRoomPrice ,
                                cis.wUnitPrice = tmp.wUnitPrice ,
                                cis.wQuantity = tmp.wQuantity ,
                                cis.wCost = tmp.wCost ,
                                cis.wSeatRequest = tmp.wSeatRequest ,
                                cis.wAdditionalFee = tmp.wAdditionalFee ,
                                cis.wCheckInRemarks = tmp.wCheckInRemarks ,
                                cis.wUnqualifiedRid = ISNULL(tmp.wUnqualifiedRid, 0) ,
                                cis.wStatus = tmp.wStatus
                        FROM    dbo.[eBookingCheckInService] AS cis
                                INNER JOIN #sDataSet_SetBookingCheckInService tmp ON cis.RowId = tmp.RowID
                        WHERE   cis.RowId = tmp.RowID;
                    END;

                ELSE
                    IF @pActionType = 'D'
                        BEGIN
                            UPDATE  CIS
                            SET     CIS.[wBookingStatus] = 'DL' ,
                                    CIS.wStatus = 'T' ,
                                    CIS.[wUpdBy] = tmp.wUpdBy ,
                                    CIS.[wUpdDt] = dbo.fnUTC8Now()
                            FROM    dbo.[eBookingCheckInService] AS CIS
                                    INNER JOIN #sDataSet_SetBookingCheckInService tmp ON CIS.RowId = tmp.RowID;

                            DECLARE @BookingRid BIGINT = ( SELECT TOP 1
                                                                    wBookingRid
                                                           FROM     #sDataSet_SetBookingCheckInService
                                                         );

                            UPDATE  ePassengerDetails
                            SET     wPassengerBookingStatus = 'DL' ,
                                    wStatus = 'T'
                            WHERE   wBookingRid = @BookingRid
                                    AND wPassengerBookingStatus = 'P';

                        END;

            ---------------------------------------------------------------------------------------------
            -- SetActionAffectedTableLog
            ---------------------------------------------------------------------------------------------
            SET @sActionAffectedXML = ( SELECT  wActionSp = OBJECT_NAME(@@PROCID) ,
                                                wActionType = @pActionType ,
                                                wNonceToken = @pNonceToken ,
                                                wRefTableName = @sThisTableName ,
                                                wRefRid = tmp.RowID ,
                                                wType = '' ,
                                                wCrtDt = @vNow
                                        FROM    #sDataSet_SetBookingCheckInService tmp
                                      FOR
                                        XML RAW('Record') ,
                                            ROOT('DataSet')
                                      );
            EXEC spa.SetActionAffectedTableLog @sActionAffectedXML, 'I', @pMainCompNo, '', 0, '';

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;  
                
                -- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetBookingCheckInService; 
       
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
    
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetBookingCheckInService') IS NOT NULL
            DROP TABLE #sDataSet_SetBookingCheckInService;
        IF OBJECT_ID('tempdb..#s_Period') IS NOT NULL
            DROP TABLE #s_Period;
    END;