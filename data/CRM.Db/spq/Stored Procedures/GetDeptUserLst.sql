CREATE PROCEDURE [spq].[GetDeptUserLst]
    @pDept VARCHAR(4000)
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @vXML XML;
        DECLARE @vDept TABLE (wCode VARCHAR(50) PRIMARY KEY)

        SET @vXML = CONCAT('<DataSet>', '<Record>', REPLACE(ISNULL(@pDept, ''), ',', '</Record><Record>'), '</Record>', '</DataSet>');

        INSERT INTO @vDept( wCode )
        SELECT wCode
        FROM (
            SELECT wCode = T.tmp.value('.', 'VARCHAR(50)')
            FROM @vXML.nodes('DataSet/Record') T(tmp)
        ) tmp WHERE ISNULL(tmp.wCode, '') != '';

        SELECT  mu.RowID,
                mu.wUsrId,
                wDeptCd = mu.wDept,
                mu.wCName,
                wEName = mu.wName,
                wIsEnable = IIF(mu.wStatus = 'ACTIVE', 'Y', 'N')
        FROM RollsMary.dbo.mUsr mu WITH(NOLOCK)
        INNER JOIN @vDept d ON d.wCode = mu.wDept;
    END