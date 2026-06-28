CREATE PROCEDURE [spa].[SetBookingStatus]
    (
      @pRequestRid BIGINT ,
      @pUpdatedBy BIGINT ,
      @pHotelBookingRid BIGINT = -1 ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
    )
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sBeginTranCount INT = 0;

        SET @sBeginTranCount = @@trancount;

        BEGIN TRY

            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            DECLARE @roomCompleted INT= 0 ,
                @roomCancelled INT= 0 ,
                @roomUnQualified INT= 0 ,
                @RoomInProgress INT= 0;

            IF @pRequestRid > 0
                BEGIN
		
                    SELECT  @roomCompleted = COUNT(1)
                    FROM    dbo.eBookingRoom
                    WHERE   wRequestRid = @pRequestRid
                            AND wStatus = 'A'
                            AND ( wBookingStatus = 'C'
                                  OR wBookingStatus = 'CO'
                                  OR wBookingStatus = 'CI'
                                );
                    SELECT  @roomCancelled = COUNT(1)
                    FROM    dbo.eBookingRoom
                    WHERE   wRequestRid = @pRequestRid
                            AND wStatus = 'A'
                            AND ( wBookingStatus = 'CL'
                                  OR wBookingStatus = 'RF'
                                );
                    SELECT  @roomUnQualified = COUNT(1)
                    FROM    dbo.eBookingRoom
                    WHERE   wRequestRid = @pRequestRid
                            AND wStatus = 'A'
                            AND wBookingStatus = 'UQ';
                    SELECT  @RoomInProgress = COUNT(1)
                    FROM    dbo.eBookingRoom
                    WHERE   wRequestRid = @pRequestRid
                            AND wStatus = 'A'
                            AND wBookingStatus = 'P';

                    UPDATE  BKHTL
                    SET     wRoomCompleted = ISNULL(@roomCompleted, 0) ,
                            wRoomCancelled = ISNULL(@roomCancelled, 0) ,
                            wRoomUnQualified = ISNULL(@roomUnQualified, 0) ,
                            wRoomInProgress = ISNULL(@RoomInProgress, 0) ,
                            wUpdBy = CASE WHEN @pUpdatedBy IS NOT NULL AND @pUpdatedBy > 0 THEN @pUpdatedBy ELSE wUpdBy END,
                            wUpdDt = dbo.fnUTC8Now()
                    FROM    dbo.eBookingHotel BKHTL
                    WHERE   wRequestRid = @pRequestRid;

                    SELECT TOP 1
                            @roomCompleted = wRoomCompleted ,
                            @roomCancelled = wRoomCancelled ,
                            @roomUnQualified = wRoomUnQualified
                    FROM    dbo.eBookingHotel
                    WHERE   wRequestRid = @pRequestRid;

                    UPDATE  RST
                    SET     RST.wStatus = ( CASE WHEN @roomUnQualified >= 1 THEN 'PU'
                                                 WHEN RST.wNumberOfRoom = @roomCompleted THEN 'C'
                                                 WHEN RST.wNumberOfRoom = @roomCancelled THEN 'CL'
                                                 WHEN RST.wNumberOfRoom = @roomUnQualified THEN 'UQ'
                                                 WHEN @roomCompleted >= 1 AND @roomUnQualified = 0 THEN 'PC'
                                                 ELSE RST.wStatus
                                            END ) ,
                            wUpdBy = CASE WHEN @pUpdatedBy IS NOT NULL AND @pUpdatedBy > 0 THEN @pUpdatedBy ELSE wUpdBy END,
                            wUpdDt = dbo.fnUTC8Now()
                    FROM    dbo.eHotelRequest RST
                    WHERE   RowID = @pRequestRid;

                    UPDATE  HTB
                    SET     HTB.wBookingStatus = RST.wStatus
                    FROM    dbo.eBookingHotel HTB
                            INNER JOIN dbo.eHotelRequest RST ON HTB.wRequestRid = RST.RowID
                                                              AND RST.RowID = @pRequestRid;

                END;

            IF @pHotelBookingRid > 0
                AND @pRequestRid < 1
                BEGIN
		
                    SELECT  @roomCompleted = COUNT(1)
                    FROM    dbo.eBookingRoom
                    WHERE   wHotelBookingRid = @pHotelBookingRid
                            AND wStatus = 'A'
                            AND ( wBookingStatus = 'C'
                                  OR wBookingStatus = 'CI'
                                  OR wBookingStatus = 'CO'
                                );
                    SELECT  @roomCancelled = COUNT(1)
                    FROM    dbo.eBookingRoom
                    WHERE   wHotelBookingRid = @pHotelBookingRid
                            AND wStatus = 'A'
                            AND ( wBookingStatus = 'CL'
                                  OR wBookingStatus = 'RF'
                                );
                    SELECT  @roomUnQualified = COUNT(1)
                    FROM    dbo.eBookingRoom
                    WHERE   wHotelBookingRid = @pHotelBookingRid
                            AND wStatus = 'A'
                            AND wBookingStatus = 'UQ';
                    SELECT  @RoomInProgress = COUNT(1)
                    FROM    dbo.eBookingRoom
                    WHERE   wHotelBookingRid = @pHotelBookingRid
                            AND wStatus = 'A'
                            AND wBookingStatus = 'P';

                    UPDATE  BKHTL
                    SET     wRoomCompleted = ISNULL(@roomCompleted, 0) ,
                            wRoomCancelled = ISNULL(@roomCancelled, 0) ,
                            wRoomUnQualified = ISNULL(@roomUnQualified, 0) ,
                            wRoomInProgress = ISNULL(@RoomInProgress, 0) ,
                            wUpdBy = CASE WHEN @pUpdatedBy IS NOT NULL AND @pUpdatedBy > 0 THEN @pUpdatedBy ELSE wUpdBy END,
                            wUpdDt = dbo.fnUTC8Now()
                    FROM    dbo.eBookingHotel BKHTL
                    WHERE   RowID = @pHotelBookingRid;

                    SET @RoomInProgress = 0;
                    SET @roomCompleted = 0;
                    SET @roomCancelled = 0;
                    SET @roomUnQualified = 0;

                    SELECT TOP 1
                            @RoomInProgress = wRoomInProgress ,
                            @roomCompleted = wRoomCompleted ,
                            @roomCancelled = wRoomCancelled ,
                            @roomUnQualified = wRoomUnQualified
                    FROM    dbo.eBookingHotel
                    WHERE   RowID = @pHotelBookingRid;
                    DECLARE @sStatus VARCHAR(3)= 'P';

                    IF @roomCompleted > 0
                        OR @roomCancelled > 0
                        OR @roomUnQualified > 0
                        SET @sStatus = 'C';

                    IF @roomCompleted <= 0
                        AND @roomCancelled > 0
                        AND @roomUnQualified <= 0
                        BEGIN
                            SET @sStatus = 'CL';
                            DECLARE @sRoomRefunded INT= 0;
                            SELECT  @sRoomRefunded = COUNT(1)
                            FROM    dbo.eBookingRoom
                            WHERE   wHotelBookingRid = @pHotelBookingRid
                                    AND wStatus = 'A'
                                    AND wBookingStatus = 'RF';
			-- need t0 uncomment when hotel booking status have 'RF'
			--IF ISNULL(@roomCancelled,0)=ISNULL(@sRoomRefunded,0) SET @sStatus='RF';
                        END;

                    IF @roomCompleted <= 0
                        AND @roomCancelled <= 0
                        AND @roomUnQualified > 0
                        SET @sStatus = 'UQ';

                    -- 2019-04-28：OP#27921，"酒店預訂"訂單狀態顯示為完成, 需求狀態的才顯示為完成, 其他狀態都顯示為處理中
                    -------------------------------------------------------------------------------
                    DECLARE @vXML XML;

                    SET @vXML = (
                        SELECT RowID,
                               wNewBookingStatus = @sStatus,
                               wOldBookingStatus = wBookingStatus
                        FROM dbo.eBookingHotel 
                        WHERE RowID = @pHotelBookingRid
                        FOR XML RAW('Record'), ROOT('DataSet')
                    );

                    EXEC spa.SetDeptRoomRepStatus @pXML         = @vXML,
                                                  @pMainCompNo  = 10,
                                                  @pErrCode     = @pErrCode OUTPUT,
                                                  @pErrMsg      = @pErrMsg OUTPUT;
                    -------------------------------------------------------------------------------

                    UPDATE  HTB
                    SET     HTB.wBookingStatus = @sStatus ,
                            wUpdBy = CASE WHEN @pUpdatedBy IS NOT NULL AND @pUpdatedBy > 0 THEN @pUpdatedBy ELSE wUpdBy END,
                            HTB.wUpdDt = dbo.fnUTC8Now() ,
                            HTB.wSeqNo = @roomCancelled
                    FROM    dbo.eBookingHotel HTB
                    WHERE   RowID = @pHotelBookingRid;

                    UPDATE EB
                    SET    EB.wBookingStatus=HTB.wBookingStatus
                    FROM   dbo.eBooking EB
                           INNER JOIN dbo.eBookingHotel HTB ON EB.RowID=HTB.wBookingRid
                    WHERE  HTB.RowID = @pHotelBookingRid;
	
                END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

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
                    EXEC spa.WriteErrorLog 0, 0, @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT, @vErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;

        END CATCH;

    END;