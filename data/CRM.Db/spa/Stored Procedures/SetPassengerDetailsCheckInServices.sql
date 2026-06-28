CREATE PROCEDURE [spa].[SetPassengerDetailsCheckInServices]
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
        DECLARE @sThisTableName VARCHAR(50) = 'ePassengerDetails' ,
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @vNow DATETIME2 = dbo.fnUTC8Now() ,
            @vMthEndYearMth VARCHAR(6) ,
            @vDateUsingCRM DATETIME2;
    
        DECLARE @sSeqNo INT = 0 ,
            @sRowIDDtl BIGINT = 0 ,
            @sDocHandle INT ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0;

        DECLARE @sReturnRowID TABLE ( RowID BIGINT );

        DECLARE @sXMLeGift NVARCHAR(MAX) = '' ,
            @sCageCodeIn VARCHAR(14);

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
        wPassengerBookingStatus VARCHAR(10),
        wCancelDebitDt DATETIME2,
        wCancelReasonCd VARCHAR(30),
        wOtherReason NVARCHAR(200),
        wCancelBy BIGINT,
        wCancelDt DATETIME2,
        wRouteRid BIGINT,
        wChangeOrderCount INT	
    );

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
                                                                   

        ---Validate required field  Start
        DECLARE @errorMsg VARCHAR(MAX);
        IF @pActionType IN ( 'I', 'U' )
            BEGIN
                SELECT  @errorMsg = CASE WHEN ep.wPersonRid <= 0 THEN 'Client is Missing'
                                    END
                FROM    #sDataSet_SetPassengerDetails ep;
            END;

        IF @errorMsg <> ''
            THROW 50001, @errorMsg, 1;
        ---Validate required field  end

         
        DECLARE @sAmount NUMERIC(18, 4) ,
            @sCost NUMERIC(18, 4) ,
            @sBookingType VARCHAR(30)= '' ,
            @sUpdBy BIGINT= 0;;
        DECLARE @sRefundCount INT= 0 ,
            @sTotalPasssengerCount INT= 0 ,
            @sBookingStatus VARCHAR(3)= '';
        
        SELECT TOP 1
                @sBookingType = wType ,
                @sUpdBy = wUpdBy
        FROM    #sDataSet_SetPassengerDetails;

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
                              [wPassengerBookingStatus] ,
                              [wRouteRid] ,
                              [wChangeOrderCount]
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
                                    s.wChangeOrderCount
                            FROM    #sDataSet_SetPassengerDetails s; 
                END;                      
            ELSE
                IF @pActionType = 'U'
                    BEGIN
        -- There are multiple scenario to handle we have added below if condition while deleting record
        -- 1 : When we edit single record from Passenger List not from Booking 1st if condition will execute
        -- 2 : Suppose we are on any of booking page 1st Save Booking and do not close the Screen and then Add single or 
        --     multiple passenger here Else If conditon will get execute

                        UPDATE  pd
                        SET     
                                [wClientTicketNo] = ISNULL(tmp.wClientTicketNo, '') ,
                                [wDepartFlightNo] = ISNULL(tmp.wDepartFlightNo, '') ,
                                [wTakeOffDt] = tmp.wTakeOffDt ,
                                [wDestination] = ISNULL(tmp.wDestination, '') ,
                                [wRequesterAcc] = ISNULL(tmp.wRequesterAcc, 0) ,
                                [wPersonRid] = ISNULL(tmp.wPersonRid, 0) ,
                                [wRemark] = tmp.wRemark ,
                                [wStatus] = tmp.wStatus ,
                                [wUpdDt] = dbo.fnUTC8Now() ,
                                [wUpdBy] = tmp.wUpdBy ,
                                [wType] = tmp.wType ,
                                [wRoomBookingRid] = tmp.wRoomBookingRid ,
                                [wCasinoCardRid] = tmp.wCasinoCardRid ,
                                [wApplicationType] = tmp.wApplicationType ,
                                [wApplicationStatus] = tmp.wApplicationStatus ,
                                [wAmount] = tmp.wAmount ,
                                [wCost] = tmp.wCost ,
                                [wSeqNo] = tmp.wPassengerSeqNo ,
                                [wCancelDebitDt] = tmp.wCancelDebitDt ,
                                [wCancelReasonCd] = tmp.wCancelReasonCd ,
                                [wOtherReason] = tmp.wOtherReason ,
                                [wCancelBy] = ( CASE WHEN ( tmp.wPassengerBookingStatus = 'CL'
                                                            OR tmp.wPassengerBookingStatus = 'RF'
                                                          )
                                                          AND pd.wCancelBy IS NULL THEN tmp.wCancelBy
                                                     ELSE pd.wCancelBy
                                                END ) ,
                                [wCancelDt] = ( CASE WHEN ( tmp.wPassengerBookingStatus = 'CL'
                                                            OR tmp.wPassengerBookingStatus = 'RF'
                                                          )
                                                          AND pd.[wCancelDt] IS NULL THEN ISNULL(tmp.wCancelDt, dbo.fnUTC8Now())
                                                     ELSE pd.wCancelDt
                                                END ) ,
                                [wPassengerBookingStatus] = tmp.wPassengerBookingStatus ,
                                [wRouteRid] = tmp.wRouteRid ,
                                [wChangeOrderCount] = tmp.wChangeOrderCount
                        FROM    [dbo].[ePassengerDetails] pd
                                INNER JOIN #sDataSet_SetPassengerDetails tmp ON tmp.[RowID] = pd.RowID
                                                                                AND tmp.[RowID] > 0; --AND tmp.wStatus='A'


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

                        SELECT  RowID
                        INTO    #temp
                        FROM    ePassengerDetails
                        WHERE   wBookingRid = @pBookingRid
                                AND RowID NOT IN ( SELECT   RowID
                                                   FROM     #sDataSet_SetPassengerDetails ); 

                        IF @pIsUpdateSinglePassenger != 1
                            BEGIN

                                DELETE  pd
                                FROM    ePassengerDetails pd
                                        INNER JOIN #temp tmp ON tmp.RowID = pd.RowID;
            --WHERE RowID NOT IN(SELECT RowID FROM #sDataSet_SetPassengerDetails WHERE RowID > 0) AND wBookingRid = @pBookingRid

                                DELETE  ptd
                                FROM    ePassengerTravelDocDetail ptd --WHERE wPassengerDetailsRid NOT IN(SELECT RowID FROM #sDataSet_SetPassengerDetails WHERE RowID > 0) AND wBookingRid = @pBookingRid
                                        INNER JOIN #temp tmp ON tmp.RowID = ptd.wPassengerDetailsRid;
                            END;

                        DROP TABLE #temp;

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
            
                        --DELETE  FROM #sDataSet_SetPassengerDetails
                        --WHERE   [RowID] > 0;
        
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
                              --wCancelDebitDt ,
                              --wCancelReasonCd ,
                              --wOtherReason ,
                              --wCancelBy ,
                              --wCancelDt ,
                              wPassengerBookingStatus ,
                              wRouteRid ,
                              wChangeOrderCount --,
                              --wIsWaiting ,
                              --wExpiryDt
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
                                    --wCancelDebitDt ,
                                    --wCancelReasonCd ,
                                    --wOtherReason ,
                                    --wCancelBy ,
                                    --wCancelDt ,
                                    wPassengerBookingStatus ,
                                    wRouteRid ,
                                    wChangeOrderCount --,
                                    --wIsWaiting ,
                                    --wExpiryDt
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
                                  [wPassengerBookingStatus] ,
                                  [wRouteRid] ,
                                  [wChangeOrderCount]
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
                                        s.wChangeOrderCount
                            FROM    #sDataSet_SetPassengerDetailsSecond s; 
                    END;   
                ELSE
                    IF @pActionType = 'D'
                        BEGIN
                            UPDATE  pd
                            SET     [wPassengerBookingStatus] = tmp.wPassengerBookingStatus ,
                                    wStatus = 'T' ,
                                    [wUpdDt] = dbo.fnUTC8Now() ,
                                    [wUpdBy] = tmp.wUpdBy ,
                                    [wCancelReasonCd] = tmp.wCancelReasonCd ,
                                    [wOtherReason] = tmp.wOtherReason ,
                                    [wCancelBy] = tmp.wCancelBy ,
                                    [wCancelDt] = dbo.fnUTC8Now()
                            FROM    [dbo].[ePassengerDetails] pd
                                    INNER JOIN #sDataSet_SetPassengerDetails tmp ON tmp.[RowID] = pd.RowID
                                                                                    AND tmp.[RowID] > 0; 

                        END;

            IF @pActionType = 'U'
                OR @pActionType = 'D'
                BEGIN
                    IF @sBookingType = 'VISA'
                        BEGIN
                            IF EXISTS (SELECT 1 FROM dbo.eBookingVisa WHERE wStatus = 'A' AND wBookingRid = @pBookingRid AND wBookingStatus != 'P')
                            AND EXISTS (SELECT 1 FROM dbo.ePassengerDetails WHERE wStatus = 'A' AND wBookingRid = @pBookingRid AND wPassengerBookingStatus = 'P')
                            BEGIN
                                -- 更新db中狀態為P的客戶
                                UPDATE pd
                                SET pd.wPassengerBookingStatus = CASE visa.wBookingStatus
                                                                    WHEN 'C' THEN 'C'
                                                                    WHEN 'RF' THEN 'RF'
                                                                    WHEN 'CL' THEN 'CL'
                                                                    WHEN 'UQ' THEN 'CL'
                                                                    ELSE pd.wPassengerBookingStatus END
                                FROM dbo.ePassengerDetails AS pd
                                INNER JOIN dbo.eBookingVisa AS visa ON visa.wBookingRid = pd.wBookingRid
                                WHERE pd.wStatus = 'A' AND pd.wBookingRid = @pBookingRid AND pd.wPassengerBookingStatus = 'P'
                            END

                            SELECT  @sAmount = SUM(ISNULL(wAmount, 0)) ,
                                    @sCost = SUM(ISNULL(wCost, 0))
                            FROM    dbo.ePassengerDetails
                            WHERE   wBookingRid = @pBookingRid
                                    AND wStatus = 'A'
                                    AND ( wPassengerBookingStatus = 'P'
                                          OR wPassengerBookingStatus = 'C'
                                        );

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

            ---Update amount and cost in Booking
                            UPDATE  VIS
                            SET     VIS.wTotalAmt = ISNULL(@sAmount, 0) ,
                                    VIS.wCost = ISNULL(@sCost, 0) ,
                                    VIS.wUpdDt = dbo.fnUTC8Now() ,
                                    VIS.wUpdBy = @sUpdBy ,
                                    VIS.wBookingStatus = CASE WHEN @sBookingStatus = 'RF' THEN 'RF'
                                                              ELSE VIS.wBookingStatus
                                                         END
                            FROM    dbo.[eBookingVisa] AS VIS
                            WHERE   VIS.wBookingRid = @pBookingRid;
            
                        END;
                    ELSE
                        IF @sBookingType = 'HELI'
                            BEGIN
                                IF EXISTS (SELECT 1 FROM dbo.eBookingHeli WHERE wStatus = 'A' AND wBookingRid = @pBookingRid AND wBookingStatus != 'P')
                                AND EXISTS (SELECT 1 FROM dbo.ePassengerDetails WHERE wStatus = 'A' AND wBookingRid = @pBookingRid AND wPassengerBookingStatus = 'P')
                                BEGIN
                                    -- 更新db中狀態為P的客戶
                                    UPDATE pd
                                    SET pd.wPassengerBookingStatus = CASE heli.wBookingStatus
                                                                     WHEN 'C' THEN 'C'
                                                                     WHEN 'RF' THEN 'RF'
                                                                     WHEN 'CL' THEN 'CL'
                                                                     WHEN 'UQ' THEN 'CL'
                                                                     ELSE pd.wPassengerBookingStatus END
                                    FROM dbo.ePassengerDetails AS pd
                                    INNER JOIN dbo.eBookingHeli AS heli ON heli.wBookingRid = pd.wBookingRid
                                    WHERE pd.wStatus = 'A' AND pd.wBookingRid = @pBookingRid AND pd.wPassengerBookingStatus = 'P'

                                    -- 更新緩存中客戶的狀態（射數用此數據）
                                    UPDATE tmp
                                    SET tmp.wPassengerBookingStatus = pd.wPassengerBookingStatus
                                    FROM #sDataSet_SetPassengerDetails AS tmp
                                    INNER JOIN dbo.ePassengerDetails AS pd ON pd.RowID = tmp.RowID AND tmp.RowID > 0
                                END

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

            ---Update status
                                IF @sBookingStatus = 'RF'
                                    BEGIN
                                        UPDATE  HEL
                                        SET     HEL.wUpdDt = dbo.fnUTC8Now() ,
                                                HEL.wUpdBy = @sUpdBy ,
                                                HEL.wBookingStatus = 'RF'
                                        FROM    dbo.eBookingHeli AS HEL
                                        WHERE   HEL.wBookingRid = @pBookingRid;
                                    END;		
                            END;
                        ELSE
                            IF @sBookingType = 'PP'
                                BEGIN
                                    IF EXISTS (SELECT 1 FROM dbo.eBookingPrivatePlane WHERE wStatus = 'A' AND wBookingRid = @pBookingRid AND wBookingStatus != 'P')
                                    AND EXISTS (SELECT 1 FROM dbo.ePassengerDetails WHERE wStatus = 'A' AND wBookingRid = @pBookingRid AND wPassengerBookingStatus = 'P')
                                    BEGIN
                                        -- 更新db中狀態為P的客戶
                                        UPDATE pd
                                        SET pd.wPassengerBookingStatus = CASE pp.wBookingStatus
                                                                            WHEN 'C' THEN 'C'
                                                                            WHEN 'RF' THEN 'RF'
                                                                            WHEN 'CL' THEN 'CL'
                                                                            WHEN 'UQ' THEN 'CL'
                                                                            ELSE pd.wPassengerBookingStatus END
                                        FROM dbo.ePassengerDetails AS pd
                                        INNER JOIN dbo.eBookingPrivatePlane AS pp ON pp.wBookingRid = pd.wBookingRid
                                        WHERE pd.wStatus = 'A' AND pd.wBookingRid = @pBookingRid AND pd.wPassengerBookingStatus = 'P'
                                    END

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

            ---Update status
                                    IF @sBookingStatus = 'RF'
                                        BEGIN
                                            UPDATE  PP
                                            SET     PP.wUpdDt = dbo.fnUTC8Now() ,
                                                    PP.wUpdBy = @sUpdBy ,
                                                    PP.wBookingStatus = 'RF'
                                            FROM    dbo.eBookingPrivatePlane AS PP
                                            WHERE   PP.wBookingRid = @pBookingRid;
                                        END;		
                                END;
                            ELSE
                                IF @sBookingType = 'CS'
                                    BEGIN
                                        IF EXISTS (SELECT 1 FROM dbo.eBookingCheckInService WHERE wStatus = 'A' AND wBookingRid = @pBookingRid AND wBookingStatus != 'P')
                                        AND EXISTS (SELECT 1 FROM dbo.ePassengerDetails WHERE wStatus = 'A' AND wBookingRid = @pBookingRid AND wPassengerBookingStatus = 'P')
                                        BEGIN
                                            -- 更新db中狀態為P的客戶
                                            UPDATE pd
                                            SET pd.wPassengerBookingStatus = CASE cs.wBookingStatus
                                                                                WHEN 'C' THEN 'C'
                                                                                WHEN 'RF' THEN 'RF'
                                                                                WHEN 'CL' THEN 'CL'
                                                                                WHEN 'UQ' THEN 'CL'
                                                                                ELSE pd.wPassengerBookingStatus END
                                            FROM dbo.ePassengerDetails AS pd
                                            INNER JOIN dbo.eBookingCheckInService AS cs ON cs.wBookingRid = pd.wBookingRid
                                            WHERE pd.wStatus = 'A' AND pd.wBookingRid = @pBookingRid AND pd.wPassengerBookingStatus = 'P'
                                        END

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

            ---Update status
                                        IF @sBookingStatus = 'RF'
                                            BEGIN
                                                UPDATE  CHK
                                                SET     CHK.wUpdDt = dbo.fnUTC8Now() ,
                                                        CHK.wUpdBy = @sUpdBy ,
                                                        CHK.wBookingStatus = 'RF'
                                                FROM    dbo.eBookingCheckInService AS CHK
                                                WHERE   CHK.wBookingRid = @pBookingRid;
                                            END;		
                                    END;
                                ELSE
                                    IF @sBookingType = 'PICKUPSERVICE'
                                        BEGIN
                                            IF EXISTS (SELECT 1 FROM dbo.eBookingPickUpService WHERE wStatus = 'A' AND wBookingRid = @pBookingRid AND wBookingStatus != 'P')
                                            AND EXISTS (SELECT 1 FROM #sDataSet_SetPassengerDetails WHERE wStatus = 'A' AND wBookingRid = @pBookingRid AND wPassengerBookingStatus = 'P')
                                            BEGIN
                                                -- 更新db中狀態為P的客戶
                                                UPDATE pd
                                                SET pd.wPassengerBookingStatus = CASE pu.wBookingStatus
                                                                                    WHEN 'C' THEN 'C'
                                                                                    WHEN 'RF' THEN 'RF'
                                                                                    WHEN 'CL' THEN 'CL'
                                                                                    WHEN 'UQ' THEN 'CL'
                                                                                    ELSE pd.wPassengerBookingStatus END
                                                FROM dbo.ePassengerDetails AS pd
                                                INNER JOIN dbo.eBookingPickUpService AS pu ON pu.wBookingRid = pd.wBookingRid
                                                WHERE pd.wStatus = 'A' AND pd.wBookingRid = @pBookingRid AND pd.wPassengerBookingStatus = 'P'
                                            END

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

            ---Update status
                                            IF @sBookingStatus = 'RF'
                                                BEGIN
                                                    UPDATE  PK
                                                    SET     PK.wUpdDt = dbo.fnUTC8Now() ,
                                                            PK.wUpdBy = @sUpdBy ,
                                                            PK.wBookingStatus = 'RF'
                                                    FROM    dbo.eBookingPickUpService AS PK
                                                    WHERE   PK.wBookingRid = @pBookingRid;
                                                END;		
                                        END;
                                    ELSE
                                        IF @sBookingType = 'TRAVEL_PACKAGE'
                                        BEGIN
                                            IF EXISTS (SELECT 1 FROM dbo.eBookingTravelPackage WHERE wStatus = 'A' AND wBookingRid = @pBookingRid AND wBookingStatus != 'P')
                                            AND EXISTS (SELECT 1 FROM dbo.ePassengerDetails WHERE wStatus = 'A' AND wBookingRid = @pBookingRid AND wPassengerBookingStatus = 'P')
                                            BEGIN
                                                -- 更新db中狀態為P的客戶
                                                UPDATE pd
                                                SET pd.wPassengerBookingStatus = CASE pkg.wBookingStatus
                                                                                    WHEN 'C' THEN 'C'
                                                                                    WHEN 'RF' THEN 'RF'
                                                                                    WHEN 'CL' THEN 'CL'
                                                                                    WHEN 'UQ' THEN 'CL'
                                                                                    ELSE pd.wPassengerBookingStatus END
                                                FROM dbo.ePassengerDetails AS pd
                                                INNER JOIN dbo.eBookingTravelPackage AS pkg ON pkg.wBookingRid = pd.wBookingRid
                                                WHERE pd.wStatus = 'A' AND pd.wBookingRid = @pBookingRid AND pd.wPassengerBookingStatus = 'P'
                                            END
                                        END;
                END;
            ---------------------------------------------------------------------------------------------
            -- Sync Expense to rollsmary
            -- Holly shit, Aloha 將個機票 passenger 拆左去 spa.[SetPassengerDetails_ForAir] 做 ....
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
                             WHERE  wType = 'HELI' )
                BEGIN
                    DECLARE @vXMLInsertExp NVARCHAR(MAX) = '' ,
                        @vXMLRefundExp NVARCHAR(MAX) = '' ,
                        @vErrCode INT = 0 ,
                        @vErrMsg NVARCHAR(MAX);                   

                    
                    --- gen period start -navin 2018-01-19
                    DECLARE @zRecCount INT = 0,
                            @zRuningIndex INT = 1,
                            @zCompNo INT,
                            @zDate DATE;
                    SELECT wRowNum = ROW_NUMBER() OVER ( ORDER BY tmp.RowID ) ,
                           sc.wRollexCompNo AS wCompNo, (CASE WHEN tmp.wPassengerBookingStatus = 'RF' THEN tmp.wCancelDebitDt
                                             ELSE b.wDebitDt
                                        END) AS wDate
                        INTO #s_Period
                        FROM #sDataSet_SetPassengerDetails tmp
                            INNER JOIN eBooking b ON tmp.wBookingRid = b.RowID
                            LEFT JOIN dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                            LEFT JOIN RollsMary.dbo.mSettlePeriod sp ON sp.wCompNo = sc.wRollexCompNo AND sp.wCageCodeIn = @sCageCodeIn
                                                                        AND DATEADD(HOUR, 12, DATEADD(dd, DATEDIFF(dd, 0, CASE WHEN tmp.wPassengerBookingStatus = 'RF' THEN tmp.wCancelDebitDt
                                                                                                                               ELSE b.wDebitDt
                                                                                                                          END), 0)) BETWEEN sp.wStartDateTime
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

                -- 以下呢段野係用來 refund 時要用另一個 date
                -- CASE WHEN tmp.wPassengerBookingStatus = 'RF' THEN b.wCancelDebitDt ELSE b.wDebitDt END
                    UPDATE  tmp
                    SET     wPeriodCodeIn = sp.wPeriodCodeIn,
                            wYearMth = sp.wYear + sp.wMonth,
                            wDate = ISNULL(cs.wDate, CAST(CASE WHEN tmp.wPassengerBookingStatus = 'RF' THEN tmp.wCancelDebitDt
                                                               ELSE b.wDebitDt
                                                          END AS DATE)) ,
                            wShift = ISNULL(cs.wShift, '1')
                    FROM    #sDataSet_SetPassengerDetails tmp
                            LEFT JOIN dbo.eBookingHeli bh ON tmp.wBookingRid = bh.wBookingRid
                            INNER JOIN eBooking b ON tmp.wBookingRid = b.RowID
                            LEFT JOIN dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                            LEFT JOIN RollsMary.dbo.mSettlePeriod sp ON sp.wCompNo = sc.wRollexCompNo AND sp.wCageCodeIn = @sCageCodeIn
                                                                        AND DATEADD(HOUR, 12, DATEADD(dd, DATEDIFF(dd, 0, CASE WHEN tmp.wPassengerBookingStatus = 'RF' THEN tmp.wCancelDebitDt
                                                                                                                               ELSE b.wDebitDt
                                                                                                                          END), 0)) BETWEEN sp.wStartDateTime
                                                                                                                                    AND     sp.wEndDateTime
                            LEFT JOIN RollsMary.dbo.eCompShift cs ON cs.wCompNo = sc.wRollexCompNo
                                                                     AND DATEADD(HOUR, 12, DATEADD(dd, DATEDIFF(dd, 0, CASE WHEN tmp.wPassengerBookingStatus = 'RF' THEN tmp.wCancelDebitDt
                                                                                                                            ELSE b.wDebitDt
                                                                                                                       END), 0)) BETWEEN cs.wStartDateTime
                                                                                                                                 AND     cs.wEndDateTime
                    WHERE   tmp.wType = 'HELI'
                            AND tmp.RowID > 0
            
                            AND bh.wIsCharteredFlight = 'N'
                            AND ( (
                        -- pd.wPassengerBookingStatus 無即係 insert 架喇, 雖然唔太正常, 但當佢原本係 In progress 即可
                                    tmp.wPassengerBookingStatus = 'C'
                                    AND ISNULL(tmp.wOriPassengerBookingStatus, 'P') != 'C'
                                  )
                                  OR ( tmp.wPassengerBookingStatus = 'RF'
                                       AND ISNULL(tmp.wOriPassengerBookingStatus, 'P') != 'RF'
                                     )
                                );
                
                -- Check is already Mth end or not	
                    IF EXISTS ( SELECT  1
                                FROM    #sDataSet_SetPassengerDetails tmp
                                WHERE   wYearMth <= @vMthEndYearMth )
                        BEGIN
                            SET @pErrMsg = CONCAT(@vMthEndYearMth, ' already month end, cannot insert expense on or before that.');
                            THROW 50001, @pErrMsg, 1;
                        END;

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
                                                        wExpTypeCode = 'HP' ,
                                                        wExpTargetCode = '' ,
                                                        wExpCode = 'HP' ,
                                                        wExpSubCode1 = '' ,
                                                        wCurCode = bh.wCurrCode ,
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
                                                                 END * CASE WHEN ISNULL(bh.wPaymentMethod, '') IN ( 'DA', 'GC', 'ST-CASH', 'ST-AP', 'ST-BT', 'ST-CC' ) THEN bh.wUnitAmt
                                                                            ELSE 0
                                                                       END ,
                                                        wRoomExpAmt = 0 ,
                                                        wAmount = CASE tmp.wPassengerBookingStatus
                                                                    WHEN 'RF' THEN -1
                                                                    ELSE 1
                                                                  END * CASE WHEN ISNULL(bh.wPaymentMethod, '') IN ( 'DA', 'GC', 'ST-CASH', 'ST-AP', 'ST-BT', 'ST-CC' ) THEN bh.wUnitAmt
                                                                             ELSE 0
                                                                        END ,
                                                        wExpLocation = sc.wDefaultHotelCode ,
                                                        wVoucherNo = '' ,
                                                        wVoucherDt = tmp.wDate ,
                                                        wRemark = CONCAT(N'直升機預訂: ', b.wRefNo, CASE tmp.wPassengerBookingStatus
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
                                                        wExpDesc = bh.wPaymentMethod ,
                                                        wExtUpdBy = ISNULL(u.wCName, '') ,
                                                        wInvoiceDateTime_CRM = b.wExpDt ,
                                                        wAmountActual_CRM = CASE tmp.wPassengerBookingStatus
                                                                              WHEN 'RF' THEN -1
                                                                              ELSE 1
                                                                            END * bh.wUnitAmt ,
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
                                               FROM     #sDataSet_SetPassengerDetails tmp
                                                        INNER JOIN dbo.mPerson p ON tmp.wPersonRid = p.RowID
                                                        LEFT JOIN dbo.eBookingHeli bh ON tmp.wBookingRid = bh.wBookingRid
                                                        INNER JOIN eBooking b ON tmp.wBookingRid = b.RowID
                                                        INNER JOIN RollsMary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                                        LEFT JOIN RollsMary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                                        LEFT JOIN dbo.mServiceCounter sc ON b.wDebitCounterRid = sc.RowID
                                                        LEFT JOIN RollsMary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                                                           AND c.wCageCode = '001'
                                                                                           AND c.wStatus = 'A'
                                                        LEFT JOIN RollsMary.dbo.mUsr u ON tmp.wUpdBy = u.RowID
                                               WHERE    tmp.wType = 'HELI'
                                                        AND tmp.RowID > 0
                           
                                                        AND bh.wIsCharteredFlight = 'N'
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

                    DECLARE @vTmp AS NVARCHAR(MAX);
                    SET @vTmp = CONCAT(@vXMLInsertExp, CHAR(10), CHAR(13), CAST(@pXML AS NVARCHAR(MAX)));

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
                        INNER JOIN dbo.eBookingHeli bh ON tmp.wBookingRid = bh.wBookingRid AND bh.wStatus = 'A'
                        WHERE ((tmp.wPassengerBookingStatus = 'C' AND ISNULL(tmp.wOriPassengerBookingStatus, 'P') != 'C')
                              OR (tmp.wPassengerBookingStatus = 'RF' AND ISNULL(tmp.wOriPassengerBookingStatus, 'P') != 'RF')
                              OR (tmp.wOriPassengerBookingStatus = 'C' AND tmp.wPassengerBookingStatus = 'C')
                              OR (tmp.wOriPassengerBookingStatus = 'RF' AND tmp.wPassengerBookingStatus = 'RF'))
                            AND tmp.wType = 'HELI' AND tmp.RowID > 0 AND bh.wIsCharteredFlight = 'N' AND (bh.wPaymentMethod = 'GC' OR bh.wPaymentMethod = 'GC0') )
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
                                                bh.wCurrCode AS wCurrCode ,
                                                wAmount = CASE WHEN g.RowID IS NULL THEN (CASE tmp.wPassengerBookingStatus WHEN 'RF' THEN -1 ELSE 1 END) * bh.wUnitAmt ELSE g.wAmount END,
                                                '02' AS wType , --送禮
                                                '0213' AS wSubType , --直升機票
                                                wRemark = bh.wRemark, -- 此處需求改為用大單的remark
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
                                                wIsReceived = 'Y' ,-- 經由booking 產生的送禮記錄要預設為 "已接收"
                                                bh.wCost
                                     FROM #sDataSet_SetPassengerDetails tmp
                                     INNER JOIN dbo.eBookingHeli bh ON tmp.wBookingRid = bh.wBookingRid AND bh.wStatus = 'A' AND (bh.wPaymentMethod = 'GC' OR bh.wPaymentMethod = 'GC0')
                                     INNER JOIN dbo.eBooking b ON b.RowID = tmp.wBookingRid
                                     INNER JOIN dbo.mServiceCounter sc ON sc.RowID = b.wReqCounterRid
                                     LEFT JOIN eGift g ON g.wRefTableRid = tmp.wBookingRid AND g.wStatus = 'A' AND ((tmp.wOriPassengerBookingStatus = 'C' AND tmp.wPassengerBookingStatus = 'C') OR (tmp.wOriPassengerBookingStatus = 'RF' AND tmp.wPassengerBookingStatus = 'RF')) -- 只有Update才能Join到舊數據
                                     INNER JOIN RollsMary.dbo.mAgent a ON a.wAgentCodeIn = b.wApprovalAgentCodeIn AND a.wStatus = 'A'
                                     WHERE tmp.RowID > 0
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
        IF OBJECT_ID('tempdb..#sDataSet_SetPassengerDetailsSecond') IS NOT NULL
            DROP TABLE #sDataSet_SetPassengerDetailsSecond;
        IF OBJECT_ID('tempdb..#s_Period') IS NOT NULL
            DROP TABLE #s_Period;
    END;