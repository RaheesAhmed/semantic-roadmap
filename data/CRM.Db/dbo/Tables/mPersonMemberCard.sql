CREATE TABLE [dbo].[mPersonMemberCard] (
    [RowID]       BIGINT         NOT NULL,
    [wPersonRID]  BIGINT         NOT NULL,
    [wCardType]   NVARCHAR (50)  CONSTRAINT [DF_mPersonMemberCard_wCardType] DEFAULT ('') NOT NULL,
    [wCardNo]     NVARCHAR (50)  CONSTRAINT [DF_mPersonMemberCard_wCardNo] DEFAULT ('') NOT NULL,
    [wExpiryDate] DATE           NULL,
    [wRemark]     NVARCHAR (500) NOT NULL,
    [wStatus]     CHAR (1)       NOT NULL,
    [wCrtDt]      DATETIME2 (7)  NOT NULL,
    [wCrtBy]      BIGINT         NOT NULL,
    [wUpdDt]      DATETIME2 (7)  NOT NULL,
    [wUpdBy]      BIGINT         NOT NULL,
    CONSTRAINT [PK_mPersonMemberCard] PRIMARY KEY CLUSTERED ([RowID] ASC)
);







