
CREATE PROCEDURE [spq].[GetWarehouseLst]
    @pRowID BIGINT ,
    @pName NVARCHAR(100) ,
    @pDepartmentCode VARCHAR(30) ,
    @pCounterRid BIGINT ,
    @pIsDefault CHAR(1) ,
    @pWarehouseRidXML XML ,
    @pStatus CHAR(1) ,
    @pPageNum INT = 1 ,
    @pPageSize INT = 999
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;   
		
        SET @pName = ISNULL(@pName, '');
        SET @pDepartmentCode = ISNULL(@pDepartmentCode, '');     

        DECLARE @vWarehouseRidCount INT;
        DECLARE @vData_WarehouseRid AS TABLE ( SelectionItem BIGINT );
	
        IF CAST(@pWarehouseRidXML AS NVARCHAR(MAX)) != N'<DataSet/>'
            BEGIN
                INSERT  INTO @vData_WarehouseRid
                        ( SelectionItem
                        )
                        SELECT  tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
                        FROM    @pWarehouseRidXML.nodes('/DataSet/Record') AS T ( tmp );
            END;

        SET @vWarehouseRidCount = ( SELECT  COUNT(1)
                                    FROM    @vData_WarehouseRid
                                  );

        WITH    cteData
                  AS ( SELECT   w_t.RowID ,
                                w_t.wDepartmentCode ,
                                w_t.wCName ,
                                w_t.wEName ,
                                w_t.wCounterRid ,
                                ISNULL(sc.wName, '') AS wCounterName ,
                                w_t.wIsDefault ,
                                w_t.wStatus ,
                                w_t.wCrtDt ,
                                w_t.wUpdDt ,
                                'N' AS RecordState
                       FROM     dbo.mWarehouse w_t
                                LEFT JOIN dbo.mServiceCounter sc ON sc.RowID = w_t.wCounterRid
                                LEFT JOIN @vData_WarehouseRid v ON w_t.RowID = v.SelectionItem
                       WHERE    ( @pRowID = 0
                                  OR w_t.RowID = @pRowID
                                )
                                AND ( @pName = ''
                                      OR w_t.wCName LIKE N'%' + @pName + '%'
                                      OR w_t.wEName LIKE N'%' + @pName + '%'
                                    )
                                AND ( @pDepartmentCode = ''
                                      OR w_t.wDepartmentCode = @pDepartmentCode
                                    )
                                AND ( @pCounterRid = 0
                                      OR w_t.wCounterRid = @pCounterRid
                                    )
                                AND ( @pIsDefault = ' '
                                      OR w_t.wIsDefault = @pIsDefault
                                    )
                                AND ( @pStatus = ' '
                                      OR w_t.wStatus = @pStatus
                                    )
                                AND ( @vWarehouseRidCount <= 0
                                      OR v.SelectionItem IS NOT NULL
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