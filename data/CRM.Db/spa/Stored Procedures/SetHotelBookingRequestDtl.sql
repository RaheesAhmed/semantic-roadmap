CREATE PROCEDURE [spa].[SetHotelBookingRequestDtl]
    (
      @pXMLHotelBookingRequest XML ,
      @pXMLHotelBookingRequestDtl XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pHotelBookingRid BIGINT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT     
    )
AS
    BEGIN
        SET NOCOUNT ON;
		
		--SELECT * FROM eHotelRequestDtl;

        DECLARE @sThisTableName VARCHAR(50) = 'eHotelRequestDtl' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
			
	        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
	        
        SET @sBeginTranCount = @@trancount;
	    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXMLHotelBookingRequest;
	    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #DataSet_HotelBookingRequest
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
				wBedType  VARCHAR(2),
				wLockCounterRid  BIGINT,
				wStatus  VARCHAR(3),
				wRemark  NVARCHAR(500),
				wCrtDt  DATETIME2(7),
				wCrtBy  BIGINT,
				wUpdDt  DATETIME2(7),
				wUpdBy  BIGINT,
				wCounterRid BIGINT,
				wTravePkgRid BIGINT
			);

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXMLHotelBookingRequestDtl;
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #DataSet_SetHotelBookingRequestDtl
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				RowID  BIGINT,
				wHotelRequestRid BIGINT,
				wHotelCode  VARCHAR(30),
				wLine  INT,
				wCounterRid  BIGINT,
				wTotalProvideRoomQty  INT,
				wIsReject CHAR(1),
				wSeqNo  INT,
				wCrtDt  DATETIME2(7),
				wCrtBy  BIGINT,
				wUpdDt  DATETIME2(7),
				wUpdBy  BIGINT,
				wCrtByCounterRid BIGINT,
				wPriority INT,
                wHotelRid BIGINT
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
                    UPDATE  #DataSet_SetHotelBookingRequestDtl
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #DataSet_SetHotelBookingRequestDtl;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
                            UPDATE  #DataSet_SetHotelBookingRequestDtl
                            SET     RowID = @sRowID ,
                                    wHotelRequestRid = @pHotelBookingRid
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				
                    INSERT  INTO dbo.[eHotelRequestDtl]
                            ( RowID ,
                              wHotelRequestRid ,
                              wHotelCode ,
                              wLine ,
                              wCounterRid ,
                              wTotalProvideRoomQty ,
                              wIsReject ,
                              wSeqNo ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy ,
                              wCrtByCounterRid ,
                              wPriority,
                              wHotelRid
							)
                            SELECT  s.RowID ,
                                    s.wHotelRequestRid ,
                                    s.wHotelCode ,
                                    s.wLine ,
                                    s.wCounterRid ,
                                    s.wTotalProvideRoomQty ,
                                    s.wIsReject ,
                                    s.wSeqNo ,
                                    s.wCrtDt ,
                                    s.wCrtBy ,
                                    s.wUpdDt ,
                                    s.wUpdBy ,
                                    s.wCrtByCounterRid ,
                                    s.wPriority,
                                    s.wHotelRid
                            FROM    #DataSet_SetHotelBookingRequestDtl s;


                END;
            
            IF @pActionType = 'U'
                BEGIN
					
                    DECLARE @wHotelRequestRid BIGINT = ( SELECT TOP 1
                                                                wHotelRequestRid
                                                         FROM   #DataSet_SetHotelBookingRequestDtl
                                                       )
                    DELETE  FROM eHotelRequestDtl
                    WHERE   RowID NOT IN ( SELECT   RowID
                                           FROM     #DataSet_SetHotelBookingRequestDtl )
                            AND wHotelRequestRid = @wHotelRequestRid

						-- Update hotel priority

                    UPDATE  RTD
                    SET     RTD.wPriority = TMP.wPriority
                    FROM    dbo.eHotelRequestDtl RTD
                            INNER JOIN #DataSet_SetHotelBookingRequestDtl TMP ON TMP.wHotelCode = RTD.wHotelCode
                                                                                 AND RTD.wHotelRequestRid = @wHotelRequestRid
                                                                                 AND TMP.RowID > 0;

                    DELETE  FROM #DataSet_SetHotelBookingRequestDtl
                    WHERE   RowID > 0;
					
                    UPDATE  #DataSet_SetHotelBookingRequestDtl
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #DataSet_SetHotelBookingRequestDtl;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
                            UPDATE  #DataSet_SetHotelBookingRequestDtl
                            SET     RowID = @sRowID ,
                                    wHotelRequestRid = @wHotelRequestRid
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    
						
                    IF ( SELECT COUNT(RowID)
                         FROM   #DataSet_SetHotelBookingRequestDtl
                       ) > 0
                        BEGIN	        
                            INSERT  INTO dbo.[eHotelRequestDtl]
                                    ( RowID ,
                                      wHotelRequestRid ,
                                      wHotelCode ,
                                      wLine ,
                                      wCounterRid ,
                                      wTotalProvideRoomQty ,
                                      wIsReject ,
                                      wSeqNo ,
                                      wCrtDt ,
                                      wCrtBy ,
                                      wUpdDt ,
                                      wUpdBy ,
                                      wCrtByCounterRid ,
                                      wPriority,
                                      wHotelRid
								    )
                                    SELECT  s.RowID ,
                                            @wHotelRequestRid ,
                                            s.wHotelCode ,
                                            s.wLine ,
                                            s.wCounterRid ,
                                            s.wTotalProvideRoomQty ,
                                            s.wIsReject ,
                                            s.wSeqNo ,
                                            s.wCrtDt ,
                                            s.wCrtBy ,
                                            s.wUpdDt ,
                                            s.wUpdBy ,
                                            s.wCrtByCounterRid ,
                                            s.wPriority,
                                            s.wHotelRid
                                    FROM    #DataSet_SetHotelBookingRequestDtl s;
                        END		
                END;
				
            IF @pActionType = 'D'
                BEGIN

                    DECLARE @wCounterRid BIGINT = ( SELECT TOP 1
                                                            wCounterRid
                                                    FROM    #DataSet_HotelBookingRequest
                                                  )
										
                    UPDATE  met
                    SET     met.wIsReject = tmp.wIsReject ,
                            met.wUpdDt = tmp.wUpdDt ,
                            met.wUpdBy = tmp.wUpdBy
                    FROM    dbo.eHotelRequestDtl AS met
                            INNER JOIN #DataSet_SetHotelBookingRequestDtl tmp ON met.wHotelRequestRid = tmp.wHotelRequestRid
                    WHERE   met.wCounterRid = @wCounterRid AND (tmp.RowID = 0 OR met.RowID = tmp.RowID)
                END

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;	
				
			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #DataSet_SetHotelBookingRequestDtl;		  
          
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

        IF OBJECT_ID('tempdb..#DataSet_HotelBookingRequest') IS NOT NULL
            DROP TABLE #DataSet_HotelBookingRequest;
    END;