CREATE TABLE [dbo].[mSpa] (
    [RowID]      BIGINT         NOT NULL,
    [wName]      NVARCHAR (100) NOT NULL,
    [wPhone]     VARCHAR (50)   NULL,
    [wHotelRid]  BIGINT         NULL,
    [wAddress]   NVARCHAR (300) NOT NULL,
    [wWorkHours] NVARCHAR (400) NOT NULL,
    [wRemark]    NVARCHAR (500) NOT NULL,
    [wStatus]    CHAR (1)       NOT NULL,
    [wSeqNo]     INT            NOT NULL,
    [wCrtDt]     DATETIME2 (7)  NOT NULL,
    [wCrtBy]     BIGINT         NOT NULL,
    [wUpdDt]     DATETIME2 (7)  NOT NULL,
    [wUpdBy]     BIGINT         NOT NULL,
    PRIMARY KEY CLUSTERED ([RowID] ASC)
);





