CREATE TABLE [dbo].[eVisaCollection] (
    [RowID]         BIGINT         NOT NULL,
    [wBookingRid]   BIGINT         NOT NULL,
    [wTicCollPoint] VARCHAR (10)   NULL,
    [wIsCollected]  VARCHAR (10)   NULL,
    [wCollDate]     DATETIME2 (7)  NULL,
    [wCollStaff]    NVARCHAR (64)  NULL,
    [wCollRemark]   NVARCHAR (500) NULL,
    [wSeqNo]        INT            NULL,
    [wCrtBy]        BIGINT         NOT NULL,
    [wCrtDt]        DATETIME       NOT NULL,
    [wUpdDt]        DATETIME       NOT NULL,
    [wUpdBy]        BIGINT         NOT NULL
);



