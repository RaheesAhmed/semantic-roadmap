CREATE PROCEDURE [spq].[GetUserByRowId]
(
    @pRowID BIGINT,
    @pLangCd VARCHAR(10) = 'zh-TW'
)
AS
    BEGIN
        SET NOCOUNT ON;

		SET @pRowID = ISNULL(IIF(@pRowID <= 0 , NULL, @pRowID), 0);
		SET @pLangCd = ISNULL(@pLangCd, 'zh-TW');

        SELECT
            RowID,
            wDept, -- 部門
            wCName = CASE WHEN @pLangCd = 'en-GB' THEN wName ELSE wCName END ,
            wPrivateTel = CONCAT(CASE WHEN NULLIF(wPrivateTelCountryCode, '') IS NULL THEN NULL ELSE ('+' + REPLACE(wPrivateTelCountryCode, '+', '')) END,
                                 CASE WHEN NULLIF(wPrivateTel, '') IS NULL THEN NULL ELSE ('-' + REPLACE(wPrivateTel, '-', '')) END), -- 刪除空白電話（原來顯示成：+-）
            wChName = wCName ,
            wEname = wName,
            wStatus -- 狀態
        FROM RollsMary.dbo.mUsr
        WHERE @pRowID = RowID
    END;