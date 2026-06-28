CREATE PROCEDURE [spa].[SC_SetGrpAdviceAndReq]
    (
	 @pUpdBy	BIGINT,				-- R#43680 : API:apiSC/v1/SetGrpAdviceAndReq 加入wUpdBy在header部分 20180205
      @pAdviceAndReqXML XML ,
      @pTaskSheetXML XML ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(1000) OUTPUT
    )
AS
    BEGIN
	/*
	declare @pAdviceAndReqXML XML,
			@pTaskSheetXML XML,
			@pErrCode INT,
			@pErrMsg NVARCHAR(1000)

	set @pAdviceAndReqXML='<DataSet><Record RowID="10000000001000" wAim="TT01540_3" wDate="2017-08-16 23:06:34.405694" wAgentCodeIn="1000010180" wType="01" wSubType="0102" 	wIsHighPriority="N" 
								wReceivedBy="100000010010" wReceivedDeptCd="CAGE" wAdviceStatus="OPEN" wContent="t___XX_esttest" wStatus="A" wCrtDt="0001-01-01 00:00:00.000000" 
								wCrtBy="0" wUpdDt="0001-01-01 00:00:00.000000" 	wUpdBy="100000010010" /></DataSet>'
	set @pTaskSheetXML='<DataSet><Record RowID="" wCounterRid="10000000010001" wDeptCd="CAGE" wUsrRid="100000010010" wDate="2017-08-17" 
							wTaskType="" wSubTaskType="" wIsInhouse="N" wContent="tet21TT" wRemark="tT2est" wRelateAgentCodeIn="" wRelatedType="eAdvice" 
							wRelatedRid="10000000001000" wHasDoc="Y" wStatus="A" wCrtDt="0001-01-01 00:00:00.000000" 
							wCrtBy="1000000000" wUpdDt="2017-08-17 00:55:45.992787" wUpdBy="1000000000" 
							wFollowUpDt="2017-08-17 00:55:45.993787" wFollowUpBy="1000000000" wTaskSheetStatus="P" /></DataSet>'
	exec spa.SC_SetGrpAdviceAndReq  @pAdviceAndReqXML, @pTaskSheetXML, @pErrCode OUTPUT, @pErrMsg  OUTPUT
	
	SELECT @pErrCode , @pErrMsg
	*/
        SET NOCOUNT ON;

	----dbml
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
            @sDocHandle_AdviceAndReq INT ,
            @sDocHandle_TaskSheet INT ,
            @sXMLStr XML ,
            --@sUpdBy BIGINT= 100000001 ,  -- 加入wUpdBy 在Header部分 20180205
            @sCount INT ,
            @sActionType CHAR(1) ,
            @sAgentCodeIn VARCHAR(14) ,
            @sRowID BIGINT ,
            @sHdrRowID BIGINT;

		SET @pUpdBy = ISNULL(@pUpdBy,100000001);
			
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
		
        EXEC sp_xml_preparedocument @sDocHandle_AdviceAndReq OUTPUT, @pAdviceAndReqXML;
        EXEC sp_xml_preparedocument @sDocHandle_TaskSheet OUTPUT, @pTaskSheetXML;
	
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_AdviceAndReq
        FROM    OPENXML (@sDocHandle_AdviceAndReq, 'DataSet/Record', 1)
	WITH (
		RowID			BIGINT,
		wAim			NVARCHAR(200),
		wIsHighPriority	VARCHAR(1),
		wDate			DATETIME2(7),
		wAgentCodeIn	VARCHAR(14),
		wReceivedDeptCd	VARCHAR(30),
		wReceivedBy		BIGINT,
		wType			VARCHAR(30),
		wSubType		VARCHAR(30),
		wContent		NVARCHAR(2000),
		wAdviceStatus	VARCHAR(20)		
	);	

        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_TaskSheet
        FROM    OPENXML (@sDocHandle_TaskSheet, 'DataSet/Record', 1)
	WITH (
		RowID				BIGINT,
		wCompNo				INT,
		wCounterRid			BIGINT,
		wDeptCd				VARCHAR(30),
		wDate				DATETIME2(7),
		wTaskType			VARCHAR(30),
		wSubTaskType		VARCHAR(30),
		wRelateAgentCodeIn	VARCHAR(14),
		wIsInhouse			VARCHAR(1),
		wContent			NVARCHAR(4000),
		wRemark				NVARCHAR(500),
		wFollowUpBy			BIGINT,
		wTaskSheetStatus	VARCHAR(30)
	);

        BEGIN TRY
		
		-- Try to make the transaction scope as small as possible to reduce locking
		
		-- Validation
		
            SELECT  @sCount = COUNT(*)
            FROM    #sDataSet_AdviceAndReq;

            IF ( ISNULL(@sCount, 0) = 0 )
                BEGIN
                    SET @pErrCode = '301';
                    SET @pErrMsg = N'CRM - Missing Advice_Req_Data';
                    RAISERROR (@pErrMsg, 16, 1);     
                END;
            ELSE
                IF ( ISNULL(@sCount, 0) > 1 )
                    BEGIN
                        SET @pErrCode = '302';
                        SET @pErrMsg = N'CRM - Not allow more than one row for Advice_Req_Data';
                        RAISERROR (@pErrMsg, 16, 1);     
                    END;

		-- Check Fields
            SELECT TOP 1
                    @sRowID = RowID ,
                    @sActionType = ( CASE WHEN ISNULL(RowID, 0) > 0 THEN 'U'
                                          ELSE 'I'
                                     END ) ,
                    @sAgentCodeIn = ISNULL(wAgentCodeIn, '')
            FROM    #sDataSet_AdviceAndReq;
		
		--select * from #sDataSet_AdviceAndReq		
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
                                FROM    #sDataSet_AdviceAndReq s
                                        LEFT JOIN RollsMary.dbo.mUsr usr ON s.wReceivedBy = usr.RowID
                                WHERE   usr.wStatus = 'A'
                                        AND usr.RowID IS NULL )
                        BEGIN
                            SET @pErrCode = '304';
                            SET @pErrMsg = N'Received Staff Not Found';
                            RAISERROR (@pErrMsg, 16, 1);
                        END;
                    ELSE
                        IF EXISTS ( SELECT  *
                                    FROM    #sDataSet_AdviceAndReq s
                                            LEFT JOIN RollsMary.dbo.mDepartment m ON m.wCode = s.wReceivedDeptCd
                                    WHERE   m.wActive = 'A'
                                            AND m.RowID IS NULL )
                            BEGIN
                                SET @pErrCode = '305';
                                SET @pErrMsg = N'Received Department Not Found';
                                RAISERROR (@pErrMsg, 16, 1);
                            END;
            IF @sActionType = 'U'
                BEGIN
                    IF EXISTS ( SELECT  *
                                FROM    dbo.eAdvice e
                                        INNER JOIN #sDataSet_AdviceAndReq s ON s.RowID = e.RowID
                                WHERE   e.wStatus != 'A' )
                        BEGIN
                            SET @pErrCode = '306';
                            SET @pErrMsg = N'System Status is terminated';
                            RAISERROR (@pErrMsg, 16, 1);
                        END;
			
                END;

            IF EXISTS ( SELECT  *
                        FROM    #sDataSet_TaskSheet t
                        WHERE   ISNULL(t.RowID, 0) > 0 )
                BEGIN
                    IF NOT EXISTS ( SELECT  *
                                    FROM    #sDataSet_TaskSheet t
                                            INNER JOIN dbo.eTaskSheet s ON s.RowID = t.RowID
                                    WHERE   ISNULL(t.RowID, 0) > 0
                                            AND s.wRelatedRid = @sRowID
                                            AND s.wRelatedType = 'eAdvice' )
                        BEGIN				
                            SET @pErrCode = '307';
                            SET @pErrMsg = N'Task Sheet not in detail of Advice Req Data';
                            RAISERROR (@pErrMsg, 16, 1);
                        END; 
                END;

		------------------------------------------------------------------------------

            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
		
            SET @sXMLStr = ( SELECT RowID ,
                                    wAim ,
                                    wDate = CAST(wDate AS DATE) ,
                                    wAgentCodeIn = ISNULL(wAgentCodeIn, '') ,
                                    wReceivedBy ,
                                    wReceivedDeptCd ,
                                    wType ,
                                    wSubType ,
                                    wIsHighPriority ,
                                    wAdviceStatus ,
                                    wContent ,
                                    wStatus = 'A' ,
									wRefNo = '',
                                    wCrtDt = SYSDATETIME() ,
                                    wCrtBy = @pUpdBy ,	 -- wCrtBy = @sUpdBy , -- R#43680 : API:apiSC/v1/SetGrpAdviceAndReq 加入wUpdBy在header部分 20180205
                                    wUpdDt = SYSDATETIME() ,
                                    wUpdBy = @pUpdBy	 -- wUpdBy = @sUpdBy  -- R#43680 : API:apiSC/v1/SetGrpAdviceAndReq 加入wUpdBy在header部分 20180205
                             FROM   #sDataSet_AdviceAndReq
                           FOR
                             XML RAW('Record') ,
                                 ROOT('DataSet')
                           );	

            INSERT  INTO #RtnHdr_Result
                    EXEC [spa].[SetAdvice] @sXMLStr, @sActionType, @sMainCompNo, '', 'Y', @pErrCode OUTPUT, @pErrMsg OUTPUT;
									
            IF ( @pErrCode != 0 )
                BEGIN
                    RAISERROR (@pErrMsg, 16, 1);     
                END;

            INSERT  INTO #RtnResult
                    ( wDataSetName ,
                      wRefRowID ,
                      wResponseType
                    )
                    SELECT  'Advice_Req_Data' ,
                            RowID ,
                            ( CASE WHEN @sActionType = 'I' THEN 'INSERTED'
                                   ELSE 'UPDATED'
                              END )
                    FROM    #RtnHdr_Result;

            SELECT  @sHdrRowID = RowID
            FROM    #RtnHdr_Result;

		-- Auto update wCompNo
            UPDATE  ts
            SET     ts.wCompNo = sc.wRollexCompNo
            FROM    #sDataSet_TaskSheet ts
                    INNER JOIN dbo.mServiceCounter sc ON sc.RowID = ts.wCounterRid;

            IF EXISTS ( SELECT  *
                        FROM    #sDataSet_TaskSheet
                        WHERE   ISNULL(RowID, 0) = 0 )
                BEGIN
                    SET @sXMLStr = ( SELECT RowID = 0 ,
                                            wCompNo ,
                                            wCounterRid ,
                                            wDeptCd ,
                                            wUsrRid = @pUpdBy ,		 -- wUsrRid = @sUpdBy , -- R#43680 : API:apiSC/v1/SetGrpAdviceAndReq 加入wUpdBy在header部分 20180205
                                            wDate = CAST(wDate AS DATE) ,
                                            wTaskType ,
                                            wSubTaskType ,
                                            wIsInhouse ,
                                            wContent ,
                                            wRemark ,
                                            wRelateAgentCodeIn ,
                                            wRelatedType = 'eAdvice' ,
                                            wRelatedRid = @sHdrRowID ,
                                            wHasDoc = 'N' ,
                                            wStatus = 'A' ,
                                            wCrtDt = SYSDATETIME() ,
                                            wCrtBy = @pUpdBy ,			 -- wCrtBy = @sUpdBy ,-- R#43680 : API:apiSC/v1/SetGrpAdviceAndReq 加入wUpdBy在header部分 20180205
                                            wUpdDt = SYSDATETIME() ,
                                            wUpdBy = @pUpdBy ,			 --  wUpdBy = @sUpdBy , -- R#43680 : API:apiSC/v1/SetGrpAdviceAndReq 加入wUpdBy在header部分 20180205
                                            wFollowUpDt = SYSDATETIME() ,
                                            wFollowUpBy ,
                                            wTaskSheetStatus
                                     FROM   #sDataSet_TaskSheet
                                     WHERE  ISNULL(RowID, 0) = 0
                                   FOR
                                     XML RAW('Record') ,
                                         ROOT('DataSet')
                                   );

                    INSERT  INTO #RtnDtl_Result
                            EXEC [spa].[SetTaskSheet] @sXMLStr, 'I', @sMainCompNo, '', 'Y', @pErrCode OUTPUT, @pErrMsg OUTPUT;

                    IF ( @pErrCode != 0 )
                        BEGIN
                            RAISERROR (@pErrMsg, 16, 1);     
                        END;

                    INSERT  INTO #RtnResult
                            ( wDataSetName ,
                              wRefRowID ,
                              wResponseType
                            )
                            SELECT  'TaskSheet_Data' ,
                                    RowID ,
                                    'INSERTED'
                            FROM    #RtnDtl_Result;

                END;

            IF EXISTS ( SELECT  *
                        FROM    #sDataSet_TaskSheet
                        WHERE   ISNULL(RowID, 0) > 0 )
                BEGIN
                    SET @sXMLStr = ( SELECT RowID ,
                                            wCompNo ,
                                            wCounterRid ,
                                            wDeptCd ,
                                            wUsrRid = @pUpdBy ,			 --wUsrRid = @sUpdBy ,	 -- R#43680 : API:apiSC/v1/SetGrpAdviceAndReq 加入wUpdBy在header部分 20180205
                                            wDate = CAST(wDate AS DATE) ,
                                            wTaskType ,
                                            wSubTaskType ,
                                            wIsInhouse ,
                                            wContent ,
                                            wRemark ,
                                            wRelateAgentCodeIn = ISNULL(wRelateAgentCodeIn, '') ,
                                            wRelatedType = 'eAdvice' ,
                                            wRelatedRid = @sHdrRowID ,
                                            wHasDoc = 'N' ,
                                            wStatus = 'A' ,
                                            wCrtDt = SYSDATETIME() ,
                                            wCrtBy = @pUpdBy ,				 --wCrtBy = @sUpdBy ,	 -- R#43680 : API:apiSC/v1/SetGrpAdviceAndReq 加入wUpdBy在header部分 20180205
                                            wUpdDt = SYSDATETIME() ,
                                            wUpdBy = @pUpdBy ,				 --wUpdBy = @sUpdBy ,	 -- R#43680 : API:apiSC/v1/SetGrpAdviceAndReq 加入wUpdBy在header部分 20180205
                                            wFollowUpDt = SYSDATETIME() ,
                                            wFollowUpBy ,
                                            wTaskSheetStatus
                                     FROM   #sDataSet_TaskSheet
                                     WHERE  ISNULL(RowID, 0) > 0
                                   FOR
                                     XML RAW('Record') ,
                                         ROOT('DataSet')
                                   );

                    INSERT  INTO #RtnDtl_Result
                            EXEC [spa].[SetTaskSheet] @sXMLStr, 'U', @sMainCompNo, '', 'Y', @pErrCode OUTPUT, @pErrMsg OUTPUT;

                    IF ( @pErrCode != 0 )
                        BEGIN
                            RAISERROR (@pErrMsg, 16, 1);     
                        END;

                    INSERT  INTO #RtnResult
                            ( wDataSetName ,
                              wRefRowID ,
                              wResponseType
                            )
                            SELECT  'TaskSheet_Data' ,
                                    RowID ,
                                    'UPDATEED'
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

        EXEC sp_xml_removedocument @sDocHandle_AdviceAndReq;
        EXEC sp_xml_removedocument @sDocHandle_TaskSheet;
	
        IF OBJECT_ID('tempdb..#sDataSet_AdviceAndReq') IS NOT NULL
            DROP TABLE #sDataSet_AdviceAndReq;

        IF OBJECT_ID('tempdb..#sDataSet_TaskSheet') IS NOT NULL
            DROP TABLE #sDataSet_TaskSheet;	

        IF OBJECT_ID('tempdb..#RtnResult') IS NOT NULL
            DROP TABLE #RtnResult;
		
        IF OBJECT_ID('tempdb..#RtnDtlResult') IS NOT NULL
            DROP TABLE #RtnDtlResult;
    END;