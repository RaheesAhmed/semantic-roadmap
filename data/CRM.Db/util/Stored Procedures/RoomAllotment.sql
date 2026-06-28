--EXEC [util].[RoomAllotment] @pMainCompNo=10,@pHotelRid=10000000010633

CREATE PROCEDURE [util].[RoomAllotment]
(
	@pMainCompNo INT = 10,
	@pHotelRid BIGINT = null
)
AS
BEGIN
	DECLARE 
	@cAHRowId bigint,
	@cAHDtlRowId bigint,
	@cHotelRid bigint,
	@cRoomRid bigint,
	@cGrpRid bigint,
	@cStartDate datetime,
	@cCurCode VARCHAR(6),
	@cUpdBy bigint,
	@today date,
	@nowDayNextYear date;

	DECLARE @sDate DATETIME;
	DECLARE @sRoomPrice NUMERIC(18,4) = 0;
	DECLARE @sBreakfastPrice NUMERIC(18,4) = 0;
	DECLARE @sRoomCost NUMERIC(18,4) = 0;
	DECLARE @sExtraBedPrice NUMERIC(18,4) = 0;
	DECLARE @sChildTableName VARCHAR(50) = 'eAllotmentHotelDaily',
			@sChildRowID BIGINT = 0 ;

	SET @today = GETDATE();
	SET @nowDayNextYear = DATEADD(YEAR,1,@today);

	--同酒店，同房间,同房间配额，不同startdate的[eAllotmentHotel]记录是存在的，选最大wCrtDt的记录
	DECLARE cur CURSOR FOR
	SELECT DISTINCT ah.RowId,ah.wHotelRid,ah.wRoomRid,h.wCurrCode,ah.wUpdBy FROM dbo.[eAllotmentHotel] ah inner JOIN mHotel h ON h.RowID = ah.wHotelRid 
	   inner join dbo.eAllotmentHotelDtl ahd on ah.RowID = ahd.wAllotmentHotelRid
   inner join 	(SELECT MAX(nah.wCrtDt) AS wMaxCrtDt, nah.wHotelRid,nah.wRoomRid,nahd.wAllotmentGroupRid FROM dbo.[eAllotmentHotel] nah inner join dbo.eAllotmentHotelDtl nahd on nah.RowID = nahd.wAllotmentHotelRid
			WHERE nah.wIsSpecialDate='N' and nah.wEndDate is null and nah.wStatus = 'A' and (@pHotelRid IS NULL OR nah.wHotelRid = @pHotelRid) group by nah.wHotelRid,nah.wRoomRid,nahd.wAllotmentGroupRid) AS nmax
		on ah.wHotelRid = nmax.wHotelRid AND ah.wRoomRid = nmax.wRoomRid AND ahd.wAllotmentGroupRid = nmax.wAllotmentGroupRid AND ah.wCrtDt = nmax.wMaxCrtDt
	WHERE ah.wIsSpecialDate='N' and ah.wEndDate is null and ah.wStatus = 'A' and (@pHotelRid IS NULL OR ah.wHotelRid = @pHotelRid)

	----DECLARE cur CURSOR FOR
	----SELECT ah.RowId,wHotelRid,wRoomRid,h.wCurrCode,ah.wUpdBy FROM dbo.[eAllotmentHotel] ah inner JOIN mHotel h ON h.RowID = ah.wHotelRid 
	----WHERE ah.wIsSpecialDate='N' and ah.wEndDate is null and ah.wStatus = 'A' and (@pHotelRid IS NULL OR ah.wHotelRid = @pHotelRid)
	------同酒店，同房间，不同startdate的[eAllotmentHotel]记录是存在的，选最大wCrtDt的记录
	----AND ah.wCrtDt = (SELECT MAX(wCrtDt) FROM dbo.[eAllotmentHotel] nah WHERE nah.wIsSpecialDate='N' and nah.wEndDate is null and nah.wStatus = 'A' AND nah.wHotelRid = ah.wHotelRid AND nah.wRoomRid = ah.wRoomRid)
	OPEN cur
	
	FETCH NEXT FROM cur INTO @cAHRowId,@cHotelRid,@cRoomRid,@cCurCode,@cUpdBy
	WHILE @@FETCH_STATUS = 0
	BEGIN
		DECLARE curDtl CURSOR FOR
		SELECT RowId,wAllotmentGroupRid FROM dbo.[eAllotmentHotelDtl] WHERE wAllotmentHotelRid = @cAHRowId
		OPEN curDtl
		FETCH NEXT FROM curDtl INTO @cAHDtlRowId,@cGrpRid
		WHILE @@FETCH_STATUS = 0

		BEGIN
			SELECT TOP 1 @sDate = wDate FROM dbo.eAllotmentHotelDaily WHERE wRoomRid = @cRoomRid AND wAllotmentGroupRid = @cGrpRid AND wStatus = 'A' ORDER BY wDate DESC
			SET @sDate = DATEADD(DAY,1,@sDate);

			While @sDate <= @nowDayNextYear
			BEGIN
				SET @sRoomPrice = 0;
				SET @sBreakfastPrice = 0;
				SET @sRoomCost = 0;
				SET @sExtraBedPrice = 0;

				Select Top 1  
				@sRoomPrice = ISNULL(CASE DATEPART(dw,@sDate) WHEN 1 THEN wSunRoomPrice
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
				FROM dbo.eHotelRoomPricing Where wHotelRoomRid = @cRoomRid AND @sDate BETWEEN wStartDate AND wEndDate AND wIsSpecialDate='Y' AND wStatus='A' ORDER BY wUpdDt DESC;

				IF (@sRoomPrice+@sBreakfastPrice+@sRoomCost) <= 0
				BEGIN
					Select Top 1  
					@sRoomPrice = ISNULL(CASE DATEPART(dw,@sDate) WHEN 1 THEN wSunRoomPrice
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
					FROM dbo.eHotelRoomPricing Where wHotelRoomRid = @cRoomRid AND (@sDate BETWEEN wStartDate AND @nowDayNextYear) AND wIsSpecialDate='N' AND wStatus='A' ORDER BY wUpdDt DESC;
				END

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
						@cRoomRid,
						@cGrpRid,
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
						@cCurCode,
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
				FROM    dbo.[eAllotmentHotelDtl] s
				WHERE   RowId = @cAHDtlRowId;
				--如果有特殊日子，更新新插入的记录
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
							[wUpdBy] = @cUpdBy
					FROM dbo.[eAllotmentHotelDaily] AS AHD
					INNER JOIN dbo.eAllotmentHotel ALT ON ALT.wRoomRid=AHD.wRoomRid						
						AND AHD.wStatus='A'
						AND ALT.wStatus='A'
						AND ALT.wIsSpecialDate='Y'
						AND ALT.wRoomRid IN (SELECT wRoomRid FROM dbo.eAllotmentHotel WHERE RowId=@cAHRowId)
						AND AHD.wDate BETWEEN ALT.wStartDate AND ALT.wEndDate
					INNER JOIN dbo.eAllotmentHotelDtl ALTDTL ON ALTDTL.wAllotmentHotelRid=ALT.RowID
						AND ALTDTL.wAllotmentGroupRid=AHD.wAllotmentGroupRid WHERE AHD.wIsCustomized = 'N' AND ahd.wDate=@sDate AND (@pHotelRid IS NULL OR ALT.wHotelRid = @pHotelRid);

				SET @sDate = DATEADD(DAY,1, @sDate);
			END

			FETCH NEXT FROM curDtl INTO @cAHDtlRowId,@cGrpRid
		END
		CLOSE curDtl;
		DEALLOCATE curDtl;

		--UPDATE AHD
		--		SET
		--		wAllotmentQty = (CASE DATEPART(dw,AHD.wDate) WHEN 1 THEN PRCDTL.wSunQty 
		--		WHEN 2 THEN PRCDTL.wMonQty
		--		WHEN 3 THEN PRCDTL.wTueQty
		--		WHEN 4 THEN PRCDTL.wWedQty
		--		WHEN 5 THEN PRCDTL.wThuQty
		--		WHEN 6 THEN PRCDTL.wFriQty
		--		WHEN 7 THEN PRCDTL.wSatQty
		--		END),
		--		[wUpdDt]=dbo.fnUTC8Now(),
		--		[wUpdBy]=@cUpdBy
		--FROM dbo.[eAllotmentHotelDaily] AS AHD
		--INNER JOIN (SELECT 
		--				ROW_NUMBER() OVER(PARTITION BY ALTDLY.wRoomRid,ALTDLY.wAllotmentGroupRid,ALTDLY.wDate ORDER BY ALTDTL.wUpdDt DESC) AS [LetestRecord]
		--				,ALTDTL.*
		--				,ALTDLY.wRoomRid
		--				,ALTDLY.wDate
		--			FROM dbo.eAllotmentHotelDaily ALTDLY
		--			INNER JOIN (
		--				SELECT * FROM dbo.eAllotmentHotel 
		--					WHERE wStatus='A' AND wIsSpecialDate='N' 
		--						AND wRoomRid IN (SELECT wRoomRid FROM dbo.eAllotmentHotel WHERE RowId=@cAHRowId)
		--				) ALT ON ALT.wRoomRid=ALTDLY.wRoomRid
		--				AND ALTDLY.wDate BETWEEN ALT.wStartDate AND @nowDayNextYear
		--				AND ALT.wRoomRid=ALTDLY.wRoomRid
		--			INNER JOIN dbo.eAllotmentHotelDtl ALTDTL ON ALTDTL.wAllotmentHotelRid=ALT.RowID
		--				AND ALTDTL.wAllotmentGroupRid=ALTDLY.wAllotmentGroupRid
		--) PRCDTL ON PRCDTL.wDate=AHD.wDate
		--	AND PRCDTL.wAllotmentGroupRid=AHD.wAllotmentGroupRid
		--	AND PRCDTL.wRoomRid=AHD.wRoomRid				
		--	AND PRCDTL.LetestRecord=1 AND AHD.wIsCustomized = 'N'

		--UPDATE AHD
		--	SET
		--		wAllotmentQty = (CASE DATEPART(dw,AHD.wDate) WHEN 1 THEN ALTDTL.wSunQty 
		--		WHEN 2 THEN ALTDTL.wMonQty
		--		WHEN 3 THEN ALTDTL.wTueQty
		--		WHEN 4 THEN ALTDTL.wWedQty
		--		WHEN 5 THEN ALTDTL.wThuQty
		--		WHEN 6 THEN ALTDTL.wFriQty
		--		WHEN 7 THEN ALTDTL.wSatQty
		--		END),
		--		[wUpdDt] = dbo.fnUTC8Now(),
		--		[wUpdBy] = @cUpdBy
		--FROM dbo.[eAllotmentHotelDaily] AS AHD
		--INNER JOIN dbo.eAllotmentHotel ALT ON ALT.wRoomRid=AHD.wRoomRid						
		--	AND AHD.wStatus='A'
		--	AND ALT.wStatus='A'
		--	AND ALT.wIsSpecialDate='Y'
		--	AND ALT.wRoomRid IN (SELECT wRoomRid FROM dbo.eAllotmentHotel WHERE RowId=@cAHRowId)
		--	AND AHD.wDate BETWEEN ALT.wStartDate AND ALT.wEndDate
		--INNER JOIN dbo.eAllotmentHotelDtl ALTDTL ON ALTDTL.wAllotmentHotelRid=ALT.RowID
		--	AND ALTDTL.wAllotmentGroupRid=AHD.wAllotmentGroupRid WHERE AHD.wIsCustomized = 'N';

		FETCH NEXT FROM cur INTO @cAHRowId,@cHotelRid,@cRoomRid,@cCurCode,@cUpdBy
	END
	CLOSE cur;
	DEALLOCATE cur;

END