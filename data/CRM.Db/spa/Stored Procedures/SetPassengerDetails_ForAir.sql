CREATE PROCEDURE [spa].[SetPassengerDetails_ForAir]
    @pXML XML ,
    @pActionType CHAR(1) , -- I/U/D                      
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pReturnResultSet CHAR(1) = 'N' ,
    @pBookingRid BIGINT ,
    @pBookingType VARCHAR(30) = '' ,
    @pPassengerRid BIGINT OUTPUT ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
AS
    BEGIN    
        SET NOCOUNT ON;                      

        DECLARE @sThisTableName VARCHAR(50) = 'ePassengerDetails' ,
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRecCountDtl INT = 0 ,
            @sSeqNo INT = 0 ,
            @sRowIDDtl BIGINT = 0 ,
            @sDocHandle INT ,
            @sRuningIndex INT = 1 ,
            @vNow DATETIME2 = dbo.fnUTC8Now() ,
            @vMthEndYearMth VARCHAR(6) ,
            @vDateUsingCRM DATETIME2 ,
            @sRowID BIGINT = 0 ,
            @sXMLeGift NVARCHAR(MAX) = '',
			@sXMLeBookingAirTicket NVARCHAR(MAX) = '',
            @sCageCodeIn VARCHAR(14);

        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
        DECLARE @sAmount NUMERIC(18, 4) = 0 ,
            @sCost NUMERIC(18, 4) = 0 ,
            @sUpdatedBy BIGINT = 0;

        DECLARE @vXMLInsertExp NVARCHAR(MAX) = '' ,
            @vXMLRefundExp NVARCHAR(MAX) = '' ,
            @vErrCode INT = 0 ,
            @vErrMsg NVARCHAR(MAX);	

        SET @sBeginTranCount = @@trancount;

        
        SET @sCageCodeIn = ( SELECT TOP 1
                                    c.wCageCodeIn
                             FROM   dbo.eBooking b
                                    INNER JOIN dbo.mServiceCounter sc ON sc.RowID = b.wDebitCounterRid
                                    INNER JOIN RollsMary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                                        AND c.wCageCode = '001'
                                                                        AND c.wStatus = 'A'
                             WHERE  b.RowID = @pBookingRid
                           );

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;  

        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetPassengerDetails
        FROM    OPENXML (@sDocHandle, 'DataSet/SetPassengerDetailsResult', 1)                      
    WITH (                      
        RowID BIGINT ,                      
        wBookingRid BIGINT,              
        wClientTicketNo VARCHAR(50),           
        wDepartFlightNo VARCHAR(20),                      
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
        wType VARCHAR(30),
        wRoomBookingRid BIGINT,
        wCasinoCardRid BIGINT,
        wApplicationType VARCHAR(10),
        wApplicationStatus VARCHAR(10),      
        wAmount NUMERIC(18,4),
        wCost NUMERIC(18,4),
        wPassengerSeqNo INT,
        wCancelDebitDt DATETIME2,
        wCancelReasonCd VARCHAR(30),
        wOtherReason NVARCHAR(200),
        wCancelBy BIGINT,
        wCancelDt DATETIME2,
        wPassengerBookingStatus VARCHAR(10),
        wChangeOrderCount INT,
        wIsWaiting CHAR(1)
    );

        BEGIN TRY

            ALTER TABLE #sDataSet_SetPassengerDetails ADD 
            wPeriodCodeIn	VARCHAR(50) NOT NULL DEFAULT '',
            wYearMth		VARCHAR(6),
            wDate			DATE,
            wShift			CHAR(1),
            wCurStatus		CHAR(1) DEFAULT 'A',
            wOriPassengerBookingStatus VARCHAR(10) DEFAULT 'X';	

            UPDATE  temp
            SET     wOriPassengerBookingStatus = pd.wPassengerBookingStatus
            FROM    #sDataSet_SetPassengerDetails temp
                    INNER JOIN dbo.ePassengerDetails pd ON pd.RowID = temp.RowID
                                                           AND temp.RowID > 0;

            UPDATE  temp
            SET     temp.wCancelDebitDt = FORMAT(temp.wCancelDebitDt, 'yyyy-MM-dd') + ' 12:00:00'
            FROM    #sDataSet_SetPassengerDetails temp
            WHERE	temp.wCancelDebitDt IS NOT NULL;
            
            -- 更新狀態為P的客戶
            IF EXISTS (SELECT 1 FROM dbo.eBookingAirTicket WHERE wStatus = 'A' AND wBookingRid = @pBookingRid AND wBookingStatus = 'C')
            AND EXISTS (SELECT 1 FROM #sDataSet_SetPassengerDetails WHERE wStatus = 'A' AND wBookingRid = @pBookingRid AND wPassengerBookingStatus = 'P')
            BEGIN
                -- 更新緩存中客戶的狀態
                UPDATE tmp
                SET tmp.wPassengerBookingStatus = 'C'
                FROM #sDataSet_SetPassengerDetails AS tmp
                WHERE wStatus = 'A'
            END

    -- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;			
    
            DECLARE @sTicketNo VARCHAR(40)= '';

            IF @pActionType = 'I'
                BEGIN 
    
                    SELECT TOP 1
                            @sTicketNo = wClientTicketNo
                    FROM    dbo.ePassengerDetails
                    WHERE   wType = 'AIRTICKET'
                            AND wClientTicketNo != ''
                            AND wClientTicketNo IN ( SELECT wClientTicketNo
                                                     FROM   #sDataSet_SetPassengerDetails );

        --IF @sTicketNo IS NOT NULL AND  @sTicketNo!=''
        --BEGIN
        --	SET @sTicketNo= @sTicketNo + ' - Client ticket no already exist.';
        --	THROW 50001, @sTicketNo, 1;
        --END
                
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
                    SET @pPassengerRid = @sRowID;
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
                              [wCancelDebitDt] ,
                              [wCancelReasonCd] ,
                              [wOtherReason] ,
                              [wCancelBy] ,
                              [wCancelDt] ,
                              [wPassengerBookingStatus] ,
                              [wChangeOrderCount] ,
                              [wIsWaiting]
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
                                    s.[wCancelDebitDt] ,
                                    s.[wCancelReasonCd] ,
                                    s.wOtherReason ,
                                    s.[wCancelBy] ,
                                    s.[wCancelDt] ,
                                    s.wPassengerBookingStatus ,
                                    s.wChangeOrderCount ,
                                    s.wIsWaiting
                            FROM    #sDataSet_SetPassengerDetails s; 
                END;                
    
            IF @pActionType = 'U'
                BEGIN 			
                    SELECT TOP 1
                            @sTicketNo = wClientTicketNo
                    FROM    dbo.ePassengerDetails
                    WHERE   wType = 'AIRTICKET'
                            AND wClientTicketNo != ''
                            AND wClientTicketNo IN ( SELECT wClientTicketNo
                                                     FROM   #sDataSet_SetPassengerDetails )
                    GROUP BY wClientTicketNo
                    HAVING  COUNT(1) > 1;
            
            --IF @sTicketNo IS NOT NULL AND  @sTicketNo!=''
            --BEGIN
            --	SET @sTicketNo= @sTicketNo + ' - Client ticket no already exist.';
            --	THROW 50001, @sTicketNo, 1;
            --END

                    SELECT TOP 1
                            @sUpdatedBy = wUpdBy
                    FROM    #sDataSet_SetPassengerDetails;

                    UPDATE  PSD
                    SET     
                            [wRoomBookingRid] = TMP.wRoomBookingRid ,
                            [wCasinoCardRid] = TMP.wCasinoCardRid ,
                            [wClientTicketNo] = ISNULL(TMP.wClientTicketNo, '') ,
                            [wDepartFlightNo] = ISNULL(TMP.wDepartFlightNo, '') ,
                            [wTakeOffDt] = TMP.wTakeOffDt ,
                            [wDestination] = ISNULL(TMP.wDestination, '') ,
                            [wRequesterAcc] = ISNULL(TMP.wRequesterAcc, 0) ,
                            [wPersonRid] = ISNULL(TMP.wPersonRid, 0) ,
                            [wRemark] = TMP.wRemark ,
                            [wStatus] = TMP.wStatus ,
                            [wUpdDt] = dbo.fnUTC8Now() ,
                            [wUpdBy] = TMP.wUpdBy ,
                            [wType] = TMP.wType ,
                            [wApplicationType] = TMP.wApplicationType ,
                            [wApplicationStatus] = TMP.wApplicationStatus ,
                            [wAmount] = TMP.wAmount ,
                            [wCost] = TMP.wCost ,
                            [wSeqNo] = TMP.wPassengerSeqNo ,
                            [wCancelDebitDt] = TMP.wCancelDebitDt ,
                            [wCancelReasonCd] = TMP.wCancelReasonCd ,
                            [wOtherReason] = TMP.wOtherReason ,
                            [wCancelBy] = ( CASE WHEN ( TMP.wPassengerBookingStatus = 'CL'
                                                        OR TMP.wPassengerBookingStatus = 'RF'
                                                      )
                                                      AND PSD.wCancelBy IS NULL THEN TMP.wCancelBy
                                                 ELSE PSD.wCancelBy
                                            END ) ,
                            [wCancelDt] = ( CASE WHEN ( TMP.wPassengerBookingStatus = 'CL'
                                                        OR TMP.wPassengerBookingStatus = 'RF'
                                                      )
                                                      AND PSD.[wCancelDt] IS NULL THEN ISNULL(TMP.wCancelDt, dbo.fnUTC8Now())
                                                 ELSE PSD.wCancelDt
                                            END ) ,
                            [wPassengerBookingStatus] = TMP.wPassengerBookingStatus ,
                            [wChangeOrderCount] = TMP.wChangeOrderCount ,
                            [wIsWaiting] = TMP.wIsWaiting
                    FROM    [dbo].[ePassengerDetails] PSD
                            INNER JOIN #sDataSet_SetPassengerDetails TMP ON TMP.[RowID] = PSD.RowID
                                                                            AND TMP.[RowID] > 0;

                    IF @pBookingType <> 'PASSENGER'
                        BEGIN

                            SELECT  RowID
                            INTO    #temp
                            FROM    ePassengerDetails
                            WHERE   wBookingRid = @pBookingRid
                                    AND RowID NOT IN ( SELECT   RowID
                                                       FROM     #sDataSet_SetPassengerDetails );

                            DELETE  pd
                            FROM    ePassengerDetails pd
                                    INNER JOIN #temp tmp ON tmp.RowID = pd.RowID;

                            DELETE  ptd
                            FROM    ePassengerTravelDocDetail ptd
                                    INNER JOIN #temp tmp ON tmp.RowID = ptd.wPassengerDetailsRid;

                            DROP TABLE #temp;

                            DELETE  FROM dbo.ePassengerTravelDocDetail
                            WHERE   wPassengerDetailsRid IN ( SELECT    RowID
                                                              FROM      dbo.ePassengerDetails
                                                              WHERE     wBookingRid = @pBookingRid
                                                                        AND wStatus = 'A'
                                                                        AND wType = 'AIRTICKET' );
                        END;

            --DELETE FROM #sDataSet_SetPassengerDetails WHERE [RowID]>0;
                    UPDATE  temp
                    SET     wCurStatus = 'A'
                    FROM    #sDataSet_SetPassengerDetails temp;  

                    UPDATE  temp
                    SET     wCurStatus = 'T'
                    FROM    #sDataSet_SetPassengerDetails temp
                    WHERE   [RowID] > 0;

                    SELECT  *
                    INTO    #sDataSet_SetPassengerDetailsSecond
                    FROM    ( SELECT    wRowNum1 = ROW_NUMBER() OVER ( ORDER BY wPassengerSeqNo ) ,
                                        *
                              FROM      #sDataSet_SetPassengerDetails
                              WHERE     wCurStatus = 'A'
                            ) x;
            
                    UPDATE  #sDataSet_SetPassengerDetailsSecond
                    SET     RowID = 0;

                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetPassengerDetailsSecond;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
                            UPDATE  #sDataSet_SetPassengerDetailsSecond
                            SET     RowID = @sRowID
                            WHERE   wRowNum1 = @sRuningIndex; 
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;

                    INSERT  INTO #sDataSet_SetPassengerDetails
                            ( RowID ,
                              wBookingRid ,
                              wClientTicketNo ,
                              wDepartFlightNo ,
                              wTakeOffDt ,
                              wDestination ,
                              wRequesterAcc ,
                              wPersonRid ,
                              wRemark ,
                              wStatus ,
                              wCrtBy ,
                              wCrtDt ,
                              wUpdDt ,
                              wUpdBy ,
                              wType ,
                              wRoomBookingRid ,
                              wCasinoCardRid ,
                              wApplicationType ,
                              wApplicationStatus ,
                              wAmount ,
                              wCost ,
                              wPassengerSeqNo ,
                              wCancelDebitDt ,
                              wCancelReasonCd ,
                              wOtherReason ,
                              wCancelBy ,
                              wCancelDt ,
                              wPassengerBookingStatus ,
                              wChangeOrderCount ,
                              wIsWaiting 
                            )
                            SELECT  RowID ,
                                    wBookingRid ,
                                    wClientTicketNo ,
                                    wDepartFlightNo ,
                                    wTakeOffDt ,
                                    wDestination ,
                                    wRequesterAcc ,
                                    wPersonRid ,
                                    wRemark ,
                                    wStatus ,
                                    wCrtBy ,
                                    wCrtDt ,
                                    wUpdDt ,
                                    wUpdBy ,
                                    wType ,
                                    wRoomBookingRid ,
                                    wCasinoCardRid ,
                                    wApplicationType ,
                                    wApplicationStatus ,
                                    wAmount ,
                                    wCost ,
                                    wPassengerSeqNo ,
                                    wCancelDebitDt ,
                                    wCancelReasonCd ,
                                    wOtherReason ,
                                    wCancelBy ,
                                    wCancelDt ,
                                    wPassengerBookingStatus ,
                                    wChangeOrderCount ,
                                    wIsWaiting
                            FROM    #sDataSet_SetPassengerDetailsSecond;
                  
 
                    SET @pPassengerRid = @sRowID;                      
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
                              [wCancelDebitDt] ,
                              [wCancelReasonCd] ,
                              [wOtherReason] ,
                              [wCancelBy] ,
                              [wCancelDt] ,
                              [wPassengerBookingStatus] ,
                              [wChangeOrderCount] ,
                              [wIsWaiting]
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
                                    s.[wCancelDebitDt] ,
                                    s.[wCancelReasonCd] ,
                                    s.wOtherReason ,
                                    s.[wCancelBy] ,
                                    ( CASE WHEN s.wPassengerBookingStatus = 'CL'
                                                OR s.wPassengerBookingStatus = 'RF' THEN dbo.fnUTC8Now()
                                           ELSE NULL
                                      END ) ,
                                    s.wPassengerBookingStatus ,
                                    s.wChangeOrderCount ,
                                    s.wIsWaiting 
                            FROM    #sDataSet_SetPassengerDetailsSecond s; 

                    IF @pBookingType = 'PASSENGER'
                        BEGIN		
                            SELECT  @sCost = SUM(wCost) ,
                                    @sAmount = SUM(wAmount)
                            FROM    dbo.ePassengerDetails
                            WHERE   wBookingRid = @pBookingRid
                                    AND wStatus = 'A'
                                    AND wPassengerBookingStatus IN ( 'P', 'C' );

            ----- Update amount and cost in Booking
                            UPDATE  ebat
                            SET     ebat.wTotalAmt = ISNULL(@sAmount, 0) ,
                                    ebat.wTotalCost = ISNULL(@sCost, 0) ,
                                    ebat.wUpdDt = dbo.fnUTC8Now() ,
                                    ebat.wUpdBy = @sUpdatedBy
                            FROM    dbo.[eBookingAirTicket] AS ebat
                            WHERE   ebat.wBookingRid = @pBookingRid;
                        END;

                    IF OBJECT_ID('tempdb..#sDataSet_SetPassengerDetailsSecond') IS NOT NULL
                        DROP TABLE #sDataSet_SetPassengerDetailsSecond;               
        
                END;      
    
            IF @pActionType = 'D'
                BEGIN
                    UPDATE  PSD
                    SET     [wUpdDt] = dbo.fnUTC8Now() ,
                            [wUpdBy] = TMP.wUpdBy ,
                            [wCancelDebitDt] = ISNULL(PSD.[wCancelDebitDt], dbo.fnUTC8Now()) ,
                            [wCancelReasonCd] = TMP.wCancelReasonCd ,
                            [wOtherReason] = TMP.wOtherReason ,
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
                            [wStatus] = 'T'
                    FROM    [dbo].[ePassengerDetails] PSD
                            INNER JOIN #sDataSet_SetPassengerDetails TMP ON TMP.RowID = PSD.RowID
                                                                            AND TMP.wCurStatus = 'A';
            
                END;

            IF ( @pActionType = 'U'
                 OR @pActionType = 'D'
               )
                AND @pBookingType = 'PASSENGER'
                BEGIN

                    SELECT  @sCost = SUM(wCost) ,
                            @sAmount = SUM(wAmount)
                    FROM    dbo.ePassengerDetails
                    WHERE   wBookingRid = @pBookingRid
                            AND wStatus = 'A'
                            AND ( wPassengerBookingStatus = 'P'
                                  OR wPassengerBookingStatus = 'C'
                                );

                    DECLARE @sRefundCount INT= 0 ,
                        @sTotalPasssengerCount INT= 0 ,
                        @sBookingStatus VARCHAR(3)= '';

                    SELECT  @sRefundCount = COUNT(1)
                    FROM    dbo.[ePassengerDetails]
                    WHERE   wBookingRid = @pBookingRid
                            AND wPassengerBookingStatus = 'RF'
                            AND wStatus = 'A';
        
                    SELECT  @sTotalPasssengerCount = COUNT(1)
                    FROM    dbo.[ePassengerDetails]
                    WHERE   wBookingRid = @pBookingRid
                            AND wStatus = 'A';
        
                    SET @sRefundCount = ISNULL(@sRefundCount, 0);
                    SET @sTotalPasssengerCount = ISNULL(@sTotalPasssengerCount, 0);

                    IF @sRefundCount = @sTotalPasssengerCount
                        AND @sTotalPasssengerCount > 0
                        SET @sBookingStatus = 'RF';

                    UPDATE  ebat
                    SET     ebat.wTotalAmt = ISNULL(@sAmount, 0) ,
                            ebat.wTotalCost = ISNULL(@sCost, 0) ,
                            ebat.wUpdDt = dbo.fnUTC8Now() ,
                            ebat.wUpdBy = @sUpdatedBy ,
                            ebat.wBookingStatus = CASE WHEN @sBookingStatus = '' THEN ebat.wBookingStatus
                                                       ELSE @sBookingStatus
                                                  END
                    FROM    dbo.[eBookingAirTicket] AS ebat
                    WHERE   ebat.wBookingRid = @pBookingRid;

                END;

            ---------------------------------------------------------------------------------------------
            -- Sync Expense to rollsmary
            -- Holly shit, Aloha 只係用呢個 sp 做機票, 所以唔可以響呢度 handle 埋直升機 ....
            ---------------------------------------------------------------------------------------------
            SELECT  @vMthEndYearMth = MAX(wYearMth)
            FROM    RollsMary.dbo.eSettleTran (NOLOCK) WHERE wSettleLineGrp = '';
            SET @vDateUsingCRM = ( SELECT TOP 1
                                            wValue
                                   FROM     RollsMary.dbo.mSysTable
                                   WHERE    wItemCode = 'DATE_USING_CRM'
                                 );
            SET @vDateUsingCRM = ISNULL(@vDateUsingCRM, '2099-12-31');

            IF @pActionType IN ( 'I', 'U' )
                AND EXISTS ( SELECT 1
                             FROM   #sDataSet_SetPassengerDetails
                             WHERE  wType = 'AIRTICKET' )
                BEGIN				
                -- 以下呢段野係用來 refund 時要用另一個 date
                -- CASE WHEN tmp.wPassengerBookingStatus = 'RF' THEN b.wCancelDebitDt ELSE b.wDebitDt END

                    --- gen period start -navin 2018-01-19
                    DECLARE @zRecCount INT = 0,
                            @zRuningIndex INT = 1,
                            @zCompNo INT,
                            @zDate DATE;
                    SELECT wRowNum = ROW_NUMBER() OVER ( ORDER BY tmp.RowID ) ,
                           sc.wRollexCompNo AS wCompNo, (CASE WHEN tmp.wPassengerBookingStatus = 'RF' THEN ISNULL(tmp.wCancelDebitDt, b.wDebitDt)
                                             ELSE b.wDebitDt
                                        END) AS wDate
                        INTO #s_Period
                        FROM #sDataSet_SetPassengerDetails tmp
                            INNER JOIN eBooking b ON tmp.wBookingRid = b.RowID
                            LEFT JOIN dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                            LEFT JOIN RollsMary.dbo.mSettlePeriod sp ON sp.wCompNo = sc.wRollexCompNo AND sp.wCageCodeIn = @sCageCodeIn
                                                                        AND CASE WHEN tmp.wPassengerBookingStatus = 'RF' THEN ISNULL(tmp.wCancelDebitDt, b.wDebitDt)
                                                                                 ELSE b.wDebitDt
                                                                            END BETWEEN sp.wStartDateTime
                                                                                AND     sp.wEndDateTime
                            WHERE sp.wPeriodCodeIn IS NULL;
                                                
                    SELECT @zRecCount = COUNT(1) FROM #s_Period

                    WHILE @zRuningIndex <= @zRecCount BEGIN
                         SELECT @zCompNo =  wCompNo, @zDate = CAST(wDate AS date) FROM #s_Period WHERE wRowNum = @zRuningIndex;
                         IF ISNULL(@zCompNo,0) > 0 AND @zDate IS NOT NULL
                            BEGIN
                                EXEC RollsMary.dbo.spqGetCompPeriod @zCompNo, @zCompNo, @zDate, 'Y', 'N';
                            END
                        SET @zCompNo = 0;
                        SET @zDate = NULL;
                        SET @zRuningIndex = @zRuningIndex + 1;
                    END	

                    -- end gen period

                    UPDATE  tmp
                    SET     wPeriodCodeIn = sp.wPeriodCodeIn,
                            wYearMth = sp.wYear + sp.wMonth,
                            wDate = ISNULL(cs.wDate, CAST(CASE WHEN tmp.wPassengerBookingStatus = 'RF' THEN ISNULL(tmp.wCancelDebitDt, b.wDebitDt)
                                                               ELSE b.wDebitDt
                                                          END AS DATE)) ,
                            wShift = ISNULL(cs.wShift, '1')
                    FROM    #sDataSet_SetPassengerDetails tmp
                            INNER JOIN eBooking b ON tmp.wBookingRid = b.RowID
                            LEFT JOIN dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                            LEFT JOIN RollsMary.dbo.mSettlePeriod sp ON sp.wCompNo = sc.wRollexCompNo AND sp.wCageCodeIn = @sCageCodeIn
                                                                        AND CASE WHEN tmp.wPassengerBookingStatus = 'RF' THEN ISNULL(tmp.wCancelDebitDt, b.wDebitDt)
                                                                                 ELSE b.wDebitDt
                                                                            END BETWEEN sp.wStartDateTime
                                                                                AND     sp.wEndDateTime
                            LEFT JOIN RollsMary.dbo.eCompShift cs ON cs.wCompNo = sc.wRollexCompNo
                                                                     AND CASE WHEN tmp.wPassengerBookingStatus = 'RF' THEN ISNULL(tmp.wCancelDebitDt, b.wDebitDt)
                                                                              ELSE b.wDebitDt
                                                                         END BETWEEN cs.wStartDateTime
                                                                             AND     cs.wEndDateTime
                    WHERE   tmp.wType = 'AIRTICKET'
                            AND tmp.RowID > 0
                            AND (
                                (tmp.wPassengerBookingStatus = 'C' AND ISNULL(tmp.wOriPassengerBookingStatus, 'P') != 'C')
                                OR 
                                (tmp.wPassengerBookingStatus = 'RF' AND ISNULL(tmp.wOriPassengerBookingStatus, 'P') != 'RF')
                        );
                
                -- Check is already Mth end or not	
                    IF EXISTS ( SELECT  1
                                FROM    #sDataSet_SetPassengerDetails tmp
                                WHERE   wYearMth <= @vMthEndYearMth )
                        BEGIN
                            SET @pErrMsg = CONCAT(@vMthEndYearMth, ' already month end, cannot insert expense on or before that.');
                            THROW 50001, @pErrMsg, 1;
                        END;


                --------test---
                --SELECT * FROM
                --		#sDataSet_SetPassengerDetails

                --SELECT TOP 10 * FROM ePassengerDetails ORDER BY wUpdDt DESC;

                --SELECT 'RESULT', tmp.wPassengerBookingStatus, tmp.wOriPassengerBookingStatus, * FROM
                --		#sDataSet_SetPassengerDetails tmp
                --	LEFT JOIN
                --		dbo.ePassengerDetails pd ON tmp.RowID = pd.RowID OR (tmp.wBookingRid = pd.wBookingRid AND tmp.wPersonRid = pd.wPersonRid AND tmp.wPersonTravelDocRid = pd.wPersonTravelDocRid)
                --	INNER JOIN
                --		dbo.mPerson p ON tmp.wPersonRid = p.RowID
                --	LEFT JOIN
                --		dbo.eBookingAirTicket bat ON tmp.wBookingRid = bat.wBookingRid
                --	INNER JOIN
                --		eBooking b ON tmp.wBookingRid = b.RowID
                --	INNER JOIN
                --		RollsMary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                --	LEFT JOIN
                --		RollsMary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                --	LEFT JOIN
                --		dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                --	LEFT JOIN
                --		RollsMary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo AND c.wCageCode = '001' AND c.wStatus = 'A'
                --	LEFT JOIN
                --		RollsMary.dbo.mUsr u ON tmp.wUpdBy = u.RowID
                --	WHERE
                --		tmp.wType = 'AIRTICKET' AND tmp.RowID > 0
                --	AND 
                --		(
                --			tmp.wPassengerBookingStatus = 'C' AND ISNULL(tmp.wOriPassengerBookingStatus, 'P') != 'C'
                --		OR
                --			tmp.wPassengerBookingStatus = 'RF' AND ISNULL(tmp.wOriPassengerBookingStatus, 'P') != 'RF'
                --		)
                --------endtest---

                    IF @vNow >= @vDateUsingCRM
                -- ADD expense tran
                        SET @vXMLInsertExp = ( SELECT   RowID = 0 ,
                                                        wCompNo = sc.wRollexCompNo ,
                                                        wCageCodeIn = c.wCageCodeIn ,
                                                        wTranNo = '' ,
                                                        wDate = tmp.wDate ,
                                                        wCurDateTime = @vNow ,
                                                        wShift = tmp.wShift ,
                                                        wAgentCodeIn = b.wDebitAgentCodeIn ,
                                                        wCardCodeIn = '' ,
                                                        wCustName = ISNULL(p.wCName, '') ,
                                                        wShopName = '' ,
                                                        wExpTypeCode = 'TICKET 2' ,
                                                        wExpTargetCode = '' ,
                                                        wExpCode = '1000012535' ,
                                                        wExpSubCode1 = '' ,
                                                        wCurCode = bat.wCurrCode ,
                                                        wRoomNo = '' ,
                                                        wRoomCfmCode = '' ,
                                                        wRoomBookDt = NULL ,
                                                        wRoomCheckInDt = NULL ,
                                                        wRoomDeptDt = NULL ,
                                                        wNight = 0 ,
                                                        wUnit = 1 ,
                                                        wPrice = CASE tmp.wPassengerBookingStatus
                                                                   WHEN 'RF' THEN -1
                                                                   ELSE 1
                                                                 END * CASE WHEN ISNULL(bat.wPaymentMethod, '') IN ( 'DA', 'GC', 'ST-CASH', 'ST-AP', 'ST-BT', 'ST-CC' ) THEN tmp.wAmount
                                                                            ELSE 0
                                                                       END ,
                                                        wRoomExpAmt = 0 ,
                                                        wAmount = CASE tmp.wPassengerBookingStatus
                                                                    WHEN 'RF' THEN -1
                                                                    ELSE 1
                                                                  END * CASE WHEN ISNULL(bat.wPaymentMethod, '') IN ( 'DA', 'GC', 'ST-CASH', 'ST-AP', 'ST-BT', 'ST-CC' ) THEN tmp.wAmount
                                                                             ELSE 0
                                                                        END ,
                                                        wExpLocation = sc.wDefaultHotelCode ,
                                                        wVoucherNo = '' ,
                                                        wVoucherDt = tmp.wDate ,
                                                        wRemark = CONCAT(N'機票預訂: ', b.wRefNo, CASE tmp.wPassengerBookingStatus
                                                                                                WHEN 'RF' THEN N'退款'
                                                                                                ELSE N''
                                                                                              END) ,
                                                        wPeriodCodeIn = tmp.wPeriodCodeIn ,
                                                        wExpType = 'I' ,
                                                        wExpGroup = 'RCRM' ,
                                                        wDeductType = 'DC' ,
                                                        wPrtPage = 0 ,
                                                        wPrtRow = 0 ,
                                                        wTotSetAmt = 0 ,
                                                        wUpdBy = tmp.wUpdBy ,
                                                        wUpdDt = @vNow ,
                                                        wRefRid = tmp.RowID ,
                                                        wReferId = tmp.wBookingRid ,
                                                        wExpSite = '' ,
                                                        wReferUpdBy = '' ,
                                                        wEliteCodeIn = '' ,
                                                        wSettleInstantTranNo = '' ,
                                                        wIsAdj = 'N' ,
                                                        wForeignTranRefNo = '' ,
                                                        wFxRateHKD = 1 ,
                                                        wFxRateRMB = 1 ,
                                                        wExpDesc = bat.wPaymentMethod ,
                                                        wExtUpdBy = ISNULL(u.wCName, '') ,
                                                        wInvoiceDateTime_CRM = b.wExpDt ,
                                                        wAmountActual_CRM = CASE tmp.wPassengerBookingStatus
                                                                              WHEN 'RF' THEN -1
                                                                              ELSE 1
                                                                            END * tmp.wAmount ,
                                                        wCardNo_CRM = '' ,
                                                        wAuthorizer_CRM = aAuth.wCName ,
                                                        wExpCategory = 'TRAVEL' ,
                                                        wGuid = '' ,
                                                        wRequestAgentCodeIn = b.wReqAgentCodeIn ,
                                                        wIsDeposit = 'N' ,
                                                        wIsDepositDone = 'N' ,
                                                        wProductCategory = '' ,
                                                        wProductDetail = '',
                                                        wBookingRid = tmp.wBookingRid,
                                                        wBookingStatus = tmp.wPassengerBookingStatus
                                               FROM     #sDataSet_SetPassengerDetails tmp --LEFT JOIN
                    --	dbo.ePassengerDetails pd ON tmp.RowID = pd.RowID OR (tmp.wBookingRid = pd.wBookingRid AND tmp.wPersonRid = pd.wPersonRid AND tmp.wPersonTravelDocRid = pd.wPersonTravelDocRid)
                                                        INNER JOIN dbo.mPerson p ON tmp.wPersonRid = p.RowID
                                                        LEFT JOIN dbo.eBookingAirTicket bat ON tmp.wBookingRid = bat.wBookingRid
                                                        INNER JOIN eBooking b ON tmp.wBookingRid = b.RowID
                                                        INNER JOIN RollsMary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                                        LEFT JOIN RollsMary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                                        LEFT JOIN dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                                                        LEFT JOIN RollsMary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                                                           AND c.wCageCode = '001'
                                                                                           AND c.wStatus = 'A'
                                                        LEFT JOIN RollsMary.dbo.mUsr u ON tmp.wUpdBy = u.RowID
                                               WHERE    tmp.wType = 'AIRTICKET'
                                                        AND tmp.RowID > 0
                                                        AND ( ( tmp.wPassengerBookingStatus = 'C'
                                                                AND ISNULL(tmp.wOriPassengerBookingStatus, 'P') != 'C'
                                                              )
                                                              OR ( tmp.wPassengerBookingStatus = 'RF'
                                                                   AND ISNULL(tmp.wOriPassengerBookingStatus, 'P') != 'RF'
                                                                 )
                                                            )
                                             FOR
                                               XML RAW('Record') ,
                                                   ROOT('DataSet')
                                             );


                    /*
                -- Log for checking
                    DECLARE @vTmpTableStr AS NVARCHAR(MAX) ,
                        @vTmp AS NVARCHAR(MAX);
                    SET @vTmpTableStr = ( SELECT    b.* ,
                                                    tmp.*
                                          FROM      #sDataSet_SetPassengerDetails tmp
                                                    INNER JOIN dbo.eBooking b ON tmp.wBookingRid = b.RowID
                                        FOR
                                          XML AUTO
                                        );
                    SET @vTmp = CONCAT(@vTmpTableStr, CHAR(10), CHAR(13), CHAR(10), CHAR(13), @vXMLInsertExp, CHAR(10), CHAR(13), CHAR(10), CHAR(13), CAST(@pXML AS NVARCHAR(MAX)));

                    EXEC spa.WriteErrorLog @pMainCompNo = 99, -- int
                        @pCompNo = 0, -- int
                        @pLogCode = N'SYNC_EXP_AIR', -- nvarchar(50)
                        @pLogInfo = @vTmp, -- nvarchar(max)
                        @pRtnCode = 0, -- int
                        @pErrMsg = ''; -- nvarchar(2000)
                    */
                    IF @vXMLInsertExp != ''
                        BEGIN
                            EXEC spa.SetCrmExpTran @pXML = @vXMLInsertExp, -- xml
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
                        END;
                END;
            ---------------------------------------------------------------------------------------------
            -- End Sync Expense
            ---------------------------------------------------------------------------------------------

            ---------------------------------------------------------------------------------------------
            -- Add eGift record
            ---------------------------------------------------------------------------------------------
            IF EXISTS ( SELECT 1
                        FROM #sDataSet_SetPassengerDetails tmp
                        INNER JOIN dbo.eBookingAirTicket bat ON tmp.wBookingRid = bat.wBookingRid AND bat.wStatus = 'A'
                        WHERE ((tmp.wPassengerBookingStatus = 'C' AND ISNULL(tmp.wOriPassengerBookingStatus, 'P') != 'C')
                               OR (tmp.wPassengerBookingStatus = 'RF' AND ISNULL(tmp.wOriPassengerBookingStatus, 'P') != 'RF')
                               OR (tmp.wOriPassengerBookingStatus = 'C' AND tmp.wPassengerBookingStatus = 'C')
                               OR (tmp.wOriPassengerBookingStatus = 'RF' AND tmp.wPassengerBookingStatus = 'RF'))
                           AND tmp.wType = 'AIRTICKET' AND tmp.RowID > 0 AND (bat.wPaymentMethod = 'GC' OR bat.wPaymentMethod = 'GC0') )
                BEGIN                    
                    SET @sXMLeGift = ( SELECT   g.RowID AS RowID ,
                                                tmp.wBookingRid AS wRefBookingRid ,
                                                'eBooking' AS wRefTableName ,
                                                tmp.wBookingRid AS wRefTableRid ,
                                                tmp.wPassengerBookingStatus AS wOriActionType ,
                                                b.wDebitCounterRid AS wDebitCounterRid ,
                                                b.wReqCounterRid AS wReqCounterRid ,
                                                sc.wRollexCompNo AS wCompNo ,
                                                @sCageCodeIn AS wCageCodeIn ,
                                                b.wReqDepartment AS wReqDeptCd ,
                                                b.wReqUserRid AS wReqStaffRid ,
                                                b.wReqAgentCodeIn AS wReqAgentCodeIn ,
                                                wDate = CASE WHEN g.RowID IS NULL THEN GETDATE() ELSE g.wDate END,
                                                a.wCName AS wRecipient ,
                                                -- 'HKD' AS wCurrCode , --2018-12-14： OP#24284，送禮特批中的金額貨幣現在默認為HKD，應該跟Booking中的貨幣
                                                bat.wCurrCode AS wCurrCode,
                                                wAmount = CASE WHEN g.RowID IS NULL THEN (CASE tmp.wPassengerBookingStatus WHEN 'RF' THEN -1 ELSE 1 END) * tmp.wAmount ELSE g.wAmount END,
                                                '02' AS wType , --送禮
                                                '0228' AS wSubType , --機票
                                                wRemark = bat.wRemark, -- 此處需求改為用大單的remark
                                                b.wEventCodeRid AS wEventCodeRid ,
                                                wStatus = CASE WHEN g.RowID IS NULL THEN 'A' ELSE g.wStatus END,
                                                wCrtDt = CASE WHEN g.RowID IS NULL THEN @vNow ELSE g.wCrtDt END, -- set sp should not update this field when update
                                                wCrtBy = CASE WHEN g.RowID IS NULL THEN tmp.wUpdBy ELSE g.wCrtBy END, -- in set sp should not update this field when update
                                                @vNow AS wUpdDt ,
                                                tmp.wUpdBy ,
                                                CASE WHEN ((tmp.wPassengerBookingStatus = 'C' AND ISNULL(tmp.wOriPassengerBookingStatus, 'P') != 'C')
                                                          OR (tmp.wPassengerBookingStatus = 'RF' AND ISNULL(tmp.wOriPassengerBookingStatus, 'P') != 'RF'))
                                                          --AND ISNULL(g.wRefTableRid, 0) <= 0 
                                                THEN 'I'
                                                ELSE 'U'
                                                END AS RecordState ,
                                                b.wGiftReasonCd AS wReasonCd ,
                                                wIsReceived = 'Y', -- 經由booking 產生的送禮記錄要預設為 "已接收"
                                                tmp.wCost
                                     FROM #sDataSet_SetPassengerDetails tmp
                                     INNER JOIN dbo.eBookingAirTicket bat ON tmp.wBookingRid = bat.wBookingRid AND bat.wStatus = 'A'
                                     INNER JOIN dbo.eBooking b ON b.RowID = tmp.wBookingRid
                                     INNER JOIN dbo.mServiceCounter sc ON sc.RowID = b.wReqCounterRid
                                     LEFT JOIN eGift g ON g.wRefTableRid = tmp.wBookingRid AND g.wStatus = 'A' AND ((tmp.wOriPassengerBookingStatus = 'C' AND tmp.wPassengerBookingStatus = 'C') OR (tmp.wOriPassengerBookingStatus = 'RF' AND tmp.wPassengerBookingStatus = 'RF')) -- 只有Update才能Join舊數據
                                     INNER JOIN RollsMary.dbo.mAgent a ON a.wAgentCodeIn = b.wApprovalAgentCodeIn AND a.wStatus = 'A'
                                     WHERE tmp.wType = 'AIRTICKET' AND tmp.RowID > 0 AND (bat.wPaymentMethod = 'GC' OR bat.wPaymentMethod = 'GC0')
                                     FOR XML RAW('Record') , ROOT('DataSet'));

                    EXEC spa.SetGift @sXMLeGift, -- xml
                        @pMainCompNo, -- int
                        @pTestMode = 0, -- int
                        @pNonceToken = '', -- varchar(64)
                        @pReturnResultSet = 'N', -- char(1)
                        @pErrCode = 0, -- int
                        @pErrMsg = N''; -- nvarchar(200)     
                END;               
                ---------------------------------------------------------------------------------------------
                -- End Add eGift record
                ---------------------------------------------------------------------------------------------

				----------------------------------------------------------------------------------------------------
				-- UPDATE stg.eBookingMisc
				----------------------------------------------------------------------------------------------------
				SELECT
					pdOut.wBookingRid, l.wLangCd, 
					wItemCd = 'CUST_NAME', wValue = ISNULL(STUFF(
							(
								SELECT  ',' + CASE WHEN l.wLangCd = 'zh-TW' THEN p.wCName ELSE p.wEName END
								FROM    ePassengerDetails pd
								        INNER JOIN mPerson p ON pd.wPersonRid = p.RowID AND pd.wStatus = 'A'
								WHERE   pd.wBookingRid = pdOut.wBookingRid
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
                END;
            ELSE
                THROW;

        END CATCH;
    
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetPassengerDetails') IS NOT NULL
            DROP TABLE #sDataSet_SetPassengerDetails;
        IF OBJECT_ID('tempdb..#s_Period') IS NOT NULL
            DROP TABLE #s_Period;
    END;