CREATE PROCEDURE [spa].[ActionBookingHotel]
    @pXMLBooking        XML ,
    @pXMLBookingHotel   XML ,
    @pActionType        CHAR(1) ,
    @pMainCompNo        INT ,
    @pNonceToken        VARCHAR(64) ,
    @pBookingRid        BIGINT = 0 OUTPUT,
    @pHotelBookingRid   BIGINT = 0 OUTPUT ,
    @pErrCode           INT = 0 OUTPUT ,
    @pErrMsg            NVARCHAR(200) = '' OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sBeginTranCount INT = 0;	

	-- Select count(*) wRecordCount From eBookingHotel
	 
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';

        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
	
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;			
			
            IF @pXMLBooking IS NOT NULL
                EXEC [spa].[SetBooking] @pXMLBooking, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT; 													      
			
            IF @pXMLBookingHotel IS NOT NULL
                EXEC [spa].[SetBookingHotel] @pXMLBookingHotel, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pHotelBookingRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT; 			    			 

            --EXEC [spa].[SetActivityLog] @pXML, @pActionType, @pMainCompNo, @pNonceToken, 'N', @pBookingRid, @pErrCode OUTPUT, @pErrMsg OUTPUT; 
				
            -- 2019-04-28：Update 酒店部門訂房eDeptRespRoom.wBookingRid
            -------------------------------------------------------------------------------------------------------
            IF NULLIF(@pErrMsg, '') IS NULL AND @pXMLBookingHotel IS NOT NULL AND @pActionType = 'I'
            BEGIN
               DECLARE @vXML XML;

               SET @vXML = (
                   SELECT tmp.RowID,
                          wBookingRid = @pBookingRid
                   FROM (
                        SELECT RowID = T.tmp.value('@wDeptRespRoomRid', 'BIGINT')
                        FROM @pXMLBookingHotel.nodes('DataSet/Record') T(tmp)
                    ) tmp WHERE tmp.RowID > 0
                    GROUP BY tmp.RowID
                    FOR XML RAW('Record'), ROOT('DataSet')
                );

                EXEC spa.SetDeptRoomBookingHotel @pXML        = @vXML,
                                                 @pMainCompNo = @pMainCompNo,
                                                 @pErrCode    = @pErrCode OUTPUT,
                                                 @pErrMsg     = @pErrMsg OUTPUT;
            END;
            -------------------------------------------------------------------------------------------------------

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