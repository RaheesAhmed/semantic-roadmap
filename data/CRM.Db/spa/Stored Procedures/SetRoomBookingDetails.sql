CREATE PROCEDURE [spa].[SetRoomBookingDetails]
    @pXML XML ,
    @pActionType CHAR(1) , -- I/U/D
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pReturnResultSet CHAR(1) = 'N' ,
    @pBookingRid BIGINT ,
    @pRoomBookingDetailRid BIGINT OUTPUT ,
    @wSeqNo INT OUTPUT ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
AS
    BEGIN
        SET NOCOUNT ON; 

        DECLARE @sThisTableName VARCHAR(50) = 'eBookingRoom' ,
            @sBeginTranCount INT= 0 ,
            @sRecCount INT= 0 ,
            @sRuningIndex INT= 1 ,
            @sRowID BIGINT= 0 ,
            @sRequestNo VARCHAR(30) ,
            @vNow DATETIME2 = dbo.fnUTC8Now() ,
            @sActionAffectedXML NVARCHAR(MAX) = '' ,
            @vMthEndYearMth VARCHAR(6) ,
            @vDateUsingCRM DATETIME2 ,
            @sDocHandle INT;
    
        SET @sBeginTranCount = @@trancount;
            
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #DataSet_SetRoomBookingDetails
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)        
        WITH (		
                RowID BIGINT,
                wBookingRid BIGINT,
                wHotelBookingRid BIGINT,		
                wRequestRid BIGINT,		
                wHotelRid BIGINT,		
                wHotelRoomRid BIGINT,
                wCounterRid BIGINT,
                wTravelAgencyRid BIGINT,			
                wOrderNo NVARCHAR(60),		
                wBedType VARCHAR(30),		
                wStartDate DATE,		
                wEndtDate DATE,		
                wDayOfStay INT,		
                wPaymentMethod VARCHAR(30),		
                wReceiptNo NVARCHAR(50),		
                wVoucherNo VARCHAR(40),		
                wConfirmationNo NVARCHAR(40),		
                wCashReceiptNo NVARCHAR(40),		
                wCashTransferReceiptNo VARCHAR(40),		
                wGetKeyMethod VARCHAR(30),		
                wCurrCode CHAR(3),		
                wUseMemberCard CHAR(1),		
                wIncludeBreakfast CHAR(1),		
                wUseExtraAllotment CHAR(1),		
                wUseUpAllotment CHAR(1),		
                wTotalAmount NUMERIC(18, 4),		
                wAdditionalFee NUMERIC(18,4),
                wActualTotalAmount NUMERIC(18,4),		
                wTotalCost NUMERIC(18, 4),		
                wRoomNo NVARCHAR(20),		
                wGetKeyPasscode VARCHAR(10),		
                wHasStaffGetKey CHAR(1),		
                wHasClientGetKey CHAR(1),		
                wReGetKeyDate DATE,		
                wSmsCount INT,		
                wIsConsigned CHAR(1),		
                wSameFloor CHAR(1),		
                wRoomExpenseState VARCHAR(30),		
                wCallCustomer CHAR(1),		
                wQuickCollectKey CHAR(1),		
                wIsCleaning CHAR(1),		
                wWarmReminderSMS CHAR(1),		
                wNoteRemark CHAR(1),		
                wIsConnectedRoom CHAR(1),	
                wIsSmoke CHAR(1),
                wIsExtraBed CHAR(1),	
                wRemark NVARCHAR(500),
                wCheckoutRemarks NVARCHAR(500),		
                wCrtDt DATETIME2(7),		
                wCrtBy BIGINT,		
                wUpdDt DATETIME2(7),		
                wUpdBy BIGINT,		
                wRoomSMSSent CHAR(1),		
                wDisplayAgencyHotel CHAR(1),		
                wUseAgencyAllotment CHAR(1),		
                wAllotmentGroupRid BIGINT,		
                wBookingStatus VARCHAR(5),
                wUnqualifiedRid BIGINT,
                wOldBookingStatus VARCHAR(5)
        );

        DECLARE @startDate DATE ,
            @endDate DATE ,
            @pwRequestIRId BIGINT= -1 ,
            @sRoomBookingOldStatus VARCHAR(30)= '';
        DECLARE @roomBookingRowId BIGINT ,
            @roomBookingStatus VARCHAR(30) ,
            @updateBy BIGINT ,
            @sHotelBookingRid BIGINT= -1;

        SELECT  @startDate = wStartDate ,
                @endDate = wEndtDate ,
                @roomBookingRowId = RowID ,
                @pwRequestIRId = wRequestRid ,
                @sHotelBookingRid = wHotelBookingRid ,
                @roomBookingStatus = wBookingStatus ,
                @updateBy = wUpdBy
        FROM    #DataSet_SetRoomBookingDetails;

        --- 确保房间金额货币是跟随扣数场馆的默认货币
        UPDATE tmp SET tmp.wCurrCode = sc.wCurrCode 
            FROM #DataSet_SetRoomBookingDetails AS tmp 
                 INNER JOIN dbo.eBooking AS b ON tmp.wBookingRid = b.RowID 
                 INNER JOIN dbo.mServiceCounter AS sc ON sc.RowID = b.wDebitCounterRid;

        BEGIN TRY
            --------------------------------------------------------------------------Checking-----------------------------------------------------------------------------
            DECLARE @sErrorMsg NVARCHAR(MAX);
            IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType NOT IN ('I', 'U', 'D')
                SET @sErrorMsg = N'非法操作！';
        
            IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType IN ('U', 'D')
            BEGIN
                DECLARE @sBookingType VARCHAR(30) = 'ROOM';
                DECLARE @sCurrentBookingStatus VARCHAR(5); -- DB当前状态
                DECLARE @sOldBookingStatus VARCHAR(5); -- 上一次Get數據時的狀態
                DECLARE @sNewBookingStatus VARCHAR(5); -- Save订单新状态
                DECLARE @sLangCd VARCHAR(10) = 'zh-TW';
                SELECT
                    @sCurrentBookingStatus = ebr.wBookingStatus, 
                    @sOldBookingStatus = sbr.wOldBookingStatus,
                    @sNewBookingStatus = sbr.wBookingStatus
                FROM dbo.eBookingRoom AS ebr 
                INNER JOIN #DataSet_SetRoomBookingDetails AS sbr ON sbr.RowID = ebr.RowID AND sbr.wBookingRid = ebr.wBookingRid
                WHERE ebr.wBookingRid = @pBookingRId;

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


            -- Try to make the transaction scope as small as possible to reduce locking	
            IF EXISTS(SELECT 1 FROM #DataSet_SetRoomBookingDetails WHERE ISNULL(wBookingStatus, 'P') != 'P'AND ISNULL(wBookingStatus, 'P') != 'CL'
                AND ISNULL(wBookingStatus, 'P') != 'UQ' AND wHotelRoomRid <= 0 AND ISNULL(wUseAgencyAllotment, 'N') = 'N')
            BEGIN
                DECLARE @eXml AS NVARCHAR(MAX) ,
                    @eErrCode AS INT ,
                    @eErrMsg NVARCHAR(200);
                SET @eXml = CONVERT(NVARCHAR(MAX), @pXML);
                EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, 'spa.SetRoomBookingDetails', @eXml, @eErrCode OUTPUT, @eErrMsg OUTPUT;
                THROW 50001, N'無法保存, 不正確的酒店資料, 請把詳細的輸入步驟發給 IT 部, Terry. 謝謝', 1;
            END

            IF @pActionType = 'U' AND EXISTS(SELECT 1 FROM dbo.eBookingRoom WHERE RowID = @roomBookingRowId AND wStatus = 'A' AND wBookingStatus != 'P') 
                AND EXISTS(SELECT 1 FROM #DataSet_SetRoomBookingDetails WHERE RowID = @roomBookingRowId AND wBookingStatus = 'P')
                THROW 50001, N'無法保存, 不是處理中狀態的訂單不能再修改為處理中, 請退出後再操作.', 1;
            
            -- 如果訂單的入住、退房日期被其它用戶修改，不能再保存此單，必須退出后重新操作，否則會導致其他用戶的修改數據被舊數據覆蓋
            IF @pActionType = 'U' AND EXISTS (SELECT 1 FROM dbo.eBookingRoom WHERE RowID = @roomBookingRowId AND ISNULL(wBookingStatus, 'P') != 'P' AND wStatus = 'A' AND (wStartDate != @startDate OR wEndtDate != @endDate)) 
            BEGIN
                DECLARE @sUpdUsrName NVARCHAR(100),
                        @sBookingDt NVARCHAR(100);
                SELECT  
                    @sUpdUsrName = CONCAT(N'【',u.wCName, '(', u.wUsrId ,')', N'】'),
                    @sBookingDt = CONCAT(N'【', FORMAT(br.wStartDate, 'yyyy-MM-dd'), N'至', FORMAT(br.wEndtDate, 'yyyy-MM-dd'), N'】')
                FROM  dbo.eBookingRoom br
                INNER JOIN RollsMary.dbo.mUsr u ON u.RowID = br.wUpdBy
                WHERE br.RowID = @roomBookingRowId AND br.wStatus = 'A';

                SET @pErrMsg = CONCAT(N'保存失敗！訂單【入住日期】已被', @sUpdUsrName, N'修改為', @sBookingDt,N', 請退出後重新操作.');
                THROW 50001, @pErrMsg, 1;
            END

            IF @pActionType = 'U'
            BEGIN
                DECLARE @vOldBookingStatus VARCHAR(30);
                SELECT @vOldBookingStatus= wBookingStatus FROM dbo.eBookingRoom WHERE RowID = @roomBookingRowId
                IF  ((@vOldBookingStatus='RF' OR @vOldBookingStatus='CL' OR @vOldBookingStatus='UQ') AND @vOldBookingStatus!=@roomBookingStatus)  --状态变为RF,CL,UQ 后 不能再更改状态了
                     OR(@vOldBookingStatus='CI' AND @roomBookingStatus IN('CL','UQ','P'))--状态变成已入住后,不能再把状态更改为'CL','UQ','P'
                     OR(@vOldBookingStatus='C' AND @roomBookingStatus IN('P','CL','UQ'))--状态变成已入住后,不能再把状态更改为'P','CL','UQ'
                     OR(@vOldBookingStatus='CO' AND @roomBookingStatus NOT IN('CI','CO'))-- 状态变成已退房后,状态只能更改为已入住                 
                BEGIN
                   SET @pErrMsg = dbo.fnGetErrorMsg('1001','zh-TW');
                   THROW 50001, @pErrMsg, 1;
                END
            END

            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
                
            IF @pActionType = 'I'
                BEGIN
                    SET @wSeqNo = ( SELECT  ISNULL(MAX(wSeqNo), 0) + 1
                                    FROM    eBookingRoom br
                                    WHERE   wHotelBookingRid = @sHotelBookingRid
                                  );
        
        ---- Set RowID by Sequence		
                    UPDATE  #DataSet_SetRoomBookingDetails
                    SET     [RowID] = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #DataSet_SetRoomBookingDetails;        
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN        
        
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;		
                    
                            UPDATE  #DataSet_SetRoomBookingDetails
                            SET     RowID = @sRowID ,
                                    wBookingRid = @pBookingRid
                            WHERE   wRowNum = @sRuningIndex;        
                            SET @sRuningIndex = @sRuningIndex + 1;
                
                        END;    		                

                    SET @pRoomBookingDetailRid = @sRowID;		
                    SET @roomBookingRowId = @pRoomBookingDetailRid;

                    INSERT  INTO dbo.[eBookingRoom]
                            ( RowID ,
                              wBookingRid ,
                              wHotelBookingRid ,
                              wRequestRid ,
                              wHotelRid ,
                              wHotelRoomRid ,
                              wTravelAgencyRid ,
                              wOrderNo ,
                              wBedType ,
                              wStartDate ,
                              wEndtDate ,
                              wDayOfStay ,
                              wPaymentMethod ,
                              wReceiptNo ,
                              wVoucherNo ,
                              wConfirmationNo ,
                              wCashReceiptNo ,
                              wCashTransferReceiptNo ,
                              wGetKeyMethod ,
                              wCurrCode ,
                              wUseMemberCard ,
                              wIncludeBreakfast ,
                              wUseExtraAllotment ,
                              wUseUpAllotment ,
                              wTotalAmount ,
                              wAdditionalFee ,
                              wActualTotalAmount ,
                              wTotalCost ,
                              wRoomNo ,
                              wGetKeyPasscode ,
                              wHasStaffGetKey ,
                              wHasClientGetKey ,
                              wReGetKeyDate ,
                              wSmsCount ,
                              wIsConsigned ,
                              wSameFloor ,
                              wRoomExpenseState ,
                              wCallCustomer ,
                              wQuickCollectKey ,
                              wIsCleaning ,
                              wWarmReminderSMS ,
                              wNoteRemark ,
                              wIsConnectedRoom ,
                              wIsSmoke,
                              wIsExtraBed,
                              wRemark ,
                              wCheckoutRemarks ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy ,
                              wRoomSMSSent ,
                              wDisplayAgencyHotel ,
                              wUseAgencyAllotment ,
                              wAllotmentGroupRid ,
                              wBookingStatus ,
                              wUnqualifiedRid ,
                              wCounterRid ,
                              wStatus ,
                              wSeqNo 
                            )
                            SELECT  s.RowID ,
                                    s.wBookingRid ,
                                    s.wHotelBookingRid ,
                                    s.wRequestRid ,
                                    s.wHotelRid ,
                                    s.wHotelRoomRid ,
                                    s.wTravelAgencyRid ,
                                    s.wOrderNo ,
                                    s.wBedType ,
                                    s.wStartDate ,
                                    s.wEndtDate ,
                                    s.wDayOfStay ,
                                    s.wPaymentMethod ,
                                    s.wReceiptNo ,
                                    s.wVoucherNo ,
                                    s.wConfirmationNo ,
                                    s.wCashReceiptNo ,
                                    s.wCashTransferReceiptNo ,
                                    s.wGetKeyMethod ,
                                    s.wCurrCode ,
                                    s.wUseMemberCard ,
                                    s.wIncludeBreakfast ,
                                    s.wUseExtraAllotment ,
                                    s.wUseUpAllotment ,
                                    s.wTotalAmount ,
                                    s.wAdditionalFee ,
                                    s.wActualTotalAmount ,
                                    s.wTotalCost ,
                                    s.wRoomNo ,
                                    s.wGetKeyPasscode ,
                                    s.wHasStaffGetKey ,
                                    s.wHasClientGetKey ,
                                    s.wReGetKeyDate ,
                                    s.wSmsCount ,
                                    s.wIsConsigned ,
                                    s.wSameFloor ,
                                    s.wRoomExpenseState ,
                                    s.wCallCustomer ,
                                    s.wQuickCollectKey ,
                                    s.wIsCleaning ,
                                    s.wWarmReminderSMS ,
                                    s.wNoteRemark ,
                                    s.wIsConnectedRoom ,
                                    s.wIsSmoke,
                                    s.wIsExtraBed,
                                    s.wRemark ,
                                    s.wCheckoutRemarks ,
                                    dbo.fnUTC8Now() ,
                                    s.wCrtBy ,
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy ,
                                    s.wRoomSMSSent ,
                                    s.wDisplayAgencyHotel ,
                                    s.wUseAgencyAllotment ,
                                    s.wAllotmentGroupRid ,
                                    s.wBookingStatus ,
                                    ISNULL(s.wUnqualifiedRid, 0) ,
                                    s.wCounterRid ,
                                    'A' AS wStatus ,
                                    @wSeqNo 
                            FROM    #DataSet_SetRoomBookingDetails s;

                    EXEC spa.SetBookingStatus @pwRequestIRId, @updateBy, @sHotelBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;
                END;

            IF @pActionType = 'U'
                BEGIN

                    SELECT  @sRoomBookingOldStatus = wBookingStatus ,
                            @wSeqNo = wSeqNo
                    FROM    dbo.eBookingRoom
                    WHERE   RowID = @roomBookingRowId;

                    SET @pRoomBookingDetailRid = @roomBookingRowId;	
                    IF @sRoomBookingOldStatus = 'P'
                        BEGIN
                            UPDATE  ehr
                            SET     ehr.wBedType = tmp.wBedType ,
                                    ehr.wStartDate = tmp.wStartDate ,
                                    ehr.wEndtDate = tmp.wEndtDate ,
                                    ehr.wDayOfStay = tmp.wDayOfStay ,
                                    ehr.wPaymentMethod = tmp.wPaymentMethod ,
                                    ehr.wAllotmentGroupRid = tmp.wAllotmentGroupRid ,
                                    ehr.wCashReceiptNo = tmp.wCashReceiptNo ,
                                    ehr.wCashTransferReceiptNo = tmp.wCashTransferReceiptNo ,
                                    ehr.wUseExtraAllotment = tmp.wUseExtraAllotment ,
                                    ehr.wUseUpAllotment = tmp.wUseUpAllotment ,
                                    ehr.wGetKeyMethod = tmp.wGetKeyMethod ,
                                    ehr.wUseMemberCard = tmp.wUseMemberCard ,
                                    ehr.wCurrCode = tmp.wCurrCode ,
                                    ehr.wRemark = tmp.wRemark ,
                                    ehr.wOrderNo = tmp.wOrderNo 
                            FROM    dbo.eBookingRoom AS ehr
                                    INNER JOIN #DataSet_SetRoomBookingDetails tmp ON ehr.RowID = tmp.RowID
                            WHERE   ehr.RowID = tmp.RowID;

                            UPDATE eb
                            SET    eb.wCancelDebitDt= ( CASE WHEN ( ( tmp.wBookingStatus = 'CL'
                                                                 OR tmp.wBookingStatus = 'UQ'
                                                               )
                                                               AND eb.wCancelDebitDt IS NULL
                                                             ) THEN dbo.fnUTC8Now()
                                                        ELSE eb.wCancelDebitDt
                                                   END ) ,
                                   eb.wCancelDt = ( CASE WHEN ( ( tmp.wBookingStatus = 'RF'
                                                            OR tmp.wBookingStatus = 'CL'
                                                            OR tmp.wBookingStatus = 'UQ'
                                                          )
                                                          AND eb.wCancelDt IS NULL
                                                        ) THEN dbo.fnUTC8Now()
                                                   ELSE eb.wCancelDt
                                              END ) 
                            FROM   dbo.eBooking AS eb
                                   INNER JOIN #DataSet_SetRoomBookingDetails tmp ON eb.RowID = tmp.wBookingRid
                            WHERE  eb.RowID=tmp.wBookingRid
                        END
                    DECLARE @pHotelChangeRid BIGINT = -1;
                    EXEC spa.GenrateChangeCheckInRecord @roomBookingRowId, @updateBy, @pMainCompNo, @roomBookingStatus, @pNonceToken, @pHotelChangeRid OUT,  @pErrCode OUTPUT, @pErrMsg OUTPUT;
                    --當C、RF狀態下， 【房間入住記錄】 關聯到 【更改入住日期】
                    IF @pHotelChangeRid > 0 BEGIN
                        UPDATE dbo.eHotelCheckIn SET wHotelChangeRid = @pHotelChangeRid WHERE   wRoomBookingRid = @roomBookingRowId AND wStatus = 'A';
                    END
                    UPDATE  ehr
                    SET     ehr.wHotelRid = tmp.wHotelRid ,
                            ehr.wHotelRoomRid = tmp.wHotelRoomRid ,
                            ehr.wTravelAgencyRid = tmp.wTravelAgencyRid ,
                            ehr.wOrderNo = tmp.wOrderNo ,
                            ehr.wBedType = tmp.wBedType ,
                            ehr.wStartDate = tmp.wStartDate ,
                            ehr.wEndtDate = tmp.wEndtDate ,
                            ehr.wDayOfStay = tmp.wDayOfStay ,
                            ehr.wPaymentMethod = tmp.wPaymentMethod ,
                            ehr.wReceiptNo = tmp.wReceiptNo ,
                            ehr.wVoucherNo = tmp.wVoucherNo ,
                            ehr.wConfirmationNo = tmp.wConfirmationNo ,
                            ehr.wCashReceiptNo = tmp.wCashReceiptNo ,
                            ehr.wCashTransferReceiptNo = tmp.wCashTransferReceiptNo ,
                            ehr.wGetKeyMethod = tmp.wGetKeyMethod ,
                            ehr.wCurrCode = tmp.wCurrCode ,
                            ehr.wUseMemberCard = tmp.wUseMemberCard ,
                            ehr.wIncludeBreakfast = tmp.wIncludeBreakfast ,
                            ehr.wUseExtraAllotment = tmp.wUseExtraAllotment ,
                            ehr.wUseUpAllotment = tmp.wUseUpAllotment ,
                            ehr.wTotalAmount = tmp.wTotalAmount ,
                            ehr.wAdditionalFee = tmp.wAdditionalFee ,
                            ehr.wActualTotalAmount = tmp.wActualTotalAmount ,
                            ehr.wTotalCost = tmp.wTotalCost ,
                            ehr.wRoomNo = tmp.wRoomNo ,
                            ehr.wGetKeyPasscode = tmp.wGetKeyPasscode ,
                            ehr.wHasStaffGetKey = tmp.wHasStaffGetKey ,
                            ehr.wHasClientGetKey = tmp.wHasClientGetKey ,
                            ehr.wReGetKeyDate = tmp.wReGetKeyDate ,
                            ehr.wSmsCount = tmp.wSmsCount ,
                            ehr.wIsConsigned = tmp.wIsConsigned ,
                            ehr.wSameFloor = tmp.wSameFloor ,
                            ehr.wRoomExpenseState = tmp.wRoomExpenseState ,
                            ehr.wCallCustomer = tmp.wCallCustomer ,
                            ehr.wQuickCollectKey = tmp.wQuickCollectKey ,
                            ehr.wIsCleaning = tmp.wIsCleaning ,
                            ehr.wWarmReminderSMS = tmp.wWarmReminderSMS ,
                            ehr.wNoteRemark = tmp.wNoteRemark ,
                            ehr.wIsConnectedRoom = tmp.wIsConnectedRoom ,
                            ehr.wIsSmoke = tmp.wIsSmoke ,
                            ehr.wIsExtraBed = tmp.wIsExtraBed ,
                            ehr.wRemark = tmp.wRemark ,
                            ehr.wCheckoutRemarks = tmp.wCheckoutRemarks ,
                            ehr.wRoomSMSSent = tmp.wRoomSMSSent ,
                            ehr.wDisplayAgencyHotel = tmp.wDisplayAgencyHotel ,
                            ehr.wUseAgencyAllotment = tmp.wUseAgencyAllotment ,
                            ehr.wUpdBy = CASE WHEN tmp.wUpdBy IS NOT NULL AND tmp.wUpdBy > 0 THEN tmp.wUpdBy ELSE ehr.wUpdBy END ,
                            ehr.wUpdDt = dbo.fnUTC8Now() ,
                            ehr.wBookingStatus = tmp.wBookingStatus ,
                            ehr.wUnqualifiedRid = ISNULL(tmp.wUnqualifiedRid, 0) ,
                            ehr.wAllotmentGroupRid = tmp.wAllotmentGroupRid
                    FROM    dbo.eBookingRoom AS ehr
                            INNER JOIN #DataSet_SetRoomBookingDetails tmp ON ehr.RowID = tmp.RowID
                    WHERE   ehr.RowID = tmp.RowID;										
                    EXEC spa.SetBookingStatus @pwRequestIRId, @updateBy, @sHotelBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;	
                END;

            IF @roomBookingStatus = 'CO'
                BEGIN
                    UPDATE  dbo.eHotelCheckIn
                    SET     wDismiss = 'Y'
                    WHERE   wRoomBookingRid = @roomBookingRowId
                            AND wStatus = 'A';
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
                                        FROM    #DataSet_SetRoomBookingDetails tmp
                                      FOR
                                        XML RAW('Record') ,
                                            ROOT('DataSet')
                                      );
            EXEC spa.SetActionAffectedTableLog @sActionAffectedXML, 'I', @pMainCompNo, '', 0, '';


            ---- update deposit 中的房間 rowId 到 mary 的射數 wRefRid 中
            DECLARE @vXMLUpdExp NVARCHAR(MAX) = '' ,
                    @vRefRid BIGINT = 0,
                    @vHotelBookingRid BIGINT = 0,
                    @vRemark nvarchar(500),
                    @vErrCode INT = 0 ,
                    @vErrMsg NVARCHAR(MAX);

            SELECT @vHotelBookingRid = wBookingRid FROM dbo.eBookingHotel WHERE RowID = @sHotelBookingRid;
            SELECT @vRefRid = e.wRefRid
                FROM RollsMary.dbo.eExpTran AS e 
                WHERE e.wExpGroup = 'RCRM' AND e.wExpType = 'I' AND e.wDeductType = 'DC' AND e.wIsDeposit = 'Y' AND e.wBookingRid = @vHotelBookingRid AND e.wRefRid = @pRoomBookingDetailRid;

            SELECT @vRemark = CONCAT(N'<預訂按金>', dbo.fnGetBookingTypeName(wBookingType), N', 編號: ', SUBSTRING(wRefNo, 0, CASE WHEN CHARINDEX('-', wRefNo) = 0 THEN LEN(wRefNo) + 2
                                                              ELSE CHARINDEX('-', wRefNo)
                                                         END), '-', FORMAT(@wSeqNo, '000')) FROM dbo.eBooking WHERE RowID = @pBookingRid;

            IF ISNULL(@vRefRid, 0) = 0
            BEGIN				
                SET @vXMLUpdExp = (SELECT e.RowID, e.wCompNo, e.wCageCodeIn, e.wTranNo, e.wDate, e.wCurDateTime, e.wShift, e.wAgentCodeIn, e.wCardCodeIn, e.wCustName, e.wShopName
                                    ,e.wExpTypeCode, e.wExpTargetCode, e.wExpCode, e.wExpSubCode1, e.wCurCode, e.wRoomNo, e.wRoomCfmCode, e.wRoomBookDt, e.wRoomCheckInDt
                                    ,e.wRoomDeptDt, e.wNight, e.wUnit, e.wPrice, e.wRoomExpAmt, e.wAmount, e.wExpLocation, e.wVoucherNo, e.wVoucherDt, ISNULL(@vRemark, e.wRemark) AS wRemark
                                    ,e.wPeriodCodeIn
                                    ,e.wExpType, e.wExpGroup, e.wDeductType, e.wPrtPage, e.wPrtRow, e.wTotSetAmt, e.wUpdBy, e.wUpdDt, @pRoomBookingDetailRid AS wRefRid
                                    ,e.wReferId, e.wExpSite, e.wReferUpdBy, e.wEliteCodeIn, e.wSettleInstantTranNo, e.wIsAdj,e.wForeignTranRefNo,e.wFxRateHKD,e.wFxRateRMB,e.wExpDesc
                                    ,e.wExtUpdBy,e.wInvoiceDateTime_CRM,e.wAmountActual_CRM,e.wCardNo_CRM,e.wAuthorizer_CRM,e.wRequestAgentCodeIn,e.wExpCategory,e.wGuid
                                    ,e.wIsDeposit,e.wIsDepositDone,e.wProductCategory,e.wProductDetail,e.wBookingRid,e.wBookingActionRid,e.wIsDepositExposed,e.wBookingStatus
                        FROM RollsMary.dbo.eExpTran AS e 
                         WHERE e.wExpGroup = 'RCRM' AND e.wExpType = 'I' AND e.wDeductType = 'DC' AND e.wIsDeposit = 'Y' AND e.wBookingRid = @vHotelBookingRid AND e.wRefRid = 0
                    FOR XML RAW('Record') , ROOT('DataSet'));

                IF @vXMLUpdExp != ''
                BEGIN
                    DECLARE @vDummy TABLE ( RowID BIGINT );
                    INSERT  INTO @vDummy( RowID )
                        EXEC RollsMary.spa.SetExpTran @pXML = @vXMLUpdExp, -- xml
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
                    IF NOT EXISTS( SELECT 1 FROM RollsMary.dbo.eExpTran e INNER JOIN @vDummy et ON e.RowID=et.RowId)
                        BEGIN
                             SET @pErrMsg = N'沒有對應的射數記錄，保存失敗';
                             THROW 50001, @pErrMsg, 1;
                        END;
                END;
            END

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;		
                END;

    -- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #DataSet_SetRoomBookingDetails;

                    
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
            PRINT '[spa].[SetRoomBookingDetails]'
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ', @sCatchErrorMessage);
            PRINT @pErrMsg;
            IF @sBeginTranCount = 0
                BEGIN
                    IF @xstate = 1 OR @xstate = -1
                        ROLLBACK;

                    -- Write Log
                    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;
        END CATCH;

        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#DataSet_SetRoomBookingDetails') IS NOT NULL
            DROP TABLE #DataSet_SetRoomBookingDetails;
    END;