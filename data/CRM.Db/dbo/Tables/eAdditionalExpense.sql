CREATE TABLE [dbo].[eAdditionalExpense] (
    [RowID]            BIGINT          NOT NULL,
    [wOrderNo]         NVARCHAR (20)   NOT NULL,
    [wBookingRid]      BIGINT          NOT NULL,
    [wRoomBookingRid]  BIGINT          CONSTRAINT [DF_eAdditionalExpenses_wRoomBookingRid] DEFAULT ((-1)) NOT NULL,
    [wExpenseType]     BIGINT          NOT NULL,
    [wExpenseSubtype]  BIGINT          NOT NULL,
    [wPaymentMethod]   VARCHAR (30)    NOT NULL,
    [wReceiptNo]       NVARCHAR (50)   CONSTRAINT [DF_eAdditionalExpenses_wReceiptNo] DEFAULT ('') NOT NULL,
    [wExpAmt]          NUMERIC (18, 4) NOT NULL,
    [wTotalAmt]        NUMERIC (18, 4) NOT NULL,
    [wCost]            NUMERIC (18, 4) NOT NULL,
    [wCurrcode]        VARCHAR (30)    NOT NULL,
    [wIsUseBlackCard]  CHAR (1)        NOT NULL,
    [wRemark]          NVARCHAR (500)  NOT NULL,
    [wSeqNo]           INT             NOT NULL,
    [wCrtDt]           DATETIME2 (7)   NOT NULL,
    [wCrtBy]           BIGINT          NOT NULL,
    [wUpdDt]           DATETIME2 (7)   NOT NULL,
    [wUpdBy]           BIGINT          NOT NULL,
    [wBookingStatus]   VARCHAR (5)     CONSTRAINT [DF_eAdditionalExpense_wBookingStatus] DEFAULT ('P') NOT NULL,
    [wStatus]          CHAR (1)        CONSTRAINT [DF_eAdditionalExpense_wStatus] DEFAULT ('A') NOT NULL,
    [wBookingRefRid]   BIGINT          NOT NULL,
    [wSpaRid]          BIGINT          CONSTRAINT [DF_eAdditionalExpenses_wSpaRid] DEFAULT ((-1)) NOT NULL,
    [wRestaurantRid]   BIGINT          CONSTRAINT [DF_eAdditionalExpenses_wRestaurantRid] DEFAULT ((-1)) NOT NULL,
    [wTravelAgencyRid] BIGINT          CONSTRAINT [DF_eAdditionalExpense_wTravelAgencyRid] DEFAULT ('0') NOT NULL,
    [wUnqualifiedRid]  BIGINT          CONSTRAINT [DF_eAdditionalExpense_wUnqualifiedRid] DEFAULT ((0)) NOT NULL,
    [wPersonRid]       VARCHAR (1000)  NOT NULL,
    CONSTRAINT [PK_eAdditionalExpenses] PRIMARY KEY CLUSTERED ([RowID] ASC)
);


















GO
CREATE NONCLUSTERED INDEX [PI_eAdditionalExpense_02]
    ON [dbo].[eAdditionalExpense]([wBookingRid] ASC, [wExpenseType] ASC, [wBookingStatus] ASC);


GO
CREATE NONCLUSTERED INDEX [PI_eAdditionalExpense_01]
    ON [dbo].[eAdditionalExpense]([wBookingRefRid] ASC)
    INCLUDE([RowID]);


GO
CREATE NONCLUSTERED INDEX [PI_eAdditionalExpense_04]
    ON [dbo].[eAdditionalExpense]([wRoomBookingRid] ASC, [wStatus] ASC)
    INCLUDE([RowID], [wBookingRefRid], [wBookingRid], [wBookingStatus], [wCost], [wCrtBy], [wCrtDt], [wCurrcode], [wExpAmt], [wExpenseSubtype], [wExpenseType], [wIsUseBlackCard], [wOrderNo], [wPaymentMethod], [wReceiptNo], [wRemark], [wRestaurantRid], [wSeqNo], [wSpaRid], [wTotalAmt], [wTravelAgencyRid], [wUpdBy], [wUpdDt]);


GO
CREATE NONCLUSTERED INDEX [PI_eAdditionalExpense_03]
    ON [dbo].[eAdditionalExpense]([wRoomBookingRid] ASC, [wStatus] ASC)
    INCLUDE([wBookingStatus], [wExpenseType], [wPaymentMethod]);

