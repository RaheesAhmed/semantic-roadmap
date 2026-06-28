CREATE PROCEDURE [spa].[SetBookingAdditionalExpenses]
(
    @pXML XML ,
    @pActionType CHAR(1) , -- I/U/D  
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pReturnResultSet CHAR(1) = 'N' ,
    @pBookingRid BIGINT ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT  
)
AS
    BEGIN  
        SET NOCOUNT ON;

        DECLARE @sThisTableName VARCHAR(50) = 'eAdditionalExpense' , -- For RowID  
                @sRecCount INT = 0 ,
                @sRuningIndex INT = 1 ,
                @sRowID BIGINT = 0 ,
                @sDocHandle INT ,
                @sSeqNo INT = 0 ,
                @vNow DATETIME2 = dbo.fnUTC8Now() ,
                @sActionAffectedXML NVARCHAR(MAX) = '' ,
                @sXMLeGift NVARCHAR(MAX) = '' ,
                @sCageCodeIn VARCHAR(14) ,
                @vMthEndYearMth VARCHAR(6) ,
                @vDateUsingCRM DATETIME2 ,
                @sBeginTranCount INT = 0;
        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );  

        SET @sBeginTranCount = @@trancount;

        SET @sCageCodeIn = (
            SELECT TOP (1) c.wCageCodeIn
            FROM dbo.eBooking AS b
            INNER JOIN dbo.mServiceCounter AS sc ON sc.RowID = b.wDebitCounterRid
            INNER JOIN RollsMary.dbo.mCage AS c ON c.wCompNo = sc.wRollexCompNo AND c.wCageCode = '001' AND c.wStatus = 'A'
            WHERE  b.RowID = @pBookingRid
        );
       
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;  
            
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
            *
        INTO #sDataSet_SetAdditionalExpense
        FROM OPENXML (@sDocHandle, 'DataSet/Record', 1)  
        WITH (  
            RowID BIGINT ,  
            wOrderNo NVARCHAR(20),  
            wBookingRefRid BIGINT,
            wBookingRid BIGINT,  
            wRoomBookingRid BIGINT,
            wExpenseType BIGINT,  
            wExpenseSubtype BIGINT,  
            wPaymentMethod VARCHAR(30),  
            wReceiptNo NVARCHAR(50), 
            wExpAmt NUMERIC(18,4),  
            wTotalAmt NUMERIC(18,4),  
            wCost NUMERIC(18,4),  
            wCurrcode VARCHAR(30),  
            wIsUseBlackCard CHAR(1),  
            wRemark NVARCHAR(500),  
            wBookingStatus VARCHAR(5),  
            wUnqualifiedRid BIGINT,  
            wSeqNo INT,  
            wUpdDt DATETIME2(7),  
            wUpdBy BIGINT,
            wSpaRid BIGINT,
            wRestaurantRid BIGINT,
            wTravelAgencyRid BIGINT,
            wPersonRid VARCHAR(1000),
            wOldBookingStatus VARCHAR(10)  
        );
          
        -- Aloha bad method, say need to update here
        UPDATE #sDataSet_SetAdditionalExpense
        SET wBookingRefRid = @pBookingRid
        WHERE wBookingRefRid <= 0;

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
            DECLARE @sBookingType VARCHAR(30) = 'ADDITIONALEXPENSES';
            DECLARE @sCurrentBookingStatus VARCHAR(5); -- DB当前状态
            DECLARE @sOldBookingStatus VARCHAR(5); -- 上一次Get數據時的狀態
            DECLARE @sNewBookingStatus VARCHAR(5); -- Save订单新状态
            DECLARE @sLangCd VARCHAR(10) = 'zh-TW';
            SELECT
                @sCurrentBookingStatus = eae.wBookingStatus, 
                @sOldBookingStatus = sae.wOldBookingStatus,
                @sNewBookingStatus = sae.wBookingStatus
            FROM dbo.eAdditionalExpense AS eae 
            INNER JOIN #sDataSet_SetAdditionalExpense AS sae ON sae.RowID = eae.RowID AND sae.wBookingRefRid = eae.wBookingRefRid
            WHERE eae.wBookingRefRid = @pBookingRid;

            -- 獲取不到DB預訂當前狀態，訂單不存在（wBookingStatus IS NOT NULL）
            -- 如果已經有錯誤，不再Check
            IF NULLIF(@sErrorMsg, '') IS NULL AND @sCurrentBookingStatus IS NULL
                SET @sErrorMsg = N'訂單不存在。' + CAST(@pBookingRid AS VARCHAR);

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
            FROM    RollsMary.dbo.eSettleTran (NOLOCK)
            WHERE wSettleLineGrp = '';	
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

                    ALTER TABLE #sDataSet_SetAdditionalExpense ADD 
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
                        FROM #sDataSet_SetAdditionalExpense tmp 
                             INNER JOIN dbo.eBooking b ON tmp.wBookingRefRid = b.RowID
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
                                                            WHEN 'RF' THEN ISNULL(b.wCancelDebitDt, b.wDebitDt)
                                                            ELSE b.wDebitDt
                                                          END AS DATE)) ,
                            wShift = ISNULL(cs.wShift, '1')
                    FROM    #sDataSet_SetAdditionalExpense tmp
                            LEFT JOIN dbo.eAdditionalExpense ae ON tmp.wBookingRefRid = ae.wBookingRefRid
                                                                   AND ae.wStatus = 'A'
                            INNER JOIN dbo.eBooking b ON tmp.wBookingRefRid = b.RowID
                            LEFT JOIN dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                            LEFT JOIN RollsMary.dbo.mSettlePeriod sp ON sp.wCompNo = sc.wRollexCompNo AND sp.wCageCodeIn = @sCageCodeIn
                                                                        AND CASE tmp.wBookingStatus
                                                                              WHEN 'RF' THEN ISNULL(b.wCancelDebitDt, b.wDebitDt)
                                                                              ELSE b.wDebitDt
                                                                            END BETWEEN sp.wStartDateTime
                                                                                AND     sp.wEndDateTime
                            LEFT JOIN RollsMary.dbo.eCompShift cs ON cs.wCompNo = sc.wRollexCompNo
                                                                     AND CASE tmp.wBookingStatus
                                                                           WHEN 'RF' THEN ISNULL(b.wCancelDebitDt, b.wDebitDt)
                                                                           ELSE b.wDebitDt
                                                                         END BETWEEN cs.wStartDateTime
                                                                             AND     cs.wEndDateTime
                    WHERE   ( ( tmp.wBookingStatus = 'C'
                                AND ISNULL(ae.wBookingStatus, 'P') != 'C'
                              )
                              OR ( tmp.wBookingStatus = 'RF'
                                   AND ISNULL(ae.wBookingStatus, 'P') != 'RF'
                                 )
                            );
                
                -- Check is already Mth end or not	
                    IF EXISTS ( SELECT  1
                                FROM    #sDataSet_SetAdditionalExpense tmp
                                WHERE   tmp.wYearMth <= @vMthEndYearMth )
                        BEGIN
                            DECLARE @vMaxYearMth VARCHAR(30) = '';
                            SELECT  @vMaxYearMth = MAX(tmp.wYearMth)
                            FROM    #sDataSet_SetAdditionalExpense tmp
                            WHERE   tmp.wYearMth <= @vMthEndYearMth;

                            SET @pErrMsg = CONCAT(@vMthEndYearMth, ' already month end, cannot insert expense on or before that. Expense contains Period: ', @vMaxYearMth);
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
                                                        wCurCode = tmp.wCurrcode ,
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
                                                                 END * tmp.wTotalAmt ,
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
                                                        wRemark = CONCAT(N'其他消費預訂: ', b.wRefNo, CASE tmp.wBookingStatus
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
                                                        wRefRid = 0,
                                                        wReferId = tmp.wBookingRefRid ,
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
                                                        wExpCategory = CASE WHEN ISNULL(est.wExpCat, et.wExpCat) IN ('FB','DINE') THEN 'DINE'
                                                                            WHEN ISNULL(est.wExpCat, et.wExpCat) = 'HO' THEN 'STAY'
                                                                            WHEN ISNULL(est.wExpCat, et.wExpCat) = 'TR' THEN 'TRAVEL'
                                                                            WHEN ISNULL(est.wExpCat, et.wExpCat) = 'SH' THEN 'SHOPPING'
                                                                            WHEN ISNULL(est.wExpCat, et.wExpCat) = 'EN' THEN 'ENTERTAINMENT'
                                                                            WHEN ISNULL(est.wExpCat, et.wExpCat) IN ('UN','OTHER') THEN 'OTHER'
                                                                            ELSE ''
                                                                       END ,
                                                        wGuid = '' ,
                                                        wRequestAgentCodeIn = b.wReqAgentCodeIn ,
                                                        wIsDeposit = 'N' ,
                                                        wIsDepositDone = 'N' ,
                                                        wProductCategory = '' ,
                                                        wProductDetail = '',
                                                        wBookingRid = tmp.wBookingRefRid,
                                                        wBookingStatus = tmp.wBookingStatus
                                               FROM     #sDataSet_SetAdditionalExpense tmp
                                                        LEFT JOIN dbo.eAdditionalExpense ae ON ae.wBookingRefRid = tmp.wBookingRefRid
                                                                                               AND ae.wStatus = 'A'
                                                        INNER JOIN dbo.eBooking b ON tmp.wBookingRefRid = b.RowID
                                                        INNER JOIN RollsMary.dbo.mAgent a ON b.wDebitAgentCodeIn = a.wAgentCodeIn
                                                        LEFT JOIN dbo.mExpenseSubtype est ON est.RowID = ae.wExpenseSubtype
                                                                                             AND est.wStatus = 'A'
                                                        LEFT JOIN dbo.mExpenseType AS et ON ae.wExpenseType = et.RowID AND et.wStatus = 'A'
                                                        LEFT JOIN RollsMary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                                        LEFT JOIN dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                                                        LEFT JOIN RollsMary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                                                           AND c.wCageCode = '001'
                                                                                           AND c.wStatus = 'A'
                                                        LEFT JOIN RollsMary.dbo.mUsr u ON tmp.wUpdBy = u.RowID
                                               WHERE    ( ( tmp.wBookingStatus = 'C'
                                                            AND ISNULL(ae.wBookingStatus, 'P') != 'C'
                                                          )
                                                          OR ( tmp.wBookingStatus = 'RF'
                                                               AND ISNULL(ae.wBookingStatus, 'P') != 'RF'
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
            ---------------------------------------------------------------------------------------------
            -- End Sync Expense
            ---------------------------------------------------------------------------------------------

            ---------------------------------------------------------------------------------------------
            -- Add eGift record
            ---------------------------------------------------------------------------------------------
            IF EXISTS ( SELECT  1
                        FROM #sDataSet_SetAdditionalExpense tmp
                        INNER JOIN dbo.eAdditionalExpense ae ON tmp.wBookingRefRid = ae.wBookingRefRid
                        WHERE ((tmp.wBookingStatus = 'C' AND ISNULL(ae.wBookingStatus, 'P') != 'C')
                               OR (tmp.wBookingStatus = 'RF' AND ISNULL(ae.wBookingStatus, 'P') != 'RF')
                               OR (tmp.wBookingStatus = 'C' AND ae.wBookingStatus = 'C')
                               OR (tmp.wBookingStatus = 'RF' AND ae.wBookingStatus = 'RF'))
                           AND (tmp.wPaymentMethod = 'GC' OR tmp.wPaymentMethod = 'GC0') )
                BEGIN
                    SET @sXMLeGift = ( SELECT g.RowID AS RowID ,
                                              tmp.wBookingRefRid AS wRefBookingRid ,
                                              'eBooking' AS wRefTableName ,
                                              tmp.wBookingRefRid AS wRefTableRid ,
                                              tmp.wBookingStatus AS wOriActionType ,
                                              b.wDebitCounterRid AS wDebitCounterRid, -- 扣數櫃台
                                              b.wReqCounterRid AS wReqCounterRid , -- 要求櫃台
                                              sc.wRollexCompNo AS wCompNo ,
                                              @sCageCodeIn AS wCageCodeIn ,
                                              b.wReqDepartment AS wReqDeptCd ,
                                              b.wReqUserRid AS wReqStaffRid ,
                                              b.wReqAgentCodeIn AS wReqAgentCodeIn ,
                                              wDate = CASE WHEN g.RowID IS NULL THEN GETDATE() ELSE g.wDate END,
                                              a.wCName AS wRecipient ,
                                              -- 'HKD' AS wCurrCode ,  --2018-12-14： OP#24284，送禮特批中的金額貨幣現在默認為HKD，應該跟Booking中的貨幣
                                              tmp.wCurrcode AS wCurrCode ,
                                              wAmount = CASE WHEN g.RowID IS NULL THEN (CASE tmp.wBookingStatus WHEN 'RF' THEN -1 ELSE 1 END) * tmp.wTotalAmt ELSE g.wAmount END,
                                              '02' AS wType , --送禮
                                              '0208' AS wSubType , --其他禮物
                                              wRemark = CASE WHEN (g.RowID IS NULL OR tmp.wRemark != ae.wRemark OR tmp.wExpenseType != ae.wExpenseType OR tmp.wExpenseSubtype != ae.wExpenseSubtype) THEN CONCAT(et.wName, CASE WHEN est.wName IS NULL THEN NULL ELSE (' - ' + est.wName) END, CHAR(10), tmp.wRemark) ELSE g.wRemark END,
                                              b.wEventCodeRid AS wEventCodeRid ,
                                              wStatus = CASE WHEN g.RowID IS NULL THEN 'A' ELSE g.wStatus END,
                                              wCrtDt = CASE WHEN g.RowID IS NULL THEN @vNow ELSE g.wCrtDt END, -- set sp should not update this field when update
                                              wCrtBy = CASE WHEN g.RowID IS NULL THEN tmp.wUpdBy ELSE g.wCrtBy END, -- in set sp should not update this field when update
                                              @vNow AS wUpdDt ,
                                              tmp.wUpdBy ,
                                              CASE WHEN ((tmp.wBookingStatus = 'C' AND ISNULL(ae.wBookingStatus, 'P') != 'C' )
                                                         OR (tmp.wBookingStatus = 'RF' AND ISNULL(ae.wBookingStatus, 'P') != 'RF'))
                                                         --AND ISNULL(g.wRefTableRid, 0) <= 0 
                                              THEN 'I'
                                              ELSE 'U'
                                              END AS RecordState ,
                                              b.wGiftReasonCd AS wReasonCd ,
                                              wIsReceived = CASE WHEN g.RowID IS NULL THEN 'Y' ELSE g.wIsReceived END, -- 經由booking 產生的送禮記錄要預設為 "已接收"
                                              tmp.wCost
                                     FROM  #sDataSet_SetAdditionalExpense tmp
                                     INNER JOIN dbo.eAdditionalExpense ae ON tmp.wBookingRefRid = ae.wBookingRefRid AND ae.wStatus = 'A' AND (tmp.wPaymentMethod = 'GC' OR tmp.wPaymentMethod = 'GC0')
                                     INNER JOIN dbo.eBooking b ON b.RowID = tmp.wBookingRefRid
                                     INNER JOIN dbo.mServiceCounter sc ON sc.RowID = b.wReqCounterRid
                                     LEFT JOIN eGift g ON g.wRefTableRid = tmp.wBookingRefRid AND g.wStatus = 'A' AND ((tmp.wBookingStatus = 'C' AND ae.wBookingStatus = 'C') OR (tmp.wBookingStatus = 'RF' AND ae.wBookingStatus = 'RF')) -- 只有Update才能Join到舊數據
                                     INNER JOIN RollsMary.dbo.mAgent a ON a.wAgentCodeIn = b.wApprovalAgentCodeIn AND a.wStatus = 'A'
                                     -- 消費類型
                                     LEFT JOIN dbo.mExpenseType AS et ON et.RowID = tmp.wExpenseType
                                     LEFT JOIN dbo.mExpenseSubtype AS est ON est.RowID = tmp.wExpenseSubtype AND est.wExpenseTypeId = et.RowID
                                     FOR XML RAW('Record'), ROOT('DataSet'));
                                                                     
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
                    UPDATE  #sDataSet_SetAdditionalExpense
                    SET     RowID = 0 ,
                            wSeqNo = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetAdditionalExpense;  
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;  
       
                            IF @sSeqNo = 0
                                BEGIN  
                                    SELECT  @sSeqNo = ISNULL(MAX(wSeqNo), 1)
                                    FROM    dbo.eAdditionalExpense;   
                                    SET @sSeqNo = @sSeqNo + 1;  
                                END;  
                            ELSE
                                BEGIN  
                                    SET @sSeqNo = @sSeqNo + 1;  
                                END;  
                            UPDATE  #sDataSet_SetAdditionalExpense
                            SET     RowID = @sRowID ,
                                    wBookingRefRid = @pBookingRid ,  
                                    --wBookingRid = @pBookingRId,  
                                    wSeqNo = @sSeqNo
                            WHERE   wRowNum = @sRuningIndex;  
                            SET @sRuningIndex = @sRuningIndex + 1;  
                        END;                
                        -- MAIN Logic here, example here is inserting dataset to eIOUPenalty  
                    INSERT  INTO dbo.[eAdditionalExpense]
                            ( RowID ,
                              wOrderNo ,
                              wBookingRefRid ,
                              wBookingRid ,
                              wRoomBookingRid ,
                              wExpenseType ,
                              wExpenseSubtype ,
                              wPaymentMethod ,
                              wReceiptNo ,
                              wExpAmt ,
                              wTotalAmt ,
                              wCost ,
                              wCurrcode ,
                              wIsUseBlackCard ,
                              wRemark ,
                              wBookingStatus ,
                              wUnqualifiedRid ,
                              wSeqNo ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy ,
                              wSpaRid ,
                              wRestaurantRid ,
                              wTravelAgencyRid ,
                              wPersonRid
                            )
                            SELECT  s.RowID ,
                                    s.wOrderNo ,
                                    s.wBookingRefRid ,
                                    CASE WHEN s.wBookingRid = 0 THEN s.wBookingRefRid
                                         ELSE s.wBookingRid
                                    END ,
                                    s.wRoomBookingRid ,
                                    s.wExpenseType ,
                                    s.wExpenseSubtype ,
                                    s.wPaymentMethod ,
                                    s.wReceiptNo ,
                                    s.wExpAmt ,
                                    s.wTotalAmt ,
                                    s.wCost ,
                                    s.wCurrcode ,
                                    s.wIsUseBlackCard ,
                                    s.wRemark ,
                                    s.wBookingStatus ,
                                    ISNULL(s.wUnqualifiedRid, 0) ,
                                    s.wSeqNo ,
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy ,
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy ,
                                    s.wSpaRid ,
                                    s.wRestaurantRid ,
                                    s.wTravelAgencyRid ,
                                    s.wPersonRid
                            FROM    #sDataSet_SetAdditionalExpense s;						 
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  ae
                        SET     ae.wOrderNo = tmp.wOrderNo ,
                                ae.wExpenseType = tmp.wExpenseType ,
                                ae.wExpenseSubtype = tmp.wExpenseSubtype ,
                                ae.wPaymentMethod = tmp.wPaymentMethod ,
                                ae.wReceiptNo = tmp.wReceiptNo ,
                                ae.wExpAmt = tmp.wExpAmt ,
                                ae.wTotalAmt = tmp.wTotalAmt ,
                                ae.wCost = tmp.wCost ,
                                ae.wCurrcode = tmp.wCurrcode ,
                                ae.wIsUseBlackCard = tmp.wIsUseBlackCard ,
                                ae.wRemark = tmp.wRemark ,
                                ae.wBookingStatus = tmp.wBookingStatus ,
                                ae.wUnqualifiedRid = ISNULL(tmp.wUnqualifiedRid, 0) ,
                                ae.wUpdDt = dbo.fnUTC8Now() ,
                                ae.wUpdBy = tmp.wUpdBy ,
                                ae.wSpaRid = tmp.wSpaRid ,
                                ae.wRestaurantRid = tmp.wRestaurantRid ,
                                ae.wTravelAgencyRid = tmp.wTravelAgencyRid
                                --如果是Update，不能修改PersonRid，此單只能在Insert時確定客戶，之後不能再轉換給另外一個人
                                --ae.wPersonRid = tmp.wPersonRid
                        FROM    [dbo].[eAdditionalExpense] AS ae
                                INNER JOIN #sDataSet_SetAdditionalExpense tmp ON ae.wBookingRefRid = tmp.wBookingRefRid
                        WHERE   ae.wBookingRefRid = tmp.wBookingRefRid;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN
                            UPDATE  ae
                            SET     ae.wBookingStatus = 'DL' ,
                                    ae.wStatus = 'T' ,
                                    ae.wUpdDt = dbo.fnUTC8Now() ,
                                    ae.wUpdBy = tmp.wUpdBy
                            FROM    [dbo].[eAdditionalExpense] AS ae
                                    INNER JOIN #sDataSet_SetAdditionalExpense tmp ON ae.RowID = tmp.RowID;
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
                                        FROM    #sDataSet_SetAdditionalExpense tmp
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
                FROM    #sDataSet_SetAdditionalExpense;
        
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

        IF OBJECT_ID('tempdb..#sDataSet_SetAdditionalExpense') IS NOT NULL
            DROP TABLE #sDataSet_SetAdditionalExpense;

        IF OBJECT_ID('tempdb..#s_Period') IS NOT NULL
            DROP TABLE #s_Period;
    END;