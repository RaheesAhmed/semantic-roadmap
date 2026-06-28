CREATE TABLE [dbo].[mAllotmentGroupDtl] (
    [RowID]              BIGINT        NOT NULL,
    [wAllotmentGroupRid] BIGINT        NOT NULL,
    [wCounterRid]        BIGINT        NOT NULL,
    [wStatus]            CHAR (1)      NOT NULL,
    [wCrtDt]             DATETIME2 (7) NOT NULL,
    [wCrtBy]             BIGINT        NOT NULL,
    [wUpdDt]             DATETIME2 (7) NOT NULL,
    [wUpdBy]             BIGINT        NOT NULL,
    CONSTRAINT [PK_mAllotmentGroupDtl] PRIMARY KEY CLUSTERED ([RowID] ASC),
    CONSTRAINT [FK_mAllotmentGroupDtl_mAllotmentGroup] FOREIGN KEY ([wAllotmentGroupRid]) REFERENCES [dbo].[mAllotmentGroup] ([RowID])
);

