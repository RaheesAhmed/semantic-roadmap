CREATE TABLE [dbo].[eUserReadMessage] (
    [RowID]          BIGINT NOT NULL,
    [wUserRid]       BIGINT NULL,
    [wRequestRid]    BIGINT NULL,
    [wLastMessageId] BIGINT NULL,
    PRIMARY KEY CLUSTERED ([RowID] ASC)
);

