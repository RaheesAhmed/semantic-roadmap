CREATE PROCEDURE [spa].[ActionClientSettings] 
    @pXML XML ,      
    @pActionType CHAR(1) , 
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pPersonRid bigint = 0,
    @pPersonOutRid bigint = 0 OUTPUT,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    --Select Count(*) as wRecordCount  from mPerson;

    DECLARE @sBeginTranCount INT = 0	
     
    SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';

     BEGIN TRY
            -- Try to make the transaction scope as small as possible to reduce locking
    
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

                --DECLARE @pwPersonRid BigINT = 0
                
                EXEC [spa].[SetClientInfo] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pPersonRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT; 	 													      
                EXEC [spa].[SetClientTravelDocInfo] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pPersonRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;
                EXEC [spa].[SetPersonMemberCard] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pPersonRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;
                EXEC [spa].[SetPersonPreference] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pPersonRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;
                EXEC [spa].[SetPersonRelationship] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pPersonRid, @pErrCode OUTPUT, @pErrMsg OUTPUT;

                SET @pPersonOutRid = @pPersonRid;
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;		
                END;
                    
            RETURN ;
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

END