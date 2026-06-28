CREATE PROCEDURE [spa].[SetTravelAgencyInvoice]    
    (    
      @pXML XML ,    
      @pActionType CHAR(1) , -- I/U/D    
      @pMainCompNo INT,
	  @pNonceToken VARCHAR(64),
	  @pReturnResultSet CHAR(1) = 'N',
	  @pTravelAgencyInvoiceRid BIGINT OUTPUT, 
      @pErrCode INT = 0 OUTPUT ,    
      @pErrMsg NVARCHAR(200) = '' OUTPUT    
 )    
AS    
    BEGIN    
      
        -- SELECT * From dbo.eTravelAgencyInvoice;
      
        SET NOCOUNT ON;    
        DECLARE @sThisTableName VARCHAR(50) = 'eTravelAgencyInvoice' , -- For RowID    
		    @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,    
            @sRuningIndex INT = 1 ,    
            @sRowID BIGINT = 0 ,    
            @sDocHandle INT    
          
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );    
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';      
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;   
         
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,    
                *    
        INTO    #sDataSet_SetTravelAgencyInvoice    
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)    
		WITH (    
			RowID BIGINT,
			wHotelBookingRid BIGINT,
			wInvoiceNo VARCHAR(50),
			wTravelAgencyRid BIGINT,
			wStatus CHAR(1),
			wCrtBy BIGINT,
			wCrtDt DATETIME2(7),
			wUpdDt DATETIME2(7),
			wUpdBy BIGINT,
			wHotelRid BIGINT,
			wStartDate DATETIME2(7),
			wEndDate DATETIME2(7),
			wDayOfStay INT,
			wNumberOfRoom INT,
			wRemark NVARCHAR(500),
			wBedType VARCHAR(30),
			wPersonName NVARCHAR(200),
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
							UPDATE  #sDataSet_SetTravelAgencyInvoice    
							SET     RowID = 0 ;    
							SELECT  @sRecCount = COUNT(*)    
							FROM    #sDataSet_SetTravelAgencyInvoice;    
							WHILE @sRuningIndex <= @sRecCount    
								BEGIN    
									EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;          
									SET @pTravelAgencyInvoiceRid=@sRowID;
									DECLARE @sInvoiceCount INT=(SELECT COUNT(1) FROM dbo.eTravelAgencyInvoice
									WHERE wHotelBookingRid=(SELECT TOP 1 wHotelBookingRid FROM #sDataSet_SetTravelAgencyInvoice WHERE wRowNum = @sRuningIndex));

									SET @sInvoiceCount=ISNULL(@sInvoiceCount,0)+1;

									UPDATE TMP
									SET RowID = @sRowID
										,wInvoiceNo = (TMP.wInvoiceNo +'.' +REPLICATE('0',3-LEN(RTRIM(@sInvoiceCount))) + RTRIM(@sInvoiceCount))
									FROM #sDataSet_SetTravelAgencyInvoice TMP
									WHERE wRowNum = @sRuningIndex;    
									
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
						wRemark, 
						wBedType, 
						wPersonName,
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
						s.wRemark, 
						s.wBedType, 
						s.wPersonName,
					    s.wAgentCode 
					 FROM #sDataSet_SetTravelAgencyInvoice s;    
			END;     
            
		   IF @pActionType = 'U'
		   BEGIN

				UPDATE INV
				   SET 
					   [wTravelAgencyRid] = TMP.wTravelAgencyRid
					  ,[wStatus] = TMP.wStatus
					  ,[wUpdDt] = dbo.fnUTC8Now()
					  ,[wUpdBy] = TMP.wUpdBy
					  ,[wHotelRid] = TMP.wHotelRid
					  ,[wStartDate] = TMP.wStartDate
					  ,[wEndDate] = TMP.wEndDate
					  ,[wDayOfStay] = TMP.wDayOfStay
					  ,[wNumberOfRoom] = TMP.wNumberOfRoom
					  ,[wRemark] = TMP.wRemark
					  ,[wBedType] = TMP.wBedType
					  ,[wPersonName] = TMP.wPersonName
					  ,[wAgentCode] = TMP.wAgentCode
				FROM [dbo].[eTravelAgencyInvoice] INV
				INNER JOIN #sDataSet_SetTravelAgencyInvoice TMP ON TMP.RowID=INV.RowID;

				SET @pTravelAgencyInvoiceRid=(SELECT TOP 1 RowID FROM #sDataSet_SetTravelAgencyInvoice);
		   END

		   IF @pActionType = 'D'
		   BEGIN
				UPDATE INV
					   SET 
						   [wStatus] = 'T'
						  ,[wUpdDt] = dbo.fnUTC8Now()
						  ,[wUpdBy] = TMP.wUpdBy
					FROM [dbo].[eTravelAgencyInvoice] INV
					INNER JOIN #sDataSet_SetTravelAgencyInvoice TMP ON TMP.RowID=INV.RowID;

				SET @pTravelAgencyInvoiceRid=(SELECT TOP 1 RowID FROM #sDataSet_SetTravelAgencyInvoice);
		   END

		   IF @sBeginTranCount = 0 AND @@trancount > 0
		   BEGIN
               COMMIT;
           END;

		   -- Return RowID affected
           IF @pReturnResultSet = 'Y' SELECT RowID FROM #sDataSet_SetTravelAgencyInvoice;
  
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
		
		IF OBJECT_ID('tempdb..#sDataSet_SetTravelAgencyInvoice') IS NOT NULL
			DROP TABLE #sDataSet_SetTravelAgencyInvoice 
END;