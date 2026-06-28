CREATE PROCEDURE [spa].[SetGenerateInvoice]
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
      
     --SELECT  
     -- RowID, wHotelBookingRid, wInvoiceNo, wTravelAgencyRid, wStatus, wCrtBy, wCrtDt, wUpdDt, wUpdBy, wHotelRid, wStartDate, wEndDate, wDayOfStay, wNumberOfRoom, wRemarks, wBedType, wPersonRid,
     -- wAgentCode
     --FROM eTRAVELAGENCYINVOICE (NOLOCK)  
      
        SET NOCOUNT ON;

        DECLARE @sThisTableName VARCHAR(50) = 'eTravelAgencyInvoice' , -- For RowID    
		    @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,    
            @sRuningIndex INT = 1 ,    
            @sRowID BIGINT = 0 ,    
            @sDocHandle INT    
          
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );    
        SELECT  @pErrCode = 0, @pErrMsg = '';          
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;   
         
        SELECT wRowNum = ROW_NUMBER() OVER (ORDER BY RowID),*    
        INTO #sDataSet_SetTravelAgencyInvoice    
        FROM OPENXML (@sDocHandle, 'DataSet/Record', 1)    
		WITH (    
			RowID BIGINT,
			wHotelBookingRid BIGINT,
			wInvoiceNo BIGINT,
			wTravelAgencyRid BIGINT,
			wStatus VARCHAR(2),
			wCrtBy BIGINT,
			wCrtDt DATE,
			wUpdDt DATE,
			wUpdBy BIGINT,
			wHotelRid BIGINT,
			wStartDate DATE,
			wEndDate DATE,
			wDayOfStay INT,
			wNumberOfRoom INT,
			wRemarks NVARCHAR(500),
			wBedType VARCHAR(30),
			wPersonRid BIGINT,
		    wAgentCode VARCHAR(100)
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
                    UPDATE  #sDataSet_SetGenerateInvoice   
                    SET     RowID = 0 ;    
                    SELECT  @sRecCount = COUNT(*)    
                    FROM    #sDataSet_SetTravelAgencyInvoice;    
                    WHILE @sRuningIndex <= @sRecCount    
                        BEGIN    
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,    
                                @sRowID OUTPUT;          
           
                            UPDATE  #sDataSet_SetGenerateInvoice    
                            SET     RowID = @sRowID   
                            WHERE   wRowNum = @sRuningIndex;    
                            SET @sRuningIndex = @sRuningIndex + 1;    
                        END;                  
            
    -- MAIN Logic here, example here is inserting dataset to eIOUPenalty    
              INSERT  INTO dbo.[eTravelAgencyInvoice]    
             (     
				RowID, 
				wHotelBookingRid, 
				wInvoiceNo, 
				wTravelAgencyRid, 
				wStatus, 
				wCrtBy, 
				wCrtDt, 
				wUpdDt, 
				wUpdBy, 				
				wHotelRid, 
				wStartDate, 
				wEndDate, 
				wDayOfStay, 
				wNumberOfRoom, 
				wBedType, 
		      wAgentCode
			)    
			 SELECT    
			    s.RowID, 
				s.wHotelBookingRid, 
				s.wInvoiceNo, 
				s.wTravelAgencyRid, 
				s.wStatus, 
				s.wCrtBy, 
				dbo.fnUTC8Now(), 
				dbo.fnUTC8Now(), 
				s.wUpdBy, 				
				s.wHotelRid, 
				s.wStartDate, 
				s.wEndDate, 
				s.wDayOfStay, 
				s.wNumberOfRoom,
				s.wBedType, 
		      s.wAgentCode 
			 FROM    #sDataSet_SetGenerateInvoice s;    
    END;    
	
	   IF @sBeginTranCount = 0
                AND @@trancount > 0
   BEGIN
                    COMMIT;
                END;   
		-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT RowID
                FROM #sDataSet_SetGenerateInvoice;	
				    
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

		IF OBJECT_ID('tempdb..#sDataSet_SetTravelAgencyInvoice') IS NOT NULL DROP TABLE #sDataSet_SetTravelAgencyInvoice;
END;