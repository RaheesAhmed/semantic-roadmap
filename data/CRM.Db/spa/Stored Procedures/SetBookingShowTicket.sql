/*
呢個 SP 名好有問題, 其實係做緊 BookingShowTicket 既實際明細門票
*/

CREATE PROCEDURE [spa].[SetBookingShowTicket]    
(  
	@pXML XML ,  
	@pActionType CHAR(1) , -- I/U/D  
	@pMainCompNo INT,  
	@pNonceToken VARCHAR(64), 
	@pReturnResultSet CHAR(1) = 'N',
	@pBookingShowRid BIGINT,
	@pErrCode INT = 0 OUTPUT ,
	@pErrMsg NVARCHAR(200) = '' OUTPUT  		
 )  
AS  
    BEGIN  
        SET NOCOUNT ON;     

	--DECLARE @v AS NVARCHAR(MAX)
	--SET @v = CAST(@pXML AS NVARCHAR(MAX));
	--EXEC crm.spa.WriteErrorLog 10, 10, 'TRACE_SHOW_TICKET', @v, 0, '';
	
     DECLARE @sThisTableName VARCHAR(50) = 'eBookingShowTicket' ,-- For RowID  
            @sBeginTranCount INT = 0 ,  
            @sRecCount INT = 0 ,  
            @sRuningIndex INT = 1 ,  
            @sRowID BIGINT = 0 ,
			@vNow DATETIME2 = dbo.fnUTC8Now(),
			@vMthEndYearMth VARCHAR(6),
			@vDateUsingCRM DATETIME2,
			@sActionAffectedXML NVARCHAR(MAX) = '',
            @sDocHandle INT;  
              
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );  
           
        SET @sBeginTranCount = @@trancount;  
         
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;  
       
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,  
                *  
        INTO    #sDataSet_SetBookingShowTicket  
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)  
		  WITH (  
					RowId bigint,
					wBookingShowRid bigint,
					wShowTicketPriceRid bigint,
					wQuantity INT,
					wAmount NUMERIC(18,4),
					wCost NUMERIC(18,4) 				
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
                UPDATE  #sDataSet_SetBookingShowTicket  
                SET     RowID = 0;  
                SELECT  @sRecCount = COUNT(*)  
                FROM    #sDataSet_SetBookingShowTicket;  
                WHILE @sRuningIndex <= @sRecCount  
                    BEGIN  
                        EXEC spq.GetRowID @pMainCompNo, @sThisTableName,  
                            @sRowID OUTPUT;  
       
                        UPDATE  #sDataSet_SetBookingShowTicket  
                        SET     RowID = @sRowID  
                        WHERE   wRowNum = @sRuningIndex;  
                        SET @sRuningIndex = @sRuningIndex + 1;  
                    END;                
          
      --SET @pBookingRid = @sRowID;  
  
				-- MAIN Logic here, example here is inserting dataset to eBookingShowTicket  

				-- Jay Lin: Missing Step, Should check is there any record here is changing show, is yes, should delete them
				-- or do it in setBookingShow or ActionBookingShow

                INSERT INTO [dbo].[eBookingShowTicket]
							   (
								RowID,	
								wBookingShowRid,	
								wShowTicketPriceRid,	
								wQuantity,
								wAmount,
								wCost)	
                            SELECT
								ers.RowID,	
								ers.wBookingShowRid,	
								ers.wShowTicketPriceRid,									
								ers.wQuantity,
								wAmount,
								wCost																
                    FROM    #sDataSet_SetBookingShowTicket ers;
            END;  
  
  ELSE IF @pActionType = 'U'  
  BEGIN  

				DELETE bst FROM eBookingShowTicket bst
				INNER JOIN #sDataSet_SetBookingShowTicket tmp ON tmp.wBookingShowRid = bst.wBookingShowRid

				UPDATE  #sDataSet_SetBookingShowTicket  
                SET     RowID = 0;  
                SELECT  @sRecCount = COUNT(*)  
                FROM    #sDataSet_SetBookingShowTicket;  
                WHILE @sRuningIndex <= @sRecCount  
                    BEGIN  
                        EXEC spq.GetRowID @pMainCompNo, @sThisTableName,  
                            @sRowID OUTPUT;  
       
                        UPDATE  #sDataSet_SetBookingShowTicket  
                        SET     RowID = @sRowID  
                        WHERE   wRowNum = @sRuningIndex;  
                        SET @sRuningIndex = @sRuningIndex + 1;  
                    END;  


					INSERT INTO [dbo].[eBookingShowTicket]
							   (
								RowID,	
								wBookingShowRid,	
								wShowTicketPriceRid,	
								wQuantity,
								wAmount,
								wCost)	
                            SELECT
								ers.RowID,	
								ers.wBookingShowRid,
								ers.wShowTicketPriceRid,									
								ers.wQuantity,
								wAmount,
								wCost																
                    FROM    #sDataSet_SetBookingShowTicket ers;  
				
  
  END; 

  			---------------------------------------------------------------------------------------------
			-- SetActionAffectedTableLog
			---------------------------------------------------------------------------------------------
			SET @sActionAffectedXML = (
				SELECT
					wActionSp = OBJECT_NAME(@@PROCID), wActionType = @pActionType, wNonceToken = @pNonceToken, 
					wRefTableName = @sThisTableName, wRefRid = tmp.RowID, wType = '', wCrtDt = @vNow
				FROM
					#sDataSet_SetBookingShowTicket tmp
				FOR XML RAW('Record'), ROOT('DataSet')
			);
			EXEC spa.SetActionAffectedTableLog @sActionAffectedXML, 'I', @pMainCompNo, '', 0, ''

        IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;
		-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetBookingShowTicket;
     
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
		
		IF OBJECT_ID('tempdb..#sDataSet_SetBookingShowTicket') IS NOT NULL DROP TABLE #sDataSet_SetBookingShowTicket
			       
    END;