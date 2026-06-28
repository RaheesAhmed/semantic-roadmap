CREATE PROCEDURE [spa].[SetComplaintFollow]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64),
	  @pReturnResultSet CHAR(1) = 'N',
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
	)
/* Test
DECLARE @vErrCode INT, @vErrMsg NVARCHAR(200)
EXEC spa.SetComplaintFollow 
	N'<DataSet><Record RowID="-1" wComplaintRid="99000000010001" wTranDt="2017-02-20T11:22:33" wFollowBy="1" wFollowDeptCd="IT"
		wContent="測試更進" wSolveDt="2017-02-21T11:22:33" wSolveContent="測試更進, 解決" wPreventContent="測試, 防止左"
		wStatus="A" wCrtDt="2017-02-20T00:00:00" wCrtBy="1" wUpdDt="2017-02-20T00:00:00" wUpdBy="1"/></DataSet>',
	'I', 99, '', @vErrCode, @vErrMsg
SELECT @vErrCode, @vErrMsg
SELECT top 100 * FROM eComplaint order by wUpdDt
*/
AS
    BEGIN
        SET NOCOUNT ON;
	    DECLARE 
			@vThisTableName VARCHAR(50) = 'eComplaintFollow' , -- For RowID 
            @vBeginTranCount INT = 0 ,
            @vRecCount INT = 0 ,
            @vRuningIndex INT = 1 ,
            @vRowID BIGINT = 0,
			@vRefNo BIGINT = 0,
            @vDocHandle INT;
	        
        SET @vBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 , @pErrMsg = '';
	    
        -- dbml
		--declare @vRtnList table (
		--	RowID bigint not null
		--)
		--Select * from @vRtnList
		--return

		EXEC sp_xml_preparedocument @vDocHandle OUTPUT, @pXML;
	    
	    --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetComplaintFollow
        FROM    OPENXML (@vDocHandle, 'DataSet/Record', 1)
		WITH (
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eComplaintFollow', '', 'Y', '', '', '')
			RowID BIGINT, wComplaintRid BIGINT, wTranDt DATETIME2, wFollowBy BIGINT, wFollowDeptCd VARCHAR(30), 
			wContent NVARCHAR(2000), wSolveDt DATETIME2, wSolveContent NVARCHAR(2000), wPreventContent NVARCHAR(2000), 
			wStatus CHAR(1), wCrtDt DATETIME2, wCrtBy BIGINT, wUpdDt DATETIME2, wUpdBy BIGINT
		);

		 --better don't put everything within try, for example
	     --getting mSysTable value
	     --getting currency, period, mCompany ...
	    
        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
            IF @vBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetComplaintFollow
                    SET     RowID = 0;
                    SELECT  @vRecCount = COUNT(*)
                    FROM    #sDataSet_SetComplaintFollow;
                    WHILE @vRuningIndex <= @vRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @vThisTableName, @vRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetComplaintFollow
                            SET     RowID = @vRowID
                            WHERE   wRowNum = @vRuningIndex;
                            SET @vRuningIndex = @vRuningIndex + 1;
                        END;
				
				-- MAIN Logic here, example here is inserting dataset to eComplaintFollow
				-- PRINT [dbo].[fnGetAllFieldNameInTable]('eComplaintFollow', '', 'N', '', '', '')
                    INSERT  INTO dbo.[eComplaintFollow]
                            (
								RowID, wComplaintRid, wTranDt, wFollowBy, wFollowDeptCd, wContent, wSolveDt, wSolveContent, wPreventContent, wStatus, wCrtDt, wCrtBy, wUpdDt, wUpdBy
							)
                            SELECT
								-- PRINT [dbo].[fnGetAllFieldNameInTable]('eComplaintFollow', '', 'N', '', 'Y', 's')
								RowID, wComplaintRid, dbo.fnUTC8Now(), wFollowBy, wFollowDeptCd, wContent, wSolveDt, wSolveContent, wPreventContent, wStatus, dbo.fnUTC8Now(), wCrtBy, dbo.fnUTC8Now(), wUpdBy
                            FROM    
								#sDataSet_SetComplaintFollow s;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  d
                        SET     -- PRINT [dbo].[fnGetAllFieldNameInTable]('eComplaintFollow', '', 'N', '', 'Y', 'tmp')							
							wComplaintRid = tmp.wComplaintRid,
							-- wTranDt = tmp.wTranDt, 
							wFollowBy = tmp.wFollowBy, 
							wFollowDeptCd = tmp.wFollowDeptCd, 
							wContent = tmp.wContent, 
							wSolveDt = tmp.wSolveDt, 
							wSolveContent = tmp.wSolveContent, 
							wPreventContent = tmp.wPreventContent, 
							wStatus = tmp.wStatus, 
							wCrtDt = tmp.wCrtDt, 
							wCrtBy = tmp.wCrtBy, 
							wUpdDt = dbo.fnUTC8Now(), 
							wUpdBy = tmp.wUpdBy
                        FROM    dbo.eComplaintFollow AS d
                                INNER JOIN #sDataSet_SetComplaintFollow tmp ON d.RowID = tmp.RowID
                        WHERE   d.RowID = tmp.RowID;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN						
							UPDATE 
								d
							SET 
								wStatus='T'
							FROM
								dbo.eComplaintFollow d
							INNER JOIN 
								#sDataSet_SetComplaintFollow t ON d.RowID = t.RowID
                        END;

            IF @vBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
			IF @pReturnResultSet = 'Y'
				SELECT RowID FROM #sDataSet_SetComplaintFollow;

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
			
			IF @vBeginTranCount = 0 BEGIN
				IF @xstate != 0
					ROLLBACK;
	            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT, @vErrMessageLog OUTPUT;
			END
			ELSE
				THROW;

        END CATCH;
	
        EXEC sp_xml_removedocument @vDocHandle;

		IF OBJECT_ID('tempdb..#sDataSet_SetComplaintFollow') IS NOT NULL
			DROP TABLE #sDataSet_SetComplaintFollow
    END;