CREATE PROCEDURE [spa].[SetHotelRoomPricing]
    @pXML XML ,
    @pActionType CHAR(1) , -- I/U/D
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pReturnResultSet CHAR(1) = 'N',
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @vOldXML XML,
            @vNewXML XML;

    ---SELECT * FROM eHotelRoomPricing;
    DECLARE @cHotelRoomRid BIGINT,@cStartDate DATETIME;
    DECLARE @sThisTableName VARCHAR(50) = 'eHotelRoomPricing' , -- For RowID
    @sBeginTranCount INT = 0 ,@sRecCount INT = 0 ,@sRuningIndex INT = 1 ,@sRowID BIGINT = 0 ,@sDocHandle INT;
            
    DECLARE @sReturnRowID TABLE ( RowID BIGINT );

    SET @sBeginTranCount = @@trancount;
    SELECT  @pErrCode = 0 ,@pErrMsg = '';

    EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
                
    SELECT wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ),*
    INTO #sDataSet_SetHotelRoomPricing
    FROM OPENXML (@sDocHandle, 'DataSet/Record', 1)
    WITH (
        RowID BIGINT ,
        wHotelRoomRid BIGINT,
        wIsSpecialDate  CHAR(1),
        wStartDate DATE,
        wEndDate DATE,
        wCurrCode VARCHAR(6),
        wSunRoomPrice NUMERIC(18,4),
        wMonRoomPrice NUMERIC(18,4),
        wTueRoomPrice NUMERIC(18,4),
        wWedRoomPrice NUMERIC(18,4),
        wThuRoomPrice NUMERIC(18,4),
        wFriRoomPrice NUMERIC(18,4),
        wSatRoomPrice NUMERIC(18,4),
        wSunRoomCost NUMERIC(18,4),
        wMonRoomCost NUMERIC(18,4),
        wTueRoomCost NUMERIC(18,4),
        wWedRoomCost NUMERIC(18,4),
        wThuRoomCost NUMERIC(18,4),
        wFriRoomCost NUMERIC(18,4),
        wSatRoomCost NUMERIC(18,4),
        wSunBreakfastPrice NUMERIC(18,4),
        wMonBreakfastPrice NUMERIC(18,4),
        wTueBreakfastPrice NUMERIC(18,4),
        wWedBreakfastPrice NUMERIC(18,4),
        wThuBreakfastPrice NUMERIC(18,4),
        wFriBreakfastPrice NUMERIC(18,4),
        wSatBreakfastPrice NUMERIC(18,4),
        wMonExtraBedPrice NUMERIC(18,4),
        wTueExtraBedPrice NUMERIC(18,4),
        wWedExtraBedPrice NUMERIC(18,4),
        wThuExtraBedPrice NUMERIC(18,4),
        wFriExtraBedPrice NUMERIC(18,4),
        wSatExtraBedPrice NUMERIC(18,4),
        wSunExtraBedPrice NUMERIC(18,4),
        wSeqNo INT,
        wCrtDt DATETIME2(7),
        wCrtBy BIGINT,
        wUpdDt DATETIME2(7),
        wUpdBy BIGINT,
        wStatus CHAR(1)
    );

    SET @vOldXML = (
        SELECT hrp.*
        FROM dbo.eHotelRoomPricing hrp WITH(NOLOCK)
        INNER JOIN #sDataSet_SetHotelRoomPricing tmp ON tmp.RowID = hrp.RowID
        FOR XML RAW('Record'), ROOT('DataSet')
    );

    --- Leading Field Validation Start
    DECLARE @errorMsg VARCHAR(max);    
        IF  @pActionType IN ('I', 'U') BEGIN
                SELECT  @errorMsg = CASE 
                                WHEN ef.wHotelRoomRid < 0 THEN 'Room Name is Missing'
                                WHEN ef.wStartDate = '1/1/0001 12:00:00 AM' THEN 'End date is missing'
                                WHEN ef.wIsSpecialDate = 'Y' AND ef.wEndDate = '1/1/0001 12:00:00 AM' THEN 'Start date is missing'
                                WHEN  RTRIM(ISNULL(ef.wCurrCode,'')) = '' THEN 'Currency is Missing'
                                WHEN  RTRIM(ISNULL(ef.wStatus,' ')) = ' ' THEN 'Status is Missing'
                        END
            FROM #sDataSet_SetHotelRoomPricing ef
        END
    IF @errorMsg <> ''
        THROW 50001, @errorMsg, 1;
            --- Leading Field Validation end

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
            UPDATE  #sDataSet_SetHotelRoomPricing
            SET     RowID = 0;
            SELECT  @sRecCount = COUNT(*)
            FROM    #sDataSet_SetHotelRoomPricing;
            WHILE @sRuningIndex <= @sRecCount
            BEGIN
                EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                @sRowID OUTPUT;
                UPDATE  #sDataSet_SetHotelRoomPricing
                SET RowID = @sRowID
                WHERE   wRowNum = @sRuningIndex;
                SET @sRuningIndex = @sRuningIndex + 1;
             END;    
                            
            SELECT TOP 1 @cHotelRoomRid = wHotelRoomRid, @cStartDate = wStartDate FROM  #sDataSet_SetHotelRoomPricing WHERE wIsSpecialDate = 'N';

            UPDATE dbo.[eHotelRoomPricing] 
            SET wStatus = 'T'
            WHERE wHotelRoomRid = @cHotelRoomRid AND wStartDate >= @cStartDate AND wStatus = 'A' AND wIsSpecialDate = 'N';

            -- MAIN Logic here, example here is inserting dataset to eIOUPenalty
            INSERT  INTO dbo.[eHotelRoomPricing]
            (
                [RowID]
                ,[wHotelRoomRid]
                ,[wIsSpecialDate]
                ,[wStartDate]
                ,[wEndDate]
                ,[wCurrCode]
                ,[wSunRoomPrice]
                ,[wMonRoomPrice]
                ,[wTueRoomPrice]
                ,[wWedRoomPrice]
                ,[wThuRoomPrice]
                ,[wFriRoomPrice]
                ,[wSatRoomPrice]
                ,[wSunRoomCost]
                ,[wMonRoomCost]
                ,[wTueRoomCost]
                ,[wWedRoomCost]
                ,[wThuRoomCost]
                ,[wFriRoomCost]
                ,[wSatRoomCost]
                ,[wSunBreakfastPrice]
                ,[wMonBreakfastPrice]
                ,[wTueBreakfastPrice]
                ,[wWedBreakfastPrice]
                ,[wThuBreakfastPrice]
                ,[wFriBreakfastPrice]
                ,[wSatBreakfastPrice]
                ,[wSeqNo]
                ,[wCrtDt]
                ,[wCrtBy]
                ,[wUpdDt]
                ,[wUpdBy]
                ,[wStatus]
                ,[wMonExtraBedPrice]
                ,[wTueExtraBedPrice]
                ,[wWedExtraBedPrice]
                ,[wThuExtraBedPrice]
                ,[wFriExtraBedPrice]
                ,[wSatExtraBedPrice]
                ,[wSunExtraBedPrice]
                                
            )
            SELECT
                s.RowID
                ,s.wHotelRoomRid
                ,s.wIsSpecialDate
                ,s.wStartDate
                ,s.wEndDate
                ,s.wCurrCode
                ,s.wSunRoomPrice
                ,s.wMonRoomPrice
                ,s.wTueRoomPrice
                ,s.wWedRoomPrice
                ,s.wThuRoomPrice
                ,s.wFriRoomPrice
                ,s.wSatRoomPrice
                ,s.wSunRoomCost
                ,s.wMonRoomCost
                ,s.wTueRoomCost
                ,s.wWedRoomCost
                ,s.wThuRoomCost
                ,s.wFriRoomCost
                ,s.wSatRoomCost
                ,s.wSunBreakfastPrice
                ,s.wMonBreakfastPrice
                ,s.wTueBreakfastPrice
                ,s.wWedBreakfastPrice
                ,s.wThuBreakfastPrice
                ,s.wFriBreakfastPrice
                ,s.wSatBreakfastPrice
                ,s.wSeqNo
                ,dbo.fnUTC8Now()
                ,s.wUpdBy
                ,dbo.fnUTC8Now()
                ,s.wUpdBy
                ,s.wStatus
                ,s.wMonExtraBedPrice
                ,s.wTueExtraBedPrice
                ,s.wWedExtraBedPrice
                ,s.wThuExtraBedPrice
                ,s.wFriExtraBedPrice
                ,s.wSatExtraBedPrice
                ,s.wSunExtraBedPrice
            FROM #sDataSet_SetHotelRoomPricing s;
    END;
    IF @pActionType = 'U'
    BEGIN
        UPDATE  met
            SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
                met.wHotelRoomRid = tmp.wHotelRoomRid,
                met.wIsSpecialDate = tmp.wIsSpecialDate,
                met.wStartDate = tmp.wStartDate,
                met.wEndDate = tmp.wEndDate,
                met.wCurrCode = tmp.wCurrCode,
                met.wSunRoomPrice = tmp.wSunRoomPrice,
                met.wMonRoomPrice = tmp.wMonRoomPrice,
                met.wTueRoomPrice = tmp.wTueRoomPrice,
                met.wWedRoomPrice = tmp.wWedRoomPrice,
                met.wThuRoomPrice = tmp.wThuRoomPrice,
                met.wFriRoomPrice = tmp.wFriRoomPrice,
                met.wSatRoomPrice = tmp.wSatRoomPrice,
                met.wSunRoomCost = tmp.wSunRoomCost,
                met.wMonRoomCost = tmp.wMonRoomCost,
                met.wTueRoomCost = tmp.wTueRoomCost,
                met.wWedRoomCost = tmp.wWedRoomCost,
                met.wThuRoomCost = tmp.wThuRoomCost,
                met.wFriRoomCost = tmp.wFriRoomCost,
                met.wSatRoomCost = tmp.wSatRoomCost,
                met.wSunBreakfastPrice = tmp.wSunBreakfastPrice,
                met.wMonBreakfastPrice = tmp.wMonBreakfastPrice,
                met.wTueBreakfastPrice = tmp.wTueBreakfastPrice,
                met.wWedBreakfastPrice = tmp.wWedBreakfastPrice,
                met.wThuBreakfastPrice = tmp.wThuBreakfastPrice,
                met.wFriBreakfastPrice = tmp.wFriBreakfastPrice,
                met.wSatBreakfastPrice = tmp.wSatBreakfastPrice,
                met.wSeqNo = tmp.wSeqNo,
                met.wCrtDt = tmp.wCrtDt,
                met.wCrtBy = tmp.wCrtBy,
                met.wUpdDt = dbo.fnUTC8Now(),
                met.wUpdBy = tmp.wUpdBy,
                met.wStatus = tmp.wStatus,
                met.wMonExtraBedPrice  = tmp.wMonExtraBedPrice,
                met.wTueExtraBedPrice  = tmp.wTueExtraBedPrice,
                met.wWedExtraBedPrice  = tmp.wWedExtraBedPrice,
                met.wThuExtraBedPrice  = tmp.wThuExtraBedPrice,
                met.wFriExtraBedPrice  = tmp.wFriExtraBedPrice,
                met.wSatExtraBedPrice  = tmp.wSatExtraBedPrice,
                met.wSunExtraBedPrice  = tmp.wSunExtraBedPrice
            FROM    dbo.eHotelRoomPricing AS met
                    INNER JOIN #sDataSet_SetHotelRoomPricing tmp ON met.RowID = tmp.RowID
            WHERE   met.RowID = tmp.RowID;
    END;
    IF @pActionType = 'D'
    BEGIN
        UPDATE dbo.eHotelRoomPricing
            SET wStatus='T',
            wUpdDt = dbo.fnUTC8Now(),
            wUpdBy = (SELECT TOP 1 wUpdBy FROM #sDataSet_SetHotelRoomPricing)
        WHERE  RowID IN (SELECT RowID FROM #sDataSet_SetHotelRoomPricing);

        UPDATE ALT
            SET 
                wRoomPrice = 0,
                wBreakfastPrice =0,
                wRoomCost = 0
        FROM dbo.eAllotmentHotelDaily AS ALT
            INNER JOIN dbo.eHotelRoomPricing PRC ON PRC.wHotelRoomRid=ALT.wRoomRid
                            AND ALT.wDate >= PRC.wStartDate
                            AND ALT.wDate <= CAST(ISNULL(PRC.wEndDate, DATEADD(YEAR,1,PRC.wStartDate)) AS DATE)
                            AND ALT.wStatus='A'
            INNER JOIN #sDataSet_SetHotelRoomPricing TMP ON TMP.RowID=PRC.RowID
    END;

    UPDATE ALT
    SET 
        ALT.wRoomCost = ALLOTMENT.RoomCost,
        ALT.wBreakfastPrice = ALLOTMENT.BreakfastPrice,
        ALT.wRoomPrice = ALLOTMENT.RoomPrice,
        ALT.wExtraBedPrice = ALLOTMENT.ExtraBedPrice,
        ALT.wUpdBy = ALLOTMENT.wUpdBy,
        ALT.wUpdDt = dbo.fnUTC8Now()
    FROM dbo.eAllotmentHotelDaily ALT
        INNER JOIN (SELECT * FROM
                    (SELECT 
                    ISNULL(CASE DATEPART(dw,met.wDate) WHEN 1 THEN tmp.wSunRoomPrice
                        WHEN 2 THEN tmp.wMonRoomPrice
                        WHEN 3 THEN tmp.wTueRoomPrice
                        WHEN 4 THEN tmp.wWedRoomPrice
                        WHEN 5 THEN tmp.wThuRoomPrice
                        WHEN 6 THEN tmp.wFriRoomPrice
                        WHEN 7 THEN tmp.wSatRoomPrice
                        END,0) RoomPrice,
                    ISNULL(CASE DATEPART(dw,wDate) WHEN 1 THEN tmp.wSunBreakfastPrice
                        WHEN 2 THEN tmp.wMonBreakfastPrice
                        WHEN 3 THEN tmp.wTueBreakfastPrice
                        WHEN 4 THEN tmp.wWedBreakfastPrice
                        WHEN 5 THEN tmp.wThuBreakfastPrice
                        WHEN 6 THEN tmp.wFriBreakfastPrice
                        WHEN 7 THEN tmp.wSatBreakfastPrice
                        END,0) AS BreakfastPrice,
                    ISNULL(CASE DATEPART(dw,wDate) WHEN 1 THEN tmp.wSunRoomCost
                        WHEN 2 THEN tmp.wMonRoomCost
                        WHEN 3 THEN tmp.wTueRoomCost
                        WHEN 4 THEN tmp.wWedRoomCost
                        WHEN 5 THEN tmp.wThuRoomCost
                        WHEN 6 THEN tmp.wFriRoomCost
                        WHEN 7 THEN tmp.wSatRoomCost
                        END,0) AS RoomCost,
                    ISNULL(CASE DATEPART(dw, met.wDate) WHEN 1 THEN tmp.wSunExtraBedPrice 
                        WHEN 2 THEN tmp.wMonExtraBedPrice
                        WHEN 3 THEN tmp.wTueExtraBedPrice
                        WHEN 4 THEN tmp.wWedExtraBedPrice
                        WHEN 5 THEN tmp.wThuExtraBedPrice
                        WHEN 6 THEN tmp.wFriExtraBedPrice
                        WHEN 7 THEN tmp.wSatExtraBedPrice
                        END, 0) AS ExtraBedPrice,
                        met.wDate,
                        met.wRoomRid,
                        PRICE.wUpdBy,
                        ROW_NUMBER() OVER(PARTITION BY met.wRoomRid,met.wDate ORDER BY TMP.wUpdDt DESC) AS LetestRecord
                    FROM dbo.eAllotmentHotelDaily AS met
                        INNER JOIN (SELECT * FROM dbo.eHotelRoomPricing WHERE wStatus='A' AND wIsSpecialDate='N') tmp ON met.wRoomRid = tmp.wHotelRoomRid
                        INNER JOIN #sDataSet_SetHotelRoomPricing PRICE ON PRICE.wHotelRoomRid= tmp.wHotelRoomRid
                    WHERE met.wDate >= tmp.wStartDate
                        AND met.wDate <= CAST(ISNULL(tmp.wEndDate, '9999-12-31') AS DATE)
                        AND met.wStatus='A'    
                    ) ALLOTS WHERE ALLOTS.LetestRecord = 1
        ) ALLOTMENT ON ALLOTMENT.wRoomRid = ALT.wRoomRid AND ALLOTMENT.wDate = ALT.wDate;

    --Update met
    --        Set 
    --            wRoomPrice = ISNULL(CASE DATEPART(dw,met.wDate) WHEN 1 THEN tmp.wSunRoomPrice
    --                WHEN 2 THEN tmp.wMonRoomPrice
    --                WHEN 3 THEN tmp.wTueRoomPrice
    --                WHEN 4 THEN tmp.wWedRoomPrice
    --                WHEN 5 THEN tmp.wThuRoomPrice
    --                WHEN 6 THEN tmp.wFriRoomPrice
    --                WHEN 7 THEN tmp.wSatRoomPrice
    --                END,0),
    --            wBreakfastPrice =ISNULL(CASE DATEPART(dw,wDate) WHEN 1 THEN tmp.wSunBreakfastPrice
    --                WHEN 2 THEN tmp.wMonBreakfastPrice
    --                WHEN 3 THEN tmp.wTueBreakfastPrice
    --                WHEN 4 THEN tmp.wWedBreakfastPrice
    --                WHEN 5 THEN tmp.wThuBreakfastPrice
    --                WHEN 6 THEN tmp.wFriBreakfastPrice
    --                WHEN 7 THEN tmp.wSatBreakfastPrice
    --                END,0),
    --            wRoomCost = ISNULL(CASE DATEPART(dw,wDate) WHEN 1 THEN tmp.wSunRoomCost
    --                WHEN 2 THEN tmp.wMonRoomCost
    --                WHEN 3 THEN tmp.wTueRoomCost
    --                WHEN 4 THEN tmp.wWedRoomCost
    --                WHEN 5 THEN tmp.wThuRoomCost
    --                WHEN 6 THEN tmp.wFriRoomCost
    --                WHEN 7 THEN tmp.wSatRoomCost
    --                END,0),
    --                wUpdDt = dbo.fnUTC8Now(),
    --                wUpdBy = PRICE.wUpdBy
    --    FROM dbo.eAllotmentHotelDaily AS met
    --    INNER JOIN (SELECT * FROM dbo.eHotelRoomPricing WHERE wStatus='A' AND wIsSpecialDate='N') tmp ON met.wRoomRid = tmp.wHotelRoomRid
    --    INNER JOIN #sDataSet_SetHotelRoomPricing PRICE ON PRICE.wHotelRoomRid= tmp.wHotelRoomRid
    --    WHERE met.wDate >= tmp.wStartDate
    --        AND met.wDate <= CAST(ISNULL(tmp.wEndDate, DATEADD(YEAR,1,tmp.wStartDate)) AS DATE)
    --        AND met.wStatus='A'

    Update met
        Set 
            wRoomPrice = ISNULL(CASE DATEPART(dw,met.wDate) WHEN 1 THEN tmp.wSunRoomPrice
                WHEN 2 THEN tmp.wMonRoomPrice
                WHEN 3 THEN tmp.wTueRoomPrice
                WHEN 4 THEN tmp.wWedRoomPrice
                WHEN 5 THEN tmp.wThuRoomPrice
                WHEN 6 THEN tmp.wFriRoomPrice
                WHEN 7 THEN tmp.wSatRoomPrice
                END,0),
            wBreakfastPrice =ISNULL(CASE DATEPART(dw,wDate) WHEN 1 THEN tmp.wSunBreakfastPrice
                WHEN 2 THEN tmp.wMonBreakfastPrice
                WHEN 3 THEN tmp.wTueBreakfastPrice
                WHEN 4 THEN tmp.wWedBreakfastPrice
                WHEN 5 THEN tmp.wThuBreakfastPrice
                WHEN 6 THEN tmp.wFriBreakfastPrice
                WHEN 7 THEN tmp.wSatBreakfastPrice
                END,0),
            wRoomCost = ISNULL(CASE DATEPART(dw,wDate) WHEN 1 THEN tmp.wSunRoomCost
                WHEN 2 THEN tmp.wMonRoomCost
                WHEN 3 THEN tmp.wTueRoomCost
                WHEN 4 THEN tmp.wWedRoomCost
                WHEN 5 THEN tmp.wThuRoomCost
                WHEN 6 THEN tmp.wFriRoomCost
                WHEN 7 THEN tmp.wSatRoomCost
                END,0),
            wExtraBedPrice = ISNULL(CASE DATEPART(dw, met.wDate) WHEN 1 THEN tmp.wSunExtraBedPrice 
                WHEN 2 THEN tmp.wMonExtraBedPrice
                WHEN 3 THEN tmp.wTueExtraBedPrice
                WHEN 4 THEN tmp.wWedExtraBedPrice
                WHEN 5 THEN tmp.wThuExtraBedPrice
                WHEN 6 THEN tmp.wFriExtraBedPrice
                WHEN 7 THEN tmp.wSatExtraBedPrice
                END, 0),
            wUpdDt = dbo.fnUTC8Now(),
            wUpdBy = PRICE.wUpdBy
        FROM dbo.eAllotmentHotelDaily AS met
            INNER JOIN (SELECT * FROM dbo.eHotelRoomPricing WHERE wStatus='A' AND wIsSpecialDate='Y') tmp ON met.wRoomRid = tmp.wHotelRoomRid
            INNER JOIN #sDataSet_SetHotelRoomPricing PRICE ON PRICE.wHotelRoomRid = tmp.wHotelRoomRid
        WHERE met.wDate >= tmp.wStartDate
            AND met.wDate <= tmp.wEndDate
            AND met.wStatus='A'
    
    UPDATE CHK
        SET CHK.wPrice= ALT.wRoomPrice,
            CHK.wBreakfastPrice = IIF(BR.wIncludeBreakfast = 'Y', ALT.wBreakfastPrice, 0),
            CHK.wExtraBedPrice =  IIF(BR.wIsExtraBed = 'Y', ALT.wExtraBedPrice, 0),
            CHK.wCost = ALT.wRoomCost,
            wUpdDt = dbo.fnUTC8Now(),
            wUpdBy = PRICE.wUpdBy
        FROM dbo.eHotelCheckIn CHK
        INNER JOIN dbo.eAllotmentHotelDaily ALT ON ALT.wRoomRid=CHK.wRoomRid
        INNER JOIN #sDataSet_SetHotelRoomPricing PRICE ON PRICE.wHotelRoomRid = CHK.wRoomRid
            AND ALT.wDate=CHK.wBookingDate
            AND CHK.wStatus='A'
            AND ALT.wStatus='A'
        INNER JOIN dbo.eBookingRoom BR ON BR.RowID=CHK.wRoomBookingRid 
            AND BR.wBookingStatus='P'
            AND BR.wAllotmentGroupRid>0
            AND BR.wHotelRid>0

    UPDATE EBKR
        SET EBKR.wTotalAmount=UPD.RoomPrice,
            EBKR.wActualTotalAmount = (CASE WHEN (EBKR.wPaymentMethod='RC' OR EBKR.wPaymentMethod='GC' OR EBKR.wPaymentMethod='DA') THEN UPD.RoomPrice
                                            ELSE 0 END),
            EBKR.wTotalCost=UPD.Cost,
            wUpdDt = dbo.fnUTC8Now(),
            wUpdBy = (SELECT TOP 1 wUpdBy FROM #sDataSet_SetHotelRoomPricing)
        FROM dbo.eBookingRoom EBKR
        INNER JOIN (SELECT SUM(CK.wPrice + CK.wBreakfastPrice + CK.wExtraBedPrice) AS RoomPrice,SUM(CK.wCost + CK.wBreakfastPrice + CK.wExtraBedPrice) AS Cost,CK.wRoomBookingRid
            FROM dbo.eHotelCheckIn CK
            INNER JOIN dbo.eBookingRoom EBR ON CK.wRoomBookingRid=EBR.RowID
            INNER JOIN #sDataSet_SetHotelRoomPricing PRICE ON PRICE.wHotelRoomRid = CK.wRoomRid
                AND EBR.wBookingStatus='P'
                AND CK.wStatus='A'
            GROUP BY CK.wRoomBookingRid
        ) UPD ON UPD.wRoomBookingRid=EBKR.RowID
            AND EBKR.wBookingStatus='P'
            AND EBKR.wAllotmentGroupRid>0
            AND EBKR.wHotelRid>0


        -- 如果數據有修改，Sync到SUNTrip
        ------------------------------------------------------------------------------------------------------
        SET @vNewXML = (SELECT *, RecordState = @pActionType FROM #sDataSet_SetHotelRoomPricing FOR XML RAW('Record'), ROOT('DataSet'));
            
        EXEC spa.SUNTrip_SetHotelRoomPriceChange @pOldXML = @vOldXML,
                                                 @pNewXML = @vNewXML;
        ------------------------------------------------------------------------------------------------------

        IF @sBeginTranCount = 0 AND @@trancount > 0
        BEGIN
            COMMIT;
        END;
    
        -- Return RowID affected
        IF @pReturnResultSet = 'Y'
            SELECT  RowID
            FROM    #sDataSet_SetHotelRoomPricing;
        
    RETURN;
    END TRY
    BEGIN CATCH
            DECLARE @sErrorNum INT ,
                @sCatchErrorMessage NVARCHAR(4000) ,
                @xstate INT ,
                @sProcedureName VARCHAR(100) ,
                @sRtnCodeLog INT ,
                @sErrMessageLog NVARCHAR(4000);
      
    SELECT  @sErrorNum = ERROR_NUMBER() ,
                        @sCatchErrorMessage = ERROR_MESSAGE() ,
                        @xstate = XACT_STATE() ,
                        @sProcedureName = OBJECT_NAME(@@PROCID);
            
    IF ISNULL(@pErrCode, 0) = 0
    BEGIN
        SET @pErrCode = 999;
    END;
    SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ',
                                    @sCatchErrorMessage);
        
    IF @sBeginTranCount = 0 AND (@xstate = 1 OR @xstate = -1)
    BEGIN
        -- transaction created within this sp
        ROLLBACK;
    END;
        
    -- Write Log
    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName,
                @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
    END CATCH;

    EXEC sp_xml_removedocument @sDocHandle;    

    IF OBJECT_ID('tempdb..#sDataSet_SetHotelRoomPricing') IS NOT NULL DROP TABLE #sDataSet_SetHotelRoomPricing;
        
END;