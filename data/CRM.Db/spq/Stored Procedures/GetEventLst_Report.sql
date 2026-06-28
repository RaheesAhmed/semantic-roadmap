CREATE PROC [spq].[GetEventLst_Report]
    @pLangCd    NVARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

        SELECT RowID,
               wName = CONCAT(wCode, ' - ', wName) 
        FROM dbo.mEvent
        WHERE wStatus = 'A'
    END