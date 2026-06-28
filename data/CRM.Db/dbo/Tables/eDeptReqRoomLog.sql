CREATE TABLE [dbo].[eDeptReqRoomLog] (
    [RowID]        BIGINT          NOT NULL,
    [wAgentCodeIn] VARCHAR (14)    NULL,
    [wRemark]      NVARCHAR (4000) NULL,
    [wRemarkDt]    DATETIME2 (7)   NULL,
    [wStatus]      CHAR (1)        NULL,
    [wCrtBy]       BIGINT          NULL,
    [wCrtDt]       DATETIME2 (7)   NULL,
    [wUpdBy]       BIGINT          NULL,
    [wUpdDt]       DATETIME2 (7)   NULL,
    CONSTRAINT [PK__eDeptReq__FFEE74515C93457C] PRIMARY KEY CLUSTERED ([RowID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_AgentCodeIn]
    ON [dbo].[eDeptReqRoomLog]([wAgentCodeIn] ASC);

