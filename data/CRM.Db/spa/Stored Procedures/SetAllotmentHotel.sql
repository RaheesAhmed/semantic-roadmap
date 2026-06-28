CREATE PROCEDURE [spa].[SetAllotmentHotel]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pAllotmentHotelRid BIGINT OUTPUT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT     
	)
AS
    BEGIN
        SET NOCOUNT ON;		
		
		--Select * from eAllotmentHotel 

        DECLARE @sThisTableName VARCHAR(50) = 'eAllotmentHotel' , -- For RowID
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
        INTO    #sDataSet_SetAllotmentHotel
        FROM    OPENXML (@sDocHandle, 'DataSet/SetAllotmentHotelResult', 1)
        WITH (
                RowID BIGINT ,
                wHotelRid BIGINT,
                wRoomRid BIGINT,
                wIsSpecialDate CHAR(1),
                wStartDate DATE,
                wEndDate DATE,
                wStatus CHAR(1) ,				
                wSeqNo INT ,				
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
                    UPDATE  #sDataSet_SetAllotmentHotel
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetAllotmentHotel;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetAllotmentHotel
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;
						       
                    SET @pAllotmentHotelRid = @sRowID;

				-- MAIN Logic here, example here is inserting dataset
                    INSERT  INTO dbo.[eAllotmentHotel]
                            ( [RowID] ,
                              [wHotelRid] ,
                              [wRoomRid] ,
                              [wIsSpecialDate] ,
                              [wStartDate] ,
                              [wEndDate] ,
                              [wStatus] ,
                              [wSeqNo] ,
                              [wCrtBy] ,
                              [wCrtDt] ,
                              [wUpdBy] ,
                              [wUpdDt]
								
							)
                            SELECT  s.RowID ,
                                    s.wHotelRid ,
                                    s.wRoomRid ,
                                    s.wIsSpecialDate ,
                                    s.wStartDate ,
                                    s.wEndDate ,
                                    s.wStatus ,
                                    s.wSeqNo ,
                                    s.wUpdBy ,
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy ,
                                    dbo.fnUTC8Now()
                            FROM    #sDataSet_SetAllotmentHotel s;


                END; 
            IF @pActionType = 'U'
                BEGIN
                   UPDATE  met
                   SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
                      met.wHotelRid = tmp.wHotelRid ,
                      met.wRoomRid = tmp.wRoomRid ,
                      met.wStartDate = tmp.wStartDate ,
                      met.wEndDate = tmp.wEndDate ,
                      met.wStatus = tmp.wStatus ,
                      met.wSeqNo = tmp.wSeqNo ,
                      met.wUpdBy = tmp.wUpdBy ,
                      met.wUpdDt = dbo.fnUTC8Now() ,
                      @pAllotmentHotelRid = met.RowID 
                   FROM dbo.eAllotmentHotel AS met
                   INNER JOIN #sDataSet_SetAllotmentHotel tmp ON met.RowID = tmp.RowID
                   WHERE met.RowID = tmp.RowID;                   
                END;
            ELSE
                IF @pActionType = 'D'
                    BEGIN                     
                       UPDATE  met
                       SET met.wStatus = 'T' , 
                           wUpdDt = dbo.fnUTC8Now() ,
                           wUpdBy = tmp.wUpdBy
                       FROM dbo.eAllotmentHotel AS met
                       INNER JOIN #sDataSet_SetAllotmentHotel tmp ON met.RowID = tmp.RowID
                       WHERE met.RowID = tmp.RowID;                                                  		
                    END;    

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;  
				
		-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetAllotmentHotel;		         

            RETURN;
	
        END TRY
        BEGIN CATCH
            DECLARE @vErrorNum INT ,
                @vCatchErrorMessage NVARCHAR(4000) ,
                @xstate INT ,
                @vProcedureName VARCHAR(100) ,
                @vRtnCodeLog INT ,
                @vErrMessageLog NVARCHAR(4000);
	        
            SET @vErrorNum = ERROR_NUMBER();
            SET @vCatchErrorMessage = ERROR_MESSAGE();
            SET @xstate = XACT_STATE();
            SET @vProcedureName = OBJECT_NAME(@@PROCID);
			
            IF ISNULL(@pErrCode, 0) = 0
                BEGIN
                    SET @pErrCode = 999;
                END;
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @vErrorNum, ') ', @vCatchErrorMessage);
			
            IF @sBeginTranCount = 0
                BEGIN
                    IF @xstate != 0
                        ROLLBACK;
                    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT, @vErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;

        END CATCH;
	
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetAllotmentHotel') IS NOT NULL
            DROP TABLE #sDataSet_SetAllotmentHotel;
		
    END;