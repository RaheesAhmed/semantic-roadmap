
CREATE PROCEDURE [spq].[GetBookingHotelByBookingRid]
    @pBookingRid BIGINT = 0,
    @pBookingHotelRid BIGINT = 0 ,
    @pBookingRoomRid BIGINT = 0, -- 通過eBookingRoom.RowID獲取房間所在的酒店訂單，等級最低，只有@pBookingRid = null，@pBookingHotelRid = null才會起作用
    @pLangCd VARCHAR(20) = 'en-gb'
AS
    BEGIN
        SET NOCOUNT ON;  

        SET @pBookingRid = IIF(@pBookingRid <= 0, NULL, @pBookingRid);
        SET @pBookingHotelRid = IIF(@pBookingHotelRid <= 0, NULL, @pBookingHotelRid);
        SET @pBookingRoomRid = IIF(@pBookingRoomRid <= 0, NULL, @pBookingRoomRid);

        -- @pBookingRid = null，@pBookingHotelRid = null，@pBookingRoomRid <> null，獲取房間所有的酒店
        IF @pBookingRid IS NULL AND @pBookingHotelRid IS NULL AND @pBookingRoomRid IS NOT NULL
            SET @pBookingHotelRid = (SELECT TOP(1) wHotelBookingRid FROM dbo.eBookingRoom WHERE RowID = @pBookingRoomRid);

        SELECT
            EBH.[RowID] ,
            EBH.[wBookingRid] ,
            EBH.[wRequestRid] ,
            EBH.[wUseTravelAgency] ,
            EBH.[wTravelAgencyRid] ,
            EBH.[wRoomInProgress] ,
            EBH.[wRoomCompleted] ,
            EBH.[wRoomNotArrange] ,
            EBH.[wRoomUnQualified] ,
            EBH.[wRoomCancelled] ,
            EBH.[wRegion] ,
            EBH.[wIsAgentHotel] ,
            EBH.[wStartDate] ,
            EBH.[wEndDate] ,
            EBH.[wDayOfStay] ,
            EBH.[wBedType] ,
            EBH.[wPaymentMethod] ,
            EBH.[wReceiptNo] ,
            EBH.[wRemark] ,
            EBH.[wSeqNo] ,
            EBH.[wCrtDt] ,
            EBH.[wCrtBy] ,
            EBH.[wUpdDt] ,
            EBH.[wUpdBy] ,
            EBH.[wQuantity] ,
            EBH.[wBookingStatus] ,
            EBH.[wCounterRid] ,
            CAST(EBH.[wStatus] AS VARCHAR(1)) AS wStatus ,
            CASE WHEN @pLangCd = 'en-gb' THEN USR.wName ELSE USR.wCName END AS wUpdByCName ,
            CASE WHEN @pLangCd = 'en-gb' THEN CRUSR.wName ELSE CRUSR.wCName END AS wCreatedByCName ,
            eb.wRefNo ,
            daAgent.wAgentCode_Display
        FROM dbo.eBookingHotel AS EBH
        INNER JOIN dbo.eBooking AS eb ON EBH.wBookingRid = eb.RowID
        INNER JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
        LEFT JOIN [RollsMary].[dbo].[mUsr] USR ON USR.RowID = EBH.wUpdBy
        LEFT JOIN [RollsMary].[dbo].[mUsr] CRUSR ON CRUSR.RowID = EBH.wCrtBy
        WHERE (@pBookingRid IS NOT NULL OR @pBookingHotelRid IS NOT NULL) -- 兩個RowId不能全是空
            AND (@pBookingRid IS NULL OR @pBookingRid = EBH.wBookingRid)
            AND (@pBookingHotelRid IS NULL OR @pBookingHotelRid = EBH.RowID)
    END;