CREATE PROCEDURE [spa].[SetHotelBookingRequestAssign]
    (
      @pXML XML,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT,
	  @pNonceToken VARCHAR(64),
	  @pReturnResultSet CHAR(1) = 'N',
      @pHotelBookingRid BIGINT OUTPUT,
	  @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT   
	)
AS
    BEGIN
        SET NOCOUNT ON;
		
		---SELECT * FROM eHotelRequest

	    DECLARE @sThisTableName VARCHAR(50) = 'eHotelRequest' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
	        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
	        
        SET @sBeginTranCount = @@trancount;
	    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
        SELECT wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ),*
        INTO #DataSet_SetHotelBookingRequest
        FROM OPENXML (@sDocHandle, 'DataSet/SetHotelBookingRequestResult', 1)
		WITH (
				RowID  BIGINT,
				wRequestNo  varchar(30),
				wReqCounterRid  BIGINT,
				wDebitCounterRid  BIGINT,
				wReqAgentCodeIn  varchar(14),
				wDebitAgentCodeIn  varchar(14),
				wReqCustomerRid  bigint,
				wDebitCustomerRid  BIGINT,
				wReqDepartment  varchar(30),
				wReqUserRid  BIGINT,
				wAsstBooker  nvarchar(50),
				wAssBookerTel  varchar(100),
				wApprovalAgentCodeIn  varchar(14),
				wRegion  varchar(3),
				wNumberOfRoom  INT,
				wStartDate  DATE,
				wEndDate  DATE,
				wDayOfStay INT,
				wHotelCodeSCV  varchar(1000),
				wIsAgentHotel  char(1),
				wBedType  varchar(2),
				wLockCounterRid  BIGINT,
				wIsLock  char(1),
				wStatus  varchar(3),
				wRemark  nvarchar(500),
				wSeqNo  INT,
				wCrtDt  datetime2(7),
				wCrtBy  BIGINT,
				wUpdDt  datetime2(7),
				wUpdBy  BIGINT
			);

		 --better don't put everything within try, for example
	     --getting mSysTable value
	     --getting currency, period, mCompany ...
	    
        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
			 IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
	
            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #DataSet_SetHotelBookingRequest
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #DataSet_SetHotelBookingRequest;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #DataSet_SetHotelBookingRequest
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				SET @pHotelBookingRid = @sRowID;
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[eHotelRequest]
                            (
								RowID,
								wRequestNo,
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
								wRegion,
								wNumberOfRoom,
								wStartDate,
								wEndDate,
								wDayOfStay,
								wHotelCodeSCV,
								wIsAgentHotel,
								wBedType,
								wLockCounterRid,
								wStatus,
								wRemark,
								wCrtDt,
								wCrtBy,
								wUpdDt,
							    wUpdBy
							)
                            SELECT
	            	            s.RowID,
								s.wRequestNo,
								s.wReqCounterRid,
								s.wDebitCounterRid,
								s.wReqAgentCodeIn,
								s.wDebitAgentCodeIn,
								s.wReqCustomerRid,
								s.wDebitCustomerRid,
								s.wReqDepartment,
								s.wReqUserRid,
								s.wAsstBooker,
								s.wAssBookerTel,
								s.wApprovalAgentCodeIn,
								s.wRegion,
								s.wNumberOfRoom,
								s.wStartDate,
								s.wEndDate,
								s.wDayOfStay,
								s.wHotelCodeSCV,
								s.wIsAgentHotel,
								s.wBedType,
								s.wLockCounterRid,
								s.wStatus,
								s.wRemark,
								s.wCrtDt,
								s.wCrtBy,
								s.wUpdDt,
								s.wUpdBy
                            FROM    #DataSet_SetHotelBookingRequest s;


                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  ehr
                        SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
								ehr.wRequestNo = tmp.wRequestNo,
								ehr.wReqCounterRid = tmp.wReqCounterRid,
								ehr.wDebitCounterRid = tmp.wDebitCounterRid,
								ehr.wReqAgentCodeIn = tmp.wReqAgentCodeIn,
								ehr.wDebitAgentCodeIn = tmp.wDebitAgentCodeIn,
								ehr.wReqCustomerRid = tmp.wReqCustomerRid,
								ehr.wDebitCustomerRid = tmp.wDebitCustomerRid,
								ehr.wReqDepartment = tmp.wReqDepartment,
								ehr.wReqUserRid = tmp.wReqUserRid,
								ehr.wAsstBooker = tmp.wAsstBooker,
								ehr.wAssBookerTel = tmp.wAssBookerTel,
								ehr.wApprovalAgentCodeIn = tmp.wApprovalAgentCodeIn,
								ehr.wRegion = tmp.wRegion,
								ehr.wNumberOfRoom = tmp.wNumberOfRoom,
								ehr.wStartDate = tmp.wStartDate,
								ehr.wEndDate = tmp.wEndDate,
								ehr.wDayOfStay = tmp.wDayOfStay,
								ehr.wHotelCodeSCV = tmp.wHotelCodeSCV,
								ehr.wIsAgentHotel = tmp.wIsAgentHotel,
								ehr.wBedType = tmp.wBedType,
								ehr.wLockCounterRid = tmp.wLockCounterRid,
								ehr.wStatus = tmp.wStatus,
								ehr.wRemark = tmp.wRemark,
								ehr.wUpdDt = tmp.wUpdDt,
								ehr.wUpdBy = tmp.wUpdBy
                        FROM    dbo.eHotelRequest AS ehr
                                INNER JOIN #DataSet_SetHotelBookingRequest tmp ON ehr.RowID = tmp.RowID
                        WHERE   ehr.RowID = tmp.RowID;
                    END;
     --         IF @pActionType = 'D'
					--BEGIN

					--	 UPDATE  met
					--	   SET
					--		met.wStatus = 'T' 
					--	FROM    dbo.eHotelRequest AS met
     --                   INNER JOIN #DataSet_SetHotelBookingRequest tmp ON met.RowID = tmp.RowID
					--	 WHERE   met.RowID = tmp.RowID;
                            
     --        END;

            RETURN;

			IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #DataSet_SetHotelBookingRequest;

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

		IF OBJECT_ID('tempdb..#DataSet_SetHotelBookingRequest') IS NOT NULL DROP TABLE #DataSet_SetHotelBookingRequest;
		
END;