CREATE PROCEDURE [spa].[SetPersonRelationship]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT,
      @pNonceToken VARCHAR(64),
      @pReturnResultSet CHAR(1) = 'N',
      @pPersonRid BIGINT,
      @pErrCode INT = 0 OUTPUT,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
    )
AS
    BEGIN
        SET NOCOUNT ON;		

        ----SELECT * FROM [mPersonRelationship];

        DECLARE @sThisTableName VARCHAR(50) = 'mPersonRelationship' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sSeqNo INT = 0,
            @sPersonRecCount INT = 0,
            @sPersonRuningIndex INT = 1,
            @sRtnPersonRid BIGINT,
            @sDocHandle INT;
            
            
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );

        DECLARE @sPerson TABLE(
            wRowNum BIGINT,
            RowID BIGINT,
            wRefRID BIGINT
        )
        
        SET @sBeginTranCount = @@trancount;

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
        
        --  
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetPersonRelationship
        FROM    OPENXML (@sDocHandle, 'DataSet/SetPersonRelationshipResult', 1)
        WITH (
                RowID BIGINT ,
                wPersonRid BIGINT,
                wRelatePersonRid BIGINT,
                wRefRID BIGINT,--R#33859,因為建立關係的時候可以選授權人,所以先用這個字段存，最終是需要使得mPerson裡面有一個wRefRid對應
                wRelationType VARCHAR(30),
                wRemark NVARCHAR(500),
                wSeqNo INT ,
                wUpdBy BIGINT ,
                wUpdDt DATETIME2(7),
                wStatus char(1)
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

            --R#33859，mPerson中要插入戶口內的授權人
            IF (SELECT COUNT(*) FROM #sDataSet_SetPersonRelationship WHERE wRefRID > 0) > 0
            BEGIN
                INSERT INTO @sPerson( wRowNum, RowID, wRefRID )
                SELECT ROW_NUMBER() OVER ( ORDER BY ds.wRefRID ), 0, ds.wRefRID
                FROM #sDataSet_SetPersonRelationship ds
                LEFT JOIN dbo.mPerson p ON p.wRefRID = ds.wRefRID AND p.wRefRID IS NOT NULL
                WHERE ds.wRefRID > 0 AND p.RowID IS NULL
                GROUP BY ds.wRefRID

                SELECT  @sPersonRecCount = COUNT(*)
                FROM    @sPerson;
                WHILE @sPersonRuningIndex <= @sPersonRecCount
                BEGIN
                    EXEC spq.GetRowID @pMainCompNo, 'mPerson',
                        @sRowID OUTPUT;
                    
                    UPDATE  @sPerson
                    SET     RowID = @sRowID
                    WHERE   wRowNum = @sPersonRuningIndex;
                    SET @sPersonRuningIndex = @sPersonRuningIndex + 1;
                END;

                INSERT  INTO dbo.[mPerson]([RowID],[wAgentCodeIn],[wCName],[wEName],[wNickname],[wRole],[wSpeakLangCd],
                                            [wWritenLangCd],[wGender],[wBirthdate],[wNationality],[wProvince],[wAddress],
                                            [wTelBusiness],[wTelHome],[wTelOther],[wRefRID],[wStatus],[wCrtBy],[wCrtDt],
                                            [wUpdBy],[wUpdDt])
                SELECT s.RowID ,ma.wAgentCodeIn,'','','','','','','','','','','','','','',s.wRefRID ,'',-1,dbo.fnUTC8Now(),-1,dbo.fnUTC8Now()
                FROM    @sPerson s
                LEFT JOIN RollsMary.dbo.mAgent ma ON ma.RowID = s.wRefRID

                UPDATE ds
                SET ds.wRelatePersonRid = p.RowID
                FROM #sDataSet_SetPersonRelationship ds
                INNER JOIN dbo.mPerson p ON p.wRefRID = ds.wRefRID AND p.wRefRID IS NOT NULL
                WHERE ds.wRefRID > 0
            END
            
            IF @pActionType = 'I'
                BEGIN
                -- Set RowID by Sequence
                    UPDATE  #sDataSet_SetPersonRelationship
                    SET     RowID = 0,wSeqNo = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetPersonRelationship;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
                    
                        IF @sSeqNo = 0
                            BEGIN
                                Select @sSeqNo = ISNULL(MAX(wSeqNo),1) From dbo.[mPersonRelationship]
                                SET @sSeqNo = @sSeqNo + 1
                            END
                            ELSE
                            BEGIN
                                SET @sSeqNo = @sSeqNo + 1
                        END
                            UPDATE #sDataSet_SetPersonRelationship
                            SET     RowID = @sRowID, 
                                    wPersonRid = @pPersonRid,
                                    wSeqNo = @sSeqNo
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
                
                -- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[mPersonRelationship]
                            (
                                [RowID],
                                [wPersonRid],
                                [wRelatePersonRid],
                                [wRelationType],
                                [wRemark],
                                [wSeqNo],						
                                [wCrtBy],
                                [wCrtDt],
                                [wUpdBy],
                                [wUpdDt],
                                [wStatus]
                            )
                            SELECT
                                    s.RowID ,
                                    s.wPersonRid,								
                                    s.wRelatePersonRid,
                                    s.wRelationType,
                                    s.wRemark,
                                    s.wSeqNo,				
                                    s.wUpdBy,
                                    dbo.fnUTC8Now(),
                                    s.wUpdBy,
                                    dbo.fnUTC8Now(),
                                    'A'
                            FROM    #sDataSet_SetPersonRelationship s;
                END;

                ELSE
                IF @pActionType = 'U'
                    BEGIN

                    DELETE FROM mPersonRelationship
                    WHERE wPersonRid = @pPersonRid OR wRelatePersonRid = @pPersonRid

                    --DELETE FROM dbo.mPersonRelationship
     --                   WHERE wPersonRid IN ( SELECT  wPersonRID FROM #sDataSet_SetPersonRelationship );

                    UPDATE  #sDataSet_SetPersonRelationship
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetPersonRelationship;
                    WHILE @sRuningIndex <= @sRecCount
     BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
                    
                            UPDATE #sDataSet_SetPersonRelationship
                            SET     RowID = @sRowID--,
                                    --wPersonRid = @pPersonRid
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
                
                -- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[mPersonRelationship]
                            (
                                [RowID],
                                [wPersonRid],
                                [wRelatePersonRid],
                                [wRelationType],
                                [wRemark],
                                [wSeqNo],						
                                [wCrtBy],
                                [wCrtDt],
                                [wUpdBy],
                                [wUpdDt],
                                [wStatus]
                                
                            )
                            SELECT
                                    s.RowID ,
                                    s.wPersonRid,								
                                    s.wRelatePersonRid,
                                    s.wRelationType,
                                    s.wRemark,
                                    s.wSeqNo,				
                                    s.wUpdBy,
                                    dbo.fnUTC8Now(),
                                    s.wUpdBy,
                                    dbo.fnUTC8Now(),
                                    s.wStatus
                            FROM    #sDataSet_SetPersonRelationship s;
                    END;     
                    
        IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;
                
        -- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetPersonRelationship;					  
         
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
            
            IF @sBeginTranCount = 0 BEGIN
                IF @xstate != 0
                    ROLLBACK;
                EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT, @vErrMessageLog OUTPUT;
            END
            ELSE
                THROW;

        END CATCH;
    
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetPersonRelationship') IS NOT NULL DROP TABLE #sDataSet_SetPersonRelationship;
        
END;