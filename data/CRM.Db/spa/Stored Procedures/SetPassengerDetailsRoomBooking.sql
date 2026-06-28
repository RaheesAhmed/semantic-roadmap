CREATE PROCEDURE [spa].[SetPassengerDetailsRoomBooking]
    @pXML XML ,
    @pActionType CHAR(1) , -- I/U/D                      
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pReturnResultSet CHAR(1) = 'N' ,
    @pRoomBookingRid BIGINT ,
    @pIsUpdateSinglePassenger BIT = 0 ,
    @pPassengerRid BIGINT OUTPUT ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
AS
    BEGIN    
        SET NOCOUNT ON;                      

        DECLARE @sThisTableName VARCHAR(50) = 'ePassengerDetails' ,
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRecCountDtl INT = 0;
        DECLARE @sSeqNo INT = 0 ,
            @sRowIDDtl BIGINT = 0 ,
            @sDocHandle INT ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0;
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );

        SET @sBeginTranCount = @@trancount;

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;  

        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetPassengerDetails
        FROM    OPENXML (@sDocHandle, 'DataSet/SetPassengerDetailsResult', 1)                      
	WITH (                      
    	RowID BIGINT ,                      
    	wBookingRid BIGINT,                   
    	wClientTicketNo VARCHAR(50),               
    	wDepartFlightNo VARCHAR(10),                      
    	wTakeOffDt DATETIME2(7),                      
    	wDestination NVARCHAR(200),    
    	wRequesterAcc BIGINT,                      
    	wPersonRid BIGINT,  
    	wRemark NVARCHAR(500),                      
    	wStatus VARCHAR(10),                   
    	wCrtBy BIGINT,                      
    	wCrtDt DATETIME2,                   
    	wUpdDt DATETIME2,                          
    	wUpdBy BIGINT,
		wType VARCHAR(10),
		wRoomBookingRid BIGINT,
		wCasinoCardRid BIGINT,
		wApplicationType VARCHAR(10),
		wApplicationStatus VARCHAR(10),      
		wAmount NUMERIC(18,4),
		wCost NUMERIC(18,4),
		wPassengerSeqNo INT,
		wPassengerBookingStatus VARCHAR(10),
		wCancelDebitDt DATETIME2,
        wCancelReasonCd VARCHAR(30),
        wCancelBy BIGINT,
        wCancelDt DATETIME2
	);

        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF @pActionType = 'I'
                BEGIN
                    UPDATE  #sDataSet_SetPassengerDetails
                    SET     RowID = 0;                      
                    SELECT  @sRecCount = COUNT(1)
                    FROM    #sDataSet_SetPassengerDetails;  
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN                      
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;                      
                            UPDATE  #sDataSet_SetPassengerDetails
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;                      
                        END;
                    SET @pPassengerRid = @sRowID
                    INSERT  INTO dbo.[ePassengerDetails]
                            ( [RowID] ,
                              [wBookingRid] ,
                              [wClientTicketNo] ,
                              [wDepartFlightNo] ,
                              [wTakeOffDt] ,
                              [wDestination] ,
                              [wRequesterAcc] ,
                              [wPersonRid] ,
                              [wRemark] ,
                              [wStatus] ,
                              [wCrtBy] ,
                              [wCrtDt] ,
                              [wUpdDt] ,
                              [wUpdBy] ,
                              [wType] ,
                              [wRoomBookingRid] ,
                              [wCasinoCardRid] ,
                              [wApplicationType] ,
                              [wApplicationStatus] ,
                              [wAmount] ,
                              [wSeqNo] ,
                              [wPassengerBookingStatus]
                            )
                            SELECT  s.RowID ,
                                    s.wBookingRid ,
                                    ISNULL(s.wClientTicketNo, '') ,
                                    ISNULL(s.wDepartFlightNo, '') ,
                                    s.wTakeOffDt ,
                                    ISNULL(s.wDestination, '') ,
                                    ISNULL(s.wRequesterAcc, 0) ,
                                    ISNULL(s.wPersonRid, 0) ,
                                    ISNULL(s.wRemark, '') ,
                                    ISNULL(s.wStatus, '') ,
                                    s.wCrtBy ,
                                    dbo.fnUTC8Now() ,
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy ,
                                    s.wType ,
                                    s.wRoomBookingRid ,
                                    ( CASE WHEN s.wCasinoCardRid < 1 THEN -1
                                           ELSE s.wCasinoCardRid
                                      END ) ,
                                    s.wApplicationType ,
                                    s.wApplicationStatus ,
                                    s.wAmount ,
                                    s.wPassengerSeqNo ,
                                    ISNULL(s.wPassengerBookingStatus, 'P')
                            FROM    #sDataSet_SetPassengerDetails s; 
                END;                      
            ELSE
                IF @pActionType = 'U'
                    BEGIN
		-- There are multiple scenario to handle we have added below if condition while deleting record
		-- 1 : When we edit single record from Passenger List not from Booking 1st if condition will execute
		-- 2 : Suppose we are on any of booking page 1st Save Booking and do not close the Screen and then Add single or 
		--     multiple passenger here Else If conditon will get execute

                        SELECT  RowID
                        INTO    #temp
                        FROM    ePassengerDetails
                        WHERE   wRoomBookingRid = @pRoomBookingRid
                                AND RowID NOT IN ( SELECT   RowID
                                                   FROM     #sDataSet_SetPassengerDetails
                                                   WHERE    RowID > 0 );
		
                        DELETE  ptd
                        FROM    ePassengerTravelDocDetail ptd
                        WHERE   ptd.wPassengerDetailsRid IN ( SELECT    RowID
                                                              FROM      dbo.ePassengerDetails
                                                              WHERE     wRoomBookingRid = @pRoomBookingRid );

                        DELETE  pd
                        FROM    ePassengerDetails pd
                                INNER JOIN #temp tmp ON tmp.RowID = pd.RowID;

                        DROP TABLE #temp;
		
                        UPDATE  pd
                        SET     [wClientTicketNo] = tmp.wClientTicketNo ,
                                [wRequesterAcc] = tmp.wRequesterAcc ,
                                [wPersonRid] = tmp.wPersonRid ,
                                [wRemark] = tmp.wRemark ,
                                [wUpdDt] = dbo.fnUTC8Now() ,
                                [wUpdBy] = CASE WHEN tmp.wUpdBy IS NOT NULL AND tmp.wUpdBy > 0 THEN tmp.wUpdBy ELSE pd.wUpdBy END ,
                                [wCasinoCardRid] = tmp.wCasinoCardRid ,
                                [wSeqNo] = tmp.wPassengerSeqNo ,
                                [wPassengerBookingStatus] = tmp.wPassengerBookingStatus,
								[wStatus]=tmp.wStatus
                        FROM    [dbo].[ePassengerDetails] pd
                                INNER JOIN #sDataSet_SetPassengerDetails tmp ON tmp.[RowID] = pd.RowID
                                                                                AND tmp.[RowID] > 0 


                        DECLARE @recordCnt BIGINT = 0 ,
                            @sRowIDD BIGINT = 0;
                        SET @recordCnt = ( SELECT   COUNT(RowID)
                                           FROM     #sDataSet_SetPassengerDetails
                                         );

		--DELETE ptd FROM ePassengerTravelDocDetail  ptd
		--INNER JOIN #sDataSet_SetPassengerDetails tmp ON tmp.[RowID]=ptd.wPassengerDetailsRid AND tmp.[RowID]>0 AND tmp.wStatus='T'

		--DELETE pd FROM ePassengerDetails pd 
		--INNER JOIN #sDataSet_SetPassengerDetails tmp ON tmp.[RowID]=pd.RowID AND tmp.[RowID]>0 AND tmp.wStatus='T'

		--SELECT RowID INTO #temp FROM #sDataSet_SetPassengerDetails 

		
                        DELETE  FROM #sDataSet_SetPassengerDetails
                        WHERE   [RowID] > 0;
		
                        UPDATE  #sDataSet_SetPassengerDetails
                        SET     RowID = 0;                      
                        SELECT  @sRecCount = COUNT(*)
                        FROM    #sDataSet_SetPassengerDetails;                      
                        WHILE @sRuningIndex <= @sRecCount
                            BEGIN                      
                                EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;     
                                UPDATE  #sDataSet_SetPassengerDetails
                                SET     RowID = @sRowID
                                WHERE   wRowNum = @sRuningIndex;                      
                                SET @sRuningIndex = @sRuningIndex + 1;                      
                            END;              
                        SET @pPassengerRid = @sRowID                      
                        INSERT  INTO dbo.[ePassengerDetails]
                                ( [RowID] ,
                                  [wBookingRid] ,
                                  [wClientTicketNo] ,
                                  [wDepartFlightNo] ,
                                  [wTakeOffDt] ,
                                  [wDestination] ,
                                  [wRequesterAcc] ,
                                  [wPersonRid] ,
                                  [wRemark] ,
                                  [wStatus] ,
                                  [wCrtBy] ,
                                  [wCrtDt] ,
                                  [wUpdDt] ,
                                  [wUpdBy] ,
                                  [wType] ,
                                  [wRoomBookingRid] ,
                                  [wCasinoCardRid] ,
                                  [wApplicationType] ,
                                  [wApplicationStatus] ,
                                  [wAmount] ,
                                  [wSeqNo] ,
                                  [wPassengerBookingStatus]
                                )
                                SELECT  s.RowID ,
                                        s.wBookingRid ,
                                        ISNULL(s.wClientTicketNo, '') ,
                                        ISNULL(s.wDepartFlightNo, '') ,
                                        s.wTakeOffDt ,
                                        ISNULL(s.wDestination, '') ,
                                        ISNULL(s.wRequesterAcc, 0) ,
                                        ISNULL(s.wPersonRid, 0) ,
                                        ISNULL(s.wRemark, '') ,
                                        ISNULL(s.wStatus, '') ,
                                        s.wCrtBy ,
                                        dbo.fnUTC8Now() ,
                                        dbo.fnUTC8Now() ,
                                        s.wUpdBy ,
                                        s.wType ,
                                        s.wRoomBookingRid ,
                                        ( CASE WHEN s.wCasinoCardRid < 1 THEN -1
                                               ELSE s.wCasinoCardRid
                                          END ) ,
                                        s.wApplicationType ,
                                        s.wApplicationStatus ,
                                        s.wAmount ,
                                        s.wPassengerSeqNo ,
                                        ISNULL(s.wPassengerBookingStatus, 'P')
                                FROM    #sDataSet_SetPassengerDetails s;                
                    END   
                ELSE
                    IF @pActionType = 'D'
                        BEGIN
                            UPDATE  pd
                            SET     [wPassengerBookingStatus] = tmp.wPassengerBookingStatus ,
                                    [wUpdDt] = dbo.fnUTC8Now() ,
                                    [wUpdBy] = tmp.wUpdBy ,
                                    [wCancelReasonCd] = tmp.wCancelReasonCd ,
                                    [wCancelBy] = tmp.wCancelBy ,
                                    [wCancelDt] = dbo.fnUTC8Now()
                            FROM    [dbo].[ePassengerDetails] pd
                                    INNER JOIN #sDataSet_SetPassengerDetails tmp ON tmp.[RowID] = pd.RowID
                                                                                    AND tmp.[RowID] > 0 

                        END

            ----------------------------------------------------------------------------------------------------
            -- UPDATE stg.eBookingMisc
            ----------------------------------------------------------------------------------------------------
            SELECT
            	er.wBookingRid, l.wLangCd, 
            	wItemCd = 'CUST_NAME', wValue = ISNULL(STUFF(
            			(
            				SELECT  ',' + CASE WHEN l.wLangCd = 'zh-TW' THEN p.wCName ELSE p.wEName END
            				FROM    ePassengerDetails pd
            				        INNER JOIN mPerson p ON pd.wPersonRid = p.RowID AND pd.wStatus = 'A'
                                    INNER JOIN eBookingRoom r ON pd.wRoomBookingRid >0 AND pd.wRoomBookingRid = r.RowID
            				WHERE   r.wBookingRid = er.wBookingRid
            				ORDER BY pd.wUpdDt
            				FOR XML PATH ('')
            			), 1,1,''), '')
            INTO #tmpStaging
            FROM ePassengerDetails pdOut
            CROSS JOIN (SELECT wLangCd = 'en-GB' UNION SELECT 'zh-TW') AS l
            INNER JOIN eBookingRoom er ON pdOut.wRoomBookingRid >0 AND pdOut.wRoomBookingRid = er.RowID
            WHERE pdOut.wRoomBookingRid = @pRoomBookingRid
            GROUP BY er.wBookingRid, l.wLangCd;
            
            DELETE bm
            FROM [stg].[eBookingMisc] bm
            INNER JOIN #tmpStaging tmp ON bm.wBookingRid = tmp.wBookingRid AND bm.wLangCd = tmp.wLangCd AND bm.wItemCd = tmp.wItemCd;
            
            INSERT INTO  [stg].[eBookingMisc] (wBookingRid, wLangCd, wItemCd, wValue)
            SELECT wBookingRid, wLangCd, wItemCd, wValue
            FROM #tmpStaging;
            ----------------------------------------------------------------------------------------------------
            -- END stg.eBookingMisc
            ----------------------------------------------------------------------------------------------------
	
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;   
				
	-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetPassengerDetails;				               
	                  
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

        IF OBJECT_ID('tempdb..#sDataSet_SetPassengerDetails') IS NOT NULL
            DROP TABLE #sDataSet_SetPassengerDetails;

    END;