
CREATE PROCEDURE [spq].[GetItemLst]
    @pName NVARCHAR(100) ,
    @pCategoryRid BIGINT ,
    @pBarcode VARCHAR(1000) ,
    @pIsSerialItem CHAR(1) ,
    @pStatus CHAR(1) ,
    @pPageNum INT = 1 ,
    @pPageSize INT = 999
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        WITH    cteData
                  AS ( SELECT   i_t.RowID ,
                                i_t.wCategoryRid ,                               
                                i_t.wCName ,
                                i_t.wEName ,
                                i_t.wPrice ,
                                i_t.wCurrCode ,
                                i_t.wBarcode ,
                                i_t.wIsSerialItem ,
                                i_t.wStatus ,
                                i_t.wCrtDt ,
                                i_t.wUpdDt ,
                                'N' AS RecordState
                       FROM     dbo.mItem i_t
                       WHERE    ( @pName = ''
                                  OR i_t.wCName LIKE N'%' + @pName + '%'
                                  OR i_t.wEName LIKE N'%' + @pName + '%'
                                )
                                AND ( @pCategoryRid = 0
                                      OR i_t.wCategoryRid = @pCategoryRid
                                    )
                                AND ( @pBarcode = ''
                                      OR i_t.wBarcode = @pBarcode
                                    )                               
                                AND ( @pIsSerialItem = ' '
                                      OR i_t.wIsSerialItem = @pIsSerialItem
                                    )
                                AND ( @pStatus = ' '
                                      OR i_t.wStatus = @pStatus
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