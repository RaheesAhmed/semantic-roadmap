-- Only one record per time
CREATE PROC [spa].[ActionReqBookingHotel]
    @pXML           XML,
    @pMainCompNo    INT,
    @pTestMode      INT,
    @pReqBookingRid BIGINT OUTPUT,
    @pErrCode       INT OUTPUT,
    @pErrMsg        NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sBeginTranCount    INT = 0 ,
                @sErrCode           INT,
                @sErrMsg            NVARCHAR(200);
        
        DECLARE @vXML                   XML,
                @vReqBookingXML         XML,
                @vReqBookingHotelXML    XML;

        -- 重組XML結構
        --------------------------------------------------------------------------------------------------
        -- dbo.eReqBookingHotel(轉<DataSet><Record ... /></DataSet>)
        SET @vReqBookingHotelXML = CONCAT('<DataSet>', REPLACE(CONVERT(NVARCHAR(MAX), @pXML.query('(/Record/Detail)[1]')), '<Detail', '<Record'), '</DataSet>');
        -- 刪除detail節點
        SET @pXML.modify('delete (/Record/Detail)')
        -- dbo.eReqBooking(轉<DataSet><Record ... /></DataSet>)
        SET @vReqBookingXML = CONCAT('<DataSet>', CONVERT(NVARCHAR(MAX), @pXML), '</DataSet>');

        -- 批核、拒絕，直接Get一次db的data
        --------------------------------------------------------------------------------------------------
        -- dbo.eReqBooking
        SET @vXML = (
            SELECT tmp.RowID,
                   tmp.wGUID,
                   tmp.wBookingType,
                   wAgentCodeIn = ISNULL(NULLIF(tmp.wAgentCodeIn, ''), rb.wAgentCodeIn),
                   wReqDeptCd   = rb.wReqDeptCd, --ISNULL(NULLIF(tmp.wReqDeptCd, ''), rb.wReqDeptCd),
                   wReqUserRid  = rb.wReqUserRid, --ISNULL(NULLIF(tmp.wReqUserRid, 0), rb.wReqUserRid),
                   tmp.wReqStatus,
                   tmp.wUpdBy,
                   tmp.RecordState
            FROM (
                SELECT  RowID           = T.tmp.value('@RowID',             'BIGINT'),
	                    wGUID           = T.tmp.value('@wGUID',             'VARCHAR(36)'),
	                    wBookingType    = T.tmp.value('@wBookingType',      'VARCHAR(30)'),
	                    wAgentCodeIn    = T.tmp.value('@wAgentCodeIn',      'VARCHAR(14)'),
	                    wReqDeptCd      = T.tmp.value('@wReqDeptCd',        'VARCHAR(30)'),
	                    wReqUserRid     = T.tmp.value('@wReqUserRid',       'BIGINT'),
	                    wReqStatus      = T.tmp.value('@wReqStatus',        'VARCHAR(10)'),
	                    wUpdBy          = T.tmp.value('@wUpdBy',            'BIGINT'),
                        RecordState     = T.tmp.value('@RecordState',       'CHAR(1)')
                FROM @vReqBookingXML.nodes('DataSet/Record') T(tmp)
            ) tmp
            INNER JOIN dbo.eReqBooking rb WITH(NOLOCK) ON rb.RowID = tmp.RowID
            WHERE tmp.RecordState = 'D' -- 刪除
                OR ( tmp.RecordState = 'U' AND ( (rb.wReqStatus = 'TP' AND tmp.wReqStatus = 'RJ') -- 拒絕派房
                                              OR (rb.wReqStatus = 'TP' AND tmp.wReqStatus = 'P' AND rb.wRefRid <= 0)  -- 確認派房，在部門酒店訂房生成一條記錄
                                           )
                )
            FOR XML RAW('Record'), ROOT('DataSet')
        );
        SET @vReqBookingXML = ISNULL(@vXML, @vReqBookingXML);
        
        -- dbo.eReqBookingHotel
        SET @vXML = (
            SELECT  tmp.RowID,
                    tmp.wGUID,
                    wHotelRid       = ISNULL(NULLIF(tmp.wHotelRid, 0), rbh.wHotelRid),
                    wHotelRoomRid   = ISNULL(NULLIF(tmp.wHotelRoomRid, 0), rbh.wHotelRoomRid),
                    wCheckInDate    = ISNULL(NULLIF(tmp.wCheckInDate, ''), rbh.wCheckInDate),
                    wCheckOutDate   = ISNULL(NULLIF(tmp.wCheckOutDate, ''), rbh.wCheckOutDate),
                    wBigBedRoomQty  = ISNULL(NULLIF(tmp.wBigBedRoomQty, 0), rbh.wBigBedRoomQty),
                    wTwinBedRoomQty = ISNULL(NULLIF(tmp.wTwinBedRoomQty, 0), rbh.wTwinBedRoomQty),
                    wSuiteRoom1Qty  = ISNULL(NULLIF(tmp.wSuiteRoom1Qty, 0), rbh.wSuiteRoom1Qty),
                    wSuiteRoom2Qty  = ISNULL(NULLIF(tmp.wSuiteRoom2Qty, 0), rbh.wSuiteRoom2Qty),
                    wSuiteRoom3Qty  = ISNULL(NULLIF(tmp.wSuiteRoom3Qty, 0), rbh.wSuiteRoom3Qty),
                    wRemark         = ISNULL(NULLIF(tmp.wRemark, ''), rbh.wRemark)
            FROM (
                SELECT  RowID               = T.tmp.value('@RowID',             'BIGINT'),
	                    wGUID               = T.tmp.value('@wGUID',             'VARCHAR(36)'),
	                    wHotelRid           = T.tmp.value('@wHotelRid',         'BIGINT'),
	                    wHotelRoomRid       = T.tmp.value('@wHotelRoomRid',     'BIGINT'),
	                    wCheckInDate        = T.tmp.value('@wCheckInDate',      'VARCHAR(20)'),
	                    wCheckOutDate       = T.tmp.value('@wCheckOutDate',     'VARCHAR(20)'),
	                    wBigBedRoomQty      = T.tmp.value('@wBigBedRoomQty',    'INT'),
	                    wTwinBedRoomQty     = T.tmp.value('@wTwinBedRoomQty',   'INT'),
	                    wSuiteRoom1Qty      = T.tmp.value('@wSuiteRoom1Qty',    'INT'),
	                    wSuiteRoom2Qty      = T.tmp.value('@wSuiteRoom2Qty',    'INT'),
	                    wSuiteRoom3Qty      = T.tmp.value('@wSuiteRoom3Qty',    'INT'),
	                    wRemark             = T.tmp.value('@wRemark',           'NVARCHAR(4000)')
                FROM @vReqBookingHotelXML.nodes('DataSet/Record') T(tmp)
            ) tmp
            INNER JOIN dbo.eReqBookingHotel rbh WITH(NOLOCK) ON rbh.RowID = tmp.RowID
            INNER JOIN dbo.eReqBooking rb WITH(NOLOCK) ON rb.RowID = rbh.wReqBookingRid
            INNER JOIN (
                SELECT  RowID           = T.tmp.value('@RowID',             'BIGINT'),
	                    wReqStatus      = T.tmp.value('@wReqStatus',        'VARCHAR(10)'),
                        RecordState     = T.tmp.value('@RecordState',       'CHAR(1)')
                FROM @vReqBookingXML.nodes('DataSet/Record') T(tmp)
            ) tmp_rb ON tmp_rb.RowID = rb.RowID
            WHERE tmp_rb.RecordState = 'D' -- 刪除
                OR (tmp_rb.RecordState = 'U' AND ( (rb.wReqStatus = 'TP' AND tmp_rb.wReqStatus = 'RJ') -- 拒絕派房
                                                OR (rb.wReqStatus = 'TP' AND tmp_rb.wReqStatus = 'P' AND rb.wRefRid <= 0)  -- 確認派房，在部門酒店訂房生成一條記錄
                                            )
                )
            FOR XML RAW('Record'), ROOT('DataSet')
        );
        SET @vReqBookingHotelXML = ISNULL(@vXML, @vReqBookingHotelXML); 
        --------------------------------------------------------------------------------------------------
        
        -- INSERT/UPDATE/DELETE
        --------------------------------------------------------------------------------------------------
        SET @pErrCode = 0;
        SET @pErrMsg  = '';
        SET @sBeginTranCount = @@TRANCOUNT;

        BEGIN TRY
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END

            DECLARE @sRefTable      VARCHAR(50),
                    @sRefRid        BIGINT,
                    @sRefNo         VARCHAR(50),
                    @sRecordState   CHAR(1),
                    @sUpdBy         BIGINT;
            
            -- SET wReqBooking.wReqStatus Change
            -- INSERT dbo.eDeptReqRoom
            --------------------------------------------------------------------------------------------------
            IF @sErrMsg = '' OR @sErrMsg IS NULL
            BEGIN
                EXEC spa.SetReqBookingHotelChange @pReqBookingXML       = @vReqBookingXML,
                                                  @pReqBookingHotelXML  = @vReqBookingHotelXML,
                                                  @pMainCompNo          = @pMainCompNo,
                                                  @pRefTable            = @sRefTable OUTPUT,
                                                  @pRefRid              = @sRefRid OUTPUT,
                                                  @pRefNo               = @sRefNo OUTPUT,
                                                  @pErrCode             = @sErrCode OUTPUT,
                                                  @pErrMsg              = @sErrMsg OUTPUT;
            END
            
            -- INSERT/UPDATE/DELETE dbo.eReqBooking
            --------------------------------------------------------------------------------------------------
            IF @sErrMsg = '' OR @sErrMsg IS NULL
            BEGIN
                -- 修正@vReqBookingXML.wReqStatus
                -- 修正@vReqBookingXML.wRefTable
                -- 修正@vReqBookingXML.wRefRid
                -- 修正@vReqBookingXML.wRefNo
                --------------------------------------------------------------------------------------------------
                IF ISNULL(@sRefTable, '') != '' AND ISNULL(@sRefRid, 0) > 0 AND ISNULL(@sRefNo, '') != ''
                BEGIN
                    SET @vReqBookingXML.modify('delete (/DataSet/Record/@wReqStatus)');
                    SET @vReqBookingXML.modify('insert (attribute wReqStatus {"P"}) into (/DataSet/Record)[1]');

                    SET @vReqBookingXML.modify('delete (/DataSet/Record/@wRefTable)');
                    SET @vReqBookingXML.modify('insert (attribute wRefTable {sql:variable("@sRefTable")}) into (/DataSet/Record)[1]');

                    SET @vReqBookingXML.modify('delete (/DataSet/Record/@wRefRid)');
                    SET @vReqBookingXML.modify('insert (attribute wRefRid {sql:variable("@sRefRid")}) into (/DataSet/Record)[1]');

                    SET @vReqBookingXML.modify('delete (/DataSet/Record/@wRefNo)');
                    SET @vReqBookingXML.modify('insert (attribute wRefNo {sql:variable("@sRefNo")}) into (/DataSet/Record)[1]');
                END

                DECLARE @vResult TABLE(RowID BIGINT NOT NULL);

                INSERT INTO @vResult ( RowID )
                EXEC spa.SetReqBooking @pXML            = @vReqBookingXML,
                                       @pMainCompNo     = @pMainCompNo,
                                       @pReturnResult   = 'Y',
                                       @pTestMode       = @pTestMode,
                                       @pErrCode        = @sErrCode OUTPUT,
                                       @pErrMsg         = @sErrMsg OUTPUT;

                -- return dbo.eReqBooking.[RowID]
                ------------------------------------------------------------------------------
                IF @sErrMsg = '' OR @sErrMsg IS NULL
                BEGIN
                    SET @pReqBookingRid = (SELECT TOP(1) RowID FROM @vResult);
                    IF ISNULL(@pReqBookingRid, 0) <= 0
                    BEGIN
                        SET @sErrCode = 50001;
                        SET @sErrMsg = N'Invalid ReqBooking.RowID';
                    END
                END
            END
            
            -- INSERT/UPDATE/DELETE dbo.eReqBookingHotel
            --------------------------------------------------------------------------------------------------
            IF @sErrMsg = '' OR @sErrMsg IS NULL
            BEGIN
                -- 修正@vReqBookingHotelXML.RecordState = @vReqBookingXML.RecordState
                -- 修正@vReqBookingHotelXML.wUpdBy = @vReqBookingXML.wUpdBy
                -- 修正@vReqBookingHotelXML.wReqBookingRid = @vReqBookingXML.RowID
                -- 修正@vReqBookingHotelXML.wRefNo = @vReqBookingXML.wRefNo OR dbo.eReqBooking.wRefNo
                --------------------------------------------------------------------------------------------------
                SET @sRecordState = @vReqBookingXML.value('(/DataSet/Record/@RecordState)[1]', 'CHAR(1)');
                SET @vReqBookingHotelXML.modify('delete (/DataSet/Record/@RecordState)');
                SET @vReqBookingHotelXML.modify('insert (attribute RecordState {sql:variable("@sRecordState")}) into (/DataSet/Record)[1]');

                SET @sUpdBy = @vReqBookingXML.value('(/DataSet/Record/@wUpdBy)[1]', 'BIGINT');
                SET @vReqBookingHotelXML.modify('delete (/DataSet/Record/@wUpdBy)');
                SET @vReqBookingHotelXML.modify('insert (attribute wUpdBy {sql:variable("@sUpdBy")}) into (/DataSet/Record)[1]');

                SET @vReqBookingHotelXML.modify('delete (/DataSet/Record/@wReqBookingRid)');
                SET @vReqBookingHotelXML.modify('insert (attribute wReqBookingRid {sql:variable("@pReqBookingRid")}) into (/DataSet/Record)[1]');

                EXEC spa.SetReqBookingHotel @pXML           = @vReqBookingHotelXML, 
                                            @pMainCompNo    = @pMainCompNo,
                                            @pReturnResult  = 'N',
                                            @pTestMode      = @pTestMode,
                                            @pErrCode       = @sErrCode OUTPUT,
                                            @pErrMsg        = @sErrMsg OUTPUT;
            END
            
            --------------------------------------------------------------------------------------------------
            IF NULLIF(@sErrMsg, '') IS NOT NULL
            BEGIN
                SET @sErrCode = ISNULL(IIF(@sErrCode <= 0, NULL, @sErrCode), 70001);
                THROW @sErrCode, @sErrMsg, 1;
            END
            
            --------------------------------------------------------------------------------------------------
            IF @sBeginTranCount = 0 AND @@TRANCOUNT > 0
            BEGIN
                IF @pTestMode = 1
                    ROLLBACK TRAN
                ELSE
                    COMMIT TRAN;
            END
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
    END