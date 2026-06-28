CREATE PROCEDURE [spa].[SetBooking]
(
    @pXML XML ,
    @pActionType CHAR(1) , -- I/U/D    
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pReturnResultSet CHAR(1) = 'N' ,
    @pBookingRid BIGINT OUTPUT ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
)
AS
    BEGIN    
        SET NOCOUNT ON;

        ---- dbml		
        --SELECT
        --	RowID,
        --	wBookingType, 
        --	wRefNo, 
        --	[GUID], 
        --	wReqCounterRid, 
        --	wDebitCounterRid, 
        --	wReqAgentCodeIn, 
        --	wDebitAgentCodeIn, 
        --	wReqCustomerRid, 
        --	wDebitCustomerRid, 
        --	wReqDepartment, 
        --	wReqUserRid, 
        --	wAsstBooker, 
        --	wAssBookerTel, 
        --	wApprovalAgentCodeIn, 
        --	wDebitDt, 
        --	wExpDt, 
        --	wCancelDebitDt, 
        --	wCancelReasonCd, 
        --	wCancelBy, 
        --	wCancelDt, 
        --	wCrtDt, 
        --	wCrtBy, 
        --	wUpdDt, 
        --	wUpdBy, 
        --	wTravePkgRid, 
        --	wEventCodeRid, 
        --	wAsstBookerEmail, 
        --	wDeptFollwedCd, 
        --	wStaffFollwedRid, 
        --	wStaffTelephone, 
        --	wOwnerAuthTelephone, 
        --	wOtherReason, 
        --	wDepositAmt, 
        --	wGiftReasonCd, 
        --	wUseTravelPkg, 
        --	wDepositDebitDt,
        --  wBookingStatus = CAST('' AS VARCHAR(10)),
        --	CAST('' as UNIQUEIDENTIFIER) AS wGUID, 
        --	CAST('' as NVARCHAR(20)) AS wAgentCode,
        --    wCoordinator,
        --    wIsUser,
        --    wUser
        --FROM dbo.eBooking
        --RETURN
       
        DECLARE @sThisTableName VARCHAR(50) = 'eBooking' ,-- For RowID    
                @sBeginTranCount INT = 0 ,
                @sRecCount INT = 0 ,
                @sRuningIndex INT = 1 ,
                @sRowID BIGINT = 0 ,
                @sBookingHotelRid BIGINT, --由於按金插入數據的時候拿不到 hotel 的資料，所以此處需要用此參數傳值到 setBooking
                @vNow DATETIME2 = dbo.fnUTC8Now() ,
                @sAnyDepositChange INT = 0 ,
                @vMthEndYearMth VARCHAR(6) ,
                @vDateUsingCRM DATETIME2 ,
                @sDocHandle INT;
        
        DECLARE @bookingType VARCHAR(30),
                @refNo VARCHAR(30),
                @changHotelRefNo VARCHAR(30);

        SET @sBeginTranCount = @@trancount;
        SET @sBookingHotelRid = @pBookingRid;

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;

        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
            *
        INTO    #sDataSet_SetBooking
        FROM    OPENXML (@sDocHandle, 'DataSet/SetBookingResult', 1)    
        WITH (    
            RowID BIGINT ,        
            wBookingType  VARCHAR(30) ,    
            wRefNo  VARCHAR(30) ,    
            [GUID] UNIQUEIDENTIFIER,           
            wReqCounterRid BIGINT ,    
            wDebitCounterRid BIGINT ,    
            wReqAgentCodeIn VARCHAR(14),    
            wDebitAgentCodeIn VARCHAR(14),    
            wReqCustomerRid BIGINT,    
            wDebitCustomerRid BIGINT,    
            wReqDepartment VARCHAR(30),    
            wReqUserRid BIGINT,    
            wAsstBooker NVARCHAR(50),    
            wAssBookerTel VARCHAR(100),    
            wApprovalAgentCodeIn VARCHAR(14),    
            wDebitDt DATETIME2,    
            wExpDt DATETIME2,    
            wCancelDebitDt DATETIME2,    
            wCancelReasonCd VARCHAR(30),   
            wOtherReason NVARCHAR(200), 
            wCancelBy BIGINT,    
            wCancelDt DATETIME2(7),
            wCrtBy BIGINT,    
            wCrtDt DATETIME2(7),  
            wUpdBy BIGINT,    
            wUpdDt DATETIME2(7),  
            wTravePkgRid BIGINT,
            wEventCodeRid BIGINT,
            wAsstBookerEmail NVARCHAR(50),
            wDeptFollwedCd VARCHAR(30),
            wStaffFollwedRid BIGINT,
            wStaffTelephone VARCHAR(100),
            wOwnerAuthTelephone VARCHAR(100),
            wDepositAmt NUMERIC(18, 4),
            wGiftReasonCd VARCHAR(30),
            wUseTravelPkg CHAR(1),
            wDepositDebitDt DATETIME2(7),
            wBookingStatus VARCHAR(10),
            wCoordinator NVARCHAR(50),
            wIsUser CHAR(1),
            wUser NVARCHAR(50)
        );  
        
        --------------------------------------------------------------------------Checking-----------------------------------------------------------------------------
        DECLARE @sErrorMsg NVARCHAR(MAX);
        IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType NOT IN ('I', 'U', 'D')
            SET @sErrorMsg = N'非法操作！';

        IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType IN ( 'I', 'U' )
        BEGIN
            SELECT @sErrorMsg = CASE WHEN ISNULL(eb.wReqCounterRid, 0) <= 0         THEN N'要求櫃台不能為空。'
                                     WHEN ISNULL(eb.wDebitCounterRid, 0) <= 0       THEN N'扣數櫃台不能為空。'
                                     WHEN NULLIF(eb.wReqAgentCodeIn, '') IS NULL    THEN N'使用戶口不能為空。'
                                     WHEN NULLIF(eb.wDebitAgentCodeIn, '') IS NULL  THEN N'扣數戶口不能為空。'
                                     WHEN NULLIF(eb.wReqDepartment, '') IS NULL     THEN N'要求部門不能為空。'
                                END
            FROM #sDataSet_SetBooking eb
        END
        
        -- 酒店（非房间）预订、更改入住日期、餐厅，没有按金，此时按金日期可以为空，其他预订，不可以为空
        IF NULLIF(@sErrorMsg, '') IS NULL
        BEGIN
            SELECT @sErrorMsg = N'「按金日期」不能為空或者「0001-01-01」！'
            FROM #sDataSet_SetBooking
            WHERE wBookingType NOT IN ('CHANGEHOTEL', 'HOTEL', 'RESTAURANT') AND (wDepositDebitDt IS NULL OR CAST(wDepositDebitDt AS DATE) = '0001-01-01')
        END;
        
        IF NULLIF(@sErrorMsg, '') IS NOT NULL
            THROW 50001, @sErrorMsg, 1;

        -- 非P狀態下，部份字段不能Update，此處修正XML偉過來的參數
        IF @pActionType IN ('U', 'D')
        BEGIN
            DECLARE @sCount INT,
                    @sBookingRid BIGINT,
                    @sBookingType VARCHAR(30),
                    @sBookingStatus VARCHAR(10);
            SELECT @sCount = COUNT(1) FROM #sDataSet_SetBooking;

            WHILE @sCount > 0
            BEGIN
                SELECT @sBookingRid = RowID, @sBookingType = wBookingType FROM #sDataSet_SetBooking WHERE wRowNum = @sCount;
                IF ISNULL(@sBookingRid, 0) > 0 AND NULLIF(@sBookingType, '') IS NOT NULL
                BEGIN
                    IF @sBookingType = 'ADDITIONALEXPENSES'
                        SELECT @sBookingStatus = wBookingStatus FROM dbo.eAdditionalExpense WHERE wBookingRefRid = @sBookingRid;

                    IF @sBookingType = 'AIRTICKET'
                        SELECT @sBookingStatus = wBookingStatus FROM dbo.eBookingAirTicket WHERE wBookingRid = @sBookingRid;

                    -- 更改入住日期永遠都是C狀態 
                    IF @sBookingType = 'CHANGEHOTEL'
                        SET @sBookingStatus = 'C';

                    IF @sBookingType = 'CHK_IN_SVC'
                        SELECT @sBookingStatus = wBookingStatus FROM dbo.eBookingCheckInService WHERE wBookingRid = @sBookingRid;

                    IF @sBookingType = 'FERRY'
                        SELECT @sBookingStatus = wBookingStatus FROM dbo.eBookingFerry WHERE wBookingRid = @sBookingRid;

                    IF @sBookingType = 'HELI'
                        SELECT @sBookingStatus = wBookingStatus FROM dbo.eBookingHeli WHERE wBookingRid = @sBookingRid;

                    -- 酒店沒有射數，先不理會
                    --IF @sBookingType = 'HOTEL'
                        --SELECT @sBookingStatus = wBookingStatus FROM dbo.eAdditionalExpense WHERE wBookingRefRid = @sBookingRid;

                    IF @sBookingType = 'LEADING_SERVICE'
                        SELECT @sBookingStatus = wBookingStatus FROM dbo.eBookingLeading WHERE wBookingRid = @sBookingRid;

                    IF @sBookingType = 'PickUp_SERVICE'
                        SELECT @sBookingStatus = wBookingStatus FROM dbo.eBookingPickUpService WHERE wBookingRid = @sBookingRid;

                    IF @sBookingType = 'PP'
                        SELECT @sBookingStatus = wBookingStatus FROM dbo.eBookingPrivatePlane WHERE wBookingRid = @sBookingRid;

                    IF @sBookingType = 'RESTAURANT'
                        SELECT @sBookingStatus = wBookingStatus FROM dbo.eBookingRestaurant WHERE wBookingRid = @sBookingRid;

                    IF @sBookingType = 'ROOM'
                        SELECT @sBookingStatus = wBookingStatus FROM dbo.eBookingRoom WHERE wBookingRid = @sBookingRid;

                    IF @sBookingType = 'SHOWTICKET'
                        SELECT @sBookingStatus = wBookingStatus FROM dbo.eBookingShow WHERE wBookingRid = @sBookingRid;

                    IF @sBookingType = 'TOUR'
                        SELECT @sBookingStatus = wBookingStatus FROM dbo.eBookingTourGuide WHERE wBookingRid = @sBookingRid;

                    IF @sBookingType = 'TRAVEL_PACKAGE'
                        SELECT @sBookingStatus = wBookingStatus FROM dbo.eBookingTravelPackage WHERE wBookingRid = @sBookingRid;

                    IF @sBookingType = 'Visa'
                        SELECT @sBookingStatus = wBookingStatus FROM dbo.eBookingVisa WHERE wBookingRid = @sBookingRid;

                    IF NULLIF(@sBookingStatus, '') IS NOT NULL AND @sBookingStatus NOT IN ('P')
                    BEGIN
                        UPDATE sb
                        SET sb.wReqAgentCodeIn = eb.wReqAgentCodeIn,
                            sb.wDebitAgentCodeIn = eb.wDebitAgentCodeIn
                        FROM #sDataSet_SetBooking AS sb
                        INNER JOIN dbo.eBooking AS eb ON eb.RowID = sb.RowID
                        WHERE @sBookingRid = eb.RowID
                    END;
                END;

                SET @sCount = @sCount - 1;
            END;
        END;
        
        -- 刪除操作，扣數日期、按金日期、取消扣數日期用加db的
        IF @pActionType IN ('D')
        BEGIN
            UPDATE sb
            SET sb.wDebitDt = eb.wDebitDt,
                sb.wDepositDebitDt = eb.wDepositDebitDt,
                sb.wCancelDebitDt = eb.wCancelDebitDt
            FROM #sDataSet_SetBooking AS sb
            INNER JOIN dbo.eBooking AS eb ON eb.RowID = sb.RowID
            WHERE @sBookingRid = eb.RowID
        END;
        --------------------------------------------------------------------------Checking-----------------------------------------------------------------------------		
        
        --- Booking Required Field Validation end
        SELECT TOP 1 @bookingType = wBookingType, @changHotelRefNo = wRefNo FROM #sDataSet_SetBooking ;

        -- Validations for Private Plane Booking
        --IF @bookingType = 'PP'  
        --BEGIN
        --	SELECT @sErrorMsg =
        --	CASE WHEN eb.wReqCounterRid <> tmp.wReqCounterRid THEN 'Can not be updated requested sevice counter when booking status code is ' + EBPP.wBookingStatus
        --	 WHEN eb.wDebitCounterRid <> tmp.wDebitCounterRid THEN 'Can not be updated debit sevice counter  when booking status code is ' + EBPP.wBookingStatus    
        --	 --WHEN eb.wReqAgentCodeIn <> tmp.wReqAgentCodeIn THEN 'Can not be updated account requested when booking status code is ' + EBPP.wBookingStatus
        --	 --WHEN eb.wDebitAgentCodeIn <> tmp.wDebitAgentCodeIn THEN 'Can not be updated debit account requested  when booking status code is '+ EBPP.wBookingStatus
        --	 --WHEN eb.wReqCustomerRid <> tmp.wReqCustomerRid THEN 'Can not be updated requested cutomer when booking status code is '+ EBPP.wBookingStatus
        --	 --WHEN eb.wDebitCustomerRid <> tmp.wDebitCustomerRid THEN 'Can not be updated debit cutomer when booking status code is '+ EBPP.wBookingStatus
        --	 WHEN EBPP.wBookingStatus IN ('DL','UQ','CL','C') AND eb.wReqDepartment <> tmp.wReqDepartment THEN 'Can not be updated requested department when booking status code is '+ EBPP.wBookingStatus
        --	 WHEN EBPP.wBookingStatus IN ('DL','UQ','CL') AND eb.wReqUserRid <> tmp.wReqUserRid THEN 'Can not be updated requested user when booking status code is '+ EBPP.wBookingStatus
        --	 WHEN EBPP.wBookingStatus IN ('DL','UQ','CL','C') AND eb.wAsstBooker <> tmp.wAsstBooker THEN 'Can not be updated asst booker when booking status code is '+ EBPP.wBookingStatus
        --	 WHEN EBPP.wBookingStatus IN ('DL','UQ','CL','C') AND eb.wAssBookerTel <> tmp.wAssBookerTel THEN 'Can not be updated asst booker phone when booking status code is '+ EBPP.wBookingStatus
        --	 WHEN EBPP.wBookingStatus IN ('DL','UQ','CL','C') AND eb.wApprovalAgentCodeIn <> tmp.wApprovalAgentCodeIn THEN 'Can not be updated owner when booking status code is '+ EBPP.wBookingStatus
        --	 WHEN eb.wDebitDt <> tmp.wDebitDt THEN 'Can not be updated debit date  when booking status code is '+ EBPP.wBookingStatus
        --	 WHEN eb.wExpDt <> tmp.wExpDt  THEN 'Can not be updated Exp date when booking status code is '+ EBPP.wBookingStatus					
        --	 WHEN EBPP.wBookingStatus IN ('DL','UQ','CL','C') AND eb.wAsstBookerEmail <> ISNULL(tmp.wAsstBookerEmail,'') THEN 'Can not be updated asst email when booking status code is '+ EBPP.wBookingStatus
        --	 WHEN EBPP.wBookingStatus IN ('DL','UQ','CL','C') AND eb.wDeptFollwedCd <> ISNULL(tmp.wDeptFollwedCd,'') THEN 'Can not be updated staff followed department when booking status code is '+ EBPP.wBookingStatus
        --	 WHEN EBPP.wBookingStatus IN ('DL','UQ','CL','C') AND eb.wStaffFollwedRid <> ISNULL(tmp.wStaffFollwedRid,-1) THEN 'Can not be updated staff followed  when booking status code is '+ EBPP.wBookingStatus
        --	 WHEN EBPP.wBookingStatus IN ('DL','UQ','CL','C') AND eb.wStaffTelephone <> ISNULL(tmp.wStaffTelephone,'') THEN 'Can not be updated staff phone when booking status code is '+ EBPP.wBookingStatus
        --	 WHEN EBPP.wBookingStatus IN ('DL','UQ','CL','C') AND eb.wOwnerAuthTelephone <> ISNULL(tmp.wOwnerAuthTelephone,'') THEN 'Can not be updated owner phone when booking status code is '+ EBPP.wBookingStatus
        --	 WHEN EBPP.wBookingStatus IN ('DL','UQ','CL','C','RF') AND eb.wDepositAmt <> ISNULL(tmp.wDepositAmt,0)
        --		  THEN 'Can not be updated deposit amount when booking status code is '+ EBPP.wBookingStatus
        --	END
        --	FROM dbo.eBooking AS eb    
        --	INNER JOIN #sDataSet_SetBooking tmp ON eb.RowID = tmp.RowID
        --	INNER JOIN (SELECT * FROM dbo.eBookingPrivatePlane WHERE wBookingRid=@pBookingRid
        --	AND wBookingStatus IN ('C','CO','DL','CL','RF','UQ')
        --	) EBPP ON EBPP.wBookingRid=eb.RowID
        --	WHERE eb.RowID = tmp.RowID;

        --	IF @sErrorMsg <> '' THROW 50001, @sErrorMsg, 1;	

        --END

        --better don't put everything within try, for example    
        --getting mSysTable value    
        --getting currency, period, mCompany ...  
        
        --------------------------------------------------------
        -- wDepositAmt
        --------------------------------------------------------
        SELECT  @vMthEndYearMth = MAX(wYearMth) FROM RollsMary.dbo.eSettleTran (NOLOCK) WHERE wSettleLineGrp = '';	
        SET @vDateUsingCRM = ( SELECT TOP 1
                                        wValue
                               FROM     RollsMary.dbo.mSysTable
                               WHERE    wItemCode = 'DATE_USING_CRM'
                             );
        SET @vDateUsingCRM = ISNULL(@vDateUsingCRM, '2099-12-31');
        
        IF @pActionType = 'I'
            BEGIN
            -- 新增時有按金, 當 wBookingType = 'CHANGEHOTEL' 的時候，如果已經有按金輸入，則需要執行扣減按金的操作
                SELECT  @sAnyDepositChange = COUNT(1)
                FROM    #sDataSet_SetBooking tmp
                WHERE   tmp.wDepositAmt > 0 AND tmp.wBookingType != 'CHANGEHOTEL';

                SELECT  @sAnyDepositChange = 1
                FROM    #sDataSet_SetBooking tmp
                WHERE   tmp.wBookingType = 'CHANGEHOTEL';
            END
        ELSE
            IF @pActionType = 'U'
                BEGIN
            -- 扣數戶口 / 按金金額有變動、按金日期修改為確認按金日期之後的日子
                    SELECT  @sAnyDepositChange = COUNT(1)
                    FROM    #sDataSet_SetBooking tmp
                            INNER JOIN dbo.eBooking b ON tmp.RowID = b.RowID
                    WHERE   tmp.wDepositAmt != b.wDepositAmt OR tmp.wDebitAgentCodeIn != b.wDebitAgentCodeIn OR (CAST(FORMAT(tmp.wDepositDebitDt, 'yyyy-MM-dd') + ' 12:00:00' AS DATETIME2)>b.wDepositDebitDt)

                END
            ELSE
                IF @pActionType = 'D'
                    BEGIN
                        -- 刪除既話就點都check一 check 有無按金了
                        SET @sAnyDepositChange = 1;
                    END
                    
        IF @sAnyDepositChange > 0 AND EXISTS(
            SELECT 1 
            FROM 
                #sDataSet_SetBooking tmp 
            LEFT JOIN 
                dbo.mServiceCounter sc ON tmp.wDebitCounterRid = sc.RowID
            INNER JOIN 
                Rollsmary.dbo.mSettlePeriod sp ON sc.wRollexCompNo = sp.wCompNo AND CAST(FORMAT(tmp.wDepositDebitDt, 'yyyy-MM-dd') + ' 12:00:00' AS DATETIME2) BETWEEN sp.wStartDateTime AND sp.wEndDateTime
            WHERE
                CONCAT(sp.wYear, sp.wMonth) <= @vMthEndYearMth
        ) BEGIN
            SET @pErrMsg = CONCAT(@vMthEndYearMth, ' already month end, cannot insert expense on or before that.');
            THROW 50001, @pErrMsg, 1;
        END

        --所有預訂->取消按金的日期 不可早於 確認該筆按金時的日期
        DECLARE @sOldBookingStatus VARCHAR(10)
        SELECT  @sOldBookingStatus=b.wBookingStatus
        FROM    #sDataSet_SetBooking tmp
        INNER JOIN dbo.eBooking b ON tmp.RowID = b.RowID

        IF @pActionType IN ('U','D')AND EXISTS(
            SELECT 1 
            FROM    #sDataSet_SetBooking tmp
            INNER JOIN dbo.eBooking b ON tmp.RowID = b.RowID
            WHERE   tmp.wDepositAmt != b.wDepositAmt AND b.wDepositAmt!=0 AND ((CAST(FORMAT(tmp.wDepositDebitDt, 'yyyy-MM-dd') + ' 12:00:00' AS DATETIME2)<b.wDepositDebitDt)
                    OR (tmp.wBookingStatus IN ('CL','UQ','C') AND @sOldBookingStatus !='C' AND (CAST(FORMAT(tmp.wDebitDt, 'yyyy-MM-dd') + ' 12:00:00' AS DATETIME2)<b.wDepositDebitDt))
                    OR (tmp.wBookingStatus='RF' AND tmp.wBookingType = 'ROOM' AND (CAST(FORMAT(tmp.wCancelDebitDt, 'yyyy-MM-dd') + ' 12:00:00' AS DATETIME2)<b.wDepositDebitDt))
                     )
        ) BEGIN
            SET @pErrMsg = N'取消按金的日期 不可早於 確認該筆按金時的日期';
            THROW 50001, @pErrMsg, 1;
        END

        --按金相同的話，不能更改按金日期
        IF @pActionType IN ('U','D')AND EXISTS(
            SELECT 1 
            FROM    #sDataSet_SetBooking tmp
            INNER JOIN dbo.eBooking b ON tmp.RowID = b.RowID
            WHERE   tmp.wDepositAmt = b.wDepositAmt  AND 
                    (CAST(FORMAT(tmp.wDepositDebitDt, 'yyyy-MM-dd') + ' 12:00:00' AS DATETIME2)<b.wDepositDebitDt)
                    AND b.wDepositAmt!=0
                   
        ) BEGIN
            SET @pErrMsg = N'如要更改按金日期到之前的日子，請先把按金歸0。';
            THROW 50001, @pErrMsg, 1;
        END
        --------------------------------------------------------
        -- END wDepositAmt
        --------------------------------------------------------
        
        SELECT  tmp.RowID ,
                tmp.wRowNum ,
                tmp.wBookingType ,
                tmp.wRefNo ,
                tmp.[GUID] ,
                tmp.wReqCounterRid ,
                tmp.wDebitCounterRid ,
                tmp.wReqAgentCodeIn ,
                tmp.wDebitAgentCodeIn ,
                tmp.wReqCustomerRid ,
                tmp.wDebitCustomerRid ,
                tmp.wReqDepartment ,
                tmp.wReqUserRid ,
                tmp.wAsstBooker ,
                tmp.wAssBookerTel ,
                tmp.wApprovalAgentCodeIn ,
                tmp.wDebitDt ,
                tmp.wExpDt ,
                tmp.wCancelDebitDt ,
                tmp.wCancelReasonCd ,
                tmp.wOtherReason ,
                tmp.wCancelBy ,
                tmp.wCancelDt ,
                tmp.wCrtBy ,
                tmp.wCrtDt ,
                tmp.wUpdBy ,
                tmp.wUpdDt ,
                tmp.wTravePkgRid ,
                tmp.wUseTravelPkg,
                tmp.wEventCodeRid ,
                tmp.wAsstBookerEmail ,
                tmp.wDeptFollwedCd ,
                tmp.wStaffFollwedRid ,
                tmp.wStaffTelephone ,
                tmp.wOwnerAuthTelephone ,
                tmp.wDepositAmt ,
                wOriginalDepositAmt = b.wDepositAmt,
                wOriginalDepositDebitDt=b.wDepositDebitDt,
                tmp.wDepositDebitDt, -- 按金日期
                tmp.wBookingStatus, -- 預訂狀態
                tmp.wCoordinator ,
                tmp.wIsUser ,
                tmp.wUser 
        INTO    #sTmpDepositAmt
        FROM    #sDataSet_SetBooking tmp
                LEFT JOIN dbo.eBooking b ON tmp.RowID = b.RowID
                
        BEGIN TRY
        -- Try to make the transaction scope as small as possible to reduce locking            
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF @pActionType = 'I'
                BEGIN    
                        --- All records from #sDataSet_SetBooking should be having same booking type, so takan booking type of first record
                    IF @bookingType = 'ADDITIONALEXPENSES'  
                    BEGIN 
                        IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqeAdditionalExpensesRefNo') AND type = 'SO') BEGIN
                            CREATE SEQUENCE seqeAdditionalExpensesRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999
                        END							
                    END
                    ELSE IF @bookingType = 'HOTEL'  
                    BEGIN  
                        IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqeHotelRefNo') AND type = 'SO') BEGIN
                            CREATE SEQUENCE seqeHotelRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999
                        END							
                    END						
                    ELSE IF @bookingType = 'SHOWTICKET'  
                    BEGIN  						    
                        IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqeShowTicketRefNo') AND type = 'SO') BEGIN
                            CREATE SEQUENCE seqeShowTicketRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999
                        END
                    END  

                    ELSE IF @bookingType = 'TRAVEL_PACKAGE'  
                    BEGIN  
                        IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqeTravelPackageRefNo') AND type = 'SO') BEGIN
                            CREATE SEQUENCE seqeTravelPackageRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999
                        END							  							  							
                    END  

                    ELSE IF @bookingType = 'FERRY'  
                    BEGIN  
                        IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqeFerryRefNo') AND type = 'SO') BEGIN
                            CREATE SEQUENCE seqeFerryRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999
                        END							  							  							
                    END  

                    ELSE IF @bookingType = 'HELI'  
                    BEGIN 
                        IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqeHeliRefNo') AND type = 'SO') BEGIN
                            CREATE SEQUENCE seqeHeliRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999
                        END							  							  							
                    END  

                    ELSE IF @bookingType = 'AIRTICKET'  
                    BEGIN  
                        IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqeAirTicketRefNo') AND type = 'SO') BEGIN
                            CREATE SEQUENCE seqeAirTicketRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999
                        END							  							  							
                    END  

                    ELSE IF @bookingType = 'PP'  
                    BEGIN  
                        IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqePrivatePlaneRefNo') AND type = 'SO') BEGIN
                            CREATE SEQUENCE seqePrivatePlaneRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999
                        END							  							  							
                    END 

                    ELSE IF @bookingType = 'CHK_IN_SVC'  
                    BEGIN 						
                        IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqeCheckInServiceRefNo') AND type = 'SO') BEGIN
                            CREATE SEQUENCE seqeCheckInServiceRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999
                        END							  							  							
                    END  

                    ELSE IF @bookingType = 'LEADING_SERVICE'  
                    BEGIN  
                        IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqeLeadingServiceRefNo') AND type = 'SO') BEGIN
                            CREATE SEQUENCE seqeLeadingServiceRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999
                        END							  							  							
                    END 

                    ELSE IF @bookingType = 'PickUp_SERVICE'  
                    BEGIN
                        IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqePickUpServiceRefNo') AND type = 'SO') BEGIN
                            CREATE SEQUENCE seqePickUpServiceRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999
                        END							  							  							
                    END 

                    ELSE IF @bookingType = 'TOUR'  
                    BEGIN  
                        IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqeTourRefNo') AND type = 'SO') BEGIN
                            CREATE SEQUENCE seqeTourRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999
                        END							  							  							
                    END

                    ELSE IF @bookingType = 'RESTAURANT'  
                    BEGIN  
                        IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqeRestaurantRefNo') AND type = 'SO') BEGIN
                            CREATE SEQUENCE seqeRestaurantRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999
                        END							  							  							
                    END 

                    ELSE IF @bookingType = 'Visa'  
                    BEGIN  
                        IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqeVisaRefNo') AND type = 'SO') BEGIN
                            CREATE SEQUENCE seqeVisaRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999
                        END							  							  							
                    END 

                -- Set RowID by Sequence    
                    UPDATE  #sDataSet_SetBooking SET RowID = 0; 
                    SELECT  @sRecCount = COUNT(1) FROM #sDataSet_SetBooking;
  
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;        
                        ---- Generating reference number for booking
                        
                            IF @bookingType = 'ADDITIONALEXPENSES'  
                            BEGIN 
                               SET @refNo = 'D' + FORMAT(NEXT VALUE FOR dbo.seqeAdditionalExpensesRefNo, '0000000')
                            END  

                            ELSE IF @bookingType = 'HOTEL'  
                            BEGIN  
                               SET @refNo = 'H' + FORMAT(NEXT VALUE FOR dbo.seqeHotelRefNo, '0000000')	
                            END
                            ELSE IF @bookingType = 'ROOM'  
                            BEGIN  
                               SELECT TOP 1 @refNo = wRefNo FROM #sDataSet_SetBooking;
                            END

                            ELSE IF @bookingType = 'SHOWTICKET'  
                            BEGIN  						    
                                 SET @refNo = 'S' + FORMAT(NEXT VALUE FOR dbo.seqeShowTicketRefNo, '0000000')	
                            END  

                            ELSE IF @bookingType = 'TRAVEL_PACKAGE'  
                            BEGIN  
                                 SET @refNo = 'K' + FORMAT(NEXT VALUE FOR dbo.seqeTravelPackageRefNo, '0000000')
                            END  

                            ELSE IF @bookingType = 'FERRY'  
                            BEGIN  
                               SET @refNo = 'F' + FORMAT(NEXT VALUE FOR dbo.seqeFerryRefNo, '0000000')	
                            END  

                            ELSE IF @bookingType = 'HELI'  
                            BEGIN 
                               SET @refNo = 'L' + FORMAT(NEXT VALUE FOR dbo.seqeHeliRefNo, '0000000')	 
                            END  

                            ELSE IF @bookingType = 'AIRTICKET'  
                            BEGIN  
                               SET @refNo = 'A' + FORMAT(NEXT VALUE FOR dbo.seqeAirTicketRefNo, '0000000')	 
                            END  

                            ELSE IF @bookingType = 'PP'  
                            BEGIN  
                               SET @refNo = 'P' + FORMAT(NEXT VALUE FOR dbo.seqePrivatePlaneRefNo, '0000000')	 
                            END 

                            ELSE IF @bookingType = 'CHK_IN_SVC'  
                            BEGIN 						
                               SET @refNo = 'C' + FORMAT(NEXT VALUE FOR dbo.seqeCheckInServiceRefNo, '0000000')	  
                            END  

                            ELSE IF @bookingType = 'LEADING_SERVICE'  
                            BEGIN  
                               SET @refNo = 'E' + FORMAT(NEXT VALUE FOR dbo.seqeLeadingServiceRefNo, '0000000')	 
                            END 

                            ELSE IF @bookingType = 'PickUp_SERVICE'  
                            BEGIN
                               SET @refNo = 'U' + FORMAT(NEXT VALUE FOR dbo.seqePickUpServiceRefNo, '0000000')	
                            END 

                            ELSE IF @bookingType = 'TOUR'  
                            BEGIN  
                               SET @refNo = 'G' + FORMAT(NEXT VALUE FOR dbo.seqeTourRefNo, '0000000')
                            END

                            ELSE IF @bookingType = 'RESTAURANT'  
                            BEGIN  
                               SET @refNo = 'R' + FORMAT(NEXT VALUE FOR dbo.seqeRestaurantRefNo, '0000000')								  
                            END 

                            ELSE IF @bookingType = 'Visa'  
                            BEGIN  
                               SET @refNo = 'V' + FORMAT(NEXT VALUE FOR dbo.seqeVisaRefNo, '0000000')								
                            END

                            ELSE IF @bookingType = 'CHANGEHOTEL'
                            BEGIN
                                SET @refNo = @changHotelRefNo;
                            END

                            SET @refNo = ISNULL(@refNo, '');
                        ---- Update row id and refNo
                            UPDATE  #sDataSet_SetBooking
                            SET     RowID = @sRowID ,
                                    wRefNo = @refNo
                            WHERE   wRowNum = @sRuningIndex;    

                            UPDATE  #sTmpDepositAmt
                            SET     RowID = @sRowID ,
                                    wRefNo = @refNo
                            WHERE   wRowNum = @sRuningIndex;    

                            SET @sRuningIndex = @sRuningIndex + 1;  
                        END;                  
            
                    -- MAIN Logic here, example here is inserting dataset to eIOUPenalty    
                    INSERT  INTO dbo.[eBooking]
                            ( [RowID] ,
                              [wBookingType] ,
                              [wRefNo] ,
                              [GUID] ,
                              [wReqCounterRid] ,
                              [wDebitCounterRid] ,
                              [wReqAgentCodeIn] ,
                              [wDebitAgentCodeIn] ,
                              [wReqCustomerRid] ,
                              [wDebitCustomerRid] ,
                              [wReqDepartment] ,
                              [wReqUserRid] ,
                              [wAsstBooker] ,
                              [wAssBookerTel] ,
                              [wApprovalAgentCodeIn] ,
                              [wDebitDt] ,
                              [wExpDt] ,
                              [wCancelDebitDt] ,
                              [wCancelReasonCd] ,
                              [wOtherReason] ,
                              [wCancelBy] ,
                              [wCancelDt] ,
                              [wCrtBy] ,
                              [wCrtDt] ,
                              [wUpdBy] ,
                              [wUpdDt] ,
                              [wTravePkgRid] ,
                              [wUseTravelPkg],
                              [wEventCodeRid] ,
                              [wAsstBookerEmail] ,
                              [wDeptFollwedCd] ,
                              [wStaffFollwedRid] ,
                              [wStaffTelephone] ,
                              [wOwnerAuthTelephone] ,
                              [wDepositAmt] ,
                              [wGiftReasonCd],
                              [wHasDeposit],
                              [wDepositDebitDt],
                              [wBookingStatus],
                              [wCoordinator] ,
                              [wIsUser] ,
                              [wUser] 
                            )
                            SELECT  s.RowID ,
                                    s.wBookingType ,
                                    s.wRefNo ,
                                    NEWID() ,
                                    s.wReqCounterRid ,
                                    s.wDebitCounterRid ,
                                    s.wReqAgentCodeIn ,
                                    s.wDebitAgentCodeIn ,
                                    s.wReqCustomerRid ,
                                    s.wDebitCustomerRid ,
                                    s.wReqDepartment ,
                                    s.wReqUserRid ,
                                    s.wAsstBooker ,
                                    s.wAssBookerTel ,
                                    s.wApprovalAgentCodeIn ,
                                    CAST(FORMAT(s.wDebitDt, 'yyyy-MM-dd') + ' 12:00:00' AS DATETIME2) , -- Changed To Date Only   
                                    s.wExpDt ,
                                    wCancelDebitDt = CASE WHEN s.wCancelDebitDt IS NULL THEN NULL ELSE CAST(FORMAT(s.wCancelDebitDt, 'yyyy-MM-dd') + ' 12:00:00' AS DATETIME2) END , -- Changed To Date Only   
                                    s.wCancelReasonCd ,
                                    s.wOtherReason ,
                                    s.wCancelBy ,
                                    s.wCancelDt ,
                                    s.wUpdBy ,
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy ,
                                    dbo.fnUTC8Now() ,
                                    s.wTravePkgRid ,
                                    s.wUseTravelPkg,
                                    ISNULL(s.wEventCodeRid, -1) ,
                                    ISNULL(s.wAsstBookerEmail, '') ,
                                    ISNULL(s.wDeptFollwedCd, '') ,
                                    ISNULL(s.wStaffFollwedRid, -1) ,
                                    ISNULL(s.wStaffTelephone, '') ,
                                    ISNULL(s.wOwnerAuthTelephone, '') ,
                                    ISNULL(s.wDepositAmt, 0) ,
                                    ISNULL(s.wGiftReasonCd, ''),
                                    wHasDeposit = CASE WHEN ISNULL(s.wDepositAmt, 0) != 0 THEN 'Y' ELSE 'N' END, -- INSERT，按金不等於0， wHasDeposit = 'Y' ELSE 'N'
                                    wDepositDebitDt = CAST(FORMAT(ISNULL(s.wDepositDebitDt, GETDATE()), 'yyyy-MM-dd') + ' 12:00:00' AS DATETIME2) ,
                                    ISNULL(s.wBookingStatus,''),
                                    ISNULL(s.wCoordinator, '') ,
                                    s.wIsUser ,
                                    ISNULL(s.wUser, '') 
                            FROM    #sDataSet_SetBooking s;  
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                --- Logic for Updating booking data
                        UPDATE  eb
                        SET     eb.wReqCounterRid = tmp.wReqCounterRid ,
                                eb.wDebitCounterRid = tmp.wDebitCounterRid ,
                                eb.wReqAgentCodeIn = tmp.wReqAgentCodeIn ,
                                eb.wDebitAgentCodeIn = tmp.wDebitAgentCodeIn ,
                                eb.wReqCustomerRid = tmp.wReqCustomerRid ,
                                eb.wDebitCustomerRid = tmp.wDebitCustomerRid ,
                                eb.wReqDepartment = tmp.wReqDepartment ,
                                eb.wReqUserRid = tmp.wReqUserRid ,
                                eb.wAsstBooker = tmp.wAsstBooker ,
                                eb.wAssBookerTel = tmp.wAssBookerTel ,
                                eb.wApprovalAgentCodeIn = tmp.wApprovalAgentCodeIn ,
                                eb.wDebitDt = CAST(FORMAT(tmp.wDebitDt, 'yyyy-MM-dd') + ' 12:00:00' AS DATETIME2)  -- Changed To Date Only   
                                ,
                                eb.wExpDt = tmp.wExpDt ,
                                eb.wCancelDebitDt = CASE WHEN tmp.wCancelDebitDt IS NULL THEN NULL ELSE CAST(FORMAT(tmp.wCancelDebitDt, 'yyyy-MM-dd') + ' 12:00:00' AS DATETIME2) END -- Changed To Date Only   
                                ,
                                eb.wCancelReasonCd = tmp.wCancelReasonCd ,
                                eb.wOtherReason = tmp.wOtherReason ,
                                eb.wCancelBy = ISNULL(eb.wCancelBy, tmp.wCancelBy) ,
                                eb.wCancelDt = ISNULL(eb.wCancelDt, tmp.wCancelDt) ,
                                eb.wUpdBy = CASE WHEN tmp.wUpdBy IS NOT NULL AND tmp.wUpdBy > 0 THEN tmp.wUpdBy ELSE eb.wUpdBy END,
                                eb.wUpdDt = dbo.fnUTC8Now() ,
                                eb.wTravePkgRid = tmp.wTravePkgRid ,
                                eb.wUseTravelPkg = tmp.wUseTravelPkg ,
                                eb.wEventCodeRid = ISNULL(tmp.wEventCodeRid, -1) ,
                                eb.wAsstBookerEmail = ISNULL(tmp.wAsstBookerEmail, '') ,
                                eb.wDeptFollwedCd = ISNULL(tmp.wDeptFollwedCd, '') ,
                                eb.wStaffFollwedRid = ISNULL(tmp.wStaffFollwedRid, -1) ,
                                eb.wStaffTelephone = ISNULL(tmp.wStaffTelephone, '') ,
                                eb.wOwnerAuthTelephone = ISNULL(tmp.wOwnerAuthTelephone, '') ,
                                eb.wDepositAmt = ISNULL(tmp.wDepositAmt, 0) ,
                                eb.wGiftReasonCd = ISNULL(tmp.wGiftReasonCd, ''),
                                eb.wHasDeposit = CASE WHEN eb.wHasDeposit = 'Y' OR ISNULL(tmp.wDepositAmt, 0) != 0 THEN 'Y' ELSE 'N' END, -- UPDATE，按金不等於0 OR wHasDeposit = 'Y'， wHasDeposit = 'Y' ELSE 'N'（如果已經Set過按金的，就不能再Set回N）
                                eb.wDepositDebitDt = CAST(FORMAT(ISNULL(tmp.wDepositDebitDt, eb.wDepositDebitDt), 'yyyy-MM-dd') + ' 12:00:00' AS DATETIME2), -- 按金日期如果沒空，不能改變舊值
                                eb.wBookingStatus=ISNULL(tmp.wBookingStatus,''),
                                eb.wCoordinator = ISNULL(tmp.wCoordinator, '') ,
                                eb.wIsUser = tmp.wIsUser ,
                                eb.wUser = ISNULL(tmp.wUser, '') 
                        FROM    dbo.eBooking AS eb
                                INNER JOIN #sDataSet_SetBooking tmp ON eb.RowID = tmp.RowID
                        WHERE   eb.RowID = tmp.RowID;

                        -- UPDATE Gift ReasonCd if exists
                        IF EXISTS(Select g.RowID from dbo.eGift g INNER JOIN #sDataSet_SetBooking tmp ON tmp.RowID = g.wRefBookingRid AND g.wRefTableName='eBooking')
                        BEGIN
                            DECLARE @sGiftRowID BIGINT
                            Select TOP 1 @sGiftRowID =g.RowID from dbo.eGift g INNER JOIN #sDataSet_SetBooking tmp ON tmp.RowID = g.wRefBookingRid AND g.wRefTableName='eBooking' ORDER BY g.wUpdDt DESC

                            UPDATE g SET g.wReasonCd=tmp.wGiftReasonCd,
                                         g.wUpdBy =tmp.wUpdBy,
                                         g.wUpdDt =tmp.wUpdDt
                             FROM    dbo.eGift AS g
                                     INNER JOIN #sDataSet_SetBooking tmp ON tmp.RowID = g.wRefBookingRid AND g.wRefTableName='eBooking' AND g.RowID=@sGiftRowID
                        END
                        /*
                        IF EXISTS(Select g.RowID from dbo.eGift g INNER JOIN #sDataSet_SetBooking tmp ON tmp.RowID = g.wRefBookingRid AND g.wRefTableName='eBooking' AND g.wOriActionType='RF')
                        BEGIN
                            UPDATE g SET g.wReasonCd=tmp.wGiftReasonCd,
                                         g.wUpdBy =tmp.wUpdBy,
                                         g.wUpdDt =tmp.wUpdDt
                             FROM    dbo.eGift AS g
                                INNER JOIN #sDataSet_SetBooking tmp ON tmp.RowID = g.wRefBookingRid AND g.wRefTableName='eBooking' AND g.wOriActionType='RF'                        
                        END
                        ELSE IF  EXISTS(Select g.RowID from dbo.eGift g INNER JOIN #sDataSet_SetBooking tmp ON tmp.RowID = g.wRefBookingRid AND g.wRefTableName='eBooking' AND g.wOriActionType='C')
                        BEGIN
                            UPDATE g SET g.wReasonCd=tmp.wGiftReasonCd,
                                         g.wUpdBy =tmp.wUpdBy ,
                                         g.wUpdDt =tmp.wUpdDt
                             FROM    dbo.eGift AS g
                                INNER JOIN #sDataSet_SetBooking tmp ON tmp.RowID = g.wRefBookingRid AND g.wRefTableName='eBooking' AND g.wOriActionType='C'                        
                        END;*/
                        -----------------------------------------------------------------------------------------------
                    END;    
                ELSE
                    IF @pActionType = 'D'
                        BEGIN
               --- Logic for Updating booking data
                            UPDATE  eb
                            SET     wDepositAmt = 0, -- 刪除，強行把按金設置為0，退按金
                                    wCancelDt = dbo.fnUTC8Now() ,
                                    wUpdDt = dbo.fnUTC8Now() ,
                                    wUpdBy = tmp.wUpdBy ,
                                    wCancelBy = tmp.wUpdBy,
                                    wBookingStatus=tmp.wBookingStatus
                            FROM    dbo.eBooking AS eb
                                    INNER JOIN #sDataSet_SetBooking tmp ON eb.RowID = tmp.RowID
                            WHERE   eb.RowID = tmp.RowID;  
                        END;  
            
        -- Set booking id
            SELECT  @pBookingRid = RowID FROM #sDataSet_SetBooking;
        ----------------------------------------------------------------------------------
        -- Sync DepositAmt to Rollsmary.dbo.eExpTran
        ---------------------------------------------------------------------------------- 
            IF @sAnyDepositChange > 0
                BEGIN
                    DECLARE @pAcsId_In BIGINT ,
                        @vErrCode INT ,
                        @vErrMsg NVARCHAR(MAX),
                        @sUsrCName NVARCHAR(50) ,
                        @vRowID BIGINT ,
                        @vRefRid BIGINT = 0,
                        @vwBookingType VARCHAR(30) ,
                        @vwRefNo VARCHAR(30) ,
                        @vGUID UNIQUEIDENTIFIER ,
                        @vwReqCounterRid BIGINT ,
                        @vwDebitCounterRid BIGINT ,
                        @vwReqAgentCodeIn VARCHAR(14) ,
                        @vwDebitAgentCodeIn VARCHAR(14) ,
                        @vwReqCustomerRid BIGINT ,
                        @vwDebitCustomerRid BIGINT ,
                        @vwReqDepartment VARCHAR(30) ,
                        @vwReqUserRid BIGINT ,
                        @vwAsstBooker NVARCHAR(50) ,
                        @vwAssBookerTel VARCHAR(100) ,
                        @vwApprovalAgentCodeIn VARCHAR(14) ,
                        @vwDebitDt DATETIME2(7) ,
                        @vwExpDt DATETIME2(7) ,
                        @vwCancelDebitDt DATETIME2(7) ,
                        @vwCancelReasonCd VARCHAR(30) ,
                        @vwOtherReason NVARCHAR(200) ,
                        @vwCancelBy BIGINT ,
                        @vwCancelDt DATETIME2(7) ,
                        @vwCrtBy BIGINT ,
                        @vwCrtDt DATETIME2(7) ,
                        @vwUpdBy BIGINT ,
                        @vwUpdDt DATETIME2(7) ,
                        @vwTravePkgRid BIGINT ,
                        @vwUseTravelPkg CHAR(1) ,
                        @vwEventCodeRid BIGINT ,
                        @vwAsstBookerEmail NVARCHAR(50) ,
                        @vwDeptFollwedCd VARCHAR(30) ,
                        @vwStaffFollwedRid BIGINT ,
                        @vwStaffTelephone VARCHAR(100) ,
                        @vwOwnerAuthTelephone VARCHAR(100) ,
                        @vwDepositAmt NUMERIC(18, 4) ,
                        @vwDepositDebitDt DATETIME2(7),
                        @vwBookingStatus VARCHAR(10),
                        @vwCompNo INT,
                        @vwCageCodeIn BIGINT,
                        @vwCurrCode	VARCHAR(6),
                        @vwDefaultHotelCode VARCHAR(30),
                        @vRemark NVARCHAR(MAX) = N'' ,
                        @vExpDesc NVARCHAR(4000) = '' ,
                        @vExpCategory NVARCHAR(10),
                        @vPeriodCodeIn VARCHAR(30),
                        @vXMLInsertExp NVARCHAR(MAX) = '',
                        @vwCoordinator NVARCHAR(50) ,
                        @vwIsUser CHAR(1) ,
                        @vwUser NVARCHAR(50) ;

                    DECLARE curXMLTempTbl CURSOR
                    FOR
                        SELECT  tmp.RowID ,
                                tmp.wBookingType ,
                                tmp.wRefNo ,
                                tmp.[GUID] ,
                                tmp.wReqCounterRid ,
                                tmp.wDebitCounterRid ,
                                tmp.wReqAgentCodeIn ,
                                tmp.wDebitAgentCodeIn ,
                                tmp.wReqCustomerRid ,
                                tmp.wDebitCustomerRid ,
                                tmp.wReqDepartment ,
                                tmp.wReqUserRid ,
                                tmp.wAsstBooker ,
                                tmp.wAssBookerTel ,
                                tmp.wApprovalAgentCodeIn ,
                                tmp.wDebitDt ,
                                tmp.wExpDt ,
                                tmp.wCancelDebitDt ,
                                tmp.wCancelReasonCd ,
                                tmp.wOtherReason ,
                                tmp.wCancelBy ,
                                tmp.wCancelDt ,
                                tmp.wCrtBy ,
                                tmp.wCrtDt ,
                                tmp.wUpdBy ,
                                tmp.wUpdDt ,
                                tmp.wTravePkgRid ,
                                tmp.wUseTravelPkg ,
                                tmp.wEventCodeRid ,
                                tmp.wAsstBookerEmail ,
                                tmp.wDeptFollwedCd ,
                                tmp.wStaffFollwedRid ,
                                tmp.wStaffTelephone ,
                                tmp.wOwnerAuthTelephone ,
                                tmp.wDepositAmt,
                                tmp.wDepositDebitDt, -- 按金日期
                                tmp.wBookingStatus, -- 預訂狀態
                                sc.wRollexCompNo,
                                sc.wCurrCode,
                                sc.wDefaultHotelCode,
                                c.wCageCodeIn,
                                tmp.wCoordinator ,
                                tmp.wIsUser ,
                                tmp.wUser 
                        FROM    #sTmpDepositAmt tmp
                                LEFT JOIN dbo.eBooking b ON tmp.RowID = b.RowID
                                LEFT JOIN dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                                LEFT JOIN Rollsmary.dbo.mCage c ON sc.wRollexCompNo = c.wCompNo AND c.wStatus = 'A' AND c.wCageCode = '001'
                                    
                        WHERE   CASE WHEN @pActionType = 'D' THEN ISNULL(b.wCancelDebitDt, dbo.fnUTC8Now())
                                     ELSE ISNULL(b.wDebitDt, dbo.fnUTC8Now())
                                END >= @vDateUsingCRM
                                AND ( ( @pActionType = 'I'
                                        AND (tmp.wDepositAmt != 0 OR tmp.wBookingType = 'CHANGEHOTEL')
                                      )
                                      OR @pActionType = 'D'
                                      OR ( @pActionType = 'U'
                                           AND ((tmp.wDepositAmt != tmp.wOriginalDepositAmt) 
                                                OR( CAST(FORMAT(tmp.wDepositDebitDt, 'yyyy-MM-dd') + ' 12:00:00' AS DATETIME2)>CAST(FORMAT(tmp.wOriginalDepositDebitDt, 'yyyy-MM-dd') + ' 12:00:00' AS DATETIME2)
                                                   AND tmp.wDepositAmt = tmp.wOriginalDepositAmt AND tmp.wDepositAmt!=0)
                                               )
                                         )
                                    )

                    OPEN curXMLTempTbl
                    FETCH NEXT FROM curXMLTempTbl
                    INTO @vRowID, @vwBookingType, @vwRefNo, @vGUID, @vwReqCounterRid, @vwDebitCounterRid, @vwReqAgentCodeIn, @vwDebitAgentCodeIn, @vwReqCustomerRid, @vwDebitCustomerRid, @vwReqDepartment, @vwReqUserRid, @vwAsstBooker, @vwAssBookerTel, @vwApprovalAgentCodeIn, @vwDebitDt, @vwExpDt, @vwCancelDebitDt, @vwCancelReasonCd, @vwOtherReason, @vwCancelBy, @vwCancelDt, @vwCrtBy, @vwCrtDt, @vwUpdBy, @vwUpdDt, @vwTravePkgRid, @vwUseTravelPkg, @vwEventCodeRid, @vwAsstBookerEmail, @vwDeptFollwedCd, @vwStaffFollwedRid, @vwStaffTelephone, @vwOwnerAuthTelephone, @vwDepositAmt,@vwDepositDebitDt, @vwBookingStatus, @vwCompNo, @vwCurrCode, @vwDefaultHotelCode, @vwCageCodeIn,
                         @vwCoordinator, @vwIsUser, @vwUser

                    WHILE @@FETCH_STATUS = 0
                        BEGIN 
                            SELECT  @sUsrCName = wCName
                            FROM    RollsMary.dbo.mUsr
                            WHERE   RowID = @vwUpdBy
                            SET @vExpCategory = CASE WHEN @vwBookingType IN ( 'RESTAURANT' ) THEN N'DINE'
                                                     WHEN @vwBookingType IN ( 'HOTEL', 'ROOM', 'CHANGEHOTEL' ) THEN N'STAY'
                                                     WHEN @vwBookingType IN ( 'LEADING', 'PRIVATE_PLANE', 'PICK_UP', 'HELI', 'AIR_TICKET', 'CHECK_IN', 'FERRY' ) THEN N'TRAVEL'
                                                     WHEN @vwBookingType IN ( 'TRAVEL_PACKAGE' ) THEN N'ENTERTAINM'
                                                END;
                -- LATER: Need to create the description to ROllsmary expense
                            SET @vExpDesc = '';

                -- 房間存儲的 bookingRid 跟 wRefId 比較特別需要特別處理
                            DECLARE @vwRoomOldBookingStatus VARCHAR(10); -- 房間預訂之前的預訂狀態

                            IF @vwBookingType = 'ROOM'
                            BEGIN
                                SELECT @vRefRid = br.RowID, @vwRoomOldBookingStatus = br.wBookingStatus
                                    FROM dbo.eBookingRoom AS br
                                    WHERE br.wBookingRid = @vRowID;
                                --- insert 的時候 eBookingRoom 還沒有 update 數據，wHotelBookingRid 仍然為 null, 取不到..
                                SELECT @vRowID = wBookingRid FROM dbo.eBookingHotel WHERE RowID = ISNULL(@sBookingHotelRid, 0);
                            END
                            ELSE IF @vwBookingType = 'CHANGEHOTEL'
                            BEGIN
                                SELECT @vRefRid = br.RowID, @vRowID = bh.wBookingRid, @vwRoomOldBookingStatus = br.wBookingStatus
                                    FROM dbo.eBookingRoom AS br 
                                         INNER JOIN dbo.eBookingHotel AS bh ON br.wHotelBookingRid = bh.RowID
                                    WHERE br.RowID = @sBookingHotelRid;

                                --SELECT @vRowID = wBookingRid FROM dbo.eBookingHotel WHERE RowID = ISNULL(@sBookingHotelRid, 0);
                            END
                -- 房間存儲的 bookingRid 跟 wRefId 比較特別需要特別處理 end
                
                -- VOID original deposit Amt
                            IF @pActionType IN ( 'U', 'D' ) OR (@pActionType = 'I' AND @vwBookingType = 'CHANGEHOTEL')
                            BEGIN
                                    -- 退按金【扣數日期】
                                    DECLARE @vDebitDt DATETIME2(7);
                                    SET @vDebitDt = CASE WHEN @vwBookingStatus = 'P' THEN @vwDepositDebitDt
                                                         WHEN @vwBookingStatus = 'CL' THEN @vwDebitDt
                                                         WHEN @vwBookingStatus = 'UQ' THEN @vwDebitDt
                                                         WHEN @vwBookingStatus = 'C' AND ISNULL(@vwRoomOldBookingStatus, 'P') = 'P' THEN @vwDebitDt -- 非更改入住日期【完成】，用扣數日期
                                                         WHEN @vwBookingStatus = 'RF' THEN @vwCancelDebitDt
                                                         WHEN @vwBookingType = 'CHANGEHOTEL' AND @vwDepositAmt <= 0 THEN @vwDebitDt -- 已有按金 = 1000, 完成修改動作(eg.如房間的續房) (生成refund記錄-1000用扣數日期, 生成訂單的消費記錄用扣數日期)
                                                         ELSE @vwDepositDebitDt END;

                                    DECLARE @vErrCodeVoidDeposit INT ,
                                        @vErrMsgVoidDeposit NVARCHAR(200) ,
                                        @vXMLVoidDeposit NVARCHAR(MAX);
                                    SET @vXMLVoidDeposit = ( SELECT wBookingRid = @vRowID, wRefRid = @vRefRid
                                                           FOR
                                                             XML RAW('Record') ,
                                                                 ROOT('DataSet')
                                                           ); 
                                    -- 添加select返回值到臨時表，不需要此值
                                    DECLARE @tActionDepositDone TABLE(RowId BIGINT);
                                    INSERT INTO @tActionDepositDone(RowId)
                                    EXEC RollsMary.apiSet.CRM_ActionDepositDone @pXML = @vXMLVoidDeposit, -- nvarchar(max)
                                        @pUpdBy = @vwUpdBy, -- bigint
                                        @pVoidDt = @vDebitDt, -- datetime2
                                        @pMainCompNo = @vwCompNo, -- int
                                        @pNonceToken = @pNonceToken, -- varchar(64)
                                        @pReturnResultSet = 'N', -- char(1)
                                        @pErrCode = @vErrCodeVoidDeposit OUTPUT, -- int
                                        @pErrMsg = @vErrMsgVoidDeposit OUTPUT -- nvarchar(200)

                                    IF @vErrCodeVoidDeposit != 0
                                    BEGIN
                                        SET @pErrMsg = @vErrMsgVoidDeposit;
                                        THROW 50001, @vErrMsgVoidDeposit, 1;
                                    END;
                           END
                                
                -- INSERT NEW Deposit Amt
                            IF @pActionType IN ( 'I', 'U' ) AND @vwDepositAmt > 0
                                BEGIN
                                    -- 按金【扣數日期】(都是使用wDepositDebitDt)
                                    DECLARE @sDebitDt DATETIME2(7);
                                    SET @sDebitDt = CASE WHEN @vwBookingStatus = 'P' THEN @vwDepositDebitDt -- @vwDepositAmt > 0
                                                         WHEN @vwBookingStatus = 'CL' THEN @vwDebitDt -- @vwDepositAmt = 0
                                                         WHEN @vwBookingStatus = 'UQ' THEN @vwDebitDt -- @vwDepositAmt = 0
                                                         WHEN @vwBookingStatus = 'C' AND ISNULL(@vwRoomOldBookingStatus, 'P') = 'P' THEN @vDebitDt   -- 確認消費，用【扣數日期】，房間完成后可以再修改，此后要用【按金日期】
                                                         WHEN @vwBookingStatus = 'RF' THEN @vwCancelDebitDt -- @vwDepositAmt = 0
                                                         WHEN @vwBookingType = 'CHANGEHOTEL' THEN @vwDepositDebitDt -- @vwDepositAmt > 0
                                                         ELSE @vwDepositDebitDt END;
                                    
                                    SET @sDebitDt = ISNULL(@sDebitDt, GETDATE());

                                    SET @vRemark = CONCAT(N'<預訂按金>', dbo.fnGetBookingTypeName(@vwBookingType), N', 編號: ', @vwRefNo);

                                    IF NOT EXISTS (SELECT sp.wPeriodCodeIn FROM Rollsmary.dbo.mSettlePeriod sp WHERE wCompNo = @vwCompNo AND CAST(FORMAT(@sDebitDt, 'yyyy-MM-dd') + ' 12:00:00' AS DATETIME2) BETWEEN sp.wStartDateTime AND sp.wEndDateTime)
                                    BEGIN
                                        -- 日期不對？
                                         DECLARE @zTmpDate DATE;
                                         SET @zTmpDate =  CAST(ISNULL(@vwCancelDebitDt, @vwDebitDt) AS date);
                                        -- EXEC RollsMary.dbo.spqGetCompPeriod @vwCompNo, @vwCompNo, @zTmpDate, 'Y', 'N';
                                        EXEC RollsMary.dbo.spqGetCompPeriod @vwCompNo, @vwCompNo, @sDebitDt, 'Y', 'N';

                                        -- wPeriodCodeIn獲取失敗，拋出異常
                                        IF NOT EXISTS (SELECT sp.wPeriodCodeIn FROM Rollsmary.dbo.mSettlePeriod sp WHERE wCompNo = @vwCompNo AND CAST(FORMAT(@sDebitDt, 'yyyy-MM-dd') + ' 12:00:00' AS DATETIME2) BETWEEN sp.wStartDateTime AND sp.wEndDateTime)
                                        BEGIN
                                            SET @pErrMsg = CONCAT('{', 'wErrMsg:''wPeriodCodeIn IS NULL''', ',vwCompNo:', CAST(@vwCompNo AS VARCHAR), ',sDebitDt:''', FORMAT(ISNULL(@sDebitDt, GETDATE()), 'yyyy-MM-dd  12:00:00'), ''',zTmpDate:''', FORMAT(@zTmpDate, 'yyyy-MM-dd'), '''}');
                                            THROW 50001, @pErrMsg, 1;
                                        END;
                                    END

                                    SET @vXMLInsertExp = (
                                        SELECT RowID = 0 ,
                                                wCompNo = @vwCompNo ,
                                                wCageCodeIn = @vwCageCodeIn ,
                                                wTranNo = '' ,
                                                wDate = FORMAT(@sDebitDt, 'yyyy-MM-dd') ,
                                                wCurDateTime = @vNow ,
                                                wShift = 1 ,
                                                wAgentCodeIn = @vwDebitAgentCodeIn ,
                                                wCardCodeIn = '' ,
                                                wCustName = '' ,
                                                wShopName = '' ,
                                                wExpTypeCode = 'DEPOSIT' ,
                                                wExpTargetCode = '' ,
                                                wExpCode = '' ,
                                                wExpSubCode1 = '' ,
                                                wCurCode = @vwCurrCode ,
                                                wRoomNo = '' ,
                                                wRoomCfmCode = '' ,
                                                wRoomBookDt = NULL ,
                                                wRoomCheckInDt = NULL ,
                                                wRoomDeptDt = NULL ,
                                                wNight = 0 ,
                                                wUnit = 1 ,
                                                wPrice = @vwDepositAmt,
                                                wRoomExpAmt = 0 ,
                                                wAmount = @vwDepositAmt,
                                                wExpLocation = @vwDefaultHotelCode ,
                                                wVoucherNo = '' ,
                                                wVoucherDt = FORMAT(@sDebitDt, 'yyyy-MM-dd') ,
                                                wRemark = @vRemark ,
                                                wPeriodCodeIn = (SELECT TOP 1 sp.wPeriodCodeIn FROM Rollsmary.dbo.mSettlePeriod sp WHERE wCompNo = @vwCompNo AND CAST(FORMAT(@sDebitDt, 'yyyy-MM-dd') + ' 12:00:00' AS DATETIME2) BETWEEN sp.wStartDateTime AND sp.wEndDateTime ORDER BY sp.wPeriodCodeIn) ,
                                                wExpType = 'I' ,
                                                wExpGroup = 'RCRM' ,
                                                wDeductType = 'DC' ,
                                                wPrtPage = 0 ,
                                                wPrtRow = 0 ,
                                                wTotSetAmt = 0 ,
                                                wUpdBy = @vwUpdBy ,
                                                wUpdDt = @vNow ,
                                                wRefRid = @vRefRid,
                                                wReferId = @vRowID ,
                                                wExpSite = '' ,
                                                wReferUpdBy = '' ,
                                                wEliteCodeIn = '' ,
                                                wSettleInstantTranNo = '' ,
                                                wIsAdj = 'N' ,
                                                wForeignTranRefNo = '' ,
                                                wFxRateHKD = 1 ,
                                                wFxRateRMB = 1 ,
                                                wExpDesc = N'' ,
                                                wExtUpdBy = @sUsrCName ,
                                                wInvoiceDateTime_CRM = @vwExpDt ,
                                                wAmountActual_CRM = @vwDepositAmt ,
                                                wCardNo_CRM = '' ,
                                                wAuthorizer_CRM = '' ,
                                                wExpCategory = @vExpCategory ,
                                                wGuid = '' ,
                                                wRequestAgentCodeIn = @vwReqAgentCodeIn ,
                                                wIsDeposit = 'Y' ,
                                                wIsDepositDone = 'N' ,
                                                wProductCategory = '' ,
                                                wProductDetail = '',
                                                wBookingRid = @vRowID,
                                                wBookingActionRid = -1,
                                                wIsDepositExposed = 'N',
                                                wBookingStatus = ''
                                         FOR XML RAW('Record'), ROOT('DataSet')
                                    );
                                    
                                    IF @vXMLInsertExp != ''
                                        BEGIN
                                            -- 添加select返回值到臨時表，不需要此值
                                            DECLARE @tExpTran TABLE(RowId BIGINT);
                                            INSERT INTO @tExpTran(RowId)
                                            EXEC RollsMary.spa.SetExpTran @pXML = @vXMLInsertExp, -- xml
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
                                            IF NOT EXISTS( SELECT 1 FROM RollsMary.dbo.eExpTran e INNER JOIN @tExpTran et ON e.RowID=et.RowId)
                                                BEGIN
                                                   SET @pErrMsg = N'沒有對應的射數記錄，保存失敗';
                                                    THROW 50001, @pErrMsg, 1;
                                                END;
                                        END;
/*                                    EXEC RollsMary.apiSet.CRM_SetExpTran @pRowID = 0, -- bigint
                                        @pCRMRefSysId = @vRowID, -- varchar(40)
                                        @pCompNo = @vwCompNo, -- int
                                        @pAgentCodeIn = @vwDebitAgentCodeIn, -- varchar(14)
                                        @pCustName = @vwAsstBooker, -- nvarchar(30)
                                        @pExpenseDateTime = @vwDebitDt, -- datetime2(7)
                                        @pInvoiceDatetime = @vwExpDt, -- datetime2(7)
                                        @pExpType = '', -- varchar(2)
                                        @pRoomNo = '', -- varchar(200)
                                        @pUnit = 1, -- int
                                        @pPrice = 0, -- numeric(18, 4)
                                        @pExpDesc = N'戶口扣數', -- nvarchar(200)
                                        @pAmount = @vwDepositAmt, -- numeric(18, 4)
                                        @pAmountActual_CRM = @vwDepositAmt, -- numeric(18, 4)
                                        @pVoucherNo = N'', -- nvarchar(400)
                                        @pCardNo = '', -- varchar(100)
                                        @pExtUpdBy = @sUsrCName, -- nvarchar(50)
                                        @pRemark = @vRemark, -- nvarchar(500)
                                        @pAuthorizerName = N'', -- nvarchar(200)
                                        @pExpCategory = @vExpCategory, -- nvarchar(10)
                                        @pIsDeposit = 'Y', @pIsDepositDone = 'N', @pAcsId_In = @vwUpdBy OUTPUT, -- bigint
                                        @pErrCode_In = @vErrCode OUTPUT, -- int
                                        @pErrMsg_In = @vErrMsg OUTPUT -- nvarchar(200)*/
                                END

                            FETCH NEXT FROM curXMLTempTbl INTO @vRowID, @vwBookingType, @vwRefNo, @vGUID, @vwReqCounterRid, @vwDebitCounterRid, @vwReqAgentCodeIn, @vwDebitAgentCodeIn, @vwReqCustomerRid, @vwDebitCustomerRid, @vwReqDepartment, @vwReqUserRid, @vwAsstBooker, @vwAssBookerTel, @vwApprovalAgentCodeIn, @vwDebitDt, @vwExpDt, @vwCancelDebitDt, @vwCancelReasonCd, @vwOtherReason, @vwCancelBy, @vwCancelDt, @vwCrtBy, @vwCrtDt, @vwUpdBy, @vwUpdDt, @vwTravePkgRid, @vwUseTravelPkg, @vwEventCodeRid, @vwAsstBookerEmail, @vwDeptFollwedCd, @vwStaffFollwedRid, @vwStaffTelephone, @vwOwnerAuthTelephone, @vwDepositAmt,@vwDepositDebitDt, @vwBookingStatus, @vwCompNo, @vwCurrCode, @vwDefaultHotelCode, @vwCageCodeIn,
                                                               @vwCoordinator, @vwIsUser, @vwUser
                        END
                    CLOSE curXMLTempTbl;  
                    DEALLOCATE curXMLTempTbl; 
                END
        ----------------------------------------------------------------------------------
        -- END Sync DepositAmt to Rollsmary.dbo.eExpTran
        ---------------------------------------------------------------------------------- 

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;
            
        -- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetBooking;	
           
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
        
        IF OBJECT_ID('tempdb..#sDataSet_SetBooking') IS NOT NULL
            DROP TABLE #sDataSet_SetBooking 
        IF OBJECT_ID('tempdb..#sTmpDepositAmt') IS NOT NULL
            DROP TABLE #sTmpDepositAmt 
        
    END;