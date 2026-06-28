CREATE TABLE [dbo].[eUnqualified] (
    [RowID]              BIGINT         NOT NULL,
    [wAgentCodeIn]       VARCHAR (14)   NOT NULL,
    [wDeptCd]            VARCHAR (30)   NOT NULL,
    [wCompNo]            INT            NOT NULL,
    [wUnqualifiedType]   VARCHAR (30)   NOT NULL,
    [wUnqualifiedStatus] VARCHAR (30)   NOT NULL,
    [wReason]            VARCHAR (30)   NOT NULL,
    [wDetails]           NVARCHAR (500) NOT NULL,
    [wFollowUpDetails]   NVARCHAR (500) NOT NULL,
    [wStatus]            CHAR (1)       NOT NULL,
    [wCrtDt]             DATETIME2 (7)  NOT NULL,
    [wCrtBy]             BIGINT         NOT NULL,
    [wUpdDt]             DATETIME2 (7)  NOT NULL,
    [wUpdBy]             BIGINT         NOT NULL,
    [wCounterRid]        BIGINT         CONSTRAINT [DF_eUnqualified_wCounterRid_1] DEFAULT ((0)) NOT NULL,
    [wBookingRid]        BIGINT         CONSTRAINT [DF_eUnqualified_wBookingRid] DEFAULT ((-1)) NOT NULL,
    [wBookingType]       VARCHAR (30)   DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_eUnqualified] PRIMARY KEY CLUSTERED ([RowID] ASC)
);








GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'預訂類型', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eUnqualified', @level2type = N'COLUMN', @level2name = N'wBookingType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'相關的預訂記錄', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eUnqualified', @level2type = N'COLUMN', @level2name = N'wBookingRid';

