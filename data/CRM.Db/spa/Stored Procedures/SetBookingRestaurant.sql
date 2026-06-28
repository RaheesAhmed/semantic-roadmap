--sp_helptext '[spa].[SetBookingRestaurant]'

CREATE PROCEDURE [spa].[SetBookingRestaurant]
    (
      @pXML XML ,
      @pActionType CHAR(1) ,   -- I/U/D      
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pBookingRid BIGINT ,
      @rBookingRestaurantInfoId BIGINT = 0 OUTPUT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
    )
AS
    BEGIN
        SET NOCOUNT ON;                      
        DECLARE @sThisTableName VARCHAR(50) = 'eBookingRestaurant' , -- For RowID                      
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @vNow DATETIME2 = dbo.fnUTC8Now() ,
            @sActionAffectedXML NVARCHAR(MAX) = '' ,
            @sDocHandle INT ,
            @sSeqNo INT = 0;
                            
        DECLARE @sReturnRowID TABLE ( RowID BIGINT ); 
		
        SET @sBeginTranCount = @@trancount;                     
                            
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;                     
	                                                 
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetBookingRestaurant
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				[RowID] [BIGINT],
				[wBookingRid] [VARCHAR](20),
				[wRestaurantRid] [BIGINT],
				[wTravelAgencyRid] [BIGINT],
				[wNoOfPpl] [INT],
				[wBookingDt] [DATETIME2](7),
				[wDiningArea] [VARCHAR](30),
				[wReserveName] [NVARCHAR](100),
				[wReservePhoneNo] [VARCHAR](50),
				[wRemark] [NVARCHAR](500),
				[wBookingStatus] [VARCHAR](5),
				[wUnqualifiedRid] [BIGINT],
				[wCrtBy] [BIGINT],
				[wCrtDt] [DATETIME2](7),
				[wUpdDt] [DATETIME2](7),
				[wUpdBy] [BIGINT],
                [wIsMinCharge] [CHAR](1),
                [wMinCharge] [NUMERIC](18,2),
                wAdditionalExp [NUMERIC](18,4),
                wAcceptBTM CHAR(1),
                wOldBookingStatus VARCHAR(5),
                wCurrCode VARCHAR(6)
        );                      
/*            
		DECLARE @errorMsg varchar(max);

		 --  Restaurant Booking Status Management update Field Validation Start
		IF  @pActionType = 'U' BEGIN
			 select  @errorMsg = case 								 								
								  When eb.wAdditionalExp <> sb.wAdditionalExp AND eb.wBookingStatus in ('CL','UQ','RF','CO', 'C') then lup.wTitle + ' status can not be changed to status code to ' + sb.wBookingStatus
								  When eb.wBookingStatus in ('RF','CL','UQ') AND  eb.wBookingStatus <> sb.wBookingStatus then lup.wTitle + ' status can not be changed to status code to ' + sb.wBookingStatus
								  When eb.wBookingStatus in ('C') AND  sb.wBookingStatus in ('P','CL','UQ') then lup.wTitle + ' status can not be changed to status code to ' + sb.wBookingStatus
								  When eb.wBookingStatus in ('P') AND  sb.wBookingStatus in ('RF','CO') then lup.wTitle + ' status can not be changed to status code to ' + sb.wBookingStatus
							end
			from eBookingRestaurant eb inner join
			   #sDataSet_SetBookingRestaurant sb on eb.wBookingRid=sb.wBookingRid 
			   INNER JOIN mLookUp lup On lup.wCode = eb.wBookingStatus AND lup.wType = 'RESTAURANT_BOOKING_STATUS' and lup.wlangCd='en-GB'			
		END
		ELSE IF @pActionType = 'D' BEGIN
			select  @errorMsg = case 								  
								  When sb.wBookingStatus <> ('P') then 'Booking can not be deleted if it not "In-Progress"' 
							end
			from eBookingHeli eb inner join
			   #sDataSet_SetBookingRestaurant sb on eb.wBookingRid=sb.wBookingRid			   
		END

		IF @errorMsg <> ''
				throw 50001, @errorMsg, 1;
		--  Restaurant Booking Status Management update Field Validation end
*/
        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;		
			 
            --------------------------------------------------------------------------Checking-----------------------------------------------------------------------------
            DECLARE @sErrorMsg NVARCHAR(MAX);
            IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType NOT IN ('I', 'U', 'D')
                SET @sErrorMsg = N'非法操作！';
        
            IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType IN ('U', 'D')
            BEGIN
                DECLARE @sBookingType VARCHAR(30) = 'RESTAURANT';
                DECLARE @sCurrentBookingStatus VARCHAR(5); -- DB当前状态
                DECLARE @sOldBookingStatus VARCHAR(5); -- 上一次Get數據時的狀態
                DECLARE @sNewBookingStatus VARCHAR(5); -- Save订单新状态
                DECLARE @sLangCd VARCHAR(10) = 'zh-TW';
                SELECT
                    @sCurrentBookingStatus = ebr.wBookingStatus, 
                    @sOldBookingStatus = sbr.wOldBookingStatus,
                    @sNewBookingStatus = sbr.wBookingStatus
                FROM dbo.eBookingRestaurant AS ebr 
                INNER JOIN #sDataSet_SetBookingRestaurant AS sbr ON sbr.RowID = ebr.RowID AND sbr.wBookingRid = ebr.wBookingRid
                WHERE ebr.wBookingRid = @pBookingRId;

                -- 獲取不到DB預訂當前狀態，訂單不存在（wBookingStatus IS NOT NULL）
                -- 如果已經有錯誤，不再Check
                IF NULLIF(@sErrorMsg, '') IS NULL AND @sCurrentBookingStatus IS NULL
                    SET @sErrorMsg = N'訂單不存在。';

                -- 如果已經有錯誤，不再Check
                IF NULLIF(@sErrorMsg, '') IS NULL
                    SET @sErrorMsg = dbo.fnGetBookingStatusErrorMsg(@pActionType, @sBookingType, @sCurrentBookingStatus, @sOldBookingStatus, @sNewBookingStatus, @sLangCd);
            
            END;

            IF NULLIF(@sErrorMsg, '') IS NOT NULL
                THROW 50001, @sErrorMsg, 1;
            ------------------------------------------------------------------------End Checking----------------------------------------------------------------------------
         
		
            IF @pActionType = 'I'
                BEGIN
		-- Set RowID by Sequence                      
                    UPDATE  #sDataSet_SetBookingRestaurant
                    SET     RowID = 0;

                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetBookingRestaurant;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;

                            UPDATE  #sDataSet_SetBookingRestaurant
                            SET     RowID = @sRowID ,
                                    wBookingRid = @pBookingRid
                            WHERE   wRowNum = @sRuningIndex;

                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;

                    SET @rBookingRestaurantInfoId = @sRowID;
                    SELECT  *
                    FROM    dbo.[eBookingRestaurant];
                    INSERT  INTO dbo.[eBookingRestaurant]
                            ( [RowID] ,
                              [wBookingRid] ,
                              [wRestaurantRid] ,
                              [wTravelAgencyRid] ,
                              [wNoOfPpl] ,
                              [wBookingDt] ,
                              [wDiningArea] ,
                              [wReserveName] ,
                              [wReservePhoneNo] ,
                              [wRemark] ,
                              [wBookingStatus] ,
                              [wUnqualifiedRid] ,
                              [wCrtBy] ,
                              [wCrtDt] ,
                              [wUpdDt] ,
                              [wUpdBy] ,
                              [wIsMinCharge] ,
                              [wMinCharge] ,
                              wAdditionalExp ,
                              wAcceptBTM,
                              wCurrCode
                            )
                            SELECT  s.[RowID] ,
                                    s.[wBookingRid] ,
                                    s.[wRestaurantRid] ,
                                    s.[wTravelAgencyRid] ,
                                    s.[wNoOfPpl] ,
                                    s.[wBookingDt] ,
                                    s.[wDiningArea] ,
                                    s.[wReserveName] ,
                                    s.[wReservePhoneNo] ,
                                    s.[wRemark] ,
                                    s.[wBookingStatus] ,
                                    ISNULL(s.[wUnqualifiedRid], 0) ,
                                    s.[wCrtBy] ,
                                    s.[wCrtDt] ,
                                    s.[wUpdDt] ,
                                    s.[wUpdBy] ,
                                    [wIsMinCharge] ,
                                    [wMinCharge] ,
                                    wAdditionalExp ,
                                    wAcceptBTM,
                                    wCurrCode
                            FROM    #sDataSet_SetBookingRestaurant s;   
                    SELECT  *
                    FROM    dbo.[eBookingRestaurant];
                END;                   
    ---------------------------------------------------------                
            ELSE
                IF @pActionType = 'U'
                    BEGIN
	             
                        UPDATE  bpp
                        SET     @rBookingRestaurantInfoId = tmp.[RowID] ,
                                [wBookingRid] = tmp.[wBookingRid] ,
                                [wRestaurantRid] = tmp.[wRestaurantRid] ,
                                [wTravelAgencyRid] = tmp.[wTravelAgencyRid] ,
                                [wNoOfPpl] = tmp.[wNoOfPpl] ,
                                [wBookingDt] = tmp.[wBookingDt] ,
                                [wDiningArea] = tmp.[wDiningArea] ,
                                [wReserveName] = tmp.[wReserveName] ,
                                [wReservePhoneNo] = tmp.[wReservePhoneNo] ,
                                [wRemark] = tmp.[wRemark] ,
                                [wBookingStatus] = tmp.[wBookingStatus] ,
                                [wUnqualifiedRid] = ISNULL(tmp.[wUnqualifiedRid],0) ,
                                [wUpdDt] = tmp.[wUpdDt] ,
                                [wUpdBy] = tmp.[wUpdBy] ,
                                [wIsMinCharge] = tmp.[wIsMinCharge] ,
                                [wMinCharge] = tmp.[wMinCharge] ,
                                wAdditionalExp = tmp.wAdditionalExp ,
                                wAcceptBTM = tmp.wAcceptBTM,
                                wCurrCode=tmp.wCurrCode
                        FROM    dbo.[eBookingRestaurant] AS bpp
                                INNER JOIN #sDataSet_SetBookingRestaurant tmp ON bpp.RowID = tmp.RowID
                        WHERE   bpp.RowID = tmp.RowID;                  
                                          
                    END;                  
                ELSE
                    IF @pActionType = 'D'
                        BEGIN
                            UPDATE  bpp
                            SET     [wUpdDt] = dbo.fnUTC8Now() ,
                                    [wUpdBy] = tmp.[wUpdBy] ,
                                    [wBookingStatus] = 'DL' ,
                                    [wStatus] = 'T'
                            FROM    dbo.[eBookingRestaurant] AS bpp
                                    INNER JOIN #sDataSet_SetBookingRestaurant tmp ON bpp.RowID = tmp.RowID;               

                        END;                  

			---------------------------------------------------------------------------------------------
			-- SetActionAffectedTableLog
			---------------------------------------------------------------------------------------------
            SET @sActionAffectedXML = ( SELECT  wActionSp = OBJECT_NAME(@@PROCID) ,
                                                wActionType = @pActionType ,
                                                wNonceToken = @pNonceToken ,
                                                wRefTableName = @sThisTableName ,
                                                wRefRid = tmp.RowID ,
                                                wType = '' ,
                                                wCrtDt = @vNow
                                        FROM    #sDataSet_SetBookingRestaurant tmp
                                      FOR
                                        XML RAW('Record') ,
                                            ROOT('DataSet')
                                      );
            EXEC spa.SetActionAffectedTableLog @sActionAffectedXML, 'I',
                @pMainCompNo, '', 0, '';

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;    
		
		-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetBookingRestaurant;      
                 
            RETURN;     

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

        IF OBJECT_ID('tempdb..#sDataSet_SetBookingRestaurant') IS NOT NULL
            DROP TABLE #sDataSet_SetBookingRestaurant;           
    END;