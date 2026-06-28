CREATE TABLE [dbo].[eHotelCheckIn] (
    [RowID]              BIGINT          NOT NULL,
    [wRoomBookingRid]    BIGINT          NOT NULL,
    [wHotelRid]          BIGINT          NOT NULL,
    [wRoomRid]           BIGINT          NOT NULL,
    [wAllotmentGroupRid] BIGINT          NOT NULL,
    [wRoomNo]            NVARCHAR (20)   NOT NULL,
    [wBookingDate]       DATE            NOT NULL,
    [wCurrCode]          CHAR (3)        NOT NULL,
    [wPrice]             NUMERIC (18, 4) CONSTRAINT [DF_eHotelCheckIn_wPrice] DEFAULT ((0)) NOT NULL,
    [wCost]              NUMERIC (18, 4) CONSTRAINT [DF_eHotelCheckIn_wCost] DEFAULT ((0)) NOT NULL,
    [wIncludeBreakfast]  CHAR (1)        CONSTRAINT [DF_eHotelCheckIn_wIncludeBreakfast] DEFAULT ('N') NOT NULL,
    [wExtraRoom]         CHAR (1)        CONSTRAINT [DF_eHotelCheckIn_wExtraRoom] DEFAULT ('N') NOT NULL,
    [wDismiss]           CHAR (1)        CONSTRAINT [DF_eHotelCheckIn_wDismiss] DEFAULT ('N') NOT NULL,
    [wExtent]            CHAR (1)        CONSTRAINT [DF_eHotelCheckIn_wExtent] DEFAULT ('N') NOT NULL,
    [wAgencyRoom]        CHAR (1)        CONSTRAINT [DF_eHotelCheckIn_wAgencyRoom] DEFAULT ('N') NOT NULL,
    [wStatus]            CHAR (1)        CONSTRAINT [DF_eHotelCheckIn_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]             DATETIME2 (7)   NOT NULL,
    [wCrtBy]             BIGINT          NOT NULL,
    [wUpdDt]             DATETIME2 (7)   NOT NULL,
    [wUpdBy]             BIGINT          NOT NULL,
    [wHotelChangeRid]    BIGINT          DEFAULT ((-1)) NOT NULL,
    [wBreakfastPrice]    NUMERIC (18, 4) DEFAULT ((0)) NOT NULL,
    [wExtraBedPrice]     NUMERIC (18, 4) DEFAULT ((0)) NOT NULL,
    [wExtraBed]          CHAR (1)        DEFAULT ('N') NOT NULL,
    CONSTRAINT [PK_eHotelCheckIn] PRIMARY KEY CLUSTERED ([RowID] ASC)
);














GO



GO



GO



GO



GO



GO



GO



GO
CREATE NONCLUSTERED INDEX [PI_eHotelCheckIn_01]
    ON [dbo].[eHotelCheckIn]([wRoomBookingRid] ASC, [wStatus] ASC, [wDismiss] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'關聯eHotelChange.RowId，表示與哪個更改入住日期相關', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eHotelCheckIn', @level2type = N'COLUMN', @level2name = N'wHotelChangeRid';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'額外房', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eHotelCheckIn', @level2type = N'COLUMN', @level2name = N'wExtraRoom';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'續房', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eHotelCheckIn', @level2type = N'COLUMN', @level2name = N'wExtent';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'加床費', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eHotelCheckIn', @level2type = N'COLUMN', @level2name = N'wExtraBedPrice';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'是否加床', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eHotelCheckIn', @level2type = N'COLUMN', @level2name = N'wExtraBed';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'早餐費', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eHotelCheckIn', @level2type = N'COLUMN', @level2name = N'wBreakfastPrice';

