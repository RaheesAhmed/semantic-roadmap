CREATE TABLE [dbo].[mTaskSheetType] (
    [wDepartmentCode] VARCHAR (30)  NOT NULL,
    [wCode]           VARCHAR (30)  NOT NULL,
    [wParentCode]     VARCHAR (30)  NOT NULL,
    [wTitle]          NVARCHAR (50) CONSTRAINT [DF_mTaskSheetType_wName] DEFAULT (N'') NOT NULL,
    [wStatus]         CHAR (1)      CONSTRAINT [DF_mTaskSheetType_wStatus] DEFAULT ('Y') NOT NULL,
    [wCrtDt]          DATETIME2 (7) NOT NULL,
    [wCrtBy]          BIGINT        NOT NULL,
    [wUpdDt]          DATETIME2 (7) NOT NULL,
    [wUpdBy]          BIGINT        NOT NULL,
    CONSTRAINT [PK_mTaskSheetType] PRIMARY KEY CLUSTERED ([wDepartmentCode] ASC, [wCode] ASC)
);

