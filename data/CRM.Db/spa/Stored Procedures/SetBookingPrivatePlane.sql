CREATE PROCEDURE [spa].[SetBookingPrivatePlane]
    (
      @pXML XML ,
      @pActionType CHAR(1) ,  -- I/U/D            
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pBookingRId BIGINT ,
      @pBookingPrivatePlaneRid BIGINT OUTPUT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT      
    )
AS
    BEGIN                            
        SET NOCOUNT ON;
      
        DECLARE @sThisTableName VARCHAR(50)   = 'eBookingPrivatePlane' , -- For RowID                            
            @sBeginTranCount INT           = 0 ,
            @sRecCount INT           = 0 ,
            @sRuningIndex INT           = 1 ,
            @sRowID BIGINT        = 0 ,
            @vNow DATETIME2     = dbo.fnUTC8Now() ,
            @sActionAffectedXML NVARCHAR(MAX) = '' ,
            @sXMLeGift NVARCHAR(MAX) = '' ,
            @sCageCodeIn VARCHAR(14) ,
            @sDocHandle INT ,
            @vMthEndYearMth VARCHAR(6) ,
            @vDateUsingCRM DATETIME2 ,
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
                             WHERE  b.RowID = @pBookingRId
                           );
                                  
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;                           
                                                        
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetBookingPrivatePlane
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)                            
     WITH (                            
            RowID BIGINT,            
            wBookingRid BIGINT,            
            wDepartCity NVARCHAR(50),            
            wPlaneModel NVARCHAR(50),            
            wSupplier NVARCHAR(50),            
            wHotelRid BIGINT,            
            wTravelAgencyRid BIGINT,            
            wSeatNo VARCHAR(10),            
            wOrderNo NVARCHAR(20),            
            wIsSmoking CHAR(2),            
            wServiceLang NVARCHAR(50),            
            wHasWifi CHAR(2),            
            wNoOfServiceStaff INT,            
            wExpAmt NUMERIC(18,4),            
            wTotalAmt NUMERIC(18,4),            
            wPaymentMethod VARCHAR(30),            
            wReceiptNo NVARCHAR(50),            
            wCurrCode VARCHAR(10),            
            wExtraFee NUMERIC(18,4),            
            wConfirmPassengerNo NVARCHAR(50),            
            wRemark NVARCHAR(500),            
            wChangeOrderCount INT,            
            wBookingStatus VARCHAR(5),
            wUnqualifiedRid BIGINT,            
            wCrtDt DATETIME2,            
            wCrtBy BIGINT,            
            wUpdDt DATETIME2,            
            wUpdBy BIGINT,      
            wBookingNo VARCHAR(20),      
            wCancelDt DATETIME2(7),      
            wCancelReason NVARCHAR(500),
            wBookingType VARCHAR(30),
            wIsUseBlackCard CHAR(1),
            wTotalCost NUMERIC(18,4),
            wOldBookingStatus VARCHAR(5)
        ); 
        
/*
        IF @pActionType IN ('I', 'U') BEGIN				 
            SELECT  @pErrMsg = case 
                                  when eb.wPaymentMethod = ''  then 'Payment Method is Missing' 
                                  when RTRIM(ISNULL(eb.wBookingType,'')) = '' then 'BookingType is Missing'
                                  when RTRIM(ISNULL(eb.wSupplier,'')) = '' then 'Supplier is Missing'
                                  when RTRIM(ISNULL(eb.wCurrCode,'')) = '' then 'Currency is Missing'
                                  when RTRIM(ISNULL(eb.wBookingStatus,'')) = ''  then 'BookingStatus is Missing'														 
                            end
           FROM #sDataSet_SetBookingPrivatePlane eb;
           IF @pErrMsg <> '' THROW 50001, @pErrMsg, 1;	
        END
            
        IF @pActionType='U'
        BEGIN
        SELECT @pErrMsg =
            CASE WHEN EBPP.wTotalCost <> tmp.wTotalCost THEN 'Can not be updated Total Cost when booking status code is ' + EBPP.wBookingStatus
             WHEN EBPP.wBookingStatus IN ('RF','CL','DL','UQ') AND EBPP.wConfirmPassengerNo <> tmp.wConfirmPassengerNo THEN 'Can not be updated debit sevice Counter  when booking status code is ' + EBPP.wBookingStatus    
             WHEN EBPP.wCurrCode <> tmp.wCurrCode THEN 'Can not be updated account requested when booking status code is ' + EBPP.wBookingStatus
             WHEN EBPP.wReceiptNo <> tmp.wReceiptNo THEN 'Can not be updated debit account requested  when booking status code is '+ EBPP.wBookingStatus
             WHEN EBPP.wPaymentMethod <> tmp.wPaymentMethod THEN 'Can not be updated requested cutomer when booking status code is '+ EBPP.wBookingStatus
             WHEN EBPP.wTotalAmt <> tmp.wTotalAmt THEN 'Can not be updated debit cutomer when booking status code is '+ EBPP.wBookingStatus
             WHEN EBPP.wExpAmt <> tmp.wExpAmt  THEN 'Can not be updated requested department when booking status code is '+ EBPP.wBookingStatus
             WHEN EBPP.wNoOfServiceStaff <> tmp.wNoOfServiceStaff THEN 'Can not be updated requested user when booking status code is '+ EBPP.wBookingStatus
             WHEN EBPP.wHasWifi <> tmp.wHasWifi THEN 'Can not be updated asist booker when booking status code is '+ EBPP.wBookingStatus
             WHEN EBPP.wBookingStatus IN ('RF','CL','DL','UQ') AND EBPP.wServiceLang <> tmp.wServiceLang THEN 'Can not be updated asist booker phone when booking status code is '+ EBPP.wBookingStatus
             WHEN EBPP.wBookingStatus IN ('RF','CL','DL','UQ') AND EBPP.wIsSmoking <> tmp.wIsSmoking THEN 'Can not be updated Owner when booking status code is '+ EBPP.wBookingStatus
             WHEN EBPP.wBookingStatus IN ('RF','CL','DL','UQ') AND EBPP.wOrderNo <> tmp.wOrderNo  THEN 'Can not be updated debit date  when booking status code is '+ EBPP.wBookingStatus
             WHEN EBPP.wTravelAgencyRid <> tmp.wTravelAgencyRid  THEN 'Can not be updated Exp date when booking status code is '+ EBPP.wBookingStatus					
             WHEN EBPP.wHotelRid <> tmp.wHotelRid THEN 'Can not be updated asst Email  when booking status code is '+ EBPP.wBookingStatus
             WHEN EBPP.wSupplier <> ISNULL(tmp.wSupplier,'') THEN 'Can not be updated staff followed department when booking status code is '+ EBPP.wBookingStatus
             WHEN EBPP.wBookingStatus IN ('RF','CL','DL','UQ') AND EBPP.wPlaneModel <> ISNULL(tmp.wPlaneModel,-1) THEN 'Can not be updated staff followed  when booking status code is '+ EBPP.wBookingStatus
             WHEN EBPP.wBookingStatus IN ('RF','CL','DL','UQ') AND EBPP.wIsUseBlackCard <> ISNULL(tmp.wIsUseBlackCard,'') THEN 'Can not be updated staff phone  when booking status code is '+ EBPP.wBookingStatus
             WHEN EBPP.wBookingStatus IN ('RF','CL','DL','UQ') AND EBPP.wBookingStatus <> tmp.wBookingStatus THEN 'Booking status '+ EBPP.wBookingStatus + ' can not be updated to booking status code '+ tmp.wBookingStatus
             WHEN EBPP.wBookingStatus IN ('CO') AND tmp.wBookingStatus NOT IN ('CO','C') THEN 'Booking status '+ EBPP.wBookingStatus +' can not be updated to status code '+ tmp.wBookingStatus			 
             WHEN EBPP.wBookingStatus IN ('C') AND tmp.wBookingStatus IN ('CL','DL','UQ','P','',' ') THEN 'Booking status '+ EBPP.wBookingStatus +' can not be updated to status code '+ tmp.wBookingStatus
        END
        FROM (SELECT * FROM dbo.eBookingPrivatePlane WHERE wBookingRid=@pBookingRid
        AND wBookingStatus IN ('C','CO','DL','CL','RF','UQ')
        ) EBPP
        INNER JOIN #sDataSet_SetBookingPrivatePlane tmp ON tmp.RowID = EBPP.RowID;

        IF @pErrMsg <> '' THROW 50001, @pErrMsg, 1;	

        SELECT @pErrMsg =
            CASE 
            WHEN  EBPPS.wBookingStatus <> 'P' AND tmp.wBookingStatus NOT IN ('CO','RF',' ','') THEN EBPPS.wBookingStatus +' Can not be updated booking status to status code= '+ tmp.wBookingStatus
            END		
        FROM (SELECT * FROM dbo.eBookingPrivatePlane WHERE wBookingRid=@pBookingRid
        AND wBookingStatus IN ('P')
        ) EBPPS
        INNER JOIN #sDataSet_SetBookingPrivatePlane tmp ON tmp.RowID = EBPPS.RowID;

        IF @pErrMsg <> '' THROW 50001, @pErrMsg, 1;	
      END

      IF @pActionType = 'D'
      BEGIN
            SELECT  @pErrMsg = CASE  WHEN eb.wBookingStatus <> ('P') THEN 'Booking can not be deleted if it is not in "In-Progress"' END
            FROM eBookingPrivatePlane eb 
            INNER JOIN #sDataSet_SetBookingPrivatePlane sb on eb.wBookingRid=sb.wBookingRid			   
            IF @pErrMsg <> '' THROW 50001, @pErrMsg, 1;	
      END
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
                DECLARE @sBookingType VARCHAR(30) = 'PP';
                DECLARE @sCurrentBookingStatus VARCHAR(5); -- DB当前状态
                DECLARE @sOldBookingStatus VARCHAR(5); -- 上一次Get數據時的狀態
                DECLARE @sNewBookingStatus VARCHAR(5); -- Save订单新状态
                DECLARE @sLangCd VARCHAR(10) = 'zh-TW';
                SELECT
                    @sCurrentBookingStatus = ebpp.wBookingStatus, 
                    @sOldBookingStatus = sbpp.wOldBookingStatus,
                    @sNewBookingStatus = sbpp.wBookingStatus
                FROM dbo.eBookingPrivatePlane AS ebpp 
                INNER JOIN #sDataSet_SetBookingPrivatePlane AS sbpp ON sbpp.RowID = ebpp.RowID AND sbpp.wBookingRid = ebpp.wBookingRid
                WHERE ebpp.wBookingRid = @pBookingRId;

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

                    ALTER TABLE #sDataSet_SetBookingPrivatePlane ADD 
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
                        FROM #sDataSet_SetBookingPrivatePlane tmp 
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
                    FROM    #sDataSet_SetBookingPrivatePlane tmp
                            LEFT JOIN dbo.eBookingPrivatePlane bpp ON tmp.wBookingRid = bpp.wBookingRid
                                                                      AND bpp.wStatus = 'A'
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
                            AND ISNULL(bpp.wBookingStatus, 'P') != 'C'
                            OR tmp.wBookingStatus = 'RF'
                            AND ISNULL(bpp.wBookingStatus, 'P') != 'RF';
                
                -- Check is already Mth end or not	
                    IF EXISTS ( SELECT  1
                                FROM    #sDataSet_SetBookingPrivatePlane tmp
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
                                                        wExpTypeCode = 'TICKET 2' ,
                                                        wExpTargetCode = '1000000020' ,
                                                        wExpCode = '1000088653' ,
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
                                                        wRemark = CONCAT(N'私人飛機預訂: ', b.wRefNo, CASE tmp.wBookingStatus
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
                                               FROM     #sDataSet_SetBookingPrivatePlane tmp
                                                        LEFT JOIN dbo.eBookingPrivatePlane bh ON tmp.wBookingRid = bh.wBookingRid
                                                                                                 AND bh.wStatus = 'A'
                                                        LEFT JOIN dbo.eBooking b ON tmp.wBookingRid = b.RowID
                                                        LEFT JOIN RollsMary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                                        LEFT JOIN RollsMary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                                        LEFT JOIN dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                                                        LEFT JOIN RollsMary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                                                           AND c.wCageCode = '001'
                                                                                           AND c.wStatus = 'A'
                                                        LEFT JOIN RollsMary.dbo.mUsr u ON tmp.wUpdBy = u.RowID
                                               WHERE    ( ( tmp.wBookingStatus = 'C'
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
            ---------------------------------------------------------------------------------------------
            -- End Sync Expense
            ---------------------------------------------------------------------------------------------

            ---------------------------------------------------------------------------------------------
            -- Add eGift record
            ---------------------------------------------------------------------------------------------
            IF EXISTS ( SELECT 1
                        FROM #sDataSet_SetBookingPrivatePlane tmp
                        INNER JOIN dbo.eBookingPrivatePlane bpp ON tmp.wBookingRid = bpp.wBookingRid
                        WHERE ((tmp.wBookingStatus = 'C' AND ISNULL(bpp.wBookingStatus, 'P') != 'C')
                              OR (tmp.wBookingStatus = 'RF' AND ISNULL(bpp.wBookingStatus, 'P') != 'RF')
                              OR (tmp.wBookingStatus = 'C' AND bpp.wBookingStatus = 'C')
                              OR (tmp.wBookingStatus = 'RF' AND bpp.wBookingStatus = 'RF'))
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
                                                '0205' AS wSubType , --私人飛機
                                                wRemark = CASE WHEN (g.RowID IS NULL OR tmp.wRemark != bpp.wRemark) THEN tmp.wRemark ELSE g.wRemark END,
                                                b.wEventCodeRid AS wEventCodeRid ,
                                                wStatus = CASE WHEN g.RowID IS NULL THEN 'A' ELSE g.wStatus END,
                                                wCrtDt = CASE WHEN g.RowID IS NULL THEN @vNow ELSE g.wCrtDt END, -- set sp should not update this field when update
                                                wCrtBy = CASE WHEN g.RowID IS NULL THEN tmp.wUpdBy ELSE g.wCrtBy END, -- in set sp should not update this field when update
                                                @vNow AS wUpdDt ,
                                                tmp.wUpdBy ,
                                                CASE WHEN ((tmp.wBookingStatus = 'C' AND ISNULL(bpp.wBookingStatus, 'P') != 'C')
                                                          OR (tmp.wBookingStatus = 'RF' AND ISNULL(bpp.wBookingStatus, 'P') != 'RF'))
                                                          --AND ISNULL(g.wRefTableRid, 0) <= 0 
                                                THEN 'I'
                                                ELSE 'U'
                                                END AS RecordState ,
                                                b.wGiftReasonCd AS wReasonCd ,
                                                wIsReceived = CASE WHEN g.RowID IS NULL THEN 'Y' ELSE g.wIsReceived END, -- 經由booking 產生的送禮記錄要預設為 "已接收"
                                                tmp.wTotalCost AS wCost
                                     FROM #sDataSet_SetBookingPrivatePlane tmp
                                     INNER JOIN dbo.eBookingPrivatePlane bpp ON tmp.wBookingRid = bpp.wBookingRid AND bpp.wStatus = 'A' AND (tmp.wPaymentMethod = 'GC' OR tmp.wPaymentMethod = 'GC0')
                                     INNER JOIN dbo.eBooking b ON b.RowID = tmp.wBookingRid
                                     INNER JOIN dbo.mServiceCounter sc ON sc.RowID = b.wReqCounterRid
                                     LEFT JOIN eGift g ON g.wRefTableRid = tmp.wBookingRid AND g.wStatus = 'A' AND ((tmp.wBookingStatus = 'C' AND bpp.wBookingStatus = 'C') OR (tmp.wBookingStatus = 'RF' AND bpp.wBookingStatus = 'RF')) -- 只有Update才能Join到舊數據
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
                    UPDATE  #sDataSet_SetBookingPrivatePlane
                    SET     RowID = 0;                            
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetBookingPrivatePlane;                            
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN                            
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;     
                            UPDATE  #sDataSet_SetBookingPrivatePlane
                            SET     RowID = @sRowID ,
                                    wBookingRid = @pBookingRId
                            WHERE   wRowNum = @sRuningIndex;                            
                            SET @sRuningIndex = @sRuningIndex + 1;    
                            SET @pBookingPrivatePlaneRid = @sRowID;                     
                        END;                                          

  -- select * from dbo. [eBookingPrivatePlane]      
                    INSERT  INTO dbo.[eBookingPrivatePlane]
                            ( RowID ,
                              wBookingRid ,
                              wPlaneModel ,
                              wSupplier ,
                              wHotelRid ,
                              wTravelAgencyRid ,
                              wSeatNo ,
                              wOrderNo ,
                              wIsSmoking ,
                              wServiceLang ,
                              wHasWifi ,
                              wNoOfServiceStaff ,
                              wExpAmt ,
                              wTotalAmt ,
                              wPaymentMethod ,
                              wReceiptNo ,
                              wCurrCode ,
                              wExtraFee ,
                              wConfirmPassengerNo ,
                              wRemark ,
                              wChangeOrderCount ,
                              wBookingStatus ,
                              wUnqualifiedRid ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy ,
                              wBookingNo ,
                              wCancelDt ,
                              wCancelReason ,
                              wBookingType ,
                              wIsUseBlackCard ,
                              wTotalCost     
                            )
                            SELECT  s.RowID ,
                                    s.wBookingRid ,
                                    s.wPlaneModel ,
                                    s.wSupplier ,
                                    s.wHotelRid ,
                                    s.wTravelAgencyRid ,
                                    s.wSeatNo ,
                                    s.wOrderNo ,
                                    s.wIsSmoking ,
                                    s.wServiceLang ,
                                    s.wHasWifi ,
                                    s.wNoOfServiceStaff ,
                                    s.wExpAmt ,
                                    s.wTotalAmt ,
                                    s.wPaymentMethod ,
                                    s.wReceiptNo ,
                                    s.wCurrCode ,
                                    s.wExtraFee ,
                                    s.wConfirmPassengerNo ,
                                    s.wRemark ,
                                    s.wChangeOrderCount ,
                                    s.wBookingStatus ,
                                    ISNULL(s.wUnqualifiedRid, 0) ,
                                    dbo.fnUTC8Now() ,
                                    s.wCrtBy ,
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy ,
                                    s.wBookingNo ,
                                    s.wCancelDt ,
                                    s.wCancelReason ,
                                    s.wBookingType ,
                                    wIsUseBlackCard ,
                                    wTotalCost
                            FROM    #sDataSet_SetBookingPrivatePlane s;    
 --select * from dbo. [eBookingPrivatePlane]                          
                END;                         
            ELSE
                IF @pActionType = 'U'
                    BEGIN                        
                        UPDATE  bpp
                        SET     bpp.wOrderNo = tmp.wOrderNo ,
                                bpp.wIsSmoking = tmp.wIsSmoking ,
                                bpp.wTotalAmt = tmp.wTotalAmt ,
                                bpp.wCurrCode = tmp.wCurrCode ,
                                bpp.wChangeOrderCount = tmp.wChangeOrderCount ,
                                bpp.wCancelDt = tmp.wCancelDt ,
                                bpp.wCancelReason = tmp.wCancelReason ,
                                bpp.wConfirmPassengerNo = tmp.wConfirmPassengerNo ,
                                bpp.wServiceLang = tmp.wServiceLang ,
                                bpp.wHasWifi = tmp.wHasWifi ,
                                bpp.wRemark = tmp.wRemark ,
                                bpp.wNoOfServiceStaff = tmp.wNoOfServiceStaff ,
                                bpp.wPlaneModel = tmp.wPlaneModel ,
                                bpp.wSupplier = tmp.wSupplier ,
                                bpp.wHotelRid = tmp.wHotelRid ,
                                bpp.wTravelAgencyRid = tmp.wTravelAgencyRid ,
                                bpp.wSeatNo = tmp.wSeatNo ,
                                bpp.wExpAmt = tmp.wExpAmt ,
                                bpp.wPaymentMethod = tmp.wPaymentMethod ,
                                bpp.wReceiptNo = tmp.wReceiptNo ,
                                bpp.wExtraFee = tmp.wExtraFee ,
                                bpp.wBookingNo = tmp.wBookingNo ,
                                bpp.[wBookingStatus] = tmp.wBookingStatus ,
                                bpp.wUnqualifiedRid = ISNULL(tmp.wUnqualifiedRid, 0) ,
                                bpp.wBookingType = tmp.wBookingType ,
                                bpp.[wUpdBy] = tmp.wUpdBy ,
                                bpp.[wUpdDt] = dbo.fnUTC8Now() ,
                                bpp.wIsUseBlackCard = tmp.wIsUseBlackCard ,
                                bpp.wTotalCost = tmp.wTotalCost
                        FROM    dbo.[eBookingPrivatePlane] AS bpp
                                INNER JOIN #sDataSet_SetBookingPrivatePlane tmp ON bpp.RowID = tmp.RowID
                        WHERE   bpp.RowID = tmp.RowID;                        
        
                        SELECT TOP 1
                                @pBookingPrivatePlaneRid = RowID
                        FROM    #sDataSet_SetBookingPrivatePlane;
                    END;                        
                ELSE
                    IF @pActionType = 'D'
                        BEGIN  
       
                            UPDATE  bpp
                            SET     bpp.[wUpdBy] = tmp.wUpdBy ,
                                    bpp.[wUpdDt] = dbo.fnUTC8Now() ,
                                    bpp.wBookingStatus = 'DL' ,
                                    bpp.wStatus = 'T'
                            FROM    dbo.[eBookingPrivatePlane] AS bpp
                                    INNER JOIN #sDataSet_SetBookingPrivatePlane tmp ON bpp.RowID = tmp.RowID;                        
                               
                           
                            UPDATE  pd
                            SET     pd.wPassengerBookingStatus = 'T' ,
                                    pd.wStatus = 'T' ,
                                    pd.wUpdDt = dbo.fnUTC8Now() ,
                                    pd.wUpdBy = tmp.wUpdBy
                            FROM    dbo.ePassengerDetails pd
                                    INNER JOIN #sDataSet_SetBookingPrivatePlane tmp ON pd.wBookingRid = tmp.wBookingRid
                            WHERE   pd.wPassengerBookingStatus = 'A';
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
                                        FROM    #sDataSet_SetBookingPrivatePlane tmp
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
                FROM    #sDataSet_SetBookingPrivatePlane;
                      
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
       
        IF OBJECT_ID('tempdb..#sDataSet_SetBookingPrivatePlane') IS NOT NULL
            DROP TABLE #sDataSet_SetBookingPrivatePlane;
        IF OBJECT_ID('tempdb..#s_Period') IS NOT NULL
            DROP TABLE #s_Period;
    END;