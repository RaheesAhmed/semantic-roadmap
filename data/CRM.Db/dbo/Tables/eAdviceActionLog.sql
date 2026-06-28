CREATE TABLE [dbo].[eAdviceActionLog] (
    [RowID]           BIGINT          NOT NULL,
    [wAdviceRid]      BIGINT          NOT NULL,
    [wAim]            NVARCHAR (200)  NOT NULL,
    [wDate]           DATE            NOT NULL,
    [wAgentCodeIn]    VARCHAR (14)    NOT NULL,
    [wReceivedBy]     BIGINT          NOT NULL,
    [wReceivedDeptCd] VARCHAR (30)    NOT NULL,
    [wType]           VARCHAR (30)    NOT NULL,
    [wSubType]        VARCHAR (30)    NOT NULL,
    [wContent]        NVARCHAR (2000) NOT NULL,
    [wIsHighPriority] CHAR (1)        NOT NULL,
    [wRefNo]          VARCHAR (30)    NOT NULL,
    [wDealDt]         DATETIME2 (7)   NOT NULL,
    [wAdviceStatus]   VARCHAR (20)    NOT NULL,
    [wStatus]         CHAR (1)        NOT NULL,
    [wCrtDt]          DATETIME2 (7)   NOT NULL,
    [wCrtBy]          BIGINT          NOT NULL,
    [wUpdDt]          DATETIME2 (7)   NOT NULL,
    [wUpdBy]          BIGINT          NOT NULL,
    [wRecStatus]      CHAR (1)        NOT NULL,
    PRIMARY KEY CLUSTERED ([RowID] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Log記錄是否有效', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eAdviceActionLog', @level2type = N'COLUMN', @level2name = N'wRecStatus';

