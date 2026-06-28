CREATE PROCEDURE [spq].[GetDocumentByRefTable]
    (
      @pRefRID BIGINT ,
      @pRefTable VARCHAR(50) ,
      @pType VARCHAR(20) ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1
    )
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 
    	
        SELECT  d.* ,
                wUpdByCName = u.wCName
        FROM    CRM_Doc.dbo.eDocument d
                LEFT JOIN RollsMary.dbo.mUsr u ON d.wUpdBy = u.RowID
        WHERE   d.wRefRID = @pRefRID
                AND d.wRefTable = @pRefTable
                AND ( d.wType = @pType
                      OR @pType = ''
                    )
                AND d.wStatus = 'A'
        ORDER BY d.wUpdDt DESC
                OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS 
		FETCH NEXT @pPageSize ROWS ONLY;
    END;