CREATE PROCEDURE [spa].[SetShowTicketBooking]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D    
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pBookingRid BIGINT ,
      @pBookingShowRid BIGINT OUTPUT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT  
    )
AS
    BEGIN    
        SET NOCOUNT ON;
  
        DECLARE @sThisTableName VARCHAR(50) = 'eBookingShow' ,-- For RowID    
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @vNow DATETIME2 = dbo.fnUTC8Now() ,
            @vMthEndYearMth VARCHAR(6) ,
            @vDateUsingCRM DATETIME2 ,
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
         
     --      
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetShowTicketBooking
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)    
  WITH (    
    RowID BIGINT,  
    wBookingRid BIGINT,  
    wShowRid BIGINT,  
    wOrderNo NVARCHAR(30),  
    wTravelAgencyRid BIGINT,  
    wSupplier VARCHAR(2),  
    wShowDt DATETIME2,  
    wCurrCode VARCHAR(6),  
    wTypeQuantity INT,  
    wTicketType NVARCHAR(50),  
    wAmount NUMERIC(18, 4),  
    wTotalQuantity INT,  
    wTotalAmt NUMERIC(18, 4),  
    wExpenseAmt NUMERIC(18, 4),  
    wTotalCost NUMERIC(18, 4),  
    wPaymentMethod VARCHAR(30),  
    wReceiptNo NVARCHAR(50),
    wUseBlackCard CHAR(1),  
    wRemark NVARCHAR(500),  
    wStatus VARCHAR(2),  
    wBookingStatus VARCHAR(5),
    wOldBookingStatus VARCHAR(5),
    wUnqualifiedRid BIGINT
    ,wHaveTicket CHAR(1)
    ,wOtherName NVARCHAR(100)
    ,wScalpedTicket	CHAR(1)
    ,wGetTicketTime	DATETIME2(7)
    ,wCrtBy BIGINT,  
    wCrtDt DATETIME2(7),  
    wUpdBy BIGINT,  
    wUpdDt DATETIME2(7)  
   );    
   
        UPDATE  #sDataSet_SetShowTicketBooking
        SET     wBookingRid = @pBookingRid
        WHERE   wBookingRid <= 0;
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
                DECLARE @sBookingType VARCHAR(30) = 'SHOWTICKET';
                DECLARE @sCurrentBookingStatus VARCHAR(5); -- DB当前状态
                DECLARE @sOldBookingStatus VARCHAR(5); -- 上一次Get數據時的狀態
                DECLARE @sNewBookingStatus VARCHAR(5); -- Save订单新状态
                DECLARE @sLangCd VARCHAR(10) = 'zh-TW';
                SELECT
                    @sCurrentBookingStatus = bs.wBookingStatus, 
                    @sOldBookingStatus = sbat.wOldBookingStatus,
                    @sNewBookingStatus = sbat.wBookingStatus
                FROM dbo.eBookingShow AS bs 
                INNER JOIN #sDataSet_SetShowTicketBooking AS sbat ON sbat.RowID = bs.RowID AND sbat.wBookingRid = bs.wBookingRid
                WHERE bs.wBookingRid = @pBookingRid;

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
/*
                DECLARE @errorMsg varchar(max);	

                IF  @pActionType = 'U' BEGIN
                                            SELECT  @errorMsg = CASE 										
                                                                    WHEN eb.wPaymentMethod<>sb.wPaymentMethod and eb.wBookingStatus IN ('C','CL','UQ','CO','RF')  then 'Can not be updated PaymentMethod when booking status is '+sb.wBookingStatus  										
                                                                    WHEN eb.wBookingStatus in ('RF','CL','UQ') AND  eb.wBookingStatus <> sb.wBookingStatus then eb.wBookingStatus + ' status can not be changed to status code ' + sb.wBookingStatus
                                                                    WHEN eb.wBookingStatus ='C' AND  sb.wBookingStatus in ('P','CL','UQ') then eb.wBookingStatus + ' status can not be changed to status code ' + sb.wBookingStatus
                                                                    WHEN eb.wBookingStatus ='P' AND  sb.wBookingStatus in ('RF','CO') then eb.wBookingStatus + ' status can not be changed to status code ' + sb.wBookingStatus								  
                                                                END
                                            FROM eBookingShow eb inner join
                                            #sDataSet_SetShowTicketBooking sb ON eb.wBookingRid=sb.wBookingRid 		
                                        END
                ELSE IF @pActionType = 'D' BEGIN
                                                SELECT  @errorMsg =CASE 								  
                                                                      WHEN sb.wBookingStatus <> ('P') THEN 'Booking can not be deleted if it not "In-Progress"' 
                                                                    END
                                                FROM eBookingShow eb inner join
                                                 #sDataSet_SetShowTicketBooking sb ON eb.wBookingRid=sb.wBookingRid			   
                                            END
            IF @errorMsg <> ''
                THROW 50001, @errorMsg, 1;

                IF  @pActionType IN ('I', 'U') BEGIN
                    SELECT  @errorMsg = case 
                                  when RTRIM(ISNULL(ebh.wOrderNo,'')) = '' then 'Order No is Missing' 
                                  when ebh.wTravelAgencyRid <= 0 then 'Supplier is Missing'
                                  when ebh.wShowRid <= 0  then 'Show is Missing'
                                  when RTRIM(ISNULL(ebh.wPaymentMethod,'')) = '' then 'Payment Method is missing'	
                                  when RTRIM(ISNULL(ebh.wOtherName,'')) = '' then 'Other name is missing'																  					 
                            end
                from #sDataSet_SetShowTicketBooking ebh
            END
            IF @errorMsg <> ''
                THROW 50001, @errorMsg, 1;
*/
            -------退款，把成本、消費還原到原來的值，因為Code傳過來可能值變成0，導致射數不正確---------------
            IF @pActionType IN ('U')
            BEGIN
                UPDATE dbs
                SET wTotalAmt = bs.wTotalAmt,
                    wExpenseAmt = bs.wExpenseAmt,
                    wTotalCost = bs.wTotalCost
                FROM #sDataSet_SetShowTicketBooking AS dbs
                INNER JOIN dbo.eBookingShow AS bs ON bs.RowID = dbs.RowID
                WHERE dbs.wBookingStatus = 'RF' AND bs.wBookingStatus = 'C'
            END;
            ---------------------------------------------------------------------------------------------
            

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

                    ALTER TABLE #sDataSet_SetShowTicketBooking ADD 
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
                        FROM #sDataSet_SetShowTicketBooking tmp 
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
                    FROM    #sDataSet_SetShowTicketBooking tmp
                            LEFT JOIN dbo.eBookingShow bf ON tmp.wBookingRid = bf.wBookingRid
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
                    WHERE   ( tmp.wBookingStatus = 'C'
                              AND ISNULL(bf.wBookingStatus, 'P') != 'C'
                              OR tmp.wBookingStatus = 'RF'
                              AND ISNULL(bf.wBookingStatus, 'P') != 'RF'
                            );				
                -- Check is already Mth end or not	
                    IF EXISTS ( SELECT  1
                                FROM    #sDataSet_SetShowTicketBooking tmp
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
                                                        wCurDateTime = b.wExpDt ,
                                                        wShift = tmp.wShift ,
                                                        wAgentCodeIn = b.wDebitAgentCodeIn ,
                                                        wCardCodeIn = '' ,
                                                        wCustName = ISNULL(a.wCName, '') ,
                                                        wShopName = '' ,
                                                        wExpTypeCode = 'TICKET 1' ,
                                                        wExpTargetCode = '' ,
                                                        wExpCode = 'TICKET 1' ,
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
                                                        wRemark = CONCAT(N'門票預訂: ', b.wRefNo, CASE tmp.wBookingStatus
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
                                                        wExpCategory = 'ENTERTAINMENT' ,
                                                        wGuid = '' ,
                                                        wRequestAgentCodeIn = b.wReqAgentCodeIn ,
                                                        wIsDeposit = 'N' ,
                                                        wIsDepositDone = 'N' ,
                                                        wProductCategory = '' ,
                                                        wProductDetail = '',
                                                        wBookingRid = tmp.wBookingRid,
                                                        wBookingStatus = tmp.wBookingStatus
                                               FROM     #sDataSet_SetShowTicketBooking tmp
                                                        LEFT JOIN dbo.eBookingShow bh ON tmp.wBookingRid = bh.wBookingRid
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
                        FROM #sDataSet_SetShowTicketBooking tmp
                        INNER JOIN dbo.eBookingShow bs ON tmp.wBookingRid = bs.wBookingRid
                        WHERE ((tmp.wBookingStatus = 'C' AND ISNULL(bs.wBookingStatus, 'P') != 'C')
                                OR (tmp.wBookingStatus = 'RF' AND ISNULL(bs.wBookingStatus, 'P') != 'RF')
                                OR (tmp.wBookingStatus = 'C' AND bs.wBookingStatus = 'C')
                                OR (tmp.wBookingStatus = 'RF' AND bs.wBookingStatus = 'RF'))
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
                                                '0215' AS wSubType , --門票
                                                wRemark = CASE WHEN (g.RowID IS NULL OR tmp.wRemark != bs.wRemark) THEN tmp.wRemark ELSE g.wRemark END,
                                                b.wEventCodeRid AS wEventCodeRid ,
                                                wStatus = CASE WHEN g.RowID IS NULL THEN 'A' ELSE g.wStatus END,
                                                wCrtDt = CASE WHEN g.RowID IS NULL THEN @vNow ELSE g.wCrtDt END, -- set sp should not update this field when update
                                                wCrtBy = CASE WHEN g.RowID IS NULL THEN tmp.wUpdBy ELSE g.wCrtBy END, -- in set sp should not update this field when update
                                                @vNow AS wUpdDt ,
                                                tmp.wUpdBy ,
                                                CASE WHEN ((tmp.wBookingStatus = 'C' AND ISNULL(bs.wBookingStatus, 'P') != 'C')
                                                          OR (tmp.wBookingStatus = 'RF' AND ISNULL(bs.wBookingStatus, 'P') != 'RF'))
                                                          --AND ISNULL(g.wRefTableRid, 0) <= 0 
                                                THEN 'I'
                                                ELSE 'U'
                                                END AS RecordState ,
                                                b.wGiftReasonCd AS wReasonCd ,
                                                wIsReceived = CASE WHEN g.RowID IS NULL THEN 'Y' ELSE g.wIsReceived END, -- 經由booking 產生的送禮記錄要預設為 "已接收"
                                                tmp.wTotalCost AS wCost
                                     FROM #sDataSet_SetShowTicketBooking tmp
                                     INNER JOIN dbo.eBookingShow bs ON tmp.wBookingRid = bs.wBookingRid AND bs.wStatus = 'A' AND (tmp.wPaymentMethod = 'GC' OR tmp.wPaymentMethod = 'GC0')
                                     INNER JOIN dbo.eBooking b ON b.RowID = tmp.wBookingRid
                                     INNER JOIN dbo.mServiceCounter sc ON sc.RowID = b.wReqCounterRid
                                     LEFT JOIN eGift g ON g.wRefTableRid = tmp.wBookingRid AND g.wStatus = 'A' AND ((tmp.wBookingStatus = 'C' AND bs.wBookingStatus = 'C') OR (tmp.wBookingStatus = 'RF' AND bs.wBookingStatus = 'RF')) -- 只有Update才能Join到舊數據
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
                    UPDATE  #sDataSet_SetShowTicketBooking
                    SET     RowID = 0;    
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetShowTicketBooking;    
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN    
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;    
         
                            UPDATE  #sDataSet_SetShowTicketBooking
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;    
                            SET @sRuningIndex = @sRuningIndex + 1;    
                        END;
    
   -- MAIN Logic here, example here is inserting dataset to eIOUPenalty    
                    INSERT  INTO [dbo].[eBookingShow]
                            ( RowID ,
                              wBookingRid ,
                              wShowRid ,
                              wOrderNo ,
                              wTravelAgencyRid ,
                              wSupplier ,
                              wShowDt ,
                              wCurrCode ,   
        --wTypeQuantity,   
        --wTicketType,   
        --wAmount,   
                              wTotalQuantity ,
                              wTotalAmt ,
                              wExpenseAmt ,
                              wTotalCost ,
                              wPaymentMethod ,
                              wReceiptNo ,
                              wUseBlackCard ,
                              wRemark ,
                              wStatus ,
                              wBookingStatus ,
                              wUnqualifiedRid ,
                              wHaveTicket ,
                              wOtherName ,
                              wScalpedTicket ,
                              wGetTicketTime ,
                              wCrtBy ,
                              wCrtDt ,
                              wUpdBy ,
                              wUpdDt
                            )
                            SELECT  ers.RowID ,
                                    @pBookingRid ,
                                    ers.wShowRid ,
                                    ers.wOrderNo ,
                                    ers.wTravelAgencyRid ,
                                    ers.wSupplier ,
                                    ers.wShowDt ,
                                    ers.wCurrCode ,   
        --ers.wTypeQuantity,   
        --ers.wTicketType,   
        --ers.wAmount,   
                                    ers.wTotalQuantity ,
                                    ers.wTotalAmt ,
                                    ers.wExpenseAmt ,
                                    ers.wTotalCost ,
                                    ers.wPaymentMethod ,
                                    ers.wReceiptNo ,
                                    ers.wUseBlackCard ,
                                    ers.wRemark ,
                                    ers.wStatus ,
                                    ers.wBookingStatus ,
                                    ISNULL(ers.wUnqualifiedRid, 0) ,
                                    ers.wHaveTicket ,
                                    ers.wOtherName ,
                                    ers.wScalpedTicket ,
                                    ers.wGetTicketTime ,
                                    ers.wCrtBy ,
                                    ers.wCrtDt ,
                                    ers.wUpdBy ,
                                    ers.wUpdDt
                            FROM    #sDataSet_SetShowTicketBooking ers;  
    
                END;    
    
            ELSE
                IF @pActionType = 'U'
                    BEGIN    
                        UPDATE  ers
                        SET     --ers.RowID = tmp.RowID,   
       --ers.wBookingRid = tmp.wBookingRid,   
                                ers.wShowRid = tmp.wShowRid ,
                                ers.wOrderNo = tmp.wOrderNo ,
                                ers.wTravelAgencyRid = tmp.wTravelAgencyRid ,
                                ers.wSupplier = tmp.wSupplier ,
                                ers.wShowDt = tmp.wShowDt ,
                                ers.wCurrCode = tmp.wCurrCode ,   
       --ers.wTypeQuantity = tmp.wTypeQuantity,   
       --ers.wTicketType = tmp.wTicketType,   
       --ers.wAmount = tmp.wAmount,   
                                ers.wTotalQuantity = tmp.wTotalQuantity ,
                                ers.wTotalAmt = tmp.wTotalAmt ,
                                ers.wExpenseAmt = tmp.wExpenseAmt ,
                                ers.wTotalCost = tmp.wTotalCost ,
                                ers.wPaymentMethod = tmp.wPaymentMethod ,
                                ers.wReceiptNo = tmp.wReceiptNo ,
                                ers.wUseBlackCard = tmp.wUseBlackCard ,
                                ers.wRemark = tmp.wRemark ,
                                ers.wStatus = tmp.wStatus ,
                                ers.wBookingStatus = tmp.wBookingStatus ,
                                ers.wUnqualifiedRid = ISNULL(tmp.wUnqualifiedRid, 0) ,
                                ers.wHaveTicket = tmp.wHaveTicket ,
                                ers.wOtherName = tmp.wOtherName ,
                                ers.wScalpedTicket = tmp.wScalpedTicket ,
                                ers.wGetTicketTime = tmp.wGetTicketTime ,
                                ers.wCrtBy = tmp.wCrtBy ,
                                ers.wCrtDt = tmp.wCrtDt ,
                                ers.wUpdBy = tmp.wUpdBy ,
                                ers.wUpdDt = tmp.wUpdDt
                        FROM    dbo.eBookingShow AS ers
                                INNER JOIN #sDataSet_SetShowTicketBooking tmp ON ers.RowID = tmp.RowID
                        WHERE   ers.RowID = tmp.RowID;  
    
                    END;    
  
                ELSE
                    IF @pActionType = 'D'
                        BEGIN  
                            UPDATE  ers
                            SET     ers.wBookingStatus = 'DL' ,
                                    ers.wStatus = 'T' ,
                                    ers.wUpdDt = dbo.fnUTC8Now()
                            FROM    dbo.eBookingShow AS ers
                                    INNER JOIN #sDataSet_SetShowTicketBooking tmp ON ers.RowID = tmp.RowID
                            WHERE   ers.RowID = tmp.RowID;                              
                        END;             
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;
        
            SELECT TOP 1
                    @pBookingShowRid = RowID
            FROM    #sDataSet_SetShowTicketBooking;
        -- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetShowTicketBooking;

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

        IF OBJECT_ID('tempdb..#sDataSet_SetShowTicketBooking') IS NOT NULL
            DROP TABLE #sDataSet_SetShowTicketBooking;
        IF OBJECT_ID('tempdb..#s_Period') IS NOT NULL
            DROP TABLE #s_Period;
    END;