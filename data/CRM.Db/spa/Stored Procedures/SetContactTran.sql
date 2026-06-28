CREATE PROCEDURE [spa].[SetContactTran]
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
        
        DECLARE @sThisTableName VARCHAR(50) = 'eContactTran' , -- For RowID 
                @sBeginTranCount INT = 0 ,
                @sRecCount INT = 0 ,
                @sRuningIndex INT = 1 ,
                @sRowID BIGINT = 0 ,
                @sNow DATETIME2 = dbo.fnUTC8Now() ,
                @sDocHandle INT;
	    
        SET @sBeginTranCount = @@trancount;
        SET @pErrCode = 0;
        SET @pErrMsg = '';
	    
        -- dbml
        -- SELECT RowID FROM dbo.eContactTran
        --return
        
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
        SELECT wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
               *
        INTO #sDataSet_SetContactTran
        FROM OPENXML (@sDocHandle, 'DataSet/Record', 1)
        WITH (
            RowID BIGINT, 
            wCompNo INT,  
            wContactTypeName NVARCHAR(100), 
            wRefNo VARCHAR(30), 
            wLocation NVARCHAR(50),
            wCategoryCd VARCHAR(100), 
            wSubCategoryCd VARCHAR(100),
            wDeptCd VARCHAR(30), 
            wExpAmount NUMERIC(18,4), 
            wExpAmountCurrCode VARCHAR(3), 
            wDateFrom DATETIME2, 
            wDateTo DATETIME2, 
            wContactStatus VARCHAR(20), 
            wRemark NVARCHAR(4000), 
            wStatus CHAR(1), 
            wCrtDt DATETIME2, 
            wCrtBy BIGINT, 
            wUpdDt DATETIME2, 
            wUpdBy BIGINT,
            wReason NVARCHAR(200),
            wPurpose VARCHAR(30),
            wAdviceRid BIGINT,
            wPeriod VARCHAR(30),
            wApprover BIGINT,
            wRegion VARCHAR(30),
            wAssistantDt DATETIME2,
            wApproverDt DATETIME2
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
                IF NOT EXISTS ( SELECT  1 FROM sys.objects WHERE object_id = OBJECT_ID('seqeContactTranRefNo') AND type = 'SO' )
                BEGIN
                    CREATE SEQUENCE seqeContactTranRefNo START WITH 10000 INCREMENT BY 1 MINVALUE 10000 MAXVALUE 99999999999999
                END

                -- Set RowID, RefNo by Sequence
                UPDATE #sDataSet_SetContactTran
                SET     RowID = 0;

                SELECT @sRecCount = COUNT(1) FROM #sDataSet_SetContactTran;

                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
                    UPDATE #sDataSet_SetContactTran
                    SET RowID = @sRowID , 
                        wRefNo = 'CT' + FORMAT(NEXT VALUE FOR dbo.seqeContactTranRefNo, '0000000')
                    WHERE wRowNum = @sRuningIndex;

                    SET @sRuningIndex = @sRuningIndex + 1;
                END;    		        
				
                -- MAIN Logic here, example here is inserting dataset to eContactTran
                -- PRINT [dbo].[fnGetAllFieldNameInTable]('eContactTran', '', 'N', '', '', '')
                INSERT  INTO dbo.eContactTran 
                (
                    RowID ,
                    wCompNo ,
                    wContactTypeName, 
                    wRefNo ,
                    wLocation ,                            
                    wCategoryCd ,
                    wSubCategoryCd ,
                    wDeptCd ,
                    wExpAmount ,
                    wExpAmountCurrCode ,
                    wDateFrom ,
                    wDateTo ,
                    wContactStatus ,
                    wRemark ,
                    wStatus ,
                    wCrtDt ,
                    wCrtBy ,
                    wUpdDt ,
                    wUpdBy,
                    wReason,
                    wPurpose,
                    wAdviceRid,
                    wPeriod,
                    wApprover,
                    wRegion,
                    wAssistantDt,
                    wApproverDt
                )
                SELECT
                    RowID = sc.RowID ,
                    wCompNo = sc.wCompNo ,
                    wContactTypeName = sc.wContactTypeName,
                    wRefNo = sc.wRefNo ,
                    wLocation = sc.wLocation ,                               
                    wCategoryCd = sc.wCategoryCd ,
                    wSubCategoryCd = ISNULL(sc.wSubCategoryCd, ''),
                    wDeptCd = sc.wDeptCd ,
                    wExpAmount = sc.wExpAmount ,
                    wExpAmountCurrCode = sc.wExpAmountCurrCode ,
                    wDateFrom = sc.wDateFrom ,
                    wDateTo = sc.wDateTo ,
                    wContactStatus = sc.wContactStatus ,
                    wRemark = sc.wRemark ,
                    wStatus = sc.wStatus ,
                    wCrtDt = @sNow ,
                    wCrtBy = sc.wCrtBy ,
                    wUpdDt = @sNow ,
                    wUpdBy = sc.wUpdBy,
                    wReason = sc.wReason,
                    wPurpose = sc.wPurpose,
                    wAdviceRid = sc.wAdviceRid,
                    wPeriod = sc.wPeriod,
                    wApprover = sc.wApprover,
                    wRegion = sc.wRegion,
                    wAssistantDt = sc.wAssistantDt,
                    wApproverDt = sc.wApproverDt
                FROM #sDataSet_SetContactTran sc;
            END
            ELSE IF @pActionType = 'U'
            BEGIN
                UPDATE  sc
                SET
                    wCompNo = tmp.wCompNo ,
                    wContactTypeName = tmp.wContactTypeName,
                    wRefNo = tmp.wRefNo ,
                    wLocation = tmp.wLocation ,                              
                    wCategoryCd = tmp.wCategoryCd ,
                    wSubCategoryCd = ISNULL(tmp.wSubCategoryCd, ''),
                    wDeptCd = tmp.wDeptCd ,
                    wExpAmount = tmp.wExpAmount ,
                    wExpAmountCurrCode = tmp.wExpAmountCurrCode ,
                    wDateFrom = tmp.wDateFrom ,
                    wDateTo = tmp.wDateTo ,
                    wContactStatus = tmp.wContactStatus ,
                    wRemark = tmp.wRemark ,
                    wStatus = tmp.wStatus ,
                    wCrtDt = tmp.wCrtDt ,
                    wCrtBy = tmp.wCrtBy ,
                    wUpdDt = @sNow ,
                    wUpdBy = tmp.wUpdBy,
                    wReason = tmp.wReason,
                    wPurpose = tmp.wPurpose,
                    wAdviceRid = tmp.wAdviceRid,
                    wPeriod = tmp.wPeriod,
                    wApprover = tmp.wApprover,
                    wRegion = tmp.wRegion,
                    wAssistantDt = tmp.wAssistantDt,
                    wApproverDt = tmp.wApproverDt
                FROM dbo.eContactTran sc
                INNER JOIN #sDataSet_SetContactTran tmp ON sc.RowID = tmp.RowID
                WHERE sc.RowID = tmp.RowID;
            END
            ELSE IF @pActionType = 'D'
            BEGIN						
                UPDATE  sc
                SET wStatus = 'T'
                FROM dbo.eContactTran sc
                INNER JOIN #sDataSet_SetContactTran tmp ON sc.RowID = tmp.RowID;
            END;

            -- 【Calendar】-->【Mary】
            IF EXISTS (SELECT 1 FROM #sDataSet_SetContactTran WHERE ISNULL(RowID, 0) > 0) 
            BEGIN
                DECLARE c_ContactTran CURSOR FOR SELECT RowID FROM #sDataSet_SetContactTran WHERE ISNULL(RowID, 0) > 0;
                OPEN c_ContactTran;
                FETCH NEXT FROM c_ContactTran INTO @sRowID
                WHILE @@fetch_status = 0
                BEGIN
                    EXEC util.WriteMaryAgentActivitiesApiLog @pBookingRid = @sRowID, @pBookingType = 'eContactTran';

                    FETCH NEXT FROM c_ContactTran INTO @sRowID;
                END;
                CLOSE c_ContactTran;
                DEALLOCATE c_ContactTran;
            END;

            IF @sBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                COMMIT;
            END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
            BEGIN
                SELECT RowID FROM #sDataSet_SetContactTran;
            END;
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
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ', @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0
                BEGIN
                    IF @xstate != 0
                        ROLLBACK;
                    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
                END;
                ELSE
                    THROW;

        END CATCH;
	
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetContactTran') IS NOT NULL
            DROP TABLE #sDataSet_SetContactTran;
    END;