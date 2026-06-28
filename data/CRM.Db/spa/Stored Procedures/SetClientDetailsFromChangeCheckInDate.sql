CREATE PROCEDURE [spa].[SetClientDetailsFromChangeCheckInDate]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D 
      @pMainCompNo INT = 10 ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pRoomBookingRid BIGINT ,
      @pNewRoomBookingRid BIGINT ,
      @pUpdatedBy BIGINT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
    )
AS
    BEGIN
--select * from ePassengerDetails;
        DECLARE @sRowId BIGINT= 0 ,
            @sRecCount INT= 0 ,
            @sRuningIndex INT= 1;

        DECLARE @sBeginTranCount INT = 0;

        SET @sBeginTranCount = @@trancount;

        SELECT  *
        INTO    #tmpClientDetails
        FROM    ( SELECT    wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                            [RowID] ,
                            [wBookingRid] ,
                            [wRoomBookingRid] ,
                            [wCasinoCardRid] ,
                            [wClientTicketNo] ,
                            [wDepartFlightNo] ,
                            [wTakeOffDt] ,
                            [wDestination] ,
                            [wRequesterAcc] ,
                            [wPersonRid] ,
                            [wRemark] ,
                            [wStatus] ,
                            [wCrtBy] ,
                            [wCrtDt] ,
                            [wUpdDt] ,
                            [wUpdBy] ,
                            [wType]
                  FROM      [dbo].[ePassengerDetails]
                  WHERE     wRoomBookingRid = @pRoomBookingRid
                ) CLI;

---- Set RowID by Sequence		
        UPDATE  #tmpClientDetails
        SET     [RowID] = 0;        
        SELECT  @sRecCount = COUNT(1)
        FROM    #tmpClientDetails;        
        WHILE @sRuningIndex <= @sRecCount
            BEGIN        
	
                EXEC spq.GetRowID @pMainCompNo, 'ePassengerDetails',
                    @sRowId OUTPUT;	
		
                UPDATE  #tmpClientDetails
                SET     RowID = @sRowId
                WHERE   wRowNum = @sRuningIndex;        
    
                SET @sRuningIndex = @sRuningIndex + 1;
            END;    

        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END; 		        

            INSERT  INTO [dbo].[ePassengerDetails]
                    ( [RowID] ,
                      [wBookingRid] ,
                      [wRoomBookingRid] ,
                      [wCasinoCardRid] ,
                      [wClientTicketNo] ,
                      [wDepartFlightNo] ,
                      [wTakeOffDt] ,
                      [wDestination] ,
                      [wRequesterAcc] ,
                      [wPersonRid] ,
                      [wRemark] ,
                      [wStatus] ,
                      [wCrtBy] ,
                      [wCrtDt] ,
                      [wUpdDt] ,
                      [wUpdBy] ,
                      [wType]
                    )
                    SELECT  [RowID] ,
                            [wBookingRid] ,
                            @pNewRoomBookingRid ,
                            [wCasinoCardRid] ,
                            [wClientTicketNo] ,
                            [wDepartFlightNo] ,
                            [wTakeOffDt] ,
                            [wDestination] ,
                            [wRequesterAcc] ,
                            [wPersonRid] ,
                            [wRemark] ,
                            [wStatus] ,
                            @pUpdatedBy ,
                            dbo.fnUTC8Now() ,
                            dbo.fnUTC8Now() ,
                            @pUpdatedBy ,
                            [wType]
                    FROM    #tmpClientDetails;

            ----------------------------------------------------------------------------------------------------
            -- UPDATE stg.eBookingMisc
            ----------------------------------------------------------------------------------------------------
            SELECT
            	pdOut.wBookingRid, l.wLangCd, 
            	wItemCd = 'CUST_NAME', wValue = ISNULL(STUFF(
            			(
            				SELECT  ',' + CASE WHEN l.wLangCd = 'zh-TW' THEN p.wCName ELSE p.wEName END
            				FROM    ePassengerDetails pd
            				        INNER JOIN mPerson p ON pd.wPersonRid = p.RowID AND pd.wStatus = 'A'
            				WHERE   pd.wBookingRid = pdOut.wBookingRid
            				ORDER BY pd.wUpdDt
            				FOR XML PATH ('')
            			), 1,1,''), '')
            INTO #tmpStaging
            FROM ePassengerDetails pdOut
            CROSS JOIN (SELECT wLangCd = 'en-GB' UNION SELECT 'zh-TW') AS l
            INNER JOIN #tmpClientDetails tmp ON pdOut.RowID = tmp.RowID
            GROUP BY pdOut.wBookingRid, l.wLangCd;
            
            DELETE bm
            FROM [stg].[eBookingMisc] bm
            INNER JOIN #tmpStaging tmp ON bm.wBookingRid = tmp.wBookingRid AND bm.wLangCd = tmp.wLangCd AND bm.wItemCd = tmp.wItemCd;
            
            INSERT INTO  [stg].[eBookingMisc] (wBookingRid, wLangCd, wItemCd, wValue)
            SELECT wBookingRid, wLangCd, wItemCd, wValue
            FROM #tmpStaging;
            ----------------------------------------------------------------------------------------------------
            -- END stg.eBookingMisc
            ----------------------------------------------------------------------------------------------------


            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

          -- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #tmpClientDetails;

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
	
        --EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#tmpClientDetails') IS NOT NULL
            DROP TABLE #tmpClientDetails;

    END;