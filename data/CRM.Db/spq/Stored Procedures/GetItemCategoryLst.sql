
CREATE PROCEDURE [spq].[GetItemCategoryLst]
    @pName NVARCHAR(100) ,
    @pStatus CHAR(1) ,
    @pPageNum INT = 1 ,
    @pPageSize INT = 999
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        

        SET @pName = ISNULL(@pName, '');
	
        WITH    cteData
                  AS ( SELECT   ic_t.RowID ,
                                ic_t.wCName ,
                                ic_t.wEName ,
                                ic_t.wStatus ,
                                ic_t.wCrtDt ,
                                ic_t.wUpdDt ,
                                'N' AS RecordState
                       FROM     dbo.mItemCategory ic_t
                       WHERE    ( @pName = ''
                                  OR ic_t.wCName LIKE N'%' + @pName + '%'
                                  OR ic_t.wEName LIKE N'%' + @pName + '%'
                                )
                                AND ( @pStatus = ' '
                                      OR ic_t.wStatus = @pStatus
                                    )
                     ),
                cteCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     cteData
                     )
            SELECT  d.* ,
                    c.wRecordCount
            FROM    cteData d ,
                    cteCount c
            ORDER BY d.wCrtDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );
    END;