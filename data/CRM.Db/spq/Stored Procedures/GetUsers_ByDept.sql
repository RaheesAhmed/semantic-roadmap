CREATE PROCEDURE [spq].[GetUsers_ByDept]
(
    @pDept VARCHAR(15) ,
    @pStatus VARCHAR(10) ,
    @pLangCd VARCHAR(10) = 'en-GB'
)
AS
    BEGIN
        SET NOCOUNT ON;

		SET @pDept = NULLIF(@pDept, '');
		SET @pStatus = NULLIF(@pStatus, '');
		SET @pLangCd = ISNULL(@pLangCd, 'en-GB');

        SELECT
            RowID,
            wDept, -- 部門
            wCName = CASE WHEN @pLangCd = 'en-GB' THEN wName ELSE wCName END ,
            wPrivateTel = CONCAT(CASE WHEN NULLIF(wPrivateTelCountryCode, '') IS NULL THEN NULL ELSE ('+' + REPLACE(wPrivateTelCountryCode, '+', '')) END,
                                 CASE WHEN NULLIF(wPrivateTel, '') IS NULL THEN NULL ELSE ('-' + REPLACE(wPrivateTel, '-', '')) END), -- 刪除空白電話（原來顯示成：+-）
            wCName AS ChName ,
            wName AS Ename,
            wStatus, -- 狀態
            wUsrId
        FROM RollsMary.dbo.mUsr
        WHERE (@pStatus IS NULL OR wStatus = @pStatus )
            AND (@pDept IS NULL OR wDept = @pDept);
    END;