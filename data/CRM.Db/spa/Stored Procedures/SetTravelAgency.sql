CREATE PROCEDURE [spa].[SetTravelAgency]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
	  @pReturnResultSet CHAR(1) = 'N',
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
	)
AS
    BEGIN
        SET NOCOUNT ON;

	    --SELECT * FROM mTravelAgency;

	    DECLARE @sThisTableName VARCHAR(50) = 'mTravelAgency' , -- For RowID
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
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetTravelAgency
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
                RowID BIGINT ,
                wName  NVARCHAR(30) ,
                wCode  NVARCHAR(10) ,
                wIsHotel char(1) ,
                wIsAirTic char(1) ,
				wIsShowTic  char(1) ,
                wIsTourGuide  char(1) ,
                wIsLeading  char(1) ,
                wIsPickup  char(1) ,
                wIsShip char(1) ,
                wIsHelicopter char(1) , 
                wIsPrivatePlane  char(1) , 
                wIsRestaurant  char(1) ,
                wIsCheckIn  char(1) ,
                wIsVisa  char(1) ,
                wIsTravelPac  char(1) ,
                wIsOtherExp  char(1) ,
                wStatus VARCHAR(20) ,
                wSeqNo INT ,
                wUpdBy BIGINT ,
                wUpdDt DATETIME2(7)
            );

		 --better don't put everything within try, for example
	     --getting mSysTable value
	     --getting currency, period, mCompany ...
	    
        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
	
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;         

            --進行刪除操作或者中止要做checking 是否有使用的記錄 有就不给删除
            IF @pActionType='D' OR EXISTS ( SELECT *  FROM #sDataSet_SetTravelAgency ds WHERE ds.wStatus ='T')
            BEGIN
              DECLARE @sTable TABLE( wTableIndex BIGINT IDENTITY(1,1) PRIMARY KEY, wTableName VARCHAR(30), wTravelAgencyType VARCHAR(30) );
              DECLARE @sTableIndex INT = 0;
              DECLARE @sTableName VARCHAR(30);
              DECLARE @sTravelAgencyType VARCHAR(30);
              DECLARE @sErrMsg NVARCHAR(MAX);
              DECLARE @sSql NVARCHAR(MAX);

              INSERT INTO @sTable (wTableName, wTravelAgencyType) VALUES
                ('dbo.eAdditionalExpense', 'wIsOtherExp' ),
                ('dbo.eBookingHotel', 'wIsHotel'),
                ('dbo.eBookingFerry', 'wIsShip'),
                ('dbo.eBookingAirTicket', 'wIsAirTic'),
                ('dbo.eBookingShow', 'wIsShowTic'),
                ('dbo.eBookingRestaurant', 'wIsRestaurant'),
                ('dbo.eBookingPrivatePlane', 'wIsPrivatePlane'),
                ('dbo.eBookingVisa', 'wIsVisa'),
                ('dbo.eBookingPickUpService', 'wIsPickup'),
                ('dbo.eBookingLeading', 'wIsLeading'),
                ('dbo.eBookingTourGuide', 'wIsTourGuide'),
                ('dbo.eBookingTravelPackage', 'wIsTravelPac'),
                ('dbo.eBookingCheckInService', 'wIsCheckIn');

              SELECT @sTableIndex = COUNT(1) FROM @sTable;

              WHILE @sTableIndex > 0
              BEGIN
                SELECT @sTableName = wTableName, @sTravelAgencyType = wTravelAgencyType FROM @sTable WHERE wTableIndex = @sTableIndex;

                IF @sTableName = 'dbo.eBookingCheckInService'
                    SET @sSql = CONCAT('SELECT TOP(1) @sErrMsg = dbo.fnGetErrorMsg(''3011'',''zh-TW'') FROM #sDataSet_SetTravelAgency AS ds INNER JOIN ',  @sTableName, ' AS booking ON ds.', @sTravelAgencyType , ' = ''Y'' AND ds.RowID = booking.wSupplier');
                ELSE
                    SET @sSql = CONCAT('SELECT TOP(1) @sErrMsg = dbo.fnGetErrorMsg(''3011'',''zh-TW'') FROM #sDataSet_SetTravelAgency AS ds INNER JOIN ',  @sTableName, ' AS booking ON ds.', @sTravelAgencyType , ' = ''Y'' AND ds.RowID = booking.wTravelAgencyRid');

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
                    UPDATE  #sDataSet_SetTravelAgency
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetTravelAgency;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,@sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetTravelAgency
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[mTravelAgency]
                            (
                                [RowID],
                                [wName],
                                [wCode],
                                [wIsHotel],
                                [wIsAirTic],
                                [wIsShowTic],
                                [wIsTourGuide],
                                [wIsLeading],
                                [wIsPickup],
                                [wIsShip],
                                [wIsHelicopter],
                                [wIsPrivatePlane],
                                [wIsRestaurant],
                                [wIsCheckIn],
                                [wIsVisa],
                                [wIsTravelPac],
                                [wIsOtherExp],
                                [wSeqNo],
                                [wStatus],
                                [wCrtBy],
                                [wCrtDt],
                                [wUpdBy],
                                [wUpdDt]
								
							)
                            SELECT
	            	                s.RowID ,
                                    s.wName ,
                                    s.wCode ,
                                    s.wIsHotel ,
                                    s.wIsAirTic ,
                                    s.wIsShowTic ,
                                    s.wIsTourGuide,
                                    s.wIsLeading,
                                    s.wIsPickup,
                                    s.wIsShip ,
                                    s.wIsHelicopter ,
                                    s.wIsPrivatePlane ,
                                    s.wIsRestaurant ,
                                    s.wIsCheckIn ,
                                    s.wIsVisa ,
                                    s.wIsTravelPac,
                                    s.wIsOtherExp,
                                    s.wSeqNo,
                                    s.wStatus,
                                    s.wUpdBy,
                                    dbo.fnUTC8Now(),
                                    s.wUpdBy,
                                    dbo.fnUTC8Now()
                            FROM    #sDataSet_SetTravelAgency s;


                END;
              ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  mta
                        SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
                                mta.wCode = tmp.wCode ,
                                mta.wName = tmp.wName ,
                                mta.wIsHotel= tmp.wIsHotel ,
                                mta.wIsAirTic= tmp.wIsAirTic ,
                                mta.wIsShowTic= tmp.wIsShowTic ,
                                mta.wIsTourGuide=tmp.wIsTourGuide,
                                mta.wIsLeading=tmp.wIsLeading,
                                mta.wIsPickup=tmp.wIsPickup,
                                mta.wIsShip=tmp.wIsShip ,
                                mta.wIsHelicopter=tmp.wIsHelicopter ,
                                mta.wIsPrivatePlane=tmp.wIsPrivatePlane ,
                                mta.wIsRestaurant=tmp.wIsRestaurant ,
                                mta.wIsCheckIn=tmp.wIsCheckIn ,
                                mta.wIsVisa= tmp.wIsVisa,
                                mta.wIsTravelPac=tmp.wIsTravelPac,
                                mta.wIsOtherExp=tmp.wIsOtherExp,
                                mta.wStatus= tmp.wStatus ,
                                mta.wSeqNo= tmp.wSeqNo ,
                                mta.wUpdBy = tmp.wUpdBy ,
                                mta.wUpdDt = dbo.fnUTC8Now()
                        FROM    dbo.mTravelAgency AS mta
                                INNER JOIN #sDataSet_SetTravelAgency tmp ON mta.RowID = tmp.RowID
                        WHERE   mta.RowID = tmp.RowID;
                    END;
                ELSE
                IF @pActionType = 'D'
                  BEGIN
                    UPDATE dbo.mTravelAgency
                    SET 
                      wStatus='T',
                      wUpdDt = dbo.fnUTC8Now()
                      WHERE   RowID IN (SELECT RowID FROM #sDataSet_SetTravelAgency );
                  END;


	
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;
			
			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID FROM    #sDataSet_SetTravelAgency;
                
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
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ',@sCatchErrorMessage);
			
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

		IF OBJECT_ID('tempdb..#sDataSet_SetTravelAgency') IS NOT NULL
			DROP TABLE #sDataSet_SetTravelAgency
		
    END;