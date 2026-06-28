CREATE TABLE [dbo].[mDepartmentTeam] (
    [RowID]       BIGINT        NOT NULL,
    [wCode]       VARCHAR (10)  NOT NULL,
    [wName]       NVARCHAR (20) NOT NULL,
    [wDepartment] VARCHAR (20)  NOT NULL,
    [wRegion]     VARCHAR (20)  NOT NULL,
    [wStatus]     CHAR (1)      NOT NULL,
    [wSeqNo]      INT           NOT NULL,
    [wCrtDt]      DATETIME2 (7) NOT NULL,
    [wCrtBy]      BIGINT        NOT NULL,
    [wUpdDt]      DATETIME2 (7) NOT NULL,
    [wUpdBy]      BIGINT        NOT NULL,
    CONSTRAINT [PK_mDepartmentTeam] PRIMARY KEY CLUSTERED ([RowID] ASC) ON [PRIMARY]
);




GO



GO


