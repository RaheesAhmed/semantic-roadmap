CREATE TABLE [dbo].[mYearMonth] (
    [wType]        CHAR (5) NOT NULL,
    [wYear]        INT      NOT NULL,
    [wMonth]       INT      NOT NULL,
    [wIsLeapMonth] CHAR (1) NOT NULL,
    [wDaysOfMonth] INT      NOT NULL,
    CONSTRAINT [PK__mYearMon__F45E0A68E22348A5] PRIMARY KEY CLUSTERED ([wType] ASC, [wYear] ASC, [wMonth] ASC, [wIsLeapMonth] ASC)
);

