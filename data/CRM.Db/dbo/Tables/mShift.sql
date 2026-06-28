CREATE TABLE [dbo].[mShift] (
    [RowID]         BIGINT        NOT NULL,
    [wName]         NVARCHAR (50) NOT NULL,
    [wCode]         VARCHAR (10)  NOT NULL,
    [wDepartmentCd] VARCHAR (30)  CONSTRAINT [DF_mShift_wDepartmentCd] DEFAULT ('') NOT NULL,
    [wStatus]       CHAR (1)      NOT NULL,
    [wSeqNo]        INT           CONSTRAINT [DF_mShift_wSeqNo] DEFAULT ((1)) NOT NULL,
    [wCrtDt]        DATETIME2 (7) NOT NULL,
    [wCrtBy]        BIGINT        NOT NULL,
    [wUpdDt]        DATETIME2 (7) NOT NULL,
    [wUpdBy]        BIGINT        NOT NULL,
    CONSTRAINT [PK_mShift] PRIMARY KEY CLUSTERED ([RowID] ASC)
);








GO


