CREATE PROCEDURE [spa].[ActionHotelChangeCheckIn]
    @pXMLBooking            XML = NULL,
    @pXML                   XML ,
    @pActionType            CHAR(1) ,
    @pMainCompNo            INT ,
    @pNonceToken            VARCHAR(64) ,
    @pIsUpdateChangeCheckIn BIT = NULL ,
    @pBookingRoomRowId      BIGINT = -1 OUTPUT ,
    @pErrCode               INT = 0 OUTPUT ,
    @pErrMsg                NVARCHAR(200) = '' OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        -- Select RowID from dbo.[eHotelChange]	

        DECLARE @sDocHandle         INT ,
                @sRecCount          INT= 0,
                @sActionType        CHAR(1),
                @sBeginTranCount    INT;

        SET @pErrCode = 0 ;
        SET @pErrMsg = '';
        SET @sActionType = @pActionType; -- 更新狀態

        SET @sBeginTranCount = @@trancount;

        IF OBJECT_ID('tempdb..#DataSet_HotelChange') IS NOT NULL
            DROP TABLE #DataSet_HotelChange;
        
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;

        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #DataSet_HotelChange
        FROM    OPENXML (@sDocHandle, 'DataSet/GetHotelChangeDateCheckInByBookingRoomIdResult', 1)
        WITH (  RowID BIGINT,
                wHotelBookingRid BIGINT,
                wRoomBookingRid BIGINT,
                wHotelRid BIGINT,
                wHotelRoomRid BIGINT,
                wAllotmentRid BIGINT,
                wAllotmentName NVARCHAR(50),
                wOrderNo NVARCHAR(60),
                wBedType VARCHAR(30),
                wStartDate DATE,
                wEndtDate DATE,
                wDayOfStay INT,
                wPaymentMethod VARCHAR(30),
                wCashReceiptNo NVARCHAR(40),
                wCashTransferReceiptNo VARCHAR(40),
                wGetKeyMethod VARCHAR(30),
                wCurrCode CHAR(3),
                wIncludeBreakfast CHAR(1),
                wUseExtraAllotment CHAR(1),
                wUseUpAllotment CHAR(1),
                wTotalAmount NUMERIC(18,4),
                wRoomNo NVARCHAR(20),
                wRemark NVARCHAR(500),
                wUpdDt DATETIME2(7),
                wUpdBy BIGINT,
                wReqUserRid BIGINT,
                wRequestStaffRid BIGINT,
                wStaffReqForAmendments VARCHAR(200),
                wReqDepartment VARCHAR(30),
                wAssistanceBookerName NVARCHAR(50),
                wAssistanceBookerPhone VARCHAR(100),
                wNewStartDate DATETIME2(7),
                wNewEndDate DATETIME2(7),
                UseBlackCard CHAR(1),
                UpdateCheckInPass CHAR(1),
                wAction VARCHAR(5),
                wReGetKey CHAR(1),
                wIsHotelChangeRecord CHAR(1),
                wReqCounterRid	BIGINT
        );

        BEGIN TRY
            -- Try to make the transaction scope as small as possible to reduce locking
            DECLARE @sOldBookingRoomRid BIGINT= 0,
                    @sHotelChangeRid    BIGINT = 0 ,
                    @sUpdatedBy         BIGINT= 0 ;

            DECLARE @totalAmount        DECIMAL= 0 ,
                    @newStartDate       DATE ,
                    @newEndDate         DATE ,
                    @startDate          DATE ,
                    @endDate            DATE ,
                    @wIsHotelChangeRecord CHAR(1) ,
                    @action             VARCHAR(5)= '' ,
                    @UpdatedDt          DATETIME2(7),
                    @sAction            VARCHAR(5)= '' ,
                    @sNewStartDate      DATE ,
                    @sNewEndDate        DATE;

            SELECT  @startDate          = wStartDate ,
                    @endDate            = wEndtDate ,
                    @newStartDate       = wNewStartDate ,
                    @newEndDate         = wNewEndDate ,
                    @sUpdatedBy         = wUpdBy ,
                    @wIsHotelChangeRecord = wIsHotelChangeRecord ,
                    @sOldBookingRoomRid  = wRoomBookingRid ,
                    @action             = wAction ,
                    @UpdatedDt          = wUpdDt
            FROM    #DataSet_HotelChange;
	
            DECLARE @vUpdatedDate DATETIME2(7) ,
                    @vUpdatedUsr VARCHAR(50),
                    @vUseAgencyAllotment CHAR(1);
	
            SELECT  @vUpdatedDate = br.wUpdDt , 
                    @vUpdatedUsr = u.wName, 
                    @vUseAgencyAllotment = br.wUseAgencyAllotment
            FROM    dbo.eBookingRoom br
            INNER JOIN RollsMary.dbo.mUsr u ON u.RowID = br.wUpdBy
            WHERE   br.RowID = @sOldBookingRoomRid;
            ----------------------------------------------------------------------------------

            IF @UpdatedDt < @vUpdatedDate
            BEGIN		 
                SET @pErrMsg = CONCAT('This record is already updated by ', @vUpdatedUsr);                 
                RETURN;
            END;
            ----------------------------------------------------------------------------------
			
            SELECT TOP 1 @sAction = wAction, @sNewStartDate = wNewStartDate, @sNewEndDate = wNewEndDate FROM dbo.eHotelChange WHERE wRoomBookingRid = @sOldBookingRoomRid ORDER BY wCrtDt DESC;
            IF @sAction = @action AND @sNewStartDate = @newStartDate AND @sNewEndDate = @newEndDate AND @pActionType = 'I'
            BEGIN		 
                SET @pErrMsg = N'數據重複輸入，請查看是否因為網絡原因卡頓而導致重複輸入';
                RETURN;
            END;
            ----------------------------------------------------------------------------------

            -- 如果訂單的入住、退房日期被其它用戶修改，不能再保存此單，必須退出后重新操作，否則會導致其他用戶的修改數據被舊數據覆蓋
            IF  @pActionType = 'I' AND EXISTS (SELECT 1 FROM dbo.eBookingRoom WHERE RowID = @sOldBookingRoomRid AND wStatus = 'A' AND (wStartDate != @startDate OR wEndtDate != @endDate)) 
            BEGIN	 
                DECLARE @sUpdUsrName NVARCHAR(100),
                        @sBookingDt NVARCHAR(100);

                SELECT @sUpdUsrName = CONCAT(N'【',u.wCName, '(', u.wUsrId ,')', N'】'),
                       @sBookingDt = CONCAT(N'【', FORMAT(br.wStartDate, 'yyyy-MM-dd'), N'至', FORMAT(br.wEndtDate, 'yyyy-MM-dd'), N'】')
                FROM  dbo.eBookingRoom AS br
                INNER JOIN RollsMary.dbo.mUsr AS u ON u.RowID = br.wUpdBy
                WHERE br.RowID = @sOldBookingRoomRid AND br.wStatus = 'A';

                SET @pErrMsg = CONCAT(N'保存失敗！訂單【入住日期】已被', @sUpdUsrName, N'修改為', @sBookingDt,N', 請退出後重新操作.');
                
                RETURN;
            END;
            ----------------------------------------------------------------------------------

            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;
	
            DECLARE @pBookingRid BIGINT = 0;
            IF @pXMLBooking IS NOT NULL
            BEGIN
                SET @pBookingRid = @sOldBookingRoomRid; ----由於按金插入數據的時候拿不到 BookingRoom 的資料，所以此處需要用此參數傳值到 setBooking -- navin  -- 2017-11-28

                EXEC [spa].[SetBooking] @pXMLBooking, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;
            END

            IF @pActionType = 'I' OR ( @pActionType = 'U' AND EXISTS (SELECT 1 FROM (SELECT TOP 1 * FROM eHotelChange WHERE wRoomBookingRid = @sOldBookingRoomRid ORDER BY RowID DESC) hc INNER JOIN #DataSet_HotelChange tmp ON tmp.RowID = hc.RowID ))
            BEGIN         			   
                DECLARE @sXMLBookingRoom XML,
                        @sRoomBookingRid BIGINT,
                        @sSeqNo INT;
               
                SELECT @sRoomBookingRid =wBookingRid FROM dbo.eBookingRoom WHERE RowID = @sOldBookingRoomRid
			   			                   
                SET @sXMLBookingRoom=(
                    SELECT  eRoom.RowID,
                            eRoom.wBookingType,
                            eRoom.[GUID],
                            eHotelChange.wReqCounterRid ,
                            eHotelChange.wDebitCounterRid,
                            eRoom.wReqAgentCodeIn ,
                            eRoom.wDebitAgentCodeIn ,
                            eHotelChange.wReqCustomerRid ,
                            eHotelChange.wDebitCustomerRid ,
                            eHotelChange.wReqDepartment,
                            eHotelChange.wReqUserRid ,
                            eHotelChange.wAsstBooker ,
                            eHotelChange.wAssBookerTel,
                            eHotelChange.wApprovalAgentCodeIn,
                            eRoom.wDebitDt,   
                            eRoom.wExpDt,
                            eRoom.wCancelDebitDt,
                            eRoom.wCancelReasonCd,
                            eRoom.wOtherReason,
                            eRoom.wCancelBy ,
                            eRoom.wCancelDt,
                            eHotelChange.wUpdBy ,
                            eHotelChange.wUpdDt ,
                            eRoom.wTravePkgRid ,
                            eRoom.wUseTravelPkg,
                            eRoom.wEventCodeRid ,
                            eRoom.wGiftReasonCd ,                        
                            eHotelChange.wAsstBookerEmail ,
                            eHotelChange.wDeptFollwedCd ,
                            eHotelChange.wStaffFollwedRid ,
                            eHotelChange.wStaffTelephone ,
                            eHotelChange.wOwnerAuthTelephone ,
                            eHotelChange.wDepositAmt,
                            eRoom.wDepositDebitDt, -- 用回原来的按金日期，否则Save不了（按金日期不能为空）
                            eHotelChange.wCoordinator ,
                            eHotelChange.wIsUser ,
                            eHotelChange.wUser 
                    FROM dbo.eBooking eRoom,dbo.eBooking eHotelChange 
                    WHERE eRoom.RowID=@sRoomBookingRid AND eHotelChange.RowID=@pBookingRid AND eRoom.wBookingType='ROOM' AND eHotelChange.wBookingType='CHANGEHOTEL' 
                    FOR XML RAW('SetBookingResult'), ROOT('DataSet')
                );

                IF @sXMLBookingRoom IS NOT NULL			   
                    EXEC [spa].[SetBooking] @sXMLBookingRoom, 'U', @pMainCompNo, @pNonceToken, 'N', @sRoomBookingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;
			   
                DECLARE @sXMLRoomDetails XML;
			   
                SET @sXMLRoomDetails=(
                    SELECT  eRoomDetails.RowID,
                            eRoomDetails.wBookingRid,
                            eRoomDetails.wHotelBookingRid,		
                            eRoomDetails.wRequestRid,		
                            eRoomDetails.wHotelRid,		
                            eRoomDetails.wHotelRoomRid,
                            eRoomDetails.wCounterRid,
                            eRoomDetails.wTravelAgencyRid,			
                            eHotelChange.wOrderNo,		
                            eRoomDetails.wBedType,		
                            eRoomDetails.wStartDate,		
                            eRoomDetails.wEndtDate,		
                            eRoomDetails.wDayOfStay,		
                            eRoomDetails.wPaymentMethod,		
                            eRoomDetails.wReceiptNo,		
                            eRoomDetails.wVoucherNo,		
                            eRoomDetails.wConfirmationNo,		
                            eHotelChange.wCashReceiptNo,		
                            eRoomDetails.wCashTransferReceiptNo,		
                            eRoomDetails.wGetKeyMethod,		
                            eRoomDetails.wCurrCode,		
                            eRoomDetails.wUseMemberCard,		
                            eRoomDetails.wIncludeBreakfast,		
                            eRoomDetails.wUseExtraAllotment,		
                            eRoomDetails.wUseUpAllotment,		
                            eRoomDetails.wTotalAmount,		
                            eRoomDetails.wAdditionalFee,
                            eRoomDetails.wActualTotalAmount,		
                            eRoomDetails.wTotalCost,		
                            eRoomDetails.wRoomNo,		
                            eRoomDetails.wGetKeyPasscode,		
                            eRoomDetails.wHasStaffGetKey,		
                            eRoomDetails.wHasClientGetKey,		
                            eRoomDetails.wReGetKeyDate,		
                            eRoomDetails.wSmsCount,		
                            eRoomDetails.wIsConsigned,		
                            eRoomDetails.wSameFloor,		
                            eRoomDetails.wRoomExpenseState,		
                            eRoomDetails.wCallCustomer,		
                            eRoomDetails.wQuickCollectKey,		
                            eRoomDetails.wIsCleaning,		
                            eRoomDetails.wWarmReminderSMS,		
                            eRoomDetails.wNoteRemark,		
                            eRoomDetails.wIsConnectedRoom,		
                            eRoomDetails.wRemark,
                            eRoomDetails.wCheckoutRemarks,		
                            eRoomDetails.wCrtDt,		
                            eRoomDetails.wCrtBy,		
                            eHotelChange.wUpdDt,		
                            eHotelChange.wUpdBy,		
                            eRoomDetails.wRoomSMSSent,		
                            eRoomDetails.wDisplayAgencyHotel,		
                            eRoomDetails.wUseAgencyAllotment,		
                            eRoomDetails.wAllotmentGroupRid ,		
                            eRoomDetails.wBookingStatus ,
                            eRoomDetails.wUnqualifiedRid,
                            eRoomDetails.wIsSmoke,
                            eRoomDetails.wIsExtraBed,
                            wOldBookingStatus = eRoomDetails.wBookingStatus
                    FROM dbo.eBookingRoom eRoomDetails, #DataSet_HotelChange eHotelChange  
                    WHERE eRoomDetails.RowID=@sOldBookingRoomRid AND eHotelChange.wRoomBookingRid=eRoomDetails.RowID  
                    FOR XML RAW('Record'), ROOT('DataSet')
                );

                IF @sXMLRoomDetails IS NOT NULL
                    EXEC [spa].[SetRoomBookingDetails] @sXMLRoomDetails, 'U', @pMainCompNo, @pNonceToken, 'N', @sRoomBookingRid, @sRoomBookingRid OUTPUT, @sSeqNo OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;
            END;

            EXEC [spa].[SetHotelChange] @pXML, @pMainCompNo, 0, @pNonceToken, 'Y', @pBookingRid, @pErrCode OUT, @pErrMsg OUT;
            IF ISNULL(@pActionType, '') = 'I' -- update【更改入住日期】，不可修改房間資料
                EXEC [spa].[SetBookingRoomByHotelChange] @pXML, @pActionType, @pMainCompNo, @pErrCode OUT, @pErrMsg OUT;

            SET @pActionType = 'I';
            IF @pIsUpdateChangeCheckIn = 1
            BEGIN
                SELECT TOP 1 RowID
                FROM    #DataSet_HotelChange
                WHERE   wIsHotelChangeRecord = 'Y';
                SET @pBookingRoomRowId = @sOldBookingRoomRid;
            END;
            ELSE
            BEGIN
                IF @wIsHotelChangeRecord = 'Y'
                    SET @pActionType = 'U';
                ELSE
                    SET @pActionType = 'I';
                --set activity log
                IF @pBookingRoomRowId > 0
                BEGIN
                    SET @pActionType = 'I';
                    IF @action <> 'CL'
                        EXEC [spa].[SetHotelCheckIn] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'Y', 'N', @pBookingRoomRowId, @pErrCode OUTPUT, @pErrMsg OUTPUT;

                    --Add addional expenses
                    EXEC [spa].[SetAdditionaExpensesFromChangeCheckInDate] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'N', @sOldBookingRoomRid, @pBookingRoomRowId, @sUpdatedBy, @pErrCode OUTPUT, @pErrMsg OUTPUT;
                    --Add Client details
                    EXEC [spa].[SetClientDetailsFromChangeCheckInDate] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'N', @sOldBookingRoomRid, @pBookingRoomRowId, @sUpdatedBy, @pErrCode OUTPUT, @pErrMsg OUTPUT;
                    --Add related document
                    EXEC [CRM_Doc].[spa].[SetRelatedDocumentFromChangeCheckIn] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'N', @sOldBookingRoomRid, @pBookingRoomRowId, @sUpdatedBy, @pErrCode OUTPUT, @pErrMsg OUTPUT;
                END;
                ELSE
                BEGIN
                    IF @action <> 'CL'
                        EXEC [spa].[SetHotelCheckIn] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'Y', 'N', @sOldBookingRoomRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;
														   
                    SET @pBookingRoomRowId = @sOldBookingRoomRid;
                END;
            END;

            --【房間入住記錄】 關聯到 【更改入住日期】
            IF @action <> 'CL' AND @sActionType = 'I' BEGIN
                SELECT TOP 1 @sHotelChangeRid = RowID FROM dbo.eHotelChange WHERE wBookingRid = @pBookingRid;
                IF @sHotelChangeRid > 0 BEGIN
                    UPDATE dbo.eHotelCheckIn SET wHotelChangeRid = @sHotelChangeRid WHERE  wRoomBookingRid = @pBookingRoomRowId AND wStatus = 'A';
                END
            END

            -- 【Calendar】 --> 【Mary】
            -- @pBookingRid 是 eHotelChange.wBookingRid，不是eBookingRoom.wBookingRid，需要另行獲取
            IF @action <> 'CL' BEGIN
                DECLARE @sBookingRid BIGINT; -- 房間預訂eBooking.RowId
					
                SELECT TOP(1) @sBookingRid = br.wBookingRid
                FROM dbo.eHotelChange AS hc
                INNER JOIN dbo.eBookingRoom AS br ON br.RowID = hc.wRoomBookingRid
                WHERE @pBookingRid = hc.wBookingRid AND br.wBookingStatus IN ('C', 'CI', 'CO', 'RF') AND br.wStatus = 'A'

                IF @sBookingRid IS NOT NULL AND @sBookingRid > 0
                    EXEC util.WriteMaryAgentActivitiesApiLog @pBookingRid = @sBookingRid, @pBookingType = 'ROOM';
            END

            --EXEC [spa].[SetActivityLog] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'N', @sHotelChangeRid, @pErrCode OUTPUT, @pErrMsg OUTPUT; 	

            --小單改變不影響大單改變，故注釋掉
            --IF (@newStartDate < @startDate OR @newEndDate > @endDate) AND @action<>'CL'
            --BEGIN
            --	UPDATE HBK
            --	SET HBK.wStartDate=(CASE WHEN @newStartDate < @startDate THEN @newStartDate ELSE HBK.wStartDate END)
            --				,HBK.wEndDate=(CASE WHEN @newEndDate > @endDate THEN @newEndDate ELSE HBK.wEndDate END),
            --				HBK.wUpdDt= dbo.fnUTC8Now()
            --				,HBK.wUpdBy=CHANGE.wUpdBy
            --	FROM dbo.eBookingHotel HBK
            --	INNER JOIN #DataSet_HotelChange CHANGE ON CHANGE.wHotelBookingRid = HBK.RowID
            --END

            -- Need to call below procedue to update amount in rolls mary
				
            SET @sRecCount = 1;

            -- Update RollsMary.dbo.eExpTran 中的 remark.
            DECLARE @vXMLUpdExp NVARCHAR(MAX) = '' ,
                    @vErrCode INT = 0 ,
                    @vErrMsg NVARCHAR(MAX);

            SET @vXMLUpdExp = (
                SELECT e.* 
                FROM RollsMary.dbo.eExpTran AS e 
                INNER JOIN dbo.eHotelChange AS hc ON e.wBookingActionRid = hc.RowID AND e.wRefRid = hc.wRoomBookingRid
                INNER JOIN dbo.eBookingRoom br ON hc.wRoomBookingRid = br.RowID
                INNER JOIN dbo.eBookingHotel bh ON br.wHotelBookingRid = bh.RowID AND bh.wBookingRid = e.wBookingRid
                WHERE e.wExpGroup = 'RCRM' AND e.wExpType = 'I' AND e.wDeductType = 'DC' AND e.wIsDeposit <> 'Y' AND hc.wRoomBookingRid = @pBookingRoomRowId
                FOR XML RAW('Record') , ROOT('DataSet')
            );

            IF @vXMLUpdExp != ''
            BEGIN
                EXEC spa.SetCrmExpTran  @pXML = @vXMLUpdExp, -- xml
                                        @pActionType = 'U', -- char(1)
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

            IF @sBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                COMMIT;		
            END;
	
            SELECT  @sRecCount AS wRecordCount;

            RETURN;
        END TRY
        BEGIN CATCH
            DECLARE @sErrorNum INT ,
                    @sCatchErrorMessage NVARCHAR(4000) ,
                    @xstate INT ,
                    @sProcedureName VARCHAR(100) ,
                    @sRtnCodeLog INT ,
                    @sErrMessageLog NVARCHAR(4000);
			
            SELECT  @sErrorNum = ERROR_NUMBER() ,
                    @sCatchErrorMessage = ERROR_MESSAGE() ,
                    @xstate = XACT_STATE() ,
                    @sProcedureName = OBJECT_NAME(@@PROCID);
			
            IF ISNULL(@pErrCode, 0) = 0
            BEGIN
                SET @pErrCode = 999;
            END;

            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ', @sCatchErrorMessage);

            IF @sBeginTranCount = 0 AND ( @xstate = 1 OR @xstate = -1 )
            BEGIN
                ROLLBACK;
            END;

            -- Write Log
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH;

        IF OBJECT_ID('tempdb..#DataSet_HotelChange') IS NOT NULL
            DROP TABLE #DataSet_HotelChange;
    END;