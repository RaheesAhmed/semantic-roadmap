CREATE PROCEDURE [spq].[GetUserLstForIM]
(
     @pDept VARCHAR(30) ,
     @pStatus VARCHAR(30) ,
     @pPageNum INT = 1 ,
     @pPageSize INT = 999
)
AS
    BEGIN
        SET NOCOUNT ON;


        SELECT
            RowID,
            wDept, 
            wCName,
            wName 
        FROM RollsMary.dbo.mUsr
        WHERE (@pDept='' OR wDept = @pDept) AND (@pStatus='' OR wStatus = @pStatus)
        ORDER BY RowID

    END;