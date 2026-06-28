CREATE PROC [spa].[SetDeptRoomRepStatus]
    @pXML           XML,
    @pMainCompNo    INT ,
    @pErrCode       INT OUTPUT ,
    @pErrMsg        NVARCHAR(200) OUTPUT
AS 
    BEGIN
        SET NOCOUNT ON;

        DECLARE @vBookingHotel TABLE(
            RowID               BIGINT PRIMARY KEY,
            wNewBookingStatus   VARCHAR(5),
            wOldBookingStatus   VARCHAR(5)
        );

        IF @pXML IS NOT NULL
        BEGIN
            INSERT @vBookingHotel (
                RowID,
                wNewBookingStatus,
                wOldBookingStatus
            )
            SELECT  tmp.RowID, 
                    tmp.wNewBookingStatus, 
                    tmp.wOldBookingStatus 
            FROM (
                SELECT  RowID               = T.tmp.value('@RowID',             'BIGINT'),
                        wNewBookingStatus   = T.tmp.value('@wNewBookingStatus', 'VARCHAR(5)'),
                        wOldBookingStatus   = T.tmp.value('@wOldBookingStatus', 'VARCHAR(5)')
                FROM @pXML.nodes('DataSet/Record') T(tmp)
            ) tmp WHERE tmp.RowID > 0 AND tmp.wNewBookingStatus IS NOT NULL AND tmp.wOldBookingStatus IS NOT NULL;
        END

        -- 自動把部門酒店訂房【需求狀態】設置為："酒店預訂"訂單狀態顯示為完成, 需求狀態的才顯示為完成, 其他狀態都顯示為處理中
        IF EXISTS (SELECT 1 FROM @vBookingHotel WHERE wNewBookingStatus <> wOldBookingStatus)
        BEGIN
            DECLARE @vXML XML;

            SET @vXML = (SELECT dr.RowID,
                                dr.wHotelRid,
                                dr.wRoomRid,
                                dr.wBigBedQty,
                                dr.wTwinBedQty,
                                dr.wSuiteRoom1Qty,
                                dr.wSuiteRoom2Qty,
                                dr.wSuiteRoom3Qty,
                                dr.wDayOfStay,
                                dr.wStartDate,
                                dr.wEndDate,
                                dr.wStatus,
                                wRepStatus = IIF(vbh.wNewBookingStatus = 'C', 'C', 'P'),
                                dr.wRemark,
                                dr.wCrtDt,
                                dr.wCrtBy,
                                wUpdDt  = bh.wUpdDt,
                                wUpdBy  = bh.wUpdBy,
                                dr.wDeptReqRoomRid,
                                dr.wIsApproved,
                                dr.wTotalAmount,
                                dr.wDeptStatus,
                                dr.wBookingRid,
                                dr.wCancelReason,
                                dr.wGUID
                        FROM @vBookingHotel vbh
                        INNER JOIN dbo.eBookingHotel bh WITH(NOLOCK) ON bh.RowID = vbh.RowID
                        INNER JOIN dbo.eDeptRespRoom dr  WITH(NOLOCK) ON dr.wBookingRid = bh.wBookingRid
                        WHERE vbh.wNewBookingStatus <> vbh.wOldBookingStatus
                        FOR XML RAW('Record'), ROOT('DataSet')
            );

            -- 非部門酒店訂房，不需要Update部門酒店狀態
            IF @vXML IS NOT NULL
            BEGIN
                EXEC spa.SetDeptResponseRoom @pXML          = @vXML,
                                             @pActionType   = 'U',
                                             @pMainCompNo   = @pMainCompNo,
                                             @pReturnResult = 'N',
                                             @pTestMode     = 0,
                                             @pErrCode      = @pErrCode OUTPUT,
                                             @pErrMsg       = @pErrMsg OUTPUT;
            END
        END
    END