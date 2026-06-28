CREATE TABLE [dbo].[mItemSerial] (
    [RowID]        BIGINT        NOT NULL,
    [wItemRid]     BIGINT        NOT NULL,
    [wPurchaseRid] BIGINT        NOT NULL,
    [wSerialNo]    VARCHAR (50)  NOT NULL,
    [wStatus]      CHAR (1)      CONSTRAINT [DF_mItemSerial_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]       DATETIME2 (7) NOT NULL,
    [wUpdDt]       DATETIME2 (7) NOT NULL,
    [wCrtBy]       BIGINT        CONSTRAINT [DF_mItemSerial_wCrtBy] DEFAULT ((0)) NOT NULL,
    [wUpdBy]       BIGINT        CONSTRAINT [DF_mItemSerial_wUpdBy] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_mItemSerial] PRIMARY KEY CLUSTERED ([RowID] ASC)
);



