CREATE TABLE [dbo].[eComplaintActionLog] (
    [RowID]                BIGINT          NOT NULL,
    [wComplaintRid]        BIGINT          NOT NULL,
    [wTranDt]              DATETIME2 (7)   NOT NULL,
    [wRefNo]               VARCHAR (30)    NOT NULL,
    [wAgentCodeIn]         VARCHAR (14)    NOT NULL,
    [wComplainantName]     NVARCHAR (50)   NOT NULL,
    [wPersonRid]           BIGINT          NOT NULL,
    [wComplainantNickname] NVARCHAR (50)   NOT NULL,
    [wComplainantTitle]    NVARCHAR (30)   NOT NULL,
    [wComplainantTel]      VARCHAR (100)   NOT NULL,
    [wType]                VARCHAR (30)    NOT NULL,
    [wChannel]             VARCHAR (30)    NOT NULL,
    [wReceivedBy]          BIGINT          NOT NULL,
    [wReceivedDeptCd]      VARCHAR (30)    NOT NULL,
    [wReceivedLocation]    NVARCHAR (30)   NOT NULL,
    [wComplainBy]          BIGINT          NOT NULL,
    [wComplainDeptCd]      VARCHAR (30)    NOT NULL,
    [wComplainLocation]    NVARCHAR (30)   NOT NULL,
    [wComplainCompNo]      INT             NOT NULL,
    [wContent]             NVARCHAR (2000) NOT NULL,
    [wCancelRemark]        NVARCHAR (500)  NOT NULL,
    [wIntroduction]        NVARCHAR (2000) NOT NULL,
    [wDealDt]              DATETIME2 (7)   NOT NULL,
    [wComplaintStatus]     VARCHAR (30)    NOT NULL,
    [wStatus]              CHAR (1)        NOT NULL,
    [wCrtDt]               DATETIME2 (7)   NOT NULL,
    [wCrtBy]               BIGINT          NOT NULL,
    [wUpdDt]               DATETIME2 (7)   NOT NULL,
    [wUpdBy]               BIGINT          NOT NULL,
    [wRecStatus]           CHAR (1)        NOT NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Log記錄是否有效', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eComplaintActionLog', @level2type = N'COLUMN', @level2name = N'wRecStatus';

