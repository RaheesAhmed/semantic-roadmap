CREATE TABLE [dbo].[eActionAffectedTableLog] (
    [wActionSp]     VARCHAR (100) NOT NULL,
    [wActionType]   CHAR (1)      NOT NULL,
    [wNonceToken]   VARCHAR (40)  NOT NULL,
    [wRefTableName] VARCHAR (100) NOT NULL,
    [wRefRid]       BIGINT        NOT NULL,
    [wType]         VARCHAR (50)  NOT NULL,
    [wCrtDt]        DATETIME2 (7) CONSTRAINT [DF_eActionAffectedTableLog_wCrtDt] DEFAULT ([dbo].[fnUTC8Now]()) NOT NULL
);




GO
CREATE CLUSTERED INDEX [CI_eActionAffectedTableLog]
    ON [dbo].[eActionAffectedTableLog]([wNonceToken] ASC);


GO


