CREATE TABLE [dbo].[eBookingTravelPackage] (
    [RowID]             BIGINT          NOT NULL,
    [wBookingRid]       BIGINT          NOT NULL,
    [wStartDt]          DATETIME2 (7)   NOT NULL,
    [wEndDt]            DATETIME2 (7)   NOT NULL,
    [wDeptCd]           VARCHAR (30)    NOT NULL,
    [wDestCd]           VARCHAR (10)    NOT NULL,
    [wPkgTypeCd]        VARCHAR (30)    NOT NULL,
    [wPaymentMethod]    VARCHAR (30)    NOT NULL,
    [wCurrCode]         VARCHAR (6)     NOT NULL,
    [wExpAmt]           NUMERIC (18, 4) NOT NULL,
    [wTotalAmt]         NUMERIC (18, 4) NOT NULL,
    [wTotalCost]        NUMERIC (18, 4) NOT NULL,
    [wRemark]           NVARCHAR (500)  NOT NULL,
    [wBookingStatus]    VARCHAR (5)     NOT NULL,
    [wReceiptNo]        NVARCHAR (50)   CONSTRAINT [DF_eBookingTravelPackage_wReceiptNo] DEFAULT ('') NOT NULL,
    [wSeqNo]            INT             NOT NULL,
    [wCrtDt]            DATETIME2 (7)   NOT NULL,
    [wCrtBy]            BIGINT          NOT NULL,
    [wUpdDt]            DATETIME2 (7)   NOT NULL,
    [wUpdBy]            BIGINT          NOT NULL,
    [wUnqualifiedRid]   BIGINT          CONSTRAINT [DF_eBookingTravelPackage_wUnqualifiedRid] DEFAULT ((0)) NOT NULL,
    [wStatus]           CHAR (1)        CONSTRAINT [DF_eBookingTravelPackage_wStatus] DEFAULT ('A') NOT NULL,
    [wTravelAgencyRid]  BIGINT          DEFAULT ((-1)) NOT NULL,
    [wOrderNo]          NVARCHAR (30)   NULL,
    [wTravelPkgTypeRid] BIGINT          NULL,
    CONSTRAINT [PK_eBookingTravelPackage] PRIMARY KEY CLUSTERED ([RowID] ASC)
);















