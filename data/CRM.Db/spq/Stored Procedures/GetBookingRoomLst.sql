
CREATE PROCEDURE [spq].[GetBookingRoomLst]
    @pRefNo VARCHAR(30) ,--預訂編號
    @pFromDt DATETIME2 ,--入住日期從
    @pToDt DATETIME2 ,--入住日期至
    @pCheckOutDt DATETIME2 ,--退房日期
    @pDebitCounterRidXML XML ,--扣數服務櫃檯
    @pHotelRid BIGINT ,--酒店
    @pReqAgentCodeIn VARCHAR(14) ,--使用戶口
    @pDebitAgentCodeIn VARCHAR(14) ,--扣數戶口
    @pReqDeptCode VARCHAR(30) ,--要求部門
    @pFollowUpDeptCode VARCHAR(30) ,--跟進部門
    @pAssBookerTel VARCHAR(100) ,--代訂人電話
    @pRoomRid BIGINT ,--房間類型
    @pOrderNo NVARCHAR(30) ,--單號
    @pConfirmationNo NVARCHAR(40) ,--確認號
    @pRoomNo NVARCHAR(20) ,--房號
    @pGetKeyPasscode VARCHAR(10) ,--取匙密碼
    @pGetKeyMethod VARCHAR(30) ,--取匙方式
    @pHasStaffGetKey CHAR(1) ,--服務部取匙
    @pHasClientGetKey CHAR(1) ,--客人取匙
    @pIsExtension CHAR(1) ,
    @pIsConsigned CHAR(1) ,
    @pCallCustomer CHAR(1) ,
    @pQuickCollectKey CHAR(1) ,
    @pIsCleaning CHAR(1) ,
    @pNoteRemark CHAR(1) ,
    @pWarmReminderSMS CHAR(1) ,
    @pIsConnectedRoom CHAR(1) ,
    @pRoomSMSSent CHAR(1) ,
    @pSameFloor CHAR(1) ,
    @pBookingStatusXML XML ,
    @pCounterRid BIGINT = 0,
    @pTravelPkgRid BIGINT ,
    @pRoomBookingRID BIGINT ,
    @pSort VARCHAR(200) ,
    @pLangCd VARCHAR(10) ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1
AS
    BEGIN
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;	

        DECLARE @vCompNo AS INT ,
                @vYearMth AS VARCHAR(6) ,
                @vLastYearMth AS VARCHAR(6) ,
                @vDebitCounterRidCount INT ,
                @vBookingStatusCount INT;
        DECLARE @vData_DebitCounterRid AS TABLE ( SelectionItem BIGINT );
        DECLARE @vData_BookingStatus AS TABLE ( SelectionItem VARCHAR(5) );

        SELECT @vCompNo = wRollexCompNo
        FROM CRM.dbo.mServiceCounter
        WHERE @pCounterRid IS NOT NULL AND @pCounterRid = RowID;

        SELECT @vYearMth = CONCAT(wYear, wMonth)
        FROM RollsMary.dbo.mSettlePeriod
        WHERE @vCompNo IS NOT NULL AND @vCompNo = wCompNo AND RollsMary.dbo.fnUTC8Now() BETWEEN wStartDateTime AND wEndDateTime;

        SELECT @vLastYearMth = CONCAT(wYear, wMonth)
        FROM RollsMary.dbo.mSettlePeriod
        WHERE @vCompNo IS NOT NULL AND @vCompNo = wCompNo AND DATEADD(MONTH, -1, RollsMary.dbo.fnUTC8Now()) BETWEEN wStartDateTime AND wEndDateTime;

        IF @pDebitCounterRidXML IS NOT NULL AND CAST(@pDebitCounterRidXML AS NVARCHAR(MAX)) != N'<DataSet/>'
        BEGIN
            INSERT INTO @vData_DebitCounterRid ( SelectionItem )
            SELECT tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
            FROM @pDebitCounterRidXML.nodes('/DataSet/Record') AS T ( tmp );
        END;

        IF @pBookingStatusXML IS NOT NULL AND CAST(@pBookingStatusXML AS NVARCHAR(MAX)) != N'<DataSet/>'
        BEGIN
            INSERT INTO @vData_BookingStatus ( SelectionItem )
            SELECT tmp.value('@SelectionItem', 'VARCHAR(5)') AS SelectionItem
            FROM @pBookingStatusXML.nodes('/DataSet/Record') AS T ( tmp );
        END;

        SET @vDebitCounterRidCount = ( SELECT COUNT(1) FROM @vData_DebitCounterRid );
        SET @vBookingStatusCount = ( SELECT COUNT(1) FROM @vData_BookingStatus );
        SET @pOrderNo = NULLIF(@pOrderNo, '');
        SET @pFromDt = ISNULL(CAST(@pFromDt AS DATE), '0001-01-01');
        SET @pToDt = ISNULL(CAST(@pToDt AS DATE), '9999-12-31');  
        SET @pHotelRid = IIF(@pHotelRid <= 0, NULL, @pHotelRid);
        SET @pDebitAgentCodeIn = NULLIF(@pDebitAgentCodeIn, '');
        SET @pReqAgentCodeIn = NULLIF(@pReqAgentCodeIn, '');
        SET @pReqDeptCode = NULLIF(@pReqDeptCode, '');
        SET @pFollowUpDeptCode = NULLIF(@pFollowUpDeptCode, '');
        SET @pAssBookerTel = NULLIF(@pAssBookerTel, '');
        SET @pRoomRid = IIF(@pRoomRid <= 0, NULL, @pRoomRid);
        SET @pRoomNo = NULLIF(@pRoomNo, '');
        SET @pGetKeyMethod = NULLIF(@pGetKeyMethod, '');
        SET @pHasClientGetKey = NULLIF(@pHasClientGetKey, ' ');
        SET @pGetKeyPasscode = NULLIF(@pGetKeyPasscode, '');
        SET @pCheckOutDt = CAST(@pCheckOutDt AS DATE);
        SET @pRefNo = NULLIF(@pRefNo, '');
        SET @pConfirmationNo = NULLIF(@pConfirmationNo, '');
        SET @pHasStaffGetKey = NULLIF(@pHasStaffGetKey, ' ');
        SET @pIsExtension = IIF(@pIsExtension != 'Y' AND @pIsExtension != 'N',  NULL, @pIsExtension);
        SET @pIsConsigned = NULLIF(@pIsConsigned, ' ');
        SET @pCallCustomer = NULLIF(@pCallCustomer, ' ');
        SET @pQuickCollectKey = NULLIF(@pQuickCollectKey, ' ');
        SET @pIsCleaning = NULLIF(@pIsCleaning, ' ');
        SET @pNoteRemark = NULLIF(@pNoteRemark, ' ');
        SET @pWarmReminderSMS = NULLIF(@pWarmReminderSMS, ' ');
        SET @pIsConnectedRoom = NULLIF(@pIsConnectedRoom, ' ');
        SET @pRoomSMSSent = NULLIF(@pRoomSMSSent, ' ');
        SET @pSameFloor = NULLIF(@pSameFloor, ' ');        
        SET @pSort = IIF(NULLIF(@pSort, '') IS NULL, '||', @pSort);
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-GB'));
        SET @pRoomBookingRID = IIF(@pRoomBookingRID <= 0, NULL, @pRoomBookingRID);
        SET @pTravelPkgRid = IIF(@pTravelPkgRid <= 0, NULL, @pTravelPkgRid);

        WITH cteRollingAmt AS (
            SELECT
                wAgentCodeIn ,
                wCompRollingHKD = SUM(IIF(wCompNo = @vCompNo, wRollingHKD + wRollingInstantSettledHKD, 0))
            FROM RollsMary.dbo.mAgentBalRollingMth
            WHERE @vYearMth IS NOT NULL AND @vYearMth = wYearMth
            GROUP BY wAgentCodeIn
        ),
        cteLastRollingAmt AS (
            SELECT
                wAgentCodeIn ,
                wCompRollingHKD = SUM(IIF(wCompNo = @vCompNo, wRollingHKD + wRollingInstantSettledHKD, 0))
            FROM RollsMary.dbo.mAgentBalRollingMth
            WHERE @vLastYearMth IS NOT NULL AND @vLastYearMth = wYearMth
            GROUP BY wAgentCodeIn
        ),
        cteHotelChange AS (
            SELECT
                wRoomBookingRid
            FROM dbo.eHotelChange
            WHERE wAction = 'EX'
            GROUP BY wRoomBookingRid
        ),
        tBookingRoomResult AS (
            SELECT
                br.RowID ,
                br.wBookingRid ,
                br.wHotelBookingRid ,
                br.wRequestRid ,
                br.wHotelRid ,
                br.wCounterRid ,
                br.wTravelAgencyRid ,
                br.wHotelRoomRid ,
                br.wOrderNo ,
                br.wBedType ,
                br.wStartDate ,
                br.wEndtDate ,
                br.wDayOfStay ,
                br.wPaymentMethod ,
                br.wReceiptNo ,
                br.wVoucherNo ,
                br.wConfirmationNo ,
                br.wCashReceiptNo ,
                br.wCashTransferReceiptNo ,
                br.wGetKeyMethod ,
                br.wCurrCode ,
                br.wUseMemberCard ,
                br.wIncludeBreakfast ,
                br.wUseExtraAllotment ,
                br.wUseUpAllotment ,
                br.wTotalAmount ,
                br.wAdditionalFee ,
                br.wActualTotalAmount ,
                br.wTotalCost ,
                br.wRoomNo ,
                br.wGetKeyPasscode ,
                br.wHasStaffGetKey ,
                br.wHasClientGetKey ,
                br.wReGetKeyDate ,
                br.wSmsCount ,
                br.wIsConsigned ,
                br.wSameFloor ,
                br.wRoomExpenseState ,
                br.wCallCustomer ,
                br.wQuickCollectKey ,
                br.wIsCleaning ,
                br.wWarmReminderSMS ,
                br.wNoteRemark ,
                br.wIsConnectedRoom ,
                br.wRemark ,
                br.wCheckoutRemarks ,
                br.wCrtDt ,
                br.wCrtBy ,
                br.wUpdDt ,
                br.wUpdBy ,
                br.wAllotmentGroupRid ,
                br.wRoomSMSSent ,
                br.wDisplayAgencyHotel ,
                br.wUseAgencyAllotment ,
                eb.wCancelDebitDt ,
                eb.wCancelReasonCd ,
                eb.wCancelBy ,
                eb.wCancelDt ,
                br.wStatus ,
                br.wSeqNo ,
                eb.wReqCounterRid ,
                eb.wAsstBooker ,
                eb.wAssBookerTel ,
                eb.wReqDepartment ,
                eb.wReqUserRid ,
                eb.wApprovalAgentCodeIn ,
                eb.wOtherReason ,
                eb.wAsstBookerEmail ,
                eb.wDeptFollwedCd ,
                eb.wStaffFollwedRid,
                eb.wStaffTelephone ,
                eb.wOwnerAuthTelephone ,
                eb.wDebitCounterRid ,
                wTravelPkgRid =eb.wTravePkgRid,
                eb.wUseTravelPkg,
                eb.wEventCodeRid ,
                br.wBookingStatus ,
                br.wUnqualifiedRid,
                eb.wDebitAgentCodeIn,
                eb.wReqAgentCodeIn,
                eb.wRefNo ,
                eb.[GUID]
            FROM dbo.eBookingRoom AS br
            INNER JOIN dbo.eBooking AS eb ON br.wBookingRid = eb.RowID
            LEFT JOIN @vData_BookingStatus vs ON vs.SelectionItem = br.wBookingStatus  
            WHERE br.wStatus = 'A'
                AND ( @vBookingStatusCount = 0 OR vs.SelectionItem IS NOT NULL)
                AND ( @pRoomBookingRID IS NULL  OR br.RowID = @pRoomBookingRID )
                AND ( @pTravelPkgRid IS NULL OR eb.wTravePkgRid = @pTravelPkgRid )
        ),
        tResult AS (
            SELECT
                wSeqNo = ROW_NUMBER() OVER ( ORDER BY br.wCrtDt DESC) ,
                br.RowID ,
                br.wBookingRid ,
                wRequestNo = ISNULL(hr.wRequestNo, '') ,
                br.wHotelBookingRid ,
                wHotelName = ISNULL(mh.wName, '') ,--酒店
                wHotelRoomCode = ISNULL(mhr.wCode, '') ,
                wHotelRoomName = ISNULL(mhr.wName, '') ,
                br.wRefNo ,
                br.[GUID] ,
                wBookingSeqNo = br.wSeqNo ,
                br.wRequestRid ,
                wClient = bm.wValue,
                br.wHotelRid ,
                br.wHotelRoomRid ,
                br.wTravelAgencyRid ,
                wAllotmentName = ISNULL(ALT.wName, '') ,
                br.wAllotmentGroupRid ,
                br.wOrderNo ,
                br.wStartDate ,
                br.wEndtDate ,
                br.wDayOfStay ,
                br.wReceiptNo ,
                br.wStatus ,
                br.wVoucherNo ,
                br.wConfirmationNo ,
                br.wCashReceiptNo ,
                br.wCashTransferReceiptNo ,
                br.wGetKeyMethod ,
                br.wUseMemberCard ,
                br.wIncludeBreakfast ,
                br.wUseExtraAllotment ,
                br.wUseUpAllotment ,
                br.wTotalAmount ,
                br.wAdditionalFee ,
                br.wActualTotalAmount ,
                br.wTotalCost ,
                br.wRoomNo ,
                br.wGetKeyPasscode ,
                br.wHasStaffGetKey ,
                br.wHasClientGetKey ,
                br.wReGetKeyDate ,
                br.wSmsCount ,
                br.wIsConsigned ,
                br.wSameFloor ,
                br.wRoomExpenseState ,
                br.wCallCustomer ,
                br.wQuickCollectKey ,
                br.wIsCleaning ,
                br.wWarmReminderSMS ,
                br.wNoteRemark ,
                br.wIsConnectedRoom ,
                br.wRemark ,
                br.wCheckoutRemarks ,
                br.wPaymentMethod ,
                br.wCurrCode ,
                br.wBedType ,
                br.wCrtDt ,
                br.wCrtBy ,
                br.wUpdDt ,
                br.wUpdBy ,
                br.wRoomSMSSent ,
                br.wDisplayAgencyHotel ,
                br.wUseAgencyAllotment ,
                br.wBookingStatus ,
                br.wUnqualifiedRid ,
                br.wCounterRid ,
                wIsBase = ISNULL(mh.wIsBase, ''),
                br.wCancelDebitDt ,
                br.wCancelReasonCd ,
                br.wCancelBy ,
                br.wCancelDt ,
                br.wOtherReason ,
                br.wTravelPkgRid ,
                br.wUseTravelPkg ,
                br.wEventCodeRid ,
                wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END ,
                wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END ,
                wIsExtension = CAST(IIF(chc.wRoomBookingRid IS NOT NULL, 1, 0) AS BIT) ,
                br.wReqCounterRid ,
                br.wReqDepartment ,
                br.wAsstBooker ,
                br.wAssBookerTel ,
                br.wReqUserRid ,
                br.wApprovalAgentCodeIn ,
                br.wAsstBookerEmail ,
                br.wDeptFollwedCd ,
                br.wStaffFollwedRid ,
                br.wStaffTelephone ,
                br.wOwnerAuthTelephone ,
                br.wDebitCounterRid ,
                daAgent.wAgentCode_Display ,
                wAgentCodeByName = CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName ELSE daAgent.wCName END ,
                wReqAgentCode_Display = rqAgent.wAgentCode_Display,
                wReqAgentCodeByName = CASE WHEN @pLangCd = 'en-gb' THEN rqAgent.wEName ELSE rqAgent.wCName END ,
                wReqUserRidByCName = CASE WHEN @pLangCd = 'en-gb' THEN rqusr.wName ELSE rqusr.wCName END  ,
                wStaffFollwedRidByCName = CASE WHEN @pLangCd = 'en-gb' THEN sfusr.wName ELSE sfusr.wCName END ,
                wDebitServiceCounterName = sc.wName ,
                wCompRollingHKD = ISNULL(r.wCompRollingHKD, 0) ,
                wLastCompRollingHKD = ISNULL(lr.wCompRollingHKD, 0) ,
                wEventCodeByName = CASE WHEN @pLangCd = 'en-gb' THEN mec.wEName ELSE mec.wCName END ,
                wAgentCodeIn = daAgent.wAgentCodeIn
            FROM tBookingRoomResult br
            INNER JOIN RollsMary.dbo.mAgent daAgent ON daAgent.wAgentCodeIn = br.wDebitAgentCodeIn
            INNER JOIN RollsMary.dbo.mAgent rqAgent ON rqAgent.wAgentCodeIn = br.wReqAgentCodeIn
            INNER JOIN dbo.mServiceCounter sc ON sc.RowID = br.wDebitCounterRid
            LEFT JOIN dbo.eHotelRequest hr ON hr.RowID = br.wRequestRid
            LEFT JOIN dbo.mHotel mh ON mh.RowID = br.wHotelRid
            LEFT JOIN dbo.mHotelRoom mhr ON mhr.RowID = br.wHotelRoomRid
            LEFT JOIN dbo.mAllotmentGroup ALT ON ALT.RowID = br.wAllotmentGroupRid
            LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = br.wUpdBy
            LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = br.wCrtBy
            LEFT JOIN RollsMary.dbo.mUsr rqusr ON rqusr.RowID = br.wReqUserRid
            LEFT JOIN RollsMary.dbo.mUsr sfusr ON sfusr.RowID = br.wStaffFollwedRid
            LEFT JOIN dbo.mEventCode mec ON mec.RowID = br.wEventCodeRid
            LEFT JOIN cteRollingAmt r ON r.wAgentCodeIn = br.wReqAgentCodeIn
            LEFT JOIN cteLastRollingAmt lr ON lr.wAgentCodeIn = br.wReqAgentCodeIn
            LEFT JOIN cteHotelChange chc ON chc.wRoomBookingRid = br.RowID
            LEFT JOIN stg.eBookingMisc bm ON bm.wBookingRid = br.wBookingRid AND bm.wLangCd = @pLangCd AND bm.wItemCd = 'CUST_NAME'
            LEFT JOIN @vData_DebitCounterRid v ON @vDebitCounterRidCount != 0 AND v.SelectionItem = br.wDebitCounterRid
            WHERE ( @pOrderNo IS NULL OR @pOrderNo = br.wOrderNo )
                AND ((@pCheckOutDt IS NULL AND (
                        (br.wStartDate BETWEEN @pFromDt AND @pToDt)
                        OR (br.wEndtDate >= @pFromDt AND br.wEndtDate < @pToDt)
                        OR ( @pFromDt BETWEEN br.wStartDate AND br.wEndtDate AND @pToDt >= br.wStartDate AND @pToDt < br.wEndtDate ) )
                    ) 
                    OR (@pCheckOutDt IS NOT NULL AND br.wEndtDate = @pCheckOutDt))
                AND ( @pHotelRid IS NULL OR @pHotelRid = br.wHotelRid)
                AND ( @pDebitAgentCodeIn IS NULL OR @pDebitAgentCodeIn = br.wDebitAgentCodeIn)
                AND ( @pReqAgentCodeIn IS NULL OR @pReqAgentCodeIn = br.wReqAgentCodeIn)
                AND ( @pReqDeptCode IS NULL OR @pReqDeptCode = br.wReqDepartment)
                AND ( @pFollowUpDeptCode IS NULL OR @pFollowUpDeptCode = br.wDeptFollwedCd)
                AND ( @pAssBookerTel IS NULL OR @pAssBookerTel = br.wAssBookerTel)
                AND ( @pRoomRid IS NULL OR @pRoomRid = mhr.RowID)
                AND ( @pRoomNo IS NULL OR @pRoomNo = br.wRoomNo)
                AND ( @pGetKeyMethod IS NULL OR @pGetKeyMethod = br.wGetKeyMethod)
                AND ( @pHasClientGetKey IS NULL OR @pHasClientGetKey = br.wHasClientGetKey)
                AND ( @pGetKeyPasscode IS NULL OR @pGetKeyPasscode = br.wGetKeyPasscode)
                AND ( @pRefNo IS NULL OR br.wRefNo = @pRefNo)
                AND ( @pConfirmationNo IS NULL OR @pConfirmationNo = br.wConfirmationNo)
                AND ( @pHasStaffGetKey IS NULL OR @pHasStaffGetKey = br.wHasStaffGetKey)
                AND ( @vDebitCounterRidCount = 0 OR v.SelectionItem IS NOT NULL)
                AND ( @pIsExtension IS NULL
                    OR ( @pIsExtension = 'Y'AND chc.wRoomBookingRid IS NOT NULL)
                    OR ( @pIsExtension = 'N'AND chc.wRoomBookingRid IS NULL)
                    )
                AND ( @pIsConsigned IS NULL OR @pIsConsigned = br.wIsConsigned)
                AND ( @pCallCustomer IS NULL OR @pCallCustomer = br.wCallCustomer)
                AND ( @pQuickCollectKey IS NULL OR @pQuickCollectKey = br.wQuickCollectKey)
                AND ( @pIsCleaning IS NULL OR @pIsCleaning = br.wIsCleaning)
                AND ( @pNoteRemark IS NULL OR @pNoteRemark = br.wNoteRemark)
                AND ( @pWarmReminderSMS IS NULL OR @pWarmReminderSMS = br.wWarmReminderSMS)
                AND ( @pIsConnectedRoom IS NULL OR @pIsConnectedRoom = br.wIsConnectedRoom)
                AND ( @pRoomSMSSent IS NULL OR @pRoomSMSSent = br.wRoomSMSSent)
                AND ( @pSameFloor IS NULL  OR @pSameFloor = br.wSameFloor )
        ),
        tCount AS (
            SELECT
                wRecordCount = COUNT(*)
            FROM tResult
        )

        SELECT
            tResult.* ,
            wRecordCount
        FROM tResult , tCount
        ORDER BY CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wCrtDt END DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );
    END;