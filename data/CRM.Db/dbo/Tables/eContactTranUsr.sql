CREATE TABLE [dbo].[eContactTranUsr] (
    [RowID]           BIGINT        NOT NULL,
    [wContactTranRid] BIGINT        NOT NULL,
    [wUsrRid]         BIGINT        NOT NULL,
    [wStatus]         CHAR (1)      NOT NULL,
    [wDeptCd]         VARCHAR (30)  NOT NULL,
    [wCrtDt]          DATETIME2 (7) NOT NULL,
    [wCrtBy]          BIGINT        NOT NULL,
    [wUpdDt]          DATETIME2 (7) NOT NULL,
    [wUpdBy]          BIGINT        NOT NULL,
    CONSTRAINT [PK_eContactTranUsr] PRIMARY KEY CLUSTERED ([RowID] ASC)
);

