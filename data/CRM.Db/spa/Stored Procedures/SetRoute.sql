CREATE PROCEDURE [spa].[SetRoute]
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

		--SELECT *FROM dbo.[mRoute]

	    DECLARE @sThisTableName VARCHAR(50) = 'mRoute' , -- For RowID
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
        INTO    #sDataSet_SetRoute
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				RowID BIGINT ,
				wRouteFrom  VARCHAR(50) ,
				wRouteTo  NVARCHAR(50) ,
				wIsTwoWay char(1),
				wVehicle VARCHAR(5) ,
				wSeqNo INT ,
				wStatus CHAR(1),
				wUpdBy BIGINT ,
				wUpdDt DATETIME2(7)
			);

		 --better don't put everything within try, for example
	     --getting mSysTable value
	     --getting currency, period, mCompany ...	    
			
	--- Required Field Validation Start
		DECLARE @errorMsg varchar(max);
		IF  @pActionType IN ('I', 'U') BEGIN				 
			SELECT  @errorMsg = case 
								  when RTRIM(ISNULL(eb.wRouteFrom,'')) = ''  then 'From Route Missing' 
								  when  RTRIM(ISNULL(eb.wRouteTo,'')) = ''  then 'To Route Missing'										
								  when wSeqNo <=0 then 'Route Squence Number Missing'								 				 
							end
		   FROM #sDataSet_SetRoute eb
		END
		IF @errorMsg <> ''
			THROW 50001, @errorMsg, 1;		
		--- Required Field Validation end

		-- Non Edit field validation
		IF @pActionType = 'U' 
		BEGIN
		SELECT  @errorMsg = case 
								 when rt.wStatus='T' AND rt.wRouteFrom <> temp.wRouteFrom  then 'Can not edit From Route' 	
								 when rt.wStatus='T' AND rt.wRouteTo <> temp.wRouteTo  then 'Can not edit To Route'								 				 
							end
		   FROM dbo.[mRoute] rt
		   INNER JOIN #sDataSet_SetRoute temp ON temp.RowID=rt.RowID 
		END
	   IF @errorMsg <> ''
			THROW 50001, @errorMsg, 1;		
		-- Non Edit field validation

        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
	        

            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            --進行刪除操作或者中止要做checking 是否有使用的記錄 有就不给删除
            IF @pActionType ='D' OR EXISTS ( SELECT *  FROM #sDataSet_SetRoute ds WHERE ds.wStatus ='T')
            BEGIN
              DECLARE @sTable TABLE( wTableIndex BIGINT IDENTITY(1,1) PRIMARY KEY, wTableName VARCHAR(30), wRefID VARCHAR(30) );
              DECLARE @sTableIndex INT = 0;
              DECLARE @sTableName VARCHAR(30);
              DECLARE @sRefID VARCHAR(30);
              DECLARE @sErrMsg NVARCHAR(MAX);
              DECLARE @sSql NVARCHAR(MAX);

              INSERT INTO @sTable (wTableName, wRefID) VALUES
               ('dbo.eBookingFerry', 'wRouteRid' ),
               ('dbo.eBookingHeli', 'wRouteRid');            
              
              SELECT @sTableIndex = COUNT(1) FROM @sTable;

              WHILE @sTableIndex > 0
              BEGIN
                SELECT @sTableName = wTableName, @sRefID = wRefID FROM @sTable WHERE wTableIndex = @sTableIndex;

                SET @sSql = CONCAT('SELECT TOP(1) @sErrMsg = dbo.fnGetErrorMsg(''3002'',''zh-TW'') FROM #sDataSet_SetRoute AS ds INNER JOIN ',  @sTableName, ' AS airport ON airport.', @sRefID , ' =  ds.RowID ');

                EXEC sp_executesql @sSql, N'@sErrMsg NVARCHAR(MAX) OUTPUT' , @sErrMsg = @sErrMsg OUTPUT   
                
                IF ISNULL(@sErrMsg, '') <> ''
                BEGIN
                    SET @pErrMsg = @sErrMsg;
                    THROW 50001, '', 1;
                END;

                SET @sTableIndex = @sTableIndex -1;
              END
            END

			IF EXISTS( SELECT * FROM mRoute As MROUTE INNER JOIN #sDataSet_SetRoute TEMPROUTE ON TEMPROUTE.wRouteFrom = MROUTE.wRouteFrom AND TEMPROUTE.wRouteTo = MROUTE.wRouteTo AND TEMPROUTE.wVehicle = MROUTE.wVehicle AND TEMPROUTE.ROWID != MROUTE.RowID AND MROUTE.wIsTwoWay = TEMPROUTE.wIsTwoWay AND MROUTE.wStatus = 'A')
				BEGIN
					DECLARE @sMessage VARCHAR(100)='This Route is already exists for ';
					SET @sMessage=@sMessage + (SELECT TOP 1 wVehicle FROM #sDataSet_SetRoute);
					THROW 50001,@sMessage, 1;
				END
			--IF EXISTS( SELECT * FROM mRoute As MROUTE INNER JOIN #sDataSet_SetRoute TEMPROUTE ON MROUTE.wIsTwoWay = 'Y' AND TEMPROUTE.wRouteFrom = MROUTE.wRouteTo AND TEMPROUTE.wRouteTo = MROUTE.wRouteFrom AND TEMPROUTE.wVehicle = MROUTE.wVehicle AND TEMPROUTE.ROWID != MROUTE.RowID)
			--	throw 50001, 'Route already exists for selected vehicle.', 1;

			--IF EXISTS( SELECT * FROM mRoute As MROUTE INNER JOIN #sDataSet_SetRoute TEMPROUTE ON MROUTE.wIsTwoWay = 'N' AND TEMPROUTE.wRouteFrom = MROUTE.wRouteTo AND TEMPROUTE.wRouteTo = MROUTE.wRouteFrom AND TEMPROUTE.wVehicle = MROUTE.wVehicle AND TEMPROUTE.ROWID != MROUTE.RowID)
			--	throw 50001, 'Route already exists for selected vehicle.', 1;

            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetRoute
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetRoute;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetRoute
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[mRoute]
                            (
								[RowID],
							    [wRouteFrom],
							    [wRouteTo],
								[wIsTwoWay],
							    [wVehicle],
							    [wSeqNo],
								[wStatus],
							    [wCrtBy],
								[wCrtDt],
							    [wUpdBy],
								[wUpdDt]
							    
							)
                            SELECT
	            	                s.RowID ,
									s.wRouteFrom ,
									s.wRouteTo ,
									s.wIsTwoWay,
									s.wVehicle ,
									s.wSeqNo ,
									s.wStatus,
									s.wUpdBy ,
									dbo.fnUTC8Now(),
									s.wUpdBy ,
									dbo.fnUTC8Now()
                            FROM    #sDataSet_SetRoute s;


                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  met
                        SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
								met.wRouteFrom = tmp.wRouteFrom ,
								met.wRouteTo = tmp.wRouteTo ,
								met.wIsTwoWay=tmp.wIsTwoWay,
								met.wVehicle= tmp.wVehicle ,
								met.wSeqNo= tmp.wSeqNo ,
								met.wStatus=tmp.wStatus,
                                met.wUpdBy = tmp.wUpdBy ,
                                met.wUpdDt = dbo.fnUTC8Now()
                        FROM    dbo.mRoute AS met
                                INNER JOIN #sDataSet_SetRoute tmp ON met.RowID = tmp.RowID
                        WHERE   met.RowID = tmp.RowID;
                    END;
                ELSE
					IF @pActionType = 'D'
                        BEGIN						
                           UPDATE dbo.mRoute
								SET 
								wStatus='T',
								wUpdDt = dbo.fnUTC8Now()
								WHERE   RowID IN (SELECT RowID FROM #sDataSet_SetRoute );
                        END;


	
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

            -- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetContactTran;

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

		IF OBJECT_ID('tempdb..#sDataSet_SetRoute') IS NOT NULL
			DROP TABLE #sDataSet_SetRoute
		
    END;