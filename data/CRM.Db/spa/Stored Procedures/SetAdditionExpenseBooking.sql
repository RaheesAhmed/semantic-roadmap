CREATE PROCEDURE [spa].[SetAdditionExpenseBooking]
(    
    @pXML XML ,    
    @pActionType CHAR(1) , -- I/U/D    
    @pMainCompNo INT,    
    @pNonceToken VARCHAR(64), 
    @pReturnResultSet CHAR(1) = 'N',
    @TempRowId BIGINT = 0,
    @pBookingRid BIGINT OUTPUT, 
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT       
 )    
AS    
    BEGIN    
        SET NOCOUNT ON;    
      --SELECT '' wAgentCode,* from dbo.eBooking;    
     DECLARE @sThisTableName VARCHAR(50) = 'eBooking' ,-- For RowID    
            @sBeginTranCount INT = 0 ,    
            @sRecCount INT = 0 ,    
            @sRuningIndex INT = 1 ,    
            @sRowID BIGINT = 0 ,    
            @sDocHandle INT;    
        
    DECLARE @bookingType VARCHAR(30), @refNo Varchar(30), @refNumber BIGINT,@maxNumber BIGINT = 0;;  
        
    DECLARE @sReturnRowID TABLE ( RowID BIGINT );    
    DECLARE @sXMLBooking AS XML;
    SET @sBeginTranCount = @@trancount;    
           
    EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;    
         
    SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) , *    
    INTO    #sDataSet_SetBooking    
    FROM    OPENXML (@sDocHandle, 'DataSet/SetAdditionalExpBookingResult', 1)    
    WITH (    
        RowID BIGINT , 
        TempRowId BIGINT,
        wBookingType  VARCHAR(30) ,    
        wRefNo  VARCHAR(30) ,    
        wGUID uniqueidentifier,           
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
        wDebitDt DATETIME2(7),    
        wExpDt DATETIME2(7),    
        wCancelDebitDt DATETIME2(7),    
        wCancelReasonCd VARCHAR(30),  
        wOtherReason NVARCHAR(200),
        wCancelBy BIGINT ,    
        wCancelDt DATETIME2(7),    
        wUpdBy BIGINT ,    
        wUpdDt DATETIME2(7),  
        wTravePkgRid BIGINT,
        wEventCodeRid BIGINT,		 			
        wAsstBookerEmail NVARCHAR(50),
        wDeptFollwedCd VARCHAR(30),
        wStaffFollwedRid BIGINT,
        wStaffTelephone VARCHAR(100),
        wOwnerAuthTelephone VARCHAR(100),
        wGiftReasonCd VARCHAR(30),
        wBookingStatus VARCHAR(10)
    );  

    -- Delete unwanted records from table   

    DELETE FROM #sDataSet_SetBooking where RowID != @TempRowId
    
    SELECT * INTO #sDataSet_SetBooking2 FROM (SELECT wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ), RowID,TempRowId,wBookingType,wRefNo,wGUID,wReqCounterRid,wDebitCounterRid,wReqAgentCodeIn,wDebitAgentCodeIn,wReqCustomerRid,
           wDebitCustomerRid,wReqDepartment,wReqUserRid,wAsstBooker,wAssBookerTel,wApprovalAgentCodeIn,wDebitDt,wExpDt,wCancelDebitDt,wCancelReasonCd,wOtherReason,wCancelBy,
           wCancelDt,wUpdBy,wUpdDt,wTravePkgRid,wEventCodeRid,wAsstBookerEmail, wDeptFollwedCd ,wStaffFollwedRid,wStaffTelephone,wOwnerAuthTelephone, wGiftReasonCd,wBookingStatus
    FROM #sDataSet_SetBooking) as temp		
 
    BEGIN 
        IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqeAdditionalExpensesRefNo') AND type = 'SO') BEGIN
            CREATE SEQUENCE seqeAdditionalExpensesRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999
        END
    END  

    UPDATE  #sDataSet_SetBooking2    
    SET     TempRowId = RowID, RowID = 0;  
    
        -- Insert only those records who has RowId = @TempRowId
    SELECT  @sRecCount = COUNT(*)    
    FROM    #sDataSet_SetBooking2;-- WHERE RowID = @TempRowId;	

    BEGIN TRY
            -- Try to make the transaction scope as small as possible to reduce locking
        IF @sBeginTranCount = 0
        BEGIN
            BEGIN TRAN;
        END;

        IF @pActionType = 'I'
        BEGIN  
            WHILE @sRuningIndex <= @sRecCount    
            BEGIN
                SET @refNo = 'D' + FORMAT(NEXT VALUE FOR dbo.seqeAdditionalExpensesRefNo, '0000000');
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
                        ISNULL(wOtherReason,'') AS wOtherReason,
                        dbo.fnUTC8Now() AS wCancelDt,
                        dbo.fnUTC8Now() AS wCrtDt,
                        wUpdBy AS wCrtBy,
                        dbo.fnUTC8Now() AS wUpdDt,
                        wUpdBy AS wUpdBy,
                        wTravePkgRid,
                        wEventCodeRid,
                        wAsstBookerEmail,
                        wDeptFollwedCd,
                        wStaffFollwedRid,
                        wStaffTelephone,
                        wOwnerAuthTelephone,
                        wGiftReasonCd,
                        wBookingStatus
                    FROM #sDataSet_SetBooking2	
                    WHERE wRowNum = @sRuningIndex AND TempRowId = @TempRowId
                    FOR XML RAW ('SetBookingResult'), ROOT ('DataSet'));

                    IF @sXMLBooking IS NOT NULL
                        EXEC [spa].[SetBooking] @sXMLBooking, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;
                                    
                SET @sRuningIndex = @sRuningIndex + 1;
            END;
        END
        ELSE IF @pActionType = 'U'
        BEGIN 
            WHILE @sRuningIndex <= @sRecCount    
            BEGIN
            SET @sXMLBooking = (
                    SELECT 
                        eb.RowID,
                        eb.wBookingType,
                        eb.wRefNo,
                        eb.[GUID],
                        tmp.wReqCounterRid,
                        tmp.wDebitCounterRid,
                        tmp.wReqAgentCodeIn,
                        tmp.wDebitAgentCodeIn,
                        tmp.wReqCustomerRid,
                        tmp.wDebitCustomerRid,
                        tmp.wReqDepartment,
                        tmp.wReqUserRid,
                        tmp.wAsstBooker,
                        tmp.wAssBookerTel,
                        tmp.wApprovalAgentCodeIn,
                        tmp.wDebitDt,
                        tmp.wExpDt,
                        tmp.wCancelDebitDt,
                        tmp.wCancelReasonCd,
                        tmp.wCancelBy,
                        ISNULL(tmp.wOtherReason,'') AS wOtherReason,
                        tmp.wCancelDt,
                        eb.wCrtDt,
                        eb.wCrtBy,
                        dbo.fnUTC8Now() AS wUpdDt,
                        tmp.wUpdBy,
                        tmp.wTravePkgRid,
                        tmp.wEventCodeRid,
                        ISNULL(tmp.wAsstBookerEmail,'') AS wAsstBookerEmail,
                        ISNULL(tmp.wDeptFollwedCd,'') AS wDeptFollwedCd,
                        ISNULL(tmp.wStaffFollwedRid,-1) AS wStaffFollwedRid,
                        ISNULL(tmp.wStaffTelephone,'') AS wStaffTelephone,
                        ISNULL(tmp.wOwnerAuthTelephone,'') AS wOwnerAuthTelephone,
                        eb.wUseTravelPkg,
                        eb.wGiftReasonCd,
                        eb.wDepositAmt,
                        eb.wHasDeposit,
                        eb.wDepositDebitDt,
                        tmp.wBookingStatus
                    FROM dbo.eBooking AS eb    
                        INNER JOIN #sDataSet_SetBooking2 tmp ON eb.RowID = tmp.TempRowId
                        WHERE tmp.wRowNum = @sRuningIndex
                    FOR XML RAW ('SetBookingResult'), ROOT ('DataSet'));

                    IF @sXMLBooking IS NOT NULL
                        EXEC [spa].[SetBooking] @sXMLBooking, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;
                
            SET @sRuningIndex = @sRuningIndex + 1;
            END; 				
        END
       
    IF @sBeginTranCount = 0 AND @@trancount > 0
    BEGIN
       COMMIT;
    END;

    -- Return RowID affected
    IF @pReturnResultSet = 'Y'
        SELECT  RowID
        FROM    #sDataSet_SetBooking2;
                        
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
    
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetBooking') IS NOT NULL DROP TABLE #sDataSet_SetBooking 

        RETURN;    
END;