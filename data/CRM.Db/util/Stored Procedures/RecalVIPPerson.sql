
CREATE PROC [util].[RecalVIPPerson]
    @pAgentCodeIn           VARCHAR(14) = '', -- 戶口
    @pAuthorizerAgentCodeIn VARCHAR(14) = '', -- 授權人
    @pActionType            CHAR(1)     = 'I' -- I/U
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sVIPPersonRid      BIGINT,
                @sBeginTranCount    INT,
                @sErrCode           INT,
                @sErrMsg            NVARCHAR(200),
                @sNow               DATETIME2(7) = GETDATE();

        SET @sBeginTranCount = @@trancount;

        BEGIN TRY
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;

            SET @pAgentCodeIn           = NULLIF(@pAgentCodeIn, '');
            SET @pAuthorizerAgentCodeIn = NULLIF(@pAuthorizerAgentCodeIn, '');
            SET @sVIPPersonRid          = 0;

            -----------------------------------------------------------授權人-------------------------------------------------------------------
            -- 導入RollsMary.dbo.mAgent的wType='AUTH'到VIP客戶資料
            -- @pAgentCodeIn  = NULL， @pAuthorizerAgentCodeIn  = NULL，Insert OR Update 所有授權人到dbo.mVIPPerosn
            -- @pAgentCodeIn  = NULL， @pAuthorizerAgentCodeIn <> NULL，Insert OR Update 指定授權人到dbo.mVIPPerosn
            -- @pAgentCodeIn <> NULL， @pAuthorizerAgentCodeIn  = NULL，Insert OR Update 指定戶口下所有授權人到dbo.mVIPPerosn
            -- @pAgentCodeIn <> NULL， @pAuthorizerAgentCodeIn <> NULL，Insert OR Update 指定戶口下指定授權人到dbo.mVIPPerosn
            EXEC util.RecalVIPPersonForAuthorizer @pAgentCodeIn, @pAuthorizerAgentCodeIn, @pActionType;
            ---------------------------------------------------------END 授權人-----------------------------------------------------------------
            
            ------------------------------------------------------------戶口--------------------------------------------------------------------
            -- OP#22764，除了戶口的授權人外，系統亦同時需要取戶口的資料，導入VIP客戶管理
            -- 戶口為空，授權人不為空，獲取授權人戶口
            -- 戶口不為空，授權人值無效
            IF @pAgentCodeIn IS NULL AND @pAuthorizerAgentCodeIn IS NOT NULL
            BEGIN
                SET @pAgentCodeIn = (SELECT TOP 1 wUpLvlAgentCodeIn FROM RollsMary.dbo.mAgent WHERE wStatus = 'A' AND wType = 'AUTH' AND  wAgentCodeIn = @pAuthorizerAgentCodeIn);
                SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
            END;
            
            -- 如果戶口不是空，檢查戶口是否已經Insert到mVIPPerson
            IF @pAgentCodeIn IS NOT NULL
            BEGIN
                -- 戶口是否已經加入到VIP客戶資料
                -- NULL, 戶口不存在，不作任何操作
                -- > 0 , 資料已存在，更新客戶資料
                -- = 0 , 資料不存在，新增客戶資料
                SET @sVIPPersonRid = (
                    SELECT TOP(1) ISNULL(mp.RowID, 0) 
                    FROM RollsMary.dbo.mAgent ma
                    LEFT JOIN dbo.mVIPPerson mp ON mp.wAgentCodeIn = ma.wAgentCodeIn AND mp.wAuthorizerAgentCodeIn = ma.wAgentCodeIn AND mp.wIsAuthorizer = 'Y' AND mp.wStatus = 'A'
                    WHERE ma.wAgentCodeIn = @pAgentCodeIn
                );
            END;

            -- 授權人不為空，但是卻沒有授權人戶口，此時應該什麽也不做
            IF @pAgentCodeIn IS NULL AND @pAuthorizerAgentCodeIn IS NOT NULL
            BEGIN
                SET @sVIPPersonRid = NULL;
            END;
            
            -- @sVIPPersonRid = NULL，什麽也不做（戶口或者授權人、戶口不存在）
            -- @sVIPPersonRid = 0，戶口沒有加入到VIP客戶資料，則Insert
            -- @sVIPPersonRid > 0，戶口已加入到VIP客戶資料，則Update
            IF @sVIPPersonRid = 0
            BEGIN
                -- 導入RollsMary.dbo.mAgent的wType='AGENT'到VIP客戶資料
                -- @pAgentCodeIn  = NULL， Insert所有戶口到dbo.mVIPPerosn
                -- @pAgentCodeIn <> NULL， Insert指定戶口到dbo.mVIPPerosn
                EXEC util.RecalVIPPersonForAgent @pAgentCodeIn, 'I';
            END
            --ELSE IF @sVIPPersonRid > 0
            --BEGIN
            --    -- 導入RollsMary.dbo.mAgent的wType='AGENT'到VIP客戶資料
            --    -- @pAgentCodeIn  = NULL， Update所有戶口到dbo.mVIPPerosn
            --    -- @pAgentCodeIn <> NULL， Update指定戶口到dbo.mVIPPerosn
            --    EXEC util.RecalVIPPersonForAgent @pAgentCodeIn, 'U';
            --END
            
            -- 2018-12-12：更新戶口或者T掉戶口下的授權人（沒有VIP、MD跟進）
            IF @pAgentCodeIn IS NOT NULL
                EXEC util.RecalVIPPersonForAgent @pAgentCodeIn, 'U';
            ----------------------------------------------------------END 戶口------------------------------------------------------------------

            IF @sBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                COMMIT;
            END;

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
			
            IF ISNULL(@sErrCode, 0) = 0
                SET @sErrCode = 70001;

            IF NULLIF(@sErrMsg, '') IS NULL
                SET @sErrMsg = CONCAT('(', @sErrorNum, ') ', @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0
            BEGIN
                IF @xstate != 0
                    ROLLBACK;

                -- Write Log
                EXEC spa.WriteErrorLog 99, 99, @sProcedureName, @sErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
            END
            ELSE
                THROW @sErrCode, @sErrMsg, 1;  

        END CATCH;
    END;