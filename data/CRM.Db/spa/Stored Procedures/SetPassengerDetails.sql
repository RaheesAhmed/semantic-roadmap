CREATE PROCEDURE [spa].[SetPassengerDetails]
    @pXML XML ,
    @pActionType CHAR(1) , -- I/U/D                      
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pReturnResultSet CHAR(1) = 'N' ,
    @pBookingRid BIGINT ,
    @pIsUpdateSinglePassenger BIT = 0 ,
    @pPassengerRid BIGINT OUTPUT ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
AS
    BEGIN    
        SET NOCOUNT ON;                      

        -- dbml
        SELECT  RowID FROM [dbo].[ePassengerDetails]
   

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
        wCancelDt DATETIME2,
		wRouteRid BIGINT,
		wOtherReason NVARCHAR(200)
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
                              [wCost] ,
                              [wSeqNo] ,
                              [wPassengerBookingStatus] ,
                              [wRouteRid] ,
                              [wOtherReason]
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
                                    ( CASE WHEN s.wRoomBookingRid < 1 THEN -1
                                           ELSE s.wRoomBookingRid
                                      END ) ,
                                    ( CASE WHEN s.wCasinoCardRid < 1 THEN -1
                                           ELSE s.wCasinoCardRid
                                      END ) ,
                                    s.wApplicationType ,
                                    s.wApplicationStatus ,
                                    s.wAmount ,
                                    s.wCost ,
                                    s.wPassengerSeqNo ,
                                    ISNULL(s.wPassengerBookingStatus, 'P') ,
                                    s.wRouteRid ,
                                    s.wOtherReason
                            FROM    #sDataSet_SetPassengerDetails s; 
                END;                      
            ELSE
                IF @pActionType = 'U'
                    BEGIN
		-- There are multiple scenario to handle we have added below if condition while deleting record
		-- 1 : When we edit single record from Passenger List not from Booking 1st if condition will execute
		-- 2 : Suppose we are on any of booking page 1st Save Booking and do not close the Screen and then Add single or 
		--     multiple passenger here Else If conditon will get execute

                        DECLARE @recordCnt BIGINT = 0 ,
                            @sRowIDD BIGINT = 0;
                        SET @recordCnt = ( SELECT   COUNT(RowID)
                                           FROM     #sDataSet_SetPassengerDetails
                                         );

                        IF @pIsUpdateSinglePassenger = 1
                            AND @pBookingRid > 0
                            BEGIN
                                SET @sRowIDD = ( SELECT RowID
                                                 FROM   #sDataSet_SetPassengerDetails
                                               );
                                IF @sRowIDD > 0
                                    BEGIN
                                        DELETE  FROM dbo.ePassengerDetails
                                        WHERE   wBookingRid = @pBookingRid
                                                AND RowID = @sRowIDD;
                                    END
                                ELSE
                                    BEGIN
                                        DELETE  FROM dbo.ePassengerDetails
                                        WHERE   wBookingRid = @pBookingRid;  
                                    END
                            END
                        ELSE
                            IF @pBookingRid > 0
                                BEGIN
                                    DELETE  FROM dbo.ePassengerDetails
                                    WHERE   wBookingRid = @pBookingRid;         
                                END
	
                        IF @pBookingRid <= 0
                            BEGIN
                                DELETE  FROM dbo.ePassengerDetails
                                WHERE   wRoomBookingRid = ( SELECT TOP 1
                                                                    wRoomBookingRid
                                                            FROM    #sDataSet_SetPassengerDetails
                                                          )
                            END

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
                                  [wCost] ,
                                  [wSeqNo] ,
                                  [wPassengerBookingStatus] ,
                                  [wRouteRid] ,
                                  [wOtherReason]
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
                                        ( CASE WHEN s.wRoomBookingRid < 1 THEN -1
                                               ELSE s.wRoomBookingRid
                                          END ) ,
                                        ( CASE WHEN s.wCasinoCardRid < 1 THEN -1
                                               ELSE s.wCasinoCardRid
                                          END ) ,
                                        s.wApplicationType ,
                                        s.wApplicationStatus ,
                                        s.wAmount ,
                                        s.wCost ,
                                        s.wPassengerSeqNo ,
                                        ISNULL(s.wPassengerBookingStatus, 'P') ,
                                        s.wRouteRid ,
                                        s.wOtherReason
                                FROM    #sDataSet_SetPassengerDetails s;                
                    END   
						  
            IF @pActionType = 'D'
                BEGIN

                    UPDATE  PSD
                    SET     [wUpdDt] = dbo.fnUTC8Now() ,
                            [wUpdBy] = TMP.wUpdBy ,
                            [wCancelDebitDt] = ISNULL(PSD.[wCancelDebitDt], dbo.fnUTC8Now()) ,
                            [wCancelReasonCd] = TMP.wCancelReasonCd ,
                            [wCancelBy] = ( CASE WHEN ( TMP.wPassengerBookingStatus = 'CL'
                                                        OR TMP.wPassengerBookingStatus = 'RF'
                                                      )
                                                      AND PSD.wCancelBy IS NULL THEN TMP.wCancelBy
                                                 ELSE PSD.wCancelBy
                                            END ) ,
                            [wCancelDt] = ( CASE WHEN ( TMP.wPassengerBookingStatus = 'CL'
                                                        OR TMP.wPassengerBookingStatus = 'RF'
                                                      )
                                                      AND PSD.[wCancelDt] IS NULL THEN dbo.fnUTC8Now()
                                                 ELSE PSD.wCancelDt
                                            END ) ,
                            [wPassengerBookingStatus] = TMP.wPassengerBookingStatus ,
                            wStatus = 'T'
                    FROM    [dbo].[ePassengerDetails] PSD
                            INNER JOIN #sDataSet_SetPassengerDetails TMP ON TMP.RowID = PSD.RowID;
                END;

            DECLARE @sAmount NUMERIC(18, 4) ,
                @sPrice NUMERIC(18, 4) ,
                @sBookingType VARCHAR(30)= '';

            SELECT TOP 1
                    @sBookingType = wType
            FROM    #sDataSet_SetPassengerDetails;

            IF @sBookingType = 'VISA'
                BEGIN
                    SELECT  @sAmount = SUM(ISNULL(wAmount, 0)) ,
                            @sPrice = SUM(ISNULL(wCost, 0))
                    FROM    dbo.ePassengerDetails
                    WHERE   wBookingRid = ( SELECT TOP 1
                                                    wBookingRid
                                            FROM    #sDataSet_SetPassengerDetails
                                          )
                            AND wStatus = 'A'
                            AND ( wPassengerBookingStatus = 'P'
                                  OR wPassengerBookingStatus = 'C'
                                );

                    DECLARE @sRefundCount INT= 0 ,
                        @sTotalPasssengerCount INT= 0 ,
                        @sBookingStatus VARCHAR(3)= '';

                    SELECT  @sRefundCount = COUNT(1)
                    FROM    dbo.[ePassengerDetails]
                    WHERE   wBookingRid = ( SELECT TOP 1
                                                    wBookingRid
                                            FROM    #sDataSet_SetPassengerDetails
                                          )
                            AND wPassengerBookingStatus = 'RF'
                            AND wStatus = 'A';
		
                    SELECT  @sTotalPasssengerCount = COUNT(1)
                    FROM    dbo.[ePassengerDetails]
                    WHERE   wBookingRid = ( SELECT TOP 1
                                                    wBookingRid
                                            FROM    #sDataSet_SetPassengerDetails
                                          )
                            AND wStatus = 'A';
		
                    SET @sRefundCount = ISNULL(@sRefundCount, 0);
                    SET @sTotalPasssengerCount = ISNULL(@sTotalPasssengerCount, 0);

                    IF @sRefundCount = @sTotalPasssengerCount
                        AND @sTotalPasssengerCount > 0
                        SET @sBookingStatus = 'RF';

		---Update amount and cost in Booking
                    UPDATE  VIS
                    SET     VIS.wTotalAmt = ISNULL(@sAmount, 0) ,
                            VIS.wCost = ISNULL(@sPrice, 0) ,
                            VIS.wUpdDt = dbo.fnUTC8Now() ,
                            VIS.wUpdBy = TMP.wUpdBy ,
                            VIS.wQuantity = CASE WHEN @pActionType = 'D' THEN ( VIS.wQuantity - 1 )
                                                 ELSE VIS.wQuantity
                                            END ,
                            VIS.wBookingStatus = CASE WHEN @sBookingStatus = 'RF' THEN 'RF'
                                                      ELSE VIS.wBookingStatus
                                                 END
                    FROM    dbo.[eBookingVisa] AS VIS
                            INNER JOIN #sDataSet_SetPassengerDetails TMP ON VIS.wBookingRid = TMP.wBookingRid;
			
                END
            ELSE
                IF @sBookingType = 'HELI'
                    BEGIN
                        SELECT  @sRefundCount = COUNT(1)
                        FROM    dbo.[ePassengerDetails]
                        WHERE   wBookingRid = ( SELECT TOP 1
                                                        wBookingRid
                                                FROM    #sDataSet_SetPassengerDetails
                                              )
                                AND wPassengerBookingStatus = 'RF'
                                AND wStatus = 'A';
		
                        SELECT  @sTotalPasssengerCount = COUNT(1)
                        FROM    dbo.[ePassengerDetails]
                        WHERE   wBookingRid = ( SELECT TOP 1
                                                        wBookingRid
                                                FROM    #sDataSet_SetPassengerDetails
                                              )
                                AND wStatus = 'A';
		
                        SET @sRefundCount = ISNULL(@sRefundCount, 0);
                        SET @sTotalPasssengerCount = ISNULL(@sTotalPasssengerCount, 0);

                        IF @sRefundCount = @sTotalPasssengerCount
                            AND @sTotalPasssengerCount > 0
                            SET @sBookingStatus = 'RF';

		---Update status
                        IF @sBookingStatus = 'RF'
                            BEGIN
                                UPDATE  HEL
                                SET     HEL.wUpdDt = dbo.fnUTC8Now() ,
                                        HEL.wUpdBy = TMP.wUpdBy ,
                                        HEL.wStatus = 'RF'
                                FROM    dbo.eBookingHeli AS HEL
                                        INNER JOIN #sDataSet_SetPassengerDetails TMP ON HEL.wBookingRid = TMP.wBookingRid;
                            END		
                    END
	--ELSE IF @sBookingType='PP'
	--BEGIN
	--	SELECT @sRefundCount=COUNT(1) FROM dbo.[ePassengerDetails] 
	--	WHERE wBookingRid =(SELECT TOP 1 wBookingRid FROM #sDataSet_SetPassengerDetails) AND wPassengerBookingStatus='RF' AND wStatus='A';
		
	--	SELECT @sTotalPasssengerCount=COUNT(1) FROM dbo.[ePassengerDetails] 
	--	WHERE wBookingRid =(SELECT TOP 1 wBookingRid FROM #sDataSet_SetPassengerDetails) AND wStatus='A';
		
	--	SET @sRefundCount=ISNULL(@sRefundCount,0);
	--	SET @sTotalPasssengerCount=ISNULL(@sTotalPasssengerCount,0);

	--	IF @sRefundCount=@sTotalPasssengerCount AND @sTotalPasssengerCount>0 SET @sBookingStatus='RF';

	--	---Update status
	--	IF @sBookingStatus = 'RF'
	--	BEGIN
	--		UPDATE PP
	--		SET 				
	--			PP.wUpdDt = dbo.fnUTC8Now(),
	--			PP.wUpdBy = TMP.wUpdBy,
	--			PP.wStatus ='RF'
	--		FROM dbo.eBookingPrivatePlane AS PP
	--		INNER JOIN #sDataSet_SetPassengerDetails TMP ON PP.wBookingRid = TMP.wBookingRid;
	--	END		
	--END
                ELSE
                    IF @sBookingType = 'CS'
                        BEGIN
                            SELECT  @sRefundCount = COUNT(1)
                            FROM    dbo.[ePassengerDetails]
                            WHERE   wBookingRid = ( SELECT TOP 1
                                                            wBookingRid
                                                    FROM    #sDataSet_SetPassengerDetails
                                                  )
                                    AND wPassengerBookingStatus = 'RF'
                                    AND wStatus = 'A';
		
                            SELECT  @sTotalPasssengerCount = COUNT(1)
                            FROM    dbo.[ePassengerDetails]
                            WHERE   wBookingRid = ( SELECT TOP 1
                                                            wBookingRid
                                                    FROM    #sDataSet_SetPassengerDetails
                                                  )
                                    AND wStatus = 'A';
		
                            SET @sRefundCount = ISNULL(@sRefundCount, 0);
                            SET @sTotalPasssengerCount = ISNULL(@sTotalPasssengerCount, 0);

                            IF @sRefundCount = @sTotalPasssengerCount
                                AND @sTotalPasssengerCount > 0
                                SET @sBookingStatus = 'RF';

		---Update status
                            IF @sBookingStatus = 'RF'
                                BEGIN
                                    UPDATE  CHK
                                    SET     CHK.wUpdDt = dbo.fnUTC8Now() ,
                                            CHK.wUpdBy = TMP.wUpdBy ,
                                            CHK.wBookingStatus = 'RF'
                                    FROM    dbo.eBookingCheckInService AS CHK
                                            INNER JOIN #sDataSet_SetPassengerDetails TMP ON CHK.wBookingRid = TMP.wBookingRid;
                                END		
                        END		

			----------------------------------------------------------------------------------------------------
			-- UPDATE stg.eBookingMisc
			----------------------------------------------------------------------------------------------------
			SELECT
				pdOut.wBookingRid, l.wLangCd, 
				wItemCd = 'CUST_NAME', wValue = ISNULL(STUFF(
						(
							SELECT 
								',' + CASE WHEN l.wLangCd = 'zh-TW' THEN p.wCName ELSE p.wEName END
							FROM ePassengerDetails pd
							     INNER JOIN mPerson p ON pd.wPersonRid = p.RowID AND pd.wStatus = 'A'
							WHERE pd.wBookingRid = pdOut.wBookingRid
							ORDER BY pd.wUpdDt
							FOR XML PATH ('')
						), 1,1,''), '')
			INTO #tmpStaging
			FROM ePassengerDetails pdOut
			CROSS JOIN (SELECT wLangCd = 'en-GB' UNION SELECT 'zh-TW') AS l
			INNER JOIN #sDataSet_SetPassengerDetails tmp ON pdOut.RowID = tmp.RowID
			GROUP BY pdOut.wBookingRid, l.wLangCd;

			DELETE bm
			FROM [stg].[eBookingMisc] bm
			INNER JOIN #tmpStaging tmp ON bm.wBookingRid = tmp.wBookingRid AND bm.wLangCd = tmp.wLangCd AND bm.wItemCd = tmp.wItemCd;

			INSERT INTO [stg].[eBookingMisc] (wBookingRid, wLangCd, wItemCd, wValue)
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

        IF OBJECT_ID('tempdb..#tmpStaging') IS NOT NULL
            DROP TABLE #tmpStaging;

    END;