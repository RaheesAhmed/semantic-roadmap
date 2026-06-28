CREATE PROCEDURE [spa].[SetBookingTour]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D  
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pBookingRid BIGINT ,
      @pBookingTourRid BIGINT OUT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT	
    )
AS
    BEGIN  

        SET NOCOUNT ON;   		
        DECLARE @sThisTableName VARCHAR(50) = 'eBookingTourGuide' ,-- For RowID  
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @vNow DATETIME2 = dbo.fnUTC8Now() ,
            @vMthEndYearMth VARCHAR(6) ,
            @vDateUsingCRM DATETIME2 ,
            @sActionAffectedXML NVARCHAR(MAX) = '' ,
            @sXMLeGift NVARCHAR(MAX) = '' ,
            @sCageCodeIn VARCHAR(14) ,
            @sDocHandle INT;  
              
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
        INTO    #sDataSet_SetBookingTourGuide
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)  
          WITH (  
                    RowID BIGINT,
                    wBookingRid BIGINT,
                    wRegion VARCHAR(10),
                    wTravelAgencyRid BIGINT,
                    wLang VARCHAR(3),
                    wOrderNo NVARCHAR(60),
                    wStartDt DATETIME2(7),
                    wEndtDt DATETIME2(7),
                    wPaymentMethod VARCHAR(30),
                    wPeriod NVARCHAR(50),
                    wExpenseAmt NUMERIC(18,4),
                    wTotalAmt NUMERIC(18,4),
                    wCost NUMERIC(18,4),
                    wAdditionalExp NUMERIC(18,4),
                    wCurrCode VARCHAR(6),
                    wRemark NVARCHAR(500),
                    wStatus CHAR(1),
                    wBookingStatus VARCHAR(5),
                    wUnqualifiedRid BIGINT,
                    wReceiptNo NVARCHAR(50),
                    wSeqNo INT,
                    wUpdBy BIGINT ,
                    wUpdDt DATETIME2(7),
                    wIsUseBlackCard CHAR(1),
                    wOldBookingStatus VARCHAR(5)
               );  
        UPDATE  #sDataSet_SetBookingTourGuide
        SET     wBookingRid = @pBookingRid
        WHERE   wBookingRid <= 0;
/*

            --- TourGuide Required Field Validation Start
            DECLARE @errorMsg varchar(max);	
            IF  @pActionType IN ('I', 'U') BEGIN
                 select  @errorMsg = case 
                                  when RTRIM(ISNULL(ebt.wOrderNo,'')) = '' then 'Order No is Missing' 
                                  when RTRIM(ISNULL(ebt.wRegion,'')) = '' then 'Region No is Missing' 
                                  when ebt.wTravelAgencyRid <= 0 then 'Supplier is Missing'
                                  when RTRIM(ISNULL(ebt.wCurrCode,'')) = '' then 'Currency is Missing'
                                  when RTRIM(ISNULL(ebt.wPaymentMethod,'')) = '' then 'Payment Method is missing'	
                                  when RTRIM(ISNULL(ebt.wBookingStatus,'')) = '' then 'Status is missing'	
                                  when ebt.wTotalAmt<0 then 'Total amount is missing'					 
                                  when ebt.wCost<0 then 'Cost is missing'								  					 
                            end
                from #sDataSet_SetBookingTourGuide ebt
            END
            IF @errorMsg <> ''
                throw 50001, @errorMsg, 1;
            --- TourGuide Required Field Validation end

            --- TourGuide Status Management update Field Validation Start
            IF @pActionType = 'U' BEGIN
                select @errorMsg = case 
                                  when eb.wCurrCode<>sb.wCurrCode then 'Can not be updated Currency when booking status is ' +lup.wTitle 
                                  when eb.wTotalAmt<>sb.wTotalAmt and eb.wBookingStatus IN ('CL','UQ','RF') then 'Can not be updated Total Amount when booking status is '+lup.wTitle  
                                  when eb.wExpenseAmt<>sb.wExpenseAmt and eb.wBookingStatus IN ('CL','UQ','RF') then 'Can not be updated Expense Amount when booking status is '+lup.wTitle 								  
                                  when eb.wCost<>sb.wCost and eb.wBookingStatus IN ('CL','UQ','RF') then 'Can not be updated Cost when booking status is ' +lup.wTitle    
                                  when eb.wPaymentMethod<>sb.wPaymentMethod and eb.wBookingStatus IN ('C','CL','UQ','RF')  then 'Can not be updated PaymentMethod when booking status is '+lup.wTitle  
                                  When eb.wBookingStatus in ('RF','CL','UQ') AND  eb.wBookingStatus <> sb.wBookingStatus then lup.wTitle + ' status can not be changed to status Code' + sb.wBookingStatus
                                  When eb.wBookingStatus in ('C') AND  sb.wBookingStatus in ('P','CL','UQ') then lup.wTitle + ' status can not be changed to status Code ' + sb.wBookingStatus
                                  When eb.wBookingStatus in ('P') AND  sb.wBookingStatus in ('RF','CO') then lup.wTitle + ' status can not be changed to status Code ' + sb.wBookingStatus								  
                            end
                from eBookingTourGuide eb inner join
                #sDataSet_SetBookingTourGuide sb on eb.wBookingRid=sb.wBookingRid 
                INNER JOIN mLookUp lup On lup.wCode = eb.wBookingStatus AND lup.wType = 'TOUR_GUIDE_STATUS' and lup.wlangCd='en-GB'			
            END

            ELSE IF @pActionType = 'D' BEGIN
                select  @errorMsg = case  When eb.wBookingStatus <> ('P') then 'Booking can not be deleted if Status Code is '+eb.wBookingStatus end
                from eBookingTourGuide eb inner join
                #sDataSet_SetBookingTourGuide sb on eb.wBookingRid=sb.wBookingRid			   
            END

        IF @errorMsg <> ''
            throw 50001, @errorMsg, 1;
*/
      --better don't put everything within try, for example  
      --getting mSysTable value  
      --getting currency, period, mCompany ...  
               
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
                DECLARE @sBookingType VARCHAR(30) = 'TOUR';
                DECLARE @sCurrentBookingStatus VARCHAR(5); -- DB当前状态
                DECLARE @sOldBookingStatus VARCHAR(5); -- 上一次Get數據時的狀態
                DECLARE @sNewBookingStatus VARCHAR(5); -- Save订单新状态
                DECLARE @sLangCd VARCHAR(10) = 'zh-TW';
                SELECT
                    @sCurrentBookingStatus = ebtg.wBookingStatus, 
                    @sOldBookingStatus = sbtg.wOldBookingStatus,
                    @sNewBookingStatus = sbtg.wBookingStatus
                FROM dbo.eBookingTourGuide AS ebtg 
                INNER JOIN #sDataSet_SetBookingTourGuide AS sbtg ON sbtg.RowID = ebtg.RowID AND sbtg.wBookingRid = ebtg.wBookingRid
                WHERE ebtg.wBookingRid = @pBookingRId;

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

                    ALTER TABLE #sDataSet_SetBookingTourGuide ADD 
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
                        FROM #sDataSet_SetBookingTourGuide tmp 
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
                    FROM    #sDataSet_SetBookingTourGuide tmp
                            LEFT JOIN dbo.eBookingTourGuide btg ON tmp.wBookingRid = btg.wBookingRid
                                                                   AND btg.wStatus = 'A'
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
                    WHERE   ( tmp.wBookingStatus = 'C'
                              AND ISNULL(btg.wBookingStatus, 'P') != 'C'
                            )
                            OR ( tmp.wBookingStatus = 'RF'
                                 AND ISNULL(btg.wBookingStatus, 'P') != 'RF'
                               );
                
                -- Check is already Mth end or not	
                    IF EXISTS ( SELECT  1
                                FROM    #sDataSet_SetBookingTourGuide tmp
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
                                                                 END * CASE WHEN ISNULL(tmp.wPaymentMethod, '') IN ( 'DA', 'GC', 'ST-CASH', 'ST-AP', 'ST-BT', 'ST-CC' ) THEN tmp.wExpenseAmt
                                                                            ELSE 0
                                                                       END ,
                                                        wRoomExpAmt = 0 ,
                                                        wAmount = CASE tmp.wBookingStatus
                                                                    WHEN 'RF' THEN -1
                                                                    ELSE 1
                                                                  END * CASE WHEN ISNULL(tmp.wPaymentMethod, '') IN ( 'DA', 'GC', 'ST-CASH', 'ST-AP', 'ST-BT', 'ST-CC' ) THEN tmp.wExpenseAmt
                                                                             ELSE 0
                                                                        END ,
                                                        wExpLocation = sc.wDefaultHotelCode ,
                                                        wVoucherNo = '' ,
                                                        wVoucherDt = tmp.wDate ,
                                                        wRemark = CONCAT(N'導遊預訂: ', b.wRefNo, CASE tmp.wBookingStatus
                                                                                                WHEN 'RF' THEN N'退款'
                                                                                                ELSE N''
                                                                                              END) ,
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
                                                        wExpCategory = N'TRAVEL' ,
                                                        wGuid = '' ,
                                                        wRequestAgentCodeIn = b.wReqAgentCodeIn ,
                                                        wIsDeposit = 'N' ,
                                                        wIsDepositDone = 'N' ,
                                                        wProductCategory = '' ,
                                                        wProductDetail = '',
                                                        wBookingRid = tmp.wBookingRid,
                                                        wBookingStatus = tmp.wBookingStatus
                                               FROM     #sDataSet_SetBookingTourGuide tmp
                                                        LEFT JOIN dbo.eBookingTourGuide btg ON tmp.wBookingRid = btg.wBookingRid
                                                                                               AND btg.wStatus = 'A'
                                                        INNER JOIN dbo.eBooking b ON tmp.wBookingRid = b.RowID
                                                        INNER JOIN RollsMary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                                        LEFT JOIN RollsMary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                                        INNER JOIN dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                                                        LEFT JOIN RollsMary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                                                           AND c.wCageCode = '001'
                                                                                           AND c.wStatus = 'A'
                                                        LEFT JOIN RollsMary.dbo.mUsr u ON tmp.wUpdBy = u.RowID
                                               WHERE    ( tmp.wBookingStatus = 'C'
                                                          AND ISNULL(btg.wBookingStatus, 'P') != 'C'
                                                        )
                                                        OR ( tmp.wBookingStatus = 'RF'
                                                             AND ISNULL(btg.wBookingStatus, 'P') != 'RF'
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
            IF EXISTS ( SELECT 1
                        FROM #sDataSet_SetBookingTourGuide tmp
                        INNER JOIN dbo.eBookingTourGuide btg ON tmp.wBookingRid = btg.wBookingRid
                        WHERE ((tmp.wBookingStatus = 'C' AND ISNULL(btg.wBookingStatus, 'P') != 'C')
                              OR (tmp.wBookingStatus = 'RF' AND ISNULL(btg.wBookingStatus, 'P') != 'RF')
                              OR (tmp.wBookingStatus = 'C' AND btg.wBookingStatus = 'C')
                              OR (tmp.wBookingStatus = 'RF' AND btg.wBookingStatus = 'RF'))
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
                                                tmp.wCurrCode AS wCurrCode,
                                                 wAmount = CASE WHEN g.RowID IS NULL THEN (CASE tmp.wBookingStatus WHEN 'RF' THEN -1 ELSE 1 END) * tmp.wTotalAmt ELSE g.wAmount END,
                                                '02' AS wType , --送禮
                                                '0236' AS wSubType , --導遊服務
                                                wRemark = CASE WHEN (g.RowID IS NULL OR tmp.wRemark != btg.wRemark) THEN tmp.wRemark ELSE g.wRemark END,
                                                b.wEventCodeRid AS wEventCodeRid ,
                                                wStatus = CASE WHEN g.RowID IS NULL THEN 'A' ELSE g.wStatus END,
                                                wCrtDt = CASE WHEN g.RowID IS NULL THEN @vNow ELSE g.wCrtDt END, -- set sp should not update this field when update
                                                wCrtBy = CASE WHEN g.RowID IS NULL THEN tmp.wUpdBy ELSE g.wCrtBy END, -- in set sp should not update this field when update
                                                @vNow AS wUpdDt ,
                                                tmp.wUpdBy ,
                                                CASE WHEN ((tmp.wBookingStatus = 'C' AND ISNULL(btg.wBookingStatus, 'P') != 'C')
                                                            OR (tmp.wBookingStatus = 'RF' AND ISNULL(btg.wBookingStatus, 'P') != 'RF'))
                                                          --AND ISNULL(g.wRefTableRid, 0) <= 0 
                                                THEN 'I'
                                                ELSE 'U'
                                                END AS RecordState ,
                                                b.wGiftReasonCd AS wReasonCd ,
                                                wIsReceived = CASE WHEN g.RowID IS NULL THEN 'Y' ELSE g.wIsReceived END ,-- 經由booking 產生的送禮記錄要預設為 "已接收"
                                                tmp.wCost
                                     FROM #sDataSet_SetBookingTourGuide tmp
                                     INNER JOIN dbo.eBookingTourGuide btg ON tmp.wBookingRid = btg.wBookingRid AND btg.wStatus = 'A' AND (tmp.wPaymentMethod = 'GC' OR tmp.wPaymentMethod = 'GC0')
                                     INNER JOIN dbo.eBooking b ON b.RowID = tmp.wBookingRid
                                     INNER JOIN dbo.mServiceCounter sc ON sc.RowID = b.wReqCounterRid
                                     LEFT JOIN eGift g ON g.wRefTableRid = tmp.wBookingRid AND g.wStatus = 'A' AND ((tmp.wBookingStatus = 'C' AND btg.wBookingStatus = 'C') OR (tmp.wBookingStatus = 'RF' AND btg.wBookingStatus = 'RF')) -- 只有Update才能Join到舊數據
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
                    UPDATE  #sDataSet_SetBookingTourGuide
                    SET     RowID = 0;  
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetBookingTourGuide;  
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN  
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;  
       
                            UPDATE  #sDataSet_SetBookingTourGuide
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;  
                            SET @sRuningIndex = @sRuningIndex + 1;  
                        END;                
               
                    SET @pBookingTourRid = @sRowID;    

                -- MAIN Logic here, example here is inserting dataset to eIOUPenalty  
                    INSERT  INTO [dbo].[eBookingTourGuide]
                            ( RowID ,
                              wBookingRid ,
                              wRegion ,
                              wTravelAgencyRid ,
                              wLang ,
                              wOrderNo ,
                              wStartDt ,
                              wEndtDt ,
                              wPaymentMethod ,
                              wPeriod ,
                              wExpenseAmt ,
                              wTotalAmt ,
                              wCost ,
                              wAdditionalExp ,
                              wCurrCode ,
                              wRemark ,
                              wStatus ,
                              wBookingStatus ,
                              wUnqualifiedRid ,
                              wReceiptNo ,
                              wSeqNo ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdBy ,
                              wUpdDt ,
                              wIsUseBlackCard
                             )
                            SELECT  @pBookingTourRid ,
                                    @pBookingRid ,
                                    bt.wRegion ,
                                    bt.wTravelAgencyRid ,
                                    bt.wLang ,
                                    bt.wOrderNo ,
                                    bt.wStartDt ,
                                    bt.wEndtDt ,
                                    bt.wPaymentMethod ,
                                    bt.wPeriod ,
                                    bt.wExpenseAmt ,
                                    bt.wTotalAmt ,
                                    bt.wCost ,
                                    bt.wAdditionalExp ,
                                    bt.wCurrCode ,
                                    bt.wRemark ,
                                    bt.wStatus ,
                                    bt.wBookingStatus ,
                                    ISNULL(bt.wUnqualifiedRid, 0) ,
                                    bt.wReceiptNo ,
                                    bt.wSeqNo ,
                                    bt.wUpdDt ,
                                    bt.wUpdBy ,
                                    bt.wUpdBy ,
                                    bt.wUpdDt ,
                                    bt.wIsUseBlackCard
                            FROM    #sDataSet_SetBookingTourGuide bt;  
                END;  
 
            ELSE
                IF @pActionType = 'U'
                    BEGIN  
                        UPDATE  bls
                        SET     bls.wRegion = tmp.wRegion ,
                                bls.wTravelAgencyRid = tmp.wTravelAgencyRid ,
                                bls.wOrderNo = tmp.wOrderNo ,
                                bls.wLang = tmp.wLang ,
                                bls.wStartDt = tmp.wStartDt ,
                                bls.wEndtDt = tmp.wEndtDt ,
                                bls.wPaymentMethod = tmp.wPaymentMethod ,
                                bls.wPeriod = tmp.wPeriod ,
                                bls.wExpenseAmt = tmp.wExpenseAmt ,
                                bls.wTotalAmt = tmp.wTotalAmt ,
                                bls.wCost = tmp.wCost ,
                                bls.wAdditionalExp = tmp.wAdditionalExp ,
                                bls.wCurrCode = tmp.wCurrCode ,
                                bls.wReceiptNo = tmp.wReceiptNo ,
                                bls.wRemark = tmp.wRemark ,
                                bls.wBookingStatus = tmp.wBookingStatus ,
                                bls.wUnqualifiedRid = ISNULL(tmp.wUnqualifiedRid, 0) ,
                                bls.wUpdBy = tmp.wUpdBy ,
                                bls.wUpdDt = tmp.wUpdDt ,
                                bls.wIsUseBlackCard = tmp.wIsUseBlackCard
                        FROM    dbo.eBookingTourGuide AS bls
                                INNER JOIN #sDataSet_SetBookingTourGuide tmp ON bls.RowID = tmp.RowID
                        WHERE   bls.RowID = tmp.RowID;  
                    END;  

                ELSE
                    IF @pActionType = 'D'
                        BEGIN									  
                            UPDATE  ebl
                            SET     ebl.wBookingStatus = 'DL' ,
                                    ebl.wStatus = 'T' ,
                                    ebl.wUpdDt = dbo.fnUTC8Now() ,
                                    ebl.wUpdBy = tmp.wUpdBy
                            FROM    dbo.eBookingTourGuide AS ebl
                                    INNER JOIN #sDataSet_SetBookingTourGuide tmp ON ebl.RowID = tmp.RowID;                          
                            DECLARE @BookingRid BIGINT = ( SELECT TOP 1
                                                                    wBookingRid
                                                           FROM     #sDataSet_SetBookingTourGuide
                                                         );

                            UPDATE  ePassengerDetails
                            SET     wPassengerBookingStatus = 'T' ,
                                    wStatus = 'T'
                            WHERE   wBookingRid = @BookingRid
                                    AND wPassengerBookingStatus = 'A';
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
                                        FROM    #sDataSet_SetBookingTourGuide tmp
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
                FROM    #sDataSet_SetBookingTourGuide;

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
        
        IF OBJECT_ID('tempdb..#sDataSet_SetBookingTourGuide') IS NOT NULL
            DROP TABLE #sDataSet_SetBookingTourGuide;
        IF OBJECT_ID('tempdb..#s_Period') IS NOT NULL
            DROP TABLE #s_Period;
    END;