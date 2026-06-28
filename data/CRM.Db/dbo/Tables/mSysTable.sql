CREATE TABLE [dbo].[mSysTable] (
    [wCompNo] INT             NOT NULL,
    [wType]   VARCHAR (10)    NOT NULL,
    [wCode]   VARCHAR (50)    NOT NULL,
    [wValue]  NVARCHAR (1000) NOT NULL,
    [wDesc]   NVARCHAR (1000) NULL,
    PRIMARY KEY CLUSTERED ([wCompNo] ASC, [wType] ASC, [wCode] ASC)
);

