CREATE PROCEDURE [spa].[SetBookingFerry]
(
    @pXML XML ,
    @pActionType CHAR(1) , -- I/U/D
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pReturnResultSet CHAR(1) = 'N' ,
    @pBookingRId BIGINT ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
)
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sThisTableName VARCHAR(50) = 'eBookingFerry' , -- For RowID
                @sBeginTranCount INT = 0 ,
                @sRecCount INT = 0 ,
                @sRuningIndex INT = 1 ,
                @sRowID BIGINT = 0 ,
                @sTicketNo INT = 0 ,
                @vNow DATETIME2 = dbo.fnUTC8Now() ,
                @sActionAffectedXML NVARCHAR(MAX) = '' ,
                @sXMLeGift NVARCHAR(MAX) = '' ,
                @sCageCodeIn VARCHAR(14) ,
                @vMthEndYearMth VARCHAR(6) ,
                @vDateUsingCRM DATETIME2 ,
                @sDocHandle INT;			
          
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );

        SET @sBeginTranCount = @@trancount;

        SET @sCageCodeIn = (
            SELECT TOP (1) c.wCageCodeIn
            FROM dbo.eBooking b
            INNER JOIN dbo.mServiceCounter sc ON sc.RowID = b.wDebitCounterRid
            INNER JOIN RollsMary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo AND c.wCageCode = '001' AND c.wStatus = 'A'
            WHERE  b.RowID = @pBookingRId
        );
       
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;	

        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
            *
        INTO    #sDataSet_SetBookingFerry
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
        WITH (
            RowID BIGINT ,
            wBookingRid BIGINT,
            wClassCd  VARCHAR(30) ,
            wTicketType  VARCHAR(30) ,
            wPaymentMethod  VARCHAR(30) ,
            wRouteRid BIGINT,
            wDepartDt DATETIME2(7),
            wCurrCode VARCHAR(6) ,
            wExpAmt NUMERIC(18,4),
            wQuantity INT,
            wTotalAmt NUMERIC(18,4),
            wCost NUMERIC(18,4),
            wRemark NVARCHAR(500),							
            wUpdBy BIGINT ,
            wUpdDt DATETIME2(7),
            wOrderNo NVARCHAR(20),
            wReceiptNo NVARCHAR(50),
            wUnitAmt NUMERIC(18,4),
            wSeqNo INT,
            wTicketId BIGINT,
            wBookingStatus VARCHAR(5),
            wUnqualifiedRid BIGINT,
            wUseBlackCard CHAR(1),
            wWaived CHAR(1),
            wTravelAgencyRid BIGINT,
            wOldBookingStatus VARCHAR(5),
            wURLType VARCHAR(10),
            wURLAddress NVARCHAR(200)
        );
        -- Aloha bad method, say need to update here
        UPDATE  #sDataSet_SetBookingFerry
        SET     wBookingRid = @pBookingRId
        WHERE   wBookingRid <= 0;

        
            /*
            --- Ferry Required Field Validation Start
            DECLARE @errorMsg VARCHAR(max);	
                IF  @pActionType IN ('I', 'U') BEGIN
                     SELECT  @errorMsg = CASE 
                                      WHEN RTRIM(ISNULL(ef.wPaymentMethod,'')) = '' THEN 'Payment Method is missing'
                                      WHEN RTRIM(ISNULL(ef.wOrderNo,'')) = ''  THEN 'Order No is Missing'
                                      WHEN ef.wRouteRid <= 0 THEN 'Route is Missing'
                                      WHEN RTRIM(ISNULL(ef.wTicketType,'')) = '' THEN 'Ticket Type is Missing'
                                      WHEN ef.wCost < 0 THEN 'Cost is Missing'
                                      WHEN RTRIM(ISNULL(ef.wCurrCode,'')) = '' THEN 'Currency is Missing'
                                      WHEN ef.wTotalAmt < 0 THEN 'Total amount is missing'
                                      WHEN ef.wExpAmt < 0 THEN 'Expense amount is Missing'

                                END
                    FROM #sDataSet_SetBookingFerry ef
                END
            IF @errorMsg <> ''
                THROW 50001, @errorMsg, 1;
            --- Ferry Required Field Validation end

            -- Ferry Status Management update Field Validation Start
            IF  @pActionType = 'U' BEGIN
             SELECT  @errorMsg = CASE
                                    When ef.wBookingStatus in ('C') AND  sb.wBookingStatus in ('P','CL','UQ') then lup.wTitle + ' status can not be changed to status code ' + sb.wBookingStatus
                                    When ef.wBookingStatus in ('RF') AND  sb.wBookingStatus in ('C','P','CL','UQ') then lup.wTitle + ' status can not be changed to status code ' + sb.wBookingStatus
                                    When ef.wBookingStatus in ('CL') AND  sb.wBookingStatus in ('C','P','RF','UQ') then lup.wTitle + ' status can not be changed to status code ' + sb.wBookingStatus									
                                    When ef.wBookingStatus in ('UQ') AND  sb.wBookingStatus in ('C','P','CL','RF') then lup.wTitle + ' status can not be changed to status code ' + sb.wBookingStatus
                                    When ef.wBookingStatus in ('P') AND  sb.wBookingStatus in ('RF','CO') then lup.wTitle + ' status can not be changed to status code ' + sb.wBookingStatus
                                    When ef.wBookingStatus in ('RF','CL','UQ') AND  ef.wBookingStatus <> sb.wBookingStatus then lup.wTitle + ' status can not be changed to status code ' + sb.wBookingStatus
                                    when ef.wCurrCode<>sb.wCurrCode then 'Can not be updated Currency when booking status is ' +lup.wTitle
                                    When ef.wBookingStatus in ('C') AND  ef.wPaymentMethod <> sb.wPaymentMethod then 'Can not be updated Payment method when booking status is ' +lup.wTitle 									

                                 END

            from eBookingFerry ef INNER JOIN
               #sDataSet_SetBookingFerry sb ON ef.wBookingRid=sb.wBookingRid
               INNER JOIN mLookUp lup ON lup.wCode = ef.wBookingStatus AND lup.wType = 'FERRY_STATUS' and lup.wlangCd='en-GB'
            END	
            ELSE IF @pActionType = 'DL' BEGIN
            SELECT  @errorMsg = CASE
                                  WHEN sb.wBookingStatus <> ('P') THEN 'Booking can not be deleted if it not "In-Progress"' 
                            END
            FROM eBookingFerry ef inner join
               #sDataSet_SetBookingFerry sb on ef.wBookingRid=sb.wBookingRid			   
        END

        IF @errorMsg <> ''
                THROW 50001, @errorMsg, 1;	
            -- Ferry Status Management update Field Validation End
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
            DECLARE @sBookingType VARCHAR(30) = 'FERRY';
            DECLARE @sCurrentBookingStatus VARCHAR(5); -- DB当前状态
            DECLARE @sOldBookingStatus VARCHAR(5); -- 上一次Get數據時的狀態
            DECLARE @sNewBookingStatus VARCHAR(5); -- Save订单新状态
            DECLARE @sLangCd VARCHAR(10) = 'zh-TW';
            SELECT
                @sCurrentBookingStatus = ebf.wBookingStatus, 
                @sOldBookingStatus = sbf.wOldBookingStatus,
                @sNewBookingStatus = sbf.wBookingStatus
            FROM dbo.eBookingFerry AS ebf 
            INNER JOIN #sDataSet_SetBookingFerry AS sbf ON sbf.RowID = ebf.RowID AND sbf.wBookingRid = ebf.wBookingRid
            WHERE ebf.wBookingRid = @pBookingRId;

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

                    ALTER TABLE #sDataSet_SetBookingFerry ADD 
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
                        FROM #sDataSet_SetBookingFerry tmp 
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
                    FROM    #sDataSet_SetBookingFerry tmp
                            LEFT JOIN dbo.eBookingFerry bf ON tmp.wBookingRid = bf.wBookingRid
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
                                FROM    #sDataSet_SetBookingFerry tmp
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
                                                        wExpTypeCode = 'SHIP' ,
                                                        wExpTargetCode = '' ,
                                                        wExpCode = 'SHIP' ,
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
                                                                 END * CASE WHEN ISNULL(tmp.wPaymentMethod, '') IN ( 'DA', 'GC', 'ST-CASH', 'ST-AP', 'ST-BT', 'ST-CC' ) THEN tmp.wUnitAmt
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
                                                        wRemark = CONCAT(N'船票預訂: ', b.wRefNo, CASE tmp.wBookingStatus
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
                                               FROM     #sDataSet_SetBookingFerry tmp
                                                        LEFT JOIN dbo.eBookingFerry bf ON tmp.wBookingRid = bf.wBookingRid
                                                                                          AND bf.wStatus = 'A'
                                                        INNER JOIN dbo.eBooking b ON tmp.wBookingRid = b.RowID
                                                        INNER JOIN RollsMary.dbo.mAgent a ON b.wDebitAgentCodeIn = a.wAgentCodeIn
                                                        LEFT JOIN RollsMary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                                        INNER JOIN dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                                                        LEFT JOIN RollsMary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                                                           AND c.wCageCode = '001'
                                                                                           AND c.wStatus = 'A'
                                                        LEFT JOIN RollsMary.dbo.mUsr u ON tmp.wUpdBy = u.RowID
                                               WHERE    ( ( tmp.wBookingStatus = 'C'
                                                            AND ISNULL(bf.wBookingStatus, 'P') != 'C'
                                                          )
                                                          OR ( tmp.wBookingStatus = 'RF'
                                                               AND ISNULL(bf.wBookingStatus, 'P') != 'RF'
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
                UPDATE tmp SET RowID = bf.RowID FROM #sDataSet_SetBookingFerry tmp INNER JOIN dbo.eBookingFerry bf ON tmp.wBookingRid = bf.wBookingRid WHERE tmp.RowID <= 0;

                IF @vNow >= @vDateUsingCRM
                -- Changed Status From CONFIRM TO REFUND, VOID expense tran
                SET @vXMLRefundExp = (
                    SELECT 
                        RowID = 0, wCompNo = sc.wRollexCompNo, wCageCodeIn = c.wCageCodeIn, wTranNo = '', wDate = tmp.wDate,
                        wCurDateTime = @vNow, wShift = tmp.wShift, wAgentCodeIn = b.wDebitAgentCodeIn, wCardCodeIn = '', wCustName = ISNULL(a.wCName, ''),
                        wShopName = '', wExpTypeCode = 'SHIP', wExpTargetCode = '', wExpCode = 'SHIP', wExpSubCode1 = '', wCurCode = tmp.wCurrCode,
                        wRoomNo = '', wRoomCfmCode = '', wRoomBookDt = NULL, wRoomCheckInDt = NULL, wRoomDeptDt = NULL, wNight = 0, wUnit = (-1 * tmp.wQuantity),
                        wPrice = tmp.wUnitAmt, wRoomExpAmt = 0, wAmount = (-1 * tmp.wTotalAmt), wExpLocation = sc.wDefaultHotelCode, wVoucherNo = '', wVoucherDt = NULL,
                        wRemark = CONCAT(N'船票預訂編號: ', b.wRefNo, N' 退款'), 
                        wPeriodCodeIn = tmp.wPeriodCodeIn, wExpType = 'I', wExpGroup = 'CRM', wDeductType = 'DC', wPrtPage = 0, wPrtRow = 0,
                        wTotSetAmt = 0, wUpdBy = tmp.wUpdBy, wUpdDt = @vNow, wRefRid = tmp.wBookingRid, wReferId = tmp.wBookingRid, wExpSite = '',
                        wReferUpdBy = '', wEliteCodeIn = '', wSettleInstantTranNo = '', wIsAdj = 'N', wForeignTranRefNo = '',
                        wFxRateHKD = 1, wFxRateRMB = 1, 
                        wExpDesc = N'',
                        wExtUpdBy = ISNULL(u.wCName, ''), wInvoiceDateTime_CRM = b.wExpDt, wAmountActual_CRM = (-1 * tmp.wExpAmt), wCardNo_CRM = '', 
                        wAuthorizer_CRM = aAuth.wCName, wExpCategory = N'行', wGuid = '', wRequestAgentCodeIn = b.wReqAgentCodeIn,
                        wIsDeposit = 'N', wIsDepositDone = 'N', wProductCategory = '', wProductDetail = ''
                    FROM
                        #sDataSet_SetBookingFerry tmp
                    INNER JOIN
                        dbo.eBookingFerry bh ON tmp.RowID = bh.RowID
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
                        tmp.wBookingStatus = 'RF' AND bh.wBookingStatus = 'C' AND tmp.wPaymentMethod IN ('DA')
                    FOR XML RAW('Record'), ROOT ('DataSet')
                )

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
                        FROM #sDataSet_SetBookingFerry tmp
                        INNER JOIN dbo.eBookingFerry bf ON tmp.wBookingRid = bf.wBookingRid
                        WHERE ((tmp.wBookingStatus = 'C' AND ISNULL(bf.wBookingStatus, 'P') != 'C')
                               OR (tmp.wBookingStatus = 'RF' AND ISNULL(bf.wBookingStatus, 'P') != 'RF')
                               OR (tmp.wBookingStatus = 'C' AND bf.wBookingStatus = 'C')
                               OR (tmp.wBookingStatus = 'RF' AND bf.wBookingStatus = 'RF'))
                           AND (tmp.wPaymentMethod = 'GC'  OR tmp.wPaymentMethod = 'GC0' ))
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
                                                '0223' AS wSubType , --船票
                                                wRemark = CASE WHEN (g.RowID IS NULL OR tmp.wRemark != bf.wRemark) THEN tmp.wRemark ELSE g.wRemark END,
                                                b.wEventCodeRid AS wEventCodeRid ,
                                                wStatus = CASE WHEN g.RowID IS NULL THEN 'A' ELSE g.wStatus END,
                                                wCrtDt = CASE WHEN g.RowID IS NULL THEN @vNow ELSE g.wCrtDt END, -- set sp should not update this field when update
                                                wCrtBy = CASE WHEN g.RowID IS NULL THEN tmp.wUpdBy ELSE g.wCrtBy END, -- in set sp should not update this field when update
                                                @vNow AS wUpdDt ,
                                                tmp.wUpdBy ,
                                                CASE WHEN ((tmp.wBookingStatus = 'C' AND ISNULL(bf.wBookingStatus, 'P') != 'C')
                                                            OR (tmp.wBookingStatus = 'RF' AND ISNULL(bf.wBookingStatus, 'P') != 'RF'))
                                                          --AND ISNULL(g.wRefTableRid, 0) <= 0 
                                                THEN 'I'
                                                ELSE 'U'
                                                END AS RecordState ,
                                                b.wGiftReasonCd AS wReasonCd ,
                                                wIsReceived = CASE WHEN g.RowID IS NULL THEN 'Y' ELSE g.wIsReceived END, -- 經由booking 產生的送禮記錄要預設為 "已接收"
                                                tmp.wCost
                                     FROM #sDataSet_SetBookingFerry tmp
                                     INNER JOIN dbo.eBookingFerry bf ON tmp.wBookingRid = bf.wBookingRid AND bf.wStatus = 'A' AND (tmp.wPaymentMethod = 'GC' OR tmp.wPaymentMethod = 'GC0')
                                     INNER JOIN dbo.eBooking b ON b.RowID = tmp.wBookingRid
                                     INNER JOIN dbo.mServiceCounter sc ON sc.RowID = b.wReqCounterRid
                                     LEFT JOIN eGift g ON g.wRefTableRid = tmp.wBookingRid AND g.wStatus = 'A' AND ((tmp.wBookingStatus = 'C' AND bf.wBookingStatus = 'C') OR (tmp.wBookingStatus = 'RF' AND bf.wBookingStatus = 'RF')) -- 只有Update才能Join到舊數據
                                     INNER JOIN RollsMary.dbo.mAgent a ON a.wAgentCodeIn = b.wApprovalAgentCodeIn AND a.wStatus = 'A'
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
                    UPDATE  #sDataSet_SetBookingFerry
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetBookingFerry;

                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
                    
                            IF @sTicketNo = 0
                                BEGIN
                                    SELECT  @sTicketNo = ISNULL(MAX(wTicketId), 1000000)
                                    FROM    dbo.eBookingFerry; 
                                    SET @sTicketNo = @sTicketNo + 1;	
                                END;
                            ELSE
                                SET @sTicketNo = @sTicketNo + 1;	

                            UPDATE  #sDataSet_SetBookingFerry
                            SET     RowID = @sRowID ,
                                    wBookingRid = @pBookingRId ,
                                    wTicketId = @sTicketNo
                            WHERE   wRowNum = @sRuningIndex;

                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
                
                -- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[eBookingFerry]
                            ( [RowID] ,
                              [wBookingRid] ,
                              [wClassCd] ,
                              [wTicketType] ,
                              [wPaymentMethod] ,
                              [wRouteRid] ,
                              [wDepartDt] ,
                              [wCurrCode] ,
                              [wExpAmt] ,
                              [wQuantity] ,
                              [wTotalAmt] ,
                              [wCost] ,
                              [wRemark] ,
                              [wCrtBy] ,
                              [wCrtDt] ,
                              [wUpdBy] ,
                              [wUpdDt] ,
                              [wOrderNo] ,
                              [wReceiptNo] ,
                              [wUnitAmt] ,
                              [wSeqNo] ,
                              [wTicketId] ,
                              [wBookingStatus] ,
                              [wUnqualifiedRid] ,
                              [wUseBlackCard] ,
                              [wWaived] ,
                              [wTravelAgencyRid],
                              [wURLType],
                              [wURLAddress]
                            )
                            SELECT  s.RowID ,
                                    s.wBookingRid ,
                                    s.wClassCd ,
                                    s.wTicketType ,
                                    s.wPaymentMethod ,
                                    s.wRouteRid ,
                                    s.wDepartDt ,
                                    s.wCurrCode ,
                                    s.wExpAmt ,
                                    s.wQuantity ,
                                    s.wTotalAmt ,
                                    s.wCost ,
                                    s.wRemark ,
                                    s.wUpdBy ,
                                    @vNow ,
                                    s.wUpdBy ,
                                    @vNow ,
                                    s.wOrderNo ,
                                    s.wReceiptNo ,
                                    s.wUnitAmt ,
                                    s.wSeqNo ,
                                    s.wTicketId ,
                                    CASE WHEN ISNULL(s.wBookingStatus, '') = '' THEN 'P' ELSE s.wBookingStatus END,
                                    ISNULL(s.wUnqualifiedRid, 0) ,
                                    s.wUseBlackCard ,
                                    s.wWaived ,
                                    ISNULL(s.wTravelAgencyRid, 0),
                                    s.wURLType,
                                    s.wURLAddress
                            FROM    #sDataSet_SetBookingFerry s;

                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  met
                        SET     met.wBookingRid = tmp.wBookingRid ,
                                met.wClassCd = tmp.wClassCd ,
                                met.wTicketType = tmp.wTicketType ,
                                met.wPaymentMethod = tmp.wPaymentMethod ,
                                met.wRouteRid = tmp.wRouteRid ,
                                met.wDepartDt = tmp.wDepartDt ,
                                met.wCurrCode = tmp.wCurrCode ,
                                met.wExpAmt = tmp.wExpAmt ,
                                met.wQuantity = tmp.wQuantity ,
                                met.wTotalAmt = tmp.wTotalAmt ,
                                met.wCost = tmp.wCost ,
                                met.wRemark = tmp.wRemark ,
                                met.wUpdBy = tmp.wUpdBy ,
                                met.wUpdDt = @vNow ,
                                met.wOrderNo = tmp.wOrderNo ,
                                met.wReceiptNo = tmp.wReceiptNo ,
                                met.wUnitAmt = tmp.wUnitAmt ,
                                met.wSeqNo = tmp.wSeqNo ,
                                met.wBookingStatus = CASE WHEN ISNULL(tmp.wBookingStatus, '') = '' THEN met.wBookingStatus ELSE tmp.wBookingStatus END ,
                                met.wUnqualifiedRid = ISNULL(tmp.wUnqualifiedRid, 0) ,
                                met.wUseBlackCard = tmp.wUseBlackCard ,
                                met.wWaived = tmp.wWaived ,
                                met.wTravelAgencyRid = ISNULL(tmp.wTravelAgencyRid, 0),
                                met.wURLType  = tmp.wURLType  ,
                                met.wURLAddress  = tmp.wURLAddress  
                        FROM    dbo.eBookingFerry AS met
                                INNER JOIN #sDataSet_SetBookingFerry tmp ON met.[wBookingRid] = tmp.[wBookingRid]
                        WHERE   met.wBookingRid = tmp.wBookingRid;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN
                    --UPDATE dbo.eBookingFerry
                    --SET
                    --wStatus ='CL'
                    -- Where  RowID IN (SELECT RowID FROM #sDataSet_SetBookingFerry);
                            UPDATE  ebf
                            SET     ebf.wBookingStatus = 'DL' ,
                                    ebf.wStatus = 'T' ,
                                    ebf.wUpdDt = @vNow ,
                                    ebf.wUpdBy = tmp.wUpdBy
                            FROM    dbo.eBookingFerry AS ebf
                                    INNER JOIN #sDataSet_SetBookingFerry tmp ON ebf.RowID = tmp.RowID;
                    
                            DECLARE @BookingRid BIGINT = ( SELECT TOP 1
                                                                    wBookingRid
                                                           FROM     #sDataSet_SetBookingFerry
                                                         );

                            UPDATE  ePassengerDetails
                            SET     wPassengerBookingStatus = 'T' ,
                                    wStatus = 'T'
                            WHERE   wBookingRid = @BookingRid
                                    AND wPassengerBookingStatus = 'A';
                        END;   

            ---------------------------------------------------------------------------------------------
            -- Activity Log
            ---------------------------------------------------------------------------------------------
            DECLARE @vActivityLogXML AS NVARCHAR(MAX) = '';

            IF @pActionType = 'I'
                OR @pActionType = 'U'
                BEGIN
                    SET @vActivityLogXML = ( SELECT RowID = 0 ,
                                                    wAction = @pActionType ,
                                                    wReqAgentCodeIn = b.wReqAgentCodeIn ,
                                                    wBookingRid = tmp.wBookingRid ,
                                                    wCategory = @sThisTableName ,
                                                    wRemark = CONCAT(CASE WHEN tmp.wBookingStatus = 'RF' THEN N'<退票>'
                                                                     END, CASE WHEN ISNULL(tmp.wReceiptNo, '') != '' THEN CONCAT(N'現金單號#', tmp.wReceiptNo, ', ')
                                                                          END, CONCAT(r.wRouteFrom, CASE WHEN r.wIsTwoWay = 'Y' THEN '<->'
                                                                                                         ELSE N'>'
                                                                                                    END, r.wRouteTo, ', '), l.wTitle, ', ', CASE WHEN tmp.wDepartDt IS NOT NULL THEN CONCAT(FORMAT(tmp.wDepartDt, 'yyyy-mm-dd'), ', ')
                                                                                                                                            END, CONCAT(N'代訂人: ', b.wAsstBooker, N', 電話: ', b.wAssBookerTel), '(', b.wRefNo, ')') ,
                                                    wIsLatest = 'Y' ,
                                                    wIsComplete = 'N' ,
                                                    wCrtDt = @vNow ,
                                                    wCrtBy = tmp.wUpdBy ,
                                                    wUpdDt = @vNow ,
                                                    wUpdBy = tmp.wUpdBy
                                             FROM   #sDataSet_SetBookingFerry tmp
                                                    INNER JOIN dbo.eBooking b ON tmp.wBookingRid = b.RowID
                                                    LEFT JOIN dbo.mRoute r ON tmp.wRouteRid = r.RowID
                                                    LEFT JOIN dbo.mLookUp l ON tmp.wClassCd = l.wCode
                                                                               AND l.wType = 'FERRY_CLASS'
                                                                               AND l.wLangCd = 'zh-TW'
                                           FOR
                                             XML RAW('Record') ,
                                                 ROOT('DataSet')
                                           );
                END;

            IF @vActivityLogXML != ''
                BEGIN
                    EXEC spa.SetActivityLog @pXML = @vActivityLogXML, -- xml
                        @pActionType = 'I', -- char(1)
                        @pMainCompNo = @pMainCompNo, -- int
                        @pNonceToken = @pNonceToken, -- varchar(64)
                        @pReturnResultSet = 'N', -- char(1)
                        @pErrCode = 0, -- int
                        @pErrMsg = ''; -- nvarchar(200)
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
                                        FROM    #sDataSet_SetBookingFerry tmp
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
                FROM    #sDataSet_SetBookingFerry;

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

        IF OBJECT_ID('tempdb..#sDataSet_SetBookingFerry') IS NOT NULL
            DROP TABLE #sDataSet_SetBookingFerry;

        IF OBJECT_ID('tempdb..#s_Period') IS NOT NULL
            DROP TABLE #s_Period;
    END;