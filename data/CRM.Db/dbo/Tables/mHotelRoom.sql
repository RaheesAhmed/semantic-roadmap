CREATE TABLE [dbo].[mHotelRoom] (
    [RowID]              BIGINT          NOT NULL,
    [wHotelRid]          BIGINT          NOT NULL,
    [wCode]              VARCHAR (30)    NOT NULL,
    [wName]              NVARCHAR (200)  CONSTRAINT [DF_mHotelRoom_wName] DEFAULT ('') NOT NULL,
    [wLangCd]            NVARCHAR (10)   CONSTRAINT [DF_mHotelRoom_wLangCd] DEFAULT ('') NOT NULL,
    [wRemarks]           NVARCHAR (500)  CONSTRAINT [DF_mHotelRoom_wRemarks] DEFAULT ('') NOT NULL,
    [wSeqNo]             INT             CONSTRAINT [DF_mHotelRoom_wSeqNo] DEFAULT ((0)) NOT NULL,
    [wStatus]            CHAR (1)        CONSTRAINT [DF_Table1_wStatuc] DEFAULT ('A') NOT NULL,
    [wCrtDt]             DATETIME2 (7)   NOT NULL,
    [wCrtBy]             BIGINT          NOT NULL,
    [wUpdDt]             DATETIME2 (7)   NOT NULL,
    [wUpdBy]             BIGINT          NOT NULL,
    [wEname]             NVARCHAR (100)  DEFAULT ('') NOT NULL,
    [wJname]             NVARCHAR (100)  DEFAULT ('') NOT NULL,
    [wThname]            NVARCHAR (100)  DEFAULT ('') NOT NULL,
    [wKname]             NVARCHAR (100)  DEFAULT ('') NOT NULL,
    [wMaxPeopleQty]      INT             DEFAULT ((1)) NOT NULL,
    [wCanExtBedType]     CHAR (1)        DEFAULT ('N') NOT NULL,
    [wBedType]           VARCHAR (30)    CONSTRAINT [DF__mHotelRoo__wBrea__70210BCE] DEFAULT ('') NOT NULL,
    [wBreakfastType]     VARCHAR (30)    DEFAULT ('') NOT NULL,
    [wCRoomIntroduction] NVARCHAR (1000) CONSTRAINT [DF__mHotelRoo__  
w__72095440] DEFAULT ('') NOT NULL,
    [wERoomIntroduction] VARCHAR (1000)  DEFAULT ('') NOT NULL,
    [wCRoomDescription]  NVARCHAR (1000) CONSTRAINT [DF__mHotelRoo__wCRoo__73F19CB2] DEFAULT ('') NOT NULL,
    [wERoomDescription]  VARCHAR (1000)  CONSTRAINT [DF__mHotelRoo__wERoo__74E5C0EB] DEFAULT ('') NOT NULL,
    [wCRoomCondition]    NVARCHAR (1000) CONSTRAINT [DF__mHotelRoo__wCRoo__75D9E524] DEFAULT ('') NOT NULL,
    [wERoomCondition]    NVARCHAR (1000) CONSTRAINT [DF__mHotelRoo__wERoo__76CE095D] DEFAULT ('') NOT NULL,
    [wIsSunTrip]         CHAR (1)        DEFAULT ('N') NOT NULL,
    [wRoomQtyOfPerID]    INT             CONSTRAINT [DF__mHotelRoo__wRoom__0E3B7E9A] DEFAULT ((1)) NOT NULL,
    [wRoomArea]          NUMERIC (18, 4) CONSTRAINT [DF__mHotelRoo__wRoom__0F2FA2D3] DEFAULT ((0)) NOT NULL,
    [wAllOpenDeposit]    NUMERIC (18, 4) DEFAULT ((0)) NOT NULL,
    [wAllLockDeposit]    NUMERIC (18, 4) DEFAULT ((0)) NOT NULL,
    [wIsMinibarFree]     CHAR (1)        DEFAULT ('N') NOT NULL,
    [wIsMinibarLock]     CHAR (1)        DEFAULT ('Y') NOT NULL,
    [wIsSmoking]         CHAR (1)        DEFAULT ('N') NOT NULL,
    [wIsNoSmoking]       CHAR (1)        DEFAULT ('N') NOT NULL,
    CONSTRAINT [PK_mHotelRoom] PRIMARY KEY CLUSTERED ([RowID] ASC),
    CONSTRAINT [FK_mHotelRoom_mHotel] FOREIGN KEY ([wHotelRid]) REFERENCES [dbo].[mHotel] ([RowID])
);












GO



GO



GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'房間簡述(英)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wERoomIntroduction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'房間描述(英)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wERoomDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'房間使用條款(英)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wERoomCondition';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'房間簡述(中)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wCRoomIntroduction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'房間描述(中)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wCRoomDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'房間使用條款(中)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wCRoomCondition';


GO



GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'可否加床位', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wCanExtBedType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'早餐', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wBreakfastType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'床類', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wBedType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'每個證件可訂房數', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wRoomQtyOfPerID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'房間面積', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wRoomArea';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'入住人數上限', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wMaxPeopleQty';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'SunTrip使用', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wIsSunTrip';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'吸菸房', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wIsSmoking';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'非吸菸房', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wIsNoSmoking';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'上鎖Mini Bar', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wIsMinibarLock';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'免費Mini Bar', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wIsMinibarFree';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'All Open押金', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wAllOpenDeposit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'All Lock押金', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotelRoom', @level2type = N'COLUMN', @level2name = N'wAllLockDeposit';

