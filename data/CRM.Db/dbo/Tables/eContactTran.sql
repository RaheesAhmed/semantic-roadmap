CREATE TABLE [dbo].[eContactTran] (
    [RowID]              BIGINT          NOT NULL,
    [wCompNo]            INT             NOT NULL,
    [wRefNo]             VARCHAR (30)    NOT NULL,
    [wLocation]          NVARCHAR (50)   CONSTRAINT [DF_eContactTran_wLocation] DEFAULT (N'') NOT NULL,
    [wDeptCd]            VARCHAR (30)    CONSTRAINT [DF_eContactTran_wDeptCd] DEFAULT ('') NOT NULL,
    [wCategoryCd]        VARCHAR (100)   NOT NULL,
    [wSubCategoryCd]     VARCHAR (100)   DEFAULT ('') NOT NULL,
    [wExpAmount]         NUMERIC (18, 4) CONSTRAINT [DF_eContactTran_wExpAmount] DEFAULT ((0)) NOT NULL,
    [wExpAmountCurrCode] VARCHAR (3)     NOT NULL,
    [wDateFrom]          DATETIME2 (7)   NOT NULL,
    [wDateTo]            DATETIME2 (7)   NOT NULL,
    [wIsFullDay]         CHAR (1)        CONSTRAINT [DF_eContactTran_wIsFullDay] DEFAULT ('N') NOT NULL,
    [wContactStatus]     VARCHAR (20)    NOT NULL,
    [wRemark]            NVARCHAR (4000) CONSTRAINT [DF_eContactTran_wCancelRemark] DEFAULT ('') NOT NULL,
    [wStatus]            CHAR (1)        CONSTRAINT [DF_eContactTran_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]             DATETIME2 (7)   NOT NULL,
    [wCrtBy]             BIGINT          NOT NULL,
    [wUpdDt]             DATETIME2 (7)   NOT NULL,
    [wUpdBy]             BIGINT          NOT NULL,
    [wContactTypeName]   NVARCHAR (100)  CONSTRAINT [DF_eContactTran_wContactTypeName] DEFAULT ('') NOT NULL,
    [wReason]            NVARCHAR (200)  CONSTRAINT [DF_eContactTran_wReason] DEFAULT ('') NOT NULL,
    [wPurpose]           VARCHAR (30)    CONSTRAINT [DF_eContactTran_wPurpose] DEFAULT ('') NOT NULL,
    [wAdviceRid]         BIGINT          CONSTRAINT [DF_eContactTran_wAdviceRid] DEFAULT ((0)) NOT NULL,
    [wPeriod]            VARCHAR (30)    CONSTRAINT [DF_eContactTran_wPeriod] DEFAULT ('') NOT NULL,
    [wApprover]          BIGINT          CONSTRAINT [DF_eContactTran_wApprover] DEFAULT ((0)) NOT NULL,
    [wRegion]            VARCHAR (30)    CONSTRAINT [DF_eContactTran_wRegion] DEFAULT ('') NOT NULL,
    [wAssistantDt]       DATETIME2 (7)   NULL,
    [wApproverDt]        DATETIME2 (7)   NULL,
    CONSTRAINT [PK_eContactTran] PRIMARY KEY CLUSTERED ([RowID] ASC)
);


















GO



GO



GO



GO



GO



GO



GO



GO



GO



GO



GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'地區', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eContactTran', @level2type = N'COLUMN', @level2name = N'wRegion';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'應酬原因', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eContactTran', @level2type = N'COLUMN', @level2name = N'wReason';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'效益', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eContactTran', @level2type = N'COLUMN', @level2name = N'wPurpose';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'時段', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eContactTran', @level2type = N'COLUMN', @level2name = N'wPeriod';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'助理交報告日期', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eContactTran', @level2type = N'COLUMN', @level2name = N'wAssistantDt';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'經理交報告日期', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eContactTran', @level2type = N'COLUMN', @level2name = N'wApproverDt';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'批准經理', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eContactTran', @level2type = N'COLUMN', @level2name = N'wApprover';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'意見需求編號', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eContactTran', @level2type = N'COLUMN', @level2name = N'wAdviceRid';


GO
CREATE NONCLUSTERED INDEX [IdxNC_eContactTran_wUpdDt]
    ON [dbo].[eContactTran]([wUpdDt] ASC);

