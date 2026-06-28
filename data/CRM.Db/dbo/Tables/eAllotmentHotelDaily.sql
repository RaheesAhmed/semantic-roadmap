CREATE TABLE [dbo].[eAllotmentHotelDaily] (
    [RowId]              BIGINT          NOT NULL,
    [wRoomRid]           BIGINT          NOT NULL,
    [wAllotmentGroupRid] BIGINT          NOT NULL,
    [wDate]              DATE            NOT NULL,
    [wAllotmentQty]      INT             NOT NULL,
    [wExtraQty]          INT             NOT NULL,
    [wBookedQty]         INT             NOT NULL,
    [wCurrCode]          VARCHAR (6)     NOT NULL,
    [wRoomPrice]         NUMERIC (18, 4) NOT NULL,
    [wBreakfastPrice]    NUMERIC (18, 4) NOT NULL,
    [wRoomCost]          NUMERIC (18, 4) NOT NULL,
    [wIsCustomized]      CHAR (1)        CONSTRAINT [DF_eRoomAllotmentDailyRecord_IsCustomized] DEFAULT ('N') NOT NULL,
    [wStatus]            CHAR (1)        CONSTRAINT [DF_eRoomAllotmentDailyRecord_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]             DATETIME2 (7)   NOT NULL,
    [wCrtBy]             BIGINT          NOT NULL,
    [wUpdDt]             DATETIME2 (7)   NOT NULL,
    [wUpdBy]             BIGINT          NOT NULL,
    [wExtraBedPrice]     NUMERIC (18, 4) DEFAULT ((0)) NOT NULL,
    [wOnHoldQty]         INT             DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_eRoomAllotmentDailyRecord] PRIMARY KEY CLUSTERED ([RowId] ASC)
);








GO



GO



GO



GO



GO



GO



GO



GO



GO
CREATE NONCLUSTERED INDEX [PI_eAllotmentHotelDaily_01]
    ON [dbo].[eAllotmentHotelDaily]([wRoomRid] ASC, [wAllotmentGroupRid] ASC, [wDate] ASC)
    INCLUDE([RowId], [wBookedQty], [wExtraQty]);


GO
CREATE NONCLUSTERED INDEX [IX_eAllotmentHotelDaily_01]
    ON [dbo].[eAllotmentHotelDaily]([wStatus] ASC)
    INCLUDE([wRoomRid], [wAllotmentGroupRid], [wDate])
    ON [CRM_IDX];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'停用房額數量：SunTrip新加', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eAllotmentHotelDaily', @level2type = N'COLUMN', @level2name = N'wOnHoldQty';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'加床費用', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eAllotmentHotelDaily', @level2type = N'COLUMN', @level2name = N'wExtraBedPrice';

