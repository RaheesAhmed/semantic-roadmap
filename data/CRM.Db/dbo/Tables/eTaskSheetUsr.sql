CREATE TABLE [dbo].[eTaskSheetUsr] (
    [RowID]         BIGINT         NOT NULL,
    [wTaskSheetRid] BIGINT         NOT NULL,
    [wUsrRid]       BIGINT         NOT NULL,
    [wStatus]       CHAR (1)       NOT NULL,
    [wDeptCd]       VARCHAR (30)   NOT NULL,
    [wRemark]       NVARCHAR (500) NULL,
    [wCrtDt]        DATETIME2 (7)  NOT NULL,
    [wCrtBy]        BIGINT         NOT NULL,
    [wUpdDt]        DATETIME2 (7)  NOT NULL,
    [wUpdBy]        BIGINT         NOT NULL
);

