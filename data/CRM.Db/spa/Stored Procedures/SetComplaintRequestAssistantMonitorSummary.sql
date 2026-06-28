CREATE PROC [spa].[SetComplaintRequestAssistantMonitorSummary]
    @pTableName VARCHAR(100),
    @pTableXML  XML
AS
    BEGIN
        SET NOCOUNT ON;

         -- 戶口跟進組、員工
        -------------------------------------------------------------------------------
        CREATE TABLE #vTeam (RowID BIGINT PRIMARY KEY);
        CREATE TABLE #vAgentFollowUsr (wUsrRid BIGINT PRIMARY KEY);
        CREATE TABLE #vTeamMembers (wADAccount VARCHAR(40) PRIMARY KEY);

        IF NULLIF(@pTableName, '') IS NOT NULL
        BEGIN
            DECLARE @sAgentCodeIn   VARCHAR(14),
                    @sTimeStamp     DATETIME2(7),
                    @sTableRid      BIGINT,
                    @vFigureXML     XML,
                    @vUserXML       XML;

            DECLARE @sRuningIndex   INT,
                    @sRecCount      INT;

            DECLARE @vTable TABLE (RowNum INT IDENTITY(1, 1), RowID BIGINT);

            IF @pTableXML IS NOT NULL
            BEGIN
                INSERT INTO @vTable (RowID)
                SELECT DISTINCT tmp.RowID FROM (
                    SELECT RowID = T.tmp.value('@RowID', 'BIGINT')
                    FROM @pTableXML.nodes('DataSet/Record') T(tmp)
                ) tmp WHERE tmp.RowID > 0;
            END

            SET @sRuningIndex = 1;
            SET @sRecCount = (SELECT COUNT(1) FROM @vTable);

            WHILE @sRuningIndex <= @sRecCount
            BEGIN
                SET @sTableRid = (SELECT TOP(1) RowID FROM @vTable WHERE RowNum = @sRuningIndex);
                    
                -- Write Api Log
                -----------------------------------------------------------------------------------
                IF @pTableName = 'eComplaint'
                BEGIN
                    SELECT @sAgentCodeIn = wAgentCodeIn, @sTimeStamp = wUpdDt FROM dbo.eComplaint WHERE RowID = @sTableRid;

                    SET @vFigureXML = (SELECT wFunction = 'COMPLAINT' FOR XML RAW('Record'), ROOT('DataSet'));
                END
                ELSE IF @pTableName = 'eAdvice'
                BEGIN
                    SELECT @sAgentCodeIn = wAgentCodeIn, @sTimeStamp = wUpdDt FROM dbo.eAdvice WHERE RowID = @sTableRid;

                    SET @vFigureXML = (SELECT wFunction = 'REQUEST' FOR XML RAW('Record'), ROOT('DataSet'));
                END
                ELSE
                BEGIN
                    SET @sAgentCodeIn = NULL;
                    SET @sTimeStamp = NULL;
                    SET @vFigureXML = NULL;
                END

                IF NULLIF(@sAgentCodeIn, '') IS NOT NULL
                BEGIN
                    -- 必須清空數據
                    DELETE FROM #vTeam;
                    DELETE FROM #vAgentFollowUsr;
                    DELETE FROM #vTeamMembers;

                    -- 戶口跟進人
                    INSERT INTO #vAgentFollowUsr(wUsrRid)
                    SELECT afd.wUsrRid 
                    FROM RollsMary.dbo.mAgentFollow af
                    INNER JOIN RollsMary.dbo.mAgentFollowDtl afd ON afd.wAgentFollowRid = af.RowID
                    WHERE af.wAgentCodeIn = @sAgentCodeIn
                        AND af.wStatus = 'A' AND af.wYearMth = ''
                        AND afd.wStatus = 'A' AND afd.wYearMth = ''
                    GROUP BY afd.wUsrRid;

                    -- 跟進組
                    INSERT INTO #vTeam( RowID )
                    SELECT tm.wTeamRID
                    FROM RollsMary.dbo.eTeamMembers tm
                    INNER JOIN RollsMary.dbo.mUsr mu ON mu.RowID = tm.wUsrRID
                    INNER JOIN #vAgentFollowUsr afu ON afu.wUsrRid = mu.RowID
                    WHERE tm.wStatus = 'A'
                        AND tm.wYearMth = ''
                        AND mu.wStatus <> 'DELETED'
                    GROUP BY tm.wTeamRID;

                    -- 更改數據會影響到： 跟進人 + 跟進組Leader
                    INSERT INTO #vTeamMembers( wADAccount )
                    SELECT mu.wADAccount
                    FROM RollsMary.dbo.eTeamMembers tm
                    INNER JOIN RollsMary.dbo.mUsr mu ON mu.RowID = tm.wUsrRID
                    LEFT JOIN #vAgentFollowUsr afu ON afu.wUsrRid = mu.RowID
                    LEFT JOIN  #vTeam t ON t.RowID = tm.wTeamRID
                    WHERE tm.wStatus = 'A'
                        AND tm.wYearMth = ''
                        AND mu.wStatus <> 'DELETED'
                        AND NULLIF(mu.wADAccount, '') IS NOT NULL
                        AND (afu.wUsrRid IS NOT NULL OR (t.RowID IS NOT NULL AND tm.wRole IN ('LEADER', 'MANAGER', 'MANAGEMENT')))
                    GROUP BY mu.wADAccount;
                    -------------------------------------------------------------------------------
                
                    -- Write api log to call sunpeople api
                    IF EXISTS (SELECT 1 FROM #vTeamMembers)
                    BEGIN
                        SET @vUserXML = (SELECT wADAccount FROM #vTeamMembers FOR XML RAW('Record'), ROOT('DataSet'));
                    
                        EXEC RollsMary.spa.SUNMD_SetAssistantMonitorSummary @pUserXML   = @vUserXML,
                                                                            @pFigureXML = @vFigureXML,
                                                                            @pTimeStamp = @sTimeStamp;
                    END
                END
                -----------------------------------------------------------------------------------

                SET @sRuningIndex = @sRuningIndex + 1;
            END
        END

        IF OBJECT_ID('tempdb..#vTeam') IS NOT NULL
            DROP TABLE #vTeam;

        IF OBJECT_ID('tempdb..#vAgentFollowUsr') IS NOT NULL
            DROP TABLE #vAgentFollowUsr;

        IF OBJECT_ID('tempdb..#vTeamMembers') IS NOT NULL
            DROP TABLE #vTeamMembers;
    END