CREATE PROCEDURE [spa].[SetAirport]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
    )
AS
    BEGIN
        SET NOCOUNT ON;	
	 --select * from mAirport;
        DECLARE @sThisTableName VARCHAR(50) = 'mAirport' , -- For RowID 
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
			
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
			
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
		
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
		
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetAirport
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				RowID BIGINT ,
				wCName  NVARCHAR(50),
				wEName  VARCHAR(200) ,
				wCode  NVARCHAR(10) ,
				wCity VARCHAR(10) ,
				wRemark NVARCHAR(500) ,
				wSeqNo INT ,
				wStatus CHAR(1),
				wUpdBy BIGINT ,
				wUpdDt DATETIME2(7)
			);
		 --better don't put everything within try, for example
		 --getting mSysTable value
		 --getting currency, period, mCompany ...

        DECLARE @errorMsg VARCHAR(MAX);	
			--- Airport Required Field Validation
        IF @pActionType IN ( 'I', 'U' )
            BEGIN
                SELECT  @errorMsg = CASE WHEN RTRIM(ISNULL(sa.wCName, '')) = ''
                                         THEN 'Chinese Name is Missing'
                                         WHEN RTRIM(ISNULL(sa.wEName, '')) = ''
                                         THEN 'English Name is Missing'
                                         WHEN RTRIM(ISNULL(sa.wCode, '')) = ''
                                         THEN 'Airport Code is Missing'
                                         WHEN RTRIM(ISNULL(sa.wCity, '')) = ''
                                         THEN 'City is Missing'
                                         WHEN sa.wSeqNo < 0
                                         THEN 'Sequence Number is Missing'
                                         WHEN RTRIM(ISNULL(sa.wStatus, '')) = ''
                                         THEN 'Status is Missing'
                                    END
                FROM    #sDataSet_SetAirport sa;
            END;
        IF @errorMsg <> ''
            THROW 50001, @errorMsg, 1;	
			--- Airport Required Field Validation end

			--- Airport Delete Validation
        ELSE
            IF @pActionType = 'D'
                BEGIN
                    SELECT  @errorMsg = CASE WHEN map.wStatus <> ( 'A' )
                                             THEN 'Airport can not be deleted if Status Code is '
                                                  + map.wStatus
                                        END
                    FROM    mAirport map
                            INNER JOIN #sDataSet_SetAirport sa ON map.RowID = sa.RowID;			   
                END;

        IF @errorMsg <> ''
            THROW 50001, @errorMsg, 1;
			--- Airport Delete Validation end

        BEGIN TRY
			-- Try to make the transaction scope as small as possible to reduce locking
	
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;			 

            --進行刪除操作或者中止要做checking 是否有使用的記錄 有就不给删除
            IF @pActionType ='D' OR EXISTS ( SELECT *  FROM #sDataSet_SetAirport ds WHERE ds.wStatus ='T')
            BEGIN
              DECLARE @sTable TABLE( wTableIndex BIGINT IDENTITY(1,1) PRIMARY KEY, wTableName VARCHAR(30), wRefIDType VARCHAR(30) );
              DECLARE @sTableIndex INT = 0;
              DECLARE @sTableName VARCHAR(30);
              DECLARE @sRefIDType VARCHAR(30);
              DECLARE @sErrMsg NVARCHAR(MAX);
              DECLARE @sSql NVARCHAR(MAX);

              INSERT INTO @sTable (wTableName, wRefIDType) VALUES
               ('dbo.ePrivatePlaneRouteDtl', 'wDepartureAirportRid' ),
               ('dbo.eAirTicketRouteDtl', 'wDepartureAirportRid'),
               ('dbo.eBookingCheckInService', 'wDestination'),
               ('dbo.eBookingPickUpService', 'wDestination');
              
              SELECT @sTableIndex = COUNT(1) FROM @sTable;

              WHILE @sTableIndex > 0
              BEGIN
                SELECT @sTableName = wTableName, @sRefIDType = wRefIDType FROM @sTable WHERE wTableIndex = @sTableIndex;

                SET @sSql = CONCAT('SELECT TOP(1) @sErrMsg = dbo.fnGetErrorMsg(''3010'',''zh-TW'') FROM #sDataSet_SetAirport AS ds INNER JOIN ',  @sTableName, ' AS airport ON airport.', @sRefIDType , ' =  ds.RowID ');

                EXEC sp_executesql @sSql, N'@sErrMsg NVARCHAR(MAX) OUTPUT' , @sErrMsg = @sErrMsg OUTPUT   
                
                IF ISNULL(@sErrMsg, '') <> ''
                BEGIN
                    SET @pErrMsg = @sErrMsg;
                    THROW 50001, '', 1;
                END;

                SET @sTableIndex = @sTableIndex -1;
              END
            END

            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetAirport
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetAirport;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetAirport
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[mAirport]
                            ( [RowID] ,
                              [wCName] ,
                              [wEName] ,
                              [wCode] ,
                              [wCity] ,
                              [wRemark] ,
                              [wSeqNo] ,
                              [wStatus] ,
                              [wCrtBy] ,
                              [wCrtDt] ,
                              [wUpdBy] ,
                              [wUpdDt]
								
							)
                            SELECT  s.RowID ,
                                    s.wCName ,
                                    s.wEName ,
                                    s.wCode ,
                                    s.wCity ,
                                    s.wRemark ,
                                    s.wSeqNo ,
                                    s.wStatus ,
                                    s.wUpdBy ,
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy ,
                                    dbo.fnUTC8Now()
                            FROM    #sDataSet_SetAirport s;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  met
                        SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
                                met.wCName = tmp.wCName ,
                                met.wEName = tmp.wEName ,
                                met.wCode = tmp.wCode ,
                                met.wCity = tmp.wCity ,
                                met.wRemark = tmp.wRemark ,
                                met.wSeqNo = tmp.wSeqNo ,
                                met.wStatus = tmp.wStatus ,
                                met.wUpdBy = tmp.wUpdBy ,
                                met.wUpdDt = dbo.fnUTC8Now()
                        FROM    dbo.mAirport AS met
                                INNER JOIN #sDataSet_SetAirport tmp ON met.RowID = tmp.RowID
                        WHERE   met.RowID = tmp.RowID;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN						
                            UPDATE  dbo.mAirport
                            SET     wStatus = 'T' ,
                                    wUpdDt = dbo.fnUTC8Now()
                            WHERE   RowID IN ( SELECT   RowID
                                               FROM     #sDataSet_SetAirport );
                        END;
	
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetAirport;
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

        IF OBJECT_ID('tempdb..#sDataSet_SetAirport') IS NOT NULL
            DROP TABLE #sDataSet_SetAirport;
		
    END;