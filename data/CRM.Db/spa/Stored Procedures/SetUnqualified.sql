CREATE PROCEDURE [spa].[SetUnqualified]
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
        DECLARE @sThisTableName VARCHAR(50) = 'eUnqualified' , -- For RowID 
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
        INTO    #sDataSet_SetUnqualified
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eUnqualified', '', 'Y', '', '', '')
			RowID BIGINT, wAgentCodeIn VARCHAR(14), wDeptCd VARCHAR(30), wCompNo INT, wCounterRid BIGINT, wUnqualifiedType VARCHAR(30), wUnqualifiedStatus VARCHAR(30), wReason VARCHAR(30), wDetails NVARCHAR(500), wFollowUpDetails NVARCHAR(500), wStatus CHAR(1), wCrtDt DATETIME2, wCrtBy BIGINT, wUpdDt DATETIME2, wUpdBy BIGINT, wBookingRid BIGINT, wBookingType varchar(30)
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
                    UPDATE  #sDataSet_SetUnqualified
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetUnqualified;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetUnqualified
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eUnqualified
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eUnqualified', '', 'N', '', '', '')
                    INSERT  INTO dbo.eUnqualified
                            ( RowID ,
                              wAgentCodeIn ,
                              wDeptCd ,
                              wCompNo ,
							  wCounterRid ,
                              wUnqualifiedType ,
                              wUnqualifiedStatus ,
                              wReason ,
                              wDetails ,
                              wFollowUpDetails ,
                              wStatus ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy,
							  wBookingRid,
							  wBookingType
							)
                            SELECT
								-- PRINT [dbo].[fnGetAllFieldNameInTable]('eUnqualified', '', 'N', '', 'Y', 's')
                                    RowID = s.RowID ,
                                    wAgentCodeIn = s.wAgentCodeIn ,
                                    wDeptCd = s.wDeptCd ,
                                    wCompNo = s.wCompNo ,
									wCounterRid = s.wCounterRid ,
                                    wUnqualifiedType = s.wUnqualifiedType ,
                                    wUnqualifiedStatus = s.wUnqualifiedStatus ,
                                    wReason = s.wReason ,
                                    wDetails = s.wDetails ,
                                   wFollowUpDetails = s.wFollowUpDetails ,
                                    wStatus = s.wStatus ,
                                    wCrtDt = s.wCrtDt ,
                                    wCrtBy = s.wCrtBy ,
                                    wUpdDt = s.wUpdDt ,
                                    wUpdBy = s.wUpdBy,
									wBookingRid = s.wBookingRid,
									wBookingType = ISNULL(s.wBookingType,'')
                            FROM    #sDataSet_SetUnqualified s;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  d
                        SET     -- PRINT [dbo].[fnGetAllFieldNameInTable]('eUnqualified', '', 'N', '', 'Y', 'tmp')
                                wAgentCodeIn = tmp.wAgentCodeIn ,
                                wDeptCd = tmp.wDeptCd ,
                                wCompNo = tmp.wCompNo ,
								wCounterRid = tmp.wCounterRid,
                                wUnqualifiedType = tmp.wUnqualifiedType ,
                                wUnqualifiedStatus = tmp.wUnqualifiedStatus ,
                                wReason = tmp.wReason ,
                                wDetails = tmp.wDetails ,
                                wFollowUpDetails = tmp.wFollowUpDetails ,
                                wStatus = tmp.wStatus ,
                                wCrtDt = tmp.wCrtDt ,
                                wCrtBy = tmp.wCrtBy ,
                                wUpdDt = tmp.wUpdDt ,
                                wUpdBy = tmp.wUpdBy,
								wBookingRid = tmp.wBookingRid,
								wBookingType = tmp.wBookingType
                        FROM    dbo.eUnqualified AS d
                                INNER JOIN #sDataSet_SetUnqualified tmp ON d.RowID = tmp.RowID
                        WHERE   d.RowID = tmp.RowID;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN						
                            UPDATE  d
                            SET     wStatus = 'T'
                            FROM    dbo.eUnqualified d
                                    INNER JOIN #sDataSet_SetUnqualified t ON d.RowID = t.RowID;
                        END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetUnqualified;

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

        IF OBJECT_ID('tempdb..#sDataSet_SetUnqualified') IS NOT NULL
            DROP TABLE #sDataSet_SetUnqualified;
    END;