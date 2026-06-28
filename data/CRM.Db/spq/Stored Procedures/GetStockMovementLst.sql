
CREATE PROCEDURE [spq].[GetStockMovementLst]
    @pWarehouseInRid BIGINT ,
    @pWarehouseOutRid BIGINT ,
    @pOutFromDt DATETIME2 ,
    @pOutToDt DATETIME2 ,
    @pInFromDt DATETIME2 ,
    @pInToDt DATETIME2 ,
    @pMovementStatus VARCHAR(30) ,
    @pAgentCodeIn VARCHAR(14) ,
    @pOutDepartmentCode VARCHAR(30) ,
    @pOutWarehouseRidXML XML ,
    @pInDepartmentCode VARCHAR(30) ,
    @pInWarehouseRidXML XML ,
    @pLang VARCHAR(10) ,
    @pStatus CHAR(1) ,
    @pPageNum INT = 1 ,
    @pPageSize INT = 999
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;      
                
        DECLARE @IsSkip VARCHAR(1)= 'N';
        IF ( @pInFromDt IS NULL
             AND @pInToDt IS NULL
           )
            BEGIN
                SET @IsSkip = 'Y';
            END;
        
        SET @pOutFromDt = ISNULL(@pOutFromDt, '1900-01-01');
        SET @pOutToDt = ISNULL(@pOutToDt, '2099-12-31'); 
        SET @pInFromDt = ISNULL(@pInFromDt, '0001-01-01');
        SET @pInToDt = ISNULL(@pInToDt, '2099-12-31');    
        SET @pMovementStatus = ISNULL(@pMovementStatus, '');
        SET @pAgentCodeIn = ISNULL(@pAgentCodeIn, '');
        SET @pLang = LOWER(ISNULL(@pLang, 'zh-tw'));
        SET @pOutDepartmentCode = ISNULL(@pOutDepartmentCode, '');
        SET @pInDepartmentCode = ISNULL(@pInDepartmentCode, '');
		

        DECLARE @vOutWarehouseRidCount INT;
        DECLARE @vOutData_WarehouseRid AS TABLE ( SelectionItem BIGINT );
        DECLARE @vInWarehouseRidCount INT;
        DECLARE @vInData_WarehouseRid AS TABLE ( SelectionItem BIGINT );
	
        IF CAST(@pOutWarehouseRidXML AS NVARCHAR(MAX)) != N'<DataSet/>'
            BEGIN
                INSERT  INTO @vOutData_WarehouseRid
                        ( SelectionItem
                        )
                        SELECT  tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
                        FROM    @pOutWarehouseRidXML.nodes('/DataSet/Record') AS T ( tmp );
            END;

        SET @vOutWarehouseRidCount = ( SELECT   COUNT(1)
                                       FROM     @vOutData_WarehouseRid
                                     );

        IF CAST(@pInWarehouseRidXML AS NVARCHAR(MAX)) != N'<DataSet/>'
            BEGIN
                INSERT  INTO @vInData_WarehouseRid
                        ( SelectionItem
                        )
                        SELECT  tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
                        FROM    @pInWarehouseRidXML.nodes('/DataSet/Record') AS T ( tmp );
            END;

        SET @vInWarehouseRidCount = ( SELECT    COUNT(1)
                                      FROM      @vInData_WarehouseRid
                                    );

        WITH    ctePurchase
                  AS ( SELECT   RowID ,
                                wAgentCodeIn ,
                                wStatus
                       FROM     dbo.ePurchase p
                       WHERE    p.wStatus = 'A'
                     ),
                cteMovementAgent
                  AS ( SELECT   DISTINCT
                                sm.RowID AS wStockMovementRid
                       FROM     ctePurchase p
                                RIGHT JOIN dbo.eStockMovementItem smi ON p.RowID = smi.wPurchaseRid
                                                                         AND smi.wStatus = 'A'
                                RIGHT JOIN dbo.eStockMovementDtl smd ON smd.RowID = smi.wStockMovementDtlRid
                                                                        AND smd.wStatus = 'A'
                                RIGHT JOIN dbo.eStockMovement sm ON sm.RowID = smd.wStockMovementRid
                       WHERE    ( @pWarehouseOutRid = 0
                                  OR sm.wOutWarehouseRid = @pWarehouseOutRid
                                )
                                AND ( @pWarehouseInRid = 0
                                      OR sm.wInWarehouseRid = @pWarehouseInRid
                                    )
                                AND ( @pOutFromDt <= sm.wOutDt
                                      AND @pOutToDt >= sm.wOutDt
                                    )
                                AND ( @IsSkip = 'Y'
                                      OR ( @pInFromDt <= sm.wInDt
                                           AND @pInToDt >= sm.wInDt
                                         )
                                    )
                                AND ( @pMovementStatus = ''
                                      OR sm.wMovementStatus = @pMovementStatus
                                    )
                                AND ( @pStatus = ' '
                                      OR sm.wStatus = @pStatus
                                    )
                                AND ( @pAgentCodeIn = ''
                                      OR p.wAgentCodeIn = @pAgentCodeIn
                                    )
                     ),
                cteData
                  AS ( SELECT   sm_t.RowID ,
                                sm_t.wOutWarehouseRid ,
                                CASE WHEN @pLang = 'en-gb' THEN w_o.wEName
                                     ELSE w_o.wCName
                                END AS wOutWarehouseName ,
                                sm_t.wOutUsrRid ,
                                CASE WHEN @pLang = 'en-gb' THEN u_o.wName
                                     ELSE u_o.wCName
                                END AS wOutUsrName ,
                                sm_t.wOutDt ,
                                sm_t.wInWarehouseRid ,
                                CASE WHEN @pLang = 'en-gb' THEN w_i.wEName
                                     ELSE w_i.wCName
                                END AS wInWarehouseName ,
                                sm_t.wInUsrRid ,
                                CASE WHEN @pLang = 'en-gb' THEN u_i.wName
                                     ELSE u_i.wCName
                                END AS wInUsrName ,
                                sm_t.wInDt ,
                                sm_t.wRemarks ,
                                sm_t.wMovementStatus ,
                                sm_t.wStatus ,
                                sm_t.wCrtDt ,
                                sm_t.wCrtBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_c.wName
                                     ELSE u_c.wCName
                                END AS wCrtByName ,
                                sm_t.wUpdDt ,
                                sm_t.wUpdBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_u.wName
                                     ELSE u_u.wCName
                                END AS wUpdByName ,
                                'N' AS RecordState
                       FROM     dbo.eStockMovement sm_t
                                INNER JOIN cteMovementAgent ma ON ma.wStockMovementRid = sm_t.RowID
                                LEFT JOIN dbo.mWarehouse w_o ON w_o.RowID = sm_t.wOutWarehouseRid
                                LEFT JOIN dbo.mWarehouse w_i ON w_i.RowID = sm_t.wInWarehouseRid
                                LEFT JOIN RollsMary.dbo.mUsr u_i ON u_i.RowID = sm_t.wInUsrRid
                                LEFT JOIN RollsMary.dbo.mUsr u_o ON u_o.RowID = sm_t.wOutUsrRid
                                LEFT JOIN RollsMary.dbo.mUsr u_c ON u_c.RowID = sm_t.wCrtBy
                                LEFT JOIN RollsMary.dbo.mUsr u_u ON u_u.RowID = sm_t.wUpdBy
                                LEFT JOIN @vOutData_WarehouseRid v_o ON v_o.SelectionItem = sm_t.wOutWarehouseRid
                                LEFT JOIN @vInData_WarehouseRid v_i ON v_i.SelectionItem = sm_t.wInWarehouseRid
                       WHERE    ( @pWarehouseOutRid = 0
                                  OR sm_t.wOutWarehouseRid = @pWarehouseOutRid
                                )
                                AND ( @pWarehouseInRid = 0
                                      OR sm_t.wInWarehouseRid = @pWarehouseInRid
                                    )
                                AND ( @pOutFromDt <= sm_t.wOutDt
                                      AND @pOutToDt >= sm_t.wOutDt
                                    )
                                AND ( @IsSkip = 'Y'
                                      OR ( @pInFromDt <= sm_t.wInDt
                                           AND @pInToDt >= sm_t.wInDt
                                         )
                                    )
                                AND ( @pMovementStatus = ''
                                      OR sm_t.wMovementStatus = @pMovementStatus
                                    )
                                AND ( @pStatus = ' '
                                      OR sm_t.wStatus = @pStatus
                                    )
                                AND ( @pOutDepartmentCode = ''
                                      OR w_o.wDepartmentCode = @pOutDepartmentCode
                                    )
                                AND ( @vOutWarehouseRidCount <= 0
                                      OR v_o.SelectionItem IS NOT NULL
                                    )
                                AND ( @pInDepartmentCode = ''
                                      OR w_i.wDepartmentCode = @pInDepartmentCode
                                    )
                                AND ( @vInWarehouseRidCount <= 0
                                      OR v_i.SelectionItem IS NOT NULL
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