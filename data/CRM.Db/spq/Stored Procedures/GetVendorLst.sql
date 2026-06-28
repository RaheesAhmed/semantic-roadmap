
CREATE PROCEDURE [spq].[GetVendorLst]
    @pName NVARCHAR(100) ,
    @pTel VARCHAR(100) ,
    @pStatus CHAR(1) ,
    @pPageNum INT = 1 ,
    @pPageSize INT = 999
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 

        SET @pName = ISNULL(@pName, '');
        SET @pTel = ISNULL(@pTel, '');
	
        WITH    cteData
                  AS ( SELECT   v_t.RowID ,
                                v_t.wCName ,
                                v_t.wEName ,
                                v_t.wAddress ,
                                v_t.wTel ,
                                v_t.wGracePeriod ,
                                v_t.wStatus ,
                                v_t.wCrtDt ,
                                v_t.wUpdDt ,
                                'N' AS RecordState
                       FROM     dbo.mVendor v_t
                       WHERE    ( @pName = ''
                                  OR v_t.wCName LIKE N'%' + @pName + '%'
                                  OR v_t.wEName LIKE N'%' + @pName + '%'
                                )
                                AND ( @pTel = ''
                                      OR v_t.wTel LIKE N'%' + @pTel + '%'
                                      OR v_t.wTel LIKE N'%' + @pTel + '%'
                                    )
                                AND ( @pStatus = ' '
                                      OR v_t.wStatus = @pStatus
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