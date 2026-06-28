-- R#57815
CREATE PROC [util].[RecalComplaintRequestActionLog]
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sBeginTranCount INT = 0;

        DECLARE @pErrCode INT,
                @pErrMsg NVARCHAR(200);

        DECLARE @vXML XML;

        SET @sBeginTranCount = @@trancount;

        BEGIN TRY
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;

            IF NULLIF(@pErrMsg, '') IS NULL
            BEGIN
                SET @vXML = (SELECT RowID FROM dbo.eAdvice FOR XML RAW('Record'), ROOT('DataSet'))
            
                EXEC spa.SetAdviceChange @pAdviceXML     = @vXML,
                                         @pSendSunPeople = 'N',
                                         @pErrCode       = @pErrCode OUTPUT,
                                         @pErrMsg        = @pErrMsg OUTPUT;
            END
            
            IF NULLIF(@pErrMsg, '') IS NULL
            BEGIN
                SET @vXML = (SELECT RowID FROM dbo.eComplaint FOR XML RAW('Record'), ROOT('DataSet'))

                EXEC spa.SetComplaintChange @pComplaintXML  = @vXML,
                                            @pSendSunPeople = 'N', 
                                            @pErrCode       = @pErrCode OUTPUT,
                                            @pErrMsg        = @pErrMsg OUTPUT;
            END

            IF NULLIF(@pErrMsg, '') IS NOT NULL
                PRINT @pErrMsg;

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
			
            PRINT @pErrMsg;
            PRINT @sProcedureName;
            PRINT @sCatchErrorMessage;
			
            IF @sBeginTranCount = 0 AND ( @xstate = 1 OR @xstate = -1 )
                ROLLBACK;

        END CATCH
    END