--sp_helptext 'spa.SetAccountRelationshipUplinerSettings'


CREATE PROCEDURE [spa].[SetAccountRelationshipUplinerSettings]
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
		--select * from mAccountRelationshipDownlineSetting
        DECLARE @sThisTableName VARCHAR(50) = 'mAccountRelationshipDownlineSetting' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
			
	        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
	        
        SET @sBeginTranCount = @@trancount;
	    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #DataSet_SetAccountRelationshipUplinerSetting
        FROM    OPENXML (@sDocHandle, 'DataSet/SetAccountRelationshipUplinerSettingsResult', 1)
		WITH (
				RowID  BIGINT,
				wIsMeetingReminder  VARCHAR(5),
				wIsEventReminder  VARCHAR(5),
				wIsGiftReminder  VARCHAR(5),
				wGiftRemark  NVARCHAR(500),
				wIsInvitationReminder VARCHAR(5),
				wIsBirthdayReminder VARCHAR(5),
				wIsProvideRepaymentStatus VARCHAR(5),
				wBirthdayMealPresentArrangement VARCHAR(5),
				wTargetAchievedGift VARCHAR(5),
				wEventInvitation VARCHAR(5),
				wWaytoRemind VARCHAR(5),
				wWaytoRemindRemarks NVARCHAR(500),
				wIsResponsibleForExpenses VARCHAR(5),
				wUplineSettingsType VARCHAR(5),
				wAgentCodeIn VARCHAR(14),
				wDownlineAgentCodeIn VARCHAR(14),
				wCrtDt DATETIME2(7),
				wCrtBy BIGINT,
				wUpdDt DATETIME2(7),
				wUpdBy BIGINT
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

            DECLARE @rowId BIGINT; 
            SET @rowId = ( SELECT   RowID
                           FROM     #DataSet_SetAccountRelationshipUplinerSetting
                         ); 
            IF @rowId = 0
                BEGIN
                    SET @pActionType = 'I'; 
                END;
            ELSE
                BEGIN
                    SET @pActionType = 'U';
                END;

				-- Try to make the transaction scope as small as possible to reduce locking
            DECLARE @uplineSettingType VARCHAR(5);
            SET @uplineSettingType = ( SELECT   wUplineSettingsType
                                       FROM     #DataSet_SetAccountRelationshipUplinerSetting
                                     );
            PRINT @uplineSettingType;
            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #DataSet_SetAccountRelationshipUplinerSetting
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #DataSet_SetAccountRelationshipUplinerSetting;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
                            UPDATE  #DataSet_SetAccountRelationshipUplinerSetting
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
                    IF CAST(( SELECT    wAgentCodeIn
                              FROM      #DataSet_SetAccountRelationshipUplinerSetting
                            ) AS BIGINT) > 0
                        BEGIN
                            DECLARE @vAgentLevel INT ,
                                @vUplinerAgentCodeIn VARCHAR(14);
                            SELECT  @vAgentLevel = wAgentLevel
                            FROM    RollsMary.dbo.mAgent
                            WHERE   wAgentCodeIn = ( SELECT wAgentCodeIn
                                                     FROM   #DataSet_SetAccountRelationshipUplinerSetting
                                                   );
                            SELECT  @vUplinerAgentCodeIn = wLvlAgentCodeIn
                            FROM    RollsMary.dbo.mAgentLevel
                            WHERE   wAgentCodeIn = ( SELECT wAgentCodeIn
                                                     FROM   #DataSet_SetAccountRelationshipUplinerSetting
                                                   )
                                    AND wAgentLevel = ( @vAgentLevel - 1 );
                            --IF ( @uplineSettingType ) <> 'DEF'
                                BEGIN
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                                    INSERT  INTO dbo.[mAccountRelationshipDownlineSetting]
                                            ( RowID ,
                                              wIsMeetingReminder ,
                                              wIsEventReminder ,
                                              wIsGiftReminder ,
                                              wGiftRemark ,
                                              wIsInvitationReminder ,
                                              wIsBirthdayReminder ,
                                              wIsProvideRepaymentStatus ,
                                              wBirthdayMealPresentArrangement ,
                                              wTargetAchievedGift ,
                                              wEventInvitation ,
                                              wWaytoRemind ,
                                              wWaytoRemindRemarks ,
                                              wIsResponsibleForExpenses ,
                                              wUplineSettingsType ,
                                              wAgentCodeIn ,
                                              wDownlineAgentCodeIn ,
                                              wCrtDt ,
                                              wCrtBy ,
                                              wUpdDt ,
                                              wUpdBy
							                )
                                            SELECT  s.RowID ,
                                                    s.wIsMeetingReminder ,
                                                    s.wIsEventReminder ,
                                                    s.wIsGiftReminder ,
                                                    s.wGiftRemark ,
                                                    s.wIsInvitationReminder ,
                                                    s.wIsBirthdayReminder ,
                                                    s.wIsProvideRepaymentStatus ,
                                                    s.wBirthdayMealPresentArrangement ,
                                                    s.wTargetAchievedGift ,
                                                    s.wEventInvitation ,
                                                    s.wWaytoRemind ,
                                                    s.wWaytoRemindRemarks ,
                                                    s.wIsResponsibleForExpenses ,
                                                    @uplineSettingType ,
                                                    @vUplinerAgentCodeIn ,
                                                    s.wDownlineAgentCodeIn ,
                                                    s.wCrtDt ,
                                                    s.wCrtBy ,
                                                    s.wUpdDt ,
                                                    s.wUpdBy
                                            FROM    #DataSet_SetAccountRelationshipUplinerSetting s;
                                END;
                        END;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
					
                        DECLARE @temp INT; 
                        SET @temp = ( SELECT    COUNT(*)
                                      FROM      dbo.mAccountRelationshipDownlineSetting AS ards
                                                INNER JOIN #DataSet_SetAccountRelationshipUplinerSetting tmp ON ards.RowID = tmp.RowID
                                      WHERE     ards.RowID = tmp.RowID
                                    );
                        IF ( @uplineSettingType ) <> 'DEF'
                            BEGIN
                                PRINT 'BEFORE UPDATED';
                                UPDATE  ards
                                SET     -- Can use dbo.fnGetAllFieldNameInTable('eIOUPenalty','','N','N','Y','tmp') to get below string
                                        ards.wIsMeetingReminder = tmp.wIsMeetingReminder ,
                                        ards.wIsEventReminder = tmp.wIsEventReminder ,
                                        ards.wIsGiftReminder = tmp.wIsGiftReminder ,
                                        ards.wGiftRemark = tmp.wGiftRemark ,
                                        ards.wIsInvitationReminder = tmp.wIsInvitationReminder ,
                                        ards.wIsBirthdayReminder = tmp.wIsBirthdayReminder ,
                                        ards.wIsProvideRepaymentStatus = tmp.wIsProvideRepaymentStatus ,
                                        ards.wBirthdayMealPresentArrangement = tmp.wBirthdayMealPresentArrangement ,
                                        ards.wTargetAchievedGift = tmp.wTargetAchievedGift ,
                                        ards.wEventInvitation = tmp.wEventInvitation ,
                                        ards.wWaytoRemind = tmp.wWaytoRemind ,
                                        ards.wWaytoRemindRemarks = tmp.wWaytoRemindRemarks ,
                                        ards.wIsResponsibleForExpenses = tmp.wIsResponsibleForExpenses ,
                                        ards.wUplineSettingsType = tmp.wUplineSettingsType ,
                                        ards.wUpdDt = tmp.wUpdDt ,
                                        ards.wUpdBy = tmp.wUpdBy
                                FROM    dbo.mAccountRelationshipDownlineSetting AS ards
                                        INNER JOIN #DataSet_SetAccountRelationshipUplinerSetting tmp ON ards.wAgentCodeIn = tmp.wAgentCodeIn
                                                              AND ards.wDownlineAgentCodeIn = tmp.wDownlineAgentCodeIn;
                                PRINT 'UPDATED';
                            END;
						
                        IF ( @uplineSettingType ) = 'DEF'
                            BEGIN
							
                                DECLARE @dAgentCodeIn VARCHAR(14) = ( SELECT wDownlineAgentCodeIn
                                                              FROM #DataSet_SetAccountRelationshipUplinerSetting
                                                              );
                                DECLARE @AgentCodeIn VARCHAR(14) = ( SELECT wAgentCodeIn
                                                              FROM #DataSet_SetAccountRelationshipUplinerSetting
                                                              );
                                PRINT @dAgentCodeIn;
                                PRINT @AgentCodeIn;
                                UPDATE  dbo.mAccountRelationshipDownlineSetting
                                SET     wUplineSettingsType = 'DEF'
                                WHERE   wDownlineAgentCodeIn = @dAgentCodeIn
                                        AND wAgentCodeIn = @AgentCodeIn;
                            END;
                    END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END; 
				
			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #DataSet_SetAccountRelationshipUplinerSetting;	               

            RETURN;
        END TRY
        BEGIN CATCH
            DECLARE @vErrorNum INT ,
                @vCatchErrorMessage NVARCHAR(4000) ,
                @xstate INT ,
                @vProcedureName VARCHAR(100) ,
                @vRtnCodeLog INT ,
                @vErrMessageLog NVARCHAR(4000);
	        
            SET @vErrorNum = ERROR_NUMBER();
            SET @vCatchErrorMessage = ERROR_MESSAGE();
            SET @xstate = XACT_STATE();
            SET @vProcedureName = OBJECT_NAME(@@PROCID);
			
            IF ISNULL(@pErrCode, 0) = 0
                BEGIN
                    SET @pErrCode = 999;
                END;
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @vErrorNum, ') ', @vCatchErrorMessage);
			
            IF @sBeginTranCount = 0
                BEGIN
                    IF @xstate != 0
                        ROLLBACK;
                    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT, @vErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;

        END CATCH;
	
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#DataSet_SetAccountRelationshipUplinerSetting') IS NOT NULL
            DROP TABLE #DataSet_SetAccountRelationshipUplinerSetting;		
		
    END;