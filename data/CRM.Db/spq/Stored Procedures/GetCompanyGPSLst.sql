CREATE PROCEDURE [spq].[GetCompanyGPSLst]
    @pCompanyRid BIGINT ,
    @pPageSize AS INT ,
    @pPageNum AS INT 
AS
    BEGIN

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;  

        SET @pCompanyRid=  ISNULL(@pCompanyRid, 0);;
        SET @pPageSize = ISNULL(@pPageSize, 10);
        SET @pPageNum = ISNULL(@pPageNum, 1);

        DECLARE @vCompany TABLE(
        RowID BIGINT,
        wName NVARCHAR(20),
        wStatus CHAR(1),
        wCompNo INT
        );
        INSERT INTO @vCompany (RowID,wName,wStatus,wCompNo)
        SELECT  RowID,wCName,wStatus,wCompNo  FROM RollsMary.dbo.mCompany WHERE wStatus='A' AND( @pCompanyRid = 0 OR RowID=@pCompanyRid )
        ORDER BY RowID
                 OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		FETCH NEXT @pPageSize ROWS ONLY;

        SELECT  sc.RowID ,
                wCompanyRid = temp.RowID,
                wCompanyName = temp.wName,
                sc.wName ,
                sc.wLatitude ,
                sc.wLongitude ,
                sc.wRadius ,
                sc.wStatus ,
                sc.wUpdDt ,
                sc.wUpdBy ,
                wRecordCount =CASE WHEN @pCompanyRid = 0 THEN (SELECT COUNT(1) FROM RollsMary.dbo.mCompany WHERE wStatus='A')
                              ELSE (SELECT COUNT(1) FROM @vCompany WHERE wStatus='A')
                              END ,
                temp.wCompNo
        FROM    @vCompany temp
        LEFT JOIN RollsMary.dbo.mCompanyCoverage sc  ON temp.wCompNo=sc.wCompNo AND sc.wStatus='A'
       
    END;