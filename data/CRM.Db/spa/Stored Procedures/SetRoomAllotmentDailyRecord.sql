CREATE PROCEDURE [spa].[SetRoomAllotmentDailyRecord]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
	)
AS
    BEGIN
        SET NOCOUNT ON;

			--Select RowId,wAllotmentQty,wUpdBy,wStatus,wIsCustomized from eAllotmentHotelDaily
	
        DECLARE @sThisTableName VARCHAR(50) = 'eAllotmentHotelDaily' , -- For RowID
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
	    	    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowId ) ,
                *
        INTO    #sDataSet_SetRoomAllotmentDailyRecord
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
			WITH (

					RowId BIGINT ,
					wAllotmentQty INT,
					wStatus CHAR(1),
					wUpdBy BIGINT,
					wIsCustomized CHAR(1)
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
	        
           
            IF @pActionType = 'U'
                BEGIN
                    UPDATE  met
                    SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
                            met.wAllotmentQty = tmp.wAllotmentQty ,
                            met.wStatus = tmp.wStatus ,
                            met.wUpdBy = tmp.wUpdBy ,
                            met.wIsCustomized = tmp.wIsCustomized,
                            met.wUpdDt = dbo.fnUTC8Now()
                    FROM    dbo.eAllotmentHotelDaily AS met
                            INNER JOIN #sDataSet_SetRoomAllotmentDailyRecord tmp ON met.RowId = tmp.RowId
                    WHERE   met.RowId = tmp.RowId;
                END;
            ELSE
                IF @pActionType = 'D'
                    BEGIN

                        UPDATE  dbo.eAllotmentHotelDaily
                        SET     wStatus = 'T' ,
                                wUpdDt = dbo.fnUTC8Now()
                        WHERE   RowId IN ( SELECT   RowId
                                           FROM     #sDataSet_SetRoomAllotmentDailyRecord );
									
                    END;

	
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

						-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowId
                FROM    #sDataSet_SetRoomAllotmentDailyRecord;

							
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

        IF OBJECT_ID('tempdb..#sDataSet_SetRoomAllotmentDailyRecord') IS NOT NULL
            DROP TABLE #sDataSet_SetRoomAllotmentDailyRecord
		
    END;