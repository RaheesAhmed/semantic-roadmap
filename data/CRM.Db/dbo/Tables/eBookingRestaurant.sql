CREATE TABLE [dbo].[eBookingRestaurant] (
    [RowID]            BIGINT          NOT NULL,
    [wBookingRid]      BIGINT          NOT NULL,
    [wRestaurantRid]   BIGINT          NOT NULL,
    [wNoOfPpl]         INT             NOT NULL,
    [wBookingDt]       DATETIME2 (7)   NOT NULL,
    [wDiningArea]      VARCHAR (30)    CONSTRAINT [DF_eBookingRestaurant_wDiningArea] DEFAULT ('') NOT NULL,
    [wRemark]          NVARCHAR (500)  NOT NULL,
    [wStatus]          CHAR (1)        CONSTRAINT [DF_eBookingRestaurant_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtBy]           BIGINT          NOT NULL,
    [wCrtDt]           DATETIME2 (7)   NOT NULL,
    [wUpdDt]           DATETIME2 (7)   NOT NULL,
    [wUpdBy]           BIGINT          NOT NULL,
    [wReserveName]     NVARCHAR (100)  CONSTRAINT [DF_eBookingRestaurant_wReserveName_1] DEFAULT ('') NOT NULL,
    [wReservePhoneNo]  VARCHAR (50)    CONSTRAINT [DF_eBookingRestaurant_wReservePhoneNo_1] DEFAULT ('') NOT NULL,
    [wIsMinCharge]     CHAR (1)        CONSTRAINT [DF_eBookingRestaurant_wIsMinCharge_1] DEFAULT ('N') NOT NULL,
    [wMinCharge]       DECIMAL (18, 2) CONSTRAINT [DF_eBookingRestaurant_wMinCharge_1] DEFAULT ((0)) NOT NULL,
    [wBookingStatus]   VARCHAR (5)     CONSTRAINT [DF_eBookingRestaurant_wBookingStatus] DEFAULT ('P') NOT NULL,
    [wAdditionalExp]   NUMERIC (18, 4) CONSTRAINT [DF_eBookingRestaurant_wAdditionalExp] DEFAULT ('0') NOT NULL,
    [wAcceptBTM]       CHAR (1)        CONSTRAINT [DF_eBookingRestaurant_wAcceptBTM] DEFAULT ('N') NOT NULL,
    [wUnqualifiedRid]  BIGINT          CONSTRAINT [DF_eBookingRestaurant_wUnqualifiedRid] DEFAULT ((0)) NOT NULL,
    [wTravelAgencyRid] BIGINT          DEFAULT ((-1)) NOT NULL,
    [wCurrCode]        VARCHAR (6)     DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_eRestaurantBooking] PRIMARY KEY CLUSTERED ([RowID] ASC),
    CONSTRAINT [FK_eRestaurantBooking_eBooking] FOREIGN KEY ([wBookingRid]) REFERENCES [dbo].[eBooking] ([RowID])
);














GO
CREATE NONCLUSTERED INDEX [PI_eBookingRestaurant_01]
    ON [dbo].[eBookingRestaurant]([wBookingRid] ASC);

