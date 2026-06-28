CREATE TABLE [dbo].[eTaskSheetSummary] (
    [wRelatedType]      VARCHAR (30)  NOT NULL,
    [wRelatedRid]       BIGINT        NOT NULL,
    [wLatestFollowUpBy] BIGINT        NULL,
    [wLatestFollowUpDt] DATETIME2 (7) NULL,
    [wLatestUpdBy]      BIGINT        NOT NULL,
    [wLatestUpdDt]      DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_eTaskSheetSummary_1] PRIMARY KEY CLUSTERED ([wRelatedType] ASC, [wRelatedRid] ASC)
);



