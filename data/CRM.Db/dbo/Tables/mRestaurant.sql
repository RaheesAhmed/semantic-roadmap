CREATE TABLE [dbo].[mRestaurant] (
    [RowID]         BIGINT          NOT NULL,
    [wName]         NVARCHAR (100)  NOT NULL,
    [wCuisine]      NVARCHAR (50)   NOT NULL,
    [wLevel]        VARCHAR (3)     NULL,
    [wPhone]        VARCHAR (50)    NULL,
    [wHotelRid]     BIGINT          NULL,
    [wAddress]      NVARCHAR (300)  NOT NULL,
    [wWorkHours]    NVARCHAR (400)  NOT NULL,
    [wRegion]       VARCHAR (10)    NOT NULL,
    [wNoOfSeat]     INT             NOT NULL,
    [wIsSign]       CHAR (1)        NOT NULL,
    [wIsBtm]        CHAR (1)        NOT NULL,
    [wMinCharge]    NUMERIC (18, 4) NOT NULL,
    [wMenu]         NVARCHAR (500)  NOT NULL,
    [wStatus]       VARCHAR (2)     NOT NULL,
    [wSeqNo]        INT             NOT NULL,
    [wCrtDt]        DATETIME2 (7)   NOT NULL,
    [wCrtBy]        BIGINT          NOT NULL,
    [wUpdDt]        DATETIME2 (7)   NOT NULL,
    [wUpdBy]        BIGINT          NOT NULL,
    [wAwards]       NVARCHAR (100)  CONSTRAINT [DF_mRestaurantSettings_wAwards_1] DEFAULT ('') NOT NULL,
    [wDressRequire] NVARCHAR (500)  NULL,
    CONSTRAINT [PK_mRestaurantSettings] PRIMARY KEY CLUSTERED ([RowID] ASC)
);






GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'服飾要求', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mRestaurant', @level2type = N'COLUMN', @level2name = N'wDressRequire';

