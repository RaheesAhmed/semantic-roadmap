CREATE PROCEDURE [spa].[SetAdditionalExpenses]
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

	--select * ,'' PaymentMethodName,'' wExpenseSubtypeName, '' wExpenseTypeName, '' wStatusName  from dbo.[eAdditionalExpense]

        DECLARE @sThisTableName VARCHAR(50) = 'eAdditionalExpense' ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT ,
            @sSeqNo INT = 0 ,
            @vNow DATETIME2 ,
            @sActionAffectedXML NVARCHAR(MAX) = '';

        DECLARE @sBeginTranCount INT = 0;
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );

        SET @sBeginTranCount = @@trancount;
        SET @vNow = dbo.fnUTC8Now();

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
 
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetAdditionalExpense
        FROM    OPENXML (@sDocHandle, 'DataSet/SetAdditionalExpensesResult', 1)  
WITH (
    RowID BIGINT ,
    TempRowID BIGINT, 
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
    wUpdBy BIGINT
	,wSpaRid BIGINT
	,wRestaurantRid BIGINT   
	,wTravelAgencyRid BIGINT  
	,wPersonRid BIGINT 
   );  


        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF @pActionType = 'I'
                BEGIN  
			-- Set RowID by Sequence  
                    UPDATE  #sDataSet_SetAdditionalExpense
                    SET     TempRowID = RowID ,
                            RowID = 0 ,
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

                            DECLARE @pBookingRefRid BIGINT;
                            DECLARE @pTempRowRid BIGINT;			
                            SET @pTempRowRid = 0;

                            EXEC [spa].[SetAdditionExpenseBooking] @pXML, @pActionType, @pMainCompNo, 0, 'N', @pTempRowRid, @pBookingRefRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;

                            IF @pBookingRid > 0
                                BEGIN
                                    UPDATE  #sDataSet_SetAdditionalExpense
                                    SET     wBookingRefRid = @pBookingRefRid ,
                                            wBookingRid = @pBookingRid;
                                END;
                            UPDATE  #sDataSet_SetAdditionalExpense
                            SET     RowID = @sRowID ,
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
                                    s.wBookingRid ,
                                    ( CASE WHEN s.wRoomBookingRid < 1 THEN -1
                                           ELSE s.wRoomBookingRid
                                      END ) ,
                                    s.wExpenseType ,
                                    s.wExpenseSubtype ,
                                    s.wPaymentMethod ,
                                    ISNULL(s.wReceiptNo, '') ,
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
    	
                        UPDATE  eae
                        SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
                                eae.wOrderNo = tmp.wOrderNo ,
                                eae.wExpenseType = tmp.wExpenseType ,
                                eae.wExpenseSubtype = tmp.wExpenseSubtype ,
                                eae.wPaymentMethod = tmp.wPaymentMethod ,
                                eae.wReceiptNo = ISNULL(tmp.wReceiptNo, '') ,
                                eae.wExpAmt = tmp.wExpAmt ,
                                eae.wTotalAmt = tmp.wTotalAmt ,
                                eae.wCost = tmp.wCost ,
                                eae.wCurrcode = tmp.wCurrcode ,
                                eae.wIsUseBlackCard = tmp.wIsUseBlackCard ,
                                eae.wRemark = tmp.wRemark ,
                                eae.wBookingStatus = tmp.wBookingStatus ,
                                eae.wUnqualifiedRid = ISNULL(tmp.wUnqualifiedRid, 0) ,
                                eae.wSeqNo = tmp.wSeqNo ,
                                eae.wUpdBy = tmp.wUpdBy ,
                                eae.wUpdDt = dbo.fnUTC8Now() ,
                                eae.wSpaRid = tmp.wSpaRid ,
                                eae.wRestaurantRid = tmp.wRestaurantRid ,
                                eae.wTravelAgencyRid = tmp.wTravelAgencyRid
								--如果是Update，不能修改PersonRid，此單只能在Insert時確定客戶，之後不能再轉換給另外一個人
                                --eae.wPersonRid = tmp.wPersonRid
                        FROM    dbo.eAdditionalExpense AS eae
                                INNER JOIN #sDataSet_SetAdditionalExpense tmp ON eae.RowID = tmp.RowID
                        WHERE   eae.RowID = tmp.RowID
                                AND tmp.RowID IN (
                                SELECT  RowID
                                FROM    eAdditionalExpense ae
                                WHERE   tmp.RowID = ae.RowID );
	
                        UPDATE  dsa
                        SET     TempRowID = RowID ,
                                wSeqNo = 0
                        FROM    #sDataSet_SetAdditionalExpense dsa;

                        SELECT  @sRecCount = COUNT(*)
                        FROM    #sDataSet_SetAdditionalExpense;  

                        DECLARE @tempAeRowID BIGINT;

                        WHILE @sRuningIndex <= @sRecCount
                            BEGIN  

                                DECLARE @pTempRowId BIGINT = 0 ,
                                    @pOldBookingRefRid BIGINT = 0;
                                SELECT  @pTempRowId = TempRowID ,
                                        @pOldBookingRefRid = wBookingRefRid
                                FROM    #sDataSet_SetAdditionalExpense
                                WHERE   wRowNum = @sRuningIndex;

                                SELECT  @tempAeRowID = RowID
                                FROM    #sDataSet_SetAdditionalExpense
                                WHERE   wRowNum = @sRuningIndex;

                                IF ( SELECT COUNT(*)
                                     FROM   eAdditionalExpense ae
                                     WHERE  RowID = @tempAeRowID
                                   ) < 1
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

                                        EXEC [spa].[SetAdditionExpenseBooking] @pXML, 'I', @pMainCompNo, @pNonceToken, 'N', @pTempRowId, @pBookingRefRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;	

                                        IF @pBookingRefRid > 0
                                            BEGIN
                                                UPDATE  #sDataSet_SetAdditionalExpense
                                                SET     wBookingRefRid = @pBookingRefRid
                                                WHERE   wRowNum = @sRuningIndex;  									
                                            END;

                                        UPDATE  #sDataSet_SetAdditionalExpense
                                        SET     RowID = @sRowID ,
                                                wSeqNo = @sSeqNo
                                        WHERE   wRowNum = @sRuningIndex;  
                                    END;
                                ELSE
                                    BEGIN
                                        SET @pBookingRefRid = @pOldBookingRefRid;
                                        EXEC [spa].[SetAdditionExpenseBooking] @pXML, 'U', @pMainCompNo, @pNonceToken, 'N', @pOldBookingRefRid, @pBookingRefRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;
                                    END;
		   		
                                EXEC [spa].[SeteVoucherForAdditionalExp] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pOldBookingRefRid, @pBookingRefRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;
				
                                SET @sRuningIndex = @sRuningIndex + 1;  
                            END;
	
	-- Select RowID from eAdditionalExpense ae Where RowID = ae.RowID

                        DELETE  FROM #sDataSet_SetAdditionalExpense
                        WHERE   RowID IN ( SELECT   RowID
                                           FROM     eAdditionalExpense ae
                                           WHERE    RowID = ae.RowID );

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
                                        s.wBookingRid ,
                                        ( CASE WHEN s.wRoomBookingRid < 1 THEN -1
                                               ELSE s.wRoomBookingRid
                                          END ) ,
                                        s.wExpenseType ,
                                        s.wExpenseSubtype ,
                                        s.wPaymentMethod ,
                                        ISNULL(s.wReceiptNo, '') ,
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
                                        s.wTravelAgencyRid,
										s.wPersonRid
                                FROM    #sDataSet_SetAdditionalExpense s;  

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

	 
                    END;   
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
		  
    END;