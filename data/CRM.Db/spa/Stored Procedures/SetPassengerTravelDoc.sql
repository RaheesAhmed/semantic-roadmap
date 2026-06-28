

CREATE PROCEDURE [spa].[SetPassengerTravelDoc] 
(  
		@pXML XML ,  
		@pActionType CHAR(1) , -- I/U/D  
		@pMainCompNo INT,
		@pNonceToken VARCHAR(64),
		@pReturnResultSet CHAR(1) = 'N',
		@pBookingRid BIGINT,		
		@pErrCode INT = 0 OUTPUT, 
		@pErrMsg NVARCHAR(200) = '' OUTPUT ,     	
		@pBookingType VARCHAR(30)=''
 )  
AS  
    BEGIN  
     SET NOCOUNT ON;     
		
		
	 ----SELECT 0 AS wSeqNo,* FROM dbo.ePassengerTravelDocDetail   
          
     DECLARE @sThisTableName VARCHAR(50) = 'ePassengerTravelDocDetail' ,-- For RowID  
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
        INTO    #sDataSet_SetPassengerTravelDocDetail  
        FROM    OPENXML (@sDocHandle, 'DataSet/SetPassengerTravelDocResult', 1)  
		  WITH (  
					 RowID BIGINT
					,wPassengerDetailsRid BIGINT
					,wPersonTravelDocRid BIGINT
					,wUpdDt	DATETIME2(7)
					,wUpdBy NCHAR(10)
					,wSeqNo int
		       );  
	   
       BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
		
	

        IF @pActionType = 'I'  
            BEGIN  
				-- Set RowID by Sequence  
                UPDATE  #sDataSet_SetPassengerTravelDocDetail  
                SET     RowID = 0;  
                SELECT  @sRecCount = COUNT(*)  
                FROM    #sDataSet_SetPassengerTravelDocDetail;  
                WHILE @sRuningIndex <= @sRecCount  
                    BEGIN  
                        EXEC spq.GetRowID @pMainCompNo, @sThisTableName,  
                            @sRowID OUTPUT;  
       
                        UPDATE  #sDataSet_SetPassengerTravelDocDetail  
                        SET     RowID = @sRowID  
                        WHERE   wRowNum = @sRuningIndex;  
                        SET @sRuningIndex = @sRuningIndex + 1;  
                END;       
				                
		UPDATE tmp
		SET tmp.wPassengerDetailsRid=pass.RowID
		FROM #sDataSet_SetPassengerTravelDocDetail tmp
		INNER JOIN (SELECT RowID,wSeqNo FROM dbo.ePassengerDetails WHERE wBookingRid=@pBookingRid AND wStatus='A') pass ON pass.wSeqNo =tmp.wSeqNo;
			

		IF @pBookingType<>'PASSENGER'
		BEGIN
			DELETE FROM [ePassengerTravelDocDetail] WHERE wPassengerDetailsRid IN (SELECT RowID
			FROM dbo.ePassengerDetails WHERE wBookingRid=@pBookingRid AND wStatus='A');
		END
	
		-- MAIN Logic here, example here is inserting dataset to eIOUPenalty  
        INSERT INTO [dbo].[ePassengerTravelDocDetail]
		(
			 RowID
			,wPassengerDetailsRid
			,wPersonTravelDocRid
			,wUpdDt
			,wUpdBy
		)
		SELECT
		 s.RowID
		,s.wPassengerDetailsRid
		,s.wPersonTravelDocRid
		,s.wUpdDt
		,s.wUpdBy
		FROM  #sDataSet_SetPassengerTravelDocDetail s;  

        END;  
  
        IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;    
				
		 -- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetPassengerTravelDocDetail;	      
      
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

		IF OBJECT_ID('tempdb..#sDataSet_SetPassengerTravelDocDetail') IS NOT NULL DROP TABLE #sDataSet_SetPassengerTravelDocDetail;
END;