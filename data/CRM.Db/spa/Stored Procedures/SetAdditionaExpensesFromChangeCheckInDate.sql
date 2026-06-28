CREATE PROCEDURE [spa].[SetAdditionaExpensesFromChangeCheckInDate] 
(
	@pXML XML,
	@pActionType CHAR(1),
	@pMainCompNo INT,
	@pNonceToken VARCHAR(64), 
	@pReturnResultSet CHAR(1) = 'N',
	@pRoomBookingRid BIGINT,
	@pNewRoomBookingRid BIGINT,
	@pUpdatedBy BIGINT,
	@pErrCode INT = 0 OUTPUT,
	@pErrMsg NVARCHAR(200) = '' OUTPUT
)
AS
BEGIN
	--select * from eAdditionalExpense;
	DECLARE @sRowId BIGINT=0,@sRecCount INT=0,@sRuningIndex INT=1;

	DECLARE @sBeginTranCount INT = 0;
	DECLARE @sXMLBooking AS XML, @sXMLBookingAdditionalExpenses AS XML;
	SET @sBeginTranCount = @@trancount;

	SELECT * INTO #tmpAdditionalExpense
	FROM (SELECT wRowNum = ROW_NUMBER() OVER (ORDER BY RowID)
		  ,[RowID]
		  ,[wOrderNo]
		  ,[wBookingRefRid]
		  ,[wBookingRid]
		  ,[wRoomBookingRid]
		  ,[wExpenseType]
		  ,[wExpenseSubtype]
		  ,[wPaymentMethod]
		  ,[wReceiptNo]
		  ,[wExpAmt]
		  ,[wTotalAmt]
		  ,[wCost]
		  ,[wCurrcode]
		  ,[wIsUseBlackCard]
		  ,[wRemark]
		  ,[wSeqNo]
		  ,[wCrtDt]
		  ,[wCrtBy]
		  ,[wUpdDt]
		  ,[wUpdBy]
		  ,[wBookingStatus]
		  ,[wSpaRid]
		  ,[wRestaurantRid]
		  ,[wTravelAgencyRid]
		  ,[wUnqualifiedRid]
		FROM [dbo].[eAdditionalExpense] WHERE wRoomBookingRid = @pRoomBookingRid) ADI

	SELECT * INTO #tmpBooking
	FROM (SELECT wRowNum = ROW_NUMBER() OVER (ORDER BY RowID)
		   ,RowID
		  ,[wBookingType]
		  ,[wRefNo]
		  ,[GUID]
		  ,[wReqCounterRid]
		  ,[wDebitCounterRid]
		  ,[wReqAgentCodeIn]
		  ,[wDebitAgentCodeIn]
		  ,[wReqCustomerRid]
		  ,[wDebitCustomerRid]
		  ,[wReqDepartment]
		  ,[wReqUserRid]
		  ,[wAsstBooker]
		  ,[wAssBookerTel]
		  ,[wApprovalAgentCodeIn]
		  ,[wDebitDt]
		  ,[wExpDt]
		  ,[wCancelDebitDt]
		  ,[wCancelReasonCd]
		  ,[wCancelBy]
		  ,[wOtherReason]
		  ,[wCancelDt]
		  ,[wCrtDt]
		  ,[wCrtBy]
		  ,[wUpdDt]
		  ,[wUpdBy]
		  ,[wTravePkgRid]
		  ,[wEventCodeRid]
		  ,[wAsstBookerEmail]
		  ,[wDeptFollwedCd]
		  ,[wStaffFollwedRid]
		  ,[wStaffTelephone]
		  ,[wOwnerAuthTelephone]
		  ,[wDepositAmt]
	  FROM [CRM].[dbo].[eBooking] EB WHERE RowID IN (SELECT [wBookingRefRid] FROM #tmpAdditionalExpense))EBK

	BEGIN TRY
	-- Try to make the transaction scope as small as possible to reduce locking
	IF @sBeginTranCount = 0
	BEGIN
		BEGIN TRAN;
	END;  

	SELECT @sRecCount = COUNT(1)    
	FROM  #tmpBooking; 
	DECLARE @sBookingRefRid BIGINT=0,@refNo VARCHAR(100), @sBookingRid BIGINT = 0;
	WHILE @sRuningIndex <= @sRecCount    
	BEGIN
		--EXEC spq.GetRowID @pMainCompNo, 'eBooking', @sRowID OUTPUT;
		SET @sBookingRid = 0;
		SELECT @sBookingRefRid=RowId
		FROM #tmpBooking	
		WHERE wRowNum = @sRuningIndex;

		---- Update row id and refNo
		SET @refNo = 'D' + FORMAT(NEXT VALUE FOR dbo.seqeAdditionalExpensesRefNo, '0000000')

		SET @sXMLBooking = (
		SELECT 
			0 AS RowID,
			wBookingType,
			@refNo AS wRefNo,
			wReqCounterRid,
			wDebitCounterRid,
			wReqAgentCodeIn,
			wDebitAgentCodeIn,
			wReqCustomerRid,
			wDebitCustomerRid,
			wReqDepartment,
			wReqUserRid,
			wAsstBooker,
			wAssBookerTel,
			wApprovalAgentCodeIn,
			wDebitDt,
			wExpDt,
			wCancelDebitDt,
			wCancelReasonCd,
			wCancelBy,
			wOtherReason,
			dbo.fnUTC8Now() AS wCancelDt,
			dbo.fnUTC8Now() AS wCrtDt,
			@pUpdatedBy AS wCrtBy,
			dbo.fnUTC8Now() AS wUpdDt,
			@pUpdatedBy AS wUpdBy,			
			wTravePkgRid,
			wEventCodeRid,
			wAsstBookerEmail,
			wDeptFollwedCd,
			wStaffFollwedRid,
			wStaffTelephone,
			wOwnerAuthTelephone,
			wDepositAmt
		FROM #tmpBooking	
		WHERE wRowNum = @sRuningIndex
		FOR XML RAW ('SetBookingResult'), ROOT ('DataSet'));

		IF @sXMLBooking IS NOT NULL
			EXEC [spa].[SetBooking] @sXMLBooking, 'I', @pMainCompNo, @pNonceToken, 'N', @sBookingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;
		
		UPDATE #tmpAdditionalExpense    
		SET [wBookingRefRid] = @sBookingRid
		WHERE [wBookingRefRid]= @sBookingRefRid;

		SET @sRuningIndex = @sRuningIndex + 1;
	END                      
	SET @sRuningIndex=1;
	SET @sRowID=0;
	SET @sRecCount=0;
		
	-- add addition exp
	DECLARE @aBookingRid BIGINT = 0;
	SELECT @sRecCount = COUNT(1)        
	FROM #tmpAdditionalExpense;        
	WHILE @sRuningIndex <= @sRecCount        
	BEGIN
		SET @sXMLBookingAdditionalExpenses = (
			SELECT  
				0 AS RowID,  
				s.wOrderNo,  
				s.wBookingRefRid,
				s.wBookingRid,
				@pNewRoomBookingRid AS wRoomBookingRid,  
				s.wExpenseType,  
				s.wExpenseSubtype,  
				s.wPaymentMethod,  
				ISNULL(s.wReceiptNo,'') AS wReceiptNo,  
				s.wExpAmt,  
				s.wTotalAmt,  
				s.wCost,  
				s.wCurrcode,  
				s.wIsUseBlackCard,  
				s.wRemark,  
				s.wBookingStatus,  
				s.wSeqNo,  
				dbo.fnUTC8Now() AS wCrtDt,  
				@pUpdatedBy AS wCrtBy,  
				dbo.fnUTC8Now() AS wUpdDt,  
				@pUpdatedBy AS wUpdBy
				,ISNULL(s.wSpaRid,-1) AS wSpaRid
				,s.wRestaurantRid
				,s.wTravelAgencyRid
				,s.wUnqualifiedRid
				FROM #tmpAdditionalExpense s
				WHERE s.wRowNum = @sRuningIndex
				FOR XML RAW ('Record'), ROOT ('DataSet'));
				
		SELECT @aBookingRid = wBookingRefRid FROM #tmpAdditionalExpense WHERE wRowNum = @sRuningIndex;

		IF @sXMLBookingAdditionalExpenses IS NOT NULL
			EXEC [spa].[SetBookingAdditionalExpenses] @sXMLBookingAdditionalExpenses, 'I', @pMainCompNo, @pNonceToken,'N', @aBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;
			
		SET @sRuningIndex = @sRuningIndex + 1;
	END;
		
	IF @sBeginTranCount = 0
		AND @@trancount > 0
		BEGIN
			COMMIT;
		END;

	-- Return RowID affected
	IF @pReturnResultSet = 'Y'
		SELECT  RowID
		FROM    #tmpAdditionalExpense;

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

	IF OBJECT_ID('tempdb..#tmpAdditionalExpense') IS NOT NULL
		DROP TABLE #tmpAdditionalExpense
	IF OBJECT_ID('tempdb..#tmpBooking') IS NOT NULL
		DROP TABLE #tmpBooking
END