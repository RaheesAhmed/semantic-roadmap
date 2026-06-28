CREATE PROCEDURE [spq].[SC_GetTaskSheetTypeList] 
( 
	/*
		exec [spq].[SC_GetTaskSheetTypeList] '', 'zh-TW'
	*/
	@pDepartmentCode VARCHAR(30),
	@pLangCd		 VARCHAR(30)='zh-TW',
	@pCode			 INT = 0 OUTPUT,
	@pMsg			 NVARCHAR(200)='' OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
	IF @@trancount = 0
		SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

	SELECT  tst.wDepartmentCode,
            dpt.wTitle AS wDepartmentName,
            tst.wCode,
            tst.wParentCode,
            tst.wTitle
    FROM  dbo.mTaskSheetType tst    
    INNER JOIN dbo.mLookUp dpt ON  dpt.wCode = tst.wDepartmentCode 
    WHERE  tst.wStatus = 'A' AND dpt.wType = 'DEPARTMENT' AND dpt.wLangCd = @pLangCd
			AND (ISNULL(@pDepartmentCode, '')='' OR tst.wDepartmentCode=@pDepartmentCode)
END;