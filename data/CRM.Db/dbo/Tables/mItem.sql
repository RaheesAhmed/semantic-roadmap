CREATE TABLE [dbo].[mItem] (
    [RowID]         BIGINT          NOT NULL,
    [wCategoryRid]  BIGINT          NOT NULL,
    [wCName]        NVARCHAR (100)  CONSTRAINT [DF_mItem_wCName] DEFAULT ('') NOT NULL,
    [wEName]        VARCHAR (100)   CONSTRAINT [DF_mItem_wEName] DEFAULT ('') NOT NULL,
    [wPrice]        DECIMAL (18, 4) NOT NULL,
    [wCurrCode]     VARCHAR (3)     NOT NULL,
    [wBarcode]      VARCHAR (1000)  CONSTRAINT [DF_mItem_wBarcode] DEFAULT ('') NOT NULL,
    [wIsSerialItem] CHAR (1)        CONSTRAINT [DF_mItem_wSerialItem] DEFAULT ('N') NOT NULL,
    [wStatus]       CHAR (1)        CONSTRAINT [DF_mItem_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]        DATETIME2 (7)   NOT NULL,
    [wUpdDt]        DATETIME2 (7)   NOT NULL,
    CONSTRAINT [PK_mItem] PRIMARY KEY CLUSTERED ([RowID] ASC)
);

