CREATE PROCEDURE [spa].[SetPointsTradingRemarks]
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
        DECLARE @sThisTableName VARCHAR(50) = 'ePointsTradingRemarks' , -- For RowID 
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
        INTO    #sDataSet_SetPointsTradingRemarks
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('ePointsTradingRemarks', '', 'Y', '', '', '')
			RowID BIGINT, wPointsTradingRid BIGINT, wRemarks NVARCHAR(200), wStatus CHAR(1), wCrtBy BIGINT, wCrtDt DATETIME2, wUpdDt DATETIME2, wUpdBy BIGINT
		);		 
	    
        BEGIN TRY		               
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF @pActionType = 'I'
                BEGIN
		  -- Set RowID by Sequence
                    UPDATE  #sDataSet_SetPointsTradingRemarks
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetPointsTradingRemarks;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetPointsTradingRemarks
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
									
					-- PRINT [dbo].[fnGetAllFieldNameInTable]('ePointsTradingRemarks', '', 'N', '', '', '')
                    INSERT  INTO dbo.[ePointsTradingRemarks]
                            ( RowID ,
                              wPointsTradingRid ,
                              wRemarks ,
                              wStatus ,
                              wCrtBy ,
                              wCrtDt ,
                              wUpdDt ,
                              wUpdBy
                            )
                            SELECT
									-- PRINT [dbo].[fnGetAllFieldNameInTable]('ePointsTradingRemarks', '', 'N', '', 'Y', 's')
                                    RowID = s.RowID ,
                                    wPointsTradingRid = s.wPointsTradingRid ,
                                    wRemarks = s.wRemarks ,
                                    wStatus = s.wStatus ,
                                    wCrtBy = s.wCrtBy ,
                                    wCrtDt = dbo.fnUTC8Now() ,
                                    wUpdDt = s.wUpdDt ,
                                    --wUpdBy = dbo.fnUTC8Now()
									wUpdBy = s.wUpdBy
                            FROM    #sDataSet_SetPointsTradingRemarks s;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  d
                        SET     -- PRINT [dbo].[fnGetAllFieldNameInTable]('ePointsTradingRemarks', '', 'N', '', 'Y', 'tmp')                              
                                wPointsTradingRid = tmp.wPointsTradingRid ,
                                wRemarks = tmp.wRemarks ,
                                wStatus = tmp.wStatus ,
                                wCrtDt = tmp.wCrtDt ,
                                wCrtBy = tmp.wCrtBy ,
                                wUpdDt = dbo.fnUTC8Now() ,
                                wUpdBy = tmp.wUpdBy
                        FROM    dbo.ePointsTradingRemarks AS d
                                INNER JOIN #sDataSet_SetPointsTradingRemarks tmp ON d.RowID = tmp.RowID
                        WHERE   d.RowID = tmp.RowID;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN						
                            UPDATE  d
                            SET     wStatus = 'T'
                            FROM    dbo.ePointsTradingRemarks d
                                    INNER JOIN #sDataSet_SetPointsTradingRemarks t ON d.RowID = t.RowID;
                        END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetPointsTradingRemarks;

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
        IF OBJECT_ID('tempdb..#sDataSet_SetPointsTradingRemarks') IS NOT NULL
            DROP TABLE #sDataSet_SetPointsTradingRemarks;
    END;