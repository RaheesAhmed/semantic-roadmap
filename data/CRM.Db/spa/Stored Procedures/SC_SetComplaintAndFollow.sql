
CREATE PROCEDURE [spa].[SC_SetComplaintAndFollow]
    (
      @pComplaintXML XML ,
      @pFollowXML XML ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(1000) OUTPUT
    )
AS
    BEGIN
	/*
	declare @pComplaintXML XML,
			@pFollowXML XML,
			@pErrCode INT,
			@pErrMsg NVARCHAR(1000)

	set @pComplaintXML=N'<DataSet><Record RowID="0" wTranDt="2017-08-21 11:00:04.387064" wAgentCodeIn="1000010180" wComplainantName="華哥"
							wComplainantNickname="" wComplainantTitle="戶主" wComplainantTel="23423" wType="CASINO" wChannel="COMMENT" 
							wReceivedBy="0" wReceivedLocation="Table 10" wComplainBy="0" wComplainLocation="Table 10" wComplainCompNo="0" 
							wContent="" wComplaintStatus="UNTREATED" wCancelRemark=""/>
							</DataSet>'
	set @pFollowXML=N'<DataSet><Record RowID="0" wComplaintRid="99000000010007" wTranDt="2017-08-21 11:04:00.000000" 
							wFollowBy="1000000281" wContent="Hello World" wSolveContent="" wPreventContent="" wStatus="A"/>
						</DataSet>'	
	exec spa.SC_SetComplaintAndFollow  @pComplaintXML, @pFollowXML, @pErrCode OUTPUT, @pErrMsg  OUTPUT
	
	SELECT @pErrCode , @pErrMsg
	*/
        SET NOCOUNT ON;

	--dbml
	--DECLARE @RtnResult AS TABLE(
	--	wDataSetName	VARCHAR(30),
	--	wRefRowID		BIGINT,
	--	wResponseType	VARCHAR(30)
	--)

	--SELECT *
	--FROM @RtnResult;
	--RETURN;

        DECLARE @sMainCompNo INT = 99 ,
            @sBeginTranCount INT = 0 ,
            @sDocHandle_Complaint INT ,
            @sDocHandle_Follow INT ,
            @sXMLStr XML ,
           -- @sUpdBy BIGINT= 100000001 ,
            @sCount INT ,
            @sActionType CHAR(1) ,
            @sAgentCodeIn VARCHAR(14) ,
            @sRowID BIGINT ,
            @sHdrRowID BIGINT;

	
        SET @sBeginTranCount = @@trancount;

        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';

        CREATE TABLE #RtnResult
            (
              wDataSetName VARCHAR(30) ,
              wRefRowID BIGINT ,
              wResponseType VARCHAR(30)
            );

        CREATE TABLE #RtnHdr_Result ( RowID BIGINT );

        CREATE TABLE #RtnDtl_Result ( RowID BIGINT );
		
        EXEC sp_xml_preparedocument @sDocHandle_Complaint OUTPUT, @pComplaintXML;
        EXEC sp_xml_preparedocument @sDocHandle_Follow OUTPUT, @pFollowXML;
	
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_Complaint
        FROM    OPENXML (@sDocHandle_Complaint, 'DataSet/Record', 1)
	WITH (
		RowID BIGINT, wTranDt DATETIME2, wRefNo VARCHAR(30), wAgentCodeIn VARCHAR(14), wComplainantName NVARCHAR(50), 
			wPersonRid BIGINT, wComplainantNickname NVARCHAR(50), wComplainantTitle NVARCHAR(30), wComplainantTel VARCHAR(100), 
			wType VARCHAR(30), wChannel VARCHAR(30), wReceivedBy BIGINT, wReceivedDeptCd VARCHAR(30), wReceivedLocation NVARCHAR(30), 
			wComplainBy BIGINT, wComplainDeptCd VARCHAR(30), wComplainLocation NVARCHAR(30), wComplainCompNo INT, wContent NVARCHAR(2000), 
			wComplaintStatus VARCHAR(30), wCancelRemark NVARCHAR(500), wStatus CHAR(1), wCrtDt DATETIME2, wCrtBy BIGINT, wUpdDt DATETIME2, wUpdBy BIGINT,
            wIntroduction NVARCHAR(2000)
	);	

        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_Follow
        FROM    OPENXML (@sDocHandle_Follow, 'DataSet/Record', 1)
	WITH (
		RowID BIGINT, wComplaintRid BIGINT, wTranDt DATETIME2, wFollowBy BIGINT, wFollowDeptCd VARCHAR(30), 
			wContent NVARCHAR(2000), wSolveDt DATETIME2, wSolveContent NVARCHAR(2000), wPreventContent NVARCHAR(2000), 
			wStatus CHAR(1), wCrtDt DATETIME2, wCrtBy BIGINT, wUpdDt DATETIME2, wUpdBy BIGINT
	);

        BEGIN TRY
		
		-- Try to make the transaction scope as small as possible to reduce locking
		
		-- Validation
		
            SELECT  @sCount = COUNT(*)
            FROM    #sDataSet_Complaint;

            IF ( ISNULL(@sCount, 0) = 0 )
                BEGIN
                    SET @pErrCode = '307';
                    SET @pErrMsg = N'CRM - Missing Complaint_Data';
                    RAISERROR (@pErrMsg, 16, 1);     
                END;
            ELSE
                IF ( ISNULL(@sCount, 0) > 1 )
                    BEGIN
                        SET @pErrCode = '308';
                        SET @pErrMsg = N'CRM - Not allow more than one row for Complaint_Data';
                        RAISERROR (@pErrMsg, 16, 1);     
                    END;

		-- Check Fields
            SELECT TOP 1
                    @sRowID = RowID ,
                    @sActionType = ( CASE WHEN ISNULL(RowID, 0) > 0 THEN 'U'
                                          ELSE 'I'
                                     END ) ,
                    @sAgentCodeIn = ISNULL(wAgentCodeIn, '')
            FROM    #sDataSet_Complaint;
		
		--select * from #sDataSet_Complaint		
		--select @sActionType
		--select * from #sDataSet_TaskSheet

            IF @sAgentCodeIn = ''
                BEGIN
                    SET @pErrCode = '303';
                    SET @pErrMsg = N'CRM - Missing wAgentCodeIn';
                    RAISERROR (@pErrMsg, 16, 1);		
                END;
            ELSE
                IF NOT EXISTS ( SELECT  *
                                FROM    RollsMary.dbo.mAgent
                                WHERE   wAgentCodeIn = @sAgentCodeIn
                                        AND wStatus <> 'T'
                                        AND wType = 'AGENT' )
                    BEGIN
                        SET @pErrCode = '3';
                        SET @pErrMsg = N'Agent Not Found';
                        RAISERROR (@pErrMsg, 16, 1);
                    END;
				ELSE
                    IF EXISTS ( SELECT  *
                                FROM    #sDataSet_Complaint s
                                        LEFT JOIN RollsMary.dbo.mDepartment m ON s.wReceivedDeptCd= m.wCode
                                WHERE   m.wActive = 'A'
										AND ISNULL(s.wReceivedDeptCd, '')<>''
                                        AND m.RowID IS NULL )
                        BEGIN
                            SET @pErrCode = '318';
                            SET @pErrMsg = N'Received Department Not Found';
                            RAISERROR (@pErrMsg, 16, 1);
                        END;
				ELSE
                    IF EXISTS ( SELECT  *
                                FROM    #sDataSet_Complaint s
                                        LEFT JOIN RollsMary.dbo.mDepartment m ON s.wComplainDeptCd= m.wCode
                                WHERE   m.wActive = 'A'
										AND ISNULL(s.wComplainDeptCd, '')<>''
                                        AND m.RowID IS NULL )
                        BEGIN
                            SET @pErrCode = '319';
                            SET @pErrMsg = N'Complaint Department Not Found';
                            RAISERROR (@pErrMsg, 16, 1);
                        END;
				ELSE
                    IF EXISTS ( SELECT  *
                                FROM    #sDataSet_Follow s
                                        LEFT JOIN RollsMary.dbo.mDepartment m ON s.wFollowDeptCd= m.wCode
                                WHERE   m.wActive = 'A'
										AND ISNULL(s.wFollowDeptCd, '')<>''
                                        AND m.RowID IS NULL )
                        BEGIN
                            SET @pErrCode = '320';
                            SET @pErrMsg = N'Follow Department Not Found';
                            RAISERROR (@pErrMsg, 16, 1);
                        END;
                ELSE
                    IF EXISTS ( SELECT  *
                                FROM    #sDataSet_Complaint s
                                        LEFT JOIN RollsMary.dbo.mUsr usr ON s.wReceivedBy = usr.RowID
                                WHERE   usr.wStatus = 'A'
										AND ISNULL(s.wReceivedBy, 0) > 0
                                        AND usr.RowID IS NULL )
                        BEGIN
                            SET @pErrCode = '321';
                            SET @pErrMsg = N'Received Staff Not Found';
                            RAISERROR (@pErrMsg, 16, 1);
                        END;
				 ELSE
                    IF EXISTS ( SELECT  *
                                FROM    #sDataSet_Complaint s
                                        LEFT JOIN RollsMary.dbo.mUsr usr ON s.wComplainBy = usr.RowID
                                WHERE   usr.wStatus = 'A'
										AND ISNULL(s.wComplainBy, 0) > 0
                                        AND usr.RowID IS NULL )
                        BEGIN
                            SET @pErrCode = '322';
                            SET @pErrMsg = N'Complaint Staff Not Found';
                            RAISERROR (@pErrMsg, 16, 1);
                        END;
				 ELSE
                    IF EXISTS ( SELECT  *
                                FROM    #sDataSet_Complaint s
                                        LEFT JOIN RollsMary.dbo.mUsr usr ON s.wUpdBy = usr.RowID
                                WHERE   usr.wStatus = 'A'
                                        AND usr.RowID IS NULL )
                        BEGIN
                            SET @pErrCode = '316';
                            SET @pErrMsg = N'Complaint - Updated Staff Not Found';
                            RAISERROR (@pErrMsg, 16, 1);
                        END;
				ELSE
                    IF EXISTS ( SELECT  *
                                FROM	#sDataSet_Follow) 
							AND EXISTS ( SELECT  *
									FROM    #sDataSet_Follow s
											LEFT JOIN RollsMary.dbo.mUsr usr ON s.wUpdBy = usr.RowID
									WHERE   usr.wStatus = 'A'
											AND usr.RowID IS NULL )
                        BEGIN
                            SET @pErrCode = '317';
                            SET @pErrMsg = N'Follow - Updated Staff Not Found';
                            RAISERROR (@pErrMsg, 16, 1);	
						END;
													
            IF @sActionType = 'U'
                BEGIN
                    IF NOT EXISTS ( SELECT  *
                                    FROM    dbo.eComplaint e
                                            INNER JOIN #sDataSet_Complaint s ON s.RowID = e.RowID )
                        BEGIN
                            SET @pErrCode = '308';
                            SET @pErrMsg = N'Transaction Not found';
                            RAISERROR (@pErrMsg, 16, 1);
                        END;	
                    ELSE
                        IF EXISTS ( SELECT  *
                                    FROM    dbo.eComplaint e
                                            INNER JOIN #sDataSet_Complaint s ON s.RowID = e.RowID
                                    WHERE   e.wStatus != 'A' )
                            BEGIN
                                SET @pErrCode = '306';
                                SET @pErrMsg = N'System Status is terminated';
                                RAISERROR (@pErrMsg, 16, 1);
                            END;
                        ELSE
                            BEGIN
                                UPDATE  s
                                SET     s.wRefNo = e.wRefNo ,
                                        s.wPersonRid = e.wPersonRid ,
                                        s.wCrtDt = e.wCrtDt ,
                                        s.wCrtBy = e.wCrtBy ,
                                        s.wStatus = e.wStatus
                                FROM    #sDataSet_Complaint s
                                        INNER JOIN dbo.eComplaint e ON s.RowID = e.RowID;
                            END;
                END;

            IF EXISTS ( SELECT  *
                        FROM    #sDataSet_Follow cf
                        WHERE   ISNULL(cf.RowID, 0) > 0 )
                BEGIN
                    IF NOT EXISTS ( SELECT  *
                                    FROM    #sDataSet_Follow cf
                                            INNER JOIN dbo.eComplaintFollow f ON f.RowID = cf.RowID
                                    WHERE   ISNULL(cf.RowID, 0) > 0
                                            AND f.wComplaintRid = @sRowID )
                        BEGIN				
                            SET @pErrCode = '307';
                            SET @pErrMsg = N'Follow List not in detail of Complaint Data';
                            RAISERROR (@pErrMsg, 16, 1);
                        END; 
                END;

		------------------------------------------------------------------------------
		-- Update Related Fields
		/*
            UPDATE  c
            SET     c.wReceivedDeptCd = ISNULL(usr_re.wDept, '') ,
                    c.wComplainDeptCd = ISNULL(usr_complaint.wDept, '')
            FROM    #sDataSet_Complaint c
                    LEFT JOIN RollsMary.dbo.mUsr usr_re ON usr_re.RowID = c.wReceivedBy
                    LEFT JOIN RollsMary.dbo.mUsr usr_complaint ON usr_complaint.RowID = c.wComplainBy;

            UPDATE  cf
            SET     cf.wFollowDeptCd = ISNULL(usr.wDept, '')
            FROM    #sDataSet_Follow cf
                    INNER JOIN RollsMary.dbo.mUsr usr ON usr.RowID = cf.wFollowBy;	*/
		------------------------------------------------------------------------------

            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            SET @sXMLStr = ( SELECT RowID ,
                                    wTranDt ,
                                    wRefNo ,
                                    wAgentCodeIn ,
                                    wComplainantName ,
                                    wPersonRid = ( CASE WHEN @sActionType = 'I' THEN 0
                                                        ELSE wPersonRid
                                                   END ) ,
                                    wComplainantNickname ,
                                    wComplainantTitle ,
                                    wComplainantTel ,
                                    wType ,
                                    wChannel ,
                                    wReceivedBy ,
                                   wReceivedDeptCd = ISNULL(wReceivedDeptCd,'') ,

                                    wReceivedLocation ,
                                    wComplainBy ,
                                    wComplainDeptCd = ISNULL(wComplainDeptCd,'') ,

                                    wComplainLocation ,
                                    wComplainCompNo ,
                                    wContent ,
                                    wComplaintStatus = ( CASE WHEN @sActionType = 'I' THEN 'UNTREATED'
                                                              ELSE wComplaintStatus
                                                         END ) ,
                                    wCancelRemark ,
                                    wCrtDt = ( CASE WHEN @sActionType = 'I' THEN dbo.fnUTC8Now()
                                                    ELSE wCrtDt
                                               END ) ,
                                    wCrtBy = ( CASE WHEN @sActionType = 'I' THEN ISNULL(wUpdBy,0)
                                                    ELSE ISNULL(wCrtBy,0)

                                               END ) ,
                                    wUpdDt = dbo.fnUTC8Now() ,
                                    wUpdBy = ISNULL(wUpdBy,0) ,

                                    wStatus = ( CASE WHEN @sActionType = 'I' THEN 'A'
                                                     ELSE wStatus
                                                END ),
						     wIntroduction = ISNULL(wIntroduction, '')

                             FROM   #sDataSet_Complaint
                           FOR
                             XML RAW('Record') ,
                                 ROOT('DataSet')
                           );	

            INSERT  INTO #RtnHdr_Result
                    EXEC [spa].[SetComplaint] @sXMLStr, @sActionType, @sMainCompNo, '', 'Y', @pErrCode OUTPUT, @pErrMsg OUTPUT;
									
            IF ( @pErrCode != 0 )
                BEGIN
                    RAISERROR (@pErrMsg, 16, 1);     
                END;

            INSERT  INTO #RtnResult
                    ( wDataSetName ,
                      wRefRowID ,
                      wResponseType
                    )
                    SELECT  'Complaint_Data' ,
                            RowID ,
                            ( CASE WHEN @sActionType = 'I' THEN 'INSERTED'
                                   ELSE 'UPDATED'
                              END )
                    FROM    #RtnHdr_Result;

            SELECT  @sHdrRowID = RowID
            FROM    #RtnHdr_Result;
		
		-- New Tran. of Details
            IF EXISTS ( SELECT  *
                        FROM    #sDataSet_Follow
                        WHERE   ISNULL(RowID, 0) = 0 )
                BEGIN
                    SET @sXMLStr = ( SELECT RowID ,
                                            wComplaintRid = @sHdrRowID ,
                                            wTranDt = dbo.fnUTC8Now() ,
                                            wFollowBy ,
                                            wFollowDeptCd = ISNULL(wFollowDeptCd,'') ,

                                            wContent ,
                                            wSolveDt ,
                                            wSolveContent ,
                                            wPreventContent ,
                                            wStatus = 'A' ,
                                            wCrtDt = dbo.fnUTC8Now() ,
                                            wCrtBy = ISNULL(wUpdBy,0) ,

                                            wUpdDt = dbo.fnUTC8Now() ,
                                            wUpdBy = ISNULL(wUpdBy,0)			    
								  

                                     FROM   #sDataSet_Follow
                                     WHERE  ISNULL(RowID, 0) = 0
                                   FOR
                                     XML RAW('Record') ,
                                         ROOT('DataSet')
                                   );

                    INSERT  INTO #RtnDtl_Result
                            EXEC [spa].[SetComplaintFollow] @sXMLStr, 'I', @sMainCompNo, '', 'Y', @pErrCode OUTPUT, @pErrMsg OUTPUT;

                    IF ( @pErrCode != 0 )
                        BEGIN
                            RAISERROR (@pErrMsg, 16, 1);     
                        END;

                    INSERT  INTO #RtnResult
                            ( wDataSetName ,
                              wRefRowID ,
                              wResponseType
                            )
                            SELECT  'Follow_Data' ,
                                    RowID ,
                                    'INSERTED'
                            FROM    #RtnDtl_Result;

                END;
		
		-- Update Existing Tran. of Details
            IF EXISTS ( SELECT  *
                        FROM    #sDataSet_Follow
                        WHERE   ISNULL(RowID, 0) > 0 )
                BEGIN
                    UPDATE  tmp
                    SET     tmp.wComplaintRid = cf.wComplaintRid ,
                            tmp.wCrtDt = cf.wCrtDt ,
                            tmp.wCrtBy = cf.wCrtBy ,
                            tmp.wUpdDt = dbo.fnUTC8Now() ,
                            tmp.wUpdBy = cf.wUpdBy
                    FROM    #sDataSet_Follow tmp
                            INNER JOIN dbo.eComplaintFollow cf ON cf.RowID = tmp.RowID
                    WHERE   ISNULL(tmp.RowID, 0) > 0
                            AND cf.wComplaintRid = @sHdrRowID;
								
                    SELECT  @sXMLStr = ( SELECT *
                                         FROM   #sDataSet_Follow tmp
                                         WHERE  ISNULL(RowID, 0) > 0
                                                AND tmp.wComplaintRid = @sHdrRowID
                                       FOR
                                         XML RAW('Record') ,
                                             ROOT('DataSet')
                                       );

                    INSERT  INTO #RtnDtl_Result
                            EXEC [spa].[SetComplaintFollow] @sXMLStr, 'U', @sMainCompNo, '', 'Y', @pErrCode OUTPUT, @pErrMsg OUTPUT;

                    IF ( @pErrCode != 0 )
                        BEGIN
                            RAISERROR (@pErrMsg, 16, 1);     
                        END;

                    INSERT  INTO #RtnResult
                            ( wDataSetName ,
                              wRefRowID ,
                              wResponseType
                            )
                            SELECT  'Follow_Data' ,
                                    RowID ,
                                    'UPDATED'
                            FROM    #RtnDtl_Result;
                END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

		-- Return Result
            SELECT  *
            FROM    #RtnResult;

        END TRY
        BEGIN CATCH
            DECLARE @sErrorNum INT ,
                @sCatchErrorMessage NVARCHAR(4000) ,
                @xstate INT ,
                @sProcedureName VARCHAR(100) ,
                @sRtnCodeLog INT ,
                @sErrMessageLog NVARCHAR(4000);

            SELECT  @sErrorNum = ERROR_NUMBER() ,
                    @sCatchErrorMessage = ERROR_MESSAGE() ,
                    @xstate = XACT_STATE() ,
                    @sProcedureName = OBJECT_NAME(@@PROCID);

            IF ISNULL(@pErrCode, 0) = 0
                BEGIN
                    SET @pErrCode = 999;
                END;
            IF @pErrMsg <> @sCatchErrorMessage
                SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ', @sCatchErrorMessage);
						
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                AND ( @xstate = 1
                      OR @xstate = -1
                    )
                BEGIN
			-- transaction created within this sp			
                    ROLLBACK;
                END;

		-- Return Empty Result
            SELECT  *
            FROM    #RtnResult;

            DECLARE @pErrCodeLog INT ,
                @pErrMsgLog NVARCHAR(1000);
		-- Write Log
            EXEC spa.WriteErrorLog @sMainCompNo, @sMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;

        END CATCH;

        EXEC sp_xml_removedocument @sDocHandle_Complaint;
        EXEC sp_xml_removedocument @sDocHandle_Follow;
	
        IF OBJECT_ID('tempdb..#sDataSet_Complaint') IS NOT NULL
            DROP TABLE #sDataSet_Complaint;

        IF OBJECT_ID('tempdb..#sDataSet_Follow') IS NOT NULL
            DROP TABLE #sDataSet_Follow;	

        IF OBJECT_ID('tempdb..#RtnResult') IS NOT NULL
            DROP TABLE #RtnResult;
		
        IF OBJECT_ID('tempdb..#RtnDtlResult') IS NOT NULL
            DROP TABLE #RtnDtlResult;
    END;