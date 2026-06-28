CREATE PROCEDURE [spa].[SetAirTicketRouteDtl]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pBookingRid BIGINT ,
      @pBookingType VARCHAR(30) = '' ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT 
    )
AS
    BEGIN
        SET NOCOUNT ON;		
	
        DECLARE @sThisTableName VARCHAR(50) = 'eAirTicketRouteDtl' ,
            @sBeginTranCount INT         = 0 ,
            @sRuningIndex INT         = 1 ,
            @sRecCount INT         = 0 ,
            @sRowID BIGINT      = 0 ,
            @sDocHandle INT ,
            @pBookingAirTicketRid BIGINT      = 0 ,
            @sUpdatedBy BIGINT      = 0 ,
            @wFlightType VARCHAR(MAX);
	
        SELECT TOP 1
                @pBookingAirTicketRid = RowID ,
                @wFlightType = wFlightType ,
                @sUpdatedBy = wUpdBy
        FROM    dbo.eBookingAirTicket
        WHERE   wBookingRid = @pBookingRid;

        SET @sBeginTranCount = @@trancount;

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;

        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wTakeOffDt, wArrivalDt ) ,
                *
        INTO    #DataSet_SetAirTicketRoutesFirst
        FROM    OPENXML (@sDocHandle, 'DataSet/GetAirTicketRouteLstResult', 1)
	WITH (
			 RowID BIGINT
			,wType VARCHAR(30)
			,wTypeRid BIGINT
			,wPNRNo VARCHAR(50)
			,wLine INT
			,wFlightType VARCHAR(30)
			,wAirline NVARCHAR(10)
			,wClassCd VARCHAR(10)
			,wIsReturn CHAR(1)
			,wDepartFlightNo VARCHAR(20)
			,wDepartureAirportRid BIGINT
			,wArrivalAirportRid BIGINT
			,wDepartureTerminal NVARCHAR(50)
			,wArrivalTerminal NVARCHAR(50)
			,wTakeOffDt DATETIME2(7)
			,wArrivalDt DATETIME2(7)
			,wStatus CHAR(1)
			,wCrtDt DATETIME2(7)
			,wCrtBy BIGINT
			,wUpdDt DATETIME2(7)
			,wUpdBy BIGINT
			,wIsWaiting CHAR(1)
			,wExpiryDt DATETIME2(7)
            ,wIsDestination CHAR(1));

        BEGIN TRY

            CREATE TABLE #DataSet_SetAirTicketRoutes
                (
                  RowID BIGINT ,
                  wType VARCHAR(30) ,
                  wTypeRid BIGINT ,
                  wPNRNo VARCHAR(50) ,
                  wLine INT ,
                  wFlightType VARCHAR(30) ,
                  wAirline VARCHAR(10) ,
                  wClassCd VARCHAR(10) ,
                  wIsReturn CHAR(1) ,
                  wDepartFlightNo VARCHAR(20) ,
                  wDepartureAirportRid BIGINT ,
                  wArrivalAirportRid BIGINT ,
                  wDepartureTerminal NVARCHAR(50) ,
                  wArrivalTerminal NVARCHAR(50) ,
                  wTakeOffDt DATETIME2(7) ,
                  wArrivalDt DATETIME2(7) ,
                  wStatus CHAR(1) ,
                  wCrtDt DATETIME2(7) ,
                  wCrtBy BIGINT ,
                  wUpdDt DATETIME2(7) ,
                  wUpdBy BIGINT,
				  wIsWaiting CHAR(1),
				  wExpiryDt DATETIME2(7),
                  wIsDestination CHAR(1)
                );

	-- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
	
            DECLARE @sErrorMsg VARCHAR(MAX);
            DECLARE @routeCount INT;	 
/*
	IF @pActionType IN( 'U','I')
	BEGIN	
	
	SELECT @sErrorMsg=
			CASE 
				WHEN ds.wDepartureAirportRid<=0 THEN 'Departure airport should not be blank'
				WHEN ds.wArrivalAirportRid<=0 THEN 'Arrival airport should not be blank'
				WHEN ds.wDepartureAirportRid =ds.wArrivalAirportRid THEN 'Arrival airport and Departure airport cannot be same'
				WHEN ISNULL(ds.wDepartureTerminal,'')!='' AND  ISNULL(ds.wArrivalTerminal,'')!=''  AND ds.wDepartureTerminal =ds.wArrivalTerminal THEN 'Arrival terminal and departure terminal cannot be same'
				WHEN ds.wTakeOffDt > ds.wArrivalDt THEN 'Departure date cannot be greater than arrival date'			
			END	 
		FROM #DataSet_SetAirTicketRoutesFirst ds ;

	  IF(@sErrorMsg<>'')
		THROW 51000, @sErrorMsg, 1;  

			SELECT @routeCount=COUNT(*) FROM #DataSet_SetAirTicketRoutesFirst;				   
			SET @sErrorMsg= CASE
								WHEN @wFlightType='OneWay' AND @routeCount<>1 THEN 'One Way Flight should only one route details.'
								WHEN @wFlightType='RoundTrip' AND @routeCount<>2 THEN 'Two Way Flight should have two route details.'
								WHEN @wFlightType='MultiCity' AND @routeCount<=1 THEN 'Multicity Flight should have more than one route.'
							END

	  IF(@sErrorMsg<>'')
		THROW 51000, @sErrorMsg, 1;  

	END
*/

	-- Update existing records after that insert new records.
            IF @pActionType = 'U'
                BEGIN
                    IF @pBookingType != 'PASSENGER'
                        BEGIN
                            UPDATE  TMP
                            SET     TMP.RowID = 0
                            FROM    #DataSet_SetAirTicketRoutesFirst TMP
                                    INNER JOIN ( SELECT *
                                                 FROM   dbo.eAirTicketRouteDtl
                                                 WHERE  wType = 'AIRTICKET'
                                                        AND wTypeRid = @pBookingAirTicketRid
                                               ) DTL ON DTL.RowID = TMP.RowID
                                                        AND TMP.wType = 'PASSENGER';
                        END;
                        
		--- Update existing records
                    UPDATE  [dbo].[eAirTicketRouteDtl]
                    SET     [wPNRNo] = ISNULL(RTS.wPNRNo, '') ,
                            [wLine] = RTS.wLine ,
                            [wFlightType] = '' -- no more internation and domestic
                            ,
                            [wAirline] = RTS.wAirline ,
                            [wClassCd] = RTS.wClassCd ,
                            [wIsReturn] = RTS.wIsReturn ,
                            [wDepartFlightNo] = RTS.wDepartFlightNo ,
                            [wDepartureAirportRid] = RTS.wDepartureAirportRid ,
                            [wArrivalAirportRid] = RTS.wArrivalAirportRid ,
                            [wDepartureTerminal] = RTS.wDepartureTerminal ,
                            [wArrivalTerminal] = RTS.wArrivalTerminal ,
                            [wTakeOffDt] = RTS.[wTakeOffDt] ,
                            [wArrivalDt] = RTS.[wArrivalDt] ,
                            [wStatus] = RTS.wStatus ,
                            [wUpdDt] = dbo.fnUTC8Now() ,
                            [wUpdBy] = RTS.wUpdBy,
							[wIsWaiting]=ISNULL(RTS.wIsWaiting,DTL.wIsWaiting),
							[wExpiryDt]=RTS.wExpiryDt,
                            [wIsDestination] = RTS.wIsDestination
                    FROM    [dbo].[eAirTicketRouteDtl] DTL
                            INNER JOIN #DataSet_SetAirTicketRoutesFirst RTS ON DTL.RowID = RTS.RowID
                                                              AND RTS.RowID > 0;
                  --更新客戶航線的狀態
	               UPDATE  [dbo].[eAirTicketRouteDtl]
                    SET
                        wStatus = 'T',
                        wUpdBy = @sUpdatedBy ,
                        wUpdDt = dbo.fnUTC8Now()
                    FROM [dbo].[eAirTicketRouteDtl] DTL
                    INNER JOIN [dbo].[ePassengerDetails] p on p.RowID = DTL.wTypeRid
                    INNER JOIN [dbo].[eBookingAirTicket] t on t.wBookingRid = p.wBookingRid
                    LEFT JOIN #DataSet_SetAirTicketRoutesFirst tmp ON tmp.RowID = DTL.RowID
                    WHERE t.wBookingRid = @pBookingRid AND DTL.wType = 'PASSENGER' AND tmp.RowID IS NULL;


                    IF @pBookingType != 'PASSENGER'
                        BEGIN
			 --Soft Delete old records from eAirTicketRouteDtl table
                            UPDATE  RT
                            SET     RT.wStatus = 'T' ,
                                    RT.wUpdBy = @sUpdatedBy ,
                                    RT.wUpdDt = dbo.fnUTC8Now()
                            FROM    dbo.eAirTicketRouteDtl RT
                            WHERE   wType = 'AIRTICKET'
                                    AND wTypeRid = @pBookingAirTicketRid
                                    AND RowID NOT IN (
                                    SELECT  RowID
                                    FROM    #DataSet_SetAirTicketRoutesFirst
                                    WHERE   RowID > 0 );
                        END;
		
		-- Delete updated records
                    DELETE  FROM #DataSet_SetAirTicketRoutesFirst
                    WHERE   RowID > 0;		
		
		-- Set Action type to insert new records
                    SET @pActionType = 'I';
                END;
	
            INSERT  INTO #DataSet_SetAirTicketRoutes
                    ( RowID ,
                      wType ,
                      wTypeRid ,
                      wPNRNo ,
                      wLine ,
                      wFlightType ,
                      wAirline ,
                      wClassCd ,
                      wIsReturn ,
                      wDepartFlightNo ,
                      wDepartureAirportRid ,
                      wArrivalAirportRid ,
                      wDepartureTerminal ,
                      wArrivalTerminal ,
                      wTakeOffDt ,
                      wArrivalDt ,
                      wStatus ,
                      wCrtDt ,
                      wCrtBy ,
                      wUpdDt ,
                      wUpdBy,
					  wIsWaiting,
					  wExpiryDt,
                      wIsDestination
                    )
                    SELECT  RowID = ROW_NUMBER() OVER ( ORDER BY wTakeOffDt, wArrivalDt ) ,
                            wType ,
                            wTypeRid ,
                            wPNRNo ,
                            wLine ,
                            wFlightType ,
                            wAirline ,
                            wClassCd ,
                            wIsReturn ,
                            wDepartFlightNo ,
                            wDepartureAirportRid ,
                            wArrivalAirportRid ,
                            wDepartureTerminal ,
                            wArrivalTerminal ,
                            wTakeOffDt ,
                            wArrivalDt ,
                            wStatus ,
                            wCrtDt ,
                            wCrtBy ,
                            wUpdDt ,
                            wUpdBy,
							wIsWaiting,
							wExpiryDt,
                            wIsDestination
                    FROM    #DataSet_SetAirTicketRoutesFirst;

            IF @pBookingType != 'PASSENGER'
                BEGIN
                    UPDATE  DS
                    SET     DS.wTypeRid = PASS.RowID
                    FROM    #DataSet_SetAirTicketRoutes DS
                            INNER JOIN ( SELECT *
                                         FROM   dbo.ePassengerDetails
                                         WHERE  wBookingRid = @pBookingRid
                                                AND wStatus = 'A'
                                       ) PASS ON PASS.wSeqNo = DS.wTypeRid
                                                 AND DS.wType = 'PASSENGER'; -- to update Passenger rowId
                END;

	-- Insert new records
            IF @pActionType = 'I'
                BEGIN
                    SELECT  @sRecCount = COUNT(1)
                    FROM    #DataSet_SetAirTicketRoutes;  
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo,
                                'eAirTicketRouteDtl', @sRowID OUTPUT;
                            UPDATE  #DataSet_SetAirTicketRoutes
                            SET     RowID = @sRowID
                            WHERE   RowID = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;

                    UPDATE  atrd
                    SET     wStatus = 'T'
                    FROM    dbo.eAirTicketRouteDtl atrd
                            INNER JOIN #DataSet_SetAirTicketRoutes tmp ON tmp.wTypeRid = atrd.wTypeRid
                    WHERE   atrd.wType = 'PASSENGER'
                            AND atrd.wTypeRid > 0
                            AND atrd.wLine = tmp.wLine;

                    INSERT  INTO [dbo].[eAirTicketRouteDtl]
                            ( [RowID] ,
                              [wType] ,
                              [wTypeRid] ,
                              [wPNRNo] ,
                              [wLine] ,
                              [wFlightType] ,
                              [wAirline] ,
                              [wClassCd] ,
                              [wIsReturn] ,
                              [wDepartFlightNo] ,
                              [wDepartureAirportRid] ,
                              [wArrivalAirportRid] ,
                              [wDepartureTerminal] ,
                              [wArrivalTerminal] ,
                              [wTakeOffDt] ,
                              [wArrivalDt] ,
                              [wStatus] ,
                              [wCrtDt] ,
                              [wCrtBy] ,
                              [wUpdDt] ,
                              [wUpdBy],
							  [wIsWaiting],
							  [wExpiryDt],
                              [wIsDestination]
                            )
                            SELECT  [RowID] ,
                                    [wType] ,
                                    ( CASE WHEN [wType] = 'AIRTICKET'
                                           THEN @pBookingAirTicketRid
                                           ELSE [wTypeRid]
                                      END ) ,
                                    ISNULL([wPNRNo], '') ,
                                    [wLine] ,
                                    [wFlightType] = '' -- no more internation and domestic
                                    ,
                                    [wAirline] ,
                                    [wClassCd] ,
                                    [wIsReturn] ,
                                    [wDepartFlightNo] ,
                                    [wDepartureAirportRid] ,
                                    [wArrivalAirportRid] ,
                                    [wDepartureTerminal] ,
                                    [wArrivalTerminal] ,
                                    [wTakeOffDt] ,
                                    [wArrivalDt] ,
                                    [wStatus] ,
                                    dbo.fnUTC8Now() ,
                                    [wCrtBy] ,
                                    dbo.fnUTC8Now() ,
                                    [wUpdBy],
									ISNULL([wIsWaiting],'N'),
									[wExpiryDt],
                                    [wIsDestination]
                            FROM    #DataSet_SetAirTicketRoutes tmp;
                END;

				---------------------------------------------------------------------------------------------
				-- Update eBookingAirTicket Passenger string
				---------------------------------------------------------------------------------------------
				--DECLARE @sXMLeBookingAirTicket AS NVARCHAR(MAX) = '';

				--SET @sXMLeBookingAirTicket = (
				--SELECT
				--	bat.RowID, bat.wBookingRid, bat.wOrderNo, bat.wTravelAgencyRid, bat.wExpiryDt, bat.wQuantity, 
				--	bat.wExpAmt, bat.wTotalAmt, bat.wTotalCost, bat.wIsRefund, bat.wChangeTicket, bat.wPaymentMethod, 
				--	bat.wReceiptNo, bat.wCurrCode, bat.wAdditionalExp, bat.wPassengerStr, 
				--	wRouteStr, 
				--	bat.wStatus, 
				--	bat.wSeqNo, bat.wCrtDt, bat.wCrtBy, bat.wUpdDt, bat.wUpdBy, bat.wRemark, bat.wFlightType, 
				--	bat.wBookingStatus, bat.wUnqualifiedRid
				--FROM
				--	dbo.eBookingAirTicket bat
				--INNER JOIN
				--	#DataSet_SetAirTicketRoutes tmp ON tmp.wTypeRid = bat.RowID AND bat.wStatus = 'A' AND wType = 'AIRTICKET'
				--FOR XML RAW('Record') , ROOT('DataSet'));

    --            EXEC spa.SetBookingAirTicket  @sXMLeBookingAirTicket, -- xml
				--	'U',
    --                @pMainCompNo, -- int
    --                '', -- varchar(64)
    --                'N', -- char(1)
				--	@pBookingRid,
				--	0,
    --                0, -- int
    --                N''; -- nvarchar(200)   
				---------------------------------------------------------------------------------------------
				-- END Update eBookingAirTicket Passenger string
				---------------------------------------------------------------------------------------------

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END; 
				
	-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #DataSet_SetAirTicketRoutes;			      

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
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @vErrorNum, ') ',
                                  @vCatchErrorMessage);
			
            IF @sBeginTranCount = 0
                BEGIN
                    IF @xstate != 0
                        ROLLBACK;
                    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo,
                        @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT,
                        @vErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;

        END CATCH;
	
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#DataSet_SetAirTicketRoutes') IS NOT NULL
            DROP TABLE #DataSet_SetAirTicketRoutes;

        IF OBJECT_ID('tempdb..#DataSet_SetAirTicketRoutesFirst') IS NOT NULL
            DROP TABLE #DataSet_SetAirTicketRoutesFirst;
    END;