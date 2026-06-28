CREATE PROCEDURE [spa].[SetBookingHotel]
    @pXML               XML ,
    @pActionType        CHAR(1) , -- I/U/D  
    @pMainCompNo        INT ,
    @pNonceToken        VARCHAR(64) ,
    @pReturnResultSet   CHAR(1) = 'N' ,
    @pBookingRid        BIGINT ,
    @pBookingHotelRid   BIGINT OUTPUT ,
    @pErrCode           INT = 0 OUTPUT ,
    @pErrMsg            NVARCHAR(200) = '' OUTPUT
AS
    BEGIN  
        SET NOCOUNT ON;  

        DECLARE @sThisTableName     VARCHAR(50) = 'eBookingHotel' , -- For RowID             
                @sRecCount          INT = 0 ,
                @sRuningIndex       INT = 1 ,
                @sRowID             BIGINT = 0 ,
                @sRequestRID        BIGINT = 0 ,
                @sRoomNotArranged   INT = 0 ,
                @vNow               DATETIME2 = dbo.fnUTC8Now() ,
                @sActionAffectedXML NVARCHAR(MAX) = '' ,
                @sDocHandle         INT ,
                @sBeginTranCount    INT = 0;


        SET @sBeginTranCount = @@trancount;

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;  


        SELECT wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
               *
        INTO   #sDataSet_SetBookingHotel
        FROM   OPENXML (@sDocHandle, 'DataSet/Record', 1)
        WITH (
            RowID               BIGINT,
            wBookingRid         BIGINT,  
            wRequestRid         BIGINT,  
            wUseTravelAgency    CHAR(1),         
            wTravelAgencyRid    BIGINT,  
            wRoomInProgress     INT,  
            wRoomCompleted      INT,  
            wRoomNotArrange     INT,  
            wRoomCancelled      INT,  
            wRegion             VARCHAR(3),  
            wIsAgentHotel       CHAR(1),  
            wStartDate          DATE,  
            wEndDate            DATE,  
            wDayOfStay          INT,  
            wBedType            VARCHAR(3),  
            wPaymentMethod      VARCHAR(30),  
            wReceiptNo          NVARCHAR(50),  
            wRemark             NVARCHAR(500),  
            wSeqNo              INT,    
            wQuantity           INT,
            wUpdBy              BIGINT ,  
            wUpdDt              DATETIME2(7),
            wCounterRid         BIGINT,
            wSource             VARCHAR(30) -- CRM、SunTrip
        );  
        -- Get RequestRID of the booking
        SET @sRequestRID = ( SELECT TOP(1) wRequestRid FROM #sDataSet_SetBookingHotel );
        IF @sRequestRID > 0
        BEGIN
            SET @sRoomNotArranged = ISNULL(( SELECT hr.wNumberOfRoom - TotalRoomsAssigned
                                             FROM dbo.eHotelRequest hr
                                             INNER JOIN ( SELECT wHotelRequestRid,
                                                                 TotalRoomsAssigned = SUM(wTotalProvideRoomQty)
                                                          FROM dbo.eHotelRequestDtl
                                                          GROUP BY wHotelRequestRid
                                                    ) hrd ON hr.RowID = hrd.wHotelRequestRid
                                            WHERE  hrd.wHotelRequestRid = @sRequestRID),  0);
        END;

        BEGIN TRY
            -- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;

            IF @pActionType = 'I'
            BEGIN  
                -- Set RowID by Sequence  
                UPDATE  #sDataSet_SetBookingHotel SET RowID = 0;  
                SELECT  @sRecCount = COUNT(*) FROM #sDataSet_SetBookingHotel;  

                WHILE @sRuningIndex <= @sRecCount
                BEGIN  
                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;  

                    UPDATE  #sDataSet_SetBookingHotel
                    SET     RowID = @sRowID ,
                            wBookingRid = @pBookingRid
                    WHERE   wRowNum = @sRuningIndex;  

                    SET @sRuningIndex = @sRuningIndex + 1;  
                END;                
                SET @pBookingHotelRid = @sRowID;


                BEGIN
                    -- MAIN Logic here, example here is inserting dataset to eIOUPenalty  
                    INSERT  INTO dbo.[eBookingHotel]( 
                        [RowID] ,
                        [wBookingRid] ,
                        [wRequestRid] ,
                        [wUseTravelAgency] ,
                        [wTravelAgencyRid] ,
                        [wRoomInProgress] ,
                        [wRoomCompleted] ,
                        [wRoomNotArrange] ,
                        [wRoomCancelled] ,
                        [wRegion] ,
                        [wIsAgentHotel] ,
                        [wStartDate] ,
                        [wEndDate] ,
                        [wDayOfStay] ,
                        [wBedType] ,
                        [wPaymentMethod] ,
                        [wReceiptNo] ,
                        [wRemark] ,
                        [wSeqNo] ,
                        [wQuantity] ,
                        [wCrtBy] ,
                        [wCrtDt] ,
                        [wUpdBy] ,
                        [wUpdDt] ,
                        [wCounterRid] ,
                        [wSource]
                    )
                    SELECT s.RowID ,
                           s.wBookingRid ,
                           s.wRequestRid ,
                           s.wUseTravelAgency ,
                           s.wTravelAgencyRid ,
                           s.wRoomInProgress ,
                           s.wRoomCompleted ,
                           @sRoomNotArranged ,
                           s.wRoomCancelled ,
                           s.wRegion ,
                           s.wIsAgentHotel ,
                           s.wStartDate ,
                           s.wEndDate ,
                           s.wDayOfStay ,
                           s.wBedType ,
                           s.wPaymentMethod ,
                           s.wReceiptNo ,
                           s.wRemark ,
                           s.wSeqNo ,
                           s.wQuantity ,
                           s.wUpdBy ,
                           dbo.fnUTC8Now() ,
                           s.wUpdBy ,
                           dbo.fnUTC8Now() ,
                           s.wCounterRid,
                           ISNULL(NULLIF(s.wSource, ''), 'CRM')
                    FROM #sDataSet_SetBookingHotel s; 
                END; 
            END;  
            ELSE IF @pActionType = 'U'
            BEGIN  
                UPDATE  met
                SET     met.wUseTravelAgency = tmp.wUseTravelAgency ,
                        met.wTravelAgencyRid = tmp.wTravelAgencyRid ,
                        met.wRoomInProgress = tmp.wRoomInProgress ,
                        met.wRoomCompleted = tmp.wRoomCompleted ,
                        met.wRoomNotArrange = @sRoomNotArranged ,
                        met.wRoomCancelled = tmp.wRoomCancelled ,
                        met.wRegion = tmp.wRegion ,
                        met.wIsAgentHotel = tmp.wIsAgentHotel ,
                        met.wStartDate = tmp.wStartDate ,
                        met.wEndDate = tmp.wEndDate ,
                        met.wDayOfStay = tmp.wDayOfStay ,
                        met.wBedType = tmp.wBedType ,
                        met.wPaymentMethod = tmp.wPaymentMethod ,
                        met.wReceiptNo = tmp.wReceiptNo ,
                        met.wRemark = tmp.wRemark ,
                        met.wSeqNo = tmp.wSeqNo ,
                        met.wQuantity = tmp.wQuantity ,
                        met.wUpdBy = CASE WHEN tmp.wUpdBy IS NOT NULL AND tmp.wUpdBy > 0 THEN tmp.wUpdBy ELSE met.wUpdBy END ,
                        met.wUpdDt = dbo.fnUTC8Now() ,
                        met.wCounterRid = tmp.wCounterRid
                FROM    dbo.eBookingHotel AS met
                INNER JOIN #sDataSet_SetBookingHotel tmp ON met.RowID = tmp.RowID
                WHERE   met.RowID = tmp.RowID;
            END;

            ---------------------------------------------------------------------------------------------
            -- SetActionAffectedTableLog
            ---------------------------------------------------------------------------------------------
            SET @sActionAffectedXML = ( 
                SELECT  wActionSp = OBJECT_NAME(@@PROCID) ,
                        wActionType = @pActionType ,
                        wNonceToken = @pNonceToken ,
                        wRefTableName = @sThisTableName ,
                        wRefRid = tmp.RowID ,
                        wType = '' ,
                        wCrtDt = @vNow
                FROM #sDataSet_SetBookingHotel tmp
                FOR XML RAW('Record') , ROOT('DataSet') 
            );

            EXEC spa.SetActionAffectedTableLog @sActionAffectedXML, 'I', @pMainCompNo, '', 0, '';


            IF @sBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                COMMIT;
            END;

            -- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT RowID FROM #sDataSet_SetBookingHotel;


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

        IF OBJECT_ID('tempdb..#sDataSet_SetBookingHotel') IS NOT NULL
            DROP TABLE #sDataSet_SetBookingHotel;
    END