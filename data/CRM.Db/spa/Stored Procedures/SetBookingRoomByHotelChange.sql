
CREATE PROCEDURE [spa].[SetBookingRoomByHotelChange]
    (
      @pXML XML ,
	  @pActionType CHAR(1) , -- I/U
      @pMainCompNo INT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
    )
AS
    BEGIN
        SET NOCOUNT ON;

        IF OBJECT_ID('tempdb..#DataSet_SetHotelChange') IS NOT NULL
            DROP TABLE #DataSet_SetHotelChange;
        DECLARE @sRowID BIGINT = 0 ,
            @sDocHandle INT ,
            @wSeqNo INT= 0;
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;

        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #DataSet_SetHotelChange
        FROM    OPENXML (@sDocHandle, 'DataSet/GetHotelChangeDateCheckInByBookingRoomIdResult', 1)
                WITH( RowID                  BIGINT,
                      wHotelBookingRid       BIGINT,
                      wRoomBookingRid        BIGINT,
                      wHotelRid              BIGINT,
                      wHotelRoomRid          BIGINT,
                      wAllotmentRid          BIGINT,
                      wAllotmentName         VARCHAR(30),
                      wOrderNo               NVARCHAR(60),
                      wBedType               VARCHAR(30),
                      wStartDate             DATE,
                      wEndtDate              DATE,
                      wDayOfStay             INT,
                      wPaymentMethod         VARCHAR(30),
                      wCashReceiptNo         NVARCHAR(40),
                      wCashTransferReceiptNo VARCHAR(40),
                      wGetKeyMethod          VARCHAR(30),
                      wCurrCode              CHAR(3),
                      wIncludeBreakfast      CHAR(1),
                      wUseExtraAllotment     CHAR(1),
                      wUseUpAllotment        CHAR(1),
                      wTotalAmount           NUMERIC(18, 4),
                      wTotalCost             NUMERIC(18, 4),
                      wRoomNo                NVARCHAR(20),
                      wRemark                NVARCHAR(500),
                      wUpdDt                 DATETIME2(7),
                      wUpdBy                 BIGINT,
                      wReqUserRid            BIGINT,
                      wRequestStaffRid       BIGINT,
                      wStaffReqForAmendments VARCHAR(200),
                      wReqDepartment         VARCHAR(30),
                      wDebitDate             DATETIME2(7),
                      wAssistanceBookerName  NVARCHAR(50),
                      wAssistanceBookerPhone VARCHAR(100),
                      wNewStartDate          DATETIME2(7),
                      wNewEndDate            DATETIME2(7),
                      UseBlackCard           CHAR(1),
                      UpdateCheckInPass      CHAR(1),
                      wAction                VARCHAR(5),
                      wReGetKey              CHAR(1),
                      wIsHotelChangeRecord   CHAR(1),
                      wReqCounterRid         BIGINT,
                      wAsstBooker            NVARCHAR(50),
                      wAssBookerTel          VARCHAR(100),
                      wApprovalAgentCodeIn   VARCHAR(14) );

        DECLARE @dayOfStay INT= 0 ,
            @roomPrice NUMERIC(18, 4)= 0 ,
            @roomCoast NUMERIC(18, 4)= 0 ,
            @totalAmount NUMERIC(18, 4)= 0 ,
            @totalCost NUMERIC(18, 4)= 0 ,
            @breakFastCoast NUMERIC(18, 4)= 0;
        DECLARE @newStartDate DATE ,
            @newEndDate DATE ,
            @startDate DATE ,
            @endDate DATE ,
            @updateBy BIGINT ,
            @reGetKey CHAR(1);
        DECLARE @roomBookingRowId BIGINT ,
            @wIsHotelChangeRecord CHAR(1) ,
            @includeBreakfast CHAR(1) ,
            @updateCheckInPass CHAR(1) ,
            @action VARCHAR(5);
        DECLARE @keyPasscode VARCHAR(8) = 1000000 - CEILING(RAND() * 100000) ,
            @paymentMethod VARCHAR(30)= '';
        DECLARE @pwRequestIRId BIGINT= -1 ,
            @sHotelBookingRid BIGINT= -1 ,
            @sOriAmount NUMERIC(18, 4)= 0;

        SELECT  @startDate = wStartDate ,
                @endDate = wEndtDate ,
                @newStartDate = wNewStartDate ,
                @newEndDate = wNewEndDate ,
                @roomBookingRowId = wRoomBookingRid ,
                @dayOfStay = DATEDIFF(DAY, wNewStartDate, wNewEndDate) ,
                @includeBreakfast = wIncludeBreakfast ,
                @wIsHotelChangeRecord = wIsHotelChangeRecord ,
                @updateCheckInPass = UpdateCheckInPass ,
                @totalAmount = wTotalAmount ,
                @totalCost = wTotalCost ,
                @action = wAction ,
                @updateBy = wUpdBy ,
                @paymentMethod = wPaymentMethod ,
                @reGetKey = wReGetKey
        FROM    #DataSet_SetHotelChange;

        DECLARE @roomBookingStatus VARCHAR(3)= 'C';

        --IF @action = 'CL'
        --    SET @roomBookingStatus = 'RF';

        IF @action != 'CL'
            BEGIN
                UPDATE  BKR
                SET     BKR.wTotalAmount = @totalAmount ,
                        BKR.wActualTotalAmount = ( CASE WHEN ( @paymentMethod = 'DA'
                                                              OR @paymentMethod = 'RC'
                                                              OR @paymentMethod = 'GC'
                                                             )
                                                        THEN @totalAmount
                                                        ELSE 0
                                                   END ) ,
                        BKR.wStartDate = @newStartDate ,
                        BKR.wEndtDate = @newEndDate ,
                        BKR.wDayOfStay = @dayOfStay ,
                        BKR.wTotalCost = @totalCost ,
                        BKR.wIncludeBreakfast = @includeBreakfast ,
                        BKR.wBookingStatus = CASE WHEN @reGetKey IS NOT NULL AND @reGetKey = 'Y' THEN @roomBookingStatus ELSE BKR.wBookingStatus END ,
                        BKR.wUpdDt = dbo.fnUTC8Now() ,
                        BKR.wUpdBy = @updateBy ,
                        BKR.wOrderNo = TMP.wOrderNo ,
                        BKR.wCashReceiptNo = TMP.wCashReceiptNo ,
                        BKR.wHasStaffGetKey = CASE WHEN @reGetKey IS NOT NULL AND @reGetKey = 'Y' THEN 'N' ELSE BKR.wHasStaffGetKey END ,
                        BKR.wHasClientGetKey = CASE WHEN @reGetKey IS NOT NULL AND @reGetKey = 'Y' THEN 'N' ELSE BKR.wHasClientGetKey END ,
                        BKR.wGetKeyPasscode = CASE @pActionType WHEN 'I' THEN RIGHT(CAST(( RAND() + 1 ) * 1000000 AS INT), 6) ELSE BKR.wGetKeyPasscode END --更改動作: 更改入住日期Edit時不更改取房密碼
                FROM    dbo.eBookingRoom BKR
                        INNER JOIN #DataSet_SetHotelChange TMP ON BKR.RowID = TMP.wRoomBookingRid
                WHERE   BKR.RowID = @roomBookingRowId;

                UPDATE eb
                SET    eb.wReqCounterRid = TMP.wReqCounterRid ,
                       eb.wReqDepartment = TMP.wReqDepartment ,
                       eb.wReqUserRid = TMP.wReqUserRid ,
                       eb.wAsstBooker = TMP.wAsstBooker ,
                       eb.wAssBookerTel = TMP.wAssBookerTel ,
                       eb.wApprovalAgentCodeIn = TMP.wApprovalAgentCodeIn 
                FROM   dbo.eBooking eb
                       INNER JOIN dbo.eBookingRoom BKR ON eb.RowID=BKR.wBookingRid
                       INNER JOIN #DataSet_SetHotelChange TMP ON BKR.RowID = TMP.wRoomBookingRid
                WHERE   BKR.RowID = @roomBookingRowId;
            END;
    END;