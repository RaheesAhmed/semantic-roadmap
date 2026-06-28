CREATE PROCEDURE [spa].[SetHotelCheckIn]
(
	@pXML XML,
	@pActionType CHAR(1),
	@pMainCompNo INT,
	@pNonceToken VARCHAR(64),
	@pResetAllotment VARCHAR(1) = 'Y',
	@pReturnResultSet CHAR(1) = 'N',
	@pRoomBookingDetailRid BIGINT,
	@pErrCode INT = 0 OUTPUT,
	@pErrMsg NVARCHAR(200) = '' OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @sThisTableName VARCHAR(50) = 'eHotelCheckIn', @sBeginTranCount INT = 0,@sRecCount INT =0,@sRuningIndex INT = 1,
	@sRowID BIGINT = 0,@sDocHandle INT,@updatedBy BIGINT=0,
	@sCurrCode CHAR(3);

	SET @sBeginTranCount = @@trancount;

	EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;

	SELECT wRowNum = ROW_NUMBER() OVER ( ORDER BY wBookingDate),*
	INTO #DataSet_SetHotelCheckIn
	FROM OPENXML (@sDocHandle, 'DataSet/GetHotelDailyCheckInRecordByRoombookingIdResult', 1)
	WITH (
		RowID BIGINT,
		wBookingDate DATE,
		wRoomBookingRid BIGINT,
		wHotelBookingRid BIGINT,
		wHotelRid BIGINT,
		wRoomRid BIGINT,
		wRoomNo NVARCHAR(20),
		wAllotmentGroupRid BIGINT,
		wCurrCode CHAR(3),
		wPrice NUMERIC(18,4),
		wCost NUMERIC(18,4),
		wBreakfastPrice NUMERIC(18, 4),
		wExtraBedPrice NUMERIC(18, 4),
		wIncludeBreakfast CHAR(1),
		wExtraRoom CHAR(1),
		wExtent CHAR(1),
		wCrtDt DATETIME2(7),
		wUpdBy BIGINT,
		wAgencyRoom CHAR(1),
		wDismiss CHAR(1),
		wStatus CHAR(1),
		wBookingStatus VARCHAR(5)
	);

	SELECT TOP 1 @updatedBy=wUpdBy FROM #DataSet_SetHotelCheckIn;
	IF(@updatedBy IS NULL OR @updatedBy <= 0)
		SELECT TOP(1) @updatedBy = wUpdBy FROM dbo.eHotelCheckIn WHERE wRoomBookingRid=@pRoomBookingDetailRid AND wStatus='A';

	DECLARE @pRoomBookingStatus VARCHAR(3)='', @sRoomBookingStatus VARCHAR(5) = '';
	SELECT TOP 1 @pRoomBookingStatus = wBookingStatus FROM #DataSet_SetHotelCheckIn WHERE wRoomBookingRid = @pRoomBookingDetailRid;
	
	SELECT @sRoomBookingStatus=wBookingStatus FROM dbo.eBookingRoom WHERE RowID=@pRoomBookingDetailRid;

	IF ISNULL(@pRoomBookingStatus, '') = '' SET @pRoomBookingStatus = @sRoomBookingStatus;

	SELECT TOP 1 @sCurrCode = br.wCurrCode 
			FROM dbo.eBookingRoom AS br
			WHERE br.RowID = @pRoomBookingDetailRid;

	BEGIN TRY
			-- Try to make the transaction scope as small as possible to reduce locking
			IF @sBeginTranCount = 0
				BEGIN
					BEGIN TRAN;
				END;
	IF @pRoomBookingStatus IN('P','C','CI','RF')
	BEGIN
		------删除旧记录前获取记录总数
		IF @pResetAllotment = 'Y'
		BEGIN
			UPDATE ALT
			SET	ALT.wBookedQty = (CASE WHEN ALT.wBookedQty <= 0 THEN 0 ELSE  ALT.wBookedQty - 1 END),
				ALT.wExtraQty = (CASE WHEN CHK.wExtraRoom='Y' THEN ( CASE WHEN ALT.wExtraQty <= 0 THEN 0 ELSE ALT.wExtraQty - 1 END)
									ELSE ALT.wExtraQty
									END),
				wUpdBy=@updatedBy,
				wUpdDt=dbo.fnUTC8Now()
			FROM dbo.eAllotmentHotelDaily ALT
			INNER JOIN dbo.eHotelCheckIn CHK ON ALT.wDate = CHK.wBookingDate
				AND CHK.wRoomBookingRid= @pRoomBookingDetailRid
				AND ALT.wAllotmentGroupRid=CHK.wAllotmentGroupRid
				AND ALT.wRoomRid=CHK.wRoomRid
				AND CHK.wStatus='A'
				AND @sRoomBookingStatus <> 'P';
		END

		UPDATE dbo.eHotelCheckIn SET wStatus = 'T', wUpdDt = dbo.fnUTC8Now(), wUpdBy = @updatedBy WHERE wRoomBookingRid=@pRoomBookingDetailRid AND wStatus='A';

		SELECT @sRecCount = COUNT(1)
		FROM #DataSet_SetHotelCheckIn;

		WHILE @sRuningIndex <= @sRecCount
		BEGIN
	
			EXEC spq.GetRowID @pMainCompNo, @sThisTableName,@sRowID OUTPUT;
							
			UPDATE #DataSet_SetHotelCheckIn
				SET RowID = @sRowID
			WHERE wRowNum = @sRuningIndex;
	
			SET @sRuningIndex = @sRuningIndex + 1;
		END;

		INSERT INTO [dbo].[eHotelCheckIn]
				   ([RowID]
				   ,[wRoomBookingRid]
				   ,[wHotelRid]
				   ,[wRoomRid]
				   ,[wAllotmentGroupRid]
				   ,[wRoomNo]
				   ,[wBookingDate]
				   ,[wCurrCode]
				   ,[wPrice]
				   ,[wCost]
				   ,[wBreakfastPrice]
				   ,[wExtraBedPrice]
				   ,[wIncludeBreakfast]
				   ,[wExtraRoom]
				   ,[wDismiss]
				   ,[wExtent]
				   ,[wAgencyRoom]
				   ,[wStatus]
				   ,[wCrtDt]
				   ,[wCrtBy]
				   ,[wUpdDt]
				   ,[wUpdBy])
		SELECT		[RowID]
				   ,@pRoomBookingDetailRid
				   ,wHotelRid
				   ,wRoomRid
				   ,wAllotmentGroupRid
				   ,wRoomNo
				   ,wBookingDate
				   ,@sCurrCode
				   ,wPrice
				   ,wCost
				   ,wBreakfastPrice
				   ,wExtraBedPrice
				   ,wIncludeBreakfast
				   ,wExtraRoom
				   ,wDismiss
				   ,wExtent
				   ,wAgencyRoom
				   ,wStatus
				   ,dbo.fnUTC8Now()
				   ,@updatedBy
				   ,dbo.fnUTC8Now()
				   ,@updatedBy
		FROM #DataSet_SetHotelCheckIn;

		EXEC sp_xml_removedocument @sDocHandle;			
		
		--Increment daily room allotment count
		UPDATE ALT
		SET	ALT.wBookedQty = ALT.wBookedQty+1,
			ALT.wExtraQty = (CASE WHEN CHK.wExtraRoom='Y' THEN (ALT.wExtraQty+1)
								ELSE ALT.wExtraQty
								END),
			wUpdBy=@updatedBy,
			wUpdDt=dbo.fnUTC8Now()
		FROM dbo.eAllotmentHotelDaily ALT
		INNER JOIN dbo.eHotelCheckIn CHK ON ALT.wDate = CHK.wBookingDate
			AND CHK.wRoomBookingRid= @pRoomBookingDetailRid
			AND ALT.wAllotmentGroupRid=CHK.wAllotmentGroupRid
			AND ALT.wRoomRid=CHK.wRoomRid
			AND CHK.wDismiss <> 'Y'
			AND CHK.wStatus='A'
			AND @pRoomBookingStatus IN ('C','CI');

		----UPDATE ly SET ly.wBookedQty = ISNULL(a.wBookedQty, 0), ly.wExtraQty = ISNULL(a.wExtraQty,0) 
		----	FROM 
		----	dbo.eAllotmentHotelDaily AS ly
		----	LEFT JOIN
		----	(
		----	SELECT ald.RowId, ald.wRoomRid, ald.wAllotmentGroupRid, ald.wDate, ald.wAllotmentQty, 
		----		CASE WHEN e.wStatus = 'A'(SELECT COUNT(1) FROM dbo.eHotelCheckIn AS e LEFT JOIN ( SELECT t.* FROM dbo.eHotelChange AS t INNER JOIN
		----					(SELECT MAX(RowID) AS RowID from dbo.eHotelChange GROUP BY wRoomBookingRid) AS g ON t.RowID = g.RowID) AS hc ON hc.wRoomBookingRid = e.wRoomBookingRid
		----			LEFT JOIN dbo.eBookingRoom AS br ON br.RowID = e.wRoomBookingRid
		----			WHERE e.wRoomRid = ald.wRoomRid AND e.wAllotmentGroupRid = ald.wAllotmentGroupRid 
		----				 AND e.wBookingDate = ald.wDate AND e.wStatus = 'A' AND e.wDismiss != 'Y' AND br.wBookingStatus IN ('C','CI')) 
		----			AS wBookedQty, 
		
		----		(SELECT COUNT(1) FROM dbo.eHotelCheckIn AS e LEFT JOIN ( SELECT t.* FROM dbo.eHotelChange AS t INNER JOIN
		----					(SELECT MAX(RowID) AS RowID from dbo.eHotelChange GROUP BY wRoomBookingRid) AS g ON t.RowID = g.RowID) AS hc ON hc.wRoomBookingRid = e.wRoomBookingRid
		----			LEFT JOIN dbo.eBookingRoom AS br ON br.RowID = e.wRoomBookingRid
		----			WHERE e.wExtraRoom = 'Y' AND e.wRoomRid = ald.wRoomRid AND e.wAllotmentGroupRid = ald.wAllotmentGroupRid 
		----				 AND e.wBookingDate = ald.wDate AND e.wStatus = 'A' AND e.wDismiss != 'Y' AND br.wBookingStatus IN ('C','CI'))
		----			AS wExtraQty
		----	 FROM dbo.eAllotmentHotelDaily AS ald 
		----			INNER JOIN	dbo.eHotelCheckIn AS e ON ald.wRoomRid = e.wRoomRid AND ald.wAllotmentGroupRid = e.wAllotmentGroupRid AND ald.wDate = e.wBookingDate		
		----			GROUP BY ald.RowId, ald.wRoomRid, ald.wAllotmentGroupRid, ald.wDate, ald.wAllotmentQty
		----	) AS a ON a.RowId = ly.RowId
		------INNER JOIN (SELECT wRoomRid ,wAllotmentGroupRid ,wBookingDate FROM #DataSet_SetHotelCheckIn GROUP BY wRoomRid ,wAllotmentGroupRid ,wBookingDate) AS t
		------	ON t.wRoomRid = ly.wRoomRid AND t.wAllotmentGroupRid = ly.wAllotmentGroupRid AND t.wBookingDate = ly.wDate;

		--IF @pRoomBookingStatus <> 'RF'
		--	DELETE FROM dbo.eHotelCheckIn WHERE wRoomBookingRid=@pRoomBookingDetailRid AND wStatus='T';
	END

	IF @pRoomBookingStatus='CO'
	BEGIN
		UPDATE dbo.eHotelCheckIn
			Set wDismiss='N',  --退房，不是取消狀態
			wUpdBy=@updatedBy,
			wUpdDt=dbo.fnUTC8Now()
		WHERE wRoomBookingRid=@pRoomBookingDetailRid AND wStatus='A';
	END

	IF @pRoomBookingStatus='CI'
	BEGIN
		UPDATE dbo.eHotelCheckIn
			Set wDismiss='N',
			wUpdBy=@updatedBy,
			wUpdDt=dbo.fnUTC8Now()
		WHERE wRoomBookingRid=@pRoomBookingDetailRid AND wStatus='A';
	END

	IF @pRoomBookingStatus='CL' OR @pRoomBookingStatus='RF' OR @pRoomBookingStatus='UQ'
	BEGIN
		UPDATE dbo.eHotelCheckIn
			Set wStatus='T',
			wUpdBy=@updatedBy,
			wUpdDt=dbo.fnUTC8Now()
		WHERE wRoomBookingRid=@pRoomBookingDetailRid AND wStatus='A';
	END


	 IF @sBeginTranCount = 0
				AND @@trancount > 0
				BEGIN
					COMMIT;
				END;

	-- Return RowID affected
	 IF @pReturnResultSet = 'Y' SELECT RowID FROM    #DataSet_SetHotelCheckIn;

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
			SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @vErrorNum, ') ', @vCatchErrorMessage);
			
			EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT, @vErrMessageLog OUTPUT;
            IF @sBeginTranCount = 0
            BEGIN
                IF (@xstate = 1 OR @xstate = -1) AND @@TRANCOUNT > 0
                    ROLLBACK;					
            END;
            ELSE
                THROW;
		END CATCH;
	
		EXEC sp_xml_removedocument @sDocHandle;

		IF OBJECT_ID('tempdb..#DataSet_SetHotelCheckIn') IS NOT NULL DROP TABLE #DataSet_SetHotelCheckIn;
END;