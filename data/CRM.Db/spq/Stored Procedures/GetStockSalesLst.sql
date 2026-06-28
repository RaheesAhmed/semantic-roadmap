
CREATE PROCEDURE [spq].[GetStockSalesLst]
    @pWarehouseRid BIGINT ,
    @pRefNo VARCHAR(50) ,
    @pSalesFromDt DATETIME2 ,
    @pSalesToDt DATETIME2 ,
    @pPickupFromDt DATETIME2,
    @pPickupToDt DATETIME2,
    @pSalesStatus VARCHAR(30) ,
    @pRecipientAgentCodeIn VARCHAR(14) ,
    @pAgentCodeIn VARCHAR(14) ,
    @pDepartmentCode VARCHAR(30) ,
    @pWarehouseRidXML XML ,
    @pIsBorrowGoods CHAR(1),
    @pLang VARCHAR(10) ,
    @pStatus CHAR(1) ,
    @pPageNum INT = 1 ,
    @pPageSize INT = 999
AS
    BEGIN
        SET NOCOUNT ON;	  
		        				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;       

        SET @pWarehouseRid = ISNULL(@pWarehouseRid, 0);	
        SET @pRefNo = ISNULL(@pRefNo, '');	
        SET @pSalesStatus = ISNULL(@pSalesStatus, '');	
        SET @pSalesFromDt = ISNULL(@pSalesFromDt, '1900-01-01');
        SET @pSalesToDt = ISNULL(@pSalesToDt, '2099-12-31');       	
        SET @pAgentCodeIn = ISNULL(@pAgentCodeIn, '');
        SET @pRecipientAgentCodeIn = ISNULL(@pRecipientAgentCodeIn,'');
        SET @pLang = LOWER(ISNULL(@pLang, 'zh-tw'));
        SET @pDepartmentCode = ISNULL(@pDepartmentCode, '');

        IF @pPickupFromDt IS NOT NULL OR @pPickupToDt IS NOT NULL
        BEGIN
           SET @pPickupFromDt =ISNULL(@pPickupFromDt,'1900-01-01');
           SET @pPickupToDt =ISNULL(@pPickupToDt,'2099-12-31')  
        END


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

        WITH    cteSalesAgent
                  AS ( SELECT   DISTINCT
                                ss.RowID AS wStockSalesRid,
                                @pAgentCodeIn AS wAgentCodeIn
                       FROM     dbo.ePurchase p
                                RIGHT JOIN dbo.eStockSalesItem ssi ON p.RowID = ssi.wPurchaseRid
                                                                      AND ssi.wStatus = 'A'
                                RIGHT JOIN dbo.eStockSalesDtl ssd ON ssd.RowID = ssi.wStockSalesDtlRid
                                                                     AND ssd.wStatus = 'A'
                                RIGHT JOIN dbo.eStockSales ss ON ss.RowID = ssd.wStockSalesRid
                       WHERE    ( @pWarehouseRid = 0
                                  OR ss.wOutWarehouseRid = @pWarehouseRid
                                )
                                AND ( @pRefNo = ''
                                      OR ss.wRefNo = @pRefNo
                                    )
                                AND ( ss.wSalesDt >= @pSalesFromDt
                                      AND ss.wSalesDt <= @pSalesToDt
                                    )
                                AND ( @pSalesStatus = ''
                                      OR ss.wSalesStatus = @pSalesStatus
                                    )
                                AND ( @pStatus = ' '
                                      OR ss.wStatus = @pStatus
                                    )
                                AND ( @pAgentCodeIn = ''
                                      OR p.wAgentCodeIn = @pAgentCodeIn
                                    )
                                AND p.wStatus = 'A'
                     ),
                cteData
                  AS ( SELECT   ss_t.RowID ,
                                ss_t.wOutWarehouseRid ,
                                CASE WHEN @pLang = 'en-gb' THEN w.wEName
                                     ELSE w.wCName
                                END AS wOutWarehouseName ,
                                ss_t.wRefNo ,
                                ss_t.wPaymentMethod ,
                                ss_t.wSalesDt ,
                                ss_t.wSalesDeptCd ,
                                CASE WHEN @pLang = 'en-gb' THEN d.wEName
                                     ELSE d.wCName
                                END AS wSalesDeptName ,
                                ss_t.wSalesmanRid ,
                                CASE WHEN @pLang = 'en-gb' THEN u_s.wName
                                     ELSE u_s.wCName
                                END AS wSalesmanName ,
                                ss_t.wDebitAgentCodeIn ,
                                a.wAgentCode_Display AS wDebitAgentCode ,
                                CASE WHEN @pLang = 'en-gb' THEN a.wEName
                                     ELSE a.wCName
                                END AS wDebitAgentName ,
                                ss_t.wRecipientAgentCodeIn ,
                                a_r.wAgentCode_Display AS wRecipientAgentCode ,
                                CASE WHEN @pLang = 'en-gb' THEN a_r.wEName
                                     ELSE a_r.wCName
                                END AS wRecipientAgentName ,
                                ss_t.wSalesTotalPrice ,
                                ss_t.wSalesStatus ,
                                ss_t.wStatus ,
                                ss_t.wCrtDt ,
                                ss_t.wCrtBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_c.wName
                                     ELSE u_c.wCName
                                END AS wCrtByName ,
                                ss_t.wUpdDt ,
                                ss_t.wUpdBy ,
                                CASE WHEN @pLang = 'en-gb' THEN u_u.wName
                                     ELSE u_u.wCName
                                END AS wUpdByName ,
                                'N' AS RecordState,
                                ss_t.wDebitCounterRid,
                                sa.wAgentCodeIn,
                                ss_t.wIsBorrowGoods,
                                ss_t.wPickupDt,
                                ss_t.wTotalCost
                       FROM     dbo.eStockSales ss_t
                                LEFT JOIN cteSalesAgent sa ON sa.wStockSalesRid = ss_t.RowID
                                LEFT JOIN RollsMary.dbo.mAgent a ON a.wAgentCodeIn = ss_t.wDebitAgentCodeIn
                                LEFT JOIN RollsMary.dbo.mAgent a_r ON a_r.wAgentCodeIn = ss_t.wRecipientAgentCodeIn
                                LEFT JOIN dbo.mWarehouse w ON w.RowID = ss_t.wOutWarehouseRid
                                LEFT JOIN RollsMary.dbo.mUsr u_c ON u_c.RowID = ss_t.wCrtBy
                                LEFT JOIN RollsMary.dbo.mUsr u_u ON u_u.RowID = ss_t.wUpdBy
                                LEFT JOIN RollsMary.dbo.mUsr u_s ON u_s.RowID = ss_t.wSalesmanRid
                                LEFT JOIN RollsMary.dbo.mDepartment d ON d.wCode = ss_t.wSalesDeptCd
                                                                         AND d.wUserLineGrp = ''
                                LEFT JOIN @vData_WarehouseRid v ON v.SelectionItem = ss_t.wOutWarehouseRid
                       WHERE    ( @pWarehouseRid = 0
                                  OR ss_t.wOutWarehouseRid = @pWarehouseRid
                                )
                                AND ( @pRefNo = ''
                                      OR ss_t.wRefNo = @pRefNo
                                    )
                                AND ( ss_t.wSalesDt >= @pSalesFromDt
                                      AND ss_t.wSalesDt <= @pSalesToDt
                                    )
                                AND ( (@pPickupFromDt IS NULL AND @pPickupToDt IS NULL) 
                                      OR (ss_t.wPickupDt >= @pPickupFromDt AND ss_t.wPickupDt <= @pPickupToDt)
                                    )
                                AND ( @pSalesStatus = ''
                                      OR ss_t.wSalesStatus = @pSalesStatus
                                    )
                                AND ( @pStatus = ' '
                                      OR ss_t.wStatus = @pStatus
                                    )
                                AND ( @pDepartmentCode = ''
                                      OR w.wDepartmentCode = @pDepartmentCode
                                    )
                                AND ( @vWarehouseRidCount <= 0
                                      OR v.SelectionItem IS NOT NULL
                                    )
                                AND ( @pIsBorrowGoods = ' '
                                      OR ss_t.wIsBorrowGoods = @pIsBorrowGoods
                                    )
                                AND (@pAgentCodeIn = ''
                                      OR ss_t.wDebitAgentCodeIn = @pAgentCodeIn
                                      )
                                AND (@pRecipientAgentCodeIn = ''
                                      OR ss_t.wRecipientAgentCodeIn = @pRecipientAgentCodeIn
                                      )
                     ),
                cteCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     cteData 
                       WHERE @pAgentCodeIn = '' OR wAgentCodeIn=@pAgentCodeIn
                     )
            SELECT  d.* ,
                    c.wRecordCount
            FROM    cteData d ,
                    cteCount c
            WHERE @pAgentCodeIn = '' OR d.wAgentCodeIn=@pAgentCodeIn
            ORDER BY d.wCrtDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	    FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );
    END;