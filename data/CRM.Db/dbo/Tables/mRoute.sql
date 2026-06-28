CREATE TABLE [dbo].[mRoute] (
    [RowID]      BIGINT        NOT NULL,
    [wRouteFrom] NVARCHAR (50) CONSTRAINT [DF_mRoute_wRouteFrom] DEFAULT ('') NOT NULL,
    [wRouteTo]   NVARCHAR (50) CONSTRAINT [DF_mRoute_wRouteTo] DEFAULT ('') NOT NULL,
    [wVehicle]   VARCHAR (5)   NOT NULL,
    [wSeqNo]     INT           CONSTRAINT [DF_mRoute_wSeqNo] DEFAULT ((1)) NOT NULL,
    [wStatus]    CHAR (1)      NULL,
    [wCrtDt]     DATETIME2 (7) NOT NULL,
    [wCrtBy]     BIGINT        NOT NULL,
    [wUpdDt]     DATETIME2 (7) NOT NULL,
    [wUpdBy]     BIGINT        NOT NULL,
    [wIsTwoWay]  CHAR (1)      CONSTRAINT [DF_mRoute_wIsTwoWay] DEFAULT ('N') NOT NULL,
    CONSTRAINT [PK_mRoute] PRIMARY KEY CLUSTERED ([RowID] ASC)
);





