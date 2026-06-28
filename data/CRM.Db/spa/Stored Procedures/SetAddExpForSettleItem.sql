
-- e.g.
--DECLARE	@pErrCode int,
--		@pErrMsg nvarchar(200)

--EXEC	[spa].[SetAddExpForSettleItem]
--		@pXML = '<DataSet><Record wExpTranRid="1001540487" wAgentCodeIn="1000010180" wCompNo="10" wDate="2018-08-13" wCurCode="HKD" wAmount="1000" wRemark="即出"/></DataSet>',
--		@pErrCode = @pErrCode OUTPUT,
--		@pErrMsg = @pErrMsg OUTPUT
-- Mary代理做即出建立一條「其它消費」記錄
-- 如果代理有欠消費數，系統需要先在佣金扣掉消費數，才可以讓代理即出，因此系統要建立一條其他消費，記錄下代理已歸還消費數
CREATE PROC [spa].[SetAddExpForSettleItem]
    @pXML       XML,
    @pErrCode   INT OUTPUT,
    @pErrMsg    NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sBookingTableName      VARCHAR(50) = 'eBooking',
                @sAddExpTableName       VARCHAR(50) = 'eAdditionalExpense',
                @sRecCount              INT         = 0,
                @sRuningIndex           INT         = 1,
                @sRowID                 BIGINT      = 0,
                @sBookingRid            BIGINT      = 0,
                @sRefNo                 VARCHAR(30) = '',
                @sSeqNo                 INT         = 0,
                @sExpenseTypeRid        BIGINT      = 0,
                @sAgentCodeIn           VARCHAR(14) = '',
                @sDebitCustomerRid      BIGINT      = 0,
                @sExpTranRid            BIGINT      = 0,
                @sUpdBy                 BIGINT      = 0,
                @sUpdBySys              BIGINT      = 0,
                @sNow                   DATETIME2(7)= GETDATE();

        DECLARE @pMainCompNo            INT;
        DECLARE @sBeginTranCount        INT = 0;
        DECLARE @vResult TABLE (wBookingRid BIGINT);
        
        DECLARE @vServiceCounter TABLE(
            RowID           BIGINT,    
            wRollxCompNo    INT,
            PRIMARY KEY(RowID, wRollxCompNo)
        );

        INSERT INTO @vServiceCounter (
            RowID,
            wRollxCompNo
        )
        SELECT
            RowID,
            wRollexCompNo
        FROM (
            SELECT
                wRowNum = ROW_NUMBER() OVER(PARTITION BY sc.wRollexCompNo ORDER BY sc.RowID),
                sc.RowID,
                sc.wRollexCompNo
            FROM dbo.mServiceCounter sc 
            INNER JOIN RollsMary.dbo.mCompany mc ON mc.wCompNo = sc.wRollexCompNo
            WHERE sc.wStatus = 'A'
                AND mc.wStatus = 'A'
                AND ((mc.wCName = N'星際' AND sc.wCode = 'SW')
                    OR (mc.wCName = N'COD' AND sc.wCode = 'COD1-MNL')
                    OR mc.wCName NOT IN (N'星際', N'COD'))
        ) AS sc WHERE sc.wRowNum = 1
        ORDER BY sc.wRollexCompNo;
        
        DECLARE @vDataSet_SetAdditionalExpense TABLE(
            wRowNum             BIGINT IDENTITY(1, 1) PRIMARY KEY,
            RowID               BIGINT,
            wBookingRefRid      BIGINT,
            wBookingRid         BIGINT,
            wRefNo              VARCHAR(30),
            wSeqNo              INT,
            wExpTranRid         BIGINT,
            [GUID]              UNIQUEIDENTIFIER,
            wDebitCustomerRid   BIGINT,
            wReqCustomerRid     BIGINT,
            wAgentCodeIn        VARCHAR(14),
            wCompNo             INT,
            wDate               DATE,
            wCurCode            VARCHAR(30),
            wAmount             NUMERIC(18,4),
            wRemark             NVARCHAR(500),
            wUpdBy              BIGINT
        );
        
        INSERT INTO @vDataSet_SetAdditionalExpense(
            wExpTranRid,
            wAgentCodeIn,
            wCompNo,
            wDate,
            wCurCode,
            wAmount,
            wRemark
        )
        SELECT
            wExpTranRid     = T.tmp.value('@wExpTranRid',   'BIGINT'),
            wAgentCodeIn    = T.tmp.value('@wAgentCodeIn',  'VARCHAR(14)'),
            wCompNo         = T.tmp.value('@wCompNo',       'INT'),
            wDate           = T.tmp.value('@wDate',         'DATE'),
            wCurCode        = T.tmp.value('@wCurCode',      'VARCHAR(30)'),
            wAmount         = T.tmp.value('@wAmount',       'NUMERIC(18,4)'),
            wRemark         = T.tmp.value('@wRemark',       'NVARCHAR(500)')
        FROM @pXML.nodes('/DataSet/Record') T (tmp)
        WHERE T.tmp.value('@wExpTranRid', 'BIGINT') > 0;

        IF EXISTS (SELECT 1 FROM @vDataSet_SetAdditionalExpense)
        BEGIN
            SET @sBeginTranCount = @@trancount;
            SET @sUpdBySys = ISNULL(( SELECT TOP(1) RowID FROM RollsMary.dbo.mUsr WHERE wUsrId = 'SYSTEM' AND wName = 'System'), 0);
            SET @sExpenseTypeRid = (SELECT TOP(1) RowID FROM dbo.mExpenseType WHERE wName = N'找消費');

            BEGIN TRY
                -- Try to make the transaction scope as small as possible to reduce locking
                IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

                IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqeAdditionalExpensesRefNo') AND type = 'SO') BEGIN
                    CREATE SEQUENCE seqeAdditionalExpensesRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999
                END;

                SET @sRecCount = (SELECT COUNT(1) FROM @vDataSet_SetAdditionalExpense);

                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    SELECT  
                        @pMainCompNo = wCompNo , 
                        @sAgentCodeIn = wAgentCodeIn ,
                        @sExpTranRid = wExpTranRid 
                    FROM @vDataSet_SetAdditionalExpense WHERE wRowNum = @sRuningIndex;

                    -- eBooking.RowID
                    EXEC spq.GetRowID @pMainCompNo, @sBookingTableName, @sBookingRid OUTPUT;
                    -- eBooking.wRefNo
                    SET @sRefNo = 'D' + FORMAT(NEXT VALUE FOR dbo.seqeAdditionalExpensesRefNo, '0000000');
                    -- eAdditionExpense.RowID
                    EXEC spq.GetRowID @pMainCompNo, @sAddExpTableName, @sRowID OUTPUT;

                    IF @sSeqNo = 0
                       SET @sSeqNo = (SELECT ISNULL(MAX(wSeqNo), 1) FROM dbo.eAdditionalExpense); 
                                  
                    SET @sSeqNo = @sSeqNo + 1;

                    SET @sDebitCustomerRid = (
                        SELECT TOP(1) wAgentCodeIn
                        FROM RollsMary.dbo.mAgent AS t
                        WHERE wStatus = 'A'
                            AND t.wType = 'AUTH' 
                            AND wAuthIdentity = 'OWNER'
                            AND wUpLvlAgentCodeIn = @sAgentCodeIn
                    );
                     
                    SET @sUpdBy = ( SELECT wUpdBy FROM RollsMary.dbo.eExpTran WHERE RowID = @sExpTranRid );       

                    UPDATE @vDataSet_SetAdditionalExpense 
                    SET RowID               = @sRowID, 
                        wBookingRefRid      = @sBookingRid, 
                        wBookingRid         = @sBookingRid,
                        wRefNo              = @sRefNo,
                        wSeqNo              = @sSeqNo,
                        [GUID]              = NEWID(),
                        wDebitCustomerRid   = ISNULL(@sDebitCustomerRid, 0),
                        wReqCustomerRid     = ISNULL(@sDebitCustomerRid, 0),
                        wUpdBy              = COALESCE(@sUpdBy, @sUpdBySys, 1);

                    SET @sRuningIndex = @sRuningIndex + 1;
                END;
                
                -- insert new record to eBooking
                INSERT INTO dbo.eBooking(
                    RowID,
                    wBookingType,
                    wRefNo,
                    [GUID],
                    wReqCounterRid,
                    wDebitCounterRid,
                    wReqAgentCodeIn,
                    wDebitAgentCodeIn,
                    wDebitCustomerRid,
                    wReqCustomerRid,
                    wReqDepartment,
                    wReqUserRid,
                    wAsstBooker,
                    wAssBookerTel,
                    wAsstBookerEmail,
                    wApprovalAgentCodeIn,
                    wOwnerAuthTelephone,
                    wUseTravelPkg,
                    wTravePkgRid,
                    wEventCodeRid,
                    wDeptFollwedCd,
                    wStaffFollwedRid,
                    wStaffTelephone,
                    wGiftReasonCd,
                    wHasDeposit,
                    wDepositAmt,
                    wDepositDebitDt,
                    wCoordinator,
                    wUser,
                    wIsUser,
                    wDebitDt,
                    wExpDt,
                    wCancelDebitDt,
                    wCancelReasonCd,
                    wOtherReason,
                    wCancelBy,
                    wCancelDt,
                    wBookingStatus,
                    wCrtDt,
                    wCrtBy,
                    wUpdDt,
                    wUpdBy
                )
                SELECT
                    ae.wBookingRefRid,
                    wBookingType = 'ADDITIONALEXPENSES',
                    ae.wRefNo,
                    ae.[GUID],
                    wReqCounterRid = sc.RowID,
                    wDebitCounterRid = sc.RowID,
                    wReqAgentCodeIn = ae.wAgentCodeIn,
                    wDebitAgentCodeIn = ae.wAgentCodeIn,
                    wDebitCustomerRid = ae.wDebitCustomerRid,
                    wReqCustomerRid = ae.wReqCustomerRid,
                    wReqDepartment = 'CAGE',
                    wReqUserRid = -1,
                    wAsstBooker = ISNULL(ma.wCName, ''),
                    wAssBookerTel = ISNULL(ma.wTel, ''),
                    wAsstBookerEmail = ISNULL(ma.wEmail, ''),
                    wApprovalAgentCodeIn = ae.wAgentCodeIn,
                    wOwnerAuthTelephone = ISNULL(ma.wTel, ''),
                    wUseTravelPkg = 'N',
                    wTravePkgRid = -1,
                    wEventCodeRid = -1,
                    wDeptFollwedCd = 'CAGE',
                    wStaffFollwedRid = -1,
                    wStaffTelephone = '',
                    wGiftReasonCd = '',
                    wHasDeposit = 'N',
                    wDepositAmt = 0,
                    wDepositDebitDt = @sNow,
                    wCoordinator = ISNULL(ma.wCName, ''),
                    wUser = ISNULL(ma.wCName, ''),
                    wIsUser = 'Y',
                    wDebitDt = ae.wDate,
                    wExpDt = @sNow,
                    wCancelDebitDt = NULL,
                    wCancelReasonCd = '',
                    wOtherReason = '',
                    wCancelBy = -1,
                    wCancelDt = NULL,
                    wBookingStatus = 'C',
                    wCrtDt = @sNow,
                    wCrtBy = ae.wUpdBy,
                    wUpdDt = @sNow,
                    wUpdBy = ae.wUpdBy
                FROM @vDataSet_SetAdditionalExpense ae
                LEFT JOIN @vServiceCounter sc ON sc.wRollxCompNo = ae.wCompNo
                LEFT JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = ae.wAgentCodeIn;

                -- insert new record to eAdditionExpense
                INSERT INTO dbo.eAdditionalExpense(
                    RowID,
                    wOrderNo,
                    wBookingRid,
                    wBookingRefRid,
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
                    wSeqNo,
                    wSpaRid,
                    wRestaurantRid,
                    wTravelAgencyRid,
                    wUnqualifiedRid,
                    wPersonRid,
                    wBookingStatus,
                    wStatus,
                    wCrtDt,
                    wCrtBy,
                    wUpdDt,
                    wUpdBy
                )
                SELECT
                    ae.RowID,
                    wOrderNo = '',
                    wBookingRefRid = ae.wBookingRefRid,
                    wBookingRid = ae.wBookingRid,
                    wRoomBookingRid = -1,
                    wExpenseType = @sExpenseTypeRid,
                    wExpenseSubtype = 0,
                    wPaymentMethod = 'DA',
                    wReceiptNo = '',
                    wExpAmt = ae.wAmount ,
                    wTotalAmt = ae.wAmount ,
                    wCost = ae.wAmount ,
                    wCurrcode = ISNULL(ae.wCurCode, ''),
                    wIsUseBlackCard = 'N',
                    wRemark = ISNULL(ae.wRemark, ''),
                    wSeqNo = @sSeqNo,
                    wSpaRid = -1,
                    wRestaurantRid = -1,
                    wTravelAgencyRid = -1,
                    wUnqualifiedRid = -1,
                    wPersonRid = -1,
                    wBookingStatus = 'C',
                    wStatus = 'A',
                    wCrtDt = @sNow,
                    wCrtBy = ae.wUpdBy,
                    wUpdDt = @sNow,
                    wUpdBy = ae.wUpdBy
                FROM @vDataSet_SetAdditionalExpense ae;

                -- update eExpTran
                UPDATE et
                SET et.wBookingRid = ae.wBookingRefRid,
                    et.wReferId = CONVERT(VARCHAR(40), ae.wBookingRefRid)
                FROM RollsMary.dbo.eExpTran et
                INNER JOIN @vDataSet_SetAdditionalExpense ae ON ae.wExpTranRid = et.RowID;

                IF @sBeginTranCount = 0 AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;
            END TRY
            BEGIN CATCH
                DECLARE @sErrorNum          INT ,
                        @sCatchErrorMessage NVARCHAR(4000) ,
                        @xstate             INT ,
                        @sProcedureName     VARCHAR(100) ,
                        @sRtnCodeLog        INT ,
                        @sErrMessageLog     NVARCHAR(4000);
	        
                SET @sErrorNum          = ERROR_NUMBER();
                SET @sCatchErrorMessage = ERROR_MESSAGE();
                SET @xstate             = XACT_STATE();
                SET @sProcedureName     = OBJECT_NAME(@@PROCID);
			
                IF ISNULL(@pErrCode, 0) = 0
                    SET @pErrCode = 999;

                SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ', @sCatchErrorMessage);
			
                IF @sBeginTranCount = 0
                    BEGIN
                        IF @xstate != 0
                            ROLLBACK;

                        EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
                    END;
                ELSE
                    THROW;

            END CATCH;
        END;
    END;