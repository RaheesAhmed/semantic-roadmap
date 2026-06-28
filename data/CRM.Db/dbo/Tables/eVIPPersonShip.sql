CREATE TABLE [dbo].[eVIPPersonShip] (
    [wVIPPersonRid]    BIGINT        NOT NULL,
    [wVIPPersonRefRid] BIGINT        NOT NULL,
    [wIsBirthday]      CHAR (1)      NOT NULL,
    [wUpdBy]           BIGINT        NOT NULL,
    [wUpdDt]           DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK__eVIPPers__7B4E0FD78DD52F08] PRIMARY KEY CLUSTERED ([wVIPPersonRid] ASC, [wVIPPersonRefRid] ASC)
);

