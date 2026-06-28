CREATE TABLE [dbo].[ePointsTradingHistory] (
    [RowID]             BIGINT          NOT NULL,
    [wPointsTradingRid] BIGINT          NOT NULL,
    [wAgentCodeIn]      VARCHAR (14)    NOT NULL,
    [wPointsType]       VARCHAR (30)    NOT NULL,
    [wTradingType]      VARCHAR (30)    NOT NULL,
    [wDiscountRatio]    NUMERIC (18, 4) NOT NULL,
    [wPoint]            NUMERIC (18, 4) NOT NULL,
    [wTradingDate]      DATE            NOT NULL,
    [wCurrCode]         VARCHAR (3)     NOT NULL,
    [wMoneyAmt]         NUMERIC (18, 4) NOT NULL,
    [wProfit]           NUMERIC (18, 4) NOT NULL,
    [wPaymentStatus]    VARCHAR (30)    NOT NULL,
    [wRemark]           NVARCHAR (200)  CONSTRAINT [DF_ePointsTradingHistory_wRemark] DEFAULT ('') NOT NULL,
    [wStatus]           CHAR (1)        NOT NULL,
    [wCrtDt]            DATETIME2 (7)   NOT NULL,
    [wCrtBy]            BIGINT          NOT NULL,
    [wUpdDt]            DATETIME2 (7)   NOT NULL,
    [wUpdBy]            BIGINT          NOT NULL,
    [wDelReason]        NVARCHAR (500)  NULL,
    [wPaymentTime]      DATETIME2 (7)   NULL,
    CONSTRAINT [PK_ePointsTradingHistory] PRIMARY KEY CLUSTERED ([RowID] ASC)
);






GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'刪除原因', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'ePointsTradingHistory', @level2type = N'COLUMN', @level2name = N'wDelReason';

