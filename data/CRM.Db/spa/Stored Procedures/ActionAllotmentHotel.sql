CREATE PROCEDURE [spa].[ActionAllotmentHotel]
    @pXML XML ,
    @pActionType CHAR(1) ,
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pwAllotmentHotelRid BIGINT = 0 OUTPUT ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;	

	--Select Count(*) as wRecordCount from eAllotmentHotel

        DECLARE @sBeginTranCount INT = 0;
	 
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';

        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
	
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;

            IF  @pXML IS NOT NULL
            BEGIN
                DECLARE @sNewStartDate DATE;
                DECLARE @sNewEndDate DATE;
                DECLARE @sNewRoomRid BIGINT;
                DECLARE @sNewAllotmentHotelRowID BIGINT;
                DECLARE @sExistStartDate DATE;
                DECLARE @sExistEndDate DATE;
                
                SELECT @sNewStartDate = @pXML.value('(DataSet/SetAllotmentHotelResult/@wStartDate)[1]', 'DATE') ;
                SELECT @sNewEndDate = @pXML.value('(DataSet/SetAllotmentHotelResult/@wEndDate)[1]', 'DATE') ;
                SELECT @sNewRoomRid = @pXML.value('(DataSet/SetAllotmentHotelResult/@wRoomRid)[1]', 'BIGINT') ;
                SELECT @sNewAllotmentHotelRowID = @pXML.value('(DataSet/SetAllotmentHotelResult/@RowID)[1]', 'BIGINT') ;

                SELECT  @sExistStartDate=ah.wStartDate, @sExistEndDate=ah.wEndDate
                FROM    dbo.eAllotmentHotel ah
                WHERE   ah.wRoomRid =@sNewRoomRid AND ah.wIsSpecialDate = 'Y' AND ah.wStatus = 'A' AND ah.RowID!=@sNewAllotmentHotelRowID 
                        AND ((ah.wStartDate BETWEEN @sNewStartDate AND @sNewEndDate)
                             OR (ah.wEndDate BETWEEN @sNewStartDate AND @sNewEndDate)
                             OR ((@sNewStartDate BETWEEN ah.wStartDate AND ah.wEndDate) AND (@sNewEndDate BETWEEN ah.wStartDate AND ah.wEndDate)))

                IF  (@sExistStartDate IS NOT NULL OR @sExistEndDate IS NOT NULL )
                BEGIN
                 SET @pErrMsg=N'特別日子:'+ CONVERT(varchar(100), @sExistStartDate, 23)+ N'至'+ CONVERT(varchar(100), @sExistEndDate, 23) + N'和'+ CONVERT(varchar(100), @sNewStartDate, 23)+N'至'+CONVERT(varchar(100), @sNewEndDate, 23)  + N'資料不能同時存在';
                 THROW 50001, @pErrMsg, 1;
                END;
            END;

            -- Record's old data(Checking)
            IF @pActionType IN ('D', 'U') AND @pXML IS NOT NULL
            BEGIN
                DECLARE @sUseAllotmentDailyCount BIGINT;
                DECLARE @sOldStartDate DATE;
                DECLARE @sOldEndDate DATE;	
                DECLARE @sIsSpecialDate CHAR(1) = 'N';
                DECLARE @sNewStatus CHAR(1);
                DECLARE @sRoomRid BIGINT;
                DECLARE @sAllotmentGroupRid BIGINT;
                DECLARE @sAllotmentHotelRid BIGINT = @pwAllotmentHotelRid;
                DECLARE @sDocHandle INT;
                DECLARE @sOriActionType CHAR(1) = @pActionType;

                SELECT 
                    @sOldStartDate = wStartDate, 
                    @sOldEndDate = wEndDate, 
                    @sIsSpecialDate = wIsSpecialDate 
                FROM dbo.eAllotmentHotel WHERE RowID = @sAllotmentHotelRid;

                SELECT @sNewStatus = @pXML.value('(DataSet/SetAllotmentHotelResult/@wStatus)[1]', 'CHAR(1)') ;
                IF (@pActionType = 'D' OR (@pActionType = 'U' AND @sNewStatus = 'T'))
                BEGIN
                    SET @pXML.modify('delete /DataSet/SetAllotmentHotelDtlResult');
                    SET @pActionType = 'U'--如果是按删 则要设置为'U' 这样才会check 是否可以删除，如果可用删除，就会T掉相关的数据
                END;

                EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;

		        SELECT 
                    wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ),
                    *
		        INTO #sDataSet_SetAllotmentHotelDtl
		        FROM OPENXML (@sDocHandle, 'DataSet/SetAllotmentHotelDtlResult', 1)
		        WITH (			
				        RowID BIGINT ,				
				        wAllotmentHotelRid BIGINT,
				        wAllotmentGroupRid BIGINT,
				        wSunQty BIGINT,
				        wMonQty BIGINT,
				        wTueQty BIGINT,
				        wWedQty BIGINT,
				        wThuQty BIGINT,
				        wFriQty BIGINT,
				        wSatQty BIGINT,
				        wSeqNo BIGINT,
				        wUpdBy BIGINT ,
				        wUpdDt DATETIME2(7)
                );

                -- 計算有多少天是已經被使用過的（eAllotmentHotelDaily.wBookedQty > 0 表示房間配額已經被使用過，此時不允許刪除）
                IF @sIsSpecialDate = 'Y'
                    BEGIN
                        SELECT
                            @sUseAllotmentDailyCount = COUNT(1)
                        FROM dbo.eAllotmentHotel AS ah
                        INNER JOIN dbo.eAllotmentHotelDtl AS ahdtl ON ahdtl.wAllotmentHotelRid = ah.RowID
                        INNER JOIN dbo.eAllotmentHotelDaily AS ahday ON ahday.wRoomRid = ah.wRoomRid AND ahday.wAllotmentGroupRid = ahdtl.wAllotmentGroupRid AND ahday.wStatus = 'A'
                        LEFT JOIN #sDataSet_SetAllotmentHotelDtl AS sahdtl ON sahdtl.wAllotmentGroupRid = ahdtl.wAllotmentGroupRid
                        WHERE ah.RowID = @sAllotmentHotelRid
                            AND ahday.wDate >= @sOldStartDate
                            AND (@sOldEndDate IS NULL OR ahday.wDate <= @sOldEndDate)
                            AND ahday.wBookedQty > 0
                            AND (@sNewStartDate != @sOldStartDate OR @sNewEndDate != @sOldEndDate OR sahdtl.wAllotmentGroupRid IS NULL)
                    END;
                ELSE
                    BEGIN
                        IF @sNewStatus <> 'A' OR @sOriActionType = 'D'
                            BEGIN
                                -- 正常日子的Record不可以中止或者刪除
                                SET @sUseAllotmentDailyCount = 1;
                            END;
                        ELSE
                            BEGIN
                                ;WITH tAllotmentHotel AS (
                                    SELECT
                                        ah.wRoomRid,
                                        ahdtl.wAllotmentGroupRid
                                    FROM dbo.eAllotmentHotel AS ah
                                    INNER JOIN dbo.eAllotmentHotelDtl AS ahdtl ON ahdtl.wAllotmentHotelRid = ah.RowID
                                    WHERE ah.RowID = @sAllotmentHotelRid
                                ),
                                tSpecialAllotmentHotel AS (
                                    SELECT
                                        ahday.RowId,
                                        ahday.wRoomRid,
                                        ahday.wAllotmentGroupRid,
                                        ahday.wDate
                                    FROM dbo.eAllotmentHotel AS ah
                                    INNER JOIN dbo.eAllotmentHotelDtl AS ahdtl ON ahdtl.wAllotmentHotelRid = ah.RowID
                                    INNER JOIN dbo.eAllotmentHotelDaily AS ahday ON ahday.wRoomRid = ah.wRoomRid AND ahday.wAllotmentGroupRid = ahdtl.wAllotmentGroupRid AND ahday.wStatus = 'A'
                                    INNER JOIN tAllotmentHotel AS tah ON tah.wRoomRid = ahday.wRoomRid AND tah.wAllotmentGroupRid = ahday.wAllotmentGroupRid
                                    WHERE ah.wIsSpecialDate = 'Y' 
                                        AND ahday.wDate >= ah.wStartDate
                                        AND (ah.wEndDate IS NULL OR ahday.wDate <= ah.wEndDate)
                                )

                                SELECT
                                     @sUseAllotmentDailyCount = COUNT(1)
                                FROM dbo.eAllotmentHotel AS ah
                                INNER JOIN dbo.eAllotmentHotelDtl AS ahdtl ON ahdtl.wAllotmentHotelRid = ah.RowID
                                INNER JOIN dbo.eAllotmentHotelDaily AS ahday ON ahday.wRoomRid = ah.wRoomRid AND ahday.wAllotmentGroupRid = ahdtl.wAllotmentGroupRid AND ahday.wStatus = 'A'
                                LEFT JOIN tSpecialAllotmentHotel AS tsah ON tsah.wRoomRid = ahday.wRoomRid AND tsah.wAllotmentGroupRid = ahday.wAllotmentGroupRid AND tsah.wDate = ahday.wDate
                                LEFT JOIN #sDataSet_SetAllotmentHotelDtl AS sahdtl ON sahdtl.wAllotmentGroupRid = ahdtl.wAllotmentGroupRid
                                WHERE ah.RowID = @sAllotmentHotelRid
                                    AND ahday.wDate >= ah.wStartDate
                                    AND (ah.wEndDate IS NULL OR ahday.wDate <= ah.wEndDate)
                                    AND tsah.RowId IS NULL
                                    AND ahday.wBookedQty > 0
                                    AND (@sNewStartDate != ah.wStartDate OR @sNewEndDate != ah.wEndDate OR sahdtl.wAllotmentGroupRid IS NULL)
                            END;
                    END;
                    
                IF @sUseAllotmentDailyCount > 0
                BEGIN
                    SET @pErrMsg = dbo.fnGetErrorMsg('3001','zh-TW');
                    SET @pErrCode = 3001; -- 该房额已被使用，不能做更新或者中止操作，屬於正常操作，unit test不應該當作Fail
                    THROW 50001, @pErrMsg, 1;
                END;
            END;
            				
            EXEC [spa].[SetAllotmentHotel] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pwAllotmentHotelRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;

            EXEC [spa].[SetAllotmentHotelDtl] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pwAllotmentHotelRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;
			    
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;		
                END;
         			
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
                    IF @sErrorNum <> 50000
                        SET @pErrCode = 999;
                    ELSE
                        SET @pErrCode = 50000;

                END;
            --SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ',
            --                      @sCatchErrorMessage);
			
            IF NULLIF(@pErrMsg, '') IS NULL
                SET @pErrMsg = @sCatchErrorMessage;

            IF @sBeginTranCount = 0
                AND ( @xstate = 1
                      OR @xstate = -1
                    )
                BEGIN
				-- transaction created within this sp
                    ROLLBACK;
                END;
	        
	        -- Write Log
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH;

        IF NULLIF(@sDocHandle, 0) IS NOT NULL
		    EXEC sp_xml_removedocument @sDocHandle;

		IF OBJECT_ID('tempdb..#sDataSet_SetAllotmentHotelDtl') IS NOT NULL 
            DROP TABLE #sDataSet_SetAllotmentHotelDtl;
    END;