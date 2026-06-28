
CREATE PROCEDURE [spa].[SetShiftDetails]  

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
	    BEGIN TRY

		--SELECT * FROM mShift;

	    DECLARE @sThisTableName VARCHAR(50) = 'SetShiftDetails' ,-- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
				        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
		DECLARE @sErrorMsg VARCHAR(MAX)='';
	        
        SET @sBeginTranCount = @@trancount;
       
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetShiftDetails
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
			RowID bigint ,
             wName  nvarchar(50),
             wCode varchar(10) ,
             wDepartmentCd varchar(30) ,
             wStatus  char (1) ,
             wSeqNo int ,
             wCrtDt DATETIME2(7),
             wCrtBy  bigint ,
             wUpdDt DATETIME2(7),
			 wUpdBy bigint  
		  			 			)

		IF @sBeginTranCount = 0 BEGIN
			BEGIN TRANSACTION;
	    END		

		 IF @pActionType ='U'
			BEGIN

				SELECT @sErrorMsg=CASE WHEN  tmp.wDepartmentCd<>ms.wDepartmentCd THEN 'Department cannot be changed for terminated shift handover.'
									   WHEN  tmp.wName<>ms.wName THEN 'Shift period cannot be changed for terminated shift handover.'									  
								  END
				FROM #sDataSet_SetShiftDetails tmp inner join mShift ms on tmp.RowId=ms.RowID WHERE ms.wStatus='T';

			END
		
	    IF @pActionType IN ('I','U') AND @sErrorMsg=''        
			BEGIN
			  SELECT @sErrorMsg= CASE WHEN ISNULL(tmp.wDepartmentCd,'')='' THEN 'Department is missing.'
									  WHEN ISNULL(tmp.wName,'')='' THEN 'Shift Period is missing.'
									  WHEN ISNULL(tmp.wStatus,'')='' THEN 'Shift Status is missing.'
								 END
			  FROM #sDataSet_SetShiftDetails tmp
			END
		
	           
		IF @sErrorMsg<>''
			THROW 50000,@sErrorMsg,5;
		         
        IF @pActionType = 'I'
            BEGIN
			-- Set RowID by Sequence
                UPDATE  #sDataSet_SetShiftDetails
                SET     RowID = 0;
                SELECT  @sRecCount = COUNT(*)
                FROM    #sDataSet_SetShiftDetails;
                WHILE @sRuningIndex <= @sRecCount
                    BEGIN
                        EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                            @sRowID OUTPUT;
					
                        UPDATE  #sDataSet_SetShiftDetails
                        SET     RowID = @sRowID
                        WHERE   wRowNum = @sRuningIndex;
                        SET @sRuningIndex = @sRuningIndex + 1;
                    END;    		        
								
			 

			-- MAIN Logic here, example here is inserting dataset to mSpa
                INSERT  INTO dbo.[mShift]
                        (
							[RowID],
						    [wName],
							[wCode],
						    [wDepartmentCd],
							[wStatus],
							[wSeqNo],
							[wCrtDt],
							[wCrtBy],
						    [wUpdDt],
						    [wUpdBy]

					 )

                        SELECT
	            	           
							    s.RowID ,
						        s.wName,
						        s.wCode,
						        s.wDepartmentCd,
						        s.wStatus ,
						        s.wSeqNo ,
						        s.wCrtDt ,
						        s.wCrtBy ,
						        s.wUpdDt ,
						        s.wUpdBy 
								
                        FROM   #sDataSet_SetShiftDetails s;

            END;

		ELSE IF @pActionType = 'U'
		  BEGIN
              IF EXISTS (SELECT 1 FROM #sDataSet_SetShiftDetails ds INNER JOIN CRM.dbo.mShiftHandover e ON e.wShiftRid=ds.RowID WHERE ds.wStatus='T')
                  BEGIN
                      SET @pErrMsg =N'更期類型已被使用,不能删除或终止';
                  END;
              ELSE
                  BEGIN    	
						UPDATE  met SET
						         met.wName=tmp.wName,
						        met.wCode=tmp.wCode,
						        met.wDepartmentCd=tmp.wDepartmentCd,
						        met.wStatus=tmp.wStatus,
						        met.wSeqNo=tmp.wSeqNo,
						        met.wUpdDt=tmp.wUpdDt,
						        met.wUpdBy=tmp.wUpdBy
															
								FROM    dbo.mShift  AS met
										INNER JOIN #sDataSet_SetShiftDetails tmp ON met.RowID = tmp.RowID
								WHERE   met.RowID = tmp.RowID;
                  END;

	 	    END;
        ELSE IF @pActionType = 'D'
          BEGIN
               IF EXISTS (SELECT 1 FROM #sDataSet_SetShiftDetails ds INNER JOIN CRM.dbo.mShiftHandover e ON e.wShiftRid=ds.RowID )
                   BEGIN
                       SET @pErrMsg =N'更期類型已被使用,不能删除或终止';
                   END;
               ELSE
                   BEGIN
						 UPDATE  met
                         SET
							met.wStatus = 'T',wUpdDt = dbo.fnUTC8Now() 
						FROM    dbo.mShift AS met
                        INNER JOIN #sDataSet_SetShiftDetails tmp ON met.RowID = tmp.RowID
                        WHERE   met.RowID = tmp.RowID;
                    END;        
                    END;

	
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
            SELECT  RowID
                FROM    #sDataSet_SetShiftDetails;

           
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

		IF OBJECT_ID('tempdb..#sDataSet_SetShiftDetails') IS NOT NULL
			DROP TABLE #sDataSet_SetShiftDetails

		END