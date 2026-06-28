CREATE TABLE [dbo].[eTravelAgencyInvoice] (
    [RowID]            BIGINT         NOT NULL,
    [wHotelBookingRid] BIGINT         NOT NULL,
    [wInvoiceNo]       VARCHAR (50)   NOT NULL,
    [wTravelAgencyRid] BIGINT         NOT NULL,
    [wStatus]          CHAR (1)       NOT NULL,
    [wCrtBy]           BIGINT         NOT NULL,
    [wCrtDt]           DATETIME       NOT NULL,
    [wUpdDt]           DATETIME       NOT NULL,
    [wUpdBy]           BIGINT         NOT NULL,
    [wHotelRid]        BIGINT         NOT NULL,
    [wStartDate]       DATETIME2 (7)  NOT NULL,
    [wEndDate]         DATETIME2 (7)  NOT NULL,
    [wDayOfStay]       INT            NOT NULL,
    [wNumberOfRoom]    INT            NOT NULL,
    [wRemark]          NVARCHAR (500) NOT NULL,
    [wBedType]         VARCHAR (30)   NOT NULL,
    [wPersonName]      NVARCHAR (200) NOT NULL,
    [wAgentCode]       VARCHAR (100)  NOT NULL,
    CONSTRAINT [PK_eTravelAgencyInvoice] PRIMARY KEY CLUSTERED ([RowID] ASC)
);






GO



GO
CREATE NONCLUSTERED INDEX [PI_eTravelAgencyInvoice_01]
    ON [dbo].[eTravelAgencyInvoice]([wHotelBookingRid] ASC);

