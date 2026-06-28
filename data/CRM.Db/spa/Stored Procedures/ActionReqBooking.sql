/*
--------------------------------------------------------------------------
DECLARE @pErrCode INT,
        @pErrMsg NVARCHAR(200);

EXEC spa.ActionReqBooking @pXML = N'<DataSet>
<Record RowID="10000000010000" wGUID="DE741F72-24B7-4D7D-A623-8733FCC3B028" wBookingType="HOTEL" wAgentCodeIn="1000010180" wReqDeptCd="DEVELOP" wReqUserRid="1000000251" wReqStatus="C" wUpdBy="1000000251" RecordState="I">
<Detail RowID="10000000010000" wGUID="C27E616C-6CDA-4397-A692-871DCAF4F007" wHotelRid="10000000001030" wHotelRoomRid="0" wCheckInDate="2019-05-14" wCheckOutDate="2019-05-16" wBigBedRoomQty="1" wTwinBedRoomQty="2" wSuiteRoom1Qty="0" wSuiteRoom2Qty="0" wSuiteRoom3Qty="0" wRemark="訂務需求，房間"></Detail></Record></DataSet>',
                          @pMainCompNo = 10,
                          @pReturnResult = 'Y',
                          @pTestMode = 0,
                          @pErrCode = @pErrCode OUTPUT,
                          @pErrMsg = @pErrMsg OUTPUT;

SELECT @pErrCode, @pErrMsg;
--------------------------------------------------------------------------
*/
CREATE PROC [spa].[ActionReqBooking]
    @pXML           XML,
    @pMainCompNo    INT,
    @pReturnResult  CHAR(1),
    @pTestMode      INT,
    @pErrCode       INT OUTPUT,
    @pErrMsg        NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;
        
        -- dbml
        ------------------------------------
        --DECLARE @vResult TABLE(RowID BIGINT NOT NULL);
        --SELECT * FROM @vResult;
        ------------------------------------

        DECLARE @sBeginTranCount    INT = 0 ,
                @sRecCount          INT = 0 ,
                @sRuningIndex       INT = 1 ,
                @sErrCode           INT,
                @sErrMsg            NVARCHAR(200);

        CREATE TABLE #vDataSet (
            RowNum          INT IDENTITY(1, 1),
            RowID           BIGINT NOT NULL DEFAULT(0),
            ReqBookingXML   XML
        );
        
        INSERT INTO #vDataSet (ReqBookingXML)
        SELECT ReqBookingXML = T.tmp.query('.')
        FROM @pXML.nodes('DataSet/Record') T(tmp);

        SET @pErrCode = 0;
        SET @pErrMsg  = '';
        SET @sBeginTranCount = @@TRANCOUNT;
        
        BEGIN TRY
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END

            -- Checking
            ----------------------------------------------------------------------------------
            IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM #vDataSet WHERE ReqBookingXML.query('count(/Record/Detail)').value('.', 'INT') = 0)
                SET @sErrMsg = N'Record detail is missing';

            IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM #vDataSet WHERE ReqBookingXML.query('count(/Record/Detail)').value('.', 'INT') > 1)
                SET @sErrMsg = N'Multiple record detail';

            IF @sErrMsg IS NULL AND EXISTS (SELECT 1 FROM #vDataSet WHERE ReqBookingXML.query('count(/Record[@wUpdBy>0])').value('.', 'INT') = 0)
                SET @sErrMsg = N'UpdBy is invalid';

            IF @sErrMsg IS NOT NULL
                THROW 50001, @sErrMsg, 1;

            -- set different booking request(e.g HOTEL, FERRY)
            ----------------------------------------------------------------------------------
            DECLARE @sReqBookingRid BIGINT,
                    @sBookingType   VARCHAR(30),
                    @sReqBookingXML XML;

            SET @sRuningIndex = 1;
            SET @sRecCount = (SELECT COUNT(1) FROM #vDataSet);
            
            -- Multiple Booking Request
            WHILE @sRuningIndex <= @sRecCount
            BEGIN
                SELECT  @sBookingType   = ReqBookingXML.value('(/Record/@wBookingType)[1]',  'VARCHAR(30)'),
                        @sReqBookingXML = ReqBookingXML
                FROM #vDataSet
                WHERE RowNum = @sRuningIndex;

                -- 酒店訂務需求
                IF @sBookingType = 'HOTEL'
                BEGIN
                    EXEC spa.ActionReqBookingHotel @pXML            = @sReqBookingXML,
                                                   @pMainCompNo     = @pMainCompNo,
                                                   @pTestMode       = @pTestMode,
                                                   @pReqBookingRid  = @sReqBookingRid OUTPUT,
                                                   @pErrCode        = @sErrCode OUTPUT,
                                                   @pErrMsg         = @sErrMsg OUTPUT;
                END
                ELSE IF @sBookingType = '' OR @sBookingType IS NULL
                BEGIN
                    SET @sErrCode = 50001;
                    SET @sErrMsg = N'Booking Type is null or empty.';
                END
                ELSE
                BEGIN
                    SET @sErrCode = 50001;
                    SET @sErrMsg = CONCAT(N'Unsupported Booking Type - ', @sBookingType);
                END

                -- result
                ------------------------------------------------------------------------------
                IF NULLIF(@sErrMsg, '') IS NOT NULL
                BEGIN
                    SET @sErrCode = ISNULL(@sErrCode, 70001);
                    THROW @sErrCode, @sErrMsg, 1;
                END
                
                -- return dbo.eReqBooking.[RowID]
                IF @pReturnResult = 'Y' AND ISNULL(@sReqBookingRid, 0) > 0 
                    UPDATE #vDataSet SET RowID = @sReqBookingRid WHERE RowNum = @sRuningIndex;
                    
                SET @sRuningIndex = @sRuningIndex + 1;
            END

            ----------------------------------------------------------------------------------
            IF @sBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                IF @pTestMode = 1
                    ROLLBACK TRAN;
                ELSE
                    COMMIT TRAN;
            END;

            -- return result
            ----------------------------------------------------------------------------------
            IF @pReturnResult = 'Y'
                SELECT RowID FROM #vDataSet;
        END TRY
        BEGIN CATCH
            DECLARE @xstate INT ,
                    @sProcedureName VARCHAR(100) ,
                    @sCatchErrorCode INT ,
                    @sCatchErrorMessage NVARCHAR(4000) ,
                    @sRtnCodeLog INT ,
                    @sErrMessageLog NVARCHAR(4000);
	        
            SET @xstate             = XACT_STATE();
            SET @sProcedureName     = OBJECT_NAME(@@PROCID);
            SET @sCatchErrorCode    = ERROR_NUMBER();
            SET @sCatchErrorMessage = ERROR_MESSAGE();
            
            SET @pErrCode = IIF(ISNULL(@pErrCode, 0) = 0, @sCatchErrorCode, @pErrCode);
            SET @pErrMsg = CONCAT(IIF(ISNULL(@pErrMsg, '') = '', '', @pErrMsg + CHAR(10)), '(', @sCatchErrorCode, ') ', @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0 AND ( @xstate = 1 OR @xstate = -1 )
            BEGIN
                ROLLBACK TRAN;
            END
            ELSE
                THROW;
	        
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH
        
        IF OBJECT_ID('tempdb..#vDataSet') IS NOT NULL
            DROP TABLE #vDataSet;
    END