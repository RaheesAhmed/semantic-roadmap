CREATE PROCEDURE [spa].[SetTaskSheet] 
    ( 
      @pXML XML , 
      @pActionType CHAR(1) , -- I/U/D 
      @pMainCompNo INT , 
      @pNonceToken VARCHAR(64) , 
	  @pReturnResultSet CHAR(1) = 'N', 
      @pErrCode INT = 0 OUTPUT , 
      @pErrMsg NVARCHAR(200) = '' OUTPUT 
	) 
AS 
    BEGIN 
        SET NOCOUNT ON; 
 
		-- SELECT *FROM [eTaskSheet] 
 
        DECLARE @sThisTableName VARCHAR(50) = 'eTaskSheet' , -- For RowID  
            @sBeginTranCount INT = 0 , 
            @sRecCount INT = 0 , 
            @sRuningIndex INT = 1 , 
            @sRowID BIGINT = 0 , 
            @sDocHandle INT; 
        -- dbml 
		--declare @vRtnList table ( 
		--	RowID bigint not null 
		--) 
		--Select * from @vRtnList 
		--return 
        DECLARE @sReturnRowID TABLE ( RowID BIGINT ); 
	         
        SET @sBeginTranCount = @@trancount; 
        SELECT  @pErrCode = 0 , 
                @pErrMsg = ''; 
	     
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML; 
	     
	    --   
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) , 
                * 
        INTO    #sDataSet_SetTaskSheet 
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1) 
		WITH ( 
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eTaskSheet', '', 'Y', '', '', '') 
			RowID BIGINT, wCompNo INT, wCounterRid BIGINT, wDeptCd VARCHAR(30), wUsrRid BIGINT, wDate DATE, wTaskType VARCHAR(30),  
			wSubTaskType VARCHAR(30), wIsInhouse CHAR(1), wContent NVARCHAR(4000), wRemark NVARCHAR(500),  
			wRelateAgentCodeIn VARCHAR(14), wRelatedType VARCHAR(30), wRelatedRid BIGINT, wHasDoc CHAR(1),  
			wStatus CHAR(1), wCrtDt DATETIME2, wCrtBy BIGINT, wUpdDt DATETIME2, wUpdBy BIGINT, 
			wFollowUpDt DATETIME2, wFollowUpBy BIGINT, wTaskSheetStatus VARCHAR(30)
		); 
 
		 --better don't put everything within try, for example 
	     --getting mSysTable value 
	     --getting currency, period, mCompany ... 
	 
	--- Task Sheet Required Field Validation Start
		DECLARE @errorMsg VARCHAR(MAX);
        IF @pActionType IN ( 'I', 'U' )
            BEGIN				 
                SELECT  @errorMsg = CASE WHEN eb.wCompNo <= 0 THEN 'CRM Place is Missing'
                                         WHEN RTRIM(ISNULL(eb.wDeptCd, '')) = '' THEN 'Department is Missing'
                                    END
                FROM    #sDataSet_SetTaskSheet eb
            END
        IF @errorMsg <> ''
            THROW 50001, @errorMsg, 1;		
		--- Task Sheet  Required Field Validation end

        IF @pActionType = 'U'
            BEGIN
                SELECT  @errorMsg = CASE WHEN temp.wCompNo <> ets.wCompNo THEN 'Can not edit CRM Place'
                                         WHEN temp.wDeptCd <> ets.wDeptCd THEN 'Can not change Department'
                                    END
                FROM    eTaskSheet ets
                        INNER JOIN #sDataSet_SetTaskSheet temp ON temp.RowID = ets.RowID
            END
        IF @errorMsg <> ''
            THROW 50001, @errorMsg, 1;

        BEGIN TRY 
		    -- Try to make the transaction scope as small as possible to reduce locking 
            IF @sBeginTranCount = 0 
                BEGIN 
                    BEGIN TRAN; 
                END; 
 
            UPDATE  #sDataSet_SetTaskSheet 
            SET     wFollowUpDt = wUpdDt , 
                    wFollowUpBy = wUpdBy 
            WHERE   ISNULL(wFollowUpBy, -1) = -1; 
 
            IF @pActionType = 'I' 
                BEGIN 
				-- Set RowID by Sequence 
                    UPDATE  #sDataSet_SetTaskSheet 
                    SET     RowID = 0; 
                    SELECT  @sRecCount = COUNT(*) 
                    FROM    #sDataSet_SetTaskSheet; 
                    WHILE @sRuningIndex <= @sRecCount 
                        BEGIN 
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, 
                                @sRowID OUTPUT; 
					 
                            UPDATE  #sDataSet_SetTaskSheet 
                            SET     RowID = @sRowID 
                            WHERE   wRowNum = @sRuningIndex; 
                            SET @sRuningIndex = @sRuningIndex + 1; 
                        END;   						                    
				 
				-- MAIN Logic here, example here is inserting dataset to eTaskSheet 
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eTaskSheet', '', 'N', '', '', '') 
                    INSERT  INTO dbo.[eTaskSheet] 
                            ( RowID , 
                              wCompNo ,
							  wCounterRid , 
                              wDeptCd , 
							  wUsrRid , 
                              wDate , 
                              wTaskType , 
                              wSubTaskType , 
                              wIsInhouse , 
                              wContent , 
                              wRemark , 
                              wRelateAgentCodeIn , 
                              wRelatedType , 
                              wRelatedRid , 
                              wHasDoc , 
                              wStatus , 
                              wCrtDt , 
                              wCrtBy , 
                              wUpdDt , 
							  wUpdBy , 
							  wFollowUpDt , 
                              wFollowUpBy ,
							  wTaskSheetStatus
							) 
                            SELECT 
								-- PRINT [dbo].[fnGetAllFieldNameInTable]('eTaskSheet', '', 'N', '', 'Y', 's') 
                                    RowID , 
                                    wCompNo , 
									wCounterRid ,
                                    wDeptCd , 
									wUsrRid, 
                                    wDate , 
                                    wTaskType , 
                                    wSubTaskType , 
                                    wIsInhouse , 
                                    wContent , 
                                    wRemark , 
                                    wRelateAgentCodeIn , 
                                    wRelatedType , 
                                    wRelatedRid , 
                                    wHasDoc , 
                                    wStatus , 
                                    dbo.fnUTC8Now() , 
                                    wCrtBy , 
                                    wUpdDt , 
                                    wUpdBy , 
                                    wFollowUpDt , 
                                    wFollowUpBy ,
									ISNULL(wTaskSheetStatus,'')
                            FROM    #sDataSet_SetTaskSheet s; 
                END; 
            ELSE 
                IF @pActionType = 'U' 
                    BEGIN 
                        UPDATE  d 
                        SET     -- PRINT [dbo].[fnGetAllFieldNameInTable]('eTaskSheet', '', 'N', '', 'Y', 'tmp')							  
                                wCompNo = tmp.wCompNo , 
								wCounterRid = ISNULL(tmp.wCounterRid, 0) , 
                                wDeptCd = tmp.wDeptCd , 
								wUsrRid = tmp.wUsrRid , 
                                wDate = tmp.wDate , 
                                wTaskType = tmp.wTaskType , 
                                wSubTaskType = tmp.wSubTaskType , 
                                wIsInhouse = tmp.wIsInhouse , 
                                wContent = tmp.wContent , 
                                wRemark = tmp.wRemark , 
                                wRelateAgentCodeIn = tmp.wRelateAgentCodeIn , 
                                wRelatedType = tmp.wRelatedType , 
                                wRelatedRid = tmp.wRelatedRid , 
                                wHasDoc = tmp.wHasDoc , 
                                wStatus = tmp.wStatus , 
                                wFollowUpDt = tmp.wFollowUpDt , 
                                wFollowUpBy = tmp.wFollowUpBy , 
                                wUpdDt = dbo.fnUTC8Now() , 
                                wUpdBy = tmp.wUpdBy ,
								wTaskSheetStatus = ISNULL(tmp.wTaskSheetStatus,'')
                        FROM    dbo.eTaskSheet AS d 
                                INNER JOIN #sDataSet_SetTaskSheet tmp ON d.RowID = tmp.RowID 
                        WHERE   d.RowID = tmp.RowID; 
                    END; 
                ELSE 
                    IF @pActionType = 'D' 
                        BEGIN						 
                            UPDATE  d 
                            SET     wStatus = 'T', 
							        wUpdDt = dbo.fnUTC8Now() 
                            FROM    dbo.eTaskSheet d 
                                    INNER JOIN #sDataSet_SetTaskSheet t ON d.RowID = t.RowID; 
                        END; 
 
            IF @sBeginTranCount = 0 
                AND @@trancount > 0 
                BEGIN 
                    COMMIT; 
                END; 
  
            WITH    cteUpdatedData 
                      AS ( SELECT DISTINCT 
                                    wRelatedType , 
                                    wRelatedRid 
                           FROM     #sDataSet_SetTaskSheet 
                         ), 
                    cteLatestTaskSheetTime 
                      AS ( SELECT   MAX(wFollowUpDt) AS wLastestFollowUpDt , 
                                    ts.wRelatedType , 
                                    ts.wRelatedRid 
                           FROM     dbo.eTaskSheet ts 
                                    INNER JOIN cteUpdatedData cteUD ON ts.wRelatedType = cteUD.wRelatedType 
                            AND ts.wRelatedRid = cteUD.wRelatedRid 
                           GROUP BY ts.wRelatedType , 
                                    ts.wRelatedRid 
                         ) 
                SELECT  ts.wRelatedType , 
                        ts.wRelatedRid , 
                        ts.wFollowUpDt , 
                        ts.wFollowUpBy , 
                        ts.wUpdBy , 
                        ts.wUpdDt 
                INTO    #sData_SetTaskSheetSummary 
                FROM    dbo.eTaskSheet ts 
                        INNER JOIN cteLatestTaskSheetTime cteLTST ON ts.wRelatedType = cteLTST.wRelatedType 
                                                              AND ts.wRelatedRid = cteLTST.wRelatedRid 
                                                              AND ts.wFollowUpDt = cteLTST.wLastestFollowUpDt; 
			 
            UPDATE  tss 
            SET     wLatestFollowUpBy = t.wFollowUpBy , 
                    wLatestFollowUpDt = t.wFollowUpDt , 
                    wLatestUpdBy = t.wUpdBy , 
                    wLatestUpdDt = t.wUpdDt 
            FROM    eTaskSheetSummary tss 
                    INNER JOIN #sData_SetTaskSheetSummary t ON tss.wRelatedType = t.wRelatedType 
                                                              AND tss.wRelatedRID = t.wRelatedRid;			  
 
            INSERT  INTO dbo.eTaskSheetSummary 
                    ( wRelatedType , 
                      wRelatedRID , 
                      wLatestFollowUpBy , 
                      wLatestFollowUpDt , 
                      wLatestUpdBy , 
                      wLatestUpdDt 
			        ) 
                    SELECT  t.wRelatedType , 
                            t.wRelatedRid , 
                            t.wFollowUpBy , 
                            t.wFollowUpDt , 
                            t.wUpdBy , 
                            t.wUpdDt 
                    FROM    #sData_SetTaskSheetSummary t 
                            LEFT JOIN eTaskSheetSummary tss ON tss.wRelatedType = t.wRelatedType 
                                                              AND tss.wRelatedRID = t.wRelatedRid 
                    WHERE   tss.wRelatedType IS NULL; 
 
			-- Return RowID affected 
			IF @pReturnResultSet = 'Y' 
				SELECT RowID FROM #sDataSet_SetTaskSheet; 
 
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
 
        IF OBJECT_ID('tempdb..#sDataSet_SetTaskSheet') IS NOT NULL 
            DROP TABLE #sDataSet_SetTaskSheet; 
		 
		IF OBJECT_ID('tempdb..#sData_SetTaskSheetSummary') IS NOT NULL 
            DROP TABLE #sData_SetTaskSheetSummary; 
		 
    END;