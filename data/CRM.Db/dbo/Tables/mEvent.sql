CREATE TABLE [dbo].[mEvent] (
    [RowID]             BIGINT         NOT NULL,
    [wName]             NVARCHAR (100) NOT NULL,
    [wStartDate]        DATE           NOT NULL,
    [wEndDate]          DATE           NOT NULL,
    [wType]             VARCHAR (10)   DEFAULT ('MD') NOT NULL,
    [wColorRGB]         VARCHAR (7)    NOT NULL,
    [wStatus]           VARCHAR (20)   NOT NULL,
    [wCrtDt]            DATETIME2 (7)  NOT NULL,
    [wCrtBy]            BIGINT         NOT NULL,
    [wUpdDt]            DATETIME2 (7)  NOT NULL,
    [wUpdBy]            BIGINT         NOT NULL,
    [wCode]             NVARCHAR (30)  NULL,
    [wBookingStartDate] DATE           NULL,
    [wBookingEndDate]   DATE           NULL,
    [wSunCRMStartDate]  DATE           NULL,
    [wSunCRMEndDate]    DATE           NULL,
    PRIMARY KEY CLUSTERED ([RowID] ASC)
);








GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'特別事件，房間可以請求下訂開始日期', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mEvent', @level2type = N'COLUMN', @level2name = N'wBookingStartDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'特別事件，房間可以請求下訂截止日期', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mEvent', @level2type = N'COLUMN', @level2name = N'wBookingEndDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'特別事件，SunPeople開放時間段', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mEvent', @level2type = N'COLUMN', @level2name = N'wSunCRMStartDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'特別事件，SunPeople開放時間段', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mEvent', @level2type = N'COLUMN', @level2name = N'wSunCRMEndDate';

