CREATE PROCEDURE [test].[SetBookingAdditionalExpenses]  
(  
    @pXML XML ,  
    @pActionType CHAR(1) , -- I/U/D  
    @pMainCompNo INT,
    @pNonceToken VARCHAR(64),	 
    @pReturnResultSet CHAR(1) = 'N',
    @pBookingRid BigINT,
    @pIsRelatedRefRid CHAR(1) ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT  
)  
AS  
    BEGIN  
        SET NOCOUNT ON;  
        select * from eAdditionalExpense
        DECLARE @sThisTableName VARCHAR(50) = 'eAdditionalExpense' , -- For RowID  
            @sRecCount INT = 0 ,  
            @sRuningIndex INT = 1 ,  
            @sRowID BIGINT = 0 ,  
            @sDocHandle INT,  
            @sSeqNo INT = 0,
            @vNow DATETIME2 = dbo.fnUTC8Now(),
            @sActionAffectedXML NVARCHAR(MAX) = '',
            @vMthEndYearMth VARCHAR(6),
            @vDateUsingCRM DATETIME2,
            @sBeginTranCount INT = 0;
        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );  

        SET @sBeginTranCount = @@trancount;
       
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;  
          
        SELECT * FROM OPENXML (@sDocHandle, 'DataSet/Record', 1)  
  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,  
                *  
        INTO    #sDataSet_SetAdditionalExpense  
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)  
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
            wBookingStatus varchar(5),  
            wUnqualifiedRid BIGINT,  
            wSeqNo INT,  
            wUpdDt DATETIME2(7),  
            wUpdBy BIGINT,
            wSpaRid BIGINT,
            wRestaurantRid BIGINT,
            wTravelAgencyRid BIGINT,
            wPersonRid BIGINT  
        );  
        -- Aloha bad method, say need to update here
        UPDATE #sDataSet_SetAdditionalExpense SET wBookingRid = @pBookingRid WHERE wBookingRid <= 0;
/*
            --- Additional Required Field Validation Start
            DECLARE @errorMsg varchar(max);	
            IF  @pActionType IN ('I', 'U') BEGIN
                 select  @errorMsg = case 
                                  when RTRIM(ISNULL(ea.wPaymentMethod,'')) = '' then 'Payment Method is missing' 
                                  when ea.wExpenseType <= 0  then 'TypeOf Expense is Missing'
                                  when ea.wTravelAgencyRid <= 0  then 'Supplier is Missing'						  													 
                            end
                from #sDataSet_SetAdditionalExpense ea
            END
            IF @errorMsg <> ''
                throw 50001, @errorMsg, 1;
            --- Additional Required Field Validation end
*/
  
        --better don't put everything within try, for example  
        --getting mSysTable value  
        --getting currency, period, mCompany ...  
        -- print 'i am idetified';  

         BEGIN TRY
            -- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            ---------------------------------------------------------------------------------------------
            -- Sync Expense to rollsmary
            ---------------------------------------------------------------------------------------------
            SELECT @vMthEndYearMth = MAX(wYearMth) FROM RollsMary.dbo.eSettleTran (NOLOCK) WHERE wSettleLineGrp = '';
            SET @vDateUsingCRM = (SELECT TOP 1 wValue FROM RollsMary.dbo.mSysTable WHERE wItemCode = 'DATE_USING_CRM');
            SET @vDateUsingCRM = ISNULL(@vDateUsingCRM, '2099-12-31');

            IF @pActionType IN ('I', 'U') BEGIN
                DECLARE
                    @vXMLInsertExp	NVARCHAR(MAX) = '',
                    @vXMLRefundExp	NVARCHAR(MAX) = '',

                    @vErrCode		INT = 0,
                    @vErrMsg		NVARCHAR(MAX);

                ALTER TABLE #sDataSet_SetAdditionalExpense ADD 
                    wPeriodCodeIn	VARCHAR(50) NOT NULL DEFAULT '',
                    wYearMth		VARCHAR(6),
                    wDate			DATE,
                    wShift			CHAR(1)

                UPDATE
                    tmp
                SET
                    wPeriodCodeIn = ISNULL(sp.wPeriodCodeIn, CONCAT(sc.wRollexCompNo, '_', FORMAT(CASE tmp.wBookingStatus WHEN 'RF' THEN ISNULL(b.wCancelDebitDt, b.wDebitDt) ELSE b.wDebitDt END, 'yyyyMM'), '_01')),
                    wYearMth = ISNULL(sp.wYear + sp.wMonth, FORMAT(CASE tmp.wBookingStatus WHEN 'RF' THEN ISNULL(b.wCancelDebitDt, b.wDebitDt) ELSE b.wDebitDt END, 'yyyyMM')),
                    wDate = ISNULL(cs.wDate, CAST(CASE tmp.wBookingStatus WHEN 'RF' THEN ISNULL(b.wCancelDebitDt, b.wDebitDt) ELSE b.wDebitDt END AS DATE)),
                    wShift = ISNULL(cs.wShift, '1')
                FROM
                    #sDataSet_SetAdditionalExpense tmp
                LEFT JOIN
                    dbo.eAdditionalExpense ae ON (CASE WHEN @pIsRelatedRefRid='Y'  THEN tmp.wBookingRefRid ELSE tmp.wBookingRid END) = (CASE WHEN @pIsRelatedRefRid='Y' THEN ae.wBookingRefRid ELSE ae.wBookingRid END) AND ae.wStatus = 'A'
                INNER JOIN
                    dbo.eBooking b ON (CASE WHEN @pIsRelatedRefRid='Y'  THEN tmp.wBookingRefRid ELSE tmp.wBookingRid END) = b.RowID
                LEFT JOIN
                    dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                LEFT JOIN
                    RollsMary.dbo.mSettlePeriod sp ON wCompNo = sc.wRollexCompNo AND CASE tmp.wBookingStatus WHEN 'RF' THEN ISNULL(b.wCancelDebitDt, b.wDebitDt) ELSE b.wDebitDt END BETWEEN sp.wStartDateTime AND sp.wEndDateTime
                LEFT JOIN
                    RollsMary.dbo.eCompShift cs ON cs.wCompNo = sc.wRollexCompNo AND CASE tmp.wBookingStatus WHEN 'RF' THEN ISNULL(b.wCancelDebitDt, b.wDebitDt) ELSE b.wDebitDt END BETWEEN cs.wStartDateTime AND cs.wEndDateTime
                WHERE
                    (
                        (tmp.wBookingStatus = 'C' AND ISNULL(ae.wBookingStatus, 'P') != 'C')
                    OR
                        (tmp.wBookingStatus = 'RF' AND ISNULL(ae.wBookingStatus, 'P') != 'RF')
                    )
                
                -- Check is already Mth end or not	
                IF EXISTS(SELECT 1 FROM #sDataSet_SetAdditionalExpense tmp WHERE tmp.wYearMth <= @vMthEndYearMth) BEGIN
                    DECLARE @vMaxYearMth VARCHAR(30) = '';
                    SELECT @vMaxYearMth = MAX(tmp.wYearMth) FROM #sDataSet_SetAdditionalExpense tmp WHERE tmp.wYearMth <= @vMthEndYearMth;

                    SET @pErrMsg = CONCAT(@vMthEndYearMth, ' already month end, cannot insert expense on or before that. Expense contains Period: ', @vMaxYearMth);
                    THROW 50001, @pErrMsg, 1;
                END

                IF @vNow >= @vDateUsingCRM
                -- Changed Status To CONFIRM, ADD expense tran
                SET @vXMLInsertExp = (
                    SELECT 		
                        RowID = 0, wCompNo = sc.wRollexCompNo, wCageCodeIn = c.wCageCodeIn, wTranNo = '', wDate = tmp.wDate,
                        wCurDateTime = @vNow, wShift = tmp.wShift, wAgentCodeIn = b.wDebitAgentCodeIn, wCardCodeIn = '', wCustName = ISNULL(a.wCName, ''),
                        wShopName = '', wExpTypeCode = 'OTHER', wExpTargetCode = '1000000017', wExpCode = '1000058000', wExpSubCode1 = '', wCurCode = tmp.wCurrCode,
                        wRoomNo = '', wRoomCfmCode = '', wRoomBookDt = NULL, wRoomCheckInDt = NULL, wRoomDeptDt = NULL, wNight = 0, wUnit = 1,
                        wPrice = CASE tmp.wBookingStatus WHEN 'RF' THEN -1 ELSE 1 END * tmp.wTotalAmt, 
                        wRoomExpAmt = 0, 
                        wAmount = CASE WHEN tmp.wPaymentMethod IN ('DA', 'GC') THEN 1 ELSE 0 END * CASE tmp.wBookingStatus WHEN 'RF' THEN -1 ELSE 1 END * tmp.wTotalAmt, 
                        wExpLocation = sc.wDefaultHotelCode, wVoucherNo = '', wVoucherDt = tmp.wDate,
                        wRemark = CONCAT(N'其他消費預訂: ', b.wRefNo, CASE tmp.wBookingStatus WHEN 'RF' THEN N'退款' ELSE N'' END ), 
                        wPeriodCodeIn = tmp.wPeriodCodeIn, wExpType = 'I', wExpGroup = 'RCRM', wDeductType = 'DC', wPrtPage = 0, wPrtRow = 0,
                        wTotSetAmt = 0, wUpdBy = tmp.wUpdBy, wUpdDt = @vNow, wRefRid = tmp.wBookingRid, wReferId = tmp.wBookingRid, wExpSite = '',
                        wReferUpdBy = '', wEliteCodeIn = '', wSettleInstantTranNo = '', wIsAdj = 'N', wForeignTranRefNo = '',
                        wFxRateHKD = 1, wFxRateRMB = 1, 
                        wExpDesc = N'',
                        wExtUpdBy = ISNULL(u.wCName, ''), wInvoiceDateTime_CRM = b.wExpDt, 
                        wAmountActual_CRM = CASE tmp.wBookingStatus WHEN 'RF' THEN -1 ELSE 1 END * tmp.wTotalAmt, 
                        wCardNo_CRM = '', 
                        wAuthorizer_CRM = aAuth.wCName, wExpCategory = N'', wGuid = '', wRequestAgentCodeIn = b.wReqAgentCodeIn,
                        wIsDeposit = 'N', wIsDepositDone = 'N', wProductCategory = '', wProductDetail = ''
                    FROM
                        #sDataSet_SetAdditionalExpense tmp
                    LEFT JOIN
                        dbo.eAdditionalExpense ae ON (CASE WHEN @pIsRelatedRefRid='Y'  THEN ae.wBookingRefRid ELSE ae.wBookingRid END) = (CASE WHEN @pIsRelatedRefRid='Y'  THEN tmp.wBookingRefRid ELSE tmp.wBookingRid END) AND ae.wStatus = 'A'
                    INNER JOIN
                        dbo.eBooking b ON (CASE WHEN @pIsRelatedRefRid='Y' THEN tmp.wBookingRefRid ELSE tmp.wBookingRid END)= b.RowID
                    INNER JOIN
                        RollsMary.dbo.mAgent a ON b.wDebitAgentCodeIn = a.wAgentCodeIn
                    LEFT JOIN
                        RollsMary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                    LEFT JOIN
                        dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                    LEFT JOIN
                        RollsMary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo AND c.wCageCode = '001' AND c.wStatus = 'A'
                    LEFT JOIN
                        RollsMary.dbo.mUsr u ON tmp.wUpdBy = u.RowID
                    WHERE
                        (
                            (tmp.wBookingStatus = 'C' AND ISNULL(ae.wBookingStatus, 'P') != 'C')
                        OR
                            (tmp.wBookingStatus = 'RF' AND ISNULL(ae.wBookingStatus, 'P') != 'RF')
                        )
                    FOR XML RAW('Record'), ROOT ('DataSet')
                )
                
                IF @vXMLInsertExp != '' BEGIN
                    EXEC spa.SetCrmExpTran 
                        @pXML = @vXMLInsertExp, -- xml
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
            ---------------------------------------------------------------------------------------------
            -- End Sync Expense
            ---------------------------------------------------------------------------------------------

                    IF @pActionType = 'I'  
                        BEGIN  
                        -- Set RowID by Sequence  
                        UPDATE  #sDataSet_SetAdditionalExpense
                            SET RowID = 0,wSeqNo = 0;
                        SELECT  @sRecCount = COUNT(*)  
                        FROM    #sDataSet_SetAdditionalExpense;  
                        WHILE @sRuningIndex <= @sRecCount  
                            BEGIN
                                EXEC spq.GetRowID @pMainCompNo, @sThisTableName,@sRowID OUTPUT;  
       
                        IF @sSeqNo = 0
                        BEGIN  
                            Select @sSeqNo = ISNULL(MAX(wSeqNo),1) From dbo.eAdditionalExpense   
                            SET @sSeqNo = @sSeqNo + 1  
                        END  
                        ELSE  
                        BEGIN  
                            SET @sSeqNo = @sSeqNo + 1  
                        END  
                        UPDATE  #sDataSet_SetAdditionalExpense  
                                SET RowID = @sRowID,  
                                    --wBookingRefRid = @pBookingRId,  
                                    --wBookingRid = @pBookingRId,  
                                    wSeqNo = @sSeqNo  
                                WHERE   wRowNum = @sRuningIndex;  
                            SET @sRuningIndex = @sRuningIndex + 1;  
                        END;                
                        -- MAIN Logic here, example here is inserting dataset to eIOUPenalty  
                        INSERT  INTO dbo.[eAdditionalExpense]
                        (
                            RowID,  
                            wOrderNo,
                            wBookingRefRid,  
                            wBookingRid,  
                            wRoomBookingRid,
                            wExpenseType,  
                            wExpenseSubtype,  
                            wPaymentMethod,  
                            wReceiptNo,  
                            wExpAmt,  
                            wTotalAmt,  
                            wCost,  
                            wCurrcode,  
                            wIsUseBlackCard,  
                            wRemark,  
                            wBookingStatus,  
                            wUnqualifiedRid,  
                            wSeqNo,  
                            wCrtDt,  
                            wCrtBy,  
                            wUpdDt,  
                            wUpdBy,
                            wSpaRid,
                            wRestaurantRid,
                            wTravelAgencyRid,
                            wPersonRid
                        )  
                            SELECT  
                            s.RowID,  
                            s.wOrderNo,  
                            s.wBookingRefRid, 
                            s.wBookingRid ,
                            --CASE WHEN s.wBookingRid = 0 THEN s.wBookingRefRid ELSE s.wBookingRid END,  
                            s.wRoomBookingRid,
                            s.wExpenseType,  
                            s.wExpenseSubtype,  
                            s.wPaymentMethod,  
                            s.wReceiptNo,  
                            s.wExpAmt,  
                            s.wTotalAmt,  
                            s.wCost,  
                            s.wCurrcode,  
                            s.wIsUseBlackCard,  
                            s.wRemark,  
                            s.wBookingStatus,  
                            ISNULL(s.wUnqualifiedRid, 0),  
                            s.wSeqNo,  
                            dbo.fnUTC8Now(),  
                            s.wUpdBy,  
                            dbo.fnUTC8Now(),  
                            s.wUpdBy,
                            s.wSpaRid,
                            s.wRestaurantRid,
                            s.wTravelAgencyRid,
                            s.wPersonRid
                            FROM    #sDataSet_SetAdditionalExpense s;						 
                        END;
                    ELSE IF @pActionType = 'U'  
                        BEGIN
                        UPDATE ae
                            SET
                            ae.wOrderNo = tmp.wOrderNo,
                            ae.wExpenseType = tmp.wExpenseType,
                            ae.wExpenseSubtype = tmp.wExpenseSubtype,
                            ae.wPaymentMethod = tmp.wPaymentMethod,  
                            ae.wReceiptNo = tmp.wReceiptNo,
                            ae.wExpAmt = tmp.wExpAmt,
                            ae.wTotalAmt = tmp.wTotalAmt,
                            ae.wCost = tmp.wCost,
                            ae.wCurrcode = tmp.wCurrcode,
                            ae.wIsUseBlackCard = tmp.wIsUseBlackCard,
                            ae.wRemark = tmp.wRemark,
                            ae.wBookingStatus = tmp.wBookingStatus,
                            ae.wUnqualifiedRid = isnull(tmp.wUnqualifiedRid, 0),
                            ae.wUpdDt = dbo.fnUTC8Now(),  
                            ae.wUpdBy = tmp.wUpdBy,
                            ae.wSpaRid = tmp.wSpaRid,
                            ae.wRestaurantRid = tmp.wRestaurantRid,
                            ae.wTravelAgencyRid = tmp.wTravelAgencyRid,
                            ae.wPersonRid = tmp.wPersonRid
                            FROM [dbo].[eAdditionalExpense] AS ae
                            INNER JOIN #sDataSet_SetAdditionalExpense tmp ON (CASE WHEN @pIsRelatedRefRid='Y' AND ae.wBookingRefRid > 0 THEN ae.wBookingRefRid ELSE ae.wBookingRid END) = (CASE WHEN @pIsRelatedRefRid='Y' AND ae.wBookingRefRid > 0 THEN tmp.wBookingRefRid ELSE tmp.wBookingRid END)
                            WHERE  (CASE WHEN @pIsRelatedRefRid='Y' AND ae.wBookingRefRid > 0 THEN ae.wBookingRefRid ELSE ae.wBookingRid END) = (CASE WHEN @pIsRelatedRefRid='Y' AND ae.wBookingRefRid > 0 THEN tmp.wBookingRefRid ELSE tmp.wBookingRid END);
                        END
                    ELSE IF @pActionType = 'D'
                        BEGIN
                            UPDATE ae
                            SET 
                            ae.wBookingStatus = 'DL',
                            ae.wStatus = 'T',
                            ae.wUpdDt = dbo.fnUTC8Now(),  
                            ae.wUpdBy = tmp.wUpdBy
                            FROM [dbo].[eAdditionalExpense] AS ae
                            INNER JOIN #sDataSet_SetAdditionalExpense tmp ON ae.RowID = tmp.RowID
                        END

            ---------------------------------------------------------------------------------------------
            -- SetActionAffectedTableLog
            ---------------------------------------------------------------------------------------------
            SET @sActionAffectedXML = (
                SELECT
                    wActionSp = OBJECT_NAME(@@PROCID), wActionType = @pActionType, wNonceToken = @pNonceToken, 
                    wRefTableName = @sThisTableName, wRefRid = tmp.RowID, wType = '', wCrtDt = @vNow
                FROM
                    #sDataSet_SetAdditionalExpense tmp
                FOR XML RAW('Record'), ROOT('DataSet')
            );
            EXEC spa.SetActionAffectedTableLog @sActionAffectedXML, 'I', @pMainCompNo, '', 0, ''


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
            
            SET  @vErrorNum = ERROR_NUMBER();
            SET  @vCatchErrorMessage = ERROR_MESSAGE();
            SET  @xstate = XACT_STATE();
            SET  @vProcedureName = OBJECT_NAME(@@PROCID);
            
            IF ISNULL(@pErrCode, 0) = 0
                BEGIN
                    SET @pErrCode = 999;
                END;
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @vErrorNum, ') ',
                                  @vCatchErrorMessage);
            
            IF @sBeginTranCount = 0 BEGIN
                IF @xstate != 0
                    ROLLBACK;
                EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT, @vErrMessageLog OUTPUT;
            END
            ELSE
                THROW;

        END CATCH;
    
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetAdditionalExpense') IS NOT NULL DROP TABLE #sDataSet_SetAdditionalExpense
    END;