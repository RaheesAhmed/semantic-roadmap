CREATE TABLE [dbo].[eBirthdayGift] (
    [RowID]            BIGINT          NOT NULL,
    [wBirthdayRid]     BIGINT          NOT NULL,
    [wGiftReason]      NVARCHAR (500)  NULL,
    [wGiftDescription] NVARCHAR (50)   NULL,
    [wBudgetCurrency]  VARCHAR (10)    NULL,
    [wBudgetAmt]       NUMERIC (18, 4) NULL,
    [wCostCurrency]    VARCHAR (10)    NULL,
    [wCostAmt]         NUMERIC (18, 4) NULL,
    [wContactWay]      VARCHAR (30)    NULL,
    [wTelNumber]       NVARCHAR (150)  NULL,
    [wWhatsappNumber]  NVARCHAR (100)  NULL,
    [wWeChatNumber]    NVARCHAR (100)  NULL,
    [wWeChatName]      NVARCHAR (100)  NULL,
    [wRemark]          NVARCHAR (4000) NULL,
    [wSource]          VARCHAR (10)    NULL,
    [wStatus]          CHAR (1)        NOT NULL,
    [wCrtBy]           BIGINT          NOT NULL,
    [wCrtDt]           DATETIME2 (7)   NOT NULL,
    [wUpdBy]           BIGINT          NOT NULL,
    [wUpdDt]           DATETIME2 (7)   NOT NULL,
    CONSTRAINT [PK__eBirthda__FFEE745170D83626] PRIMARY KEY CLUSTERED ([RowID] ASC)
);

