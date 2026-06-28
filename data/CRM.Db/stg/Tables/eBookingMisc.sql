CREATE TABLE [stg].[eBookingMisc] (
    [wBookingRid] BIGINT         NOT NULL,
    [wLangCd]     VARCHAR (10)   NOT NULL,
    [wItemCd]     VARCHAR (20)   NOT NULL,
    [wValue]      NVARCHAR (MAX) NOT NULL,
    CONSTRAINT [PK_eBookingMisc] PRIMARY KEY CLUSTERED ([wBookingRid] ASC, [wLangCd] ASC, [wItemCd] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'ms_description', @value = N'記得常用的 detail 內容, 例如客人名', @level0type = N'SCHEMA', @level0name = N'stg', @level1type = N'TABLE', @level1name = N'eBookingMisc';

