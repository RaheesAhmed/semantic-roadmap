CREATE PROCEDURE [spa].[SetAllotmentTicket]
(
  @pXML XML ,
  @pActionType CHAR(1) , -- I/U/D
  @pMainCompNo INT ,	 
  @pNonceToken VARCHAR(64), 
  @pReturnResultSet CHAR(1) = 'N',
  @pBookingRId BigINT,
  @pErrCode INT = 0 OUTPUT ,
  @pErrMsg NVARCHAR(200) = '' OUTPUT
)
AS
    BEGIN
        SET NOCOUNT ON;	

		--SELECT '' as wSvCtrName,'' as wRoute,'' AS wBookingClassCd,'' AS wTicketStatus,'' AS IssueLocationName,'' AS wBookingClassCdName, '' as wTicketTypeName,* from eAllotmentTicket

	    DECLARE @sThisTableName VARCHAR(50) = 'eAllotmentTicket' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;	        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );	
		
		SET @sBeginTranCount = @@trancount;
		    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetAllotmentTicket
        FROM    OPENXML (@sDocHandle, 'DataSet/SetAllotmentTicketResult', 1)
		WITH (
				RowID BIGINT ,				
				wTicketNo VARCHAR(30),
				wSvCtrCode NVARCHAR(15),
				wCounterRid BIGINT,
				wExpiryDate DATE,
				wTicketType VARCHAR(30),
				wRouteRid BIGINT,
				wBookingClassCd VARCHAR(50),
				wAmount NUMERIC(18,4),
				wTicketStatus VARCHAR(30),
				wBookingRid BIGINT,
				wUpdBy BIGINT ,
				wUpdDt DATETIME2(7)
			);	     
			
			BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
				   
            IF @pActionType = 'I'
                BEGIN   
					--UPDATE  #sDataSet_SetAllotmentTicket
     --               SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetAllotmentTicket;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN                         
					
                            UPDATE  #sDataSet_SetAllotmentTicket
                            SET  	wBookingRid = @pBookingRId
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END; 				
						
						UPDATE  eat
                        SET     eat.wAllotmentStatus = 'I',
								eat.wBookingRid = s.wBookingRid,								
                                eat.wUpdBy = s.wUpdBy ,
                                eat.wUpdDt = dbo.fnUTC8Now()								
                        FROM    dbo.eAllotmentTicket AS eat
                                INNER JOIN #sDataSet_SetAllotmentTicket s ON eat.RowID = s.RowID 
								WHERE s.wTicketStatus = 'N'                    
				
				END;
			ELSE
				IF @pActionType = 'U'
                        BEGIN						
						--Update status for eAllotmentTicket as Used
							UPDATE  ea
							SET     
								ea.wAllotmentStatus = 'I',
								ea.wBookingRid = tmp.wBookingRid,													
                                ea.wUpdBy = tmp.wUpdBy ,
                                ea.wUpdDt = dbo.fnUTC8Now()				
							FROM    
								dbo.eAllotmentTicket AS ea
                                INNER JOIN #sDataSet_SetAllotmentTicket tmp ON ea.RowID = tmp.RowID
								WHERE tmp.wTicketStatus = 'I'

							--Update status for eAllotmentTicket as Terminate
							UPDATE  eat
							SET     
								eat.wAllotmentStatus = s.wTicketStatus,
								eat.wBookingRid = NULL,								
                                eat.wUpdBy = s.wUpdBy ,
                                eat.wUpdDt = dbo.fnUTC8Now()								
							FROM    
								dbo.eAllotmentTicket AS eat
                                INNER JOIN #sDataSet_SetAllotmentTicket s ON eat.RowID = s.RowID
								WHERE s.wTicketStatus = 'T'	
								
								--Update status for eAllotmentTicket as Available
							UPDATE  eatt
							SET     
								eatt.wAllotmentStatus = 'N',
								eatt.wBookingRid = NULL,													
                                eatt.wUpdBy = tmp.wUpdBy ,
                                eatt.wUpdDt = dbo.fnUTC8Now()				
							FROM    
								dbo.eAllotmentTicket AS eatt
                                INNER JOIN #sDataSet_SetAllotmentTicket tmp ON eatt.RowID = tmp.RowID
								WHERE tmp.wTicketStatus = 'N'	
                    END;    
					 	
				else if @pActionType ='D'
					BEGIN 
					UPDATE  eatt
							SET     
								eatt.wAllotmentStatus = 'N',
								eatt.wBookingRid = NULL,													
                                eatt.wUpdBy = tmp.wUpdBy ,
                                eatt.wUpdDt = dbo.fnUTC8Now()				
							FROM    
								dbo.eAllotmentTicket AS eatt
                                INNER JOIN #sDataSet_SetAllotmentTicket tmp ON eatt.RowID = tmp.RowID
								WHERE tmp.wTicketStatus = 'N'	
                 END;
								
           IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

		   -- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetAllotmentTicket;	

		RETURN;
        END TRY
        BEGIN CATCH
            DECLARE @vErrorNum INT ,
                @vCatchErrorMessage NVARCHAR(4000) ,
                @xstate INT ,
                @vProcedureName VARCHAR(100) ,
                @vRtnCodeLog INT ,
                @vErrMessageLog NVARCHAR(4000);
	        
			SET  @vErrorNum = ERROR_NUMBER();
			SET  @vCatchErrorMessage = ERROR_MESSAGE();
			SET  @xstate = XACT_STATE();
			SET  @vProcedureName = OBJECT_NAME(@@PROCID);
			
            IF ISNULL(@pErrCode, 0) = 0
                BEGIN
                    SET @pErrCode = 999;
                END;
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @vErrorNum, ') ',
                                  @vCatchErrorMessage);
			
			IF @sBeginTranCount = 0 BEGIN
				IF @xstate != 0
					ROLLBACK;
	            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT, @vErrMessageLog OUTPUT;
			END
			ELSE
				THROW;

        END CATCH;
	
        EXEC sp_xml_removedocument @sDocHandle;

		IF OBJECT_ID('tempdb..#sDataSet_SetAllotmentTicket') IS NOT NULL DROP TABLE #sDataSet_SetAllotmentTicket
    END;