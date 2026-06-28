
CREATE PROCEDURE [spa].[SetShiftHandoverDetails]  

    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT,
	  @pNonceToken VARCHAR(64), 
	  @pReturnResultSet CHAR(1) = 'N',
	  @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT 
	)
AS
    BEGIN
        SET NOCOUNT ON;

		--SELECT *FROM [mShiftHandover]
	    
		BEGIN TRY

	    DECLARE @sThisTableName VARCHAR(50) = 'SetShiftHandover' ,-- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
				        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
		DECLARE @sErrorMsg varchar(max);
	        
        SET @sBeginTranCount = @@trancount;
       
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetShiftHandoverDetails
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
			RowID bigint ,
             wShiftDt  date,
             wDepartment varchar(30) ,
             wShiftRid bigint,
             wCounterRid bigint,
             wStatus  char (1) ,
             wRemark nvarchar(500),
             wSeqNo int ,
             wCrtDt DATETIME2(7),
             wCrtBy  bigint ,
             wUpdDt DATETIME2(7),
			 wUpdBy bigint  
		  			 			)

		IF @pActionType ='U'
			BEGIN

				SELECT @sErrorMsg=CASE WHEN  tmp.wCounterRid<>msh.wCounterRid THEN 'Service counter value cannot be changed for terminated shift handover'
									   WHEN  tmp.wShiftRid<>msh.wShiftRid THEN 'Shift period cannot be changed for terminated shift handover'
									   WHEN  tmp.wDepartment<>msh.wDepartment THEN 'Department cannot be changed for terminated shift handover'									  
								  END
									 FROM #sDataSet_SetShiftHandoverDetails tmp inner join mShiftHandover msh on tmp.RowId=msh.RowID WHERE msh.wStatus='T';

			END

		
		IF @pActionType IN ('I','U') AND @sErrorMsg=''
			BEGIN

				SELECT @sErrorMsg=CASE WHEN  tmp.wCounterRid<=0 THEN 'Service Counter is missing'
									   WHEN  tmp.wShiftRid<=0 THEN 'Shift period is missing'
									   WHEN  ISNULL(tmp.wDepartment,'')='' THEN 'Department is missing'
									   WHEN  ISNULL(tmp.wStatus,'')=''  THEN 'Status is missing'
								  END
									 FROM #sDataSet_SetShiftHandoverDetails tmp;

			END
		
	           
		IF @sErrorMsg<>''
			THROW 50000,@sErrorMsg,5;
		         
        IF @pActionType = 'I'
            BEGIN
			-- Set RowID by Sequence
                UPDATE  #sDataSet_SetShiftHandoverDetails
                SET     RowID = 0;
                SELECT  @sRecCount = COUNT(*)
                FROM    #sDataSet_SetShiftHandoverDetails;
                WHILE @sRuningIndex <= @sRecCount
                    BEGIN
                        EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                            @sRowID OUTPUT;
					
                        UPDATE  #sDataSet_SetShiftHandoverDetails
                        SET     RowID = @sRowID
                        WHERE   wRowNum = @sRuningIndex;
                        SET @sRuningIndex = @sRuningIndex + 1;
                    END;    		        
								
			 

			-- MAIN Logic here, example here is inserting dataset to mSpa
                INSERT  INTO dbo.[mShiftHandover]
                        (
							[RowID],
						    [wShiftDt],
							[wDepartment],
						    [wShiftRid],
						    [wCounterRid],
							[wStatus],
							[wRemark],
							[wSeqNo],
							[wCrtDt],
							[wCrtBy],
						    [wUpdDt],
						    [wUpdBy]

					 )

                        SELECT
	            	           
							    s.RowID ,
						        s.wShiftDt,
						        s.wDepartment,
						        s.wShiftRid,
						        s.wCounterRid,
						        s.wStatus ,
						        s.wRemark,
						        s.wSeqNo ,
						        s.wCrtDt ,
						        s.wCrtBy ,
						        s.wUpdDt ,
						        s.wUpdBy 
								
                        FROM   #sDataSet_SetShiftHandoverDetails s;

            END;

		ELSE IF @pActionType = 'U'
		  BEGIN
						UPDATE  met SET
						         met.wShiftDt=tmp.wShiftDt,
						        met.wDepartment=tmp.wDepartment,
						        met.wShiftRid=tmp.wShiftRid,
						        met.wCounterRid=tmp.wCounterRid,
						        met.wStatus=tmp.wStatus,
						        met.wRemark=tmp.wRemark,
						        met.wSeqNo=tmp.wSeqNo,
						        met.wUpdDt=tmp.wUpdDt,
						        met.wUpdBy=tmp.wUpdBy
															
								FROM    dbo.mShiftHandover  AS met
										INNER JOIN #sDataSet_SetShiftHandoverDetails tmp ON met.RowID = tmp.RowID
								WHERE   met.RowID = tmp.RowID;

	 	    END;
        ELSE IF @pActionType = 'D'
          BEGIN

						 UPDATE  met
                         SET
							met.wStatus = 'T',wUpdDt = dbo.fnUTC8Now()
						FROM    dbo.mShiftHandover AS met
 INNER JOIN #sDataSet_SetShiftHandoverDetails tmp ON met.RowID = tmp.RowID
    WHERE   met.RowID = tmp.RowID;
                            
                    END;

	
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetShiftHandoverDetails;
           
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

		IF OBJECT_ID('tempdb..#sDataSet_SetShiftHandoverDetails') IS NOT NULL
			DROP TABLE #sDataSet_SetShiftHandoverDetails

		END