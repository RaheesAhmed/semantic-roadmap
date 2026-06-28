--sp_helptext 'spa.SetRestaurantSetting'


CREATE PROCEDURE [spa].[SetRestaurantSetting]
    (                      
      @pXML XML,
      @pActionType CHAR(1),   -- I/U/D      
      @pMainCompNo INT,     
	  @pNonceToken VARCHAR(64), 
	  @pReturnResultSet CHAR(1) = 'N',     
	  @rErrCode INT = 0 OUTPUT,
      @rErrMsg NVARCHAR(200) = '' OUTPUT
      )
AS         
    BEGIN

		--Select * from dbo.[mRestaurant]

        SET NOCOUNT ON;                      
        DECLARE @sThisTableName VARCHAR(50) = 'mRestaurant' , -- For RowID                      
                        @sBeginTranCount INT = 0 ,
						@sRecCount INT = 0 ,
						@sRuningIndex INT = 1 ,
						@sRowID BIGINT = 0 ,
						@sDocHandle INT,
						@sSeqNo INT = 0;
                            
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );    
		
		SET @sBeginTranCount = @@trancount;                  
                            
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;                     

			                                                 
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,                      
                *                      
        INTO    #sDataSet_SetRestaurant
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)                      
		WITH (
				[RowID] [bigint],
				[wName] [nvarchar](100),
				[wCuisine] [nvarchar](50),
				[wLevel] [varchar](3),
				[wPhone] [varchar](50),
				[wHotelRid] [bigint],
				[wAddress] [nvarchar](300),
				[wWorkHours] [nvarchar](400),
				[wRegion] [varchar](10),
				[wNoOfSeat] [int],
				[wIsSign] [char](1),
				[wIsBtm] [char](1),
				[wMinCharge] [numeric](18, 4),
				[wMenu] [nvarchar](500),
				[wStatus] [varchar](2),
				[wSeqNo] [int],
				[wCrtDt] [datetime2](7),
				[wCrtBy] [bigint],
				[wUpdDt] [datetime2](7),
				[wUpdBy] [bigint],
				[wAwards][nvarchar](100),
				[wDressRequire] [nvarchar](500)
        );                      
                      
		BEGIN TRY
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

				   IF @pActionType = 'I'
					BEGIN
						-- Set RowID by Sequence                      
						UPDATE  #sDataSet_SetRestaurant
						SET RowID = 0;

						SELECT
							@sRecCount = COUNT(*)
						FROM
							#sDataSet_SetRestaurant;
						WHILE
							@sRuningIndex <= @sRecCount
							BEGIN EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
						
							UPDATE #sDataSet_SetRestaurant
							SET RowID = @sRowID							
							WHERE wRowNum = @sRuningIndex;

							SET @sRuningIndex = @sRuningIndex + 1;
						END;
	
					INSERT  INTO dbo.[mRestaurant]
					(
							[RowID],
							[wName],
							[wCuisine],
							[wLevel],
							[wPhone],
							[wHotelRid],
							[wAddress],
							[wWorkHours],
							[wRegion],
							[wNoOfSeat],
							[wIsSign],
							[wIsBtm],
							[wMinCharge],
							[wMenu],
							[wStatus],
							[wSeqNo],
							[wCrtDt],
							[wCrtBy],
							[wUpdDt],
							[wUpdBy],
							[wAwards],
							[wDressRequire]
					 )
					SELECT
							s.[RowID],
							s.[wName],
							s.[wCuisine],
							s.[wLevel],
							s.[wPhone],
							s.[wHotelRid],
							s.[wAddress],
							s.[wWorkHours],
							s.[wRegion],
							s.[wNoOfSeat],
							s.[wIsSign],
							s.[wIsBtm],
							s.[wMinCharge],
							s.[wMenu],
							s.[wStatus],
							s.[wSeqNo],
							dbo.fnUTC8Now(),
							s.[wCrtBy],
							dbo.fnUTC8Now(),
							s.[wUpdBy],
							s.[wAwards],
							s.[wDressRequire]

					FROM    #sDataSet_SetRestaurant s;  
				
					END;                   
					---------------------------------------------------------                
					ELSE IF @pActionType = 'U' 
					BEGIN                  
					 UPDATE bpp                  
										SET
											[wName] = tmp.[wName],
											[wCuisine] = tmp.[wCuisine],
											[wLevel] = tmp.[wLevel],
											[wPhone] = tmp.[wPhone],
											[wHotelRid] = tmp.[wHotelRid],
											[wAddress] = tmp.[wAddress],
											[wWorkHours] = tmp.[wWorkHours],
											[wRegion] = tmp.[wRegion],
											[wNoOfSeat] = tmp.[wNoOfSeat],
											[wIsSign] = tmp.[wIsSign],
											[wIsBtm] = tmp.[wIsBtm],
											[wMinCharge] = tmp.[wMinCharge],
											[wMenu] = tmp.[wMenu],
											[wStatus] = tmp.[wStatus],
											[wSeqNo] = tmp.[wSeqNo],
											[wCrtDt] = tmp.[wCrtDt],
											[wCrtBy] = tmp.[wCrtBy],
											[wUpdDt] = dbo.fnUTC8Now(),
											[wUpdBy] = tmp.[wUpdBy],
											[wAwards] = tmp.[wAwards],
											[wDressRequire]=tmp.[wDressRequire]
										FROM    dbo.[mRestaurant] AS bpp                  
												INNER JOIN #sDataSet_SetRestaurant tmp ON bpp.RowID = tmp.RowID                  
										WHERE   bpp.RowID = tmp.RowID;                  
                                          
					END;                  
					 ELSE                                    
					 IF @pActionType = 'D'                  
					 BEGIN                                           
					   UPDATE dbo.[mRestaurant]                 
						SET                   
						wStatus = 'T',
						wUpdDt = dbo.fnUTC8Now()                    
					   WHERE RowID IN (SELECT RowID FROM #sDataSet_SetRestaurant );                  
                             
                     END;                  
    

				IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

		-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetRestaurant;

            RETURN ;
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

            IF ISNULL(@rErrCode, 0) = 0
                BEGIN
                    SET @rErrCode = 999;
                END;
            SET @rErrMsg = CONCAT(@rErrMsg, CHAR(10), '(', @sErrorNum, ') ',
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
                @rErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH;    
		
		  EXEC sp_xml_removedocument @sDocHandle;

		IF OBJECT_ID('tempdb..#sDataSet_SetRestaurant') IS NOT NULL
			DROP TABLE #sDataSet_SetRestaurant              
END;