CREATE PROCEDURE [spa].[ActionBookingRestaurant]
    @pXMLBooking XML ,
    @pXMLBookingRestaurant XML ,
    @pActionType CHAR(1) ,
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pBookingRid BIGINT = 0 ,
    @pBookingRidOut BIGINT = 0 OUTPUT ,
    @pBookingRestaurantId BIGINT = 0 OUTPUT ,
    @pRefNo VARCHAR(30) = '' OUTPUT ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
AS
    BEGIN
 
        SET NOCOUNT ON;

--SELECT RowID,wBookingRid FROM dbo.eBookingRestaurant where wBookingRid = @pBookingRid

        DECLARE @sBeginTranCount INT = 0;

        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';

        BEGIN TRY

            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF @pXMLBooking IS NOT NULL
                EXEC [spa].[SetBooking] @pXMLBooking, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT; 
    
            IF @pXMLBookingRestaurant IS NOT NULL
                EXEC [spa].[SetBookingRestaurant] @pXMLBookingRestaurant, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pBookingRestaurantId OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;
    
            --【Calendar】-->【Mary】
            IF @pBookingRid IS NOT NULL AND @pBookingRid > 0 BEGIN
                EXEC util.WriteMaryAgentActivitiesApiLog @pBookingRid = @pBookingRid, @pBookingType = 'RESTAURANT';
            END;	

            SET @pBookingRidOut = @pBookingRid;
    
            SELECT TOP 1
                    @pRefNo = wRefNo
            FROM    dbo.eBooking
            WHERE   RowID = @pBookingRid;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

            RETURN;
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

            IF @sBeginTranCount = 0
                AND ( @xstate = 1
                      OR @xstate = -1
                    )
                BEGIN
        -- transaction created within this sp
                    ROLLBACK;
                END;

         -- Write Log
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH;		
    END;