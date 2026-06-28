CREATE PROCEDURE [util].[WriteMaryAgentActivitiesApiLog](
/*
	用於寫到RollsMary_Sync.dbo.ApiLog
	select top 10 *  from eBooking ORDER BY wCrtDt desc
	EXEC [util].[WriteMaryAgentActivitiesApiLog] 10000000008855,'HOTEL','A'
	SELECT TOP 10 * FROM [RollsMary_Sync].[dbo].[eApiLog] ORDER BY [wCurDateTime] desc
*/
	--@pTableName VARCHAR(30),
    @pBookingRid  BIGINT,
	@pBookingType VARCHAR(30) --eBooking/eGift/eContactTranParticipant/eContactTran/eComplaint/eAdvice,   @pBookingType='eGift'時,從wTableName = 'eGift'取值, @pBookingType='eContactTranParticipant'時,從eContactTranParticipant取值

)AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @sBeginTranCount INT = 0;
    SET @sBeginTranCount = @@trancount;

	BEGIN TRY
		IF @sBeginTranCount = 0
        BEGIN
            BEGIN TRAN;
        END;


		DECLARE @sDataStr NVARCHAR(MAX),
			@sSysDateTime DATETIME = SYSDATETIME(),
			@sBookingStatus VARCHAR(10),
			@sAgentCodeIn	VARCHAR(10),
			@sRowID AS			BIGINT,
			@sIndex			INT = 1,
			@sCount AS		INT;
		
		DECLARE @sApiLog AS TABLE(
			wRowNum	INT,
			RowID BIGINT,
			wBookingRid BIGINT,
			wAgentCodeIn VARCHAR(14),
			wDataStr	NVARCHAR(MAX)
		)

		SET @sDataStr = CONCAT('{"pBookingRid":"', @pBookingRid,
														'","pBookingType":"', @pBookingType,
														'","pBookingStatus":"', @sBookingStatus,
													'""}');
	

		IF(@pBookingType='eGift')
		BEGIN
			SELECT @sAgentCodeIn = eb.wReqAgentCodeIn 
					FROM [CRM].[dbo].[eGift] AS eb 
					WHERE eb.RowID = @pBookingRid;			
		END		
		ELSE IF( @pBookingType='eContactTranParticipant')
		BEGIN
			SELECT @sAgentCodeIn = ctp.wAgentCodeIn
				FROM [CRM].[dbo].[eContactTranParticipant] AS ctp
				WHERE ctp.RowID = @pBookingRid;
		END
		ELSE IF(@pBookingType = 'eComplaint') --OP#16291:API : /ApiSUNMD/v1/GetAgentActivityByDate 針對目前的所有類型資料, 都需要有activityRowid
		BEGIN
			SELECT @sAgentCodeIn = c.wAgentCodeIn
				FROM [CRM].[dbo].[eComplaint] AS c
				WHERE c.RowID = @pBookingRid;
		END
		ELSE IF(@pBookingType = 'eAdvice') --OP#16291
		BEGIN
			SELECT @sAgentCodeIn = a.wAgentCodeIn
				FROM [CRM].[dbo].eAdvice AS a
				WHERE a.RowID = @pBookingRid;	
		END	
		ELSE
		BEGIN
			SELECT @sAgentCodeIn = eb.wReqAgentCodeIn 
					FROM [CRM].[dbo].[eBooking] AS eb 
					WHERE eb.RowID = @pBookingRid;
		END
			
		
		IF (@pBookingType = 'eContactTran') --OP#16291 因為有多條,所以分開寫
		BEGIN
		--找出[eContactTranParticipant]所有記錄,寫到eApiLog里面,  
			PRINT(N'找出[eContactTranParticipant]所有記錄,寫到eApiLog里面')			
			
			IF (SELECT COUNT(0) FROM eContactTranParticipant WHERE wContactTranRid = @pBookingRid) > 0 BEGIN				
				INSERT INTO @sApiLog
						( wRowNum,wBookingRid,wAgentCodeIn )
				SELECT ROW_NUMBER()OVER(ORDER BY ctp.RowID),ctp.RowID,  ctp.wAgentCodeIn 
					FROM dbo.eContactTranParticipant AS ctp 
				WHERE   ctp.wContactTranRid = @pBookingRid				
				GROUP BY ctp.RowID,ctp.wAgentCodeIn
						
				SELECT @sCount = COUNT(0) FROM @sApiLog;			
				WHILE @sIndex <= @sCount BEGIN
					EXEC [RollsMary].spa.GetRowID 10, 'eApiLog', @sRowID OUTPUT
				
					UPDATE @sApiLog
						SET RowID = @sRowID, 
							wDataStr = CONCAT('{"pBookingRid":"', wBookingRid,
														'","pBookingType":"', 'eContactTranParticipant',
														'","pBookingStatus":"', @sBookingStatus,
									   '""}')
					WHERE wRowNum = @sIndex;
				
					--PRINT 'UPDATE @sApiLog_Index:'
					--PRINT @sRowID;
				
					SET @sIndex = @sIndex + 1;
				END

				INSERT INTO [RollsMary_Sync].[dbo].[eApiLog](
						[RowID]
						,[wCurDateTime]
						,[wApiName]
						,[wQueryStr]
						,[wPostData]
						,[wTranType]
						,[wSrc]
						,[wResponse]
						,[wFailCnt]
						,[wReferRID]
						,[wStatus]
						,[wUpdDt]
						,[wActionDt]
						,[wType]
						,[wQueueType]
						,[wPriority])
				SELECT  RowID,
						@sSysDateTime,
						'CRM_TO_MARY_AGENT_ACTIVITE',
						'eContactTranParticipant',
						wDataStr,
						'O',
						'CRM',
						'',
						0,
						wBookingRid,
						'O',
						NULL,
						NULL,
						'',
						'CRM_TRIP',
						'5'
					FROM @sApiLog

					--PRINT 'INSERT INTO [RollsMary_Sync].[dbo].[eApiLog]'
			END
				
		END
		ELSE
		BEGIN
			--OP#16169 生成activity/生成, sunpeople 的行程/旅程 的MD Agent 限制拿掉  2018-01-29
			--IF ([RollsMary].[dbo].[fnIsMDAgent](@sAgentCodeIn) = 1)
			--BEGIN
			EXEC [RollsMary].spa.GetRowID 10, 'eApiLog', @sRowID OUTPUT
			INSERT INTO [RollsMary_Sync].[dbo].[eApiLog](
							[RowID]
							,[wCurDateTime]
							,[wApiName]
							,[wQueryStr]
							,[wPostData]
							,[wTranType]
							,[wSrc]
							,[wResponse]
							,[wFailCnt]
							,[wReferRID]
							,[wStatus]
							,[wUpdDt]
							,[wActionDt]
							,[wType]
							,[wQueueType]
							,[wPriority])
					VALUES(@sRowID,
							@sSysDateTime,
							'CRM_TO_MARY_AGENT_ACTIVITE',
							@pBookingType,
							@sDataStr,
								'O',
								'CRM',
								'',
								0,
								@pBookingRid,
								'O',
								NULL,
								NULL,
								'',
								'CRM_TRIP',
								'5'
							);
		END
		--END
		--ELSE
		--BEGIN
		--	PRINT('[fnIsMDAgent]=false')
		--END

		IF @sBeginTranCount = 0  AND @@trancount > 0
        BEGIN
            COMMIT;		
        END;
	END TRY
	BEGIN CATCH
		DECLARE @sErrorNum INT ,
				@sCatchErrorMessage NVARCHAR(4000) ,
				@xstate INT ,
				@sProcedureName VARCHAR(100) ,
				@sRtnCodeLog INT ,
				@sErrMessageLog NVARCHAR(4000),
				@pErrCode INT = 0,
				@pErrMsg NVARCHAR(200);
	        
		SELECT  @sErrorNum = ERROR_NUMBER() ,
				@sCatchErrorMessage = ERROR_MESSAGE() ,
				@xstate = XACT_STATE() ,
				@sProcedureName = OBJECT_NAME(@@PROCID);
			
		IF ISNULL(@pErrCode, 0) = 0
			BEGIN
				SET @pErrCode = 999;
			END;
		SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ', @sCatchErrorMessage);
			
		IF @sBeginTranCount = 0
			AND ( @xstate = 1
					OR @xstate = -1
				)
			BEGIN
			-- transaction created within this sp
				ROLLBACK;
			END;
	        
		-- Write Log
		EXEC spa.WriteErrorLog 0, 0, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
	END CATCH;
END