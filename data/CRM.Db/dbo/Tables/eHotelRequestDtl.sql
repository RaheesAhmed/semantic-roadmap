CREATE TABLE [dbo].[eHotelRequestDtl] (
    [RowID]                BIGINT          NOT NULL,
    [wHotelRequestRid]     BIGINT          NOT NULL,
    [wHotelCode]           VARCHAR (20)    NOT NULL,
    [wLine]                INT             NOT NULL,
    [wCounterRid]          BIGINT          NOT NULL,
    [wTotalProvideRoomQty] INT             NOT NULL,
    [wIsReject]            CHAR (1)        NOT NULL,
    [wSeqNo]               INT             CONSTRAINT [DF_eHotelRequestDtl_wSeqNo] DEFAULT ((0)) NOT NULL,
    [wCrtDt]               DATETIME2 (7)   NOT NULL,
    [wCrtBy]               BIGINT          NOT NULL,
    [wUpdDt]               DATETIME2 (7)   NOT NULL,
    [wUpdBy]               BIGINT          NOT NULL,
    [wCrtByCounterRid]     BIGINT          NOT NULL,
    [wPriority]            INT             CONSTRAINT [DF_eHotelRequestDtl_wPriority] DEFAULT ((0)) NOT NULL,
    [wRemark]              NVARCHAR (4000) CONSTRAINT [DF_eHotelRequestDtl_wRemark] DEFAULT (N'') NOT NULL,
    [wHotelRid]            BIGINT          DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_eHotelRequestDtl] PRIMARY KEY CLUSTERED ([RowID] ASC)
);
















GO



GO



GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'不派房時, 需要輸入原因', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eHotelRequestDtl', @level2type = N'COLUMN', @level2name = N'wRemark';

