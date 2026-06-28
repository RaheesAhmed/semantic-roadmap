-- 部門酒店安排酒店訂單
CREATE PROC [spa].[SetDeptRoomBookingHotel]
    @pXML           XML,
    @pMainCompNo    INT ,
    @pErrCode       INT OUTPUT,
    @pErrMsg        NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @vDeptRespRoom TABLE (RowID BIGINT PRIMARY KEY, wBookingRid BIGINT);
        
        IF @pXML IS NOT NULL
        BEGIN
            INSERT INTO @vDeptRespRoom ( RowID, wBookingRid)
            SELECT tmp.RowID, tmp.wBookingRid FROM (
                SELECT RowNum = ROW_NUMBER() OVER (PARTITION BY tmp.RowID ORDER BY tmp.wBookingRid DESC),
                       tmp.RowID,
                       tmp.wBookingRid
                FROM (
                    SELECT  RowID       = T.tmp.value('@RowID',         'BIGINT'),
                            wBookingRid = T.tmp.value('@wBookingRid',   'BIGINT')
                    FROM @pXML.nodes('DataSet/Record') T(tmp)
                ) tmp WHERE tmp.RowID > 0 AND tmp.wBookingRid > 0
            ) tmp WHERE tmp.RowNum = 1;
        END

        -- 禁止重複派房
        IF EXISTS ( SELECT 1 
                    FROM @vDeptRespRoom vdr 
                    INNER JOIN dbo.eDeptRespRoom dr ON dr.RowID = vdr.RowID
                    INNER JOIN dbo.eBooking eb ON eb.RowID = dr.wBookingRid)
        BEGIN
            SET @pErrCode = 70001;
            SET @pErrMsg = ( 
                SELECT TOP(1) N'重複派房（已有酒店單號：'+ eb.wRefNo +'）' 
                FROM @vDeptRespRoom vdr 
                INNER JOIN dbo.eDeptRespRoom dr ON dr.RowID = vdr.RowID
                INNER JOIN dbo.eBooking eb ON eb.RowID = dr.wBookingRid
            );

            THROW @pErrCode, @pErrMsg, 1;
        END;
        
        -- 關聯酒店訂單
        IF EXISTS (SELECT 1 FROM @vDeptRespRoom)
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
                                dr.wRepStatus,
                                dr.wRemark,
                                dr.wCrtDt,
                                dr.wCrtBy,
                                wUpdDt  = bh.wUpdDt,
                                wUpdBy  = bh.wUpdBy,
                                dr.wDeptReqRoomRid,
                                dr.wIsApproved,
                                dr.wTotalAmount,
                                dr.wDeptStatus,
                                wBookingRid = bh.wBookingRid,
                                dr.wCancelReason,
                                dr.wGUID
                        FROM @vDeptRespRoom vdr
                        INNER JOIN dbo.eBookingHotel bh ON bh.wBookingRid = vdr.wBookingRid
                        INNER JOIN dbo.eDeptRespRoom dr ON dr.RowID = vdr.RowID
                        FOR XML RAW('Record'), ROOT('DataSet')
            );
            
            EXEC spa.SetDeptResponseRoom @pXML          = @vXML,
                                         @pActionType   = 'U',
                                         @pMainCompNo   = @pMainCompNo,
                                         @pReturnResult = 'N',
                                         @pTestMode     = 0,
                                         @pErrCode      = @pErrCode OUTPUT,
                                         @pErrMsg       = @pErrMsg OUTPUT;
        END
    END