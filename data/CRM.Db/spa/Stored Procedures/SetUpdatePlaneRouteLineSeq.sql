CREATE PROCEDURE [spa].[SetUpdatePlaneRouteLineSeq]
    (
      @pXML XML ,      
	  @pMainCompNo INT ,
	  @pTestMode INT = 0, -- 0: Normal(Non-Test), 1: UnitTest, 2: Scenario Test
	  @pNonceToken VARCHAR(64) ,
	  @pReturnResultSet CHAR(1) = 'N',
	  @pBookingPrivatePlaneRid BIGINT,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) OUTPUT
    )
AS
BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

		DECLARE @sUpdDt DATETIME2(7), @sUpdBy BIGINT

		-- SELECT *,'Y' AS RecordState FROM dbo.ePrivatePlaneRouteDtl; 

        DECLARE @sThisTableName VARCHAR(50) = 'ePrivatePlaneRouteDtl' ,
            @sBeginTranCount	INT = 0 ,
            @sDocHandle			INT,
            @sRecCount			INT = 0,
	        @sRuningIndex		INT = 1,
			@sRowID				BIGINT = 0,
			@sNow				DATETIME2 = dbo.fnUTC8Now();
        
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt DESC) ,
                *
        INTO    #sDataSet_SetPrivatePlaneRouteDtl FROM  OPENXML (@sDocHandle, 'DataSet/SetPrivatePlaneRouteDtlResult', 1)
		WITH (
			RowID BIGINT, 
			wBookingPrivatePlaneRid BIGINT, 
			wLine INT, 
			wCityCd VARCHAR(10), 
			wIsReturn CHAR(1), 
			wDepartureAirportRid BIGINT, 
			wArrivalAirportRid BIGINT,
			wTakeOffDt DATETIME2, 
			wArrivalDt DATETIME2, 
			wStatus CHAR(1), 
			wCrtDt DATETIME2, 
			wCrtBy BIGINT, 
			wUpdDt DATETIME2, 
			wUpdBy BIGINT, 
			RecordState VARCHAR(1)
			);        

		

        BEGIN TRY	                
			IF @sBeginTranCount = 0
				BEGIN
					BEGIN TRAN;
				END;
            
			IF EXISTS ( SELECT 1 FROM #sDataSet_SetPrivatePlaneRouteDtl)
			BEGIN
				
				select Top 1 
					@sUpdDt=wUpdDt, 
					@sUpdBy=wUpdBy
				from 
					#sDataSet_SetPrivatePlaneRouteDtl
				order by 
					wUpdDt desc

				-- update Private Plane's Line 
				;With ctePrivatePlaneRoute as (
					select 
						rd.RowID, 
						rd.wLine, 
						wLine_New = ROW_NUMBER() OVER ( ORDER BY wIsReturn, wTakeOffDt )
					from 
						dbo.ePrivatePlaneRouteDtl rd			
					where 
						rd.wBookingPrivatePlaneRid=@pBookingPrivatePlaneRid and rd.wStatus='A'

				)update rd set
						rd.wLine = p.wLine_New,
						rd.wUpdBy = @sUpdBy,
	 					rd.wUpdDt = @sUpdDt
				 from 
					dbo.ePrivatePlaneRouteDtl rd
				 inner join 
					ctePrivatePlaneRoute p on p.RowID = rd.RowID
				 where 
					rd.wLine <> p.wLine_New
                   
			END;

			IF @sBeginTranCount = 0 AND @@trancount > 0
			BEGIN
				IF @pTestMode = 1
					ROLLBACK;
				ELSE
					COMMIT;
			END;

			-- Return RowID List
			--IF @pReturnResultSet = 'Y'
			--BEGIN
			--	SELECT RowID FROM #sDataSet_SetPrivatePlaneRouteDtl;
			--END;
        END TRY
        BEGIN CATCH
            DECLARE @sErrorNum INT ,
                @sCatchErrorMessage NVARCHAR(4000) ,
                @xstate INT ,
                @sProcedureName VARCHAR(100) ,
                @sRtnCodeLog INT ,
                @sErrMessageLog NVARCHAR(4000);
        
            SET @sErrorNum = ERROR_NUMBER();
            SET @sCatchErrorMessage = ERROR_MESSAGE();
            SET @xstate = XACT_STATE();
            SET @sProcedureName = OBJECT_NAME(@@PROCID);
		
            IF ISNULL(@pErrCode, 0) = 0
                BEGIN
                    SET @pErrCode = 70001;
                END;

            SET @pErrMsg = CONCAT('(', @sErrorNum, ') ', @sCatchErrorMessage);

            IF @sBeginTranCount = 0
                BEGIN
                    IF @xstate != 0
                        ROLLBACK;

                    -- Write Log
					EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName,
						@pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;             			
                              
        END CATCH;

        EXEC sp_xml_removedocument @sDocHandle;
        IF OBJECT_ID('tempdb..#sDataSet_SetPrivatePlaneRouteDtl') IS NOT NULL DROP TABLE #sDataSet_SetPrivatePlaneRouteDtl;
END;