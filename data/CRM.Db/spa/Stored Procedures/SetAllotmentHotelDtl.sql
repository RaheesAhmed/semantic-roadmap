CREATE PROCEDURE [spa].[SetAllotmentHotelDtl]
	(
	  @pXML XML ,
	  @pActionType CHAR(1) , -- I/U/D
	  @pMainCompNo INT,
	  @pNonceToken VARCHAR(64) ,
	  @pReturnResultSet CHAR(1) = 'N',
	  @pAllotmentHotelRid BIGINT,
	  @pErrCode INT = 0 OUTPUT ,
	  @pErrMsg NVARCHAR(200) = '' OUTPUT   	  	  
	)
AS
BEGIN
		SET NOCOUNT ON;
		--Select * from eAllotmentHotelDtl
		DECLARE @cHotelRid BIGINT,@cRoomRid BIGINT,@cStartDate DATETIME,@cUpdBy BIGINT;
		DECLARE @sThisTableName VARCHAR(50) = 'eAllotmentHotelDtl' , -- For RowID	
				@sChildTableName VARCHAR(50) = 'eAllotmentHotelDaily',
			@sRecCount INT = 0 ,
			@sRuningIndex INT = 1 ,
			@sRowID BIGINT = 0 ,
			@sChildRowID BIGINT = 0 ,
			@sDocHandle INT,
			@sBeginTranCount INT = 0;
			
		SET @sBeginTranCount = @@trancount;
		  
		DECLARE @sReturnRowID TABLE ( RowID BIGINT );
		
		EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
		
		--  
		SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ),*
		INTO #sDataSet_SetAllotmentHotelDtl
		FROM OPENXML (@sDocHandle, 'DataSet/SetAllotmentHotelDtlResult', 1)
		WITH (
				RowID BIGINT ,				
				wAllotmentHotelRid BiGINT,
				wAllotmentGroupRid BiGINT,
				wSunQty BiGINT,
				wMonQty BiGINT,
				wTueQty BiGINT,
				wWedQty BiGINT,
				wThuQty BiGINT,
				wFriQty BiGINT,
				wSatQty BiGINT,
				wSeqNo BiGINT,
				wUpdBy BIGINT ,
				wUpdDt DATETIME2(7)
			);
		
		DECLARE @sUpdBy BIGINT=0;
		
		SELECT @sUpdBy=wUpdBy FROM dbo.eAllotmentHotel WHERE RowID=@pAllotmentHotelRid;

		BEGIN TRY
		-- Try to make the transaction scope as small as possible to reduce locking
		IF @sBeginTranCount = 0
			BEGIN
				BEGIN TRAN;
			END;

		IF @pActionType = 'U'
		BEGIN
			SELECT * INTO #sSpecialPeriodData
				FROM (SELECT ALTN.wStartDate,ALTN.wEndDate,ALTDN.wAllotmentGroupRid,ALTN.wRoomRid
					FROM (SELECT * FROM dbo.eAllotmentHotel WHERE wStatus='A' AND wIsSpecialDate='Y'
						AND wRoomRid IN (SELECT wRoomRid FROM dbo.eAllotmentHotel WHERE RowID=@pAllotmentHotelRid)) ALTN
				INNER JOIN dbo.eAllotmentHotelDtl ALTDN ON ALTDN.wAllotmentHotelRid=ALTN.RowID) y;

			DECLARE @sIsSpecialPeriodDate CHAR(1)=(SELECT TOP 1 wIsSpecialDate FROM dbo.eAllotmentHotel WHERE RowID=@pAllotmentHotelRid);
			DECLARE @sAllotmentGroupId BIGINT=0;
			IF @sIsSpecialPeriodDate='Y'
			BEGIN
				SELECT TOP 1 @sAllotmentGroupId=AHD.wAllotmentGroupRid
				FROM dbo.[eAllotmentHotelDaily] AS AHD
				INNER JOIN dbo.eAllotmentHotel ALT ON ALT.wRoomRid=AHD.wRoomRid						
					AND AHD.wStatus='A'
					AND ALT.wStatus='A'
					AND ALT.wIsSpecialDate='Y'
					AND ALT.RowID=@pAllotmentHotelRid
					AND AHD.wDate BETWEEN ALT.wStartDate AND ALT.wEndDate
					AND AHD.wBookedQty > 0 
						INNER JOIN dbo.eAllotmentHotelDtl ALTDTL ON ALTDTL.wAllotmentHotelRid=ALT.RowID
					AND ALTDTL.wAllotmentGroupRid=AHD.wAllotmentGroupRid;
			END;
			ELSE
			BEGIN
				SELECT TOP 1 @sAllotmentGroupId=AHD.wAllotmentGroupRid
					FROM dbo.[eAllotmentHotelDaily] AS AHD
					INNER JOIN dbo.eAllotmentHotel ALT ON ALT.wRoomRid=AHD.wRoomRid				
					AND AHD.wStatus='A'
					AND ALT.wStatus='A'
					AND ALT.wIsSpecialDate='N'
					AND ALT.RowID=@pAllotmentHotelRid
					AND AHD.wDate BETWEEN ALT.wStartDate AND CAST(DATEADD(DAY,-1,CAST(DATEADD(YEAR,1,wStartDate) AS DATE)) AS DATE)
					AND AHD.wBookedQty>0
					INNER JOIN dbo.eAllotmentHotelDtl ALTDTL ON ALTDTL.wAllotmentHotelRid=ALT.RowID 
					AND ALTDTL.wAllotmentGroupRid=AHD.wAllotmentGroupRid
					AND (
							(AHD.wAllotmentGroupRid IN (SELECT wAllotmentGroupRid FROM #sSpecialPeriodData WHERE wAllotmentGroupRid=AHD.wAllotmentGroupRid)
							AND (AHD.wDate < (SELECT TOP 1 wStartDate FROM #sSpecialPeriodData WHERE wAllotmentGroupRid=AHD.wAllotmentGroupRid)
								OR AHD.wDate > (SELECT TOP 1 wEndDate FROM #sSpecialPeriodData WHERE wAllotmentGroupRid=AHD.wAllotmentGroupRid))
						)
						OR (AHD.wAllotmentGroupRid NOT IN (SELECT wAllotmentGroupRid FROM #sSpecialPeriodData WHERE wAllotmentGroupRid=AHD.wAllotmentGroupRid))
						);
			END;

			/*IF @sAllotmentGroupId>0
			BEGIN
				DECLARE @errorMessage VARCHAR(100)= (SELECT TOP 1 wName FROM dbo.mAllotmentGroup WHERE RowID=@sAllotmentGroupId);
				RAISERROR (@errorMessage,16,5);
			END*/

			IF @sIsSpecialPeriodDate='Y'
			BEGIN
				SELECT * INTO #sNormalPeriodData
				FROM (SELECT ALTN.wStartDate,CAST(DATEADD(DAY,-1,CAST(DATEADD(YEAR,1,ALTN.wStartDate) AS DATE)) AS DATE) AS wEndDate,ALTDN.wAllotmentGroupRid,ALTN.wRoomRid
					FROM (SELECT * FROM dbo.eAllotmentHotel WHERE wStatus='A' AND wIsSpecialDate='N'
						AND wRoomRid IN (SELECT TOP 1 wRoomRid FROM dbo.eAllotmentHotel WHERE RowID=@pAllotmentHotelRid)) ALTN
					INNER JOIN dbo.eAllotmentHotelDtl ALTDN ON ALTDN.wAllotmentHotelRid=ALTN.RowID) x;
			    
                /*IF (SELECT COUNT(1)
                  FROM dbo.eAllotmentHotelDaily DLY
                  INNER JOIN  dbo.eHotelCheckIn AS e ON DLY.wRoomRid = e.wRoomRid AND DLY.wAllotmentGroupRid = e.wAllotmentGroupRid  AND DLY.wDate = e.wBookingDate AND e.wStatus = 'A' 
                  INNER JOIN dbo.eBookingRoom AS room ON e.wRoomBookingRid=room.RowID AND room.wBookingStatus !='P' 
				  INNER JOIN (SELECT * FROM dbo.eAllotmentHotel WHERE RowID=@pAllotmentHotelRid) ALT ON ALT.wRoomRid=DLY.wRoomRid                      
				  INNER JOIN (SELECT * FROM dbo.eAllotmentHotelDtl DTL 
                                       WHERE DTL.wAllotmentHotelRid = @pAllotmentHotelRid
					                    AND DTL.wAllotmentGroupRid NOT IN (SELECT wAllotmentGroupRid FROM #sDataSet_SetAllotmentHotelDtl)
				             ) ALTDTL ON ALTDTL.wAllotmentGroupRid=DLY.wAllotmentGroupRid
				                      AND DLY.wDate BETWEEN ALT.wStartDate AND ALT.wEndDate
				                      AND ALT.wIsSpecialDate = 'Y'
				                      AND DLY.wIsCustomized = 'N'
				                      AND ((DLY.wAllotmentGroupRid IN (SELECT wAllotmentGroupRid FROM #sNormalPeriodData WHERE wAllotmentGroupRid=DLY.wAllotmentGroupRid)
							          AND (DLY.wDate < (SELECT TOP 1 wStartDate FROM #sNormalPeriodData WHERE wAllotmentGroupRid=DLY.wAllotmentGroupRid)
								           OR DLY.wDate > (SELECT TOP 1 wEndDate FROM #sNormalPeriodData WHERE wAllotmentGroupRid=DLY.wAllotmentGroupRid)))
                                           OR (DLY.wAllotmentGroupRid NOT IN (SELECT wAllotmentGroupRid FROM #sNormalPeriodData WHERE wAllotmentGroupRid=DLY.wAllotmentGroupRid)))                                   
                 )>0
                BEGIN
                SET @pErrMsg=dbo.fnGetErroMsg('3001','zh-TW');
                    THROW 50001, @pErrMsg, 1;
                END;*/

				UPDATE DLY
					SET DLY.wStatus='T',
						DLY.wUpdDt=dbo.fnUTC8Now(),
						DLY.wUpdBy=@sUpdBy
				FROM dbo.eAllotmentHotelDaily DLY
				INNER JOIN (SELECT * FROM dbo.eAllotmentHotel WHERE RowID=@pAllotmentHotelRid) ALT ON ALT.wRoomRid=DLY.wRoomRid
				INNER JOIN (SELECT *
					FROM dbo.eAllotmentHotelDtl DTL
					WHERE DTL.wAllotmentHotelRid = @pAllotmentHotelRid
					AND DTL.wAllotmentGroupRid NOT IN (SELECT wAllotmentGroupRid FROM #sDataSet_SetAllotmentHotelDtl)
				) ALTDTL ON ALTDTL.wAllotmentGroupRid=DLY.wAllotmentGroupRid
				AND DLY.wDate BETWEEN wStartDate AND wEndDate
				AND ALT.wIsSpecialDate = 'Y'
				AND DLY.wIsCustomized = 'N'
				AND ((DLY.wAllotmentGroupRid IN (SELECT wAllotmentGroupRid FROM #sNormalPeriodData WHERE wAllotmentGroupRid=DLY.wAllotmentGroupRid)
							AND (DLY.wDate < (SELECT TOP 1 wStartDate FROM #sNormalPeriodData WHERE wAllotmentGroupRid=DLY.wAllotmentGroupRid)
								OR DLY.wDate > (SELECT TOP 1 wEndDate FROM #sNormalPeriodData WHERE wAllotmentGroupRid=DLY.wAllotmentGroupRid))
						)
						OR (DLY.wAllotmentGroupRid NOT IN (SELECT wAllotmentGroupRid FROM #sNormalPeriodData WHERE wAllotmentGroupRid=DLY.wAllotmentGroupRid))
				);

				IF OBJECT_ID('tempdb..##sNormalPeriodData') IS NOT NULL DROP TABLE #sNormalPeriodData;
			END
			ELSE
			BEGIN

                /*IF (SELECT COUNT(1)
                  FROM dbo.eAllotmentHotelDaily DLY
                  INNER JOIN  dbo.eHotelCheckIn AS e ON DLY.wRoomRid = e.wRoomRid AND DLY.wAllotmentGroupRid = e.wAllotmentGroupRid  AND DLY.wDate = e.wBookingDate AND e.wStatus = 'A' 
                  INNER JOIN dbo.eBookingRoom AS room ON e.wRoomBookingRid=room.RowID AND room.wBookingStatus !='P' 
				  INNER JOIN (SELECT * FROM dbo.eAllotmentHotel WHERE RowID=@pAllotmentHotelRid)ALT ON ALT.wRoomRid=DLY.wRoomRid
				  INNER JOIN (SELECT * FROM dbo.eAllotmentHotelDtl DTL
								       WHERE DTL.wAllotmentHotelRid = @pAllotmentHotelRid
								         AND DTL.wAllotmentGroupRid NOT IN (SELECT wAllotmentGroupRid FROM #sDataSet_SetAllotmentHotelDtl)
                             ) ALTDTL ON ALTDTL.wAllotmentGroupRid=DLY.wAllotmentGroupRid 
                                      AND DLY.wDate BETWEEN ALT.wStartDate AND CAST(DATEADD(DAY,-1,CAST(DATEADD(YEAR,1,ALT.wStartDate) AS DATE)) AS DATE)
						              AND ALT.wIsSpecialDate='N'
						              AND DLY.wIsCustomized = 'N'
						              AND ((DLY.wAllotmentGroupRid IN (SELECT wAllotmentGroupRid FROM #sSpecialPeriodData WHERE wAllotmentGroupRid=DLY.wAllotmentGroupRid)
							                AND (DLY.wDate < (SELECT TOP 1 wStartDate FROM #sSpecialPeriodData WHERE wAllotmentGroupRid=DLY.wAllotmentGroupRid) 
                                            OR DLY.wDate > (SELECT TOP 1 wEndDate FROM #sSpecialPeriodData WHERE wAllotmentGroupRid=DLY.wAllotmentGroupRid)))
							                OR (DLY.wAllotmentGroupRid NOT IN (SELECT wAllotmentGroupRid FROM #sSpecialPeriodData WHERE wAllotmentGroupRid=DLY.wAllotmentGroupRid)))                                   
                 )>0
                BEGIN
                SET @pErrMsg=dbo.fnGetErroMsg('3001','zh-TW');
                    THROW 50001, @pErrMsg, 1;
                END;*/
                           
				UPDATE DLY
				SET DLY.wStatus='T',
					DLY.wUpdDt=dbo.fnUTC8Now(),
					DLY.wUpdBy=@sUpdBy FROM dbo.eAllotmentHotelDaily DLY
					INNER JOIN (SELECT * FROM dbo.eAllotmentHotel WHERE RowID=@pAllotmentHotelRid)ALT ON ALT.wRoomRid=DLY.wRoomRid
					INNER JOIN (SELECT *
								FROM dbo.eAllotmentHotelDtl DTL
								WHERE DTL.wAllotmentHotelRid = @pAllotmentHotelRid
								AND DTL.wAllotmentGroupRid NOT IN (SELECT wAllotmentGroupRid FROM #sDataSet_SetAllotmentHotelDtl)) ALTDTL 
						ON ALTDTL.wAllotmentGroupRid=DLY.wAllotmentGroupRid AND DLY.wDate BETWEEN wStartDate AND CAST(DATEADD(DAY,-1,CAST(DATEADD(YEAR,1,wStartDate) AS DATE)) AS DATE)
						  AND ALT.wIsSpecialDate='N'
						  AND DLY.wIsCustomized = 'N'
						  AND (
							(DLY.wAllotmentGroupRid IN (SELECT wAllotmentGroupRid FROM #sSpecialPeriodData WHERE wAllotmentGroupRid=DLY.wAllotmentGroupRid)
							 AND (DLY.wDate < (SELECT TOP 1 wStartDate FROM #sSpecialPeriodData WHERE wAllotmentGroupRid=DLY.wAllotmentGroupRid) OR DLY.wDate > (SELECT TOP 1 wEndDate FROM #sSpecialPeriodData WHERE wAllotmentGroupRid=DLY.wAllotmentGroupRid)))
							 OR (DLY.wAllotmentGroupRid NOT IN (SELECT wAllotmentGroupRid FROM #sSpecialPeriodData WHERE wAllotmentGroupRid=DLY.wAllotmentGroupRid))
							);
				IF (SELECT COUNT(1) FROM #sDataSet_SetAllotmentHotelDtl) > 0
				BEGIN
					SELECT TOP 1 @cHotelRid = wHotelRid, @cRoomRid = wRoomRid, @cStartDate = wStartDate,@cUpdBy = wUpdBy FROM  dbo.eAllotmentHotel WHERE RowID=@pAllotmentHotelRid;
					UPDATE dbo.[eAllotmentHotel] 
						SET wStatus = 'T',wUpdDt=dbo.fnUTC8Now(),wUpdBy=@cUpdBy
						WHERE wHotelRid = @cHotelRid AND wRoomRid = @cRoomRid  AND wStartDate >= @cStartDate AND wStatus = 'A' AND wIsSpecialDate = 'N' AND RowId <> @pAllotmentHotelRid;

					--restore daily record that date is in range if exist
					UPDATE AHD 
						SET	[wStatus]='A', [wUpdDt]=dbo.fnUTC8Now(),[wUpdBy]=@sUpdBy
					FROM dbo.[eAllotmentHotelDaily] AHD
					INNER JOIN dbo.eAllotmentHotel ALT ON ALT.wRoomRid=AHD.wRoomRid	AND ALT.wIsSpecialDate = 'N' AND ALT.RowId = @pAllotmentHotelRid
					INNER JOIN dbo.eAllotmentHotelDtl ALTDTL ON ALTDTL.wAllotmentHotelRid=ALT.RowID	AND ALTDTL.wAllotmentGroupRid=AHD.wAllotmentGroupRid
					WHERE wDate >= (SELECT MIN(wStartDate) FROM dbo.eAllotmentHotel h INNER JOIN dbo.eAllotmentHotelDtl d ON d.wAllotmentHotelRid=h.RowID
								WHERE wHotelRid = (SELECT TOP 1 wHotelRid FROM dbo.eAllotmentHotel WHERE RowId = @pAllotmentHotelRid)
								AND wRoomRid = (SELECT TOP 1 wRoomRid FROM dbo.eAllotmentHotel WHERE RowId = @pAllotmentHotelRid)
								AND wStatus = 'A')
						AND wDate <= (SELECT DATEADD(DAY,-1,DATEADD(YEAR,1,MAX(wStartDate))) FROM dbo.eAllotmentHotel h INNER JOIN dbo.eAllotmentHotelDtl d ON d.wAllotmentHotelRid=h.RowID
									WHERE wHotelRid = (SELECT TOP 1 wHotelRid FROM dbo.eAllotmentHotel WHERE RowId = @pAllotmentHotelRid)
									AND wRoomRid = (SELECT TOP 1 wRoomRid FROM dbo.eAllotmentHotel WHERE RowId = @pAllotmentHotelRid)
									AND wStatus = 'A')
						AND AHD.wIsCustomized = 'N'
				END
			END

			IF OBJECT_ID('tempdb..##sSpecialPeriodData') IS NOT NULL DROP TABLE #sSpecialPeriodData;

			DELETE eAllotmentHotelDtl WHERE wAllotmentHotelRid = @pAllotmentHotelRid;
		END

		-- Set RowID by Sequence
		UPDATE  #sDataSet_SetAllotmentHotelDtl
		SET     RowID = 0;
		SELECT  @sRecCount = COUNT(*)
		FROM    #sDataSet_SetAllotmentHotelDtl;
		WHILE @sRuningIndex <= @sRecCount
			BEGIN
				EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
				UPDATE  #sDataSet_SetAllotmentHotelDtl
				SET     RowID = @sRowID,
						wAllotmentHotelRid = @pAllotmentHotelRid		
				WHERE   wRowNum = @sRuningIndex;

				DECLARE @sStartDate DATE,
						@sDate DATE,
						@sEndDate DATE,
						@sNowDate DATE = CAST(GETDATE() AS DATE),
						@sRoomRid BIGINT,
						@sCurCode VARCHAR(6),
						@sRoomPrice NUMERIC(18,4) = 0,
						@sBreakfastPrice NUMERIC(18,4) = 0,
						@sRoomCost NUMERIC(18,4) = 0,
						@sExtraBedPrice NUMERIC(18, 4) = 0,
						@wAllotmentGroupRid BIGINT = 0,
						@sRecordCnt INT = 0,
						@sIsSpecialDate CHAR(1)='N';
							
				SELECT TOP 1 @wAllotmentGroupRid = wAllotmentGroupRid FROM #sDataSet_SetAllotmentHotelDtl WHERE wRowNum = @sRuningIndex;
				SELECT @sStartDate = wStartDate,
						@sEndDate = CAST(ISNULL(wEndDate,DATEADD(YEAR,1, CASE WHEN wStartDate < @sNowDate THEN @sNowDate ELSE wStartDate END)) AS DATE),
						@sCurCode = h.wCurrCode,
						@sRoomRid = wRoomRid,
						@sIsSpecialDate=wIsSpecialDate
				FROM dbo.eAllotmentHotel ah
				INNER JOIN dbo.mHotel h on h.RowID = ah.wHotelRid  WHERE ah.RowID = @pAllotmentHotelRid
							
				IF @sIsSpecialDate='N' SET @sEndDate=DATEADD(DAY,-1,@sEndDate);

				SET @sDate = @sStartDate;
													
				WHILE @sDate <= @sEndDate
				BEGIN
					SET @sRoomPrice = 0;
					SET @sBreakfastPrice = 0;
					SET @sRoomCost = 0;
					SET @sExtraBedPrice = 0;
					SET @sRecordCnt = 0;
					
					SELECT @sRecordCnt = COUNT (1)
						FROM dbo.eHotelRoomPricing WHERE wHotelRoomRid = @sRoomRid AND @sDate BETWEEN wStartDate AND wEndDate AND wIsSpecialDate='Y' AND wStatus='A';

					SELECT TOP 1 @sRoomPrice = ISNULL(CASE DATEPART(dw,@sDate) WHEN 1 THEN wSunRoomPrice
						WHEN 2 THEN wMonRoomPrice
						WHEN 3 THEN wTueRoomPrice
						WHEN 4 THEN wWedRoomPrice
						WHEN 5 THEN wThuRoomPrice
						WHEN 6 THEN wFriRoomPrice
						WHEN 7 THEN wSatRoomPrice
						END,0),
					@sBreakfastPrice = ISNULL(CASE DATEPART(dw,@sDate) WHEN 1 THEN wSunBreakfastPrice
						WHEN 2 THEN wMonBreakfastPrice
						WHEN 3 THEN wTueBreakfastPrice
						WHEN 4 THEN wWedBreakfastPrice
						WHEN 5 THEN wThuBreakfastPrice
						WHEN 6 THEN wFriBreakfastPrice
						WHEN 7 THEN wSatBreakfastPrice
						END,0),
					@sRoomCost = ISNULL(CASE DATEPART(dw,@sDate) WHEN 1 THEN wSunRoomCost
						WHEN 2 THEN wMonRoomCost
						WHEN 3 THEN wTueRoomCost
						WHEN 4 THEN wWedRoomCost
						WHEN 5 THEN wThuRoomCost
						WHEN 6 THEN wFriRoomCost
						WHEN 7 THEN wSatRoomCost
						END,0),
					@sExtraBedPrice = ISNULL(CASE DATEPART(dw, @sDate) WHEN 1 THEN wSunExtraBedPrice 
						WHEN 2 THEN wMonExtraBedPrice
						WHEN 3 THEN wTueExtraBedPrice
						WHEN 4 THEN wWedExtraBedPrice
						WHEN 5 THEN wThuExtraBedPrice
						WHEN 6 THEN wFriExtraBedPrice
						WHEN 7 THEN wSatExtraBedPrice
						END, 0)
					FROM dbo.eHotelRoomPricing WHERE wHotelRoomRid = @sRoomRid AND @sDate BETWEEN wStartDate AND wEndDate AND wIsSpecialDate='Y' AND wStatus='A' ORDER BY wUpdDt DESC;

					IF (@sRecordCnt) <= 0
					BEGIN
						SELECT TOP 1 @sRoomPrice = ISNULL(CASE DATEPART(dw,@sDate) WHEN 1 THEN wSunRoomPrice
							WHEN 2 THEN wMonRoomPrice
							WHEN 3 THEN wTueRoomPrice
							WHEN 4 THEN wWedRoomPrice
							WHEN 5 THEN wThuRoomPrice
							WHEN 6 THEN wFriRoomPrice
							WHEN 7 THEN wSatRoomPrice
							END,0),
						@sBreakfastPrice = ISNULL(CASE DATEPART(dw,@sDate) WHEN 1 THEN wSunBreakfastPrice
							WHEN 2 THEN wMonBreakfastPrice
							WHEN 3 THEN wTueBreakfastPrice
							WHEN 4 THEN wWedBreakfastPrice
							WHEN 5 THEN wThuBreakfastPrice
							WHEN 6 THEN wFriBreakfastPrice
							WHEN 7 THEN wSatBreakfastPrice
							END,0),
						@sRoomCost = ISNULL(CASE DATEPART(dw,@sDate) WHEN 1 THEN wSunRoomCost
							WHEN 2 THEN wMonRoomCost
							WHEN 3 THEN wTueRoomCost
							WHEN 4 THEN wWedRoomCost
							WHEN 5 THEN wThuRoomCost
							WHEN 6 THEN wFriRoomCost
							WHEN 7 THEN wSatRoomCost
							END,0),
						@sExtraBedPrice = ISNULL(CASE DATEPART(dw, @sDate) WHEN 1 THEN wSunExtraBedPrice 
							WHEN 2 THEN wMonExtraBedPrice
							WHEN 3 THEN wTueExtraBedPrice
							WHEN 4 THEN wWedExtraBedPrice
							WHEN 5 THEN wThuExtraBedPrice
							WHEN 6 THEN wFriExtraBedPrice
							WHEN 7 THEN wSatExtraBedPrice
                            END, 0)
						FROM dbo.eHotelRoomPricing 
						WHERE wHotelRoomRid = @sRoomRid AND 
							  (@sDate BETWEEN wStartDate AND ISNULL(wEndDate, '9999-12-31')) AND wIsSpecialDate='N' AND wStatus='A' 
						ORDER BY wUpdDt DESC;
					END
								
					IF EXISTS(SELECT 1 FROM dbo.[eAllotmentHotelDaily] WITH(NOLOCK) WHERE wRoomRid = @sRoomRid AND [wDate] = @sDate AND wAllotmentGroupRid = @wAllotmentGroupRid AND wStatus = 'A')
					BEGIN
						--PRINT 'Record Exists'
						UPDATE ahd
							SET
							[wRoomPrice] = @sRoomPrice,
							[wRoomCost] = @sRoomCost,
							[wBreakfastPrice] = @sBreakfastPrice,
							[wExtraBedPrice] = @sExtraBedPrice,
							[wCurrCode]	= @sCurCode,
							[wUpdDt] = dbo.fnUTC8Now(),
							[wUpdBy] = @sUpdBy
							FROM dbo.[eAllotmentHotelDaily] AS ahd
							WHERE ahd.wRoomRid = @sRoomRid 
								AND ahd.[wDate] = @sDate 
								AND ahd.wAllotmentGroupRid = @wAllotmentGroupRid 
								AND ahd.wStatus = 'A' 
								AND ahd.wIsCustomized = 'N'--#35462
					END
					ELSE
					BEGIN
						EXEC spq.GetRowID @pMainCompNo, @sChildTableName,@sChildRowID OUTPUT;								
						-----------------------------------------------
						INSERT INTO dbo.[eAllotmentHotelDaily]
						(
							[RowId],
							[wRoomRid],
							[wAllotmentGroupRid],
							[wDate],
							[wAllotmentQty],
							[wExtraQty],
							[wBookedQty],
							[wCurrCode],
							[wRoomPrice],
							[wBreakfastPrice],
							[wRoomCost],
							[wExtraBedPrice],
							[wIsCustomized],
							[wStatus],
							[wCrtDt],
							[wCrtBy],
							[wUpdDt],
							[wUpdBy]
						)
						SELECT
								@sChildRowID ,
								@sRoomRid,
								@wAllotmentGroupRid,
								@sDate,
								wAllotmentQty = CASE DATEPART(dw,@sDate) WHEN 1 THEN wSunQty 
								WHEN 2 THEN wMonQty
								WHEN 3 THEN wTueQty
								WHEN 4 THEN wWedQty
								WHEN 5 THEN wThuQty
								WHEN 6 THEN wFriQty
								WHEN 7 THEN wSatQty
								END,
								0,
								0,
								@sCurCode,
								@sRoomPrice,
								@sBreakfastPrice,
								@sRoomCost,
								@sExtraBedPrice,
								'N',
								'A',
								dbo.fnUTC8Now(),
								s.wUpdBy ,
								dbo.fnUTC8Now(),
								s.wUpdBy 									
						FROM    #sDataSet_SetAllotmentHotelDtl s
						WHERE   wRowNum = @sRuningIndex;
					END

					SET @sDate = DATEADD(DAY,1, @sDate);
				END;
				SET @sRuningIndex = @sRuningIndex + 1;
		END
					
		-- MAIN Logic here, example here is inserting dataset to
		INSERT  INTO dbo.[eAllotmentHotelDtl]
			(
				[RowID],								
				[wAllotmentHotelRid],
				[wAllotmentGroupRid],
				[wSunQty],
				[wMonQty],
				[wTueQty],
				[wWedQty],
				[wThuQty],
				[wFriQty],
				[wSatQty],
				[wSeqNo],
				[wCrtBy],
				[wCrtDt],
				[wUpdBy],
				[wUpdDt]
								
			)
			SELECT
					s.RowID ,
					wAllotmentHotelRid,
					wAllotmentGroupRid,
					s.wSunQty,
					s.wMonQty,
					s.wTueQty,
					s.wWedQty,
					s.wThuQty,
					s.wFriQty,
					s.wSatQty,
					s.wSeqNo,
					s.wUpdBy ,
					dbo.fnUTC8Now(),
					s.wUpdBy ,
					dbo.fnUTC8Now()
			FROM    #sDataSet_SetAllotmentHotelDtl s;

			

			UPDATE AHD
			SET
					wAllotmentQty = (CASE DATEPART(dw,AHD.wDate) WHEN 1 THEN PRCDTL.wSunQty 
					WHEN 2 THEN PRCDTL.wMonQty
					WHEN 3 THEN PRCDTL.wTueQty
					WHEN 4 THEN PRCDTL.wWedQty
					WHEN 5 THEN PRCDTL.wThuQty
					WHEN 6 THEN PRCDTL.wFriQty
					WHEN 7 THEN PRCDTL.wSatQty
					END),
					[wUpdDt]=dbo.fnUTC8Now(),
					[wUpdBy]=@sUpdBy
			FROM dbo.[eAllotmentHotelDaily] AS AHD
			INNER JOIN (SELECT 
							ROW_NUMBER() OVER(PARTITION BY ALTDLY.wRoomRid,ALTDLY.wAllotmentGroupRid,ALTDLY.wDate ORDER BY ALTDTL.wUpdDt DESC) AS [LetestRecord]
							,ALTDTL.*
							,ALTDLY.wRoomRid
							,ALTDLY.wDate
						FROM dbo.eAllotmentHotelDaily ALTDLY
						INNER JOIN (
							SELECT * FROM dbo.eAllotmentHotel 
								WHERE wStatus='A' AND wIsSpecialDate='N' 
									AND wRoomRid IN (SELECT wRoomRid FROM dbo.eAllotmentHotel WHERE RowId=@pAllotmentHotelRid)
							) ALT ON ALT.wRoomRid=ALTDLY.wRoomRid
							AND ALTDLY.wDate BETWEEN ALT.wStartDate AND CAST(DATEADD(DAY,-1,ISNULL(ALT.wEndDate, '9999-12-31')) AS DATE)
							AND ALT.wRoomRid=ALTDLY.wRoomRid
						INNER JOIN dbo.eAllotmentHotelDtl ALTDTL ON ALTDTL.wAllotmentHotelRid=ALT.RowID
							AND ALTDTL.wAllotmentGroupRid=ALTDLY.wAllotmentGroupRid
			) PRCDTL ON PRCDTL.wDate=AHD.wDate
				AND PRCDTL.wAllotmentGroupRid=AHD.wAllotmentGroupRid
				AND PRCDTL.wRoomRid=AHD.wRoomRid				
				AND PRCDTL.LetestRecord=1
				AND AHD.wIsCustomized = 'N'--#35462

			UPDATE AHD
				SET
					wAllotmentQty = (CASE DATEPART(dw,AHD.wDate) WHEN 1 THEN ALTDTL.wSunQty 
					WHEN 2 THEN ALTDTL.wMonQty
					WHEN 3 THEN ALTDTL.wTueQty
					WHEN 4 THEN ALTDTL.wWedQty
					WHEN 5 THEN ALTDTL.wThuQty
					WHEN 6 THEN ALTDTL.wFriQty
					WHEN 7 THEN ALTDTL.wSatQty
					END),
					[wUpdDt] = dbo.fnUTC8Now(),
					[wUpdBy] = @sUpdBy
			FROM dbo.[eAllotmentHotelDaily] AS AHD
			INNER JOIN dbo.eAllotmentHotel ALT ON ALT.wRoomRid=AHD.wRoomRid						
				AND AHD.wStatus='A'
				AND AHD.wIsCustomized = 'N'--#35462
				AND ALT.wStatus='A'
				AND ALT.wIsSpecialDate='Y'
				AND ALT.wRoomRid IN (SELECT wRoomRid FROM dbo.eAllotmentHotel WHERE RowId=@pAllotmentHotelRid)
				AND AHD.wDate BETWEEN ALT.wStartDate AND ALT.wEndDate
			INNER JOIN dbo.eAllotmentHotelDtl ALTDTL ON ALTDTL.wAllotmentHotelRid=ALT.RowID
				AND ALTDTL.wAllotmentGroupRid=AHD.wAllotmentGroupRid;

			--remove useless daily record that date is not in range
			UPDATE AHD SET
			[wStatus]='T',
			[wUpdDt]=dbo.fnUTC8Now(),
			[wUpdBy]=@sUpdBy
			FROM dbo.[eAllotmentHotelDaily] AHD
			INNER JOIN dbo.eAllotmentHotel ALT ON ALT.wRoomRid=AHD.wRoomRid						
				AND AHD.wStatus='A'
				AND ALT.wStatus='A'
				AND ALT.wRoomRid IN (SELECT wRoomRid FROM dbo.eAllotmentHotel WHERE RowId=@pAllotmentHotelRid)
				AND ALT.wHotelRid IN (SELECT wHotelRid FROM dbo.eAllotmentHotel WHERE RowId=@pAllotmentHotelRid)
			INNER JOIN dbo.eAllotmentHotelDtl ALTDTL ON ALTDTL.wAllotmentHotelRid=ALT.RowID
				AND ALTDTL.wAllotmentGroupRid=AHD.wAllotmentGroupRid
			WHERE (wDate < (SELECT MIN(wStartDate) FROM dbo.eAllotmentHotel h INNER JOIN dbo.eAllotmentHotelDtl d ON d.wAllotmentHotelRid=h.RowID
						WHERE wHotelRid = (SELECT TOP 1 wHotelRid FROM dbo.eAllotmentHotel WHERE RowId = @pAllotmentHotelRid)
						AND wRoomRid = (SELECT TOP 1 wRoomRid FROM dbo.eAllotmentHotel WHERE RowId = @pAllotmentHotelRid)
						AND wStatus = 'A')
			OR wDate > (SELECT DATEADD(DAY,0, MAX(ISNULL(h.wEndDate, '9999-12-31'))) FROM dbo.eAllotmentHotel h INNER JOIN dbo.eAllotmentHotelDtl d ON d.wAllotmentHotelRid=h.RowID
						WHERE wHotelRid = (SELECT TOP 1 wHotelRid FROM dbo.eAllotmentHotel WHERE RowId = @pAllotmentHotelRid)
						AND wRoomRid = (SELECT TOP 1 wRoomRid FROM dbo.eAllotmentHotel WHERE RowId = @pAllotmentHotelRid)
						AND wStatus = 'A')
			)
			AND AHD.wIsCustomized = 'N'

		IF @sBeginTranCount = 0 AND @@trancount > 0
		BEGIN
			COMMIT;
		END;  
	   
		-- Return RowID affected
		IF @pReturnResultSet = 'Y'
			SELECT  RowID
			FROM    #sDataSet_SetAllotmentHotelDtl;
		RETURN;

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

		IF OBJECT_ID('tempdb..#sDataSet_SetAllotmentHotelDtl') IS NOT NULL DROP TABLE #sDataSet_SetAllotmentHotelDtl
END;