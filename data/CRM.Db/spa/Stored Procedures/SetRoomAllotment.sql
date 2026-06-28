CREATE PROCEDURE [spa].[SetRoomAllotment]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pRoomAllotmentNameRid BIGINT OUTPUT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
    
	)
AS
    BEGIN
        SET NOCOUNT ON;			

		--SELECT * FROM [mAllotmentGroup]

        DECLARE @sThisTableName VARCHAR(50) = 'mAllotmentGroup' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
		 
        SET @sBeginTranCount = @@trancount;			
	        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
	    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetRoomAllotment
        FROM    OPENXML (@sDocHandle, 'DataSet/SetRoomAllotmentResult', 1)
		WITH (
				RowID BIGINT,
				wCode VARCHAR(20),
				wName NVARCHAR(200),
				wRemark NVARCHAR(400),
				wSeqNo INT ,
				wStatus CHAR(1) ,
				wUpdBy BIGINT ,
				wUpdDt DATETIME2(7),
                wDept NVARCHAR(20)
			);

		IF @pActionType = 'U' 
		   AND EXISTS(SELECT 1 FROM dbo.eBookingRoom AS br INNER JOIN #sDataSet_SetRoomAllotment AS da ON br.wAllotmentGroupRid = da.RowID AND da.wStatus = 'T' AND br.wStatus = 'A')
			THROW 50001, 'Cannot terminate using alloment group ', 1;

        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
	
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
		        	        
            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetRoomAllotment
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetRoomAllotment;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetRoomAllotment
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
                    SET @pRoomAllotmentNameRid = @sRowID;
				-- MAIN Logic here, example here is inserting dataset
                    INSERT  INTO dbo.[mAllotmentGroup]
                            ( [RowID] ,
                              [wCode] ,
                              [wName] ,
                              [wRemark] ,
                              [wSeqNo] ,
                              [wStatus] ,
                              [wCrtDt] ,
                              [wCrtBy] ,
                              [wUpdDt] ,
                              [wUpdBy],
                              [wDept]
							)
                            SELECT  s.RowID ,
                                    s.wCode ,
                                    s.wName ,
                                    s.wRemark ,
                                    s.wSeqNo ,
                                    s.wStatus ,
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy ,
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy,
                                    s.wDept
                            FROM    #sDataSet_SetRoomAllotment s;


                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        IF EXISTS (SELECT 1 FROM #sDataSet_SetRoomAllotment ds INNER JOIN CRM.dbo.eBookingRoom r ON r.wAllotmentGroupRid=ds.RowID WHERE ds.wStatus='T')
                           BEGIN
                               SET @pErrMsg =N'该房間配額類型已被使用,不能删除或终止';	
                           END;

                        ELSE
                           BEGIN
                               UPDATE  met
                               SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
                                       met.wCode = tmp.wCode ,
                                       met.wName = tmp.wName ,
                                       met.wRemark = tmp.wRemark ,
                                       met.wSeqNo = tmp.wSeqNo ,
                                       met.wStatus = tmp.wStatus ,
                                       met.wUpdBy = tmp.wUpdBy ,
                                       met.wUpdDt = dbo.fnUTC8Now() ,
                                       @pRoomAllotmentNameRid = tmp.RowID,
                                       met.wDept=tmp.wDept
                               FROM    dbo.mAllotmentGroup AS met
                                       INNER JOIN #sDataSet_SetRoomAllotment tmp ON met.RowID = tmp.RowID
                               WHERE   met.RowID = tmp.RowID;
                          END;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN
                        IF EXISTS (SELECT 1 FROM #sDataSet_SetRoomAllotment ds INNER JOIN CRM.dbo.eBookingRoom r ON r.wAllotmentGroupRid=ds.RowID)
                           BEGIN
                               SET @pErrMsg =N'该房間配額類型已被使用,不能删除或终止';	
                           END;

                        ELSE
                           BEGIN
                               UPDATE  met
                               SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string																					
                                       met.wStatus = 'T' ,
                                       wUpdDt = dbo.fnUTC8Now()
                               FROM    dbo.mAllotmentGroup AS met
                                       INNER JOIN #sDataSet_SetRoomAllotment tmp ON met.RowID = tmp.RowID
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
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ', @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0
                AND ( @xstate = 1
                      OR @xstate = -1
                    )
                BEGIN
				-- transaction created within this sp
                    ROLLBACK;
                END;
	        
	        -- Write Log
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH;

        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetRoomAllotment') IS NOT NULL
            DROP TABLE #sDataSet_SetRoomAllotment
		
    END;