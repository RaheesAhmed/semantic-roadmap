CREATE PROCEDURE [spa].[SetPointsTradingHistory]
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
        DECLARE @sThisTableName VARCHAR(50) = 'ePointsTradingHistory' , -- For RowID 
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
			
	        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
	        
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';

	    -- dbml
		--declare @sRtnList table (
		--	RowID bigint not null
		--)
		--Select * from @sRtnList
		--return

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetPointsTradingHistory
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('ePointsTradingHistory', '', 'Y', '', '', '')
			RowID BIGINT, 
            wPointsTradingRid BIGINT, 
            wAgentCodeIn VARCHAR(14), 
            wPointsType VARCHAR(30), 
            wTradingType VARCHAR(30), 
            wDiscountRatio NUMERIC(18,4), 
            wPoint NUMERIC(18,4), 
            wTradingDate DATE, 
            wCurrCode VARCHAR(3), 
            wMoneyAmt NUMERIC(18,4), 
            wProfit NUMERIC(18,4), 
            wPaymentStatus VARCHAR(30), 
            wRemark NVARCHAR(200), 
            wStatus CHAR(1), 
            wCrtDt DATETIME2, 
            wCrtBy BIGINT, 
            wUpdDt DATETIME2, 
            wUpdBy BIGINT,
            wPaymentTime DATETIME2(7),
            wDelReason NVARCHAR(500)
		);		 
	    
        BEGIN TRY		               
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF @pActionType = 'I'
                BEGIN
		  -- Set RowID by Sequence
                    UPDATE  #sDataSet_SetPointsTradingHistory
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetPointsTradingHistory;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetPointsTradingHistory
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
									
					-- PRINT [dbo].[fnGetAllFieldNameInTable]('ePointsTradingHistory', '', 'N', '', '', '')
                    INSERT  INTO dbo.[ePointsTradingHistory]
                            ( RowID ,
                              wPointsTradingRid ,
                              wAgentCodeIn ,
							  wPointsType,
                              wTradingType ,
                              wDiscountRatio ,
                              wPoint ,
                              wTradingDate ,
                              wCurrCode ,
                              wMoneyAmt ,
                              wProfit ,
                              wPaymentStatus ,
                              wRemark ,
                              wStatus ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy,
                              wPaymentTime,
                              wDelReason
                            )
                            SELECT
									-- PRINT [dbo].[fnGetAllFieldNameInTable]('ePointsTradingHistory', '', 'N', '', 'Y', 's')
                                    RowID = s.RowID ,
                                    wPointsTradingRid = s.wPointsTradingRid ,
                                    wAgentCodeIn = s.wAgentCodeIn ,
									wPointsType = s.wPointsType,
                                    wTradingType = s.wTradingType ,
                                    wDiscountRatio = s.wDiscountRatio ,
                                    wPoint = s.wPoint ,
                                    wTradingDate = s.wTradingDate ,
                                    wCurrCode = s.wCurrCode ,
                                    wMoneyAmt = s.wMoneyAmt ,
                                    wProfit = s.wProfit ,
                                    wPaymentStatus = s.wPaymentStatus ,
                                    wRemark = s.wRemark ,
                                    wStatus = s.wStatus ,
                                    wCrtDt = dbo.fnUTC8Now() ,
                                    wCrtBy = s.wCrtBy ,
                                    wUpdDt = dbo.fnUTC8Now() ,
                                    wUpdBy = s.wUpdBy,
                                    wPaymentTime=s.wPaymentTime,
                                    wDelReason=s.wDelReason
                            FROM    #sDataSet_SetPointsTradingHistory s;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  d
                        SET     -- PRINT [dbo].[fnGetAllFieldNameInTable]('ePointsTradingHistory', '', 'N', '', 'Y', 'tmp')                              
                                wPointsTradingRid = tmp.wPointsTradingRid ,
                                wAgentCodeIn = tmp.wAgentCodeIn ,
								wPointsType = tmp.wPointsType,
                                wTradingType = tmp.wTradingType ,
                                wDiscountRatio = tmp.wDiscountRatio ,
                                wPoint = tmp.wPoint ,
                                wTradingDate = tmp.wTradingDate ,
                                wCurrCode = tmp.wCurrCode ,
                                wMoneyAmt = tmp.wMoneyAmt ,
                                wProfit = tmp.wProfit ,
                                wPaymentStatus = tmp.wPaymentStatus ,
                                wRemark = tmp.wRemark ,
                                wStatus = tmp.wStatus ,
                                wCrtDt = tmp.wCrtDt ,
                                wCrtBy = tmp.wCrtBy ,
                                wUpdDt = dbo.fnUTC8Now() ,
                                wUpdBy = tmp.wUpdBy,
                                wPaymentTime=tmp.wPaymentTime,
                                wDelReason=tmp.wDelReason
                        FROM    dbo.ePointsTradingHistory AS d
                                INNER JOIN #sDataSet_SetPointsTradingHistory tmp ON d.RowID = tmp.RowID
                        WHERE   d.RowID = tmp.RowID;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN						
                            UPDATE  d
                            SET wStatus = 'T',
                                wDelReason=t.wDelReason, 
                                wUpdBy= t.wUpdBy, 
                                wUpdDt = dbo.fnUTC8Now()
                            FROM    dbo.ePointsTradingHistory d
                                    INNER JOIN #sDataSet_SetPointsTradingHistory t ON d.RowID = t.RowID;
                        END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetPointsTradingHistory;

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
                    SET @pErrCode = 999;
                END;
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ',
                                  @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0
                BEGIN
                    IF @xstate != 0
                        ROLLBACK;
                    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo,
                        @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT,
                        @sErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;

        END CATCH;
	
        EXEC sp_xml_removedocument @sDocHandle;
        IF OBJECT_ID('tempdb..#sDataSet_SetPointsTradingHistory') IS NOT NULL
            DROP TABLE #sDataSet_SetPointsTradingHistory;
    END;