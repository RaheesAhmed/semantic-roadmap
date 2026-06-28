CREATE PROCEDURE [spa].[SetHotelBookingRequest]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pHotelBookingRid BIGINT OUTPUT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT   
	)
AS
    BEGIN
        SET NOCOUNT ON;
		
 		-- SELECT top 1 * FROM eHotelRequest;

        DECLARE @sThisTableName VARCHAR(50) = 'eHotelRequest' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sRequestNo VARCHAR(30) ,
            @sDocHandle INT;
			
	        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
	        
        SET @sBeginTranCount = @@trancount;    
	    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #DataSet_SetHotelBookingRequest
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				RowID  BIGINT,
				wRequestNo  VARCHAR(30),
				wReqCounterRid  BIGINT,
				wDebitCounterRid  BIGINT,
				wReqAgentCodeIn  VARCHAR(14),
				wDebitAgentCodeIn  VARCHAR(14),
				wReqCustomerRid  BIGINT,
				wDebitCustomerRid  BIGINT,
				wReqDepartment  VARCHAR(30),
				wReqUserRid  BIGINT,
				wAsstBooker  NVARCHAR(50),
				wAssBookerTel  VARCHAR(100),
				wApprovalAgentCodeIn  VARCHAR(14),
				wRegion  VARCHAR(3),
				wNumberOfRoom  INT,
				wStartDate  DATE,
				wEndDate  DATE,
				wDayOfStay INT,
				wHotelCodeSCV  VARCHAR(1000),
				wIsAgentHotel  CHAR(1),
				wIsSelectRoom CHAR(1),
				wBedType  VARCHAR(2),
				wLockCounterRid  BIGINT,
				wStatus  VARCHAR(3),
				wRemark  NVARCHAR(500),
				wCrtDt  DATETIME2(7),
				wCrtBy  BIGINT,
				wUpdDt  DATETIME2(7),
				wUpdBy  BIGINT,
				wCounterRid BIGINT,
				wTravePkgRid BIGINT,
				wEventCodeRid BIGINT,
				wAsstBookerEmail NVARCHAR(50),
				wDeptFollwedCd VARCHAR(20),
				wStaffFollwedRid BIGINT,
				wStaffTelephone VARCHAR(100),
				wOwnerAuthTelephone VARCHAR(100),
                wCoordinator  NVARCHAR(50),
                wIsUser  CHAR(1),
                wUser  NVARCHAR(50),
                wHotelRidSVC  VARCHAR(2000)
			);

			--- Hotel Request Field Validation Start
        DECLARE @errorMsg VARCHAR(MAX);	
        IF @pActionType IN ( 'I', 'U' )
            BEGIN
                SELECT  @errorMsg = CASE WHEN RTRIM(ISNULL(tmp.wRegion, '')) = '' THEN 'Region is Missing' 
										--WHEN RTRIM(ISNULL(tmp.wDebitAgentCodeIn,'')) = '' THEN 'Debit Agent is Missing' 
                                         WHEN tmp.wReqCounterRid <= 0 THEN 'Requested Counter is Missing'
                                         WHEN RTRIM(ISNULL(tmp.wReqAgentCodeIn, '')) = '' THEN 'Account Requested is Missing' 
										--WHEN tmp.wStartDate < GETDATE()  THEN 'Check In Date is Missing'
										--WHEN tmp.wEndDate < GETDATE()  THEN 'Check Out Date is Missing'
                                         WHEN tmp.wStartDate > tmp.wEndDate THEN 'Check-Out Date should not be less than Check-In date'
                                         WHEN tmp.wStartDate = tmp.wEndDate THEN 'Check-In and Check-Out Date should not be same'
										--WHEN RTRIM(ISNULL(tmp.wHotelCodeSCV,'')) = '' THEN 'Hotel Request is Missing' 
                                         WHEN tmp.wNumberOfRoom <= 0 THEN 'Requested Quantity is Missing'
										--WHEN tmp.wDayOfStay<>DATEDIFF(tmp.wStartDate,tmp.wEndDate) THEN 'Date of Stay is wrong'	
                                    END
                FROM    #DataSet_SetHotelBookingRequest tmp
            END
        IF @errorMsg <> ''
            THROW 50001, @errorMsg, 1;
        IF @pActionType = 'U'
            BEGIN
                SELECT  @errorMsg = CASE WHEN hr.wReqAgentCodeIn <> tmp.wReqAgentCodeIn
                                              AND hr.wStatus <> 'P' THEN 'Can not be Account Requested when booking status is ' + lup.wTitle
                                         WHEN hr.wRegion <> tmp.wRegion
                                              AND hr.wStatus <> 'P' THEN 'Can not be updated Region when booking status is ' + lup.wTitle
                                         WHEN hr.wNumberOfRoom <> tmp.wNumberOfRoom
                                              AND hr.wStatus <> 'P' THEN 'Can not be updated Quantity when booking status is ' + lup.wTitle
                                         WHEN hr.wStartDate <> tmp.wStartDate
                                              AND hr.wStatus <> 'P' THEN 'Can not be updated Check In Date when booking status is ' + lup.wTitle
                                         WHEN hr.wEndDate <> tmp.wEndDate
                                              AND hr.wStatus <> 'P' THEN 'Can not be updated Check Out Date when booking status is ' + lup.wTitle
                                         WHEN hr.wHotelCodeSCV <> tmp.wHotelCodeSCV
                                              AND hr.wStatus <> 'P' THEN 'Can not be updated Hotel Request Date when booking status is ' + lup.wTitle
                                    END
                FROM    eHotelRequest hr
                        INNER JOIN #DataSet_SetHotelBookingRequest tmp ON hr.RowID = tmp.RowID
                        INNER JOIN mLookUp lup ON lup.wCode = hr.wStatus
                                                  AND lup.wType = 'HOTEL_BOOKING_STATUS'
                                                  AND lup.wLangCd = 'en-GB'			
            END

        BEGIN TRY
		     -- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
	
            IF @pActionType = 'I'
                BEGIN
					
                    IF NOT EXISTS ( SELECT  1
                                    FROM    sys.objects
                                    WHERE   object_id = OBJECT_ID('seqeHotelRequestNo')
                                            AND type = 'SO' )
                        BEGIN
                            CREATE SEQUENCE seqeHotelRequestNo START WITH 10000 INCREMENT BY 1 MINVALUE 10000 MAXVALUE 99999999999999
                        END

					-- Set RowID by Sequence
                    UPDATE  #DataSet_SetHotelBookingRequest
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #DataSet_SetHotelBookingRequest;
                
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
                            UPDATE  #DataSet_SetHotelBookingRequest
                            SET     RowID = @sRowID ,
                                    wRequestNo = 'R' + FORMAT(NEXT VALUE FOR dbo.seqeHotelRequestNo, '0000000')
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
                    SET @pHotelBookingRid = @sRowID;
										

				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[eHotelRequest]
                            ( RowID ,
                              wRequestNo ,
                              wReqCounterRid ,
                              wDebitCounterRid ,
                              wReqAgentCodeIn ,
                              wDebitAgentCodeIn ,
                              wReqCustomerRid ,
                              wDebitCustomerRid ,
                              wReqDepartment ,
                              wReqUserRid ,
                              wAsstBooker ,
                              wAssBookerTel ,
                              wApprovalAgentCodeIn ,
                              wRegion ,
                              wNumberOfRoom ,
                              wStartDate ,
                              wEndDate ,
                              wDayOfStay ,
                              wHotelCodeSCV ,
                              wIsAgentHotel ,
							  wIsSelectRoom,
                              wBedType ,
                              wLockCounterRid ,
                              wStatus ,
                              wRemark ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy ,
                              wCounterRid ,
                              wTravePkgRid ,
                              wEventCodeRid ,
                              wAsstBookerEmail ,
                              wDeptFollwedCd ,
                              wStaffFollwedRid ,
                              wStaffTelephone ,
                              wOwnerAuthTelephone,
                              wCoordinator,
                              wIsUser,
                              wUser,
                              wHotelRidSVC
							)
                            SELECT  s.RowID ,
                                    s.wRequestNo ,
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
                                    s.wRegion ,
                                    s.wNumberOfRoom ,
                                    s.wStartDate ,
                                    s.wEndDate ,
                                    s.wDayOfStay ,
                                    s.wHotelCodeSCV ,
                                    s.wIsAgentHotel ,
									s.wIsSelectRoom,
                                    s.wBedType ,
                                    s.wLockCounterRid ,
                                    s.wStatus ,
                                    s.wRemark ,
                                    dbo.fnUTC8Now() ,
                                    s.wCrtBy ,
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy ,
                                    s.wCounterRid ,
                                    s.wTravePkgRid ,
                                    s.wEventCodeRid ,
                                    ISNULL(s.wAsstBookerEmail, '') ,
                                    ISNULL(s.wDeptFollwedCd, '') ,
                                    ISNULL(s.wStaffFollwedRid, -1) ,
                                    ISNULL(s.wStaffTelephone, '') ,
                                    ISNULL(s.wOwnerAuthTelephone, ''),
                                    ISNULL(s.wCoordinator, '') ,
                                    s.wIsUser ,
                                    ISNULL(s.wUser, '') ,
                                    s.wHotelRidSVC
                            FROM    #DataSet_SetHotelBookingRequest s;
                
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        DECLARE @temp INT 
                        SET @temp = ( SELECT    COUNT(*)
                                      FROM      dbo.eHotelRequest AS ehr
                                                INNER JOIN #DataSet_SetHotelBookingRequest tmp ON ehr.RowID = tmp.RowID
                                      WHERE     ehr.RowID = tmp.RowID
                                    )
                       
                        UPDATE  ehr
                        SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
                                ehr.wReqCounterRid = tmp.wReqCounterRid ,
                                ehr.wDebitCounterRid = tmp.wDebitCounterRid ,
                                ehr.wReqAgentCodeIn = tmp.wReqAgentCodeIn ,
                                ehr.wDebitAgentCodeIn = tmp.wDebitAgentCodeIn ,
                                ehr.wReqCustomerRid = tmp.wReqCustomerRid ,
                                ehr.wDebitCustomerRid = tmp.wDebitCustomerRid ,
                                ehr.wReqDepartment = tmp.wReqDepartment ,
                                ehr.wReqUserRid = tmp.wReqUserRid ,
                                ehr.wAsstBooker = tmp.wAsstBooker ,
                                ehr.wAssBookerTel = tmp.wAssBookerTel ,
                                ehr.wApprovalAgentCodeIn = tmp.wApprovalAgentCodeIn ,
                                ehr.wRegion = tmp.wRegion ,
                                ehr.wNumberOfRoom = tmp.wNumberOfRoom ,
                                ehr.wStartDate = tmp.wStartDate ,
                                ehr.wEndDate = tmp.wEndDate ,
                                ehr.wDayOfStay = tmp.wDayOfStay ,
                                ehr.wHotelCodeSCV = tmp.wHotelCodeSCV ,
                                ehr.wIsAgentHotel = tmp.wIsAgentHotel ,
								ehr.wIsSelectRoom = tmp.wIsSelectRoom,
                                ehr.wBedType = tmp.wBedType ,
                                ehr.wLockCounterRid = tmp.wLockCounterRid ,
                                ehr.wStatus = tmp.wStatus ,
                                ehr.wRemark = tmp.wRemark ,
                                ehr.wUpdDt = dbo.fnUTC8Now() ,
                                ehr.wUpdBy = tmp.wUpdBy ,
                                ehr.wCounterRid = tmp.wCounterRid ,
                                ehr.wEventCodeRid = tmp.wEventCodeRid ,
                                ehr.wAsstBookerEmail = ISNULL(tmp.wAsstBookerEmail, '') ,
                                ehr.wDeptFollwedCd = ISNULL(tmp.wDeptFollwedCd, '') ,
                                ehr.wStaffFollwedRid = ISNULL(tmp.wStaffFollwedRid, -1) ,
                                ehr.wStaffTelephone = ISNULL(tmp.wStaffTelephone, '') ,
                                ehr.wOwnerAuthTelephone = ISNULL(tmp.wOwnerAuthTelephone, ''),
                                ehr.wCoordinator = ISNULL(tmp.wCoordinator, '') ,
                                ehr.wIsUser = tmp.wIsUser ,
                                ehr.wUser = ISNULL(tmp.wUser, '') ,
                                ehr.wHotelRidSVC = tmp.wHotelRidSVC
                        FROM    dbo.eHotelRequest AS ehr
                                INNER JOIN #DataSet_SetHotelBookingRequest tmp ON ehr.RowID = tmp.RowID
                        WHERE   ehr.RowID = tmp.RowID;
                    END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

		-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetContactTran;
            
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
                END
            ELSE
                THROW;

        END CATCH;
	
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#DataSet_SetHotelBookingRequest') IS NOT NULL
            DROP TABLE #DataSet_SetHotelBookingRequest;
		
    END;