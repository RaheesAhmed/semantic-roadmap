CREATE TABLE [test].[mItem] (
    [wCategoryRid]  BIGINT         NOT NULL,
    [wCategoryName] NVARCHAR (255) NOT NULL,
    [wItemName]     NVARCHAR (255) NOT NULL,
    [wCurrCode]     VARCHAR (30)   NOT NULL,
    [wIsSerialItem] CHAR (1)       NOT NULL,
    [wStatus]       CHAR (1)       NOT NULL
);

