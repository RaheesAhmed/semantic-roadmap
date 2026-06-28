CREATE TABLE [dbo].[mHotel] (
    [RowID]                  BIGINT          NOT NULL,
    [wCode]                  VARCHAR (20)    NOT NULL,
    [wName]                  NVARCHAR (100)  NOT NULL,
    [wLangCd]                VARCHAR (10)    CONSTRAINT [DF_mHotel_wLangCd] DEFAULT ('') NOT NULL,
    [wRegion]                VARCHAR (20)    NULL,
    [wDistrictCd]            VARCHAR (30)    NULL,
    [wCurrCode]              VARCHAR (6)     NOT NULL,
    [wIsBase]                CHAR (1)        CONSTRAINT [DF_mHotel_wHasAllotment] DEFAULT ('N') NOT NULL,
    [wAddress]               NVARCHAR (1000) CONSTRAINT [DF_mHotel_wAddress] DEFAULT ('') NULL,
    [wRemark]                NVARCHAR (1000) CONSTRAINT [DF_Table1_wRemarks] DEFAULT ('') NULL,
    [wSmsRemark]             NVARCHAR (1000) NULL,
    [wSeqNo]                 INT             CONSTRAINT [DF_mHotel_wSeqNo] DEFAULT ((0)) NOT NULL,
    [wStatus]                CHAR (1)        CONSTRAINT [DF_mHotel_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]                 DATETIME2 (7)   NOT NULL,
    [wCrtBy]                 BIGINT          NOT NULL,
    [wUpdDt]                 DATETIME2 (7)   NOT NULL,
    [wUpdBy]                 BIGINT          NOT NULL,
    [wEname]                 NVARCHAR (100)  DEFAULT ('') NOT NULL,
    [wJname]                 NVARCHAR (100)  DEFAULT ('') NOT NULL,
    [wThname]                NVARCHAR (100)  DEFAULT ('') NOT NULL,
    [wKname]                 NVARCHAR (100)  DEFAULT ('') NOT NULL,
    [wGetKeyMethod]          VARCHAR (5)     DEFAULT ('1') NOT NULL,
    [wIsSunTrip]             CHAR (1)        DEFAULT ('N') NOT NULL,
    [wDebitServiceCounter]   BIGINT          DEFAULT ((0)) NOT NULL,
    [wHasWIFI]               CHAR (1)        DEFAULT ('Y') NOT NULL,
    [wNeedEntrancePaper]     CHAR (1)        DEFAULT ('N') NOT NULL,
    [wEntrancePaperTips]     NVARCHAR (1000) DEFAULT ('') NOT NULL,
    [wRoomServiceDesc]       NVARCHAR (1000) DEFAULT ('') NOT NULL,
    [wHotelDesktopDesc]      NVARCHAR (1000) DEFAULT ('') NOT NULL,
    [wNeedPassengerName]     CHAR (1)        DEFAULT ('N') NOT NULL,
    [wNeedPassengerID]       CHAR (1)        DEFAULT ('N') NOT NULL,
    [wNeedPassengerBirthday] CHAR (1)        DEFAULT ('N') NOT NULL,
    [wNeedUploadID]          CHAR (1)        DEFAULT ('N') NOT NULL,
    [wUploadIDType]          VARCHAR (5)     DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_mHotel] PRIMARY KEY CLUSTERED ([RowID] ASC)
);












GO
CREATE NONCLUSTERED INDEX [PI_mHotel_01]
    ON [dbo].[mHotel]([wRegion] ASC, [wIsBase] ASC, [wStatus] ASC)
    INCLUDE([RowID], [wCode], [wCrtBy], [wCurrCode], [wDistrictCd], [wEname], [wJname], [wKname], [wName], [wSeqNo], [wThname], [wUpdBy], [wUpdDt]);


GO
CREATE NONCLUSTERED INDEX [PI_mHotel_02]
    ON [dbo].[mHotel]([wCode] ASC)
    INCLUDE([wName]);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'SunTrip使用', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotel', @level2type = N'COLUMN', @level2name = N'wIsSunTrip';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'取匙方式（1：服務部，2：酒店前台, 3: 服務部/酒店前台）', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotel', @level2type = N'COLUMN', @level2name = N'wGetKeyMethod';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'上傳證件方式（1：即時， 2： 后補）', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotel', @level2type = N'COLUMN', @level2name = N'wUploadIDType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'服務部描述', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotel', @level2type = N'COLUMN', @level2name = N'wRoomServiceDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'上傳證件', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotel', @level2type = N'COLUMN', @level2name = N'wNeedUploadID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'客戶姓名', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotel', @level2type = N'COLUMN', @level2name = N'wNeedPassengerName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'證件資料', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotel', @level2type = N'COLUMN', @level2name = N'wNeedPassengerID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'出生日期', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotel', @level2type = N'COLUMN', @level2name = N'wNeedPassengerBirthday';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'入境紙', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotel', @level2type = N'COLUMN', @level2name = N'wNeedEntrancePaper';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'前台描述', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotel', @level2type = N'COLUMN', @level2name = N'wHotelDesktopDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'有WIFI', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotel', @level2type = N'COLUMN', @level2name = N'wHasWIFI';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'入境紙提示', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotel', @level2type = N'COLUMN', @level2name = N'wEntrancePaperTips';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'扣數服務櫃台', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mHotel', @level2type = N'COLUMN', @level2name = N'wDebitServiceCounter';

