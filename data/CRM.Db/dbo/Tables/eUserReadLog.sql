CREATE TABLE [dbo].[eUserReadLog] (
    [wADAccount]    VARCHAR (40)  NOT NULL,
    [wTable]        VARCHAR (255) NOT NULL,
    [wTableRid]     BIGINT        NOT NULL,
    [wLatestLogRid] BIGINT        NULL,
    [wLatestDt]     DATETIME2 (7) NULL,
    CONSTRAINT [PK__eUserRea__9177B9AC152875F5] PRIMARY KEY CLUSTERED ([wADAccount] ASC, [wTable] ASC, [wTableRid] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'最近一次Read record''s datetime', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eUserReadLog', @level2type = N'COLUMN', @level2name = N'wLatestDt';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'最近一次Read record action log''s rowid ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eUserReadLog', @level2type = N'COLUMN', @level2name = N'wLatestLogRid';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'RollsMary.dbo.mAgent.wADAccount', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eUserReadLog', @level2type = N'COLUMN', @level2name = N'wADAccount';

