
-- 2019-04-28改：
-- Old：
-- Send SMS 
-- 客人取消（3）--> 通知MD、VIP部門訂單跟進人 --> SetDeptResponseRoom
-- 客人取消（2）--> RollsMary界面 --> SetSMSDeptResponseRoom、SunPeople --> SUNCRM_SetDeptRoomResponse
-- 訂單完成 --> ActionBookingHotel --> SetSMSDeptResponseRoom
-- New: 
-- 客人取消（3）、客人取消（2）、訂單完成 --> SetDeptResponseRoom
CREATE PROCEDURE [spa].[SetSMSDeptResponseRoom]
    @pDeptRespRoomRid   BIGINT,
    @pMainCompNo        INT ,
    @pErrCode           INT = 0 OUTPUT ,
    @pErrMsg            NVARCHAR(200) = '' OUTPUT 
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sBeginTranCount INT = 0;

        ----------------------------------------------------------------------------------
        -- @pMainCompNo為空，先取最後修改人的wCompNo，如果沒有，就取default值
        IF ISNULL(@pMainCompNo, 0) <= 0
        BEGIN
            SELECT @pMainCompNo = mu.wCompNo 
            FROM dbo.eDeptRespRoom drr 
            INNER JOIN RollsMary.dbo.mUsr mu ON mu.RowID = drr.wUpdBy
            WHERE drr.RowID = @pDeptRespRoomRid;
        END;

        IF ISNULL(@pMainCompNo, 0) <= 0
        BEGIN
            SET @pMainCompNo = RollsMary.dbo.fnGetMainCompNo(NULL, 'mac01');
        END;
        ----------------------------------------------------------------------------------

        SET @sBeginTranCount = @@trancount;
        BEGIN TRY
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;

            IF EXISTS (SELECT 1 FROM dbo.eDeptRespRoom WHERE RowID = @pDeptRespRoomRid AND (wDeptStatus = 'CL2' OR wDeptStatus = 'CL3' OR (wDeptStatus = 'CS_AH' AND wRepStatus = 'C')))
            BEGIN
                EXEC RollsMary.spa.SetQueProcsDeptRespRoomSMS @pDeptRespRoomRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;

                IF NULLIF(@pErrMsg, '') IS NOT NULL OR ISNULL(@pErrCode, 0) > 0
                    THROW @pErrCode, @pErrMsg, 1;
            END;

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
			
            IF ISNULL(@pErrCode, 0) = 0
            BEGIN
                SET @pErrCode = 999;
            END;
            
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ', @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0 AND ( @xstate = 1 OR @xstate = -1 )
            BEGIN
                ROLLBACK;
            END
            ELSE 
                THROW;
	        
            -- Write Log
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH;
    END;