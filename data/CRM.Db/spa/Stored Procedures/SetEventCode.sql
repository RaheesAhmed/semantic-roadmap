CREATE PROCEDURE [spa].[SetEventCode]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT 
	)
AS
    BEGIN
        SET NOCOUNT ON;
		--select * from mEventCode;
        DECLARE @sThisTableName VARCHAR(50) = 'mEventCode' ,-- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
		     
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
		        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
	   
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetEventCodeDetails
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
			 RowID BIGINT ,
			 wEventCode NVARCHAR(30),
			 wCName NVARCHAR(500),
			 wEName NVARCHAR(500),
			 wRegion VARCHAR(10),
			 wStartDt DATE,
			 wEndDt DATE,
			 wYear VARCHAR(15),
             wRemark NVARCHAR(500),
			 wStatus CHAR(1),
             wCrtDt DATETIME2(7),
             wCrtBy  BIGINT ,
             wUpdDt DATETIME2(7),
			 wUpdBy BIGINT  
		  	);

        DECLARE @errorMsg VARCHAR(MAX);	
			--- EventCode Required Field Validation
        IF @pActionType IN ( 'I', 'U' )
            BEGIN
                SELECT  @errorMsg = CASE WHEN RTRIM(ISNULL(sec.wEventCode, '')) = ''
                                         THEN 'Event Code is Missing'
                                         WHEN RTRIM(ISNULL(sec.wStatus, '')) = ''
                                         THEN 'Status is Missing'
                                    END
                FROM    #sDataSet_SetEventCodeDetails sec;
            END;
        IF @errorMsg <> ''
            THROW 50001, @errorMsg, 1;	
			--- EventCode Required Field Validation end

			--- EventCode Delete Validation
        ELSE
            IF @pActionType = 'D'
                BEGIN
                    SELECT  @errorMsg = CASE WHEN mec.wStatus <> ( 'A' )
                                             THEN 'Event Code can not be deleted if Status Code is '
                                                  + mec.wStatus
                                        END
                    FROM    mEventCode mec
                            INNER JOIN #sDataSet_SetEventCodeDetails ec ON mec.RowID = ec.RowID;			   
                END;

        IF @errorMsg <> ''
            THROW 50001, @errorMsg, 1;
			--- EventCode Delete Validation end

        BEGIN TRY
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
            
            --進行刪除操作要做checking 是否有使用的記錄 有就不给删除
            IF (@pActionType='D' OR EXISTS(SELECT * FROM #sDataSet_SetEventCodeDetails ds WHERE ds.wStatus='T')) AND
               EXISTS (
                  SELECT * FROM #sDataSet_SetEventCodeDetails ds
                  INNER JOIN dbo.eBooking eb ON ds.RowID = eb.wEventCodeRid
               )
               BEGIN                          
                    SET @pErrMsg=[dbo].[fnGetErrorMsg]('3007','zh-TW');
                    THROW 50001, '', 1;
               END;

            IF @pActionType = 'I'
                BEGIN

                    IF EXISTS ( SELECT  1
                                FROM    dbo.mEventCode EVENTCODE
                                        INNER JOIN #sDataSet_SetEventCodeDetails TEMPEVENTCODE ON TEMPEVENTCODE.wEventCode = EVENTCODE.wEventCode )
                        THROW 50001, 'Event Code already exist.', 1;

			-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetEventCodeDetails
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetEventCodeDetails;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetEventCodeDetails
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
								
			-- MAIN Logic here, example here is inserting dataset to mSpa
                    INSERT  INTO dbo.[mEventCode]
                            ( [RowID] ,
                              [wEventCode] ,
                              [wCName] ,
                              [wEName] ,
                              [wRegion] ,
                              [wStartDt] ,
                              [wEndDt] ,
                              [wYear] ,
                              [wRemark] ,
                              [wStatus] ,
                              [wCrtDt] ,
                              [wCrtBy] ,
                              [wUpdDt] ,
                              [wUpdBy]
						    )
                            SELECT  s.RowID ,
                                    s.wEventCode ,
                                    s.wCName ,
                                    s.wEName ,
                                    s.wRegion ,
                                    s.wStartDt ,
                                    s.wEndDt ,
                                    s.wYear ,
                                    s.wRemark ,
                                    s.wStatus ,
                                    s.wCrtDt ,
                                    s.wCrtBy ,
                                    s.wUpdDt ,
                                    s.wUpdBy
                            FROM    #sDataSet_SetEventCodeDetails s;

                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN

                        IF EXISTS ( SELECT  1
                                    FROM    dbo.mEventCode EVENTCODE
                                            INNER JOIN #sDataSet_SetEventCodeDetails TEMPEVENTCODE ON TEMPEVENTCODE.wEventCode = EVENTCODE.wEventCode
                                                              AND TEMPEVENTCODE.RowID <> EVENTCODE.RowID )
                            THROW 50001, 'Event Code already exist.', 1;

                        UPDATE  mec
                        SET     mec.RowID = tmp.RowID ,
                                mec.wEventCode = tmp.wEventCode ,
                                mec.wCName = tmp.wCName ,
                                mec.wEName = tmp.wEName ,
                                mec.wRegion = tmp.wRegion ,
                                mec.wStartDt = tmp.wStartDt ,
                                mec.wEndDt = tmp.wEndDt ,
                                mec.wYear = tmp.wYear ,
                                mec.wRemark = tmp.wRemark ,
                                mec.wStatus = tmp.wStatus ,
                                mec.wUpdDt = tmp.wUpdDt ,
                                mec.wUpdBy = tmp.wUpdBy
                        FROM    dbo.mEventCode AS mec
                                INNER JOIN #sDataSet_SetEventCodeDetails tmp ON mec.RowID = tmp.RowID
                        WHERE   mec.RowID = tmp.RowID;

                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN
                            UPDATE  ec
                            SET     ec.wStatus = 'T' ,
                                    wUpdDt = dbo.fnUTC8Now()
                            FROM    dbo.mEventCode AS ec
                                    INNER JOIN #sDataSet_SetEventCodeDetails tmp ON ec.RowID = tmp.RowID
                            WHERE   ec.RowID = tmp.RowID;
                        END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

		-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetEventCodeDetails;

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
			
            IF @sBeginTranCount = 0
                AND ( @xstate = 1
                      OR @xstate = -1
                    )
                BEGIN
				-- transaction created within this sp
                    ROLLBACK;
                END;
	        
	        -- Write Log
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName,
                @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;

        END CATCH;
	
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetEventCodeDetails') IS NOT NULL
            DROP TABLE #sDataSet_SetEventCodeDetails;

    END;