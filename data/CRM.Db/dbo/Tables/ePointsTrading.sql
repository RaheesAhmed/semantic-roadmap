CREATE TABLE [dbo].[ePointsTrading] (
    [RowID]                BIGINT          NOT NULL,
    [wRequestDt]           DATETIME2 (7)   NOT NULL,
    [wTargetExpiryDate]    DATE            NOT NULL,
    [wTargetAmt]           NUMERIC (18, 4) NOT NULL,
    [wTargetDiscountRatio] NUMERIC (18, 4) NOT NULL,
    [wAmtDone]             NUMERIC (18, 4) NOT NULL,
    [wAgentCodeIn]         VARCHAR (14)    NOT NULL,
    [wPointsType]          VARCHAR (30)    NOT NULL,
    [wTradingType]         VARCHAR (30)    NOT NULL,
    [wTradingStatus]       VARCHAR (30)    NOT NULL,
    [wStatus]              CHAR (1)        NOT NULL,
    [wCrtDt]               DATETIME2 (7)   NOT NULL,
    [wCrtBy]               BIGINT          NOT NULL,
    [wUpdDt]               DATETIME2 (7)   NOT NULL,
    [wUpdBy]               BIGINT          NOT NULL,
    [wOutstandAmt]         NUMERIC (18, 4) DEFAULT ((0.0000)) NOT NULL,
    [wFollowStaffRid]      BIGINT          DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ePointsTradingTran] PRIMARY KEY CLUSTERED ([RowID] ASC)
);




GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'ePointsTrading', @level2type = N'COLUMN', @level2name = N'RowID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'餘額', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'ePointsTrading', @level2type = N'COLUMN', @level2name = N'wOutstandAmt';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'跟單員工', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'ePointsTrading', @level2type = N'COLUMN', @level2name = N'wFollowStaffRid';

