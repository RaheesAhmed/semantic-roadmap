CREATE TABLE [dbo].[eComplaintFollow] (
    [RowID]           BIGINT          NOT NULL,
    [wComplaintRid]   BIGINT          NOT NULL,
    [wTranDt]         DATETIME2 (7)   NOT NULL,
    [wFollowBy]       BIGINT          NOT NULL,
    [wFollowDeptCd]   VARCHAR (30)    NOT NULL,
    [wContent]        NVARCHAR (2000) NOT NULL,
    [wSolveDt]        DATETIME2 (7)   NULL,
    [wSolveContent]   NVARCHAR (2000) NOT NULL,
    [wPreventContent] NVARCHAR (2000) NOT NULL,
    [wStatus]         CHAR (1)        NOT NULL,
    [wCrtDt]          DATETIME2 (7)   NOT NULL,
    [wCrtBy]          BIGINT          NOT NULL,
    [wUpdDt]          DATETIME2 (7)   NOT NULL,
    [wUpdBy]          BIGINT          NOT NULL,
    CONSTRAINT [PK_eComplaintFollow] PRIMARY KEY CLUSTERED ([RowID] ASC)
);

