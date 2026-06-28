CREATE TABLE [dbo].[mShiftHandover] (
    [RowID]       BIGINT         NOT NULL,
    [wShiftDt]    DATE           NOT NULL,
    [wDepartment] VARCHAR (30)   NOT NULL,
    [wShiftRid]   BIGINT         NOT NULL,
    [wCounterRid] BIGINT         NOT NULL,
    [wStatus]     CHAR (1)       NOT NULL,
    [wRemark]     NVARCHAR (500) NOT NULL,
    [wSeqNo]      INT            NOT NULL,
    [wCrtDt]      DATETIME2 (7)  NOT NULL,
    [wCrtBy]      BIGINT         NOT NULL,
    [wUpdDt]      DATETIME2 (7)  NOT NULL,
    [wUpdBy]      BIGINT         NOT NULL,
    PRIMARY KEY CLUSTERED ([RowID] ASC)
);

