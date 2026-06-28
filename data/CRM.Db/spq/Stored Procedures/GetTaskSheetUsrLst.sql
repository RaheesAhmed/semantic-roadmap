

CREATE PROCEDURE [spq].[GetTaskSheetUsrLst] 
       ( @pRowId BIGINT,
		  @pLangCd VARCHAR(30)
	   )
AS
    BEGIN
        SET NOCOUNT ON;
	  	
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        SELECT tUsr.RowID,
			   tUsr.wTaskSheetRid,
			   tUsr.wUsrRid,
			   (CASE WHEN @pLangCd = 'en-GB' THEN mUsr.wName ELSE mUsr.wCName END ) AS wUsrName,
	           tUsr.wStatus,
	           tUsr.wDeptCd,
	           tUsr.wRemark,
	           tUsr.wCrtDt,
	           tUsr.wCrtBy,
			   (CASE WHEN @pLangCd = 'en-GB' THEN pUsr.wName ELSE pUsr.wCName END ) AS wCrtByName,
	           tUsr.wUpdDt,
	           tUsr.wUpdBy
        FROM   [dbo].[eTaskSheetUsr] tUsr
		LEFT JOIN  [RollsMary].[dbo].[mUsr]  mUsr ON mUsr.RowID = tUsr.wUsrRid
		LEFT JOIN  [RollsMary].[dbo].[mUsr]  pUsr ON pUsr.RowID = tUsr.wCrtBy
        WHERE   wTaskSheetRid=@pRowId;
    END;