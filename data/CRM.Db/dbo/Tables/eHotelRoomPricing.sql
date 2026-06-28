CREATE TABLE [dbo].[eHotelRoomPricing] (
    [RowID]              BIGINT          NOT NULL,
    [wHotelRoomRid]      BIGINT          NOT NULL,
    [wIsSpecialDate]     CHAR (1)        CONSTRAINT [DF_eHotelRoomPricing_wIsSpecialDate] DEFAULT ('N') NOT NULL,
    [wStartDate]         DATE            NOT NULL,
    [wEndDate]           DATE            NULL,
    [wCurrCode]          VARCHAR (6)     NOT NULL,
    [wSunRoomPrice]      NUMERIC (18, 4) CONSTRAINT [DF_eHotelRoomPricing_wSunRoomPrice] DEFAULT ((0)) NOT NULL,
    [wMonRoomPrice]      NUMERIC (18, 4) CONSTRAINT [DF_eHotelRoomPricing_wMonRoomPrice] DEFAULT ((0)) NOT NULL,
    [wTueRoomPrice]      NUMERIC (18, 4) CONSTRAINT [DF_eHotelRoomPricing_wTueRoomPrice] DEFAULT ((0)) NOT NULL,
    [wWedRoomPrice]      NUMERIC (18, 4) CONSTRAINT [DF_eHotelRoomPricing_wWedRoomPrice] DEFAULT ((0)) NOT NULL,
    [wThuRoomPrice]      NUMERIC (18, 4) CONSTRAINT [DF_eHotelRoomPricing_wThuRoomPrice] DEFAULT ((0)) NOT NULL,
    [wFriRoomPrice]      NUMERIC (18, 4) CONSTRAINT [DF_eHotelRoomPricing_wFriRoomPrice] DEFAULT ((0)) NOT NULL,
    [wSatRoomPrice]      NUMERIC (18, 4) CONSTRAINT [DF_eHotelRoomPricing_wSatRoomPrice] DEFAULT ((0)) NOT NULL,
    [wSunRoomCost]       NUMERIC (18, 4) CONSTRAINT [DF_Table1_wSunRoomPrice1_1] DEFAULT ((0)) NOT NULL,
    [wMonRoomCost]       NUMERIC (18, 4) CONSTRAINT [DF_Table1_wMonRoomPrice1_1] DEFAULT ((0)) NOT NULL,
    [wTueRoomCost]       NUMERIC (18, 4) CONSTRAINT [DF_Table1_wTueRoomPrice1_1] DEFAULT ((0)) NOT NULL,
    [wWedRoomCost]       NUMERIC (18, 4) CONSTRAINT [DF_Table1_wWedRoomPrice1_1] DEFAULT ((0)) NOT NULL,
    [wThuRoomCost]       NUMERIC (18, 4) CONSTRAINT [DF_Table1_wThuRoomPrice1_1] DEFAULT ((0)) NOT NULL,
    [wFriRoomCost]       NUMERIC (18, 4) CONSTRAINT [DF_Table1_wFriRoomPrice1_1] DEFAULT ((0)) NOT NULL,
    [wSatRoomCost]       NUMERIC (18, 4) CONSTRAINT [DF_Table1_wSatRoomPrice1_1] DEFAULT ((0)) NOT NULL,
    [wSunBreakfastPrice] NUMERIC (18, 4) CONSTRAINT [DF_Table1_wSunRoomPrice1] DEFAULT ((0)) NOT NULL,
    [wMonBreakfastPrice] NUMERIC (18, 4) CONSTRAINT [DF_Table1_wMonRoomPrice1] DEFAULT ((0)) NOT NULL,
    [wTueBreakfastPrice] NUMERIC (18, 4) CONSTRAINT [DF_Table1_wTueRoomPrice1] DEFAULT ((0)) NOT NULL,
    [wWedBreakfastPrice] NUMERIC (18, 4) CONSTRAINT [DF_Table1_wWedRoomPrice1] DEFAULT ((0)) NOT NULL,
    [wThuBreakfastPrice] NUMERIC (18, 4) CONSTRAINT [DF_Table1_wThuRoomPrice1] DEFAULT ((0)) NOT NULL,
    [wFriBreakfastPrice] NUMERIC (18, 4) CONSTRAINT [DF_Table1_wFriRoomPrice1] DEFAULT ((0)) NOT NULL,
    [wSatBreakfastPrice] NUMERIC (18, 4) CONSTRAINT [DF_Table1_wSatRoomPrice1] DEFAULT ((0)) NOT NULL,
    [wSeqNo]             INT             CONSTRAINT [DF_eHotelRoomPricing_wSeqNo] DEFAULT ((1)) NOT NULL,
    [wCrtDt]             DATETIME2 (7)   NOT NULL,
    [wCrtBy]             BIGINT          NOT NULL,
    [wUpdDt]             DATETIME2 (7)   NOT NULL,
    [wUpdBy]             BIGINT          NOT NULL,
    [wStatus]            CHAR (1)        NOT NULL,
    [wMonExtraBedPrice]  NUMERIC (18, 4) DEFAULT ((0)) NOT NULL,
    [wTueExtraBedPrice]  NUMERIC (18, 4) DEFAULT ((0)) NOT NULL,
    [wWedExtraBedPrice]  NUMERIC (18, 4) DEFAULT ((0)) NOT NULL,
    [wThuExtraBedPrice]  NUMERIC (18, 4) DEFAULT ((0)) NOT NULL,
    [wFriExtraBedPrice]  NUMERIC (18, 4) DEFAULT ((0)) NOT NULL,
    [wSatExtraBedPrice]  NUMERIC (18, 4) DEFAULT ((0)) NOT NULL,
    [wSunExtraBedPrice]  NUMERIC (18, 4) DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_eHotelRoomPricing] PRIMARY KEY CLUSTERED ([RowID] ASC)
);







