CREATE TABLE [dbo].[mAgentSMSPreference] (
    [wAgentCodeIn] VARCHAR (14)  NOT NULL,
    [wSmsType]     VARCHAR (50)  NOT NULL,
    [wIsIgnore]    CHAR (1)      CONSTRAINT [DF_mAgentSMSPreference_wIsIgnore] DEFAULT ('N') NOT NULL,
    [wUpdDt]       DATETIME2 (7) NOT NULL,
    [wUpdBy]       BIGINT        NOT NULL,
    CONSTRAINT [PK_mAgentSMSPreference] PRIMARY KEY CLUSTERED ([wAgentCodeIn] ASC, [wSmsType] ASC)
);




GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'戶口不想接收此訊息, 當 Y 時, 訊息預覽需顯示提示字句', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mAgentSMSPreference', @level2type = N'COLUMN', @level2name = N'wIsIgnore';

