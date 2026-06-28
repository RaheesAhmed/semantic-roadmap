CREATE TABLE [dbo].[eAllotmentHotelDtl] (
    [RowID]              BIGINT        NOT NULL,
    [wAllotmentHotelRid] BIGINT        NOT NULL,
    [wAllotmentGroupRid] BIGINT        NOT NULL,
    [wSunQty]            INT           CONSTRAINT [DF_eAllotmentHotelDtl_wSunQty_1] DEFAULT ((0)) NOT NULL,
    [wMonQty]            INT           CONSTRAINT [DF_eAllotmentHotelDtl_wMonQty_1] DEFAULT ((0)) NOT NULL,
    [wTueQty]            INT           CONSTRAINT [DF_eAllotmentHotelDtl_wTueQty_1] DEFAULT ((0)) NOT NULL,
    [wWedQty]            INT           CONSTRAINT [DF_eAllotmentHotelDtl_wWedQty_1] DEFAULT ((0)) NOT NULL,
    [wThuQty]            INT           CONSTRAINT [DF_eAllotmentHotelDtl_wThuQty_1] DEFAULT ((0)) NOT NULL,
    [wFriQty]            INT           CONSTRAINT [DF_eAllotmentHotelDtl_wFriQty_1] DEFAULT ((0)) NOT NULL,
    [wSatQty]            INT           CONSTRAINT [DF_eAllotmentHotelDtl_wSatQty_1] DEFAULT ((0)) NOT NULL,
    [wSeqNo]             INT           CONSTRAINT [DF_eAllotmentHotelDtl_wSeqNo] DEFAULT ((1)) NOT NULL,
    [wCrtDt]             DATETIME2 (7) NOT NULL,
    [wCrtBy]             BIGINT        NOT NULL,
    [wUpdDt]             DATETIME2 (7) NOT NULL,
    [wUpdBy]             BIGINT        NOT NULL,
    CONSTRAINT [PK_eAllotmentHotelDtl_1] PRIMARY KEY CLUSTERED ([RowID] ASC),
    CONSTRAINT [FK_eAllotmentHotelDtl_eAllotmentHotel] FOREIGN KEY ([wAllotmentHotelRid]) REFERENCES [dbo].[eAllotmentHotel] ([RowID]),
    CONSTRAINT [FK_eAllotmentHotelDtl_mAllotmentGroup] FOREIGN KEY ([wAllotmentGroupRid]) REFERENCES [dbo].[mAllotmentGroup] ([RowID])
);



