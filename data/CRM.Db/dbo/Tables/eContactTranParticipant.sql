CREATE TABLE [dbo].[eContactTranParticipant] (
    [RowID]           BIGINT        NOT NULL,
    [wContactTranRid] BIGINT        NOT NULL,
    [wAgentCodeIn]    VARCHAR (14)  NOT NULL,
    [wParticipated]   CHAR (1)      NOT NULL,
    [wStatus]         CHAR (1)      NOT NULL,
    [wCrtDt]          DATETIME2 (7) NOT NULL,
    [wCrtBy]          BIGINT        NOT NULL,
    [wUpdDt]          DATETIME2 (7) NOT NULL,
    [wUpdBy]          BIGINT        NOT NULL,
    CONSTRAINT [PK_eContactTranParticipant] PRIMARY KEY CLUSTERED ([RowID] ASC)
);




GO
CREATE NONCLUSTERED INDEX [PI_eContactTranParticipant_01]
    ON [dbo].[eContactTranParticipant]([wAgentCodeIn] ASC);

