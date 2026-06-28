CREATE PROC [spa].[SetVIPPersonForAgent]
    @pAgentCodeIn VARCHAR(14)
AS
    BEGIN
        DECLARE @sVIPPersonRid  BIGINT,
                @sAgentType     VARCHAR(10), -- 戶口類型（授權人、戶口）
                @sYear          INT,
                @sNow           DATETIME2(7) = GETDATE();

        SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');

        IF @pAgentCodeIn IS NOT NULL
        BEGIN
            SET @sVIPPersonRid = 0;
            -- Old：判斷戶口是授權人（幕後老闆、戶主、授權人、伙計）亦或系AGENT（其他戶口類型，不做任何操作）
            -- Old：SET @sAgentType = (SELECT 'AUTH' FROM RollsMary.dbo.mAgent WHERE wAgentCodeIn = @pAgentCodeIn AND wType = 'AUTH' AND wAuthIdentity IN ('BOSS', 'OWNER', 'AUTH', 'STAFF'));
            -- New：判斷戶口是授權人亦或系AGENT（其他戶口類型，不做任何操作）
            SET @sAgentType = (SELECT 'AUTH' FROM RollsMary.dbo.mAgent WHERE wAgentCodeIn = @pAgentCodeIn AND wType = 'AUTH');
            SET @sAgentType = ISNULL(@sAgentType, (SELECT 'AGENT' FROM RollsMary.dbo.mAgent WHERE wAgentCodeIn = @pAgentCodeIn AND wType = 'AGENT'));
            
            -- 授權人
            IF @sAgentType = 'AUTH'
            BEGIN
                -- 授權人是否已經加入到VIP客戶資料
                -- NULL, 戶口不存在，不作任何操作
                -- > 0 , 資料已存在，更新客戶資料
                -- = 0 , 資料不存在，新增客戶資料
                SET @sVIPPersonRid = (
                    SELECT TOP(1) ISNULL(mp.RowID, 0) 
                    FROM RollsMary.dbo.mAgent ma
                    LEFT JOIN dbo.mVIPPerson mp ON mp.wAgentCodeIn = ma.wUpLvlAgentCodeIn AND mp.wAuthorizerAgentCodeIn = ma.wAgentCodeIn AND mp.wIsAuthorizer = 'Y' AND mp.wStatus = 'A'
                    WHERE ma.wAgentCodeIn = @pAgentCodeIn
                );

                -- 如果授權人沒有加入到VIP客戶資料，則新增
                IF @sVIPPersonRid = 0
                BEGIN
                    -- RollsMary新增授權人，不需要傳授權人戶口
                    EXEC util.RecalVIPPerson NULL, @pAgentCodeIn, 'I';

                    -- 檢查是否Import成功
                    SET @sVIPPersonRid = (
                        SELECT TOP(1) mp.RowID
                        FROM RollsMary.dbo.mAgent ma
                        LEFT JOIN dbo.mVIPPerson mp ON mp.wAgentCodeIn = ma.wUpLvlAgentCodeIn AND mp.wAuthorizerAgentCodeIn = ma.wAgentCodeIn AND mp.wIsAuthorizer = 'Y' AND mp.wStatus = 'A'
                        WHERE ma.wAgentCodeIn = @pAgentCodeIn
                    );

                    -- 如果新增VIP客戶資料成功，自動生成一條生日記錄
                    IF @sVIPPersonRid > 0
                    BEGIN
                        -- Old: util.RecalVIPPerson默認送禮，@pAgentCodeIn有效值、NULL、空值，生成客戶生日eBirthday（空值 --> 指定授權人@sVIPPersonRid，非空 --> 戶口指定授權人@pAgentCodeIn and @sVIPPersonRid)
                        -- New: util.RecalVIPPerson默認不送禮，新增VIP客戶資料不影響生日eBirthday，所以此處@pAgentCodeIn='Y'（任意非空的無效值，不做任何操作）
                        SET @sYear = YEAR(@sNow);
                        EXEC util.RecalVIPPersonBirthday @sYear, 'N', @sVIPPersonRid, 'Y';
                    END;
                END
                -- 如果VIP客戶資料存在，Update資料
                ELSE IF @sVIPPersonRid > 0
                BEGIN
                    -- RollsMary更新授權人，不需要傳授權人戶口
                    EXEC util.RecalVIPPerson NULL, @pAgentCodeIn, 'U';

                    -- Old: wVIPPersonStatus --> 檢查是生成、T掉生日記錄，或者什麽也不做
                    -- Old: util.RecalVIPPerson默認送禮，@pAgentCodeIn有效值、NULL、空值，生成客戶生日eBirthday（空值 --> 指定授權人@sVIPPersonRid，非空 --> 戶口指定授權人@pAgentCodeIn and @sVIPPersonRid)
                    -- New: util.RecalVIPPerson默認不送禮，新增VIP客戶資料不影響生日eBirthday，所以此處@pAgentCodeIn='Y'（任意非空的無效值，不做任何操作）
                    SET @sYear = YEAR(@sNow);
                    EXEC util.RecalVIPPersonBirthday @sYear, 'N', @sVIPPersonRid, 'Y';
                END
            END
            -- 戶口、戶口代理跟進
            ELSE IF @sAgentType = 'AGENT'
            BEGIN
                -- 如果是戶口，則新增戶口下所有授權人
                EXEC util.RecalVIPPerson @pAgentCodeIn, NULL, 'I';

                -- 新加的授權人不會直接生成生日記錄，後面Call RecalVIPPersonBirthday只需要Update跟進
                SET @sYear = YEAR(@sNow);
                EXEC util.RecalVIPPersonBirthday @sYear, 'Y', @sVIPPersonRid, @pAgentCodeIn;

            END
        END
    END