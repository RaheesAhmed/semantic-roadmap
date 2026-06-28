CREATE PROCEDURE [spa].[SetHotelChange]
    (
      @pXML XML ,
      @pMainCompNo INT ,
      @pTestMode INT = 0 ,-- 0: Normal(Non-Test), 1: UnitTest, 2: Scenario Test
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pBookingRid BIGINT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) OUTPUT
    )
AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
      -- SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

      ----------result set-----------
      --DECLARE @sResultSet TABLE (
      --  RowID  BIGINT
      --)     
      --SELECT * FROM @sResultSet; RETURN
      ---------end result set--------
        DECLARE @sThisTableName VARCHAR(50) = 'eHotelChange' ,
            @sBeginTranCount INT = 0 ,
            @sDocHandle INT ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sXMLeGift NVARCHAR(MAX) = '' ,
            @sCageCodeIn VARCHAR(14) ,
            @vNow DATETIME2 = dbo.fnUTC8Now() ,
            @vMthEndYearMth VARCHAR(6) ,
            @vDateUsingCRM DATETIME2;

        SET @sBeginTranCount = @@TRANCOUNT;

        SET @sCageCodeIn = ( SELECT TOP 1
                                    c.wCageCodeIn
                             FROM   dbo.eBooking b
                                    INNER JOIN dbo.mServiceCounter sc ON sc.RowID = b.wDebitCounterRid
                                    INNER JOIN RollsMary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                                        AND c.wCageCode = '001'
                                                                        AND c.wStatus = 'A'
                             WHERE  b.RowID = @pBookingRid
                           );
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;

        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ) ,
                *
        INTO    #sDataSet_SetHotelChange
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
                WITH ( RowID                  BIGINT,
                       wBookingRid			  BIGINT,
                       wRoomBookingRid        BIGINT,
                       wAllotmentRid          BIGINT,
                       wAction                VARCHAR(5),
                       wOriStartDate          DATE,
                       wOriEndDate            DATE,
                       wNewStartDate          DATE,
                       wNewEndDate            DATE,
                       wDayOfStay             INT,
                       wVoucherNo             VARCHAR(40),
                       wCashReceiptNo         NVARCHAR(40),
                       wCashTransferReceiptNo VARCHAR(40),
                       wUseMemeberCard        CHAR(1),
                       wUseExtraAllotment     CHAR(1),
                       wUseUpAllotment        CHAR(1),
                       wGetKeyMethod          VARCHAR(30),
                       wReGetKey              CHAR(1),
                       wChangeCheckinPwd      CHAR(1),
                       wCurrCode              CHAR(3),
                       wPaymentMethod         VARCHAR(30),
                       wRemark                NVARCHAR(500),
                       wCrtDt                 DATETIME2,
                       wCrtBy                 BIGINT,
                       wUpdDt                 DATETIME2,
                       wUpdBy                 BIGINT,
                       wOrderNo               NVARCHAR(60),
                       wAmountChange          NUMERIC(18, 4),  --总值变动
                       wCostChange			  NUMERIC(18, 4),  --成本变动
                       wTotalAmount           NUMERIC(18, 4),  --变动后总值
                       wTotalCost			  NUMERIC(18, 4),  --变动后总成本
                       RecordState            VARCHAR(1),
                       wDateChange            NVARCHAR(64));--變動日期
        
        UPDATE  tmp
        SET     tmp.wCurrCode = br.wCurrCode
        FROM    #sDataSet_SetHotelChange AS tmp
                INNER JOIN dbo.eBookingRoom AS br ON tmp.wRoomBookingRid = br.RowID;

        UPDATE  #sDataSet_SetHotelChange
        SET     wBookingRid = @pBookingRid
        WHERE   wBookingRid <= 0;

        -- VALIDATION, C & RF cannot more than 1 record
        IF EXISTS ( SELECT  1
                    FROM    #sDataSet_SetHotelChange tmp
                            INNER JOIN dbo.eHotelChange hc ON tmp.wRoomBookingRid = hc.wRoomBookingRid
                                                              AND tmp.wAction = hc.wAction
                    WHERE   tmp.RecordState = 'I'
                            AND tmp.wAction IN ( 'C', 'RF' ) )
            BEGIN
                SET @pErrMsg = N'同一條房間預訂單不能重覆確認或退款';
                THROW 50001, @pErrMsg, 1;
            END;

        BEGIN TRY
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetHotelChange
                        WHERE   RecordState = 'I' )
                BEGIN
                -- Set RowID by Sequence
                    UPDATE  #sDataSet_SetHotelChange
                    SET     RowID = 0
                    WHERE   RecordState = 'I';

                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetHotelChange;

                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            IF EXISTS ( SELECT  1
                                        FROM    #sDataSet_SetHotelChange
                                        WHERE   RecordState = 'I'
                                                AND wRowNum = @sRuningIndex )
                                BEGIN
                                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;

                                    UPDATE  #sDataSet_SetHotelChange
                                    SET     RowID = @sRowID ,
                                            wBookingRid = @pBookingRid
                                    WHERE   wRowNum = @sRuningIndex;
                                END;

                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;

                    INSERT  INTO [dbo].[eHotelChange]
                            ( RowID ,
                              wBookingRid ,
                              wRoomBookingRid ,
                              wAllotmentRid ,
                              wAction ,
                              wOriStartDate ,
                              wOriEndDate ,
                              wNewStartDate ,
                              wNewEndDate ,
                              wDayOfStay ,
                              wVoucherNo ,
                              wCashReceiptNo ,
                              wCashTransferReceiptNo ,
                              wUseMemeberCard ,
                              wUseExtraAllotment ,
                              wUseUpAllotment ,
                              wGetKeyMethod ,
                              wReGetKey ,
                              wChangeCheckinPwd ,
                              wCurrCode ,
                              wPaymentMethod ,
                              wRemark ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy ,
                              wOrderNo ,
                              wAmountChange ,
                              wCostChange ,
                              wTotalAmount ,
                              wTotalCost ,
                              wDateChange
                            )
                            SELECT  RowID ,
                                    wBookingRid ,
                                    wRoomBookingRid ,
                                    wAllotmentRid ,
                                    wAction ,
                                    wOriStartDate ,
                                    wOriEndDate ,
                                    wNewStartDate ,
                                    wNewEndDate ,
                                    wDayOfStay ,
                                    wVoucherNo ,
                                    wCashReceiptNo ,
                                    wCashTransferReceiptNo ,
                                    wUseMemeberCard ,
                                    wUseExtraAllotment ,
                                    wUseUpAllotment ,
                                    wGetKeyMethod ,
                                    wReGetKey ,
                                    wChangeCheckinPwd ,
                                    wCurrCode ,
                                    wPaymentMethod ,
                                    wRemark ,
                                    wCrtDt ,
                                    wCrtBy ,
                                    wUpdDt ,
                                    wUpdBy ,
                                    wOrderNo ,
                                    wAmountChange ,
                                    wCostChange ,
                                    wTotalAmount ,
                                    wTotalCost ,
                                    wDateChange
                            FROM    #sDataSet_SetHotelChange
                            WHERE   RecordState = 'I';

                ---------------------------------------------------------------------------------------------
                -- Sync Expense to rollsmary
                -- 只會新增, 每次新增記錄就係確認好, 所以永遠都係insert, 做正負數
                ---------------------------------------------------------------------------------------------
                    SELECT  @vMthEndYearMth = MAX(wYearMth)
                    FROM    RollsMary.dbo.eSettleTran (NOLOCK) WHERE wSettleLineGrp = '';
                    SET @vDateUsingCRM = ( SELECT TOP 1
                                                    wValue
                                           FROM     RollsMary.dbo.mSysTable
                                           WHERE    wItemCode = 'DATE_USING_CRM'
                                         );
                    SET @vDateUsingCRM = ISNULL(@vDateUsingCRM, '2099-12-31');

                    DECLARE @vXMLInsertExp NVARCHAR(MAX) = '' ,
                        @vErrCode INT = 0 ,
                        @vErrMsg NVARCHAR(MAX);

                    ALTER TABLE #sDataSet_SetHotelChange ADD 
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
                           sc.wRollexCompNo AS wCompNo, (CASE WHEN tmp.wAction = 'RF' THEN bChg.wCancelDebitDt
                                             ELSE bChg.wDebitDt
                                        END) AS wDate
                        INTO #s_Period
                        FROM #sDataSet_SetHotelChange tmp 
                             LEFT JOIN dbo.eBookingRoom br ON tmp.wRoomBookingRid = br.RowID
                             LEFT JOIN dbo.eBookingHotel bh ON br.wHotelBookingRid = bh.RowID
                             LEFT JOIN dbo.eBooking b ON bh.wBookingRid = b.RowID
                             LEFT JOIN dbo.eBooking bRoom ON br.wBookingRid = bRoom.RowID
                             LEFT JOIN dbo.eBooking bChg ON tmp.wBookingRid = bChg.RowID
                                                           AND tmp.wBookingRid > 0
                             LEFT JOIN dbo.mServiceCounter sc ON sc.RowID = ISNULL(ISNULL(bChg.wDebitCounterRid, bRoom.wDebitCounterRid), b.wDebitCounterRid)
                             LEFT JOIN RollsMary.dbo.mSettlePeriod sp ON sp.wCompNo = sc.wRollexCompNo AND sp.wCageCodeIn = @sCageCodeIn
                                                                        AND CASE WHEN tmp.wAction = 'RF' THEN bChg.wCancelDebitDt
                                                                                 ELSE bChg.wDebitDt
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
                            wDate = ISNULL(cs.wDate, CASE WHEN tmp.wAction = 'RF' THEN bChg.wCancelDebitDt
                                                          ELSE bChg.wDebitDt
                                                     END) ,
                            wShift = ISNULL(cs.wShift, '1')
                    FROM    #sDataSet_SetHotelChange tmp
                            LEFT JOIN dbo.eBookingRoom br ON tmp.wRoomBookingRid = br.RowID
                            LEFT JOIN dbo.eBookingHotel bh ON br.wHotelBookingRid = bh.RowID
                            LEFT JOIN dbo.eBooking b ON bh.wBookingRid = b.RowID
                            LEFT JOIN dbo.eBooking bRoom ON br.wBookingRid = bRoom.RowID
                            LEFT JOIN dbo.eBooking bChg ON tmp.wBookingRid = bChg.RowID
                                                           AND tmp.wBookingRid > 0
                            LEFT JOIN dbo.mServiceCounter sc ON sc.RowID = ISNULL(ISNULL(bChg.wDebitCounterRid, bRoom.wDebitCounterRid), b.wDebitCounterRid)
                            LEFT JOIN RollsMary.dbo.mSettlePeriod sp ON sp.wCompNo = sc.wRollexCompNo AND sp.wCageCodeIn = @sCageCodeIn
                                                                        AND CASE WHEN tmp.wAction = 'RF' THEN bChg.wCancelDebitDt
                                                                                 ELSE bChg.wDebitDt
                                                                            END BETWEEN sp.wStartDateTime
                                                                                AND     sp.wEndDateTime
                            LEFT JOIN RollsMary.dbo.eCompShift cs ON cs.wCompNo = sc.wRollexCompNo
                                                                     AND CASE WHEN tmp.wAction = 'RF' THEN bChg.wCancelDebitDt
                                                                              ELSE bChg.wDebitDt
                                                                         END BETWEEN cs.wStartDateTime
                                                                             AND     cs.wEndDateTime;

                    --DECLARE @vTmp NVARCHAR(MAX);
                    --SET @vTmp = (SELECT * FROM #sDataSet_SetHotelChange FOR XML RAW('Record'), ROOT ('DataSet'));
                    --SET @vTmp = CAST(@pXML AS NVARCHAR(MAX));

                    --EXEC spa.WriteErrorLog @pMainCompNo = 0, -- int
                    --    @pCompNo = @pMainCompNo, -- int
                    --    @pLogCode = N'SYNC_EXP_H_D', -- nvarchar(50)
                    --    @pLogInfo = @vTmp, -- nvarchar(max)
                    --    @pRtnCode = 0, -- int
                    --    @pErrMsg = '' -- nvarchar(2000)

                    ----SET @vTmp = (SELECT * FROM #sDataSet_SetHotelChange FOR XML RAW('Record'), ROOT ('DataSet'));
                    --SET @vTmp = CAST(@pXML AS NVARCHAR(MAX));

                    --EXEC spa.WriteErrorLog @pMainCompNo = 0, -- int
                    --    @pCompNo = @pMainCompNo, -- int
                    --    @pLogCode = N'SYNC_EXP_H', -- nvarchar(50)
                    --    @pLogInfo = @vTmp, -- nvarchar(max)
                    --    @pRtnCode = 0, -- int
                    --    @pErrMsg = '' -- nvarchar(2000)

                    -- Check is already Mth end or not	
                    IF EXISTS ( SELECT  1
                                FROM    #sDataSet_SetHotelChange tmp
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
                                                        wAgentCodeIn = ISNULL(bChg.wDebitAgentCodeIn, bRoom.wDebitAgentCodeIn) ,
                                                        wCardCodeIn = '' ,
                                                        wCustName = ISNULL(a.wCName, '') ,
                                                        wShopName = tmp.RowID ,
                                                        wExpTypeCode = 'HOTEL' ,
                                                        wExpTargetCode = '' ,
                                                        wExpCode = 'HOTEL' ,
                                                        wExpSubCode1 = '' ,
                                                        wCurCode = tmp.wCurrCode ,
                                                        wRoomNo = ISNULL(br.wRoomNo, '') ,
                                                        wRoomCfmCode = ISNULL(br.wConfirmationNo, '') ,
                                                        wRoomBookDt = NULL ,
                                                        wRoomCheckInDt = NULL ,
                                                        wRoomDeptDt = NULL ,
                                                        wNight = tmp.wDayOfStay ,
                                                        wUnit = 1 ,
                                                        wPrice = CASE WHEN tmp.wPaymentMethod IN ( 'DA', 'GC', 'ST-CASH', 'ST-AP', 'ST-BT', 'ST-CC' ) THEN CASE WHEN tmp.wAction = 'C' THEN tmp.wTotalAmount
                                                                                                                         ELSE ISNULL(tmp.wAmountChange, 0)
                                                                                                                    END
                                                                      ELSE 0
                                                                 END ,
                                                        wRoomExpAmt = 0 ,
                                                        wAmount = CASE WHEN tmp.wPaymentMethod IN ( 'DA', 'GC', 'ST-CASH', 'ST-AP', 'ST-BT', 'ST-CC' ) THEN CASE WHEN tmp.wAction = 'C' THEN tmp.wTotalAmount
                                                                                                                          ELSE ISNULL(tmp.wAmountChange, 0)
                                                                                                                     END
                                                                       ELSE 0
                                                                  END ,
                                                        wExpLocation = sc.wDefaultHotelCode ,
                                                        wVoucherNo = '' ,
                                                        wVoucherDt = tmp.wDate ,
                                                        wRemark = CONCAT(N'房間預訂: ', bRoom.wRefNo, CASE WHEN tmp.wAction = 'RF' THEN N'退款'
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
                                                        wRefRid = tmp.wRoomBookingRid ,
                                                        wReferId = b.RowID ,
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
                                                        wInvoiceDateTime_CRM = ISNULL(ISNULL(bChg.wExpDt, bRoom.wExpDt), b.wExpDt) ,
                                                        wAmountActual_CRM = CASE WHEN tmp.wAction = 'C' THEN tmp.wTotalAmount
                                                                                 ELSE ISNULL(tmp.wAmountChange, 0)
                                                                            END ,
                                                        wCardNo_CRM = '' ,
                                                        wAuthorizer_CRM = aAuth.wCName ,
                                                        wExpCategory = 'STAY' ,
                                                        wGuid = '' ,
                                                        wRequestAgentCodeIn = b.wReqAgentCodeIn ,
                                                        wIsDeposit = 'N' ,
                                                        wIsDepositDone = 'N' ,
                                                        wProductCategory = '' ,
                                                        wProductDetail = '',
                                                        wBookingRid = b.RowID,
                                                        wBookingActionRid = tmp.RowID,
                                                        wBookingStatus = CASE WHEN tmp.wAction IN ('C', 'RF') THEN tmp.wAction ELSE br.wBookingStatus END--wAction = 'C' 确认消费 wAction = 'C' 房间退款
                                               FROM     #sDataSet_SetHotelChange tmp
                                                        LEFT JOIN dbo.eBookingRoom br ON tmp.wRoomBookingRid = br.RowID
                                                        LEFT JOIN dbo.eBookingHotel bh ON br.wHotelBookingRid = bh.RowID
                                                        LEFT JOIN dbo.eBooking b ON bh.wBookingRid = b.RowID
                                                        LEFT JOIN dbo.eBooking bRoom ON br.wBookingRid = bRoom.RowID
                                                        LEFT JOIN dbo.eBooking bChg ON tmp.wBookingRid = bChg.RowID
                                                                                       AND tmp.wBookingRid > 0
                                                        LEFT JOIN RollsMary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                                        LEFT JOIN RollsMary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                                        LEFT JOIN dbo.mServiceCounter sc ON sc.RowID = ISNULL(ISNULL(bChg.wDebitCounterRid, bRoom.wDebitCounterRid), b.wDebitCounterRid)
                                                        LEFT JOIN RollsMary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                                                           AND c.wCageCode = '001'
                                                                                           AND c.wStatus = 'A'
                                                        LEFT JOIN RollsMary.dbo.mUsr u ON tmp.wUpdBy = u.RowID
                                             FOR
                                               XML RAW('Record') ,
                                                   ROOT('DataSet')
                                             );
                    
                    --SET @vTmp = (SELECT * FROM #sDataSet_SetHotelChange FOR XML RAW('Record'), ROOT ('DataSet'));
                    --SET @vTmp = @vXMLInsertExp;

                    --EXEC spa.WriteErrorLog @pMainCompNo = 0, -- int
                    --    @pCompNo = @pMainCompNo, -- int
                    --    @pLogCode = N'SYNC_EXP_H_S', -- nvarchar(50)
                    --    @pLogInfo = @vTmp, -- nvarchar(max)
                    --    @pRtnCode = 0, -- int
                    --    @pErrMsg = '' -- nvarchar(2000)

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
                ---------------------------------------------------------------------------------------------
                -- End Sync Expense
                ---------------------------------------------------------------------------------------------

                /*
                DECLARE @vTmp NVARCHAR(MAX);

                SET @vTmp = CONCAT(@vXMLInsertExp, CHAR(10), CHAR(13), CAST(@pXML AS NVARCHAR(MAX)));

                EXEC spa.WriteErrorLog @pMainCompNo = 0, -- int
                    @pCompNo = 99, -- int
                    @pLogCode = N'SYNC_EXP_HOTEL', -- nvarchar(50)
                    @pLogInfo = @vTmp, -- nvarchar(max)
                    @pRtnCode = 0, -- int
                    @pErrMsg = '' -- nvarchar(2000)
                */
                END;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetHotelChange
                        WHERE   RecordState = 'U' )
                BEGIN
                    UPDATE  hc_t
                    SET     wRoomBookingRid = tmp.wRoomBookingRid ,
                            wAllotmentRid = tmp.wAllotmentRid ,
                            wAction = tmp.wAction ,
                            wOriStartDate = tmp.wOriStartDate ,
                            wOriEndDate = tmp.wOriEndDate ,
                            wNewStartDate = tmp.wNewStartDate ,
                            wNewEndDate = tmp.wNewEndDate ,
                            wDayOfStay = tmp.wDayOfStay ,
                            wVoucherNo = tmp.wVoucherNo ,
                            wCashReceiptNo = tmp.wCashReceiptNo ,
                            wCashTransferReceiptNo = tmp.wCashTransferReceiptNo ,
                            wUseMemeberCard = tmp.wUseMemeberCard ,
                            wUseExtraAllotment = tmp.wUseExtraAllotment ,
                            wUseUpAllotment = tmp.wUseUpAllotment ,
                            wGetKeyMethod = tmp.wGetKeyMethod ,
                            wReGetKey = tmp.wReGetKey ,
                            wChangeCheckinPwd = tmp.wChangeCheckinPwd ,
                            wCurrCode = tmp.wCurrCode ,
                            wPaymentMethod = tmp.wPaymentMethod ,
                            wRemark = tmp.wRemark ,
                            --wCrtDt = tmp.wCrtDt ,
                            --wCrtBy = tmp.wCrtBy ,
                            wUpdDt = @vNow ,
                            wUpdBy = tmp.wUpdBy ,
                            wOrderNo = tmp.wOrderNo ,
                            wAmountChange = tmp.wAmountChange ,
                            wCostChange = tmp.wCostChange ,
                            wTotalAmount = tmp.wTotalAmount ,
                            wTotalCost = tmp.wTotalCost ,
                            wDateChange = tmp.wDateChange
                    FROM    [dbo].[eHotelChange] hc_t
                            INNER JOIN #sDataSet_SetHotelChange tmp ON hc_t.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'U';
                END;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetHotelChange
                        WHERE   RecordState = 'D' )
                BEGIN
                --;THROW 70002, 'Deleted operation is not allowed', 1;
                    UPDATE  hc_t
                    SET     --wStatus = 'T',
                            wUpdDt = @vNow
                    FROM    [dbo].[eHotelChange] hc_t
                            INNER JOIN #sDataSet_SetHotelChange tmp ON hc_t.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'D';
                END;

                ---------------------------------------------------------------------------------------------
                -- Add eGift record
                ---------------------------------------------------------------------------------------------
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetHotelChange tmp
                                INNER JOIN dbo.eHotelChange hc ON tmp.wBookingRid = hc.wBookingRid
                        WHERE   tmp.wPaymentMethod IN ('GC', 'RC0')
                                AND ( tmp.wAction IN ( 'C', 'EX', 'RF' ) ) )
                BEGIN                    
                    SET @sXMLeGift = ( SELECT   g.RowID AS RowID ,
                                                CASE WHEN tmp.wAction = 'EX' THEN hc.wBookingRid
                                                     ELSE br.wBookingRid
                                                END AS wRefBookingRid ,
                                                'eBooking' AS wRefTableName ,
                                                CASE WHEN tmp.wAction = 'EX' THEN hc.wBookingRid
                                                     ELSE br.wBookingRid
                                                END AS wRefTableRid ,
                                                tmp.wAction AS wOriActionType ,
                                                b.wDebitCounterRid AS wDebitCounterRid ,
                                                b.wReqCounterRid AS wReqCounterRid ,
                                                sc.wRollexCompNo AS wCompNo ,
                                                @sCageCodeIn AS wCageCodeIn ,
                                                b.wReqDepartment AS wReqDeptCd ,
                                                b.wReqUserRid AS wReqStaffRid ,
                                                b.wReqAgentCodeIn AS wReqAgentCodeIn ,
                                                GETDATE() AS wDate ,
                                                a.wCName AS wRecipient ,
                                                -- 'HKD' AS wCurrCode , --2018-12-14： OP#24284，送禮特批中的金額貨幣現在默認為HKD，應該跟Booking中的貨幣
                                                tmp.wCurrCode AS wCurrCode ,
                                                CASE WHEN tmp.wAction = 'C' THEN tmp.wTotalAmount
                                                     ELSE ISNULL(tmp.wAmountChange, 0)
                                                END AS wAmount ,
                                                '02' AS wType , --送禮
                                                '0209' AS wSubType , --房間
                                                tmp.wRemark AS wRemark ,
                                                b.wEventCodeRid AS wEventCodeRid ,
                                                'A' AS wStatus ,
                                                @vNow AS wCrtDt , -- set sp should not update this field when update
                                                tmp.wUpdBy AS wCrtBy , -- set sp should not update this field when update
                                                @vNow AS wUpdDt ,
                                                tmp.wUpdBy ,
                                                CASE WHEN ISNULL(g.wRefTableRid, 0) <= 0 THEN 'I'
                                                     ELSE 'U'
                                                END AS RecordState ,
                                                CASE WHEN tmp.wAction = 'EX' THEN b.wGiftReasonCd
                                                     ELSE rb.wGiftReasonCd
                                                END AS wReasonCd ,
                                                CASE WHEN tmp.wAction = 'EX'
                                                          AND ( g.RowID IS NOT NULL ) THEN g.wIsReceived
                                                     WHEN tmp.wAction != 'EX'
                                                          AND ( rg.RowID IS NOT NULL ) THEN rg.wIsReceived
                                                     ELSE 'Y' -- 經由booking 產生的送禮記錄要預設為 "已接收"
                                                END AS wIsReceived,
                                                tmp.wTotalCost AS wCost
                                       FROM     #sDataSet_SetHotelChange tmp
                                                INNER JOIN dbo.eHotelChange hc ON tmp.wBookingRid = hc.wBookingRid
                                                                                  AND tmp.wPaymentMethod IN ('GC', 'RC0')
                                                                                  AND ( tmp.wAction IN ( 'C', 'EX', 'RF' ) )
                                                INNER JOIN dbo.eBookingRoom br ON br.RowID = hc.wRoomBookingRid
                                                INNER JOIN dbo.eBooking b ON b.RowID = tmp.wBookingRid
                                                INNER JOIN dbo.eBooking rb ON rb.RowID = br.wBookingRid
                                                INNER JOIN dbo.mServiceCounter sc ON sc.RowID = b.wReqCounterRid
                                                LEFT JOIN eGift g ON g.wRefTableRid = tmp.wBookingRid
                                                                     AND g.wStatus = 'A'
                                                LEFT JOIN eGift rg ON rg.wRefTableRid = br.wBookingRid
                                                                      AND rg.wStatus = 'A'
                                                INNER JOIN RollsMary.dbo.mAgent a ON a.wAgentCodeIn = b.wApprovalAgentCodeIn
                                                                                     AND a.wStatus = 'A'
                                     FOR
                                       XML RAW('Record') ,
                                           ROOT('DataSet')
                                     );
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

            IF @sBeginTranCount = 0
                AND @@TRANCOUNT > 0
                BEGIN
                    IF @pTestMode = 1 
                        ROLLBACK;
                    ELSE
                        COMMIT;
                END;

          -- Return RowID List
            IF @pReturnResultSet = 'Y'
                BEGIN
                    SELECT  RowID
                    FROM    #sDataSet_SetHotelChange;
                END;
        END TRY
        BEGIN CATCH
            DECLARE @sErrorNum INT ,
                @sCatchErrorMessage NVARCHAR(4000) ,
                @xstate INT ,
                @sProcedureName VARCHAR(100) ,
                @sRtnCodeLog INT ,
                @sErrMessageLog NVARCHAR(4000);
            SET @sErrorNum = ERROR_NUMBER();
            SET @pErrCode = ERROR_NUMBER();
            SET @sCatchErrorMessage = ERROR_MESSAGE();
            SET @xstate = XACT_STATE();
            SET @sProcedureName = OBJECT_NAME(@@PROCID);
            IF ISNULL(@pErrCode, 0) = 0
                BEGIN
                    SET @pErrCode = 70001;
                END;

            PRINT '[spa].[SetHotelChange]'
            SET @pErrMsg = CONCAT('(', @sErrorNum, ') ', @sCatchErrorMessage);
            -- Write Log
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
            IF @sBeginTranCount = 0
            BEGIN
                IF (@xstate = 1 OR @xstate = -1) AND @@TRANCOUNT > 0
                    ROLLBACK;					
            END;
            ELSE
                THROW;
        END CATCH;

        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetHotelChange') IS NOT NULL
            DROP TABLE #sDataSet_SetHotelChange;
        IF OBJECT_ID('tempdb..#s_Period') IS NOT NULL
            DROP TABLE #s_Period;
    END;