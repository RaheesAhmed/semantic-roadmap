CREATE PROCEDURE [spa].[SetBookingHeli]
    (
      @pXML XML ,
      @pActionType CHAR(1) ,  -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pBookingRid BIGINT ,
      @pTicketId BIGINT OUTPUT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
    )
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @vXMLText NVARCHAR(MAX) ,
            @sThisTableName VARCHAR(50) = 'eBookingHeli' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @vNow DATETIME2 = dbo.fnUTC8Now() ,
            @sActionAffectedXML NVARCHAR(MAX) = '' ,
            @sXMLeGift NVARCHAR(MAX) = '' ,
            @sCageCodeIn VARCHAR(14) ,
            @sDocHandle INT ,
            @sSeqNo INT = 0 ,
            @sTicketNo INT = 0 ,
            @vMthEndYearMth VARCHAR(6) ,
            @vDateUsingCRM DATETIME2;
            
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

     --   SET @vXMLText = CAST(@pXML AS NVARCHAR(MAX));
        --EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, 'SetBookingHeli', @vXMLText, 0 , '';

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
        
        --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetBookingHeli
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
        WITH (
                RowID BIGINT ,
                wBookingRid BIGINT,
                wTicketId BIGINT,
                wOrderNo NVARCHAR(20),
                wBookingLocation VARCHAR(20),
                wUseBlackCardFlag CHAR(1),
                wPaymentMethod  VARCHAR(30) ,
                wReceiptNo NVARCHAR(50),
                wRouteRid BIGINT,
                wDepartDt DATETIME2(7),
                wUnitAmt NUMERIC(18,4),
                wQuantity INT,
                wExpAmt NUMERIC(18,4),
                wTotalAmt NUMERIC(18,4),
                wCost NUMERIC(18,4),
                wHandlingFee NUMERIC(18,4),
                wCurrCode VARCHAR(6),
                wAdditionalExp NUMERIC(18,4),
                wRemark NVARCHAR(500),
                wBookingStatus VARCHAR (30),
                wUnqualifiedRid BIGINT,
                wSeqNo INT,
                wCrtDt  DATETIME2(7),
                wCrtBy BIGINT,
                wUpdDt DATETIME2(7),
                wUpdBy BIGINT,
                wIsCharteredFlight CHAR(1),
                wChangeOrderCount INT,
                wOldBookingStatus VARCHAR(5)
            );
/*
            --- Heli Required Field Validation Start
            DECLARE @errorMsg varchar(max);	
            IF  @pActionType IN ('I', 'U') BEGIN
                 select  @errorMsg = case 
                                  when RTRIM(ISNULL(ebh.wOrderNo,'')) = '' then 'Order No is Missing' 
                                  when RTRIM(ISNULL(ebh.wBookingLocation,'')) = '' then 'Supplier is Missing'
                                  when ebh.wRouteRid <= 0  then 'Route is Missing'
                                  when RTRIM(ISNULL(ebh.wCurrCode,'')) = '' then 'Currency is Missing'
                                  when ebh.wDepartDt IS NULL then 'Departure Date Time is Missing'
                                  when RTRIM(ISNULL(ebh.wPaymentMethod,'')) = '' then 'Payment Method is missing'	
                                  when RTRIM(ISNULL(ebh.wBookingStatus,'')) = '' then 'Status is missing'	
                                  when ebh.wTotalAmt<0 then 'Total amount is missing'					 
                                  when ebh.wCost<0 then 'Cost is missing'								  					 
                            end
                from #sDataSet_SetBookingHeli ebh
            END
            IF @errorMsg <> ''
                throw 50001, @errorMsg, 1;
            --- Heli Required Field Validation end

         -- Heli Status Management update Field Validation Start
         IF  @pActionType = 'U' BEGIN
             select  @errorMsg = case 
                                  when eb.wCurrCode<>sb.wCurrCode then 'Can not be updated Currency when booking status is ' +lup.wTitle   
                                  when eb.wPaymentMethod<>sb.wPaymentMethod and eb.wBookingStatus IN ('C','CL','UQ','CO','RF')  then 'Can not be updated PaymentMethod when booking status is '+lup.wTitle  
                                  when eb.wIsCharteredFlight<>sb.wIsCharteredFlight and eb.wBookingStatus='C'  then 'Can not be updated Chartered Flight when booking status is '+lup.wTitle  								  
                                  When eb.wBookingStatus in ('RF','CL','UQ') AND  eb.wBookingStatus <> sb.wBookingStatus then lup.wTitle + ' status can not be changed to status code ' + sb.wBookingStatus
                                  When eb.wBookingStatus in ('C') AND  sb.wBookingStatus in ('P','CL','UQ') then lup.wTitle + ' status can not be changed to status code ' + sb.wBookingStatus
                                  When eb.wBookingStatus in ('P') AND  sb.wBookingStatus in ('RF','CO') then lup.wTitle + ' status can not be changed to status code ' + sb.wBookingStatus								  
                            end
            from eBookingHeli eb inner join
               #sDataSet_SetBookingHeli sb on eb.wBookingRid=sb.wBookingRid 
               INNER JOIN mLookUp lup On lup.wCode = eb.wBookingStatus AND lup.wType = 'HELICOPTER_BOOKING_STATUS' and lup.wlangCd='en-GB'			
        END
        ELSE IF @pActionType = 'D' BEGIN
            select  @errorMsg = case 								  
                                  When sb.wBookingStatus <> ('P') then 'Booking can not be deleted if it not "In-Progress"' 
                            end
            from eBookingHeli eb inner join
               #sDataSet_SetBookingHeli sb on eb.wBookingRid=sb.wBookingRid			   
        END

        IF @errorMsg <> ''
                throw 50001, @errorMsg, 1;

        IF EXISTS( SELECT 1 FROM eBookingHeli As HELI INNER JOIN #sDataSet_SetBookingHeli TEMPHELI ON TEMPHELI.wOrderNo = HELI.wOrderNo AND TEMPHELI.wBookingRid != HELI.wBookingRid  )
                throw 50001, 'Order Number already exist.', 1;		

*/

         --better don't put everything within try, for example
         --getting mSysTable value
         --getting currency, period, mCompany ...
        
    
        SELECT  @vMthEndYearMth = MAX(wYearMth)
        FROM    RollsMary.dbo.eSettleTran (NOLOCK) WHERE wSettleLineGrp = '';	
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
                DECLARE @sBookingType VARCHAR(30) = 'HELI';
                DECLARE @sCurrentBookingStatus VARCHAR(5); -- DB当前状态
                DECLARE @sOldBookingStatus VARCHAR(5); -- 上一次Get數據時的狀態
                DECLARE @sNewBookingStatus VARCHAR(5); -- Save订单新状态
                DECLARE @sLangCd VARCHAR(10) = 'zh-TW';
                SELECT
                    @sCurrentBookingStatus = ebbh.wBookingStatus, 
                    @sOldBookingStatus = sbbh.wOldBookingStatus,
                    @sNewBookingStatus = sbbh.wBookingStatus
                FROM dbo.eBookingHeli AS ebbh 
                INNER JOIN #sDataSet_SetBookingHeli AS sbbh ON sbbh.RowID = ebbh.RowID AND sbbh.wBookingRid = ebbh.wBookingRid
                WHERE ebbh.wBookingRid = @pBookingRId;

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
            -- 直升機比較特別, 包機先Booking 計數, 一般情況就睇乘客數目來扣數
            ---------------------------------------------------------------------------------------------
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

                    ALTER TABLE #sDataSet_SetBookingHeli ADD 
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
                        FROM #sDataSet_SetBookingHeli tmp 
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
                            wDate = ISNULL(cs.wDate, CAST(CASE tmp.wBookingStatus
                                                            WHEN 'RF' THEN b.wCancelDebitDt
                                                            ELSE b.wDebitDt
                                                          END AS DATE)) ,
                            wShift = ISNULL(cs.wShift, '1')
                    FROM    #sDataSet_SetBookingHeli tmp
                            LEFT JOIN dbo.eBookingHeli bh ON tmp.RowID = bh.RowID
                            INNER JOIN dbo.eBooking b ON tmp.wBookingRid = b.RowID
                            LEFT JOIN dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                            LEFT JOIN RollsMary.dbo.mSettlePeriod sp ON sp.wCompNo = sc.wRollexCompNo AND sp.wCageCodeIn = @sCageCodeIn
                                                                        AND CASE tmp.wBookingStatus
                                                                              WHEN 'RF' THEN b.wCancelDebitDt
                                                                              ELSE b.wDebitDt
                                                                            END BETWEEN sp.wStartDateTime
                                                                                AND     sp.wEndDateTime
                            LEFT JOIN RollsMary.dbo.eCompShift cs ON cs.wCompNo = sc.wRollexCompNo
                                                                     AND CASE tmp.wBookingStatus
                                                                           WHEN 'RF' THEN b.wCancelDebitDt
                                                                           ELSE b.wDebitDt
                                                                         END BETWEEN cs.wStartDateTime
                                                                             AND     cs.wEndDateTime
                    WHERE   tmp.wIsCharteredFlight = 'Y'
                            AND ( ( tmp.wBookingStatus = 'C'
                                    AND ISNULL(bh.wBookingStatus, 'P') != 'C'
                                  )
                                  OR ( tmp.wBookingStatus = 'RF'
                                       AND ISNULL(bh.wBookingStatus, 'P') != 'RF'
                                     )
                                );
                
                -- Check is already Mth end or not	
                    IF EXISTS ( SELECT  1
                                FROM    #sDataSet_SetBookingHeli tmp
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
                                                        wExpTypeCode = 'HP' ,
                                                        wExpTargetCode = '' ,
                                                        wExpCode = 'HP' ,
                                                        wExpSubCode1 = '' ,
                                                        wCurCode = tmp.wCurrCode ,
                                                        wRoomNo = '' ,
                                                        wRoomCfmCode = '' ,
                                                        wRoomBookDt = NULL ,
                                                        wRoomCheckInDt = NULL ,
                                                        wRoomDeptDt = NULL ,
                                                        wNight = 0 ,
                                                        wUnit = tmp.wQuantity ,
                                                        wPrice = CASE tmp.wBookingStatus
                                                                   WHEN 'RF' THEN -1
                                                                   ELSE 1
                                                                 END * tmp.wUnitAmt ,
                                                        wRoomExpAmt = 0 ,
                                                        wAmount = CASE WHEN tmp.wPaymentMethod IN ( 'DA', 'GC', 'ST-CASH', 'ST-AP', 'ST-BT', 'ST-CC' ) THEN 1
                                                                       ELSE 0
                                                                  END * CASE tmp.wBookingStatus
                                                                          WHEN 'RF' THEN -1
                                                                          ELSE 1
                                                                        END * tmp.wTotalAmt ,
                                                        wExpLocation = sc.wDefaultHotelCode ,
                                                        wVoucherNo = '' ,
                                                        wVoucherDt = tmp.wDate ,
                                                        wRemark = CONCAT(N'直昇機預訂: ', b.wRefNo) ,
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
                                               FROM     #sDataSet_SetBookingHeli tmp
                                                        LEFT JOIN dbo.eBookingHeli bh ON tmp.wBookingRid = bh.wBookingRid
                                                                                         AND bh.wStatus = 'A'
                                                        LEFT JOIN dbo.eBooking b ON tmp.wBookingRid = b.RowID
                                                        LEFT JOIN RollsMary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                                        LEFT JOIN RollsMary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                                        LEFT JOIN dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                                                        LEFT JOIN RollsMary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                                                           AND c.wCageCode = '001'
                                                                                           AND c.wStatus = 'A'
                                                        LEFT JOIN RollsMary.dbo.mUsr u ON tmp.wUpdBy = u.RowID
                                               WHERE    tmp.wIsCharteredFlight = 'Y'
                                                        AND ( ( tmp.wBookingStatus = 'C'
                                                                AND ISNULL(bh.wBookingStatus, 'P') != 'C'
                                                              )
                                                              OR ( tmp.wBookingStatus = 'RF'
                                                                   AND ISNULL(bh.wBookingStatus, 'P') != 'RF'
                                                                 )
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
/*
            IF @pActionType IN ('U') BEGIN
                -- Temp use for missing RowID case
                UPDATE tmp SET RowID = bf.RowID FROM #sDataSet_SetBookingHeli tmp INNER JOIN dbo.eBookingHeli bf ON tmp.wBookingRid = bf.wBookingRid WHERE tmp.RowID <= 0;

                IF @vNow >= @vDateUsingCRM
                -- Changed Status From CONFIRM TO REFUND, VOID expense tran
                SET @vXMLRefundExp = (
                    SELECT 
                        RowID = 0, wCompNo = sc.wRollexCompNo, wCageCodeIn = c.wCageCodeIn, wTranNo = '', wDate = tmp.wDate,
                        wCurDateTime = @vNow, wShift = tmp.wShift, wAgentCodeIn = b.wDebitAgentCodeIn, wCardCodeIn = '', wCustName = ISNULL(a.wCName, ''),
                        wShopName = '', wExpTypeCode = 'HP', wExpTargetCode = '', wExpCode = 'HP', wExpSubCode1 = '', wCurCode = tmp.wCurrCode,
                        wRoomNo = '', wRoomCfmCode = '', wRoomBookDt = NULL, wRoomCheckInDt = NULL, wRoomDeptDt = NULL, wNight = 0, wUnit = -1 * tmp.wQuantity,
                        wPrice = tmp.wUnitAmt, wRoomExpAmt = 0, wAmount = (-1 * tmp.wTotalAmt), wExpLocation = sc.wDefaultHotelCode, wVoucherNo = '', wVoucherDt = NULL,
                        wRemark = CONCAT(N'直昇機預訂編號: ', b.wRefNo, N' 退款'), 
                        wPeriodCodeIn = tmp.wPeriodCodeIn, wExpType = 'I', wExpGroup = 'CRM', wDeductType = 'DC', wPrtPage = 0, wPrtRow = 0,
                        wTotSetAmt = 0, wUpdBy = tmp.wUpdBy, wUpdDt = @vNow, wRefRid = tmp.wBookingRid, wReferId = tmp.wBookingRid, wExpSite = '',
                        wReferUpdBy = '', wEliteCodeIn = '', wSettleInstantTranNo = '', wIsAdj = 'N', wForeignTranRefNo = '',
                        wFxRateHKD = 1, wFxRateRMB = 1, 
                        wExpDesc = N'',
                        wExtUpdBy = ISNULL(u.wCName, ''), wInvoiceDateTime_CRM = b.wExpDt, wAmountActual_CRM = (-1 * tmp.wExpAmt), wCardNo_CRM = '', 
                        wAuthorizer_CRM = aAuth.wCName, wExpCategory = N'行', wGuid = '', wRequestAgentCodeIn = b.wReqAgentCodeIn,
                        wIsDeposit = 'N', wIsDepositDone = 'N', wProductCategory = '', wProductDetail = ''
                    FROM
                        #sDataSet_SetBookingHeli tmp
                    INNER JOIN
                        dbo.eBookingHeli bh ON tmp.RowID = bh.RowID
                    LEFT JOIN
                        dbo.eBooking b ON tmp.wBookingRid = b.RowID
                    LEFT JOIN
                        RollsMary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                    LEFT JOIN
                        RollsMary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                    LEFT JOIN
                        dbo.mServiceCounter sc ON b.wReqCounterRid = sc.RowID
                    LEFT JOIN
                        RollsMary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo AND c.wCageCode = '001' AND c.wStatus = 'A'
                    LEFT JOIN
                        RollsMary.dbo.mUsr u ON tmp.wUpdBy = u.RowID
                    WHERE
                        tmp.wBookingStatus = 'RF' AND bh.wBookingStatus = 'C' AND tmp.wPaymentMethod IN ('DA') AND wDebitDt >= @vDateUsingCRM
                    AND
                        tmp.wIsCharteredFlight = 'Y'
                    FOR XML RAW('Record'), ROOT ('DataSet')
                );

                IF @vXMLRefundExp != '' BEGIN
                    EXEC RollsMary.spa.SetExpTran 
                        @pXML = @vXMLRefundExp, -- xml
                        @pActionType = 'I', -- char(1)
                        @pMainCompNo = @pMainCompNo, -- int
                        @pNonceToken = @pNonceToken, -- varchar(64)
                        @pErrCode = @vErrCode OUTPUT, -- int
                        @pErrMsg = @vErrMsg OUTPUT -- nvarchar(200)
                    
                    IF @vErrCode != 0 BEGIN
                        SET @pErrMsg = @vErrMsg;
                        THROW 50001, @pErrMsg, 1;
                    END
                END
            END
*/
            ---------------------------------------------------------------------------------------------
            -- End Sync Expense
            ---------------------------------------------------------------------------------------------

            ---------------------------------------------------------------------------------------------
            -- Add eGift record
            ---------------------------------------------------------------------------------------------
            IF EXISTS ( SELECT  1
                        FROM #sDataSet_SetBookingHeli tmp
                        INNER JOIN dbo.eBookingHeli bh ON tmp.wBookingRid = bh.wBookingRid
                        WHERE ((tmp.wBookingStatus = 'C' AND ISNULL(bh.wBookingStatus, 'P') != 'C' )
                              OR (tmp.wBookingStatus = 'RF' AND ISNULL(bh.wBookingStatus, 'P') != 'RF')
                              OR (tmp.wBookingStatus = 'C' AND bh.wBookingStatus = 'C')
                              OR (tmp.wBookingStatus = 'RF' AND bh.wBookingStatus = 'RF'))
                           AND tmp.wIsCharteredFlight = 'Y' AND (tmp.wPaymentMethod = 'GC' OR tmp.wPaymentMethod = 'GC0') )
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
                                                tmp.wCurrCode AS wCurrCode,
                                                wAmount = CASE WHEN g.RowID IS NULL THEN (CASE tmp.wBookingStatus WHEN 'RF' THEN -1 ELSE 1 END) * tmp.wTotalAmt ELSE g.wAmount END,
                                                '02' AS wType , --送禮
                                                '0213' AS wSubType , --直升機票
                                                wRemark = CASE WHEN (g.RowID IS NULL OR tmp.wRemark != bh.wRemark) THEN tmp.wRemark ELSE g.wRemark END,
                                                b.wEventCodeRid AS wEventCodeRid ,
                                                wStatus = CASE WHEN g.RowID IS NULL THEN 'A' ELSE g.wStatus END,
                                                wCrtDt = CASE WHEN g.RowID IS NULL THEN @vNow ELSE g.wCrtDt END, -- set sp should not update this field when update
                                                wCrtBy = CASE WHEN g.RowID IS NULL THEN tmp.wUpdBy ELSE g.wCrtBy END, -- in set sp should not update this field when update
                                                @vNow AS wUpdDt ,
                                                tmp.wUpdBy ,
                                                CASE WHEN ((tmp.wBookingStatus = 'C' AND ISNULL(bh.wBookingStatus, 'P') != 'C')
                                                            OR (tmp.wBookingStatus = 'RF' AND ISNULL(bh.wBookingStatus, 'P') != 'RF'))
                                                          --AND ISNULL(g.wRefTableRid, 0) <= 0 
                                                THEN 'I'
                                                ELSE 'U'
                                                END AS RecordState ,
                                                b.wGiftReasonCd AS wReasonCd ,
                                                wIsReceived = CASE WHEN g.RowID IS NULL THEN 'Y' ELSE g.wIsReceived END ,-- 經由booking 產生的送禮記錄要預設為 "已接收"
                                                tmp.wCost
                                     FROM #sDataSet_SetBookingHeli tmp
                                     INNER JOIN dbo.eBookingHeli bh ON tmp.wBookingRid = bh.wBookingRid AND bh.wStatus = 'A' AND (tmp.wPaymentMethod = 'GC' OR tmp.wPaymentMethod = 'GC0')
                                     INNER JOIN dbo.eBooking b ON b.RowID = tmp.wBookingRid
                                     INNER JOIN dbo.mServiceCounter sc ON sc.RowID = b.wReqCounterRid
                                     LEFT JOIN eGift g ON g.wRefTableRid = tmp.wBookingRid AND g.wStatus = 'A' AND ((tmp.wBookingStatus = 'C' AND bh.wBookingStatus = 'C') OR (tmp.wBookingStatus = 'RF' AND bh.wBookingStatus = 'RF')) -- 只有Update才能Join到舊數據
                                     INNER JOIN RollsMary.dbo.mAgent a ON a.wAgentCodeIn = b.wApprovalAgentCodeIn AND a.wStatus = 'A'
                                     WHERE tmp.wIsCharteredFlight = 'Y'
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
                    UPDATE  #sDataSet_SetBookingHeli
                    SET     RowID = 0 ,
                            wSeqNo = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetBookingHeli;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
                    
                            IF @sSeqNo = 0
                                BEGIN
                                    SELECT  @sSeqNo = ISNULL(MAX(wSeqNo), 1)
                                    FROM    dbo.eBookingHeli; 
                                    SET @sSeqNo = @sSeqNo + 1;
                                END;
                            ELSE
                                BEGIN
                                    SET @sSeqNo = @sSeqNo + 1;
                                END;
                                 
                            IF @sTicketNo = 0
                                BEGIN
                                    SELECT  @sTicketNo = ISNULL(MAX(wTicketId), 1000000)
                                    FROM    dbo.eBookingHeli; 
                                    SET @sTicketNo = @sTicketNo + 1;	
                                END;
                            ELSE
                                SET @sTicketNo = @sTicketNo + 1;	

                            UPDATE  #sDataSet_SetBookingHeli
                            SET     RowID = @sRowID ,
                                    wBookingRid = @pBookingRid ,
                                    wSeqNo = @sSeqNo ,
                                    wTicketId = @sTicketNo
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
                        
                    SET @pTicketId = @sTicketNo;
                                        
                -- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[eBookingHeli]
                            ( RowID ,
                              wBookingRid ,
                              wTicketId ,
                              wOrderNo ,
                              wBookingLocation ,
                              wUseBlackCardFlag ,
                              wPaymentMethod ,
                              wReceiptNo ,
                              wRouteRid ,
                              wDepartDt ,
                              wUnitAmt ,
                              wQuantity ,
                              wExpAmt ,
                              wTotalAmt ,
                              wCost ,
                              wHandlingFee ,
                              wCurrCode ,
                              wAdditionalExp ,
                              wRemark ,
                              wStatus ,
                              wSeqNo ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy ,
                              wBookingStatus ,
                              wUnqualifiedRid ,
                              wIsCharteredFlight ,
                              wChangeOrderCount
                            )
                            SELECT  s.RowID ,
                                    s.wBookingRid ,
                                    s.wTicketId ,
                                    s.wOrderNo ,
                                    s.wBookingLocation ,
                                    s.wUseBlackCardFlag ,
                                    s.wPaymentMethod ,
                                    s.wReceiptNo ,
                                    s.wRouteRid ,
                                    s.wDepartDt ,
                                    s.wUnitAmt ,
                                    s.wQuantity ,
                                    s.wExpAmt ,
                                    s.wTotalAmt ,
                                    s.wCost ,
                                    s.wHandlingFee ,
                                    s.wCurrCode ,
                                    s.wAdditionalExp ,
                                    s.wRemark ,
                                    'A' ,
                                    s.wSeqNo ,
                                    s.wCrtDt ,
                                    s.wUpdBy ,
                                    s.wUpdDt ,
                                    s.wUpdBy ,
                                    s.wBookingStatus ,
                                    ISNULL(s.wUnqualifiedRid, 0) ,
                                    s.wIsCharteredFlight ,
                                    s.wChangeOrderCount
                            FROM    #sDataSet_SetBookingHeli s;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  bh
                        SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
                                bh.wRouteRid = tmp.wRouteRid ,
                                bh.wDepartDt = tmp.wDepartDt ,
                                bh.wAdditionalExp = tmp.wAdditionalExp ,
                                bh.wUnitAmt = tmp.wUnitAmt ,
                                bh.wQuantity = tmp.wQuantity ,
                                bh.wExpAmt = tmp.wExpAmt ,
                                bh.wTotalAmt = tmp.wTotalAmt ,
                                bh.wHandlingFee = tmp.wHandlingFee ,
                                bh.wRemark = tmp.wRemark ,
                                bh.wBookingStatus = tmp.wBookingStatus ,
                                bh.wUnqualifiedRid = ISNULL(tmp.wUnqualifiedRid, 0) ,
                                bh.wCost = tmp.wCost ,
                                bh.wPaymentMethod = tmp.wPaymentMethod ,
                                bh.wBookingLocation = tmp.wBookingLocation ,
                                bh.wUseBlackCardFlag = tmp.wUseBlackCardFlag ,
                                bh.wCurrCode = tmp.wCurrCode ,
                                bh.wOrderNo = tmp.wOrderNo ,
                                bh.wUpdBy = tmp.wUpdBy ,
                                bh.wUpdDt = @vNow ,
                                bh.wIsCharteredFlight = tmp.wIsCharteredFlight ,
                                bh.wChangeOrderCount = tmp.wChangeOrderCount ,
                                bh.wReceiptNo = tmp.wReceiptNo
                        FROM    dbo.eBookingHeli AS bh
                                INNER JOIN #sDataSet_SetBookingHeli tmp ON bh.wBookingRid = tmp.wBookingRid
                        WHERE   bh.wBookingRid = tmp.wBookingRid;	
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN	
                        
                            UPDATE  bh
                            SET     bh.wUpdBy = tmp.wUpdBy ,
                                    bh.wUpdDt = @vNow ,
                                    bh.wBookingStatus = 'DL' ,
                                    bh.wStatus = 'T'
                            FROM    dbo.eBookingHeli AS bh
                                    INNER JOIN #sDataSet_SetBookingHeli tmp ON bh.RowID = tmp.RowID;
                                                        
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
                                        FROM    #sDataSet_SetBookingHeli tmp
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
                FROM    #sDataSet_SetBookingHeli;
           
            RETURN;

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

        IF OBJECT_ID('tempdb..#sDataSet_SetBookingHeli') IS NOT NULL
            DROP TABLE #sDataSet_SetBookingHeli;
        IF OBJECT_ID('tempdb..#s_Period') IS NOT NULL
            DROP TABLE #s_Period;
    END;