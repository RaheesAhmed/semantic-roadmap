CREATE PROCEDURE [spa].[SetComplaint]
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
EXEC spa.setComplaint 
	N'<DataSet><Record RowID="-1" wTranDt="2017-02-20T00:00:00" wRefNo="" wAgentCodeIn="1000010180" wComplainantName="陳大文" 
	wPersonRid="-1" wComplainantNickname="小虎哥" wComplainantTitle="大人物" wComplainantTel="2233445566" wType="TEST" wChannel="TEST" wReceivedBy="1" 
	wReceivedDeptCd="IT" wReceivedLocation="中土12樓" wComplainBy="1" wComplainDeptCd="IT" wComplainLocation="中土11樓" wComplainCompNo="10" wContent="測試內容"
	wComplaintStatus="PROGRESS"	wStatus="A" wCrtDt="2017-02-20T00:00:00" wCrtBy="1" wUpdDt="2017-02-20T00:00:00" wUpdBy="1"/></DataSet>',
	'I', 99, '', @vErrCode, @vErrMsg
SELECT @vErrCode, @vErrMsg
SELECT top 100 * FROM eComplaint order by wUpdDt
*/
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @vThisTableName VARCHAR(50) = 'eComplaint' , -- For RowID 
                @vBeginTranCount INT = 0 ,
                @vRecCount INT = 0 ,
                @vRuningIndex INT = 1 ,
                @vRowID BIGINT = 0,
                @vRefNo BIGINT = 0,
                @vDocHandle INT,
                @vNow DATETIME2(7);

        SET @vBeginTranCount = @@trancount;
        SET @pErrCode = 0;
        SET @pErrMsg = '';
        SET @vNow = dbo.fnUTC8Now();

        -- dbml
        --declare @vRtnList table (
        --	RowID bigint not null
        --)
        --Select * from @vRtnList
        --return

        EXEC sp_xml_preparedocument @vDocHandle OUTPUT, @pXML;
	    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetComplaint
        FROM    OPENXML (@vDocHandle, 'DataSet/Record', 1)
        WITH (
            RowID BIGINT, 
            wTranDt DATETIME2, 
            wRefNo VARCHAR(30), 
            wAgentCodeIn VARCHAR(14), 
            wComplainantName NVARCHAR(50), 
            wPersonRid BIGINT, 
            wComplainantNickname NVARCHAR(50), 
            wComplainantTitle NVARCHAR(30), 
            wComplainantTel VARCHAR(100), 
            wType VARCHAR(30), 
            wChannel VARCHAR(30), 
            wReceivedBy BIGINT, 
            wReceivedDeptCd VARCHAR(30), 
            wReceivedLocation NVARCHAR(30), 
            wComplainBy BIGINT, 
            wComplainDeptCd VARCHAR(30), 
            wComplainLocation NVARCHAR(30), 
            wComplainCompNo INT, 
            wContent NVARCHAR(2000), 
            wComplaintStatus VARCHAR(30), 
            wCancelRemark NVARCHAR(500), 
            wStatus CHAR(1), 
            wCrtDt DATETIME2, 
            wCrtBy BIGINT, 
            wUpdDt DATETIME2, 
            wUpdBy BIGINT,
            wIntroduction NVARCHAR(2000)
        );

        --better don't put everything within try, for example
        --getting mSysTable value
        --getting currency, period, mCompany ...

        UPDATE ds
        SET ds.wPersonRid = p.RowID
        FROM #sDataSet_SetComplaint ds
        INNER JOIN dbo.mPerson p ON ds.wAgentCodeIn = p.wAgentCodeIn AND ds.wComplainantName = p.wCName AND p.wStatus = 'A'
	    
        BEGIN TRY
            -- Try to make the transaction scope as small as possible to reduce locking
            IF @vBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;

            -----------------------------------------------Checking---------------------------------------------
            IF EXISTS (SELECT 1 FROM #sDataSet_SetComplaint WHERE wIntroduction IS NULL)
                THROW 50001, N'簡介不能為空', 1;
            -----------------------------------------------End Checking-----------------------------------------

            IF @pActionType = 'I'
            BEGIN
                IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqeComplaintRefNo') AND type = 'SO')
                BEGIN
                    CREATE SEQUENCE seqeComplaintRefNo START WITH 1000 INCREMENT BY 1 MAXVALUE 99999999999999
                END
               
                -- Set RowID by Sequence
                UPDATE  #sDataSet_SetComplaint
                SET     RowID = 0;

                SELECT  @vRecCount = COUNT(*)
                FROM    #sDataSet_SetComplaint;
				
                WHILE @vRuningIndex <= @vRecCount
                BEGIN
                    EXEC spq.GetRowID @pMainCompNo, @vThisTableName, @vRowID OUTPUT;

                    UPDATE  #sDataSet_SetComplaint
                    SET     RowID = @vRowID, 
                            wRefNo = 'CAS' + FORMAT(NEXT VALUE FOR dbo.seqeComplaintRefNo, '0000000')
                    WHERE   wRowNum = @vRuningIndex;

                    SET @vRuningIndex = @vRuningIndex + 1;
                END;

                -- MAIN Logic here, example here is inserting dataset to eComplaint
                -- PRINT [dbo].[fnGetAllFieldNameInTable]('eComplaint', '', 'N', '', '', '')
                INSERT  INTO dbo.[eComplaint]
                (
                    RowID, 
                    wTranDt, 
                    wRefNo, 
                    wAgentCodeIn, 
                    wComplainantName, 
                    wPersonRid, 
                    wComplainantNickname, 
                    wComplainantTitle, 
                    wComplainantTel, 
                    wType, 
                    wChannel, 
                    wReceivedBy, 
                    wReceivedDeptCd, 
                    wReceivedLocation, 
                    wComplainBy, 
                    wComplainDeptCd, 
                    wComplainLocation, 
                    wComplainCompNo, 
                    wContent, 
                    wComplaintStatus, 
                    wCancelRemark, 
                    wStatus, 
                    wCrtDt, 
                    wCrtBy, 
                    wUpdDt, 
                    wUpdBy,
                    wIntroduction,
                    wDealDt
                )
                SELECT
                    RowID, 
                    wTranDt, 
                    wRefNo, 
                    wAgentCodeIn,
                    wComplainantName, 
                    wPersonRid, 
                    wComplainantNickname, 
                    wComplainantTitle, 
                    wComplainantTel,
                    wType, 
                    wChannel, 
                    wReceivedBy, 
                    wReceivedDeptCd, 
                    wReceivedLocation, 
                    wComplainBy, 
                    wComplainDeptCd, 
                    wComplainLocation, 
                    wComplainCompNo, 
                    wContent, 
                    wComplaintStatus, 
                    wCancelRemark, 
                    wStatus, 
                    @vNow, 
                    wUpdBy, 
                    @vNow,
                    wUpdBy,
                    wIntroduction,
                    @vNow
                FROM #sDataSet_SetComplaint s;
            END;
            ELSE IF @pActionType = 'U'
                BEGIN
                    UPDATE  d
                    SET
                        wTranDt = tmp.wTranDt, 
                        -- wRefNo = tmp.wRefNo, -- 投訴編號不能修改
                        wAgentCodeIn = tmp.wAgentCodeIn, 
                        wComplainantName = tmp.wComplainantName, 
                        wPersonRid = tmp.wPersonRid, 
                        wComplainantNickname = tmp.wComplainantNickname, 
                        wComplainantTitle = tmp.wComplainantTitle, 
                        wComplainantTel = tmp.wComplainantTel, 
                        wType = tmp.wType, 
                        wChannel = tmp.wChannel, 
                        wReceivedBy = tmp.wReceivedBy, 
                        wReceivedDeptCd = tmp.wReceivedDeptCd, 
                        wReceivedLocation = tmp.wReceivedLocation, 
                        wComplainBy = tmp.wComplainBy, 
                        wComplainDeptCd = tmp.wComplainDeptCd, 
                        wComplainLocation = tmp.wComplainLocation, 
                        wComplainCompNo = tmp.wComplainCompNo, 
                        wContent = tmp.wContent, 
                        wComplaintStatus = tmp.wComplaintStatus,
                        wCancelRemark = tmp.wCancelRemark, 
                        wStatus = tmp.wStatus, 
                        -- wCrtDt = tmp.wCrtDt, 創建時間不能修改
                        -- wCrtBy = tmp.wCrtBy, 創建者不能修改
                        wUpdDt = @vNow, 
                        wUpdBy = tmp.wUpdBy,
                        wIntroduction=tmp.wIntroduction,
                        wDealDt = IIF(d.wComplaintStatus = tmp.wComplaintStatus, d.wDealDt, @vNow) -- 處理狀態沒有發生改變，處理日期不修改
                    FROM dbo.eComplaint AS d
                    INNER JOIN #sDataSet_SetComplaint tmp ON d.RowID = tmp.RowID
                    WHERE d.RowID = tmp.RowID;
                END;
                ELSE IF @pActionType = 'D'
                BEGIN						
                    UPDATE d
                    SET 
                        wStatus='T',
                        wUpdDt = @vNow,
                        wUpdBy = tmp.wUpdBy,
                        wDealDt = @vNow
                    FROM dbo.eComplaint d
                    INNER JOIN  #sDataSet_SetComplaint t ON d.RowID = t.RowID
                END;

            -- 2019-04-25：OP#28045，Write change Log
            -----------------------------------------------------------------------------------------
            DECLARE @pComplaintXML XML;
            SET @pComplaintXML = (SELECT RowID FROM #sDataSet_SetComplaint FOR XML RAW('Record'), ROOT('DataSet'));
            EXEC spa.SetComplaintChange @pComplaintXML  = @pComplaintXML,
                                        @pSendSunPeople = 'Y',
                                        @pErrCode       = @pErrCode OUTPUT,
                                        @pErrMsg        = @pErrMsg OUTPUT;
            -----------------------------------------------------------------------------------------

            -- 【Calendar】-->【Mary】
            -----------------------------------------------------------------------------------------
            IF EXISTS (SELECT 1 FROM #sDataSet_SetComplaint WHERE ISNULL(RowID, 0) > 0) 
            BEGIN
                DECLARE c_Complaint CURSOR FOR SELECT RowID FROM #sDataSet_SetComplaint WHERE ISNULL(RowID, 0) > 0;
                
                OPEN c_Complaint;

                FETCH NEXT FROM c_Complaint INTO @vRowID;

                WHILE @@fetch_status = 0
                BEGIN
                    EXEC util.WriteMaryAgentActivitiesApiLog @pBookingRid = @vRowID, @pBookingType = 'eComplaint';

                    FETCH NEXT FROM c_Complaint INTO @vRowID;
                END;

                CLOSE c_Complaint;
                DEALLOCATE c_Complaint;
            END;
            -----------------------------------------------------------------------------------------

            IF @vBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                COMMIT;
            END;

            -- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT RowID FROM #sDataSet_SetComplaint;

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

            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @vErrorNum, ') ', @vCatchErrorMessage);
			
            IF @vBeginTranCount = 0
            BEGIN
                IF @xstate != 0
                    ROLLBACK;

                EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT, @vErrMessageLog OUTPUT;
            END
            ELSE
                THROW;

        END CATCH;
	
        EXEC sp_xml_removedocument @vDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetComplaint') IS NOT NULL
            DROP TABLE #sDataSet_SetComplaint
    END;