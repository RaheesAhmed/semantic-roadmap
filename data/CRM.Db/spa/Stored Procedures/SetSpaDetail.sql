CREATE PROCEDURE [spa].[SetSpaDetail]  
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
		--SELECT * FROM [mSpa]
	    DECLARE @sThisTableName VARCHAR(50) = 'SetSpaDetail' ,-- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
				        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
        SET @sBeginTranCount = @@trancount;
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetSpaDetail
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
			   RowID bigint ,
               wName  nvarchar(100),
               wPhone VARCHAR(50) ,
               wHotelRid Bigint ,
               wAddress  nvarchar(300) ,
               wWorkHours Nvarchar(400) ,
               wRemark Nvarchar(500) ,
               wStatus  varchar (2) ,
               wSeqNo int ,
               wCrtDt DATETIME2(7),
               wCrtBy  bigint ,
               wUpdDt DATETIME2(7),
			   wUpdBy bigint  
		  	)
		 
		 DECLARE @errorMsg varchar(max);	
			--- Spa Details Required Field Validation
			IF  @pActionType IN ('I', 'U') BEGIN
			select @errorMsg = CASE 
									WHEN RTRIM(ISNULL(spa.wName,'')) = '' THEN 'Spa Name is Missing' 
									WHEN RTRIM(ISNULL(spa.wStatus,'')) = '' THEN 'Status is Missing'
								END
			from #sDataSet_SetSpaDetail spa
			END
			IF @errorMsg <> ''
				throw 50001, @errorMsg, 1;	
			--- Spa Details Required Field Validation end

			--- Spa Details Delete Validation
			ELSE IF @pActionType = 'D' BEGIN
			select @errorMsg = CASE
									WHEN ms.wStatus <> ('A') THEN 'Spa Details can not be deleted if Status Code is '+ ms.wStatus
								END
				from mSpa ms INNER JOIN
				#sDataSet_SetSpaDetail spa on ms.RowID=spa.RowID			   
			END

			IF @errorMsg <> ''
			throw 50001, @errorMsg, 1;
			--- Spa Details Delete Validation end
		         
			BEGIN TRY
			-- Try to make the transaction scope as small as possible to reduce locking
	
			IF @sBeginTranCount = 0
				BEGIN
					BEGIN TRAN;
				END;

        IF @pActionType = 'I'
            BEGIN
			-- Set RowID by Sequence
                UPDATE  #sDataSet_SetSpaDetail
                SET     RowID = 0;
                SELECT  @sRecCount = COUNT(*)
                FROM    #sDataSet_SetSpaDetail;
                WHILE @sRuningIndex <= @sRecCount
                    BEGIN
                        EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                            @sRowID OUTPUT;
					
                        UPDATE  #sDataSet_SetSpaDetail
                        SET     RowID = @sRowID
                        WHERE   wRowNum = @sRuningIndex;
                        SET @sRuningIndex = @sRuningIndex + 1;
                    END;    		        

			-- MAIN Logic here, example here is inserting dataset to mSpa
             INSERT  INTO dbo.[mSpa]
				(
					[RowID],
					[wName],
					[wPhone],
					[wHotelRid],
					[wAddress],
					[wWorkHours],
					[wRemark],
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
					s.wPhone,
					s.wHotelRid,
					s.wAddress,
					s.wWorkHours ,
					s.wRemark ,
					s.wStatus ,
					s.wSeqNo ,
					s.wCrtDt ,
					s.wCrtBy ,
					s.wUpdDt ,
					s.wUpdBy 
                FROM   #sDataSet_SetSpaDetail s;
            END;

		ELSE IF @pActionType = 'U'
			BEGIN
                IF EXISTS (SELECT 1 FROM #sDataSet_SetSpaDetail ds INNER JOIN CRM.dbo.eAdditionalExpense e ON e.wSpaRid=ds.RowID WHERE ds.wStatus='T')
                   BEGIN
                       SET @pErrMsg =N'该Spa類型已被使用,不能删除或终止';	
                   END;	
                ELSE 
                   BEGIN
				       UPDATE  met SET
				       	met.wName=tmp.wName,
				       	met.wPhone=tmp.wPhone,
				       	met.wHotelRid=tmp.wHotelRid,
				       	met.wAddress=tmp.wAddress,
				       	met.wWorkHours=tmp.wWorkHours,
				       	met.wRemark=tmp.wRemark,
				       	met.wStatus=tmp.wStatus,
				       	met.wSeqNo=tmp.wSeqNo,
				       	met.wUpdDt=tmp.wUpdDt,
				       	met.wUpdBy=tmp.wUpdBy
				       	
				       FROM    dbo.mSpa  AS met
				       INNER JOIN #sDataSet_SetSpaDetail tmp ON met.RowID = tmp.RowID
				       WHERE   met.RowID = tmp.RowID;
                   END;
	 	    END;
        ELSE IF @pActionType = 'D'
          BEGIN
              IF EXISTS (SELECT 1 FROM #sDataSet_SetSpaDetail ds INNER JOIN CRM.dbo.eAdditionalExpense e ON e.wSpaRid=ds.RowID )
                 BEGIN
                     SET @pErrMsg =N'该Spa類型已被使用,不能删除或终止';	
                 END;	
            ELSE
                BEGIN
                    UPDATE  met SET
				    met.wStatus = 'T',
				    met.wUpdDt = dbo.fnUTC8Now()   
				    FROM dbo.mSpa AS met
                    INNER JOIN #sDataSet_SetSpaDetail tmp ON met.RowID = tmp.RowID
                    WHERE met.RowID = tmp.RowID;
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
                FROM    #sDataSet_SetSpaDetail;
            
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

		IF OBJECT_ID('tempdb..#sDataSet_SetSpaDetail') IS NOT NULL
			DROP TABLE #sDataSet_SetSpaDetail
		END