
CREATE PROCEDURE [spa].[SetVIPPersonShip]
    @pXML XML ,      
    @pVIPPersonRid BIGINT,
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sThisTableName VARCHAR(50) = 'eVIPPersonShip' ,
                @sBeginTranCount	INT = 0 ,
                @sDocHandle			INT,
                @sRecCount			INT = 0,
                @sRuningIndex		INT = 1,
                @sNow				DATETIME2 = dbo.fnUTC8Now();
        
        SET @sBeginTranCount = @@trancount;
        SET @pErrCode = 0;
        SET @pErrMsg = '';
        SET @pVIPPersonRid = ISNULL(IIF(@pVIPPersonRid < 0, NULL, @pVIPPersonRid), 0);
    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ),
                *
        INTO    #sDataSet_SetVIPPersonShip
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
        WITH (
            wVIPPersonRid BIGINT,
            wVIPPersonRefRid BIGINT,
            wIsBirthday CHAR(1), -- 是否生成生日記錄(wVIPPersonRid == wVIPPersonRefRid)
            wUpdBy BIGINT,
            wUpdDt DATETIME2(7)
        );
        
        EXEC sp_xml_removedocument @sDocHandle;  

        BEGIN TRY	                
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;
        	
            ------------------------ Checking -----------------------------
            SET @sRecCount = (SELECT COUNT(1) FROM #sDataSet_SetVIPPersonShip);
            IF NULLIF(@pErrMsg, '') IS NULL AND @sRecCount = 0
            BEGIN
                SET @pErrMsg = N'VIP客戶至少指定一個相關戶口';
            END;

            IF NULLIF(@pErrMsg, '') IS NULL AND @pVIPPersonRid = 0
            BEGIN
                SET @pErrMsg = N'相關戶口沒有指定VIP客戶。';
            END;

            IF NULLIF(@pErrMsg, '') IS NOT NULL
                THROW 50001, @pErrMsg, 1;
            -----------------------End Checking ---------------------------
            
            DECLARE @sVIPPersonRid BIGINT,
                    @sVIPPersonRefRid BIGINT,
                    @sIsBirthday CHAR(1), -- 是否生成生日記錄(wVIPPersonRid == wVIPPersonRefRid)
                    @sUpdBy BIGINT,
                    @sUpdDt DATETIME2(7);

            -- 刪除原來的關聯戶口
            DELETE FROM dbo.eVIPPersonShip WHERE wVIPPersonRid = @pVIPPersonRid OR wVIPPersonRefRid = @pVIPPersonRid;

            -- 把所有相關戶口為0的關聯到自己
            UPDATE #sDataSet_SetVIPPersonShip
            SET wVIPPersonRefRid = @pVIPPersonRid 
            WHERE ISNULL(wVIPPersonRefRid, 0) <= 0;

            -- 更新
            SET @sRecCount = (SELECT COUNT(1) FROM #sDataSet_SetVIPPersonShip);
            SET @sRuningIndex = 1;

            WHILE @sRuningIndex <= @sRecCount
            BEGIN
                SELECT @sVIPPersonRid = @pVIPPersonRid,
                       @sVIPPersonRefRid = wVIPPersonRefRid,
                       @sIsBirthday = 'N',
                       @sUpdBy = wUpdBy,
                       @sUpdDt = @sNow
                FROM #sDataSet_SetVIPPersonShip
                WHERE wRowNum = @sRuningIndex;

                -- 當前客戶關聯到其他客戶
                IF NOT EXISTS (SELECT 1 FROM dbo.eVIPPersonShip WHERE wVIPPersonRid = @sVIPPersonRid AND wVIPPersonRefRid = @sVIPPersonRefRid )
                BEGIN
                    INSERT INTO dbo.eVIPPersonShip(
                        wVIPPersonRid,
                        wVIPPersonRefRid,
                        wIsBirthday, -- 是否生成生日記錄(wVIPPersonRid == wVIPPersonRefRid)
                        wUpdBy,
                        wUpdDt
                    ) VALUES (
                        @sVIPPersonRid,
                        @sVIPPersonRefRid,
                        @sIsBirthday,
                        @sUpdBy,
                        @sUpdDt
                    );
                END;

                -- 其他客戶關聯到當前客戶
                IF NOT EXISTS (SELECT 1 FROM dbo.eVIPPersonShip WHERE wVIPPersonRid = @sVIPPersonRefRid AND wVIPPersonRefRid = @sVIPPersonRid)
                BEGIN
                    INSERT INTO dbo.eVIPPersonShip(
                        wVIPPersonRid,
                        wVIPPersonRefRid,
                        wIsBirthday, -- 是否生成生日記錄(wVIPPersonRid == wVIPPersonRefRid)
                        wUpdBy,
                        wUpdDt
                    ) VALUES (
                        @sVIPPersonRefRid,
                        @sVIPPersonRid,
                        @sIsBirthday,
                        @sUpdBy,
                        @sUpdDt
                    );
                END;

                SET @sRuningIndex = @sRuningIndex + 1;
            END;

            -- 是否生成生日記錄(wVIPPersonRid == wVIPPersonRefRid)
            UPDATE ps
            SET ps.wIsBirthday = eps.wIsBirthday
            FROM dbo.eVIPPersonShip ps
            INNER JOIN #sDataSet_SetVIPPersonShip eps ON eps.wVIPPersonRefRid = ps.wVIPPersonRid
            WHERE ps.wVIPPersonRid = ps.wVIPPersonRefRid;
            
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
        
            SET @sErrorNum = ERROR_NUMBER();
            SET @pErrCode = ERROR_NUMBER();
            SET @sCatchErrorMessage = ERROR_MESSAGE();
            SET @xstate = XACT_STATE();
            SET @sProcedureName = OBJECT_NAME(@@PROCID);
		
            IF ISNULL(@pErrCode, 0) = 0
            BEGIN
                SET @pErrCode = 70001;
            END;

            SET @pErrMsg = CONCAT('(', @sErrorNum, ') ', @sCatchErrorMessage);

            IF @sBeginTranCount = 0
            BEGIN
                IF @xstate != 0
                    ROLLBACK;

                -- Write Log
                EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
            END;
            ELSE
                THROW;           
        END CATCH;
        
        IF OBJECT_ID('tempdb..#sDataSet_SetVIPPersonShip') IS NOT NULL
            DROP TABLE #sDataSet_SetVIPPersonShip;

    END;