CREATE PROCEDURE [spa].[SetPointsTrading]
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
	/* Test
	DECLARE @vErrCode INT, @vErrMsg NVARCHAR(200)
	EXEC spa.SetPointsTrading 
		N'<DataSet><Record RowID="-1" wRequestDt="2017-03-15T00:00:00" wTargetExpiryDate="2017-03-16T00:00:00"
		wTargetAmt="2000.00" wTargetDiscountRatio ="0.85" wAmtDone="0" wAgentCodeIn="1000010180" wPointsType="SHARE" 
		wTradingType="BUY" wTradingStatus="INPROGRESS" wStatus="A"
		wCrtDt="2017-02-20T00:00:00" wCrtBy="1" wUpdDt="2017-02-20T00:00:00" wUpdBy="1"/></DataSet>',
		'I', 99, '', @vErrCode, @vErrMsg
	SELECT @vErrCode, @vErrMsg
	SELECT top 100 * FROM ePointsTrading order by wUpdDt
	*/
    BEGIN
        SET NOCOUNT ON;
        DECLARE @sThisTableName VARCHAR(50) = 'ePointsTrading' , -- For RowID 
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
	    
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
        INTO    #sDataSet_SetPointsTrading
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('ePointsTrading', '', 'Y', '', '', '')			
			RowID BIGINT, 
            wRequestDt DATETIME2, 
            wTargetExpiryDate DATE, 
            wTargetAmt NUMERIC(18,4), 
            wTargetDiscountRatio NUMERIC(18,4), 
            wAmtDone NUMERIC(18,4), 
            wAgentCodeIn VARCHAR(14), 
            wPointsType VARCHAR(30), 
            wTradingType VARCHAR(30), 
            wTradingStatus VARCHAR(30), 
            wStatus CHAR(1), 
            wCrtDt DATETIME2, 
            wCrtBy BIGINT, 
            wUpdDt DATETIME2, 
            wUpdBy BIGINT,
            wOutstandAmt NUMERIC(18, 4),
            wFollowStaffRid BIGINT
		);
	    
        BEGIN TRY		    
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetPointsTrading
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetPointsTrading;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetPointsTrading
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
								
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('ePointsTrading', '', 'N', '', '', '')
                    INSERT  INTO dbo.ePointsTrading
                            ( RowID ,
                              wRequestDt ,
                              wTargetExpiryDate ,
                              wTargetAmt ,
                              wTargetDiscountRatio ,
                              wAmtDone ,
                              wAgentCodeIn ,
                              wPointsType ,
                              wTradingType ,
                              wTradingStatus ,
                              wStatus ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy,
                              wOutstandAmt,
                              wFollowStaffRid
							)
                            SELECT
								-- PRINT [dbo].[fnGetAllFieldNameInTable]('ePointsTrading', '', 'N', '', 'Y', 's')
                                    RowID = s.RowID ,
                                    wRequestDt = s.wRequestDt ,
                                    wTargetExpiryDate = s.wTargetExpiryDate ,
                                    wTargetAmt = s.wTargetAmt ,
                                    wTargetDiscountRatio = s.wTargetDiscountRatio ,
                                    wAmtDone = s.wAmtDone ,
                                    wAgentCodeIn = s.wAgentCodeIn ,
                                    wPointsType = s.wPointsType ,
                                    wTradingType = s.wTradingType ,
                                    wTradingStatus = s.wTradingStatus ,
                                    wStatus = s.wStatus ,
                                    --wCrtDt = s.wCrtDt ,
                                    dbo.fnUTC8Now(),
                                    wCrtBy = s.wCrtBy ,
                                    --wUpdDt = s.wUpdDt ,
                                    dbo.fnUTC8Now(),
                                    wUpdBy = s.wUpdBy,
                                    wOutstandAmt=s.wOutstandAmt,
                                    wFollowStaffRid=s.wFollowStaffRid
                            FROM    #sDataSet_SetPointsTrading s;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  d
                        SET     -- PRINT [dbo].[fnGetAllFieldNameInTable]('ePointsTrading', '', 'N', '', 'Y', 'tmp')                                                                
                                wRequestDt = tmp.wRequestDt ,
                                wTargetExpiryDate = tmp.wTargetExpiryDate ,
                                wTargetAmt = tmp.wTargetAmt ,
                                wTargetDiscountRatio = tmp.wTargetDiscountRatio ,
                                wAmtDone = tmp.wAmtDone ,
                                wAgentCodeIn = tmp.wAgentCodeIn ,
                                wPointsType = tmp.wPointsType ,
                                wTradingType = tmp.wTradingType ,
                                wTradingStatus = tmp.wTradingStatus ,
                                wStatus = tmp.wStatus ,
                                --wCrtDt = tmp.wCrtDt ,
                                wCrtBy = tmp.wCrtBy ,
                                --wUpdDt = tmp.wUpdDt ,
                                wUpdDt =dbo.fnUTC8Now(),
                                wUpdBy = tmp.wUpdBy,
                                wOutstandAmt=tmp.wOutstandAmt,
                                wFollowStaffRid=tmp.wFollowStaffRid
                        FROM    dbo.ePointsTrading AS d
                                INNER JOIN #sDataSet_SetPointsTrading tmp ON d.RowID = tmp.RowID
                        WHERE   d.RowID = tmp.RowID;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN						
                            UPDATE  d
                            SET     wStatus = 'T',wUpdDt =dbo.fnUTC8Now()
                            FROM    dbo.ePointsTrading d
                                    INNER JOIN #sDataSet_SetPointsTrading t ON d.RowID = t.RowID;
                        END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetPointsTrading;

            RETURN;
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

        IF OBJECT_ID('tempdb..#sDataSet_SetPointsTrading') IS NOT NULL
            DROP TABLE #sDataSet_SetPointsTrading;
    END;