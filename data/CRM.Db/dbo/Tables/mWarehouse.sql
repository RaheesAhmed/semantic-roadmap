CREATE TABLE [dbo].[mWarehouse] (
    [RowID]           BIGINT         NOT NULL,
    [wDepartmentCode] VARCHAR (30)   NOT NULL,
    [wCName]          NVARCHAR (100) NOT NULL,
    [wEName]          VARCHAR (100)  NOT NULL,
    [wStatus]         CHAR (1)       CONSTRAINT [DF_mWareHouse_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]          DATETIME2 (7)  NOT NULL,
    [wUpdDt]          DATETIME2 (7)  NOT NULL,
    [wCounterRid]     BIGINT         NOT NULL,
    [wIsDefault]      CHAR (1)       NOT NULL,
    CONSTRAINT [PK_mWareHouse] PRIMARY KEY CLUSTERED ([RowID] ASC)
);



