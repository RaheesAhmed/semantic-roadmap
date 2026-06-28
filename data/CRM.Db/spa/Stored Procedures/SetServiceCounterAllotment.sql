
CREATE PROCEDURE [spa].[SetServiceCounterAllotment]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
	  @pNonceToken VARCHAR(64), 
	  @pReturnResultSet CHAR(1) = 'N',
	  @pRoomAllotmentRid BIGINT OUTPUT,
	  @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
	)
AS
    BEGIN
        SET NOCOUNT ON;	
		
		------ start for creating the dmbl generated class
		--SELECT  
		--mrasc.RowID,
		--mrasc.wAllotmentGroupRid,
		--mrasc.wCounterRid,
		--msc.wCode,
		--msc.wName,
		--msc.wSmsRoomID,
		--msc.wRollexCompNo,
		--msc.wRegion,
		--msc.wDefaultHotelCode,
		--msc.wCurrCode,
		--msc.wRemark,				
		--mrasc.RowID wSeqNo,
		--mrasc.wCrtDt,
		--mrasc.wCrtBy,
		--mrasc.wUpdDt,
		--mrasc.wUpdBy,
		--msc.wStatus
  --      FROM  dbo.mAllotmentGroupDtl mrasc
		--inner join dbo.mAllotmentGroup mrl on mrl.RowID = mrasc.wAllotmentGroupRid
		--inner join dbo.mServiceCounter msc ON msc.RowID = mrasc.wCounterRid
		------ end for creating the dmbl generated class		

	    DECLARE @sThisTableName VARCHAR(50) = 'mAllotmentGroupDtl', -- For Service Counter RowID				
		    @sBeginTranCount INT = 0 ,            
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
			            	             	    
        SET @sBeginTranCount = @@trancount;

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetServiceCounterAllotment
        FROM    OPENXML (@sDocHandle, 'DataSet/SetServiceCounterAllotmentResult', 1)
		WITH (
				RowID BIGINT ,						
				wCounterRid BIGINT,						
				wSeqNo INT,
				wStatus CHAR(1),
				wUpdBy BIGINT ,
				wUpdDt DATETIME2(7)
			);
		
		 --better don't put everything within try, for example       
      		    -- Try to make the transaction scope as small as possible to reduce locking    
				
		 BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
	
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;		        
	        
            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetServiceCounterAllotment
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetServiceCounterAllotment;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetServiceCounterAllotment
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        												

							INSERT  INTO dbo.[mAllotmentGroupDtl]
                             (
								[RowID] ,
								[wAllotmentGroupRid],
								[wCounterRid],
								[wStatus] ,
								[wCrtBy] ,
								[wCrtDt] ,
								[wUpdBy] ,
								[wUpdDt] 
							)
                            SELECT
									s.RowID,
									@pRoomAllotmentRid,
	            					wCounterRid,									
									s.wStatus,
									s.wUpdBy ,
									dbo.fnUTC8Now(),
									s.wUpdBy ,
									dbo.fnUTC8Now()
                            FROM    #sDataSet_SetServiceCounterAllotment s;
					END;  
				ELSE
					IF @pActionType = 'U'
                    BEGIN
						
					   DELETE mAllotmentGroupDtl WHERE wAllotmentGroupRid = @pRoomAllotmentRid

					UPDATE  #sDataSet_SetServiceCounterAllotment
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetServiceCounterAllotment;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetServiceCounterAllotment
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		
						      
					   INSERT  INTO dbo.[mAllotmentGroupDtl]
   (
								[RowID] ,
								[wAllotmentGroupRid],
								[wCounterRid],
								[wStatus] ,
								[wCrtBy] ,
								[wCrtDt] ,
								[wUpdBy] ,
								[wUpdDt] 
							)
                            SELECT
									s.RowID,
									@pRoomAllotmentRid,
	            					wCounterRid,									
									s.wStatus ,
									s.wUpdBy ,
									dbo.fnUTC8Now(),
									s.wUpdBy ,
									dbo.fnUTC8Now()
                            FROM    #sDataSet_SetServiceCounterAllotment s;
																		
                    END;          

           
           IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;		
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetServiceCounterAllotment;
         			
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

		IF OBJECT_ID('tempdb..#sDataSet_SetServiceCounterAllotment') IS NOT NULL
			DROP TABLE #sDataSet_SetServiceCounterAllotment
		
    END;