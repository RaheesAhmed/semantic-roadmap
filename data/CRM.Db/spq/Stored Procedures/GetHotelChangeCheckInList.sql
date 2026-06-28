CREATE PROCEDURE [spq].[GetHotelChangeCheckInList]
    @pRefNo             VARCHAR(30),
    @pOrderNo           VARCHAR(30),
    @pDebitAgentCodeIn  VARCHAR(14),
    @pStartDate         DATE,
    @pEndDate           DATE,
    @pHotelRid          BIGINT,
    @pPaymentMethod     VARCHAR(30),
    @pAction            VARCHAR(10) = '',
    @pLangCd            VARCHAR(10) = 'en-GB' ,
    @pPageSize          INT = 999 ,
    @pPageNum           INT = 1
AS
    BEGIN  
        SET NOCOUNT ON;  
        
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        SET @pRefNo             = NULLIF(@pRefNo, '');
        SET @pOrderNo           = NULLIF(@pOrderNo, '');
        SET @pDebitAgentCodeIn  = NULLIF(@pDebitAgentCodeIn, '');
        SET @pStartDate         = ISNULL(@pStartDate, '0001-01-01');
        SET @pEndDate           = ISNULL(@pEndDate, '9999-12-31');
        SET @pHotelRid          = IIF(@pHotelRid <= 0, NULL, @pHotelRid);
        SET @pPaymentMethod     = NULLIF(@pPaymentMethod, '');
        SET @pAction            = NULLIF(@pAction, '');
        SET @pLangCd            = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

        WITH tResult AS (
            SELECT
                CNG.RowID ,
                CNG.wRoomBookingRid ,
                agnt.wAgentCode_Display ,
                h.wName ,
                bh.wIsAgentHotel ,
                BR.wBedType ,
                BR.wRoomNo ,
                UseAgencyAllotment = CAST(CNG.wUseExtraAllotment AS CHAR(1)) , 
                wReqStaff = IIF( @pLangCd = 'en-GB', USR.wName, USR.wCName),
                CNG.wAction  ,
                wAllotmentName = ag.wName ,
                CNG.wDayOfStay ,
                BR.wTotalAmount ,
                CNG.wNewStartDate ,
                CNG.wNewEndDate ,
                CNG.wOrderNo ,
                BR.wPaymentMethod  ,
                wReqDepartment = ebc.wReqDepartment ,
                CNG.wCrtDt ,
                CNG.wUpdDt ,
                CNG.wCurrCode ,
                wUpdBy = IIF( @pLangCd = 'en-GB', mUpdUsr.wName, mUpdUsr.wCName),
                wAgentCodeIn = eb.wReqAgentCodeIn ,
                wBookingNo = eb.wRefNo,
                CNG.wAmountChange ,
                wRequestDeptCd =ebc.wReqDepartment ,
                CNG.wBookingRid,
                br.wGetKeyMethod
            FROM dbo.eHotelChange AS CNG WITH(NOLOCK)
            INNER JOIN dbo.eBookingRoom AS br WITH(NOLOCK) ON br.RowID = CNG.wRoomBookingRid AND br.wStatus = 'A'
            INNER JOIN dbo.eBooking AS eb WITH(NOLOCK) ON eb.RowID = BR.wBookingRid AND eb.wBookingType = 'ROOM'
            INNER JOIN dbo.eBookingHotel AS bh WITH(NOLOCK) ON bh.RowID = br.wHotelBookingRid AND br.wStatus = 'A'
            INNER JOIN RollsMary.dbo.mAgent AS agnt WITH(NOLOCK) ON agnt.wAgentCodeIn = eb.wDebitAgentCodeIn
            INNER JOIN dbo.eBooking AS ebc WITH(NOLOCK) ON ebc.RowID = CNG.wBookingRid AND ebc.wBookingType = 'CHANGEHOTEL'
            LEFT JOIN dbo.mAllotmentGroup AS ag WITH(NOLOCK) ON ag.RowID = BR.wAllotmentGroupRid
            LEFT JOIN dbo.mHotel AS h WITH(NOLOCK) ON h.RowID = br.wHotelRid
            LEFT JOIN RollsMary.dbo.mUsr AS USR WITH(NOLOCK) ON USR.RowID = ebc.wReqUserRid
            LEFT JOIN RollsMary.dbo.mUsr AS mUpdUsr WITH(NOLOCK) ON mUpdUsr.RowID = CNG.wUpdBy
            WHERE (@pRefNo IS NULL OR @pRefNo = eb.wRefNo)
                AND (@pOrderNo IS NULL OR @pOrderNo = CNG.wOrderNo)
                AND (@pDebitAgentCodeIn IS NULL OR @pDebitAgentCodeIn = ebc.wDebitAgentCodeIn)
                AND (CNG.wNewStartDate BETWEEN @pStartDate AND @pEndDate)
                AND (@pHotelRid IS NULL OR @pHotelRid = br.wHotelRid)
                AND (@pPaymentMethod IS NULL OR @pPaymentMethod = CNG.wPaymentMethod)
                AND ( @pAction IS NULL OR wAction = @pAction)
        ),
        tCount AS (
            SELECT wRecordCount = COUNT(1) FROM tResult
        )

        SELECT
            tResult.* ,
            wRecordCount
        FROM tResult , tCount
        ORDER BY tResult.wCrtDt DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION(RECOMPILE);
    END;