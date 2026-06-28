CREATE PROCEDURE [spa].[SetDepartmentTeam]
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
		--select * from mDepartmentTeam;
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
				[RowID] [bigint],
				[wCode] [varchar](10) ,
				[wName] [nvarchar](20) ,
				[wDepartment] [varchar](20) ,
				[wRegion] [varchar](20) ,
				[wStatus] [char](1) ,
				[wSeqNo] [int] ,
				[wCrtDt] [datetime2](7) ,
				[wCrtBy] [bigint] ,
				[wUpdDt] [datetime2](7) ,
				[wUpdBy] [bigint]
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
                    INSERT  INTO dbo.[mDepartmentTeam]
                            (
								[RowID],
								[wCode],
								[wName],
								[wDepartment],
								[wRegion],
								[wStatus],
								[wSeqNo],
								[wCrtDt],
								[wCrtBy],
								[wUpdDt],
								[wUpdBy]							    
							)
                            SELECT
	            	            s.[RowID] ,
								s.[wCode] ,
								s.[wName] ,
								s.[wDepartment] ,
								s.[wRegion] ,
								s.[wStatus] ,
								s.[wSeqNo],
								dbo.fnUTC8Now(),
								s.wUpdBy ,
								dbo.fnUTC8Now(),									
								s.wUpdBy 						
                            FROM    #sDataSet_SetRoute s;


                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  met
                        SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
								met.[wCode] = tmp.wCode ,
								met.[wName] = tmp.wName ,
								met.[wDepartment]= tmp.wDepartment ,
								met.[wRegion]= tmp.wRegion ,
								met.[wStatus]= tmp.wStatus ,
								met.wSeqNo= tmp.wSeqNo ,
                                met.wUpdBy = tmp.wUpdBy ,
                                met.wUpdDt = dbo.fnUTC8Now()
                        FROM    dbo.[mDepartmentTeam] AS met
            INNER JOIN #sDataSet_SetRoute tmp ON met.RowID = tmp.RowID
                        WHERE   met.RowID = tmp.RowID;
                    END;
                ELSE
				IF @pActionType = 'D'
                        BEGIN						
                           UPDATE dbo.[mdepartmentteam]
								SET 
								wStatus='T'
								WHERE   RowID IN (SELECT RowID FROM #sdataset_setroute );
                        END;
	
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

            -- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sdataset_setroute;

           RETURN
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

		IF OBJECT_ID('tempdb..#sDataSet_SetRoute') IS NOT NULL DROP TABLE #sDataSet_SetRoute
		
    END;