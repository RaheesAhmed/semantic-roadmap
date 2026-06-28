CREATE PROCEDURE [spa].[SetBookingVisa]
    (
      @pXML XML ,
      @pActionType CHAR(1) ,  -- I/U/D        
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pBookingRid BIGINT ,
      @pVisaInfoId BIGINT = 0 OUTPUT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT   
    )
AS
    BEGIN                        
        SET NOCOUNT ON;                        

        DECLARE @sThisTableName VARCHAR(50)   = 'eBookingVisa' , -- For RowID                        
            @sBeginTranCount INT           = 0 ,
            @sRecCount INT           = 0 ,
            @sRuningIndex INT           = 1 ,
            @sRowID BIGINT        = 0 ,
            @vNow DATETIME2     = dbo.fnUTC8Now() ,
            @sActionAffectedXML NVARCHAR(MAX) = '' ,
            @sXMLeGift NVARCHAR(MAX) = '' ,
            @sCageCodeIn VARCHAR(14) ,
            @vMthEndYearMth VARCHAR(6) ,
            @vDateUsingCRM DATETIME2 ,
            @sDocHandle INT ,
            @sSeqNo INT           = 0;                 
                              
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
                                                    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowId ) ,
                *
        INTO    #sDataSet_SetBookingVisa
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
        WITH (                        
            RowId BIGINT,        
            wBookingRid BIGINT,  
            wOrderNo NVARCHAR(50),      
            wApplyDt DATETIME2,
            wPlaceOfIssue VARCHAR(6),
            wCurrCode VARCHAR(6),
            wPaymentMethod VARCHAR(30),
            wExpAmt DECIMAL(18,4),
            wTotalAmt DECIMAL(18,4),
            wBookingStatus VARCHAR(5),
            wUnqualifiedRid BIGINT,        
            wCrtDt DATETIME2,        
            wCrtBy BIGINT,        
            wUpdDt DATETIME2,        
            wUpdBy BIGINT,
            wReceiptNo NVARCHAR(50),
            wTravelAgencyRid BIGINT,
            wQuantity INT,
            --wUnitPrice NUMERIC(18,4),
            wCost NUMERIC(18,4),
            wAdditionalExp NUMERIC(18,4),
            wRemark NVARCHAR(500),
            wUseBlackCard CHAR(1),
            wReasonCd VARCHAR(30),
            wIsReceived CHAR(1),
            wOldBookingStatus VARCHAR(5)
        );                        
        -- Aloha bad method, say need to update here
        UPDATE  #sDataSet_SetBookingVisa
        SET     wBookingRid = @pBookingRid
        WHERE   wBookingRid <= 0;
/*
    --- Visa Application Required Field Validation Start
    DECLARE @errorMsg varchar(max);	
    IF  @pActionType IN ('I', 'U') BEGIN
            select  @errorMsg = case 
                            when RTRIM(ISNULL(ebh.wOrderNo,'')) = '' then 'Order No is Missing' 						
                            when RTRIM(ISNULL(ebh.wPaymentMethod,'')) = '' then 'Payment Method is missing'	
                            when RTRIM(ISNULL(ebh.wBookingStatus,'')) = '' then 'Booking Status is missing'	
                            when ebh.wTravelAgencyRid <= 0 then 'Supplier is missing'										  					 
                    end
        from #sDataSet_SetBookingVisa ebh
    END
    IF @errorMsg <> ''
        throw 50001, @errorMsg, 1;
    --- Visa Application Required Field Validation end


     --  Visa Application Status Management update Field Validation Start
         IF  @pActionType = 'U' BEGIN
             select  @errorMsg = case 								 
                                  when eb.wPaymentMethod<>sb.wPaymentMethod and eb.wBookingStatus IN ('C','CL','UQ','CO','RF')  then 'Can not be updated PaymentMethod when booking status is '+lup.wTitle  								 
                                  when eb.wTotalAmt<>sb.wTotalAmt and eb.wBookingStatus IN ('C','CL','UQ','CO','RF')  then 'Can not be updated total amount when booking status is '+lup.wTitle  								 
                                  when eb.wExpAmt<>sb.wExpAmt and eb.wBookingStatus IN ('C','CL','UQ','CO','RF')  then 'Can not be updated expense amount when booking status is '+lup.wTitle  								 
                                  when eb.wQuantity<>sb.wQuantity and eb.wBookingStatus IN ('C','CL','UQ','CO','RF')  then 'Can not be updated quantity when booking status is '+lup.wTitle  								 
                                  when eb.wCost<>sb.wCost and eb.wBookingStatus IN ('C','CL','UQ','CO','RF')  then 'Can not be updated cost when booking status is '+lup.wTitle  								 
                                  when eb.wAdditionalExp<>sb.wAdditionalExp and eb.wBookingStatus IN ('C','CL','UQ','CO','RF')  then 'Can not be updated additional expense amount when booking status is '+lup.wTitle  								 
                                  When eb.wBookingStatus in ('RF','CL','UQ') AND  eb.wBookingStatus <> sb.wBookingStatus then lup.wTitle + ' status can not be changed to status code ' + sb.wBookingStatus
                                  When eb.wBookingStatus in ('C') AND  sb.wBookingStatus in ('P','CL','UQ') then lup.wTitle + ' status can not be changed to status code ' + sb.wBookingStatus
                                  When eb.wBookingStatus in ('P') AND  sb.wBookingStatus in ('RF','CO') then lup.wTitle + ' status can not be changed to status code ' + sb.wBookingStatus								  
                            end
            from eBookingVisa eb inner join
               #sDataSet_SetBookingVisa sb on eb.wBookingRid=sb.wBookingRid 
               INNER JOIN mLookUp lup On lup.wCode = eb.wBookingStatus AND lup.wType = 'VISA_APPLICATION_STATUS' and lup.wlangCd='en-GB'			
        END
        ELSE IF @pActionType = 'D' BEGIN
            select  @errorMsg = case 								  
                                  When sb.wBookingStatus <> ('P') then 'Booking can not be deleted if it not "In-Progress"' 
                            end
            from eBookingHeli eb inner join
               #sDataSet_SetBookingVisa sb on eb.wBookingRid=sb.wBookingRid			   
        END

        IF @errorMsg <> ''
                throw 50001, @errorMsg, 1;
        --  Visa Application Status Management update Field Validation end
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
                DECLARE @sBookingType VARCHAR(30) = 'Visa';
                DECLARE @sCurrentBookingStatus VARCHAR(5); -- DB当前状态
                DECLARE @sOldBookingStatus VARCHAR(5); -- 上一次Get數據時的狀態
                DECLARE @sNewBookingStatus VARCHAR(5); -- Save订单新状态
                DECLARE @sLangCd VARCHAR(10) = 'zh-TW';
                SELECT
                    @sCurrentBookingStatus = ebv.wBookingStatus, 
                    @sOldBookingStatus = sbv.wOldBookingStatus,
                    @sNewBookingStatus = sbv.wBookingStatus
                FROM dbo.eBookingVisa AS ebv 
                INNER JOIN #sDataSet_SetBookingVisa AS sbv ON sbv.RowID = ebv.RowID AND sbv.wBookingRid = ebv.wBookingRid
                WHERE ebv.wBookingRid = @pBookingRid;

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

                    ALTER TABLE #sDataSet_SetBookingVisa ADD 
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
                        FROM #sDataSet_SetBookingVisa tmp 
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
                    FROM    #sDataSet_SetBookingVisa tmp
                            LEFT JOIN dbo.eBookingVisa bf ON tmp.wBookingRid = bf.wBookingRid
                                                             AND bf.wStatus = 'A'
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
                            AND ISNULL(bf.wBookingStatus, 'P') != 'C'
                            OR tmp.wBookingStatus = 'RF'
                            AND ISNULL(bf.wBookingStatus, 'P') != 'RF';
                
                -- Check is already Mth end or not	
                    IF EXISTS ( SELECT  1
                                FROM    #sDataSet_SetBookingVisa tmp
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
                                                        wExpLocation = sc.wDefaultHotelCode ,
                                                        wVoucherNo = '' ,
                                                        wVoucherDt = tmp.wDate ,
                                                        wRemark = CONCAT(N'簽証預訂: ', b.wRefNo, CASE tmp.wBookingStatus
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
                                                        wExpCategory = 'TRAVEL' ,
                                                        wGuid = '' ,
                                                        wRequestAgentCodeIn = b.wReqAgentCodeIn ,
                                                        wIsDeposit = 'N' ,
                                                        wIsDepositDone = 'N' ,
                                                        wProductCategory = '' ,
                                                        wProductDetail = '',
                                                        wBookingRid = tmp.wBookingRid,
                                                        wBookingStatus = tmp.wBookingStatus
                                               FROM     #sDataSet_SetBookingVisa tmp
                                                        LEFT JOIN dbo.eBookingVisa bh ON tmp.wBookingRid = bh.wBookingRid
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
            IF EXISTS ( SELECT 1
                        FROM #sDataSet_SetBookingVisa tmp
                        INNER JOIN dbo.eBookingVisa bv ON tmp.wBookingRid = bv.wBookingRid
                        WHERE ((tmp.wBookingStatus = 'C' AND ISNULL(bv.wBookingStatus, 'P') != 'C')
                               OR (tmp.wBookingStatus = 'RF' AND ISNULL(bv.wBookingStatus, 'P') != 'RF')
                               OR (tmp.wBookingStatus = 'C' AND bv.wBookingStatus = 'C')
                               OR (tmp.wBookingStatus = 'RF' AND bv.wBookingStatus = 'RF'))
                           AND (tmp.wPaymentMethod = 'GC' OR tmp.wPaymentMethod = 'GC0') )
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
                                                '0239' AS wSubType , --簽證服務
                                                wRemark = CASE WHEN (g.RowID IS NULL OR tmp.wRemark != bv.wRemark) THEN tmp.wRemark ELSE g.wRemark END,
                                                b.wEventCodeRid AS wEventCodeRid ,
                                                wStatus = CASE WHEN g.RowID IS NULL THEN 'A' ELSE g.wStatus END,
                                                wCrtDt = CASE WHEN g.RowID IS NULL THEN @vNow ELSE g.wCrtDt END, -- set sp should not update this field when update
                                                wCrtBy = CASE WHEN g.RowID IS NULL THEN tmp.wUpdBy ELSE g.wCrtBy END, -- in set sp should not update this field when update
                                                @vNow AS wUpdDt ,
                                                tmp.wUpdBy ,
                                                CASE WHEN ((tmp.wBookingStatus = 'C' AND ISNULL(bv.wBookingStatus, 'P') != 'C')
                                                           OR (tmp.wBookingStatus = 'RF' AND ISNULL(bv.wBookingStatus, 'P') != 'RF'))
                                                          --AND ISNULL(g.wRefTableRid, 0) <= 0 
                                                THEN 'I'
                                                ELSE 'U'
                                                END AS RecordState ,
                                                b.wGiftReasonCd AS wReasonCd ,
                                                wIsReceived = CASE WHEN g.RowID IS NULL THEN 'Y' ELSE g.wIsReceived END, -- 經由booking 產生的送禮記錄要預設為 "已接收"
                                                tmp.wCost
                                     FROM #sDataSet_SetBookingVisa tmp
                                     INNER JOIN dbo.eBookingVisa bv ON tmp.wBookingRid = bv.wBookingRid AND bv.wStatus = 'A' AND (tmp.wPaymentMethod = 'GC' OR tmp.wPaymentMethod = 'GC0')
                                     INNER JOIN dbo.eBooking b ON b.RowID = tmp.wBookingRid
                                     INNER JOIN dbo.mServiceCounter sc ON sc.RowID = b.wReqCounterRid
                                     LEFT JOIN eGift g ON g.wRefTableRid = tmp.wBookingRid AND g.wStatus = 'A' AND ((tmp.wBookingStatus = 'C' AND bv.wBookingStatus = 'C') OR (tmp.wBookingStatus = 'RF' AND bv.wBookingStatus = 'RF')) -- 只有Update才能Join到舊數據
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
                    UPDATE  #sDataSet_SetBookingVisa
                    SET     RowId = 0;                        
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetBookingVisa;                        
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN                        
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;                              
                            UPDATE  #sDataSet_SetBookingVisa
                            SET     RowId = @sRowID ,
                                    wBookingRid = @pBookingRid
                            WHERE   wRowNum = @sRuningIndex;                        
                            SET @sRuningIndex = @sRuningIndex + 1;                        
                        END;                                      
           
                    SET @pVisaInfoId = @sRowID;  

                    INSERT  INTO dbo.[eBookingVisa]
                            ( RowId ,
                              wBookingRid ,
                              wOrderNo ,
                              wApplyDt ,
                              wPlaceOfIssue ,
                              wCurrCode ,
                              wPaymentMethod ,
                              wExpAmt ,
                              wTotalAmt ,
                              wBookingStatus ,
                              wUnqualifiedRid ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy ,
                              wReceiptNo ,
                              wTravelAgencyRid ,
                              wQuantity ,
        --wUnitPrice,
                              wCost ,
                              wAdditionalExp ,
                              wRemark ,
                              wUseBlackCard
                            )
                            SELECT  s.RowId ,
                                    s.wBookingRid ,
                                    s.wOrderNo ,
                                    s.wApplyDt ,
                                    s.wPlaceOfIssue ,
                                    s.wCurrCode ,
                                    s.wPaymentMethod ,
                                    s.wExpAmt ,
                                    s.wTotalAmt ,
                                    s.wBookingStatus ,
                                    ISNULL(s.wUnqualifiedRid, 0) ,
                                    dbo.fnUTC8Now() ,
                                    s.wCrtBy ,
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy ,
                                    s.wReceiptNo ,
                                    s.wTravelAgencyRid ,
                                    s.wQuantity ,
        --s.wUnitPrice,
                                    s.wCost ,
                                    s.wAdditionalExp ,
                                    s.wRemark ,
                                    s.wUseBlackCard
                            FROM    #sDataSet_SetBookingVisa s;     
                    SELECT  *
                    FROM    dbo.[eBookingVisa];                      
                END;                     
    -------------------------------------------------------                  
            ELSE
                IF @pActionType = 'U'
                    BEGIN 
                  
                        UPDATE  bv
                        SET     bv.wOrderNo = tmp.wOrderNo ,
                                bv.wApplyDt = tmp.wApplyDt ,
                                bv.wPlaceOfIssue = tmp.wPlaceOfIssue ,
                                bv.wCurrCode = tmp.wCurrCode ,
                                bv.wPaymentMethod = tmp.wPaymentMethod ,
                                bv.wExpAmt = tmp.wExpAmt ,
                                bv.wTotalAmt = tmp.wTotalAmt ,
                                bv.[wBookingStatus] = tmp.wBookingStatus ,
                                bv.[wUnqualifiedRid] = ISNULL(tmp.wUnqualifiedRid, 0) ,
                                bv.[wUpdBy] = tmp.wUpdBy ,
                                bv.[wUpdDt] = dbo.fnUTC8Now() ,
                                bv.[wReceiptNo] = tmp.wReceiptNo ,
                                bv.[wTravelAgencyRid] = tmp.wTravelAgencyRid ,
                                bv.[wQuantity] = tmp.wQuantity ,
        --bv.[wUnitPrice]=tmp.wUnitPrice,
                                bv.[wCost] = tmp.wCost ,
                                bv.[wAdditionalExp] = tmp.wAdditionalExp ,
                                bv.[wRemark] = tmp.wRemark ,
                                bv.[wUseBlackCard] = tmp.wUseBlackCard ,
                                @pVisaInfoId = tmp.RowId
                        FROM    dbo.[eBookingVisa] AS bv
                                INNER JOIN #sDataSet_SetBookingVisa tmp ON bv.RowId = tmp.RowId
                        WHERE   bv.RowId = tmp.RowId;                    
                            
                    END;                    
                ELSE
                    IF @pActionType = 'D'
                        BEGIN 
            
                            DECLARE @BookingRid BIGINT = ( SELECT TOP 1
                                                                    wBookingRid
                                                           FROM     #sDataSet_SetBookingVisa
                                                         );
            --UPDATE PSD
            --SET PSD.wPassengerBookingStatus= (CASE WHEN (PSD.wPassengerBookingStatus='C' OR PSD.wPassengerBookingStatus='RF') THEN 'RF'
            --											  WHEN (PSD.wPassengerBookingStatus='P' OR PSD.wPassengerBookingStatus='UQ') THEN 'CL'
            --											  ELSE 'CL'
            --											  END),					
            --	PSD.wUpdDt=dbo.fnUTC8Now(),
            --	PSD.wUpdBy=tmp.wUpdBy
            --FROM dbo.ePassengerDetails PSD
            --INNER JOIN #sDataSet_SetBookingVisa tmp ON PSD.wBookingRid = tmp.wBookingRid AND PSD.wStatus='A' AND PSD.wPassengerBookingStatus IN ('P','C');
                                        
                            UPDATE  ePassengerDetails
                            SET     wPassengerBookingStatus = 'DL' ,
                                    wStatus = 'T'
                            WHERE   wBookingRid = @BookingRid
                                    AND wPassengerBookingStatus = 'P';	
                            UPDATE  bv
                            SET     bv.wTotalAmt = 0 ,
                                    bv.wCost = 0 ,
                                    bv.wQuantity = 0 ,
                                    bv.[wBookingStatus] = 'DL' ,
                                    bv.wStatus = 'T' ,
                                    bv.[wUpdBy] = tmp.wUpdBy ,
                                    bv.[wUpdDt] = dbo.fnUTC8Now()
                            FROM    dbo.[eBookingVisa] AS bv
                                    INNER JOIN #sDataSet_SetBookingVisa tmp ON bv.RowId = tmp.RowId;                              
                            
                        END;                    

            ---------------------------------------------------------------------------------------------
            -- SetActionAffectedTableLog
            ---------------------------------------------------------------------------------------------
            SET @sActionAffectedXML = ( SELECT  wActionSp = OBJECT_NAME(@@PROCID) ,
                                                wActionType = @pActionType ,
                                                wNonceToken = @pNonceToken ,
                                                wRefTableName = @sThisTableName ,
                                                wRefRid = tmp.RowId ,
                                                wType = '' ,
                                                wCrtDt = @vNow
                                        FROM    #sDataSet_SetBookingVisa tmp
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
                SELECT  RowId
                FROM    #sDataSet_SetBookingVisa;			           
                  
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
       
        IF OBJECT_ID('tempdb..#sDataSet_SetBookingVisa') IS NOT NULL
            DROP TABLE #sDataSet_SetBookingVisa;
        IF OBJECT_ID('tempdb..#s_Period') IS NOT NULL
            DROP TABLE #s_Period;
    END;